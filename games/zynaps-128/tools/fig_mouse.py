#!/usr/bin/env python3
"""Doc 05 figure: K-MOUSE at work in recording m1 (tools/rec_mouse.py): the mouse driver's position against the
ship's position, frame by frame, and the screen at four moments.

    python3 tools/fig_mouse.py --work work/z128A/m1 --out docs/img/controls/mouse-ship.png

Every value is read from m1 with time_travel memory_at (exact), at the end of each frame:
  MouseX `$FED9`, MouseY `$FEDA`  the driver's position (0-239, 0-127), moved by the counters' steps (MouseMove)
  ShipX `$F36F`/`$F370`           the ship's X: column + 16 in the high byte, the pixel in bits 5-7 of the low byte
  ShipY `$F371`/`$F372`           the ship's Y: the row in the high byte, the line in bits 5-7 of the low byte
The ship's X and Y are drawn in pixels ((column) * 8 + pixel, row * 8 + line), the same units as the driver's.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

F0, F1 = 1785, 2576
SHOTS = [1840, 2120, 2210, 2380]
# tools/rec_mouse.py's schedule from m1's first frame 1785: 10 frames, the right button 35, 250 frames, then per
# COURSE entry a glide, 40 frames, a 4-frame left click (fire)
COURSE = [(0, 0), (40, 0), (0, 30), (-40, 0), (0, -30), (80, 20), (-60, -20), (30, 40), (-50, -40)]
START = (1795, 1830)
GLIDE0, GLIDE_STEP = 2080, 44
# the life, from find_last over m1: MouseReset $FE00 at 1910, MouseRead $FE1D every second frame from 1912 to 2389
# (the ship destroyed then: EndOfPlay $B0FF at 2438, PlayerDied $B119 at 2500)
LIFE = (1912, 2389)


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def read(s, frame, lo, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': lo, 'length': n},
               ok=False)
    if not r.structured or not r.structured.get('exact'):
        raise SystemExit(f'memory_at {frame} ${lo:04X}: {r.text[:200]}')
    return bytes.fromhex(r.structured['hex'])


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = session(args.work)
    rows = []
    for fr in range(F0, F1 + 1):
        mx, my = read(s, fr, 0xFED9, 2)
        sx_lo, sx_hi, sy_lo, sy_hi = read(s, fr, 0xF36F, 4)
        ship_x = (sx_hi - 16) * 8 + (sx_lo >> 5) if sx_hi >= 16 else None
        ship_y = sy_hi * 8 + (sy_lo >> 5)
        rows.append((fr, mx, my, ship_x, ship_y, sx_hi))
    W, H = 1240, 840
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f, fs, ft = K.font(12), K.font(11), K.font(17)
    d.text((10, 8), 'K-MOUSE: X follows the driver exactly; in Y the ship sits one move step above it (the driver '
           'returns "up")', fill=K.TEXT, font=ft)
    d.text((10, 32), 'm1 (Pentagon 128 + TR-DOS, K-MOUSE on, mouse glides from tools/rec_mouse.py), frames '
           f'{F0}-{F1}, read every frame with memory_at.', fill=K.DIM, font=f)
    ax0, ax1 = 70, W - 20

    def xat(fr):
        return ax0 + (ax1 - ax0) * (fr - F0) // (F1 - F0)

    diffs = {'x': [], 'y': []}
    for k, (title, y0, y1, vmax, idx_m, idx_s) in enumerate(
            (('X (pixels across, 0 = column 0 of the playfield)', 70, 260, 255, 1, 3),
             ('Y (lines down)', 300, 490, 127, 2, 4))):
        d.text((ax0, y0 - 18), title, fill=K.TEXT, font=f)
        d.rectangle((ax0, y0, ax1, y1), outline=(60, 60, 75))
        for v in range(0, vmax + 1, 32 if vmax > 128 else 16):
            yy = y1 - (y1 - y0) * v // vmax
            d.line((ax0, yy, ax1, yy), fill=(34, 34, 46))
            d.text((ax0 - 32, yy - 7), str(v), fill=K.DIM, font=fs)
        for idx, colour in ((idx_m, (250, 210, 80)), (idx_s, (90, 200, 250))):
            pts = []
            for r in rows:
                v = r[idx]
                if v is None:
                    if len(pts) > 1:
                        d.line(pts, fill=colour, width=2)
                    pts = []
                    continue
                pts.append((xat(r[0]), y1 - (y1 - y0) * min(v, vmax) // vmax))
            if len(pts) > 1:
                d.line(pts, fill=colour, width=2)
        for r in rows:
            if r[idx_s] is not None and LIFE[0] <= r[0] <= LIFE[1]:
                diffs['x' if k == 0 else 'y'].append(r[idx_m] - r[idx_s])
    # the inputs
    d.rectangle((xat(START[0]), 62, xat(START[1]), 66), fill=(230, 110, 110))
    for k, (gx, gy) in enumerate(COURSE):
        fr = GLIDE0 + k * GLIDE_STEP
        if gx or gy:
            d.line((xat(fr), 66, xat(fr), 490), fill=(70, 70, 92))
            d.text((xat(fr) + 2, 272), f'{gx:+d},{gy:+d}', fill=(200, 200, 220), font=fs)
        d.rectangle((xat(fr + 40) - 1, 62, xat(fr + 44) + 1, 66), fill=(230, 110, 110))
    d.rectangle((xat(LIFE[0]), 494, xat(LIFE[1]), 497), fill=(90, 200, 120))
    d.text((xat(LIFE[1]) + 4, 272), 'the ship destroyed (last MouseRead 2389)', fill=(230, 110, 110), font=fs)
    # legend
    ly = 505
    for colour, text in (((250, 210, 80), 'the driver: MouseX $FED9 / MouseY $FEDA'),
                         ((90, 200, 250), 'the ship record: ShipX $F36F-$F370 / ShipY $F371-$F372, in pixels')):
        d.line((ax0, ly + 6, ax0 + 30, ly + 6), fill=colour, width=3)
        d.text((ax0 + 38, ly), text, fill=K.TEXT, font=f)
        ly += 18
    same_x = sum(1 for v in diffs['x'] if v == 0)
    same_y = sum(1 for v in diffs['y'] if v == 0)
    ly += 2
    for text in ('grey lines: a glide (dx,dy of mouse_input, +dy = up); red ticks on top: a button held;',
                 f'green bar under the Y chart: the life, MouseRead called ({LIFE[0]}-{LIFE[1]})'):
        d.text((ax0, ly), text, fill=K.DIM, font=fs)
        ly += 15
    d.text((ax0 + 620, 505), f'in the life: X equal in {same_x} of {len(diffs["x"])} frames', fill=K.TEXT, font=f)
    d.text((ax0 + 620, 523), f'MouseY - ship Y: {min(diffs["y"])}..{max(diffs["y"])} lines '
           f'(0 in {same_y} frames)', fill=K.TEXT, font=f)
    # screens
    sy = 580
    for i, fr in enumerate(SHOTS):
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = read(s, fr, 0x4000, 6912)
        x = ax0 + i * 290
        img.paste(K.render_screen(mem).resize((256, 192)), (x, sy))
        r = rows[fr - F0]
        d.text((x, sy + 196), f'frame {fr}: mouse ({r[1]}, {r[2]}), ship ({r[3]}, {r[4]})', fill=K.TEXT, font=fs)
        d.line((x + 128, sy - 2, xat(fr), 490), fill=(80, 80, 100))
    for fr in range(1800, F1, 100):
        d.text((xat(fr) - 14, 492), str(fr), fill=K.DIM, font=fs)
    img.save(args.out)
    print(args.out, 'X equal', same_x, len(diffs['x']), 'Y equal', same_y, len(diffs['y']),
          'Y diff range', min(diffs['y']), max(diffs['y']), 'Y diffs', sorted(__import__('collections').Counter(diffs['y']).items()), 'X diffs', sorted(__import__('collections').Counter(diffs['x']).items()))


if __name__ == '__main__':
    main()

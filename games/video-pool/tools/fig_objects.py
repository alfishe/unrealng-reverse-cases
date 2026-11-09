#!/usr/bin/env python3
"""Figures of docs/07-objects.md: the 30 + 6 rack-in scripts as maps, and the ball block as a data sheet.

    python3 tools/fig_objects.py racks  --image work/mkgame/original.bin --table work/docs/vpC/shots/t707.png \
        --out docs/img/maps/racks.png
    python3 tools/fig_objects.py record --samples work/docs/vpC/w1-break.jsonl --frame 1117 \
        --out docs/img/objects/ball-record.png

`racks` decodes RackSets $A0C4 from the image (the six sets, six scripts each, the format of RackStep $A05E) and draws
every ball's path on the empty table of w1 frame 707 (kit/screen_shot.py, scale 2). `record` draws the 98-byte ball
block $8A88 and the two counters after it as read with TTD memory_at at one frame (work/docs/vpC/sample.py).
"""
import argparse
import json
import math
import os

from PIL import Image, ImageDraw, ImageFont

BG, TEXT, DIM = (24, 24, 28), (235, 235, 235), (170, 170, 175)
BALL_COLOURS = [(255, 255, 255), (220, 0, 0), (0, 40, 230), (200, 0, 200), (250, 140, 0), (0, 0, 0), (0, 150, 160)]


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def s8(v):
    return v - 256 if v > 127 else v


def word(m, a):
    return m[a] | m[a + 1] << 8


def decode(m, a):
    """One rack script: [('wait', n) | ('at', x, y) | ('move', n, dx, dy) | ('end',)], and its end address"""
    out = []
    while True:
        c = m[a]
        if c == 0:
            out.append(('end',))
            return out, a + 1
        if c == 1:
            out.append(('at', m[a + 1], m[a + 2]))
            a += 3
        elif c == 2:
            out.append(('move', m[a + 1], s8(m[a + 2]), s8(m[a + 3])))
            a += 4
        elif c == 3:
            out.append(('wait', m[a + 1]))
            a += 2
        else:
            raise SystemExit(f'unknown rack command {c} at ${a:04X}')


def run(script):
    """Frames as RackStep runs them: a list of (frame, x, y, visible) and the frame the script ends.
    A wait n costs n + 1 frames (the command's own frame, then n), a move n costs n frames (the first at once),
    a place costs one frame, the end one frame."""
    frame, x, y, pts = 0, None, None, []
    for cmd in script:
        if cmd[0] == 'wait':
            frame += cmd[1] + 1
        elif cmd[0] == 'at':
            frame += 1
            x, y = cmd[1], cmd[2]
            pts.append((frame, x, y, 'at'))
        elif cmd[0] == 'move':
            for _ in range(cmd[1]):
                frame += 1
                x, y = x + cmd[2], y + cmd[3]
                pts.append((frame, x, y, 'move'))
        else:
            frame += 1
    return pts, frame


def arrow(d, p, q, colour, width=3):
    d.line([p, q], fill=colour, width=width)
    ang = math.atan2(q[1] - p[1], q[0] - p[0])
    mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
    a, s = 0.5, 9
    d.polygon([(mx + s * math.cos(ang), my + s * math.sin(ang)),
               (mx - s * math.cos(ang - a), my - s * math.sin(ang - a)),
               (mx - s * math.cos(ang + a), my - s * math.sin(ang + a))], fill=colour)


def racks(args):
    m = open(args.image, 'rb').read()
    table = Image.open(args.table).convert('RGB').crop((0, 96, 512, 368))   # screen rows 48-183 at scale 2
    sets = [word(m, 0xA0C4 + 2 * i) for i in range(6)]
    pw, ph = 512, 272
    gap, top, cap = 8, 104, 74
    W = 2 * pw + 3 * gap
    H = top + 3 * (ph + cap + 34) + 10
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    fb, f, fs = font(20), font(15), font(14)
    d.text((gap, 8), 'Video Pool: the rack-in scripts of all six sets (RackSets $A0C4, RackStep $A05E)',
           font=fb, fill=TEXT)
    d.text((gap, 36), 'set = ((frame - 1) / 2) mod 6; each ball rolls 2 px a frame along its script and ends on its '
           'rack place', font=fs, fill=DIM)
    d.text((gap, 56), 'ring = a "place" (the start, or where a ball comes out of a pocket), arrow = a run of moves, '
           'disc = the rack', font=fs, fill=DIM)
    d.text((gap, 76), 'place; the paths of one set are drawn 2 px apart per ball so that shared lines stay visible', font=fs, fill=DIM)
    reached = {0: 'w1 frames 707-877 (frame 1)', 1: 'w1 frames 3 and 4'}
    for si, sp in enumerate(sets):
        col, row = si % 2, si // 2
        ox = gap + col * (pw + gap)
        oy = top + row * (ph + cap + 34)
        frames = f'frames {2 * si + 1}-{2 * si + 2}, {2 * si + 13}-{2 * si + 14}, ...'
        seen = reached.get(si, 'from the code: no recording reached it')
        d.text((ox, oy), f'set {si} at ${sp:04X}: {frames}', font=f, fill=TEXT)
        d.text((ox, oy + 18), seen, font=fs, fill=(120, 230, 120) if si in reached else (250, 170, 90))
        oy += 40
        panel = table.copy()
        pd = ImageDraw.Draw(panel)
        lengths = []
        for b in range(6):
            script, _ = decode(m, word(m, sp + 2 * b))
            pts, end = run(script)
            lengths.append((b + 1, script[0][1] if script[0][0] == 'wait' else 0, end))
            off = (b - 2.5) * 2

            def xy(x, y):
                return (2 * x + off, 2 * (y - 48) + off)
            colour = BALL_COLOURS[b + 1]
            prev = None
            run_start = None
            for k, (fr, x, y, kind) in enumerate(pts):
                if kind == 'at':
                    if prev is not None and run_start is not None:
                        arrow(pd, xy(*run_start), xy(*prev), colour)
                    if k == 0 or (x, y) != prev:
                        c = xy(x, y)
                        pd.ellipse([c[0] - 7, c[1] - 7, c[0] + 7, c[1] + 7], outline=colour, width=3)
                    run_start = (x, y)
                    prev = (x, y)
                    continue
                # a move: a new run starts when the direction changes
                if prev is not None and k >= 2 and pts[k - 1][3] == 'move':
                    px, py = pts[k - 2][1], pts[k - 2][2]
                    if (x - prev[0], y - prev[1]) != (prev[0] - px, prev[1] - py):
                        arrow(pd, xy(*run_start), xy(*prev), colour)
                        run_start = prev
                prev = (x, y)
            c = xy(*prev)
            pd.ellipse([c[0] - 8, c[1] - 8, c[0] + 8, c[1] + 8], fill=colour, outline=(0, 0, 0))
            pd.text((c[0] - 4, c[1] - 8), str(b + 1), font=fs, fill=(0, 0, 0) if b + 1 in (0,) else
                    ((255, 255, 255) if b + 1 != 4 else (0, 0, 0)))
        img.paste(panel, (ox, oy))
        leg = '  '.join(f'{b}:{w}' for b, w, e in lengths)
        leg2 = '  '.join(f'{b}:{e}' for b, w, e in lengths)
        d.text((ox, oy + ph + 4), 'first wait (frames)  ' + leg, font=fs, fill=DIM)
        d.text((ox, oy + ph + 22), 'script ends at frame ' + leg2, font=fs, fill=DIM)
        for b in range(6):
            d.rectangle([ox + 470 + 0, oy + ph + 46 + 0, ox + 470, oy + ph + 46], fill=BG)
    # legend strip
    y = H - 30
    x = gap
    d.text((x, y), 'balls:', font=f, fill=TEXT)
    x += 70
    for b in range(1, 7):
        d.ellipse([x, y + 1, x + 16, y + 17], fill=BALL_COLOURS[b], outline=(200, 200, 200))
        d.text((x + 22, y), str(b), font=f, fill=TEXT)
        x += 60
    d.text((x + 10, y), 'python3 tools/fig_objects.py racks (image work/mkgame/original.bin)', font=fs, fill=DIM)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    img.save(args.out)
    print(args.out, img.size)


FIELDS = [(0, 2, 'x 8.8', (60, 120, 200)), (2, 2, 'y 8.8', (60, 120, 200)), (4, 2, 'vx 8.8', (200, 120, 40)),
          (6, 2, 'vy 8.8', (200, 120, 40)), (8, 1, 'fx', (170, 60, 170)), (9, 1, 'fy', (170, 60, 170)),
          (10, 1, 'spr x', (70, 150, 70)), (11, 1, 'spr y', (70, 150, 70)), (12, 1, 'pkt', (150, 150, 40)),
          (13, 1, 'flags', (180, 60, 60))]


def s16(v):
    return v - 65536 if v > 32767 else v


def record(args):
    data = None
    for line in open(args.samples):
        dd = json.loads(line)
        if dd['frame'] == args.frame:
            data = bytes.fromhex(dd['hex'])
    if data is None:
        raise SystemExit(f'no sample at frame {args.frame}')
    W, cw, rh, left = 1050, 48, 34, 128
    top = 120
    H = top + 7 * rh + 90 + 8 * 30 + 150
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    fb, f, fs, fm = font(20), font(15), font(14), font(16)
    d.text((12, 8), f'Video Pool: the ball block $8A88 at w1 frame {args.frame} (after the first contact)', font=fb, fill=TEXT)
    d.text((12, 36), 'seven 14-byte records (cue ball, balls 1-6), each byte as the game holds it; '
           'little-endian words, fraction byte first', font=fs, fill=DIM)
    for off, n, name, colour in FIELDS:
        x = left + off * cw
        d.rectangle([x + 1, 64, x + n * cw - 2, 100], fill=colour)
        d.text((x + 4, 66), f'+{off}' if n == 1 else f'+{off}/+{off + 1}', font=fs, fill=(255, 255, 255))
        d.text((x + 4, 82), name, font=fs, fill=(255, 255, 255))
    names = ['cue  $8A88', 'ball 1 $8A96', 'ball 2 $8AA4', 'ball 3 $8AB2', 'ball 4 $8AC0', 'ball 5 $8ACE',
             'ball 6 $8ADC']
    for i in range(7):
        y = top + i * rh
        r = data[14 * i:14 * i + 14]
        d.text((10, y + 8), names[i], font=fs, fill=TEXT)
        for k in range(14):
            colour = next(c for o, n, _, c in FIELDS if o <= k < o + n)
            x = left + k * cw
            d.rectangle([x + 1, y + 2, x + cw - 2, y + rh - 3], fill=tuple(v // 3 for v in colour),
                        outline=colour)
            d.text((x + 11, y + 8), f'{r[k]:02X}', font=fm, fill=TEXT)
        x = left + 14 * cw + 10
        moving = 'rolling' if r[13] & 0x40 else 'at rest'
        d.text((x, y + 8), f'({r[1] + r[0] / 256:.2f}, {r[3] + r[2] / 256:.2f}) {moving}', font=fs, fill=DIM)
    y = top + 7 * rh + 10
    tail = data[98:100]
    d.text((10, y), 'then', font=fs, fill=TEXT)
    d.text((left, y), f'OtherPlayerBalls $8AEA: the same 7 x 14 bytes of the other player (swapped on the turn '
           f'change)', font=fs, fill=DIM)
    if len(data) >= 100:
        pass
    y += 22
    d.text((left, y), f'FrictionTurn $8B4C = {data[196] if len(data) > 196 else "?"}   EventCount $8B4D = '
           f'{data[197] if len(data) > 197 else "?"}', font=fs, fill=DIM)
    # decoding the cue ball
    r = data[0:14]
    y += 40
    d.text((10, y), 'The cue ball decoded:', font=f, fill=TEXT)
    lines = [
        f'+0/+1  {r[0]:02X} {r[1]:02X}  x  = ${r[1]:02X}{r[0]:02X} / 256 = {r[1]} + {r[0]}/256 = '
        f'{r[1] + r[0] / 256:.3f} px (the centre)',
        f'+2/+3  {r[2]:02X} {r[3]:02X}  y  = ${r[3]:02X}{r[2]:02X} / 256 = {r[3] + r[2] / 256:.3f} px from the '
        f'screen top',
        f'+4/+5  {r[4]:02X} {r[5]:02X}  vx = ${r[5]:02X}{r[4]:02X} = {s16(r[4] | r[5] << 8)} / 256 = '
        f'{s16(r[4] | r[5] << 8) / 256:+.3f} px a tick',
        f'+6/+7  {r[6]:02X} {r[7]:02X}  vy = ${r[7]:02X}{r[6]:02X} = {s16(r[6] | r[7] << 8)} / 256 = '
        f'{s16(r[6] | r[7] << 8) / 256:+.3f} px a tick',
        f'+8 +9  {r[8]:02X} {r[9]:02X}  friction steps {s8(r[8]):+d}, {s8(r[9]):+d} / 256 px a tick, '
        f'added to vx, vy every tick',
        f'+10/11 {r[10]:02X} {r[11]:02X}  the sprite drawn at ({r[10]}, {r[11]}) = the centre - 7 '
        f'at the last redraw',
        f'+12    {r[12]:02X}     pocket {r[12]} (0 = none; 1-6 clockwise from the top left)',
        f'+13    {r[13]:02X}     flags {r[13]:08b}: bit 7 on the table, 6 moving, 5 potted, 4 to be redrawn',
    ]
    for k, line in enumerate(lines):
        d.text((24, y + 26 + k * 26), line, font=fs, fill=TEXT)
    y += 26 + len(lines) * 26 + 16
    d.text((10, y), f'The point: one byte pair is one 8.8 number; the pixel byte alone serves every whole-pixel '
           f'test (tables,', font=fs, fill=TEXT)
    d.text((10, y + 20), 'cushions, pockets), the fraction only carries the motion.  python3 tools/fig_objects.py '
           f'record --frame {args.frame}', font=fs, fill=TEXT)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    img = img.crop((0, 0, W, y + 50))
    img.save(args.out)
    print(args.out, img.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['racks', 'record'])
    p.add_argument('--image')
    p.add_argument('--table')
    p.add_argument('--samples')
    p.add_argument('--frame', type=int)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    {'racks': racks, 'record': record}[args.what](args)


if __name__ == '__main__':
    main()

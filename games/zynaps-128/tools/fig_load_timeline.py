#!/usr/bin/env python3
"""Doc 03 figure: the disk as a picture and the load as a time line, from recording c1.

    python3 tools/fig_load_timeline.py --work work/z128A/c1 --out docs/img/load/load-timeline.png

Top: the 137 sectors of ZYNAPS.B as they lie on the TRD (16 sectors a track, from track 1 sector 0), coloured by what
they carry, and boot.B at track 9 sector 9. Middle: the screen at the moments of docs/03 3.7. Bottom: how many of
ZYNAPS.B's sectors are in memory at each frame of c1, measured with time_travel memory_at (exact) by comparing
memory with the file's own bytes: sector 0 = the BASIC at $5D3B (from $5D42: the loader rewrites its first bytes), sector 1 = the depacker at $5B00, then the sectors
of each packed block counted from $6000 while their bytes are still there (the move then overwrites them; block
2's last frame, 2905, is read at T 56500, just before its move at 56587). The
coloured bands under it are the stages with their first frames (docs/03 3.7).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PARTS = [  # first sector, count, colour, label
    (0, 1, (230, 200, 80), 'BASIC + loader'),
    (1, 1, (230, 120, 80), 'depacker'),
    (2, 56, (90, 150, 250), 'block 1: the intro (Hrust 1)'),
    (58, 79, (90, 200, 120), 'block 2: the game (Hrust 1)'),
]
STAGES = [  # first frame, last frame, colour, label
    (1602, 1870, (70, 70, 90), '128 menu, TR-DOS, RUN'),
    (1870, 2051, (120, 90, 160), 'boot.B list'),
    (2051, 2125, (70, 110, 190), 'read 1'),
    (2125, 2183, (60, 150, 90), 'unpack 1'),
    (2183, 2780, (200, 150, 60), 'intro: title, options, Hewson'),
    (2780, 2905, (70, 110, 190), 'read 2'),
    (2905, 2976, (60, 150, 90), 'unpack 2'),
    (2976, 3302, (110, 110, 120), 'wait for a key'),
    (3302, 3314, (220, 90, 90), 'set-up'),
    (3314, 3460, (150, 80, 80), 'game menu'),
]
SHOTS = [(1700, 'TR-DOS'), (1990, 'boot.B list'), (2100, 'reading block 1'), (2590, 'title'), (2740, 'options'),
         (2850, 'Hewson, loading'), (3460, 'game menu')]
F0, F1 = 1600, 3470


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def read(s, frame, lo, n, t=None):
    a = {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': lo, 'length': n}
    if t is not None:
        a['tinframe'] = t
    r = s.call('time_travel', a, ok=False)
    if not r.structured or not r.structured.get('exact'):
        raise SystemExit(f'memory_at {frame} ${lo:04X}: {r.text[:200]}')
    return bytes.fromhex(r.structured['hex'])


def leading_sectors(mem, ref):
    n = 0
    while n < len(ref) and mem[n] == ref[n]:
        n += 1
    return n // 256


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = session(args.work)
    parts = os.path.join(CASE, 'work', 'parts')
    basic = open(os.path.join(parts, 'zynaps-b-sector0.bin'), 'rb').read()[:168]
    depacker = open(os.path.join(parts, 'depacker-5b00.bin'), 'rb').read()
    blk1 = open(os.path.join(parts, 'blk1-packed.bin'), 'rb').read() + open(os.path.join(parts, 'blk1-trailer.bin'), 'rb').read()
    blk2 = open(os.path.join(parts, 'blk2-packed.bin'), 'rb').read() + open(os.path.join(parts, 'blk2-trailer.bin'), 'rb').read()
    # the arrival curve
    curve = []
    best1 = best2 = 0
    for fr in range(2030, 2990):
        mem_b = read(s, fr, 0x5D42, 168 - 7)
        mem_d = read(s, fr, 0x5B00, 256)
        n = (1 if mem_b == basic[7:] else 0)
        n += 1 if (n and mem_d == depacker) else 0
        if fr < 2780:
            if fr <= 2125:
                best1 = leading_sectors(read(s, fr, 0x6000, len(blk1)), blk1)
            n += best1 if n == 2 else 0
        else:
            n = 2 + 56
            if fr <= 2905:
                best2 = leading_sectors(read(s, fr, 0x6000, len(blk2), 56500 if fr == 2905 else None), blk2)
            n += best2
        curve.append((fr, n))
    f, fb, fs, ft = K.font(12), K.font(14), K.font(11), K.font(17)
    W, H = 1240, 760
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 8), 'From the disk to the game: 137 sectors, two Hrust 1 blocks, 1 700 frames (34 s) from the 128 menu',
           fill=K.TEXT, font=ft)
    d.text((10, 32), 'c1, Pentagon 128 + TR-DOS, the TRD, from power-on. The disk (top), the screens, and the sectors of '
           'ZYNAPS.B in memory per frame (bottom, measured).', fill=K.DIM, font=f)
    # the disk: tracks 1-9 as rows of 16 sectors
    dx, dy, cw, ch = 70, 62, 34, 14

    for track in range(1, 10):
        y = dy + (track - 1) * (ch + 2)
        d.text((dx - 56, y), f'track {track}', fill=K.DIM, font=fs)
        for sec in range(16):
            x = dx + sec * (cw + 2)
            idx = (track - 1) * 16 + sec
            colour = (40, 40, 50)
            for first, count, c, _ in PARTS:
                if first <= idx < first + count:
                    colour = c
            if track == 9 and 9 <= sec < 13:
                colour = (200, 110, 230)
            d.rectangle((x, y, x + cw, y + ch), fill=colour)
    lx = dx + 16 * (cw + 2) + 20
    for i, (first, count, c, label) in enumerate(PARTS + [(None, 4, (200, 110, 230), 'boot.B (TRD only)')]):
        y = dy + i * 22
        d.rectangle((lx, y, lx + 14, y + 12), fill=c)
        sect = f'sector {first}' if count == 1 else (f'sectors {first}-{first + count - 1}' if first is not None
                                                       else 'track 9, sectors 9-12')
        d.text((lx + 22, y - 2), f'{label}: {sect}', fill=K.TEXT, font=f)
    d.text((lx, dy + 5 * 22 + 6), 'ZYNAPS.B: 137 sectors from track 1 sector 0 (TR-DOS LOAD reads only sector 0;',
           fill=K.DIM, font=fs)
    d.text((lx, dy + 5 * 22 + 22), 'the loader reads 1, then 56, then 79 from where TR-DOS stopped, $5CF4)',
           fill=K.DIM, font=fs)
    # the time axis
    ax0, ax1 = 70, W - 20

    def xat(fr):
        return ax0 + (ax1 - ax0) * (fr - F0) // (F1 - F0)
    # screens
    sy = 230
    tw, th = 160, 120
    for i, (fr, label) in enumerate(SHOTS):
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = read(s, fr, 0x4000, 6912)
        thumb = K.render_screen(mem).resize((tw, th))
        x = 10 + i * (tw + 12)
        img.paste(thumb, (x, sy))
        d.text((x, sy + th + 3), f'{fr}: {label}', fill=K.TEXT, font=fs)
        d.line((x + tw // 2, sy + th + 18, xat(fr), 420), fill=(90, 90, 110), width=1)
    # the curve
    cy0, cy1 = 430, 640
    d.rectangle((ax0, cy0, ax1, cy1), outline=(60, 60, 75))
    for v in (0, 58, 137):
        y = cy1 - (cy1 - cy0) * v // 137
        d.line((ax0, y, ax1, y), fill=(40, 40, 55))
        d.text((ax0 - 30, y - 7), str(v), fill=K.DIM, font=fs)
    d.text((10, cy0 - 18), 'sectors of ZYNAPS.B in memory (measured every frame)', fill=K.TEXT, font=f)
    pts = [(xat(fr), cy1 - (cy1 - cy0) * n // 137) for fr, n in curve]
    d.line([(xat(F0), cy1), (xat(2030), cy1)] + pts + [(xat(F1), pts[-1][1])], fill=(250, 220, 120), width=2)
    # the rates
    def rate(lo, hi, f0, f1):
        return (hi - lo) / ((f1 - f0) / 50)
    r1 = [fr for fr, n in curve if n >= 58]
    r2 = [fr for fr, n in curve if n >= 137]
    first1 = [fr for fr, n in curve if n > 2]
    first2 = [fr for fr, n in curve if n > 58]
    if r1 and first1:
        d.text((xat(first1[0]) + 4, cy0 + 40), f'block 1: 56 sectors in {r1[0] - first1[0]} frames '
               f'({rate(0, 56, first1[0], r1[0]):.1f} sectors/s)', fill=(140, 180, 255), font=f)
    if r2 and first2:
        d.text((xat(first2[0]) - 470, cy0 + 8), f'block 2: 79 sectors in {r2[0] - first2[0]} frames '
               f'({rate(0, 79, first2[0], r2[0]):.1f} sectors/s)', fill=(140, 230, 160), font=f)
    # stage bands
    by = cy1 + 10
    for i, (a, b, c, label) in enumerate(STAGES):
        d.rectangle((xat(a), by, xat(b), by + 16), fill=c)
        ty = by + 20 + (i % 2) * 16
        d.text((xat(a) + 2, ty), f'{a} {label}', fill=K.TEXT, font=fs)
    for fr in range(1700, F1, 100):
        d.text((xat(fr) - 14, H - 22), str(fr), fill=K.DIM, font=fs)
        d.line((xat(fr), H - 26, xat(fr), H - 30), fill=K.DIM)
    d.text((ax1 - 140, H - 40), 'c1 frame (50 a second)', fill=K.DIM, font=fs)
    img.save(args.out)
    print(args.out, img.size)
    print('first block 1 sector', first1[:1], 'all 58 at', r1[:1], 'first block 2', first2[:1], 'all 137 at', r2[:1])


if __name__ == '__main__':
    main()

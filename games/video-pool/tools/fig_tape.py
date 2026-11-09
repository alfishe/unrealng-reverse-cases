#!/usr/bin/env python3
"""Doc 03's tape figure: the five data blocks of `Video Pool.tzx` on a time line, where each one lands in memory,
and the turbo block's pulse lengths against the ROM's.

    python3 tools/fig_tape.py [--tzx work/media/tzx/Video\\ Pool.tzx] [--out docs/img/load/tape.png]

The block times, pauses, pulse lengths and destinations come from tools/tzxblocks.py list (parsed, not typed in).
"""
import argparse
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
LEFT = 20
RIGHT = WIDTH - 20
COLOURS = {1: (90, 140, 220), 2: (120, 190, 120), 3: (90, 140, 220), 4: (230, 170, 70), 5: (220, 90, 90)}
NAMES = {1: 'header', 2: 'BASIC', 3: 'header', 4: 'loader', 5: 'the game (turbo)'}


def blocks(tzx):
    out = subprocess.run([sys.executable, os.path.join(HERE, 'tzxblocks.py'), 'list', tzx], check=True,
                         capture_output=True, text=True).stdout
    found = []
    for line in out.splitlines():
        m = re.match(r'\s*(\d+) @\s+\d+ id (1[01]) ', line)
        if not m:
            continue
        num = int(m.group(1))
        field = {k: int(v) for k, v in re.findall(r'(\w+)=(\d+)', line)}
        secs = float(re.search(r'\| ([\d.]+) s$', line).group(1))
        pause = int(re.search(r'pause (\d+) ms', line).group(1)) / 1000
        data = int(re.search(r'len (\d+)', line).group(1))
        start = re.search(r'start \d+ \(\$([0-9A-F]+)\)', line)
        found.append(dict(num=num, secs=secs, pause=pause, len=data, pulses=field, line=line,
                          start=int(start.group(1), 16) if start else None))
    return found


def text(d, xy, s, size=13, fill=K.TEXT, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--tzx', default=os.path.join(CASE, 'work', 'media', 'tzx', 'Video Pool.tzx'))
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'tape.png'))
    a = ap.parse_args()
    bl = blocks(a.tzx)
    img = Image.new('RGB', (WIDTH, 730), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    text(d, (LEFT, 10), 'Video Pool.tzx: five data blocks, 121 s of signal, 125 s with the pauses, the game in one turbo block', 16)

    # Panel A: the time line, the last pause cut (it is silence after the game)
    y0 = 80
    text(d, (LEFT, y0 - 40), 'A. the tape in seconds (each block, then its pause; the 39.6 s silence after block 5 left out)',
         13, K.DIM)
    total = sum(b['secs'] + b['pause'] for b in bl[:-1]) + bl[-1]['secs']
    scale = (RIGHT - LEFT) / total
    t = 0.0
    spans = {}
    for b in bl:
        x1 = LEFT + t * scale
        x2 = LEFT + (t + b['secs']) * scale
        d.rectangle([x1, y0, x2, y0 + 40], fill=COLOURS[b['num']], outline=K.TEXT)
        spans[b['num']] = (x1, x2, t)
        t += b['secs'] + (b['pause'] if b is not bl[-1] else 0)
    # labels: the four small blocks fan out under the line, block 5 inside its bar
    lab_y = y0 + 52
    for i, b in enumerate(bl[:-1]):
        x1, x2, t0 = spans[b['num']]
        lx = LEFT + 8 + i * 118
        d.line([(x1 + x2) / 2, y0 + 40, lx + 30, lab_y], fill=K.DIM)
        text(d, (lx, lab_y + 2), f"{b['num']} {NAMES[b['num']]}", 13)
        text(d, (lx, lab_y + 20), f"{b['secs']:.2f} s, {b['len'] - 2} B", 12, K.DIM)
    x1, x2, t0 = spans[5]
    text(d, ((x1 + x2) / 2, y0 + 20), f"5 the game: 25 000 bytes, {bl[-1]['secs']:.2f} s at the turbo timings",
         14, (255, 255, 255), 'mm')
    for s in range(0, int(total) + 1, 10):
        x = LEFT + s * scale
        d.line([x, y0 + 40, x, y0 + 46], fill=K.DIM)
        if s % 20 == 0:
            text(d, (x, y0 - 4), f'{s} s', 11, K.DIM, 'mb')
    text(d, (560, lab_y + 2), f'block 5 starts at {t0:.1f} s', 12, K.DIM)
    text(d, (560, lab_y + 20), f'and ends at {total:.1f} s = {total * 3500000 / 69888:.0f} frames of the 48K', 12, K.DIM)

    # Panel B: where each block lands in the 64K
    yb = 205
    text(d, (LEFT, yb), 'B. where the data lands: the 48K memory map, 0000 to FFFF hex (colours as in A)', 13, K.DIM)
    my = yb + 70
    mscale = (RIGHT - LEFT) / 0x10000

    def mx(addr):
        return LEFT + addr * mscale
    d.rectangle([mx(0), my, mx(0x4000), my + 34], fill=(70, 70, 80), outline=K.DIM)
    text(d, ((mx(0) + mx(0x4000)) / 2, my + 17), 'ROM 0000-3FFF', 13, K.TEXT, 'mm')
    d.rectangle([mx(0x4000), my, mx(0x5B00), my + 34], fill=(55, 55, 95), outline=K.DIM)
    text(d, ((mx(0x4000) + mx(0x5B00)) / 2, my + 17), 'screen', 12, K.TEXT, 'mm')
    d.rectangle([mx(0x5B00), my, mx(0x8000), my + 34], fill=(45, 45, 50), outline=K.DIM)
    regions = [(2, 0x5CCB, 0x5CCB + 44, 'BASIC'), (4, 0xF000, 0xF100, 'F000-F0FF'),
               (5, 0x8000, 0xE1A8, '8000-E1A7: the game image')]
    for num, lo, hi, name in regions:
        w = max(mx(hi) - mx(lo), 6)
        d.rectangle([mx(lo), my, mx(lo) + w, my + 34], fill=COLOURS[num], outline=K.TEXT)
        if num == 5:
            text(d, ((mx(lo) + mx(hi)) / 2, my + 17), name, 13, (255, 255, 255), 'mm')
        else:
            text(d, (mx(lo) + w / 2, my + 48), name, 12, K.TEXT, 'ma')
        # the block number above its destination, in the block's colour
        d.polygon([(mx(lo) + w / 2 - 6, my - 12), (mx(lo) + w / 2 + 6, my - 12), (mx(lo) + w / 2, my - 2)],
                  fill=COLOURS[num])
        text(d, (mx(lo) + w / 2, my - 16), f'block {num}', 13, COLOURS[num], 'mb')
    text(d, (mx(0x5CCB) + 4, my + 66), 'RAMTOP 7FFF (CLEAR 32767)', 12, K.DIM)
    text(d, (LEFT, my + 90), 'The headers (blocks 1, 3) load nowhere: the ROM reads them into its work space and takes '
         'the type, start and length.', 12, K.DIM)

    # Panel C: the pulse lengths, ROM blocks against the turbo block
    yc = 410
    text(d, (LEFT, yc), 'C. pulse lengths in T states (3.5 MHz): blocks 1-4 at the ROM timings, block 5 at the '
         "loader's", 13, K.DIM)
    rom = bl[0]['pulses']
    tur = bl[-1]['pulses']
    rows = [('pilot', 'pilot'), ('sync 1', 'sync1'), ('sync 2', 'sync2'), ('zero bit', 'zero'), ('one bit', 'one')]
    bscale = 700 / 2200
    for i, (name, key) in enumerate(rows):
        y = yc + 30 + i * 46
        text(d, (LEFT, y + 9), name, 13)
        for j, (src, col, tag) in enumerate(((rom, (90, 140, 220), 'ROM'), (tur, (220, 90, 90), 'turbo'))):
            v = src[key]
            yy = y + j * 19
            d.rectangle([LEFT + 110, yy, LEFT + 110 + v * bscale, yy + 15], fill=col)
            text(d, (LEFT + 116 + v * bscale, yy + 1), f'{tag} {v} T', 12)
    tz, to = tur['zero'], tur['one']
    rz, ro = rom['zero'], rom['one']
    text(d, (LEFT + 110, yc + 270), f'A turbo bit takes {tz / rz * 100:.0f} % of a ROM bit ({tz} / {rz}, {to} / {ro}): '
         f'25 000 bytes in {bl[-1]["secs"]:.0f} s instead of about {bl[-1]["secs"] * rz / tz:.0f} s.', 13)
    text(d, (LEFT + 110, yc + 290), 'Pilot: ROM 8063 pulses for a header, 3223 for data; turbo 3240.', 13)
    img.save(a.out)
    print(f'{a.out}: {img.width} x {img.height}')


if __name__ == '__main__':
    main()

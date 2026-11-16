#!/usr/bin/env python3
"""Graphics as stored: a memory range drawn as bitmaps W bytes wide (a byte's bit 7 on the left, ink black), cut into
columns of N rows, each column labelled with its first address; for finding sprites in the image.

    python3 tools/gfx_strips.py IMAGE.cpu.bin OUT.png START END --width 3 [--rows 64] [--scale 3] [--columns 12]"""
import argparse
from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument('image')
ap.add_argument('out')
ap.add_argument('start')
ap.add_argument('end')
ap.add_argument('--width', type=int, default=3)
ap.add_argument('--rows', type=int, default=64)
ap.add_argument('--scale', type=int, default=3)
ap.add_argument('--columns', type=int, default=12)
a = ap.parse_args()
img = open(a.image, 'rb').read()
lo, hi = int(a.start, 16), int(a.end, 16)
w, n, s = a.width, a.rows, a.scale
chunk = w * n
cols = (hi - lo + chunk - 1) // chunk
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 14)
cw, chh = max(w * 8 * s + 10, 62), n * s + 22
nrow = (cols + a.columns - 1) // a.columns
out = Image.new('RGB', (min(cols, a.columns) * cw, nrow * chh), 'white')
d = ImageDraw.Draw(out)
for c in range(cols):
    base = lo + c * chunk
    x0, y0 = (c % a.columns) * cw, (c // a.columns) * chh
    d.text((x0 + 2, y0 + 2), f'${base:04X}', fill='black', font=font)
    for r in range(n):
        for b in range(w):
            addr = base + r * w + b
            if addr >= hi:
                continue
            v = img[addr]
            for k in range(8):
                if v & (0x80 >> k):
                    d.rectangle([x0 + (b * 8 + k) * s, y0 + 20 + r * s, x0 + (b * 8 + k) * s + s - 1,
                                 y0 + 20 + r * s + s - 1], fill='black')
    d.rectangle([x0, y0 + 19, x0 + w * 8 * s, y0 + 20 + n * s], outline=(170, 170, 170))
out.save(a.out)
print(a.out, out.size)

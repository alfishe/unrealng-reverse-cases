#!/usr/bin/env python3
"""A sprite sheet from the image: each sprite given as ADDR:WIDTH:ROWS:LABEL (hex address, width in bytes, rows),
drawn as stored (bit 7 on the left, ink black) at --scale, labelled with its address and size.

    python3 tools/sprite_sheet.py IMAGE.cpu.bin OUT.png 'D264:3:55:player' [...] [--scale 3] [--columns 6]"""
import argparse
from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument('image')
ap.add_argument('out')
ap.add_argument('sprites', nargs='+')
ap.add_argument('--scale', type=int, default=3)
ap.add_argument('--columns', type=int, default=6)
a = ap.parse_args()
img = open(a.image, 'rb').read()
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 14)
spr = []
for t in a.sprites:
    addr, w, h, label = t.split(':', 3)
    spr.append((int(addr, 16), int(w), int(h), label))
s = a.scale
cw = max(max(w * 8 * s for _, w, _, _ in spr) + 14, 150)
ch = max(h * s for _, _, h, _ in spr) + 44
rows = (len(spr) + a.columns - 1) // a.columns
out = Image.new('RGB', (min(len(spr), a.columns) * cw, rows * ch), 'white')
d = ImageDraw.Draw(out)
for i, (addr, w, h, label) in enumerate(spr):
    x0, y0 = (i % a.columns) * cw, (i // a.columns) * ch
    d.text((x0 + 4, y0 + 2), label, fill='black', font=font)
    d.text((x0 + 4, y0 + 18), f'${addr:04X}, {w} x {h}', fill=(90, 90, 90), font=font)
    for r in range(h):
        for b in range(w):
            v = img[addr + r * w + b]
            for k in range(8):
                if v & (0x80 >> k):
                    X, Y = x0 + 6 + (b * 8 + k) * s, y0 + 38 + r * s
                    d.rectangle([X, Y, X + s - 1, Y + s - 1], fill='black')
    d.rectangle([x0 + 5, y0 + 37, x0 + 6 + w * 8 * s, y0 + 38 + h * s], outline=(180, 180, 180))
out.save(a.out)
print(a.out, out.size)

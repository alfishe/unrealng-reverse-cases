#!/usr/bin/env python3
"""A sheet of crops from recorded screens (512 x 384, the Spectrum screen at 2x): each crop a labelled cell.

    python3 tools/crop_sheet.py OUT.png 'SCREEN.png:X0,Y0,X1,Y1:LABEL' [...] [--scale 1] [--columns 6]

The boxes are in the screen's 512 x 384 pixels; the label is drawn above the cell, 13 px."""
import argparse
from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument('out')
ap.add_argument('crops', nargs='+')
ap.add_argument('--scale', type=float, default=1)
ap.add_argument('--columns', type=int, default=6)
a = ap.parse_args()
cells = []
for c in a.crops:
    path, box, label = c.split(':', 2)
    im = Image.open(path).convert('RGB').crop(tuple(int(v) for v in box.split(',')))
    if a.scale != 1:
        im = im.resize((round(im.width * a.scale), round(im.height * a.scale)), Image.NEAREST)
    cells.append((im, label))
try:
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 15)
except OSError:
    font = ImageFont.load_default()
cw = max(max(im.width for im, _ in cells), 150) + 12
ch = max(im.height for im, _ in cells) + 26
rows = (len(cells) + a.columns - 1) // a.columns
sheet = Image.new('RGB', (min(len(cells), a.columns) * cw, rows * ch), 'white')
d = ImageDraw.Draw(sheet)
for i, (im, label) in enumerate(cells):
    x, y = (i % a.columns) * cw, (i // a.columns) * ch
    d.text((x + 4, y + 3), label, fill='black', font=font)
    sheet.paste(im, (x + 6, y + 22))
sheet.save(a.out)
print(a.out, sheet.size)

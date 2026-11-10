#!/usr/bin/env python3
"""A contact sheet of a recording's screenshots: python3 tools/sheet.py SCREENS_DIR OUT.png FROM TO STEP [COLS]"""
import sys
from PIL import Image, ImageDraw
d, out, a, b, s = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:6])
cols = int(sys.argv[6]) if len(sys.argv) > 6 else 4
fs = list(range(a, b, s))
S = Image.new('RGB', (256 * cols, 200 * ((len(fs) + cols - 1) // cols)))
dr = ImageDraw.Draw(S)
for i, f in enumerate(fs):
    x, y = (i % cols) * 256, (i // cols) * 200
    S.paste(Image.open(f'{d}/{f:06d}.png').convert('RGB'), (x, y))
    dr.text((x + 2, y + 191), str(f), fill=(255, 255, 0))
S.save(out)

#!/usr/bin/env python3
"""The game's other graphics from the entry image (tools/image.py), drawn as they are stored:

- the text font: characters 32-118 at `$D200 + 8 x (code - 32)` (the same bytes as `$D100 + 8 x code`) (the printer `$8E3A`; the draft map of `c1g`);
- the 16 x 16 cursor at `$9A37` (32 bytes, two bytes a row; drawn by `$9A11`);
- the LEVEL digits at `$88B0` (8 bytes a digit, a byte a pixel row; `$843C` copies them to the LEVEL field).

    python3 tools/gfx_sheet.py docs/img/sprites/font.png
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from level_maps import IMAGE  # noqa: E402

W, B = (230, 230, 230), (0, 0, 0)


def bits(px, x0, y0, rows, width_bytes, s):
    for y, row in enumerate(rows):
        for i in range(width_bytes):
            for x in range(8):
                if row[i] & (0x80 >> x):
                    for dy in range(s):
                        for dx in range(s):
                            px[x0 + (i * 8 + x) * s + dx, y0 + y * s + dy] = W


def main():
    img = open(IMAGE, 'rb').read()
    s = 3
    sheet = Image.new('RGB', (900, 225), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    px = sheet.load()
    d.text((8, 4), 'font $D200 + 8 x (code - 32), codes 32-118 (printer $8E3A)', fill=W)
    for i, code in enumerate(range(32, 119)):
        x0, y0 = 8 + (i % 29) * 30, 22 + (i // 29) * 34
        c = img[0xD200 + 8 * (code - 32):0xD208 + 8 * (code - 32)]
        bits(px, x0, y0, [[b] for b in c], 1, s)
    d.text((8, 132), 'cursor $9A37 (16 x 16, $9A11)', fill=W)
    cur = img[0x9A37:0x9A57]
    bits(px, 8, 150, [cur[i:i + 2] for i in range(0, 32, 2)], 2, 4)
    d.text((220, 132), 'LEVEL digits $88B0 (0-9, 8 bytes each, $843C)', fill=W)
    for n in range(10):
        dg = img[0x88B0 + 8 * n:0x88B8 + 8 * n]
        bits(px, 220 + n * 50, 150, [dg[k:k + 1] for k in range(8)], 1, 4)
    sheet.save(sys.argv[1])


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The cell tiles drawn from the data: each cell code below `$5D` is four 8 x 8 characters from the table `$8200`
(4 bytes a code: top left, top right, bottom left, bottom right, as `$8960` puts them in the map `$E000`), each
character 8 bytes at `$D700 + 8 x char` and its colour at `$DF00 + char` (as `$8A09` draws them). `$8374` onward is
other data (variables from `$8374`, the per-level table at `$8385`), so `$5D` is the end of the table.

    python3 tools/tile_sheet.py docs/img/sprites/tiles.png [--scale 3]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from level_maps import IMAGE, PAL  # noqa: E402


def char(img, n, px, x0, y0):
    a = img[0xDF00 + n]
    ink, paper = PAL[(a & 7) + (8 if a & 64 else 0)], PAL[((a >> 3) & 7) + (8 if a & 64 else 0)]
    for k in range(8):
        b = img[0xD700 + 8 * n + k]
        for x in range(8):
            px[x0 + x, y0 + k] = ink if b & (0x80 >> x) else paper


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=3)
    args = ap.parse_args()
    img = open(IMAGE, 'rb').read()
    cols, cw, ch = 16, 16 * args.scale + 10, 16 * args.scale + 22
    sheet = Image.new('RGB', (cols * cw, 6 * ch), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for code in range(0x5D):
        t = Image.new('RGB', (16, 16))
        px = t.load()
        c = img[0x8200 + 4 * code:0x8204 + 4 * code]
        for i, (x, y) in enumerate([(0, 0), (8, 0), (0, 8), (8, 8)]):
            char(img, c[i], px, x, y)
        x0, y0 = (code % cols) * cw + 5, (code // cols) * ch + 18
        sheet.paste(t.resize((16 * args.scale, 16 * args.scale), Image.NEAREST), (x0, y0))
        d.text((x0, y0 - 14), f'${code:02X}', fill=(230, 230, 230))
    sheet.save(args.out)


if __name__ == '__main__':
    main()

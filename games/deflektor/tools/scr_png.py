#!/usr/bin/env python3
"""A Spectrum screen (6912 bytes: a recording's screens/NNNNNN.scr, or a 64 K image's `$4000-$5AFF`) as a PNG.

    python3 tools/scr_png.py IN.scr OUT.png [--scale 2] [--offset 0x4000] [--flash]
"""
import argparse
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from level_maps import PAL  # noqa: E402


def screen(data, flash=False):
    im = Image.new('RGB', (256, 192))
    px = im.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for c in range(32):
            b = data[row + c]
            a = data[6144 + (y >> 3) * 32 + c]
            br = 8 if a & 64 else 0
            ink, paper = PAL[(a & 7) + br], PAL[((a >> 3) & 7) + br]
            if flash and a & 128:
                ink, paper = paper, ink
            for x in range(8):
                px[c * 8 + x, y] = ink if b & (0x80 >> x) else paper
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=2)
    ap.add_argument('--offset', type=lambda x: int(x, 0), default=0)
    ap.add_argument('--flash', action='store_true')
    a = ap.parse_args()
    d = open(a.src, 'rb').read()[a.offset:a.offset + 6912]
    screen(d, a.flash).resize((256 * a.scale, 192 * a.scale), Image.NEAREST).save(a.out)


if __name__ == '__main__':
    main()

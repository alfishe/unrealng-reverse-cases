#!/usr/bin/env python3
"""Find where a sprite seen on a recorded screen is stored: each pixel row of the box (Spectrum coordinates, ink
taken as dark pixels of the 512 x 384 screenshot) is searched in the image's range at all 8 bit shifts; rows found at
addresses in step W (the stored width in bytes) vote for the sprite's first row. Prints the best (start, width).

    python3 tools/find_sprite.py SHOT.png IMAGE.cpu.bin X0 Y0 X1 Y1 [--range B306-E2C0] [--mirror]"""
import argparse
from collections import Counter
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('shot')
ap.add_argument('image')
ap.add_argument('box', nargs=4, type=int)
ap.add_argument('--range', default='B306-E2C0')
ap.add_argument('--mirror', action='store_true', help='search the box mirrored left to right (a sprite drawn flipped)')
a = ap.parse_args()
im = Image.open(a.shot).convert('RGB')
img = open(a.image, 'rb').read()
lo, hi = (int(v, 16) for v in a.range.split('-'))
G = img[lo:hi]
x0, y0, x1, y1 = a.box
votes = Counter()
for y in range(y0, y1):
    bits = [1 if sum(im.getpixel((2 * x, 2 * y))) < 100 else 0 for x in range(x0, x1)]
    if a.mirror:
        bits = bits[::-1]
    if bits.count(1) < 4:
        continue
    f = bits.index(1)
    l = len(bits) - 1 - bits[::-1].index(1)
    seg = bits[f:l + 1]
    if len(seg) < 9:
        continue
    for sh in range(8):
        b = [0] * sh + seg
        b += [0] * ((-len(b)) % 8)
        pat = bytes(int(''.join(map(str, b[i:i + 8])), 2) for i in range(0, len(b), 8))
        i = G.find(pat)
        while i >= 0:
            for w in range(len(pat), 8):
                for off in range(0, w - len(pat) + 1):
                    votes[(lo + i - off - (y - y0) * w, w)] += 1
            i = G.find(pat, i + 1)
for (start, w), n in votes.most_common(5):
    print(f'${start:04X} width {w}: {n} rows')

#!/usr/bin/env python3
"""The memory map of doc 02 as one figure: $4000-$FFFF, one row per 256 bytes (192 rows), each byte a square
coloured by what the stage-1 recordings did with it (union of their L1 builds): executed green, read as data blue,
written yellow, written and read orange, untouched dark. The regions of tools/memmap-regions.txt as labelled
brackets on the right.

    python3 tools/fig_memmap.py --out docs/img/arch/memmap.png work/runs/{a1,g1,t1,p2,i1,i2,h1,h2}/l1.json
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

import l1map

HERE = os.path.dirname(os.path.abspath(__file__))
COL = {'X': (60, 200, 80), 'XR': (60, 200, 80), 'XW': (230, 60, 60), 'R': (70, 120, 230), 'W': (240, 220, 60),
       'WR': (245, 150, 40), '-': (28, 28, 34)}
NAMES = [('X', 'executed'), ('R', 'read as data'), ('WR', 'written and read'), ('W', 'written only'),
         ('XW', 'executed and written'), ('-', 'untouched')]


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', required=True)
    p.add_argument('--regions', default=os.path.join(HERE, 'memmap-regions.txt'))
    p.add_argument('--cell', type=int, default=2)
    p.add_argument('l1', nargs='+')
    args = p.parse_args()
    ex, rd, wr = l1map.load(args.l1)
    c = args.cell
    rows = 0xC0
    left, top = 70, 50
    mapw, maph = 256 * c, rows * c * 2
    W, H = left + mapw + 380, top + maph + 90
    img = Image.new('RGB', (W, H), (16, 16, 20))
    d = ImageDraw.Draw(img)
    f, fb, fs = font(15), font(18), font(13)
    d.text((10, 10), 'Moon Patrol: what the stage-1 recordings did with each byte of $4000-$FFFF', font=fb,
           fill=(240, 240, 240))
    for r in range(rows):
        for col in range(256):
            a = 0x4000 + r * 256 + col
            k = l1map.klass(ex[a], rd[a], wr[a])
            x, y = left + col * c, top + r * c * 2
            d.rectangle([x, y, x + c - 1, y + 2 * c - 1], fill=COL[k])
        if r % 16 == 0:
            d.text((8, top + r * c * 2 - 2), '$%04X' % (0x4000 + r * 256), font=fs, fill=(200, 200, 200))
    # regions
    regs = [l.split(None, 2) for l in open(args.regions) if l.strip()]
    last_y = -100
    for lo, hi, name in regs:
        lo, hi = int(lo, 16), int(hi, 16)
        y0 = top + ((lo - 0x4000) // 256) * c * 2
        y1 = top + ((hi - 0x4000) // 256 + 1) * c * 2 - 1
        x = left + mapw + 8
        d.line([x, y0, x + 6, y0, x + 6, y1, x, y1], fill=(220, 220, 220))
        ty = max((y0 + y1) // 2 - 8, last_y + 16)
        d.line([x + 6, (y0 + y1) // 2, x + 16, ty + 8], fill=(150, 150, 150))
        d.text((x + 20, ty), '$%04X-$%04X %s' % (lo, hi, name.strip()), font=f, fill=(235, 235, 235))
        last_y = ty
    ly = top + maph + 15
    x = left
    for k, n in NAMES:
        d.rectangle([x, ly, x + 14, ly + 14], fill=COL[k])
        d.text((x + 20, ly - 1), n, font=f, fill=(220, 220, 220))
        x += 30 + int(d.textlength(n, font=f))
    d.text((left, ly + 28), 'one row = 256 bytes; recordings: ' + ' '.join(
        os.path.basename(os.path.dirname(pth)) for pth in args.l1) + ' (from the entry snapshot)', font=fs,
        fill=(170, 170, 170))
    img.save(args.out)
    print(args.out, img.size)


if __name__ == '__main__':
    main()

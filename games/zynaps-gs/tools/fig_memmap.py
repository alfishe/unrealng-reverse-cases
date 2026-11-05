#!/usr/bin/env python3
"""Doc 02 figure: the memory map as bars, one per stage, each region coloured by kind and labelled with its first
address, from tools/memmap.txt.

    python3 tools/fig_memmap.py --stages 'menu=at the menu,play=in play,load=the level load' --lo 4000 \
        --title T --png docs/img/arch/memory-map.png
    python3 tools/fig_memmap.py --stages 'bank1=bank 1,bank3=bank 3,bank4=bank 4,bank6=bank 6,bank7=bank 7' \
        --lo C000 --title T --png docs/img/arch/banks.png
"""
import argparse
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
KINDS = {'screen': (70, 130, 200), 'code': (60, 170, 90), 'data': (200, 170, 60), 'sound': (210, 110, 210),
         'work': (90, 90, 110), 'system': (130, 130, 130), 'loader': (230, 140, 50), 'stack': (170, 80, 80)}
LEGEND = {'work': 'work space / buffers', 'sound': 'GS: driver, stubs, FX', 'loader': 'loader / installer'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--table', default=os.path.join(Z.HERE, 'memmap.txt'))
    p.add_argument('--stages', required=True)
    p.add_argument('--lo', default='4000')
    p.add_argument('--title', required=True)
    p.add_argument('--height', type=int, default=640)
    p.add_argument('--png', required=True)
    args = p.parse_args()
    stages = [s.split('=', 1) for s in args.stages.split(',')]
    rows = []
    for line in open(args.table):
        line = line.strip()
        if line and not line.startswith('#'):
            st, a, b, kind, name = line.split(None, 4)
            rows.append((st, int(a, 16), int(b, 16), kind, name))
    lo, hi = int(args.lo, 16), 0x10000
    f, fb = K.font(12), K.font(15)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    top, height, bar, gap, left = 70, args.height, 34, 14, 56
    widths = []
    for st, _ in stages:
        names = [f'${a:04X} {n}' for s, a, _, _, n in rows if s == st]
        widths.append(bar + 20 + max(probe.textlength(n, font=f) for n in names))
    scale = height / (hi - lo)
    W = int(left + sum(widths) + gap * (len(stages) - 1) + 10)
    im = Image.new('RGB', (max(W, 600), top + height + 80), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 28), 'each bar: the address space, top to bottom; a label gives a region\'s first '
                     'address', fill=K.DIM, font=f)
    step = 0x2000 if hi - lo > 0x4000 else 0x1000
    for a in range(lo, hi + 1, step):
        y = top + (a - lo) * scale
        d.text((8, y - 7), f'${a:04X}' if a < hi else '', fill=K.DIM, font=f)
    x0 = left
    for i, (st, title) in enumerate(stages):
        d.text((x0, top - 18), title, fill=K.TEXT, font=f)
        nxt = top
        for _, a, b, kind, name in (r for r in rows if r[0] == st):
            y0, y1 = top + (a - lo) * scale, top + (b + 1 - lo) * scale
            d.rectangle([x0, y0, x0 + bar, max(y0, y1 - 1)], fill=KINDS[kind], outline=K.BACKGROUND)
            mid = (y0 + y1) / 2
            ly = max(mid - 7, nxt)
            nxt = ly + 15
            d.line([x0 + bar, mid, x0 + bar + 6, mid, x0 + bar + 12, ly + 7], fill=(150, 150, 150))
            d.text((x0 + bar + 14, ly), f'${a:04X} {name}', fill=(225, 225, 225), font=f)
        x0 += widths[i] + gap
    x, y = 10, top + height + 52
    for kind, colour in KINDS.items():
        if not any(r[3] == kind and r[0] in dict(stages) for r in rows):
            continue
        label = LEGEND.get(kind, kind)
        d.rectangle([x, y + 2, x + 12, y + 14], fill=colour)
        d.text((x + 16, y), label, fill=K.TEXT, font=f)
        x += 16 + probe.textlength(label, font=f) + 22
    im.save(args.png)
    print(args.png, im.size)


if __name__ == '__main__':
    main()

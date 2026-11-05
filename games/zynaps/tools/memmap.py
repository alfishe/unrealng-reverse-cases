#!/usr/bin/env python3
"""The memory map as a picture, stages side by side (docs/02-architecture.md): $4000-$FFFF as a bar per stage (the
tape load, the image as the loader's move leaves it, play), each region coloured by kind and labelled, from tools/memmap.txt.

    python3 tools/memmap.py [--table tools/memmap.txt] --png docs/img/memory-map.png [--regions-out FILE]

--regions-out writes the play stage's regions of 512 bytes or more as kit/heatmap.py's regions file (START END
NAME).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

KINDS = {'screen': (70, 130, 200), 'code': (60, 170, 90), 'data': (200, 170, 60), 'graphics': (200, 110, 200),
         'work': (90, 90, 110), 'dead': (110, 60, 60), 'system': (130, 130, 130), 'loader': (230, 140, 50),
         'stack': (170, 80, 80)}
STAGES = [('load', 'the code file loading'), ('image', 'the image at $8000'), ('play', 'in play')]
LO, HI = 0x4000, 0x10000
LEGEND = {'work': 'work space', 'dead': 'dead bytes', 'system': 'ROM system area', 'loader': 'loader'}
TITLE = ('The game is $61A8-$FFFE; in play $B700-$DFFF and $5C00-$67FF change role (buffers, the copied tiles)',
         'Each bar is $4000-$FFFF at one stage, top to bottom; a label gives the region\'s first address')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--table', default=os.path.join(HERE, 'memmap.txt'))
    p.add_argument('--png', required=True)
    p.add_argument('--regions-out')
    args = p.parse_args()
    rows = []
    for line in open(args.table):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        stage, start, end, kind, name = line.split(None, 4)
        rows.append((stage, int(start, 16), int(end, 16), kind, name))
    if args.regions_out:
        with open(args.regions_out, 'w') as f:
            for stage, a, b, _, name in rows:
                if stage == 'play' and b - a >= 0x1FF:
                    f.write(f'{a:04X} {b:04X} {name}\n')
    f, small, title_font = K.font(21), K.font(19), K.font(24)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    top, height, bar, gap, left = 110, 1100, 56, 24, 86
    widths = []
    for stage, _ in STAGES:
        names = [f'${a:04X} {name}' for st, a, _, _, name in rows if st == stage]
        widths.append(bar + 24 + max(probe.textlength(n, font=small) for n in names))
    scale = height / (HI - LO)
    image = Image.new('RGB', (int(left + sum(widths) + gap * (len(STAGES) - 1) + 10), top + height + 170),
                      (24, 24, 30))
    d = ImageDraw.Draw(image)
    d.text((10, 12), TITLE[0], fill=(240, 240, 240), font=title_font)
    d.text((10, 44), TITLE[1], fill=(200, 200, 200), font=small)
    for a in range(LO, HI + 1, 0x2000):
        y = top + (a - LO) * scale
        d.text((8, y - 10), f'${a:04X}' if a < HI else '', fill=(190, 190, 190), font=small)
    x0 = left
    for i, (stage, title) in enumerate(STAGES):
        d.text((x0, top - 34), title, fill=(235, 235, 235), font=f)
        regions = [r for r in rows if r[0] == stage]
        next_label = top
        for _, a, b, kind, name in regions:
            y0, y1 = top + (a - LO) * scale, top + (b + 1 - LO) * scale
            d.rectangle([x0, y0, x0 + bar, max(y0, y1 - 1)], fill=KINDS[kind], outline=(24, 24, 30))
            mid = (y0 + y1) / 2
            ly = max(mid - 11, next_label)
            next_label = ly + 23
            d.line([x0 + bar, mid, x0 + bar + 8, mid, x0 + bar + 16, ly + 11], fill=(150, 150, 150))
            d.text((x0 + bar + 20, ly), f'${a:04X} {name}', fill=(225, 225, 225), font=small)
        x0 += widths[i] + gap
    x, y = left, top + height + 120
    for kind, colour in KINDS.items():
        label = LEGEND.get(kind, kind)
        d.rectangle([x, y + 3, x + 16, y + 19], fill=colour)
        d.text((x + 22, y), label, fill=(220, 220, 220), font=small)
        x += 22 + probe.textlength(label, font=small) + 30
    image.save(args.png)
    print(args.png)


if __name__ == '__main__':
    sys.exit(main())

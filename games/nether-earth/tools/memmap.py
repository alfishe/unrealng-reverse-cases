#!/usr/bin/env python3
"""The memory map as a picture, stages side by side (docs/02-architecture.md): $4000-$FFFF as a bar per stage (the
tape load, the image as N1 leaves it, play), each region coloured by kind and labelled, from tools/memmap.txt.

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
STAGES = [('load', 'the tape load (N1 running)'), ('image', 'the image as N1 leaves it'), ('play', 'in play')]
LO, HI = 0x4000, 0x10000


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
    top, height, bar, col = 50, 1000, 70, 520
    scale = height / (HI - LO)
    image = Image.new('RGB', (col * len(STAGES) + 70, top + height + 110), (24, 24, 30))
    d = ImageDraw.Draw(image)
    f, small = K.font(14), K.font(12)
    for a in range(LO, HI + 1, 0x1000):
        y = top + (a - LO) * scale
        d.text((8, y - 7), f'${a:04X}' if a < HI else '', fill=(190, 190, 190), font=small)
    for i, (stage, title) in enumerate(STAGES):
        x0 = 70 + i * col
        d.text((x0, 16), title, fill=(235, 235, 235), font=f)
        regions = [r for r in rows if r[0] == stage]
        next_label = top
        for _, a, b, kind, name in regions:
            y0, y1 = top + (a - LO) * scale, top + (b + 1 - LO) * scale
            d.rectangle([x0, y0, x0 + bar, max(y0, y1 - 1)], fill=KINDS[kind], outline=(24, 24, 30))
            mid = (y0 + y1) / 2
            ly = max(mid - 7, next_label)
            next_label = ly + 15
            d.line([x0 + bar, mid, x0 + bar + 8, mid, x0 + bar + 16, ly + 7], fill=(150, 150, 150))
            d.text((x0 + bar + 20, ly), f'${a:04X} {name}', fill=(225, 225, 225), font=small)
    x = 70
    for kind, colour in KINDS.items():
        d.rectangle([x, top + height + 75, x + 12, top + height + 87], fill=colour)
        d.text((x + 16, top + height + 73), kind, fill=(220, 220, 220), font=small)
        x += 110
    image.save(args.png)
    print(args.png)


if __name__ == '__main__':
    sys.exit(main())

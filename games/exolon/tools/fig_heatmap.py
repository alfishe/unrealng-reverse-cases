#!/usr/bin/env python3
"""Exolon doc 02 figure (copied from B/tools/fig_heatmap.py): the 48K memory heatmap of a whole recording at about 900 px (kit/heatmap.py's panels, laid out
for reading: the composite large with the regions named, the three single counts small below it).

    python3 tools/fig_heatmap.py work/docs/docA/c1-play/l1.json docs/img/arch/heatmap.png --regions work/docs/docA/regions-play.txt

The address space $4000-$FFFF is a grid of 192 rows of 256 bytes, $4000 at the top left. Colours are log2 of the
count over the whole recording (kit/heatmap.py scale()). Labels that would overlap are pushed apart and joined to
their bracket by a leader.
"""
import argparse
import importlib.util
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, '..', '..', '..', 'kit')


def kit_module(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(KIT, name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--regions', required=True)
    p.add_argument('--title', default='c1 play, 2150 frames: code in one block, writes to the screen, the cell maps and the lists')
    args = p.parse_args()
    H = kit_module('heatmap')
    K = kit_module('kitlib')
    lo, hi = 0x4000, 0xFFFF
    executes, reads, writes, _last, replay = H.load(args.l1, H.BASES_48K)
    fx, tx = H.scale(executes, lo, hi)
    fr, tr = H.scale(reads, lo, hi)
    fw, tw = H.scale(writes, lo, hi)
    big = H.panel(lo, hi, 2, lambda a: (int(255 * fw(a)), int(255 * fr(a)), int(255 * fx(a))))
    small = [('executed', H.panel(lo, hi, 1, lambda a: H.heat(fx(a))), tx),
             ('read', H.panel(lo, hi, 1, lambda a: H.heat(fr(a))), tr),
             ('written', H.panel(lo, hi, 1, lambda a: H.heat(fw(a))), tw)]
    f, fb = K.font(12), K.font(15)
    W = 900
    top, left = 52, 54
    h = top + big.height + 40 + small[0][1].height + 60 + 90
    out = Image.new('RGB', (W, h), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), 'red = written, green = read, blue = executed (log2 of the count); one row = 256 bytes',
           fill=K.DIM, font=f)
    out.paste(big, (left, top))
    for a in range(lo, hi + 1, 0x1000):
        y = top + ((a - lo) >> 8) * 2
        d.text((8, y - 7), f'${a:04X}', fill=K.DIM, font=f)
        d.line([(left - 6, y), (left - 2, y)], fill=K.DIM)
    # the regions: brackets on the grid's right, labels pushed apart
    rx = left + big.width + 6
    regions = []
    for line in open(args.regions):
        parts = line.split(None, 2)
        if len(parts) < 3 or line.startswith('#'):
            continue
        a, b = int(parts[0], 16), int(parts[1], 16)
        y0 = top + ((a - lo) >> 8) * 2
        y1 = top + ((b - lo) >> 8) * 2 + 1
        name = parts[2].strip()
        name = name if len(name) <= 34 else name[:33] + '.'
        regions.append((y0, y1, f'${a:04X} ' + name))
    placed, last_y = [], -100
    for y0, y1, text in regions:
        want = (y0 + y1) // 2 - 7
        y = max(want, last_y + 15)
        placed.append((y0, y1, y, text))
        last_y = y
    for y0, y1, y, text in placed:
        d.line([(rx, y0), (rx + 5, y0), (rx + 5, y1), (rx, y1)], fill=(220, 220, 140))
        d.line([(rx + 5, (y0 + y1) // 2), (rx + 14, y + 7)], fill=(150, 150, 110))
        d.text((rx + 16, y), text, fill=(230, 230, 170), font=f)
    y = max(top + big.height, last_y + 16) + 14
    d.text((10, y), 'the three counts alone (same grid, 1 px a byte, bright = many):', fill=K.TEXT, font=f)
    x = left
    for name, im, peak in small:
        out.paste(im, (x, y + 22))
        d.text((x, y + 26 + im.height), f'{name}, max {peak:,} on one byte', fill=K.DIM, font=f)
        x += im.width + 30
    out = out.crop((0, 0, W, y + 50 + small[0][1].height))
    out.save(args.png)
    print(args.png, out.size, replay.get('frames'), 'frames')


if __name__ == '__main__':
    main()

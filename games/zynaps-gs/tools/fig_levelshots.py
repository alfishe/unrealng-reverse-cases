#!/usr/bin/env python3
"""Docs 01 and 06 figure: the 12 levels side by side, one screen of each at the same time into play, from the tour
captures (tools/cap_tour.py level --level n: SELECT LEVEL n, music mode, INFINITE LIFE, the stick pattern with fire).

    python3 tools/fig_levelshots.py --offset 600 --out docs/img/render/levels.png

Each level's play starts where its steps.log says "the loading screen is gone"; the picture is the capture --offset
frames later. The label is the level key and $B461 (the level whose sound the driver loaded) of that capture.
"""
import argparse
import glob
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
KEYS = 'QWERTYUIOPAS'


def play_start(d):
    for line in open(os.path.join(d, 'steps.log')):
        if 'loading screen is gone' in line:
            return int(line.split()[0])
    raise SystemExit(f'{d}: no play start in steps.log')


def nearest(d, frame):
    caps = sorted(int(os.path.basename(p)[:-4]) for p in glob.glob(os.path.join(d, '*.scr')))
    return min(caps, key=lambda n: abs(n - frame))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--tour', default=os.path.join(Z.CASE, 'work', 'zgsA', 'tour'))
    ap.add_argument('--offset', type=int, default=600)
    ap.add_argument('--offsets', default='', help='per level, "5=900,7=300": another offset for some levels')
    ap.add_argument('--title', default='The 12 levels, each started with SELECT LEVEL and shot at the same point')
    ap.add_argument('--out', default=Z.out('render', 'levels.png'))
    args = ap.parse_args()
    special = {int(k): int(v) for k, v in (x.split('=') for x in args.offsets.split(',') if x)}
    f, fb = K.font(12), K.font(15)
    cols, cw, ch = 3, 296, 226
    top = 52
    im = Image.new('RGB', (cols * cw + 12, top + 4 * ch + 6), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 28), f'each: the screen {args.offset} frames' + (f' ({args.offsets})' if args.offsets else '') + f' after the loading screen went (tools/cap_tour.py '
                     'captures); label: key, $B461, frame', fill=K.DIM, font=f)
    for n in range(1, 13):
        dd = os.path.join(args.tour, f'L{n:02d}')
        frame = nearest(dd, play_start(dd) + special.get(n, args.offset))
        scr = open(os.path.join(dd, f'{frame:06d}.scr'), 'rb').read()
        gsv = open(os.path.join(dd, f'{frame:06d}.gsv'), 'rb').read()
        x, y = 10 + ((n - 1) % cols) * cw, top + ((n - 1) // cols) * ch
        im.paste(Z.render(scr, 1).resize((280, 210), Image.LANCZOS), (x, y))
        d.text((x, y + 211), f'level {n} (key {KEYS[n - 1]})  $B461 = {gsv[0x21]}  frame {frame}', fill=K.TEXT,
               font=f)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

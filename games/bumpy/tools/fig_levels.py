#!/usr/bin/env python3
"""The level atlas (doc 02, WALKTHROUGH 6.1): each of the 100 single-screen levels as it stands when its play starts
(the timer `$AB04` leaves 1000), from the RZX snapshots `work/stage1/rzx/levels/play-FFFFFF.z80` that
tools/rzx_levels.py wrote, 25 levels a figure in a 5 x 5 grid, each screen at half size with its level number.

    python3 tools/fig_levels.py [--out docs/img/maps]      (SkoolKit from $SKOOLKIT_VENV)
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import zxscreen  # noqa: E402
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for q in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.append(q)
from skoolkit.snapshot import Snapshot  # noqa: E402

LEVELS = os.path.join(HERE, '..', 'work', 'stage1', 'rzx', 'levels')
BG, TEXT, DIM = (24, 24, 30), (235, 235, 235), (170, 170, 180)


def plays():
    out = {}
    for line in open(os.path.join(LEVELS, 'plays.tsv')):
        if line.startswith('#'):
            continue
        frame, level = map(int, line.split())
        out.setdefault(level, frame)  # the first play of each level (level 0 comes back after the ending)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'maps'))
    a = p.parse_args()
    first = plays()
    tw, th, cols = 192, 144, 5
    f_title, f_lab = K.font(24), K.font(17)
    for part in range(4):
        levels = list(range(part * 25, part * 25 + 25))
        top = 56
        w = cols * (tw + 12) + 12
        h = top + 5 * (th + 30) + 8
        out = Image.new('RGB', (w, h), BG)
        d = ImageDraw.Draw(out)
        d.text((12, 12), f'Levels {levels[0]}-{levels[-1]} at the start of play (from the RZX, half size)', fill=TEXT,
               font=f_title)
        for k, lv in enumerate(levels):
            frame = first[lv]
            ram = Snapshot.get(os.path.join(LEVELS, f'play-{frame:06d}.z80')).ram(-1)
            im = zxscreen.render(bytes(ram[:6912]), 1).resize((tw, th), Image.LANCZOS)
            x, y = 12 + (k % cols) * (tw + 12), top + (k // cols) * (th + 30)
            d.text((x, y), f'level {lv}', fill=DIM, font=f_lab)
            out.paste(im, (x, y + 24))
        path = os.path.join(a.out, f'levels-{levels[0]:02d}-{levels[-1]:02d}.png')
        out.save(path)
        print(path, out.size)


if __name__ == '__main__':
    main()

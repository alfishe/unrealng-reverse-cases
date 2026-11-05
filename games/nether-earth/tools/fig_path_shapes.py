#!/usr/bin/env python3
"""Doc 13 figure: game turns to get past an obstacle, by its shape and the locomotion (docs/img/path/shapes.png).

    for l in bipod tracks anti-grav; do python3 tools/path_lab.py shapes --seeds 200 --locos $l \
        --out work/path/shapes-$l.json; done
    python3 tools/fig_path_shapes.py --runs work/path/shapes-bipod.json work/path/shapes-tracks.json \
        work/path/shapes-anti-grav.json --order 6 --out docs/img/path/shapes.png

Each shape is a test world of tools/path_lab.py: the robot starts at (285, 8) facing right; with order 6 its target
is a neutral factory door at (318, 8), past the obstacle at column 300. 200 seeds of the game's generator each, at
most 3000 game turns.
"""
import argparse
import json
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import path_lab as L  # noqa: E402
import path_model as P  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8d99'
LOCO = {'bipod': '#e5534b', 'tracks': '#d9a441', 'anti-grav': '#4caf50'}
NAMES = {'open': 'open field', 'block': 'one tall block', 'tower': 'tall tower, rows 5-10',
         'wall-top-gap': 'wall, gap at the top', 'wall-bottom-gap': 'wall, gap at the bottom',
         'wall-full': 'wall, no gap', 'pocket': 'U pocket, open to the robot', 'corridor': 'corridor, 2 rows',
         'rocks': 'rocks across (type $08)', 'trench': 'trench across (type $0C)'}


def thumbnail(ax, shape):
    m = L.scenario(shape, 6)
    window = np.zeros((16, 46))
    for x in range(280, 326):
        for y in range(16):
            t = m[P.cell_address(x, y)] & 0x1F
            window[y, x - 280] = 0 if t < 0x08 else 1 if t < 0x0C else 2 if t < 0x0F else 3
    ax.imshow(window, cmap=ListedColormap(['#262833', '#6b5a3a', '#8a6e3e', '#b08a52']), vmin=0, vmax=3,
              interpolation='nearest', aspect='auto')
    ax.add_patch(plt.Rectangle((285 - 280 - 0.5, 8 - 1.5), 2, 2, color='#5c8fd6'))
    ax.add_patch(plt.Rectangle((318 - 280 - 0.5, 8 - 0.5), 1, 1, fill=False, ec='#e5534b', lw=1.2))
    ax.set_xticks([])
    ax.set_yticks([])
    for s in ax.spines.values():
        s.set_color('#2c2e38')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--runs', nargs='+', required=True)
    p.add_argument('--order', type=int, default=6)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    results = {}
    cap = 3000
    for path in args.runs:
        d = json.load(open(path))
        cap = d['cap']
        results.update(d['results'])
    shapes = list(L.SHAPES)
    fig = plt.figure(figsize=(9.6, 9.4), dpi=100)
    fig.patch.set_facecolor(BG)
    top, row_h = 0.87, 0.074
    bars = fig.add_axes([0.36, top - row_h * len(shapes), 0.6, row_h * len(shapes)])
    bars.set_facecolor(AX)
    for i, shape in enumerate(shapes):
        ax = fig.add_axes([0.02, top - row_h * (i + 1) + 0.008, 0.13, row_h - 0.016])
        thumbnail(ax, shape)
        fig.text(0.16, top - row_h * (i + 0.5), NAMES[shape], color=FG, fontsize=8.5, va='center')
        for j, loco in enumerate(LOCO):
            key = f'{shape} order {args.order} {loco}'
            if key not in results:
                continue
            t = np.array(results[key]['times'])
            ok = t[t >= 0]
            y = i + 0.25 + j * 0.25
            if len(ok):
                lo, med, hi = np.percentile(ok, [10, 50, 90])
                bars.plot([lo, hi], [y, y], color=LOCO[loco], lw=1.5)
                bars.plot([med], [y], 'o', color=LOCO[loco], ms=5)
            never = len(t) - len(ok)
            if never:
                bars.text(cap * 0.985, y, f'{never * 100 // len(t)} % never', color=LOCO[loco], fontsize=7.5,
                          va='center', ha='right')
    bars.set_ylim(len(shapes), 0)
    bars.set_xlim(0, cap)
    bars.set_yticks([])
    for i in range(1, len(shapes)):
        bars.axhline(i, color='#2c2e38', lw=0.6)
    bars.tick_params(colors=DIM, labelsize=7.5)
    bars.set_xlabel(f'game turns to the door (dot: median, line: 10-90 %; "never": not within {cap})',
                    color=DIM, fontsize=8)
    for s in bars.spines.values():
        s.set_color('#2c2e38')
    for j, (loco, c) in enumerate(LOCO.items()):
        fig.text(0.36 + 0.12 * j, top + 0.012, '● ' + loco, color=c, fontsize=9)
    fig.text(0.02, top + 0.012, 'blue: robot start, red: door', color=DIM, fontsize=8)
    fig.suptitle('Order 6 past one obstacle: a gap costs 2-3 times the open walk, a pocket or a full wall traps\n'
                 'for good, and what is a wall depends on the locomotion', color=FG, fontsize=11, y=0.975)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight', pad_inches=0.15)
    print(args.out)


if __name__ == '__main__':
    main()

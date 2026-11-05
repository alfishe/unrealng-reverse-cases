#!/usr/bin/env python3
"""Doc 02: the 128K memory map, drawn from tools/fig_banks.txt (docs/img/arch/memmap-play.png, memmap-stages.png).

    python3 tools/fig_banks.py [--table tools/fig_banks.txt] [--out docs/img/arch]

play:   the eight 16 K banks in play, one bar each, every region labelled with its range.
stages: the same eight banks at the four moments (UltraXOR's first read, the intro, the boot menu, play): a matrix, one row per moment, coloured by kind, labelled where a region is wide.

The table's witnesses are in its header; each region's range is the block's or the dump's (doc 02 2.2 lists them).
"""
import argparse
import os
import textwrap

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
KIND = {'screen': '#5c8fd6', 'code': '#4caf50', 'data': '#d9a441', 'graphics': '#8e7cc3', 'work': '#5a6380',
        'free': '#2b2d38',
        'packed': '#e8833a', 'system': '#7a7d8c', 'music': '#e07ad0', 'sequence': '#d9534f'}
ORDER = [5, 2, 0, 1, 3, 4, 6, 7]
BASE = {5: 0x4000, 2: 0x8000}
STAGES = [('boot', 'UltraXOR read the loader\n(sim frame 29)'), ('intro', 'the intro plays\n(sim frames 60-1172)'),
          ('menu', 'the boot menu\n(sim frame 1473 on)'),
          ('play', 'play\n(recording r2)')]


def load(path):
    rows = []
    for line in open(path):
        if not line.strip() or line.startswith('#'):
            continue
        st, bank, lo, hi, kind, name = line.split(None, 5)
        rows.append((st, int(bank), int(lo, 16), int(hi, 16), kind, name.strip()))
    for st, _l in STAGES:  # every bank of every stage covered without a hole
        for b in ORDER:
            rs = sorted((lo, hi) for s, bb, lo, hi, _k, _n in rows if s == st and bb == b)
            base = BASE.get(b, 0xC000)
            assert rs and rs[0][0] == base and rs[-1][1] == base + 0x3FFF, (st, b, rs)
            assert all(rs[i][1] + 1 == rs[i + 1][0] for i in range(len(rs) - 1)), (st, b, rs)
    return rows


def esc(s):
    return s.replace('$', r'\$')


def play(rows, png):
    fig = plt.figure(figsize=(14, 9), facecolor=BG)
    fig.text(0.012, 0.98, 'In play the game owns banks 5, 2, 0; bank 1 is its music; 3, 4, 6, 7 wait for one '
             'event each', color=FG, fontsize=13, family='monospace', va='top')
    fig.text(0.012, 0.947, 'Each bar a 16 K bank, its address as the Z80 sees it when paged; banks 3, 4, 6, 7 are '
             'paged only for Dead End, a save or load, Final Cut, the boot', color=DIM, fontsize=9,
             family='monospace', va='top')
    ax = fig.add_axes([0.05, 0.08, 0.94, 0.82], facecolor=BG)
    w = 0.42
    role = {5: 'bank 5\n\\$4000 always', 2: 'bank 2\n\\$8000 always', 0: 'bank 0\n\\$C000 in play',
            1: 'bank 1\neach interrupt', 3: 'bank 3\nDead End, menu pic.', 4: 'bank 4\nsave, load',
            6: 'bank 6\na won game', 7: 'bank 7\nnever again'}
    for x, b in enumerate(ORDER):
        base = BASE.get(b, 0xC000)
        small = []
        for st, bb, lo, hi, kind, name in rows:
            if st != 'play' or bb != b:
                continue
            y0, y1 = (lo - base) / 0x4000, (hi + 1 - base) / 0x4000
            ax.add_patch(Rectangle((x, 1 - y1), w, y1 - y0, facecolor=KIND[kind], edgecolor=BG, lw=1))
            if y1 - y0 > 0.06:
                ax.text(x + 0.02, 1 - (y0 + y1) / 2, esc('%s\n$%04X-$%04X' % (textwrap.fill(name, 15), lo, hi)),
                        color=FG, fontsize=6.8, va='center', family='monospace')
            else:
                small.append(((y0 + y1) / 2, '%s $%04X' % (name, lo)))
        last = -1
        for y, text in small:  # beside the bar, spread so that no two overlap, a leader to the region
            ty = max(y, last + 0.024)
            last = ty
            ax.plot([x + w, x + w + 0.03], [1 - y, 1 - ty], color=DIM, lw=0.5)
            ax.text(x + w + 0.035, 1 - ty, esc(textwrap.shorten(text, 24, placeholder='..')), color=FG,
                    fontsize=6.2, va='center', family='monospace')
        ax.text(x + w / 2, 1.015, role[b], color=FG, ha='center', fontsize=8, family='monospace')
    ax.set_xlim(-0.05, len(ORDER) + 0.05)
    ax.set_ylim(-0.08, 1.06)
    ax.axis('off')
    for i, (k, c) in enumerate(KIND.items()):
        ax.add_patch(Rectangle((i * 0.78, -0.065), 0.1, 0.03, facecolor=c, edgecolor=DIM, lw=0.5))
        ax.text(i * 0.78 + 0.13, -0.05, k, color=FG, fontsize=8, va='center', family='monospace')
    fig.savefig(png, dpi=100, facecolor=BG)


def stages(rows, png):
    fig = plt.figure(figsize=(13, 7.8), facecolor=BG)
    fig.text(0.012, 0.98, 'The boot fills the 128 K from the top: by the boot menu every bank holds a packed block '
             'or a program', color=FG, fontsize=13, family='monospace', va='top')
    fig.text(0.012, 0.947, 'One row per moment, one cell per 16 K bank (left = its first byte); orange = still '
             'packed, dark = free; after the menu the game starter unpacks what play needs', color=DIM, fontsize=9,
             family='monospace', va='top')
    ax = fig.add_axes([0.15, 0.10, 0.84, 0.80], facecolor=BG)
    cw, gap = 1.0, 0.06
    for r, (st, label) in enumerate(STAGES):
        y = len(STAGES) - 1 - r
        fig.text(0.012, 0.10 + 0.80 * (y + 0.5) / len(STAGES), label, color=FG, fontsize=8.5, va='center',
                 family='monospace')
        for c, b in enumerate(ORDER):
            base = BASE.get(b, 0xC000)
            x0 = c * (cw + gap)
            for s, bb, lo, hi, kind, name in rows:
                if s != st or bb != b:
                    continue
                a, z = (lo - base) / 0x4000, (hi + 1 - base) / 0x4000
                ax.add_patch(Rectangle((x0 + a * cw, y + 0.1), (z - a) * cw, 0.8, facecolor=KIND[kind],
                                       edgecolor=BG, lw=0.8))
                if z - a > 0.33 and kind != 'free':
                    ax.text(x0 + (a + z) / 2 * cw, y + 0.5, textwrap.fill(name, max(8, int(20 * (z - a)))),
                            color=FG, fontsize=6.4, ha='center', va='center', family='monospace')
    for c, b in enumerate(ORDER):
        ax.text(c * (cw + gap) + cw / 2, len(STAGES) + 0.05, 'bank %d\n%s' % (b, esc('$%04X' % BASE.get(b, 0xC000))),
                color=FG, ha='center', fontsize=8.5, family='monospace')
    ax.set_xlim(0, len(ORDER) * (cw + gap))
    ax.set_ylim(-0.35, len(STAGES) + 0.5)
    ax.axis('off')
    for i, (k, col) in enumerate(KIND.items()):
        ax.add_patch(Rectangle((i * 0.84, -0.3), 0.12, 0.18, facecolor=col, edgecolor=DIM, lw=0.5))
        ax.text(i * 0.84 + 0.16, -0.21, k, color=FG, fontsize=8, va='center', family='monospace')
    fig.savefig(png, dpi=100, facecolor=BG)


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('--table', default=os.path.join(HERE, 'fig_banks.txt'))
    a.add_argument('--out', default=os.path.join(CASE, 'docs/img/arch'))
    args = a.parse_args()
    rows = load(args.table)
    os.makedirs(args.out, exist_ok=True)
    play(rows, os.path.join(args.out, 'memmap-play.png'))
    stages(rows, os.path.join(args.out, 'memmap-stages.png'))
    print(len(rows), 'regions')


if __name__ == '__main__':
    main()

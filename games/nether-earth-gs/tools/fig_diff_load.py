#!/usr/bin/env python3
"""How long each edition takes from the start of loading to the game: Nether Earth's tape, the 2002 Tron Z disk and
the 2017 Hood tape, each split by what loads (docs/img/diff/load-time.png).

    python3 tools/fig_diff_load.py [--out PNG]

The numbers are the docs' measurements, not new runs:
  NE tape      ../nether-earth/docs/03-build-and-load.md: signal time of each block from its bit count, no pauses
  GS disk      docs/03-build-and-load.md: Pentagon frames (20.48 ms) from RUN (frame 326) to Start (frame 4868)
  GS tape      docs/03-build-and-load.md: signal time of the 50 blocks from their bit counts, grouped by what loads
"""

import argparse
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
GS = os.path.normpath(os.path.join(HERE, '..'))
BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'
FRAME = 71680 / 3500000                       # Pentagon frame, s

COLORS = {'BASIC': '#5a5d6a', 'loader': '#8a8d9a', 'screen': '#26c6da', 'game': '#3d6b47', 'GS module': '#e8913a',
          'GS effects': '#e5534b', 'GS driver': '#f2e86d'}
EDITIONS = [
    ('Nether Earth, tape (1987)', [('BASIC', 9.0), ('loader', 8.2), ('game', 247.6)],
     'block 4 holds the screen and the game, $4000-$FCE8'),
    ('GS, Tron Z disk (2002)', [('BASIC', (739 - 326) * FRAME), ('screen', (828 - 739) * FRAME),
                                ('GS module', (2098 - 828) * FRAME), ('GS effects', (4546 - 2098) * FRAME),
                                ('GS driver', (4633 - 4546) * FRAME), ('game', (4868 - 4633) * FRAME)],
     'measured: Pentagon frames from RUN to Start'),
    ('GS, Hood tape (2017)', [('BASIC', 12.3), ('loader', 12.1), ('screen', 41.5), ('GS module', 814.3),
                              ('GS effects', 1448.3), ('GS driver', 8.6), ('game', 210.4)],
     '50 blocks, 416 591 bytes of signal'),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(GS, 'docs/img/diff/load-time.png'))
    a = ap.parse_args()
    fig, axes = plt.subplots(2, 1, figsize=(13, 6.4), facecolor=BG,
                             gridspec_kw=dict(height_ratios=[1, 1], hspace=0.55, left=0.27, right=0.97, top=0.86,
                                              bottom=0.1))
    for ax, limit, note in ((axes[0], 3000, 'to scale'), (axes[1], 330, 'the first five minutes')):
        ax.set_facecolor(BG)
        for i, (name, parts, why) in enumerate(EDITIONS):
            y = len(EDITIONS) - 1 - i
            x = 0
            for part, sec in parts:
                ax.barh(y, sec, left=x, color=COLORS[part], height=0.62, edgecolor=BG, lw=0.6)
                if sec / limit > 0.06 and x < limit:
                    ax.text(x + min(sec, limit - x) / 2, y, f'{part}\n{sec:.0f} s', ha='center', va='center',
                            fontsize=7, color='#101010')
                x += sec
            ax.text(min(x, limit) + limit * 0.005, y, f' {x:,.1f} s = {x / 60:.1f} min' if x < limit else '',
                    va='center', fontsize=8, color=TEXT)
            ax.text(-limit * 0.01, y, f'{name}\n{why}', ha='right', va='center', fontsize=8, color=TEXT)
        ax.set_xlim(0, limit)
        ax.set_yticks([])
        ax.tick_params(colors=DIM, labelsize=8)
        for s in ax.spines.values():
            s.set_color(DIM)
        ax.set_xlabel(f'seconds ({note})', color=DIM, fontsize=8)
    handles = [plt.Rectangle((0, 0), 1, 1, color=c) for c in COLORS.values()]
    fig.legend(handles, list(COLORS), loc='upper right', ncol=7, frameon=False, labelcolor=TEXT, fontsize=8,
               bbox_to_anchor=(0.97, 0.95))
    fig.suptitle('From the load to the game: the disk is 2.8 times faster than NE\'s tape, the GS tape 9.6 times '
                 'slower', color=TEXT, fontsize=11, x=0.01, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    for name, parts, _ in EDITIONS:
        print(f'{name}: {sum(s for _, s in parts):.1f} s', ', '.join(f'{p} {s:.1f}' for p, s in parts))
    print('wrote', a.out)


if __name__ == '__main__':
    main()

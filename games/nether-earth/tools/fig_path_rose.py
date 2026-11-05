#!/usr/bin/env python3
"""Doc 13 figure: the chances of each direction at one decision (docs/img/path/rose.png).

    python3 tools/path_lab.py odds --states 50000 --out work/path/odds.json
    python3 tools/fig_path_rose.py --odds work/path/odds.json --out docs/img/path/rose.png

The shares come from tools/path_lab.py `odds`: the decision run on 50000 states of the game's generator, three draws
apart, as the robot loop takes them.
"""
import argparse
import json
import math
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8d99'
FREE, BLOCKED, WANTED = '#4caf50', '#e5534b', '#f2c84b'
ANGLE = {'R': 0.0, 'U': math.pi / 2, 'L': math.pi, 'D': 3 * math.pi / 2}


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--odds', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    odds = json.load(open(args.odds))
    panels = [
        ('advance, all four free', 'RLDU', 'R', odds['lean']['R free RLDU']['share']),
        # free R, L, D: the fall-back pick drops L, so it is the case 'R free RD' of odds.json
        ('advance, up blocked', 'RLD', 'R', odds['lean']['R free RD']['share']),
        ('advance, right blocked', 'LDU', 'R', odds['lean']['R free LDU']['share']),
        ('door 5 columns right, rows above', 'RLDU', 'RU', odds['aim']['near']),
        ('order 3, no opponent left', 'RLDU', '', odds['pick']['RLDU']['share']),
    ]
    fig = plt.figure(figsize=(9.6, 6.6), dpi=100)
    fig.patch.set_facecolor(BG)
    for i, (title, free, wanted, share) in enumerate(panels):
        col, row = i % 3, i // 3
        ax = fig.add_axes([0.1 + col * 0.31 + (0.155 if row else 0), 0.53 - row * 0.4, 0.17, 0.25], projection='polar')
        ax.set_facecolor(AX)
        ax.set_ylim(0, 1.0)
        ax.set_yticks([])
        ax.set_xticks([ANGLE[d] for d in 'RULD'])
        ax.set_xticklabels([])
        ax.spines['polar'].set_color('#2c2e38')
        ax.grid(color='#2c2e38')
        for d in 'RLDU':
            v = share.get(d, 0.0)
            colour = FREE if d in free else BLOCKED
            ax.bar(ANGLE[d], max(v, 0.02 if d not in free else 0.0), width=0.9, color=colour,
                   alpha=0.9 if d in free else 0.35, edgecolor=WANTED if d in wanted else colour,
                   lw=2 if d in wanted else 0)
            label = f'{d} blocked' if d not in free else f'{d} {v * 100:.0f} %'
            ax.text(ANGLE[d], 1.12 if d in 'RL' else 1.22, label, color=FG if d in free else BLOCKED,
                    ha={'R': 'left', 'L': 'right'}.get(d, 'center'), va='center', fontsize=8.5, clip_on=False)
        ax.set_title(title, color=FG, fontsize=9.5, pad=22)
    fig.suptitle('One decision: the wanted side 84-88 % when it is free, the way back only when it is blocked',
                 color=FG, fontsize=11.5, y=0.97)
    notes = ['green: free (FreeDirections); red: blocked; yellow edge: a direction the order wants',
             'a bar is the chance this decision picks it (the course then lasts 3-6 steps)']
    for k, t in enumerate(notes):
        fig.text(0.03, 0.06 - 0.035 * k, t, color=DIM, fontsize=8.5)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor())
    print(args.out)


if __name__ == '__main__':
    main()

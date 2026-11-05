#!/usr/bin/env python3
"""Doc 03: the boot as time, from tools/ane_sim.py's log: every sector read, every $7FFD write, every HRUM depack,
from RUN "A_NETHER" to the game's Restart (docs/img/load/boot-timeline.png).

    VENV/bin/python tools/ane_sim.py --until A5EF --keys 1300:space:10 2000:1:10 --frames 4500 \
        --log work/stage2/tmp/log3.txt
    python3 tools/fig_boot.py [--log work/stage2/tmp/log3.txt] [--png docs/img/load/boot-timeline.png]

The frames are the simulator's (71 680 T each, frame 0 = the BASIC's USR), not a recording's. SPACE was pressed
at frame 1300 and 1 (the boot menu's "game") at 2000. Three windows of the time axis: the first disk read (0-60),
the end of the intro to the boot menu (1150-1500), the game's start (1990-2520); nothing reads the disk outside
them. Prints the counts per writer too.
"""
import argparse
import os
from collections import Counter

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
BANK_COL = ['#d9a441', '#e07ad0', '#4caf50', '#d9534f', '#e8833a', '#5c8fd6', '#f0c05a', '#8e7cc3']
WRITERS = [  # PC range, who
    ((0x5E69, 0x5E69), 'UltraXOR\'s sector reader', '#9aa0b0'),
    ((0x6185, 0x620D), 'the loader (its music handler, SetPage)', '#4fb3bf'),
    ((0x66B3, 0x66B3), 'the intro', '#5c8fd6'),
    ((0x624D, 0x624D), 'the boot program\'s SetPage (also used by the game starter)', '#4caf50'),
    ((0xA5E3, 0xA5ED), 'the game: GameEntry', '#d9a441'),
]
WINDOWS = [(0, 64), (1150, 1500), (1990, 2520)]
STAGES = [  # from, to, label
    (0, 29, 'UltraXOR reads\nthe loader'), (29, 1172, 'the intro'), (1172, 1274, 'Presents'),
    (1274, 1300, 'scroller'), (1300, 1405, 'UltraXOR reads\nsectors 87-436'), (1405, 2000, 'boot program:\nthe boot menu'),
    (2005, 2100, 'game starter\n\\$9C40'), (2151, 2496, 'GameEntry: the\ntune set-up (\\$D8E1)'),
    (2496, 2520, 'Restart'),
]
NAMES = {'6600': 'intro', 'C000/7': 'intro picture', '6600b': 'Presents', '6600c': 'scroller', 'C000/1': 'music',
         '6060': 'boot program', '9C40': 'game starter', 'C000/3': 'Dead End', 'C000/4': 'disk module',
         '6731': 'the game'}


def who(pc):
    for (lo, hi), name, col in WRITERS:
        if lo <= pc <= hi:
            return name, col
    return 'other', '#777'


def parse(path):
    reads, pages, depacks = [], [], []
    for line in open(path):
        p = line.split()
        if p[0] == 'read' and len(p) >= 6:
            reads.append((int(p[3]) / 71680, int(p[1]) * 16 + int(p[2]) - 16, int(p[5], 16)))
        elif p[0] == '7ffd':
            pages.append((int(p[3]), int(p[1]), int(p[2])))
        elif p[0] == 'depack':
            depacks.append((int(p[-1]), p[1], int(p[6])))
    return reads, pages, depacks


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('--log', default=os.path.join(CASE, 'work/stage2/tmp/log3.txt'))
    a.add_argument('--png', default=os.path.join(CASE, 'docs/img/load/boot-timeline.png'))
    args = a.parse_args()
    reads, pages, depacks = parse(args.log)
    cnt = Counter(who(pc)[0] for _f, pc, _v in pages)
    for k, v in cnt.most_common():
        print('%6d  %s' % (v, k))
    print('reads', len(reads), 'sectors, frames', int(reads[0][0]), '-', int(reads[-1][0]))
    widths = [w[1] - w[0] for w in WINDOWS]
    widths = [60 * 3, 350, 530]
    fig = plt.figure(figsize=(13, 8.4), facecolor=BG)
    fig.text(0.012, 0.98, 'The boot reads the whole disk in two bursts (frames 10-29, 1302-1405), then pages a bank '
             'every frame', color=FG, fontsize=13, family='monospace', va='top')
    fig.text(0.012, 0.947, 'Simulator frames (tools/ane_sim.py), SPACE at 1300, key 1 at 2000; three windows of the '
             'time axis; the rest is the intro playing', color=DIM, fontsize=9.5, family='monospace', va='top')
    gs = fig.add_gridspec(3, 3, width_ratios=widths, height_ratios=[3.2, 2.4, 1.3], left=0.07, right=0.99,
                          top=0.88, bottom=0.17, wspace=0.04, hspace=0.12)
    for col, (lo, hi) in enumerate(WINDOWS):
        ax = fig.add_subplot(gs[0, col], facecolor=PANEL)
        for f, sec, page in [r for r in reads if lo <= r[0] <= hi]:
            ax.plot(f, sec, 's', ms=2.2, color=BANK_COL[page], mec='none')
        ax.set_xlim(lo, hi)
        ax.set_ylim(520, -8)
        bx = fig.add_subplot(gs[1, col], facecolor=PANEL)
        for f, pc, v in [p for p in pages if lo <= p[0] <= hi]:
            bx.plot(f + (pc % 7) * 0.08, v & 7, 'o', ms=3, color=who(pc)[1], mec='none', alpha=0.6)
        bx.set_xlim(lo, hi)
        bx.set_ylim(7.6, -0.6)
        cx = fig.add_subplot(gs[2, col], facecolor=PANEL)
        for s0, s1, lab in STAGES:
            if s1 < lo or s0 > hi:
                continue
            x0, x1 = max(s0, lo), min(s1, hi)
            cx.add_patch(plt.Rectangle((x0, 0.05), x1 - x0, 0.9, facecolor='#2b2d38', edgecolor=DIM, lw=0.6))
            if x1 - x0 > (hi - lo) * 0.08:
                cx.text((x0 + x1) / 2, 0.5, lab, color=FG, ha='center', va='center', fontsize=7.5,
                        family='monospace')
        for f, start, bank in depacks:
            if lo <= f <= hi:
                for z in (ax, bx):
                    z.axvline(f, color='#f0c05a', lw=0.6, ls=':')
                ax.text(f, -10, '\\$%s/%d' % (start, bank), color='#f0c05a', fontsize=7, rotation=90, ha='right', va='bottom',
                        family='monospace')
        cx.set_xlim(lo, hi)
        cx.set_ylim(0, 1)
        cx.set_yticks([])
        for z in (ax, bx, cx):
            z.tick_params(colors=DIM, labelsize=8)
            for s in z.spines.values():
                s.set_color('#444')
            if col:
                z.set_yticklabels([])
        ax.set_xticklabels([])
        bx.set_xticklabels([])
        if col == 0:
            ax.set_ylabel('sector read', color=DIM, fontsize=9)
            bx.set_ylabel('bank paged at\n\\$C000 (\\$7FFD)', color=DIM, fontsize=9)
            bx.set_yticks(range(8))
        cx.set_xlabel('frames %d-%d' % (lo, hi), color=DIM, fontsize=8.5)
    hs = [plt.Line2D([], [], marker='s', ls='', color=BANK_COL[b], label='read into bank %d' % b) for b in
          (0, 1, 3, 4, 6, 7)]
    hs += [plt.Line2D([], [], marker='o', ls='', color=c, label=n) for _r, n, c in WRITERS]
    hs += [plt.Line2D([], [], color='#f0c05a', ls=':', label='an HRUM depack (output address / bank)')]
    fig.legend(handles=hs, loc='lower center', ncol=4, frameon=False, labelcolor=FG, fontsize=8,
               prop={'family': 'monospace', 'size': 8})
    os.makedirs(os.path.dirname(args.png), exist_ok=True)
    fig.savefig(args.png, dpi=100, facecolor=BG)


if __name__ == '__main__':
    main()

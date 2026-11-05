#!/usr/bin/env python3
"""From the load to the game menu: the 48K tape against the 2 in 1's disk (docs/img/diff/load-time.png, doc 13.1).

    python3 tools/fig_diff_load.py [--out PNG]

The numbers are the two cases' own, nothing new is measured:
  48K   the TZX's nine blocks, signal and pause (../zynaps/docs/03-build-and-load.md 3.1, tools/tzxblocks.py list);
        the Hewson loader reads blocks 6 and 8 at the signal's speed, so this is the real time at ROM speed
  2 in 1  c1's frames from RUN to JP $8000 (docs/03-build-and-load.md 3.7, tools/fig_load_timeline.py), a Pentagon
        frame being 71 680 T = 20.48 ms; the waits for the player's keys are hatched
"""

import argparse
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.normpath(os.path.join(HERE, '..'))
BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'

# 48K: (label, seconds of signal, pause seconds, colour)
TAPE = [('header', 5.09, 1.005, '#555566'), ('BASIC', 2.43, 1.009, '#5b8def'), ('header', 5.09, 1.003, '#555566'),
        ('loader', 6.46, 1.010, '#ff9f43'), ('header', 5.08, 1.010, '#555566'),
        ('picy', 25.29, 1.003, '#b07cf0'), ('header', 5.10, 0.996, '#555566'),
        ('code: the game, 40 535 bytes', 202.83, 0.0, '#3d9b57')]
# 2 in 1: (label, first frame, end frame, colour, a key wait)
FRAME = 71680 / 3.5e6
DISK = [('RUN: boot.B', 1772, 1870, '#5b8def', False),
        ("boot.B's list, ZYNAPS.B", 1870, 2051, '#5b8def', False),
        ('block 1 read', 2051, 2125, '#ff9f43', False),
        ('block 1 unpacked', 2125, 2182, '#e5534b', False),
        ('the title (a key)', 2182, 2602, '#b07cf0', True),
        ('options (0)', 2602, 2752, '#b07cf0', True),
        ('Hewson picture', 2752, 2838, '#b07cf0', False),
        ('block 2 read', 2838, 2905, '#ff9f43', False),
        ('block 2 unpacked', 2905, 2975, '#e5534b', False),
        ('a key', 2975, 3302, '#b07cf0', True),
        ('set-up', 3302, 3313, '#3d9b57', False)]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(C, 'docs/img/diff/load-time.png'))
    a = ap.parse_args()
    fig, (top, bot) = plt.subplots(2, 1, figsize=(13, 5.6), facecolor=BG, gridspec_kw=dict(height_ratios=[1.1, 1]))
    tape_total = sum(s + p for _, s, p, _ in TAPE)
    disk_total = (DISK[-1][2] - DISK[0][1]) * FRAME
    waits = sum((e - s) * FRAME for _, s, e, _, w in DISK if w)
    for ax in (top, bot):
        ax.set_facecolor(BG)
        ax.tick_params(colors=DIM, labelsize=8)
        for sp in ax.spines.values():
            sp.set_color(DIM)
    # top: both to scale
    x = 0
    for label, s, p, col in TAPE:
        top.barh(1, s, left=x, height=0.55, color=col, edgecolor=BG, lw=0.5)
        if s > 20:
            top.text(x + s / 2, 1, label, color='black', fontsize=8, ha='center', va='center')
        x += s
        top.barh(1, p, left=x, height=0.55, color='#22222c')
        x += p
    for label, s, e, col, wait in DISK:
        top.barh(0, (e - s) * FRAME, left=(s - DISK[0][1]) * FRAME, height=0.55, color=col, edgecolor=BG, lw=0.5,
                 hatch='///' if wait else None)
    top.text(tape_total + 2, 1, f'{tape_total:.1f} s', color=TEXT, fontsize=9, va='center')
    top.text(disk_total + 2, 0, f'{disk_total:.1f} s from RUN, {disk_total - waits:.1f} s without the key waits',
             color=TEXT, fontsize=9, va='center')
    top.set_yticks([0, 1])
    top.set_yticklabels(['2 in 1: TRD on a Pentagon (c1)', '48K: Zynaps.tzx at ROM speed'], color=TEXT, fontsize=9)
    top.set_xlim(0, 300)
    top.set_xlabel('seconds', color=DIM, fontsize=8)
    # bottom: the 2 in 1 alone
    for i, (label, s, e, col, wait) in enumerate(DISK):
        x0, w = (s - DISK[0][1]) * FRAME, (e - s) * FRAME
        bot.barh(0, w, left=x0, height=0.5, color=col, edgecolor=BG, lw=0.8, hatch='///' if wait else None)
        y = 0.45 + 0.22 * (i % 3)
        bot.annotate(f'{label}\n{s}-{e}', (x0 + w / 2, 0.25), xytext=(x0 + w / 2, y + 0.1), color=TEXT, fontsize=7.5,
                     ha='center', va='bottom', arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6))
    bot.set_ylim(-0.4, 1.25)
    bot.set_yticks([])
    bot.set_xlim(0, disk_total + 0.5)
    bot.set_xlabel('seconds from RUN (c1 frames under the labels, 20.48 ms each); hatched: waiting for the player',
                   color=DIM, fontsize=8)
    fig.suptitle(f'From the load to the game menu: the tape plays {tape_total:.0f} s of signal; the disk is at the '
                 f'menu {disk_total:.0f} s after RUN, of which {waits:.0f} s are the intro waiting for keys',
                 color=TEXT, fontsize=10.5, x=0.01, ha='left')
    fig.subplots_adjust(left=0.2, right=0.97, top=0.9, bottom=0.1, hspace=0.45)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=90, facecolor=BG)
    print('wrote', a.out, f'tape {tape_total:.1f} s, disk {disk_total:.1f} s, waits {waits:.1f} s')


if __name__ == '__main__':
    main()

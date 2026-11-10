#!/usr/bin/env python3
"""Passes and interrupts (doc 4.7): the length of each of 200 main-loop passes, coloured by the interrupts that fell
inside it (2, or 3 when one was lost while the loop ran with interrupts off), with the passes that frame numbers
alone would call "1 frame" ringed; and the two counts side by side.

    python3 tools/fig_passes.py work/stage2/passes2-at050000.json docs/img/loop/passes.png

The JSON is work/stage2/passes2.py's (TOP $6911, HALT $796D, WAKE $796E with the beam's frame and T-state). The 48K
interrupt of unreal-ng comes at frame T 1812 (intstart 1811, strict >), so an INT instant is k x 69 888 + 1812.
"""
import collections
import json
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

F, INT = 69888, 1812
BG, PANEL, TEXT = '#0e0e14', '#181820', '#d2d2dc'


def main():
    rows = json.load(open(sys.argv[1]))
    out = sys.argv[2]
    ab = lambda p: p[0] * F + p[1]
    xs, ts, ints, byframe = [], [], [], []
    for i, r in enumerate(rows):
        t0, t1 = ab(r['top']), ab(r['next'])
        n = sum(1 for k in range(r['top'][0] - 1, r['next'][0] + 2) if t0 <= k * F + INT < t1)
        xs.append(i)
        ts.append(t1 - t0)
        ints.append(n)
        byframe.append(r['next'][0] - r['top'][0])
    plt.rcParams.update({'font.size': 11, 'font.family': 'monospace'})
    fig = plt.figure(figsize=(10.5, 5.4), dpi=100, facecolor=BG)
    ax = fig.add_axes([0.08, 0.12, 0.60, 0.74], facecolor=PANEL)
    hb = fig.add_axes([0.76, 0.12, 0.22, 0.74], facecolor=PANEL)
    col = {2: '#5ad278', 3: '#f0a046'}
    for n in (2, 3):
        sel = [k for k in xs if ints[k] == n]
        ax.scatter(sel, [ts[k] for k in sel], s=14, color=col[n],
                   label=f'{n} INTs inside the pass ({len(sel)})')
    one = [k for k in xs if byframe[k] == 1]
    ax.scatter(one, [ts[k] for k in one], s=110, facecolors='none', edgecolors='#ff5a5a', linewidths=1.5,
               label=f'"1 frame" by frame number ({len(one)})')
    for m in (2, 3):
        ax.axhline(m * F, color='#8a8aa0', lw=0.8, ls='--')
        ax.text(len(xs) - 1, m * F + 1500, f'{m} frames = {m * F:,} T'.replace(',', ' '), ha='right',
                va='bottom', color=TEXT, fontsize=10)
    ax.set_xlabel('pass (200 in a row from rzx/at050000.szx, room 102, no key)', color=TEXT)
    ax.set_ylabel('T a pass', color=TEXT)
    ax.set_ylim(90000, 230000)
    ax.legend(loc='upper left', facecolor=PANEL, edgecolor='#3c3c50', labelcolor=TEXT, fontsize=10)
    a = collections.Counter(byframe)
    b = collections.Counter(ints)
    labels = ['1', '2', '3']
    hb.bar([0, 1, 2], [a.get(1, 0), a.get(2, 0), a.get(3, 0)], width=0.38, color='#8a8aa0',
           label='by frame number')
    hb.bar([0.4, 1.4, 2.4], [b.get(1, 0), b.get(2, 0), b.get(3, 0)], width=0.38, color='#5ad278',
           label='by INTs inside')
    for x, v in [(0, a.get(1, 0)), (1, a.get(2, 0)), (2, a.get(3, 0)), (0.4, b.get(1, 0)), (1.4, b.get(2, 0)),
                 (2.4, b.get(3, 0))]:
        hb.text(x, v + 2, str(v), ha='center', va='bottom', color=TEXT, fontsize=10)
    hb.set_xticks([0.2, 1.2, 2.2])
    hb.set_xticklabels(labels)
    hb.set_xlabel('frames / INTs a pass', color=TEXT)
    hb.set_ylim(0, 265)
    hb.legend(loc='upper left', facecolor=PANEL, edgecolor='#3c3c50', labelcolor=TEXT, fontsize=10)
    for x in (ax, hb):
        x.tick_params(colors=TEXT)
        for s in x.spines.values():
            s.set_color('#3c3c50')
    fig.suptitle('200 passes of the main loop: 2 or 3 interrupts each, never 1', color='white', fontsize=14,
                 x=0.08, ha='left', y=0.96)
    fig.savefig(out, facecolor=BG)
    print(out, len(xs), dict(a), dict(b))


if __name__ == '__main__':
    main()

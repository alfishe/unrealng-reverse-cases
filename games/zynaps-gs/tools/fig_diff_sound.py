#!/usr/bin/env python3
"""What the GS sound costs against the 48K's beeper (docs/img/diff/sound-cost.png): the host's wait per effect in
music mode and in effects-only mode, and the frames the game stands still between rounds and at a level change.
Made for doc 13 after nether-earth-gs's tools/fig_diff_sound.py.

    python3 tools/fig_diff_sound.py [--out PNG]

Left: one histogram per run of the T-states the Spectrum waits for the card over one play (the `wait` of every play
in work/zgsB/e1/timeline.json, music mode, and work/zgsB/e2/timeline.json, effects only; both written by
tools/fig_sound.py timeline). The 48K's effects cost no wait: the beeper is driven in the main loop's spare time.

Right: the frames without play. The values are measured in the port journals or counted from the code (doc 13.7):
  48K between rounds   WaitFrames with A = 50 (EndOfPlay $B0FF), 50 frames
  GS between rounds    RoundWait's Delay ($C36D): 65536 steps x 31 T = 2 031 616 T, 28.3 Pentagon frames
  GS level done, music RoundWait's fade: 26 #2A steps, e1 frames 9276-9307
  GS level change      music (e1 9270-9720), effects only on 128 KB (e3 8195-8500), on 512 KB nothing
"""

import argparse
import json
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
import numpy as np  # noqa: E402
from matplotlib.ticker import FuncFormatter  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
GS = os.path.normpath(os.path.join(HERE, '..'))
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
FRAME = 71680

STILL = [  # (label, frames, colour)
    ('48K: between rounds (WaitFrames 50)', 50, '#8aa1b1'),
    ('GS: between rounds (RoundWait Delay)', 2031616 / FRAME, '#26c6da'),
    ('GS music: level done, module fade (e1)', 9307 - 9276, '#26c6da'),
    ('48K: level load (all in memory)', 0, '#8aa1b1'),
    ('GS music: level load (e1)', 9720 - 9270, '#e5534b'),
    ('GS effects, 128 KB: level load (e3)', 8500 - 8195, '#f2a65a'),
    ('GS effects, 512 KB: level load', 0, '#3d6b47'),
]


def waits(run):
    return np.array([p['wait'] for p in json.load(open(os.path.join(GS, 'work/zgsB', run, 'timeline.json')))['plays']])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(GS, 'docs/img/diff/sound-cost.png'))
    a = ap.parse_args()
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5.2), facecolor=BG, gridspec_kw=dict(width_ratios=(1.1, 1)))
    bins = np.logspace(2, 5.3, 40)
    for run, lab, col in (('e1', 'e1, music mode (a module playing)', '#e5534b'),
                          ('e2', 'e2, effects only (no module)', '#3d9b57')):
        w = waits(run)
        ax1.hist(w, bins=bins, color=col, alpha=0.75,
                 label=f'{lab}: {len(w)} plays, median {int(np.median(w)):,} T, {int((w > FRAME).sum())} over a frame')
    ax1.axvline(FRAME, color='white', lw=0.8, ls=':')
    ax1.text(FRAME * 1.05, ax1.get_ylim()[1] * 0.6, 'one frame\n71680 T', color='white', fontsize=8, va='top')
    ax1.set_xscale('log')
    ax1.xaxis.set_major_formatter(FuncFormatter(lambda v, _: f'{v:,.0f}'))
    ax1.set_ylim(0, ax1.get_ylim()[1] * 1.25)
    ax1.set_xlabel('T-states the Spectrum waits for the card over one play (#2E, #40, #80+c)', color=TEXT, fontsize=9)
    ax1.set_ylabel('plays', color=TEXT, fontsize=9)
    ax1.set_title('The wait per effect; the 48K\'s beeper effects wait for nothing', color=TEXT, fontsize=10)
    ax1.legend(frameon=False, labelcolor=TEXT, fontsize=8, loc='upper left')
    labels = [s[0] for s in STILL][::-1]
    vals = [s[1] for s in STILL][::-1]
    ax2.barh(range(len(STILL)), vals, color=[s[2] for s in STILL][::-1])
    for i, v in enumerate(vals):
        ax2.text(v + 4, i, f'{v:.0f} frames' if v else 'none', color=TEXT, fontsize=8, va='center')
    ax2.set_yticks(range(len(STILL)))
    ax2.set_yticklabels(labels, color=TEXT, fontsize=8)
    ax2.set_xlim(0, 540)
    ax2.set_xlabel('frames without play', color=TEXT, fontsize=9)
    ax2.set_title('The pauses: shorter between rounds, long level loads', color=TEXT, fontsize=10)
    for ax in (ax1, ax2):
        ax.set_facecolor(PANEL)
        ax.tick_params(colors=DIM, labelsize=8)
        for s in ax.spines.values():
            s.set_color(DIM)
    fig.suptitle('What the GS sound costs against the 48K beeper', color=TEXT, fontsize=12, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    print('wrote', a.out)


if __name__ == '__main__':
    main()

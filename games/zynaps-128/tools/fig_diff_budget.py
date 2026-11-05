#!/usr/bin/env python3
"""Where the CPU time goes in play, the 48K Zynaps against the 2 in 1, per routine of the shared game code
(docs/img/diff/budget-diff.png, docs 13.6).

    python3 tools/fig_diff_budget.py [--top 18] [--out PNG]

Reads the two whole-game L1 builds the cases already have:
  48K  ../zynaps/work/r1/l1.json      (75 003 frames x 69 888 T, the 48K bot run of 12 levels)
  128  work/z128A/r3/l1.json          (76 003 frames x 71 680 T, the Pentagon bot run of 12 levels)
Each instruction's T-states are summed per routine (the "$ADDR c Name" entry at or before it in the part's .ann, as
tools/fig_budget.py does) and shown as a share of all the recording's T-states. The 2 in 1's own code (page 4's
engine, the glue at $5B00, the hook stubs $B30D-$B3A8, the mouse driver) is one bar each. Both games use the same
routine names, so the bars pair by name.
"""

import argparse
import json
import os
import re
from bisect import bisect_right

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.normpath(os.path.join(HERE, '..'))
Z48 = os.path.normpath(os.path.join(C, '..', 'zynaps'))
ENTRY = re.compile(r'^\$([0-9A-F]{4}) c (\w+)')
BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'
C48, C128, COWN = '#5b8def', '#e5534b', '#ff9f43'


def routines(ann):
    out = []
    for line in open(ann, encoding='utf-8'):
        m = ENTRY.match(line)
        if m:
            out.append((int(m.group(1), 16), m.group(2)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def shares(l1, frame_t, parts, part_of):
    doc = json.load(open(l1))
    total = doc['replay']['frames'] * frame_t
    per = {}
    for z80, page, code, cls, count, tstates, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        if a < 0x4000:
            k, name = 'ROM', 'ROM'
        else:
            k = part_of(a, page)
            if k != 'game':
                name = k
            else:
                starts, names = parts['game']
                i = bisect_right(starts, a) - 1
                name = names[i] if i >= 0 else f'${a:04X}'
        per[name] = per.get(name, 0) + tstates
    return {n: 100 * t / total for n, t in per.items()}, doc['replay']['frames']


def part128(a, page):
    if page == 4:
        return 'the AY engine (page 4)'
    if 0x5B00 <= a < 0x5C00:
        return 'the glue ($5B00)'
    if 0xB30D <= a <= 0xB3A8:
        return 'the hook stubs ($B30D)'
    if 0xFE00 <= a <= 0xFEDC and page == 0:
        return 'the mouse driver'
    return 'game'


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--top', type=int, default=18)
    ap.add_argument('--out', default=os.path.join(C, 'docs/img/diff/budget-diff.png'))
    a = ap.parse_args()
    s48, f48 = shares(os.path.join(Z48, 'work/r1/l1.json'), 69888,
                      {'game': routines(os.path.join(Z48, 'src/game/game.ann'))}, lambda a, p: 'game')
    s128, f128 = shares(os.path.join(C, 'work/z128A/r3/l1.json'), 71680,
                        {'game': routines(os.path.join(C, 'src/game/game.ann'))}, part128)
    own = [n for n in s128 if n.startswith('the ')]
    names = sorted((n for n in set(s48) | set(s128) if n not in own),
                   key=lambda n: -max(s48.get(n, 0), s128.get(n, 0)))[:a.top]
    names += sorted(own, key=lambda n: -s128[n])
    fig = plt.figure(figsize=(12, 0.36 * len(names) + 2.4), facecolor=BG)
    ax = fig.add_axes((0.25, 0.1, 0.7, 0.76), facecolor=BG)
    h = 0.38
    for i, n in enumerate(names):
        v48, v128 = s48.get(n, 0), s128.get(n, 0)
        ax.barh(i - h / 2, v48, h, color=C48)
        ax.barh(i + h / 2, v128, h, color=COWN if n in own else C128)
        for y, v in ((i - h / 2, v48), (i + h / 2, v128)):
            if v:
                ax.text(v + 0.2, y, f'{v:.1f}%', color=TEXT, fontsize=7.5, va='center')
    ax.set_yticks(range(len(names)))
    ax.set_yticklabels(names, color=TEXT, fontsize=8.5)
    ax.invert_yaxis()
    ax.tick_params(colors=DIM, labelsize=8)
    ax.set_xlabel('share of all T-states of the recording, %', color=DIM, fontsize=8.5)
    for sp in ax.spines.values():
        sp.set_color(DIM)
    from matplotlib.patches import Patch
    ax.legend(handles=[Patch(color=C48, label=f'48K, r1 ({f48:,} frames x 69,888 T)'),
                       Patch(color=C128, label=f'2 in 1, r3 ({f128:,} frames x 71,680 T, Pentagon)'),
                       Patch(color=COWN, label="2 in 1's own code")],
              loc='lower right', frameon=False, labelcolor=TEXT, fontsize=8.5)
    loop48 = s48.get('EffectPlay', 0) + s48.get('PlayLoop', 0) + s48.get('EventDispatch', 0)
    loop128 = s128.get('PlayLoop', 0) + s128.get('EventDispatch', 0)
    fig.suptitle(f"The same game code costs the same; the main loop's time is beeper tones on the 48K "
                 f"(EffectPlay {s48.get('EffectPlay', 0):.1f}%) and idle spinning on the 2 in 1",
                 color=TEXT, fontsize=10.5, x=0.01, ha='left')
    fig.text(0.01, 0.885, f"Per routine of the shared game code, paired by name; the main loop's time: 48K "
             f"EffectPlay + PlayLoop + EventDispatch {loop48:.1f}%, 2 in 1 PlayLoop + EventDispatch {loop128:.1f}%.\n"
             f"PlayInterrupt grows by the 2018 waits (13.5). The {len(names) - len(own)} largest routines, then "
             f"the 2 in 1's own parts.",
             color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=90, facecolor=BG)
    print('wrote', a.out)
    for n in names:
        print(f'{n:28s} {s48.get(n, 0):6.2f} {s128.get(n, 0):6.2f}')


if __name__ == '__main__':
    main()

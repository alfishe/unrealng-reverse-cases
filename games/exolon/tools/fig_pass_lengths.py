#!/usr/bin/env python3
"""Doc 04 figure: how long MainLoop's passes take over a recording, and what makes a pass long.

    python3 tools/fig_pass_lengths.py --work work/docs/docA/c1 --from 12376 --to 28760 \
        --out docs/img/loop/pass-lengths.png

The passes are the starts of MainLoop `$75BE` (TTD find_event exec, the first start in each frame: a pass takes
about two frames, so every start is one). A pass's length is the T-states to the next start; gaps over 5 000 000 T
(about 72 frames: the game over and the menu between games, each over 46 million T in c1) end a game and are left
out. The longest real pass is 416 959 T (c1 20184-20190, a turn and a beeper effect together). Each pass is put in the first class whose
routine started inside it (find_event exec on that routine, its first start in each frame):

    BuildScreen $8494 (a new screen), FlipPlayerFrames $7BAA (the player turns), BeeperNoise $7C26 or
    BeeperSweep $7C3C (a beeper effect), DrawBigSprite $76DA (the player drawn), else a quiet pass.

The hits are cached in WORK/passes-*.txt. The histogram is stacked by class, 2000 T a bin; the frame lengths
(69 888 T) are marked.
"""
import argparse
import os
import re
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, HERE)
import exlib  # noqa: E402

FRAME = 69888
CLASSES = [('a new screen built (BuildScreen $8494)', ['8494'], '#ffffff'),
           ('the player turns (FlipPlayerFrames $7BAA)', ['7BAA'], '#78e6be'),
           ('a beeper effect (BeeperNoise $7C26, BeeperSweep $7C3C)', ['7C26', '7C3C'], '#a0dc50'),
           ('the player drawn (DrawBigSprite $76DA)', ['76DA'], '#2e9e46'),
           ('quiet: none of these', [], '#5c8fd6')]


def hits(s, work, addr, lo, hi):
    cache = os.path.join(work, f'passes-{addr}-{lo}-{hi}.txt')
    if os.path.isfile(cache):
        return [tuple(map(int, line.split())) for line in open(cache)]
    out, f = [], lo
    s = s()  # the session only when the cache misses
    while f <= hi:
        r = s.call('time_travel', {'action': 'find_event', 'find': 'exec', 'addr': '0x' + addr, 'from_frame': f,
                                   'to_frame': hi, 'limit': 100}, ok=False)
        got = re.findall(r'^f(\d+)\+(\d+) ', r.text, re.M)
        out += [(int(a), int(b)) for a, b in got]
        m = re.search(r'more from frame (\d+)', r.text)
        if not got or not m:
            break
        f = int(m.group(1))
    with open(cache, 'w') as o:
        o.writelines(f'{a} {b}\n' for a, b in out)
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='lo', type=int, required=True)
    p.add_argument('--to', dest='hi', type=int, required=True)
    p.add_argument('--title', default='')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = lambda: exlib.session(args.work)  # noqa: E731
    starts = [f * FRAME + t for f, t in hits(s, args.work, '75BE', args.lo, args.hi)]
    marks = {}
    for name, addrs, _ in CLASSES:
        marks[name] = sorted(f * FRAME + t for a in addrs for f, t in hits(s, args.work, a, args.lo, args.hi))
    import bisect
    passes = {name: [] for name, _, _ in CLASSES}
    for k in range(len(starts) - 1):
        a, b = starts[k], starts[k + 1]
        if b - a > 5000000:
            continue
        for name, addrs, _ in CLASSES:
            m = marks[name]
            i = bisect.bisect_left(m, a)
            if not addrs or (i < len(m) and m[i] < b):
                passes[name].append(b - a)
                break
    n = sum(len(v) for v in passes.values())
    fig, ax = plt.subplots(figsize=(9, 4.6), dpi=100)
    bg, panel, fg, dim = '#0e0e14', '#18181f', '#d2d2dc', '#8a8a99'
    fig.patch.set_facecolor(bg)
    ax.set_facecolor(panel)
    ax.tick_params(colors=dim, labelsize=10)
    for sp in ax.spines.values():
        sp.set_color('#444')
    bins = list(range(130000, 424000, 2000))
    shown = [c for c in CLASSES if passes[c[0]]]
    data = [[v / 1000 for v in passes[name]] for name, _, _ in shown]
    labels = [f'{name}: {len(passes[name])}'.replace('$', r'\$') for name, _, _ in shown]
    ax.hist(data, bins=[b / 1000 for b in bins], stacked=True, color=[c for _, _, c in shown], label=labels,
            edgecolor=panel, linewidth=0.3)
    ax.set_yscale('log')
    for k, lab in ((2, '2 frames'), (3, '3 frames'), (4, '4 frames'), (6, '6 frames')):
        ax.axvline(k * FRAME / 1000, color='#e05050', lw=1, ls='--')
        ax.text(k * FRAME / 1000 + 1, 1500, lab, color='#e05050', fontsize=10)
    q = sorted(passes[CLASSES[-1][0]])
    ax.set_xlabel('pass length, thousands of T-states (2000 T a bin)', color=dim)
    ax.set_ylabel('passes (log scale)', color=dim)
    med = f'{q[len(q) // 2]:,}'.replace(',', ' ')
    ax.set_title(args.title or f'{n} passes: a quiet one about 2 frames ({med} T the median); a turn about 4, the longest 6',
                 color=fg, fontsize=12, loc='left')
    ax.set_ylim(0.6, 3000)
    leg = ax.legend(facecolor=panel, edgecolor='#444', fontsize=9, loc='center right', bbox_to_anchor=(1.0, 0.6))
    for t in leg.get_texts():
        t.set_color(fg)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=bg, bbox_inches='tight')
    print(args.out, n, 'passes')
    for name, _, _ in CLASSES:
        v = sorted(passes[name])
        if v:
            print(f'{name:58s} {len(v):5d}  min {v[0]:7d} median {v[len(v) // 2]:7d} max {v[-1]:7d}')


if __name__ == '__main__':
    main()

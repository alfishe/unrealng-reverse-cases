#!/usr/bin/env python3
"""The simulation pass step by step (doc 4.6, 4.9): wall frames of the three parts of a pass in c1, city2 and metro,
and every pass of city2 and metro against the pass number.

    python3 tools/fig_passes.py work/docs/scA docs/img/arch/sim-passes.png

Reads the probe outputs of work/docs/scA: passes-c1.txt (probe.py, exec 8362 / 836B / 836E), passes-city2.tab and
passes-metro.tab (passes.py), pass-metro80.txt (the step probe of metro pass 80)."""
import os
import re
import statistics
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402


def probe_rows(path):
    rows = {}
    for line in open(path):
        m = re.match(r'exec 0x(\w+): .*frames (.*)', line)
        if m:
            rows[m.group(1)] = [int(x) for x in m.group(2).split(', ')]
    return rows


def passes_of_probe(path):
    """(power, scan, rest, total) for each complete pass of a probe output."""
    rows = probe_rows(path)
    starts = rows['8362']
    out = []
    for i, s in enumerate(starts[:-1]):
        a = next(x for x in rows['836B'] if x >= s)
        b = next(x for x in rows['836E'] if x >= a)
        e = starts[i + 1]
        out.append((a - s, b - a, e - b, e - s))
    return out


def passes_of_tab(path):
    out = []
    for line in open(path):
        f = line.split()
        if f and f[0].isdigit():
            out.append((int(f[0]), int(f[1]), int(f[2]), int(f[3]), int(f[4]), int(f[5])))
    return out


def main():
    src, out = sys.argv[1], sys.argv[2]
    c1 = passes_of_probe(os.path.join(src, 'passes-c1.txt'))
    city2 = passes_of_tab(os.path.join(src, 'passes-city2.tab'))
    metro = passes_of_tab(os.path.join(src, 'passes-metro.tab'))
    m80 = [p for p in metro if p[0] == 80][0]

    def med(rows, k):
        return statistics.median(r[k] for r in rows)
    cols = [
        (f'c1, mean of {len(c1)}', [statistics.mean(r[k] for r in c1) for k in range(3)]),
        # the third part is the median pass less the two medians before it, as in doc 4.6's table
        (f'city2, median of {len(city2)}', [med(city2, 2), med(city2, 3), med(city2, 5) - med(city2, 2) - med(city2, 3)]),
        (f'metro, median of {len(metro)}', [med(metro, 2), med(metro, 3), med(metro, 5) - med(metro, 2) - med(metro, 3)]),
        ('metro pass 80', [m80[2], m80[3], m80[4]]),
    ]
    parts = ['ClearCounters, SetSpeed, PowerFlood', 'ScanCity', 'CoverStations to the month']
    colours = ['#d9a400', '#2060c0', '#40a040']

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(9, 7.2), gridspec_kw={'height_ratios': [1, 1.25]})
    for y, (name, vals) in enumerate(reversed(cols)):
        left = 0
        for v, c, p in zip(vals, colours, parts):
            ax1.barh(y, v, left=left, color=c, label=p if y == 0 else None)
            if v >= 30:
                ax1.text(left + v / 2, y, f'{v:.0f}', ha='center', va='center', color='white', fontsize=9)
            left += v
        ax1.text(left + 6, y, f'{left:.0f}', va='center', fontsize=9)
    ax1.set_yticks(range(len(cols)), [c[0] for c in reversed(cols)])
    ax1.set_xlabel('wall frames (both tasks)')
    ax1.set_xlim(0, 640)
    ax1.set_title('A simulation pass in wall frames: the three parts (doc 4.6)')
    ax1.legend(loc='upper right', fontsize=8)

    ax2.plot([p[0] for p in city2], [p[5] for p in city2], '.', color='#c04040', ms=4, label='city2 (FAST)')
    ax2.plot([p[0] for p in metro], [p[5] for p in metro], '.', color='#2060c0', ms=4, label='metro (FAST)')
    ax2.plot([80], [m80[5]], 'o', mfc='none', mec='black', ms=10)
    ax2.annotate('metro pass 80: 575, the heaviest plain pass', (80, m80[5]), (95, m80[5] + 120),
                 arrowprops={'arrowstyle': '->'}, fontsize=9)
    ax2.set_xlabel('pass number')
    ax2.set_ylabel('wall frames')
    ax2.set_ylim(0, 1000)
    ax2.set_title('Every pass of city2 and metro (the spikes are passes with a dialog open, doc 4.9)')
    ax2.legend(loc='upper left', fontsize=8)
    ax2.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(out, dpi=100)
    print(out, [(c[0], [round(v, 1) for v in c[1]]) for c in cols])


if __name__ == '__main__':
    main()

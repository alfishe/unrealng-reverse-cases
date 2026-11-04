#!/usr/bin/env python3
"""The case's cost as a figure: the lead session and its subagents over time, with their output tokens.

    python3 tools/case_cost.py work/cost/tokens.json docs/img/case-cost.png

tokens.json is written by work/cost/tokens.py from the Claude Code transcripts of the session (not in the
repository); WALKTHROUGH 8 has the numbers.
"""
import json
import sys
from datetime import datetime

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

NAMES = {  # the brief ids (WALKTHROUGH 6) and what each agent did
    'r1': 'r1 start, menus, turn', 'r2': 'r2 world, robots', 'r3': 'r3 enemy, bases, level',
    'r4': 'r4 menu, music, build menu', 'r5': 'r5 view, screen, irq', 'd1': 'd1 data', 'lab': 'lab inner labels',
    'res': 'res resources', 'docA': 'docA docs 01-04', 'docB': 'docB docs 05-07', 'docC': 'docC docs 08-10',
    'ill1': 'ill1 doc 10 events', 'ill2': 'ill2 06/07 rendering', 'ill3': 'ill3 01-09 ui, sound',
    'cmA': 'cmA world', 'cmB': 'cmB enemy, bases, turn, ship', 'cmC': 'cmC start, menus',
    'cmD': 'cmD view, screen, print, irq', 'cmE': 'cmE menus, music, data', 'cmF': 'cmF data rows'}
COLOURS = {'r': '#4C72B0', 'd': '#4C72B0', 'l': '#55A868', 'p': '#999999', 'docA': '#C44E52', 'ill': '#8172B2',
           'cm': '#CCB974'}


def colour(label):
    for key in ('ill', 'cm', 'docA'):
        if label.startswith(key):
            return COLOURS[key]
    if label.startswith('doc'):
        return COLOURS['docA']
    if label.startswith('res') or label.startswith('lab'):
        return COLOURS['l']
    return COLOURS.get(label[0], '#4C72B0')


def main():
    data = json.load(open(sys.argv[1]))
    t = lambda s: datetime.fromisoformat(s.replace('Z', '+00:00'))  # noqa: E731
    rows = [r for r in data['rows'] if r[4] in NAMES]
    t0 = t(rows[0][0])
    fig, ax = plt.subplots(figsize=(12, 7), dpi=110)
    for i, (a, b, out, inp, _) in enumerate(rows):
        label = NAMES[rows[i][4]]
        x0 = (t(a) - t0).total_seconds() / 60
        w = max((t(b) - t(a)).total_seconds() / 60, 1)
        ax.barh(i, w, left=x0, color=colour(label), edgecolor='black', linewidth=0.4)
        ax.text(x0 + w + 1, i, '%s  %dk out' % (label, out // 1000), va='center', fontsize=8)
    ax.invert_yaxis()
    ax.set_yticks([])
    ax.set_xlabel('minutes from the first wave (%s UTC)' % t0.strftime('%Y-%m-%d %H:%M'))
    lead = data['lead']
    subs = data['subs']
    n = len(rows)
    ax.set_title('Nether Earth: the subagents over time (lead: %dk output tokens; %d subagents: %dk output, %.1f M '
                 'input of which %.1f M cache reads)' % (lead['output'] // 1000, n, subs['output'] // 1000,
                                                       (subs['input'] + subs['cache_write'] + subs['cache_read']) / 1e6,
                                                       subs['cache_read'] / 1e6), fontsize=9)
    ax.set_xlim(-5, ax.get_xlim()[1] + 60)
    ax.grid(axis='x', alpha=0.3)
    fig.subplots_adjust(left=0.02, right=0.98, top=0.93, bottom=0.08)
    fig.savefig(sys.argv[2])


if __name__ == '__main__':
    main()

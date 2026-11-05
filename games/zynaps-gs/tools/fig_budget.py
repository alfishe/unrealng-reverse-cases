#!/usr/bin/env python3
"""Doc 02 figure: where the CPU's time goes in play, per module of src/game/game.ann and per GS part, from an L1
build of a window of r1 (re_session.py build).

    python3 tools/fig_budget.py work/zgsA/r1-play/l1.json docs/img/arch/budget-play.png --title T

A module's share is the T-states of the instructions after an entry written under that @module (up to the next
entry) over the window's T-states. Code outside the game's modules is named by where it runs: bank 1 (the GS
driver), the stubs at $FF1C-$FFD1, the trampolines at $B446-$B4A7, the beeper-call stubs ($A6AE, $AA28, $B2F0) and
HALT (the CPU waiting for the interrupt, counted by the instruction's own T-states).
"""
import argparse
import json
import os
import re
import bisect

import zgsplot as P

HERE = os.path.dirname(os.path.abspath(__file__))
GS = [('GS driver (bank 1)', None, None), ('GS stubs $FF1C', 0xFF1C, 0xFFD1), ('GS trampolines $B446', 0xB446, 0xB4A7)]


def modules(ann):
    """every entry of game.ann with the module it is written under (the modules are not in address order)"""
    out, current = [], None
    for line in open(ann):
        m = re.match(r'@module (\w+)', line)
        if m:
            current = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) ', line)
        if m and current:
            out.append((int(m.group(1), 16), current))
    return sorted(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('l1')
    ap.add_argument('png')
    ap.add_argument('--title', required=True)
    ap.add_argument('--top', type=int, default=16)
    a = ap.parse_args()
    d = json.load(open(a.l1))
    total = d['replay']['tstates']
    starts = modules(os.path.join(HERE, '..', 'src', 'game', 'game.ann'))
    keys = [a for a, _ in starts]
    share = {}
    for z80, page, code, cls, count, t, *_ in d['instructions']:
        addr = int(z80[1:], 16)
        if page == 1 and addr >= 0xC000:
            name = 'GS driver (bank 1)'
        elif 0xFF1C <= addr <= 0xFFD1:
            name = 'GS stubs $FF1C'
        elif 0xB446 <= addr <= 0xB4A7:
            name = 'GS trampolines $B446'
        elif code == '76':
            name = 'HALT (waiting)'
        else:
            i = bisect.bisect_right(keys, addr) - 1
            name = starts[i][1] if i >= 0 else '?'

        share[name] = share.get(name, 0) + t
    rows = sorted(share.items(), key=lambda kv: -kv[1])
    shown = rows[:a.top]
    rest = sum(v for _, v in rows[a.top:])
    gs = [(k, v) for k, v in rows[a.top:] if k.startswith('GS')]
    shown += gs
    rest -= sum(v for _, v in gs)
    if rest:
        shown.append((f'{len(rows) - len(shown)} other modules', rest))
    P.style()
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(9, 0.32 * len(shown) + 1.4), dpi=100)
    names = [k for k, _ in shown][::-1]
    vals = [100 * v / total for _, v in shown][::-1]
    colours = [P.COLOURS[2] if n.startswith('GS') else P.COLOURS[0] if not n.startswith('HALT') else P.DIM
               for n in names]
    ax.barh(names, vals, color=colours)
    for y, v in enumerate(vals):
        ax.text(v + 0.3, y, f'{v:.2f} %' if v < 1 else f'{v:.1f} %', va='center', color=P.TEXT, fontsize=9)
    ax.set_xlabel(f'share of the {total:,} T-states of {d["replay"]["frames"]} frames '
                  f'({d["replay"]["first_frame"]}-{d["replay"]["last_frame"]})')
    ax.set_title(a.title, color=P.TEXT, fontsize=11)
    fig.tight_layout()
    fig.savefig(a.png)
    for k, v in rows:
        print(f'{k:28s} {100 * v / total:6.2f} %')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The numbers of docs 02, 04 and 06 from an L1 build: each routine's entries, its own and inclusive T-states, its
share of the recording's T-states and T-states a call, with the names of the game's listing; the calls between
routines with their counts; the ports a routine touched.

    python3 tools/l1_table.py --l1 work/gsA/deep/l1.json [--sym build/game/game-scl.sym] [--names A,B,...]
                              [--calls NAME] [--top N] [--ports]

--names prints only those routines (labels of the listing, or $ADDR); --calls NAME prints NAME's callers and
callees with the call counts; --top N the N routines with the most inclusive T. A Pentagon frame is 71680 T.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
FRAME_T = 71680


def symbols(path):
    out = {}
    for line in open(path):
        m = re.match(r'(\w+):\s+EQU\s+0x([0-9A-F]+)', line)
        if m and '.' not in m.group(1):
            out.setdefault(int(m.group(2), 16), m.group(1))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--l1', required=True)
    p.add_argument('--sym', default=os.path.join(CASE, 'build', 'game', 'game-scl.sym'))
    p.add_argument('--names')
    p.add_argument('--calls')
    p.add_argument('--top', type=int)
    p.add_argument('--ports', action='store_true')
    a = p.parse_args()
    d = json.load(open(a.l1))
    names = symbols(a.sym)
    total = d['replay']['tstates']
    print(f"recording: frames {d['replay']['first_frame']}-{d['replay']['last_frame']}, {d['replay']['frames']} frames, "
          f"{d['replay']['instructions']} instructions, {total} T ({total / FRAME_T:.1f} Pentagon frames), "
          f"{d['replay']['interrupts']} interrupts, checked {d['replay']['checked']}, diverged {d['replay']['diverged']}")
    rows = []
    for i, r in enumerate(d['routines']):
        addr = int(r['entry'][1:], 16)
        name = names.get(addr, r['entry']) if r['page'] in (0, 2, 5) or addr < 0xC000 else f"bank{r['page']}:{r['entry']}"
        if addr < 0x4000:
            name = f'ROM {r["entry"]}'
        pr = r['profile']
        rows.append((i, name, addr, pr, r))
    by_index = {i: (name, addr) for i, name, addr, _, _ in rows}

    def show(rs):
        print('| Routine | Entries | Own T | Inclusive T | Share | T a call | Frames a call |')
        print('| --- | ---: | ---: | ---: | ---: | ---: | ---: |')
        for i, name, addr, pr, r in rs:
            e = pr['entries'] or 1
            print(f"| `{name}` `${addr:04X}` | {pr['entries']} | {pr['tstates']} | {pr['tstates_inclusive']} | "
                  f"{100 * pr['tstates_inclusive'] / total:.1f} % | {pr['tstates_inclusive'] // e} | "
                  f"{pr['tstates_inclusive'] / e / FRAME_T:.2f} |")
            if a.ports and (pr['ports_in'] or pr['ports_out']):
                print('    ports in', pr['ports_in'], 'out', pr['ports_out'])

    if a.names:
        want = a.names.split(',')
        show([x for x in rows if x[1] in want or f'${x[2]:04X}' in want])
    if a.top:
        show(sorted(rows, key=lambda x: -x[3]['tstates_inclusive'])[:a.top])
    if a.calls:
        me = [i for i, name, addr, _, _ in rows if name == a.calls or f'${addr:04X}' == a.calls]
        for c in d['calls']:
            if c['caller'] in me:
                print(f"  calls {by_index[c['callee']][0]} x{c['count']} ({c['kind']}) at {','.join(c['sites'][:4])}")
            if c['callee'] in me:
                print(f"  called by {by_index[c['caller']][0]} x{c['count']} ({c['kind']}) at {','.join(c['sites'][:4])}")
    if not (a.names or a.top or a.calls):
        show(sorted(rows, key=lambda x: x[2]))


if __name__ == '__main__':
    sys.exit(main())

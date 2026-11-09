#!/usr/bin/env python3
"""Doc 04 table: MainLoop's 54 calls in order, each with its group, its run count and its T-states in traced passes.

    python3 tools/mainloop_calls.py --l1 work/c1/l1.json \
        --trace work/docs/docA/c1/traces/16186_50000-16191_10000.uatr \
        --trace work/docs/fillL/c1/traces/20184_50000-20191_0.uatr

- The calls come from `build/game.lst`, MainLoop `$75BE` to its `JP MainLoop`: every `CALL nn` and `CALL C,nn`.
- The group is the one `tools/fig_pass.py` colours the call with.
- The run count is the L1's count of executions of the `CALL` instruction itself; for a `CALL C,nn` also the count
  of calls from MainLoop to the callee, all its sites together (a conditional call taken every time adds a full
  share).
- The T-states: for each `CALL` executed in a complete pass of a trace, the time from the `CALL` to the first
  instruction back at the return address (the callee and everything it calls). One column per complete pass.

Prints a markdown table and the per-pass totals.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import fig_pass  # noqa: E402

LO, HI = 0x75BE, 0x768B


def listing_calls():
    calls = []
    for line in open(os.path.join(CASE, 'build', 'game.lst'), encoding='utf-8'):
        m = re.match(r'^\s*\d+\+?\s+([0-9A-F]{4})\s+(?:[0-9A-F]{2} ){3}\s*CALL (C,)?(\w+)', line)
        if m and LO <= int(m.group(1), 16) <= HI:
            calls.append((int(m.group(1), 16), m.group(3), bool(m.group(2))))
    return calls


def l1_counts(path):
    d = json.load(open(path))
    execs = {int(x[0][1:], 16): x[4] for x in d['instructions'] if x[1] in (2, 5)}
    routines = d['routines']
    entry = {i: int(r['entry'][1:], 16) for i, r in enumerate(routines)}
    main = [i for i, a in entry.items() if a == 0x758A or a == LO]
    per_callee = {}
    for c in d['calls']:
        if c['caller'] in main:
            per_callee[entry[c['callee']]] = per_callee.get(entry[c['callee']], 0) + c['count']
    return execs, per_callee


def trace_times(path, sites):
    class A:
        trace, unreal, work, window = path, None, None, None
    tr = K.load_trace(A())
    u = max(1, tr.units_per_t)
    passes, cur, open_call = [], None, None
    for x in tr.instructions:
        ab = x.frame * tr.frame_t + x.t // u
        if x.pc == LO:
            if cur is not None:
                cur['end'] = ab
                passes.append(cur)
            cur = {'start': (x.frame, x.t // u), 't0': ab, 'calls': []}
        if open_call and x.pc == open_call[0] + 3:
            if cur is not None:
                cur['calls'].append((open_call[0], ab - open_call[1]))
            open_call = None
        if x.pc in sites and open_call is None:
            open_call = (x.pc, ab)
    return passes


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--l1', required=True)
    p.add_argument('--trace', action='append', default=[])
    a = p.parse_args()
    names = fig_pass.ann_entries()
    group = {}
    for g, _, rs in fig_pass.GROUPS:
        for r in rs.split():
            group[r] = g.split(' (')[0].split(':')[0]
    calls = listing_calls()
    execs, per_callee = l1_counts(a.l1)
    sites = {s for s, _, _ in calls}
    cols = []
    for t in a.trace:
        for ps in trace_times(t, sites):
            cols.append(ps)
    head = '| # | `CALL` at | Routine | Group | Runs (L1) |' + ''.join(
        f' T, pass {ps["start"][0]}:{ps["start"][1]} |' for ps in cols)
    print(head)
    print('| ---: | --- | --- | --- | ---: |' + ' ---: |' * len(cols))
    for k, (s, name, cond) in enumerate(calls, 1):
        ex = execs.get(s, 0)
        rcell = f'{ex}' if not cond else f'{ex} (all calls of it {per_callee.get(names.get(name), 0)})'
        tcells = ''
        for ps in cols:
            ts = [t for site, t in ps['calls'] if site == s]
            tcells += f' {ts[0]} |' if ts else ' - |'
        label = name + (' (if GrenadeTimer < `$13`)' if cond else '')
        print(f'| {k} | `${s:04X}` | {label} `${names.get(name, 0):04X}` | {group.get(name, "")} | {rcell} |{tcells}')
    for ps in cols:
        tot = sum(t for _, t in ps['calls'])
        print(f'pass {ps["start"]}: length {ps["end"] - ps["t0"]} T, inside calls {tot} T, {len(ps["calls"])} calls')


if __name__ == '__main__':
    main()

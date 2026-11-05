#!/usr/bin/env python3
"""Facts of the L1 builds (work/*/l1.json) about a routine or a memory range, for the annotations' evidence.

    python3 tools/l1info.py routine ADDR [--build B]      # entries, frames, T-states, callers, callees, memory, ports
    python3 tools/l1info.py who LO[-HI] [--build B]       # the routines that read / write / run bytes in LO..HI
    python3 tools/l1info.py list [--build B]              # every routine: entry, entries, permille of the time

ADDR, LO, HI in hex ($ optional). --build names one work/<B>/l1.json; default every build.
"""
import argparse
import glob
import json
import os

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_cache = {}


def builds(name=None):
    paths = [os.path.join(CASE, 'work', name, 'l1.json')] if name else \
        sorted(glob.glob(os.path.join(CASE, 'work', '*', 'l1.json')))
    for p in paths:
        if p not in _cache:
            _cache[p] = json.load(open(p))
        yield os.path.basename(os.path.dirname(p)), _cache[p]


def hexa(t):
    return int(t.lstrip('$'), 16)


def ranges(items):
    return ', '.join(f"{r['from']}-{r['to']}" for r in items[:12]) + (' ...' if len(items) > 12 else '')


def routine(args):
    a = hexa(args.addr)
    for name, d in builds(args.build):
        rs = d['routines']
        for k, r in enumerate(rs):
            if hexa(r['entry']) != a:
                continue
            p = r['profile']
            callers = [(rs[c['caller']]['entry'], c['kind'], c['count']) for c in d['calls'] if c['callee'] == k]
            callees = [(rs[c['callee']]['entry'], c['kind'], c['count']) for c in d['calls'] if c['caller'] == k]
            print(f"[{name}] {r['entry']} {r['kinds']}: {p['entries']} entries in {p['active_frames']} frames "
                  f"({p['first_frame']}-{p['last_frame']}), {p['tstates']} T own, {p['tstates_inclusive']} T with callees, "
                  f"{p['tstates_permille']} permille")
            print('  callers:', ', '.join(f'{e} ({kd} x{n})' for e, kd, n in callers) or '-')
            print('  callees:', ', '.join(f'{e} ({kd} x{n})' for e, kd, n in callees) or '-')
            print('  reads:', ranges(p['reads']) or '-')
            print('  writes:', ranges(p['writes']) or '-')
            print('  executes:', ranges(p['executes']))
            if p['ports_in'] or p['ports_out']:
                print('  ports in:', p['ports_in'], 'out:', p['ports_out'])


def who(args):
    lo, _, hi = args.range.partition('-')
    lo = hexa(lo)
    hi = hexa(hi) if hi else lo
    for name, d in builds(args.build):
        for r in d['routines']:
            p = r['profile']
            for kind in ('reads', 'writes', 'executes'):
                hit = [x for x in p[kind] if hexa(x['from']) <= hi and hexa(x['to']) >= lo]
                if hit:
                    print(f"[{name}] {r['entry']} {kind} {ranges(hit)} ({p['entries']} entries)")


def listing(args):
    for name, d in builds(args.build):
        for r in sorted(d['routines'], key=lambda r: hexa(r['entry'])):
            p = r['profile']
            print(f"[{name}] {r['entry']} {r['kinds']:<12} entries {p['entries']:>7} permille {p['tstates_permille']:>4}")


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('command', choices=['routine', 'who', 'list'])
    p.add_argument('addr', nargs='?')
    p.add_argument('--build')
    args = p.parse_args()
    args.range = args.addr
    {'routine': routine, 'who': who, 'list': listing}[args.command](args)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""What the recordings' L1 builds say about addresses: the runs of an instruction, the reads and writes of a byte,
the callers of a routine, per build (work/<build>/l1.json of case.json and the part files).

    python3 tools/l1q.py ADDR [ADDR ...]            # runs / reads / writes per build, the callers (L1 call sites)
    python3 tools/l1q.py --range LO-HI              # every executed instruction start in LO..HI with its runs
    python3 tools/l1q.py --page 4 ADDR              # an address in bank 4 (page 4 at $C000)

ADDR is hex ($8DFE, 8DFE). Page: 5 for $4000-$7FFF, 2 for $8000-$BFFF, 0 for $C000 up, unless --page is given.
"""
import argparse
import glob
import json
import os

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_cache = {}


def builds():
    paths = sorted(glob.glob(os.path.join(CASE, 'work', 'stage1', 'c1', 'l1.json')) +
                   glob.glob(os.path.join(CASE, 'work', 'stage1', 'rec', '*', 'l1.json')) +
                   glob.glob(os.path.join(CASE, 'work', 'stage2', 'rzx', '*', 'l1.json')) +
                   glob.glob(os.path.join(CASE, 'work', 'stage2', 'rzx', 'rooms', '*', 'l1.json')) +
                   glob.glob(os.path.join(CASE, 'work', 'stage2', 'rec', '*', 'l1.json')))
    return [p for p in paths if '-old' not in p and '-lost' not in p]


def load(path):
    if path not in _cache:
        d = json.load(open(path))
        ins = {}
        for a, page, op, kind, n, t, _ in d['instructions']:
            ins[(page, int(a[1:], 16))] = (op, n)
        counts = {c['page']: c for c in d.get('byte_counts', [])}
        _cache[path] = (d, ins, counts)
    return _cache[path]


def page_of(a, page):
    if page is not None:
        return page
    return 5 if a < 0x8000 else 2 if a < 0xC000 else 0


def name(path):
    return os.path.relpath(os.path.dirname(path), os.path.join(CASE, 'work'))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('addr', nargs='*')
    p.add_argument('--range')
    p.add_argument('--page', type=int)
    a = p.parse_args()
    if a.range:
        lo, hi = (int(x.lstrip('$'), 16) for x in a.range.split('-'))
        tot = {}
        for path in builds():
            _, ins, _ = load(path)
            for (pg, ad), (op, n) in ins.items():
                if lo <= ad < hi and pg == page_of(ad, a.page):
                    tot.setdefault(ad, [op, 0, []])
                    tot[ad][1] += n
                    tot[ad][2].append(name(path).split('/')[-1])
        for ad in sorted(tot):
            print(f'${ad:04X} {tot[ad][0]:8} {tot[ad][1]:9}  {",".join(tot[ad][2])}')
        return
    for s in a.addr:
        ad = int(s.lstrip('$'), 16)
        pg = page_of(ad, a.page)
        print(f'== ${ad:04X} (page {pg})')
        for path in builds():
            d, ins, counts = load(path)
            base = {5: 0x4000, 2: 0x8000}.get(pg, 0xC000)
            c = counts.get(pg)
            r = w = x = 0
            if c:
                off = ad - base
                r = c['reads'][off] if 'reads' in c else 0
                w = c['writes'][off] if 'writes' in c else 0
                x = c['executes'][off] if 'executes' in c else 0
            op, n = ins.get((pg, ad), ('', 0))
            callers = []
            for call in d['calls']:
                pass
            if n or r or w:
                print(f'  {name(path):24} runs {n:8} {op:8} reads {r:8} writes {w:8}')


if __name__ == '__main__':
    main()

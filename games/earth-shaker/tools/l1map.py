#!/usr/bin/env python3
"""The address space of one or more L1 builds as runs of use: each run of bytes executed, read or written (or
untouched), merged over the builds, with the counts. The source of doc 2's memory-map table.

    python3 tools/l1map.py work/game/l1.json [work/runs/b1/l1.json ...] [--from 4000] [--to FFFF] [--gap 16]
"""
import argparse
import json

BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000, 261: 0x0000}


def load(paths):
    ex, rd, wr = [0] * 0x10000, [0] * 0x10000, [0] * 0x10000
    for p in paths:
        doc = json.load(open(p))
        for z80, page, code, _cls, count, *_ in doc['instructions']:
            a = int(z80[1:], 16)
            for k in range(len(code) // 2):
                ex[(a + k) & 0xFFFF] += count
        for bc in doc['byte_counts']:
            base = BASES.get(bc['page'])
            if base is None:
                continue
            for i in range(0x4000):
                rd[base + i] += bc['reads'][i]
                wr[base + i] += bc['writes'][i]
    return ex, rd, wr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('l1', nargs='+')
    ap.add_argument('--from', dest='lo', default='4000')
    ap.add_argument('--to', dest='hi', default='FFFF')
    ap.add_argument('--gap', type=int, default=16, help='merge runs of one kind across gaps up to this size')
    a = ap.parse_args()
    ex, rd, wr = load(a.l1)
    lo, hi = int(a.lo, 16), int(a.hi, 16) + 1

    def kind(i):
        return 'code' if ex[i] else ('data' if rd[i] or wr[i] else '-')
    runs, start = [], lo
    for i in range(lo + 1, hi + 1):
        if i == hi or kind(i) != kind(start):
            runs.append([start, i, kind(start)])
            start = i
    # an untouched gap of up to --gap bytes between two runs of the same kind joins them
    merged = []
    for r in runs:
        if (len(merged) >= 2 and merged[-1][2] == '-' and merged[-1][1] - merged[-1][0] <= a.gap
                and merged[-2][2] == r[2]):
            merged.pop()
            merged[-1][1] = r[1]
        elif merged and merged[-1][2] == r[2]:
            merged[-1][1] = r[1]
        else:
            merged.append(list(r))
    for s, e, k in merged:
        x = sum(ex[s:e]); r = sum(rd[s:e]); w = sum(wr[s:e])
        print(f'{s:04X}-{e - 1:04X} {e - s:6d} {k:5s} exec {x:10d} reads {r:10d} writes {w:10d}')


if __name__ == '__main__':
    main()

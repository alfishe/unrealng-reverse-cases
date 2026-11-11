#!/usr/bin/env python3
"""The address space of several L1 builds as coarse regions for doc 2's memory map: each byte marked code (executed),
written (more writes than the snapshot loads and the tape load give: above BASE a build) or read (likewise), else
untouched; runs of one kind shorter than GAP bytes are folded into their neighbour.

    python3 tools/l1regions.py work/stage1/menu/l1.json ... [--gap 32] [--base 3]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l1map import load  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('l1', nargs='+')
    ap.add_argument('--gap', type=int, default=32)
    ap.add_argument('--base', type=int, default=3)
    ap.add_argument('--from', dest='lo', default='4000')
    a = ap.parse_args()
    ex, rd, wr = load(a.l1)
    base = a.base * len(a.l1)
    lo = int(a.lo, 16)
    kind = []
    for i in range(lo, 0x10000):
        kind.append('code' if ex[i] else 'written' if wr[i] > base else 'read' if rd[i] > base else '-')
    runs = []
    for i, k in enumerate(kind):
        if runs and runs[-1][2] == k:
            runs[-1][1] = i
        else:
            runs.append([i, i, k])
    changed = True
    while changed:
        changed = False
        for j, r in enumerate(runs):
            if r[1] - r[0] + 1 < a.gap and len(runs) > 1:
                n = runs[j - 1] if j else runs[j + 1]
                n[0], n[1] = min(n[0], r[0]), max(n[1], r[1])
                del runs[j]
                changed = True
                break
        merged = []
        for r in runs:
            if merged and merged[-1][2] == r[2]:
                merged[-1][1] = r[1]
            else:
                merged.append(r)
        runs = merged
    for s, e, k in runs:
        s, e = s + lo, e + lo
        x = sum(ex[s:e + 1]); w = sum(wr[s:e + 1]); r = sum(rd[s:e + 1])
        print(f'{s:04X}-{e:04X} {e - s + 1:6d} {k:8s} exec {x:11d} reads {r:10d} writes {w:10d}')


if __name__ == '__main__':
    main()

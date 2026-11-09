#!/usr/bin/env python3
"""The byte counts of doc 02's memory map table: per region of tools/memmap-regions.txt, how many bytes the union of
the given L1 builds executed (X, XR), read only (R), wrote (W, WR, XW) or never touched (-).

    python3 tools/regcounts.py work/stage1/c1/l1.json work/runs/*/l1.json
"""
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import l1map  # noqa: E402


def main():
    ex, rd, wr = l1map.load(sys.argv[1:])
    print('range      bytes  X     R     W     -     what')
    for line in open(os.path.join(HERE, 'memmap-regions.txt')):
        if not line.strip() or line.startswith('#'):
            continue
        lo, hi, name = line.split(None, 2)
        lo, hi = int(lo, 16), int(hi, 16)
        c = collections.Counter(l1map.klass(ex[a], rd[a], wr[a]) for a in range(lo, hi + 1))
        x = c['X'] + c['XR']
        w = c['W'] + c['WR'] + c['XW']
        print(f"{lo:04X}-{hi:04X} {hi - lo + 1:5} {x:5} {c['R']:5} {w:5} {c['-']:5} {name.strip()}")


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The game bytes the recordings executed: the union of the L1 blocks of the given work folders, each block from its
first byte to its "end", which the L1 gives as the last byte of its last instruction.

    python3 tools/coverage.py work/c1 work/m1 work/w/*      # the total, and the unexecuted gaps of 16 bytes or more
    python3 tools/coverage.py --new work/m1 -- work/c1 work/w/*   # bytes m1 executed that the others did not
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import image  # noqa: E402

LO = image.GAME_AT


def executed(work):
    d = json.load(open(os.path.join(work, 'l1.json')))
    out = set()
    for b in d['blocks']:
        s, e = int(b['start'][1:], 16), int(b['end'][1:], 16)
        if s < LO:
            continue
        out.update(range(s, e + 1))
    return out


def main():
    args = sys.argv[1:]
    new = args[0] == '--new'
    if new:
        args = args[1:]
    if new:
        k = args.index('--')
        a = set().union(*(executed(w) for w in args[:k]))
        b = set().union(*(executed(w) for w in args[k + 1:]))
        sel = sorted(a - b)
        print(f'{len(sel)} bytes new')
    else:
        a = set().union(*(executed(w) for w in args))
        print(f'{len(a)} bytes executed of {0x10000 - LO}')
        sel = sorted(set(range(LO, 0x10000)) - a)
    runs, start = [], None
    for i, x in enumerate(sel):
        if start is None:
            start = x
        if i + 1 == len(sel) or sel[i + 1] != x + 1:
            runs.append((start, x))
            start = None
    for s, e in runs:
        if new or e - s >= 15:
            print(f'{s:04X}-{e:04X}', end=' ')
    print()


if __name__ == '__main__':
    main()

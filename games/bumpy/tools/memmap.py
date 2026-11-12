#!/usr/bin/env python3
"""The memory map's raw material from a (merged) L1 build: runs of bytes by use (x executed, w written, r only read,
. untouched) over $4000-$FFFF, runs shorter than --min folded into their neighbour's text, and the stack's low mark
(the lowest byte written in $5CB6-$61A7 below the CLEAR 24999 RAMTOP, with the bytes written there).

    python3 tools/memmap.py work/stage1/l1-all.json [--min 16]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import heatmap as H  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('l1')
    p.add_argument('--min', type=int, default=16)
    a = p.parse_args()
    ex, rd, wr, _last, rep = H.load(a.l1, H.BASES_48K)

    def kind(q):
        return 'x' if ex[q] else 'w' if wr[q] else 'r' if rd[q] else '.'
    runs = []
    for q in range(0x4000, 0x10000):
        k = kind(q)
        if runs and runs[-1][2] == k:
            runs[-1][1] = q
        else:
            runs.append([q, q, k])
    print('frames', rep['frames'])
    for s, e, k in runs:
        if e - s + 1 >= a.min:
            print(f'${s:04X}-${e:04X} {e - s + 1:6d} {k}')
    low = next((q for q in range(0x5CB6, 0x61A8) if wr[q]), None)
    stack = [q for q in range(0x5CB6, 0x61A8) if wr[q]]
    print('stack low mark', f'${low:04X}' if low is not None else None, 'bytes written below $61A8:', len(stack),
          f'${stack[0]:04X}-${stack[-1]:04X}' if stack else '')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Byte ranges where two images differ: byte_diff.py A.bin@BASE B.bin@BASE [--from HEX --to HEX] [--gap N]
Prints each differing run (runs closer than --gap bytes are joined) with its length."""
import argparse
ap = argparse.ArgumentParser()
ap.add_argument('a'); ap.add_argument('b')
ap.add_argument('--from', dest='lo', default=None); ap.add_argument('--to', dest='hi', default=None)
ap.add_argument('--gap', type=int, default=4)
a = ap.parse_args()
def load(s):
    f, b = s.rsplit('@', 1); d = open(f, 'rb').read(); b = int(b, 16)
    m = bytearray(65536); m[b:b + len(d)] = d[:65536 - b]; return m, b, b + len(d)
A, alo, ahi = load(a.a); B, blo, bhi = load(a.b)
lo = int(a.lo, 16) if a.lo else max(alo, blo); hi = int(a.hi, 16) if a.hi else min(ahi, bhi)
runs = []
for x in range(lo, hi):
    if A[x] != B[x]:
        if runs and x - runs[-1][1] <= a.gap: runs[-1][1] = x + 1
        else: runs.append([x, x + 1])
tot = 0
for s, e in runs:
    n = sum(1 for x in range(s, e) if A[x] != B[x]); tot += n
    print(f'${s:04X}-${e - 1:04X} {e - s:5d} bytes, {n:5d} differ')
print(f'# {len(runs)} runs, {tot} bytes differ in ${lo:04X}-${hi - 1:04X}')

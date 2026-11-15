#!/usr/bin/env python3
"""The address ranges where two 64 K images differ ($4000-$FFFF; runs closer than GAP bytes joined).

    python3 tools/image_diff.py A.bin|A.szx B.bin|B.szx [--gap 16] [--from 5B00] [--to FFFF]

A snapshot (.szx, .z80) is read through tools/z80mem.py (the 64 K view).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import z80mem  # noqa: E402


def image(path):
    if path.endswith('.bin'):
        return open(path, 'rb').read()
    hdr, pages = z80mem.load(path)
    return bytes(65536 - 49152) + pages[5] + pages[2] + pages[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('a')
    ap.add_argument('b')
    ap.add_argument('--gap', type=int, default=16)
    ap.add_argument('--from', dest='frm', default='4000')
    ap.add_argument('--to', default='FFFF')
    x = ap.parse_args()
    a, b = image(x.a), image(x.b)
    lo, hi = int(x.frm, 16), int(x.to, 16)
    d = [i for i in range(lo, hi + 1) if a[i] != b[i]]
    rs = []
    for i in d:
        if rs and i - rs[-1][1] <= x.gap:
            rs[-1][1] = i
        else:
            rs.append([i, i])
    for s, e in rs:
        n = sum(1 for i in range(s, e + 1) if a[i] != b[i])
        print(f'${s:04X}-${e:04X} {e - s + 1:6d} bytes, {n} differ')
    print(f'{len(d)} bytes differ in ${lo:04X}-${hi:04X}')


if __name__ == '__main__':
    main()

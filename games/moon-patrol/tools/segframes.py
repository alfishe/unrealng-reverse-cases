#!/usr/bin/env python3
"""The frames a recording's course script pointer $B27A first enters each segment (tools/course.py), sampled every
STEP frames at the frame start, with the lives $B284 and the score: when each point and sector end was reached.

    python3 tools/segframes.py --work work/runs/i1 [--step 20]
"""
import argparse

import mplib as M
from timeline import seg_name


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--step', type=int, default=20)
    p.add_argument('--to', type=int, default=40000)
    args = p.parse_args()
    s = M.session(args.work)
    last = None
    for f in range(0, args.to, args.step):
        try:
            m = M.read(s, f, 0xB271, 0x20)
        except RuntimeError:
            break
        ptr = m[9] | m[10] << 8
        name = seg_name(ptr)
        if name != last:
            print('%6d %-14s $%04X lives %d score %02X%02X%02X%02X' % (f, name, ptr, m[0x13], m[1], m[2], m[3], m[4]))
            last = name


if __name__ == '__main__':
    main()

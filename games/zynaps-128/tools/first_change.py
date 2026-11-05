#!/usr/bin/env python3
"""The first moment (frame, T-state) in a recording at which a byte holds a value: a binary search over
time_travel memory_at between two moments.

    first_change.py --work W --addr FFFF --value 73 --from F[:T] --to F[:T] [--frame-t 71680]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from ttd_dump import read, session  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--addr', required=True)
    p.add_argument('--value', required=True)
    p.add_argument('--from', dest='lo', required=True)
    p.add_argument('--to', dest='hi', required=True)
    p.add_argument('--frame-t', type=int, default=71680, help='T-states a frame (Pentagon 71680)')
    a = p.parse_args()
    s = session(a.work)
    ft = a.frame_t
    addr, val = int(a.addr, 16), int(a.value, 16)

    def at(x):
        f, t = divmod(x, ft)
        return read(s, 'cpu', f, t, addr, 1)[0]

    def parse(text):
        f, _, t = text.partition(':')
        return int(f) * ft + int(t or 0)

    lo, hi = parse(a.lo), parse(a.hi)
    if at(hi) != val or at(lo) == val:
        raise SystemExit('the value is not absent at --from and present at --to')
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if at(mid) == val:
            hi = mid
        else:
            lo = mid
    print(f'{addr:04X} = {val:02X} first at frame {hi // ft} T {hi % ft}')


if __name__ == '__main__':
    main()

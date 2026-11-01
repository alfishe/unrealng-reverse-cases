#!/usr/bin/env python3
"""Pack a screen the way the loading screen of CODE "H_A_T_E.1" was packed; the inverse of screen_depack.py.

The bytes are taken in the unpacker's order (flag bit 0 set: by pixel lines across each third, then the
attributes). Zeros are always a run (00 N 00: the unpacker treats 00 as the escape), other bytes become a run from
four equal ones on; runs are at most 256 (N = 0).

    python3 screen_pack.py screen.scr packed.bin [--first 0 --thirds 3 --flags 1]
"""
import argparse


def order(first, thirds, across):
    for column in range(1 if across else 32):
        for third in range(thirds):
            for row in range(8):
                for line in range(8):
                    address = (first + third) * 0x800 + line * 0x100 + row * 32 + column
                    yield from range(address, address + (32 if across else 1))
    yield from range(0x1800 + first * 256, 0x1800 + (first + thirds) * 256)


def pack(screen, first=0, thirds=3, flags=1, min_run=4):
    stream = bytes(screen[a] for a in order(first, thirds, flags & 1))
    out = bytearray()
    i = 0
    while i < len(stream):
        v, j = stream[i], i
        while j < len(stream) and stream[j] == v and j - i < 256:
            j += 1
        n = j - i
        out += bytes([0, n & 0xFF, v]) if v == 0 or n >= min_run else bytes([v] * n)
        i = j
    return bytes(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('screen')
    p.add_argument('packed')
    p.add_argument('--first', type=int, default=0)
    p.add_argument('--thirds', type=int, default=3)
    p.add_argument('--flags', type=int, default=1)
    args = p.parse_args()
    screen = open(args.screen, 'rb').read()
    open(args.packed, 'wb').write(pack(screen, args.first, args.thirds, args.flags))


if __name__ == '__main__':
    main()

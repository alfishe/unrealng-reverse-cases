#!/usr/bin/env python3
"""A clone of the entry snapshot that starts on screen N, for exploration runs (never the evidence of a claim about
the game itself): work/snaps/entry.z80 with the ZXDB POKEs (lives, ammo, grenades, immunity, mines, traps), the
store of the screen number at $6D75 (LD ($8523),A of the entry) turned into NOPs, and $8523 = N.

    python3 tools/warp_snapshot.py N work/snaps/warp-NNN.z80
"""
import sys

POKES = {40221: 0, 33646: 0, 37456: 0, 40120: 201, 40110: 201, 39957: 201, 0x6D75: 0, 0x6D76: 0, 0x6D77: 0}


def main():
    n, out = int(sys.argv[1]), sys.argv[2]
    b = bytearray(open('work/snaps/entry.z80', 'rb').read())
    for a, v in {**POKES, 0x8523: n}.items():
        b[30 + a - 0x4000] = v
    open(out, 'wb').write(b)


if __name__ == '__main__':
    main()

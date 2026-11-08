#!/usr/bin/env python3
"""A snapshot of the moment the game is entered, read from a recording from power-on (c1): the 48K RAM at the
entry of $6D60 (frame 12376, T 62848 of c1), PC $6D60, SP $6D5E, IM 1, interrupts on (the loader's EI): a .z80 (v1,
uncompressed) to start bot and experiment runs without the 4-minute load.

    python3 tools/entry_snapshot.py --work work/c1 --out work/snaps/entry.z80
"""
import argparse
import struct

import exlib as X


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--at', default='12376:62848')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    f, t = (int(x) for x in args.at.split(':'))
    s = X.session(args.work)
    ram = X.read(s, f, 0x4000, 0xC000, t)
    # v1 header: A F BC HL PC SP I R flags DE BC' DE' HL' A' F' IY IX IFF1 IFF2 mode
    hdr = struct.pack('<BBHHHHBBBHHHHBBHHBBB', 0, 0, 0, 0, 0x6D60, 0x6D5E, 0x3F, 0, 0x00, 0, 0, 0, 0, 0, 0,
                      0x5C3A, 0, 1, 1, 1)
    open(args.out, 'wb').write(hdr + ram)
    print('wrote', args.out, len(hdr) + len(ram))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The load's claims of docs/03-build-and-load.md, checked against a recording from power-on (c1).

    python3 tools/check_load.py --work work/c1

Reads the recording's memory at each stage's moment (re_session.py stages gives them) and compares it with the
static decode of the tape blocks: the decrypted loader, the unpacked loading screen, the moved game image.
"""
import argparse
import os

import zynlib as Z
import tzxblocks
import depack_picy


def block(n):
    t = open(os.path.join(Z.CASE, 'work', 'media', 'tzx', 'Zynaps.tzx'), 'rb').read()
    for b in tzxblocks.parse(t):
        if b['index'] == n:
            return b['data'][1:-1]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--loader-entry', default='251:4195')
    p.add_argument('--picy-entry', default='1830:69547')
    p.add_argument('--stub-entry', default='12310:27461')
    p.add_argument('--game-entry', default='12323:59971')
    args = p.parse_args()
    s = Z.session(args.work)
    mom = lambda t: tuple(int(x) for x in t.split(':'))
    loader = bytearray(block(4))
    for i in range(0x13, 0x13 + 0x28C):
        loader[i] ^= loader[i + 1]
    f, t = mom(args.loader_entry)
    got = Z.read(s, f, 0xFC00, 0x300, t)
    print(f'decrypted loader at {f}:{t} ($FC13 entered): {sum(a != b for a, b in zip(got, loader))} of 768 bytes differ')
    f, t = mom(args.picy_entry)
    got = Z.read(s, f, 0x8000, 0x1000, t)
    print(f'picy at {f}:{t} ($8001 entered): {sum(a != b for a, b in zip(got, block(6)))} of 4096 bytes differ')
    scr, _ = depack_picy.depack(block(6))
    f, t = mom(args.stub_entry)
    got = Z.read(s, f, 0x4000, 6912, t)
    diff = [i for i in range(6912) if got[i] != scr[i]]
    print(f'screen at {f}:{t} ($5B00 entered): {len(diff)} of 6912 bytes differ from depack_picy.py'
          + (f' (first ${0x4000 + diff[0]:04X}, last ${0x4000 + diff[-1]:04X})' if diff else ''))
    got = Z.read(s, f, 0x5DA8, len(block(8)), t)
    print(f'code at {f}:{t}: {sum(a != b for a, b in zip(got, block(8)))} of {len(block(8))} bytes differ at $5DA8')
    f, t = mom(args.game_entry)
    got = Z.read(s, f, 0x61A8, 0x10000 - 0x61A8 - 1, t)
    print(f'game at {f}:{t} ($8000 entered): {sum(a != b for a, b in zip(got, block(8)))} of {len(block(8))} '
          f'bytes differ at $61A8-$FFFE')


if __name__ == '__main__':
    main()

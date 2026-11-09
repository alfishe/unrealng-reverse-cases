#!/usr/bin/env python3
"""A snapshot of the moment the game is entered, read from the power-on recording c1 (fast load): the 48K RAM at
the first instruction of $8000 (frame 256, T 58497 of c1) with the registers seen there (PC $8000, SP $C338, IM 1,
interrupts on): a .z80 (v1, uncompressed) to start input-script and clone runs without the load.

    python3 tools/entry_snapshot.py --work work/stage1/c1x --out work/snaps/entry.z80

The registers are those `inspect_state registers` gives after a seek to 256:58497 of c1.
"""
import argparse
import struct

import mplib as M

# A F BC HL PC SP I R flags DE BC' DE' HL' A' F' IY IX IFF1 IFF2 mode
REGS = dict(a=0x00, f=0x54, bc=0x8000, hl=0x2D2B, pc=0x8000, sp=0xC338, i=0x3F, r=0x1A, de=0x5D8C,
            bc_=0x0921, de_=0x369B, hl_=0x2758, a_=0x00, f_=0x44, iy=0x5C3A, ix=0x0000, im=1)


def z80(ram, regs=REGS, border=0):
    r = regs
    flags = ((r['r'] >> 7) & 1) | (border << 1)
    hdr = struct.pack('<BBHHHHBBBHHHHBBHHBBB', r['a'], r['f'], r['bc'], r['hl'], r['pc'], r['sp'], r['i'],
                      r['r'] & 0x7F, flags, r['de'], r['bc_'], r['de_'], r['hl_'], r['a_'], r['f_'], r['iy'],
                      r['ix'], 1, 1, r['im'])
    return hdr + ram


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--at', default='256:58497')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    f, t = (int(x) for x in args.at.split(':'))
    s = M.session(args.work)
    ram = M.read(s, f, 0x4000, 0xC000, t)
    open(args.out, 'wb').write(z80(ram))
    print('wrote', args.out)


if __name__ == '__main__':
    main()

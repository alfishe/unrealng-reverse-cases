#!/usr/bin/env python3
"""Clones of the entry snapshot for exploration runs (never the evidence of a claim about the game by themselves):
work/snaps/entry.z80 with

- --immune: the kill entry $A7DD (which starts the buggy's death: $B216 from $FF to 0) turned into RET;
- --segment ADDR: the course script pointer the game start puts in $B27A (LD BC,$B7E8 at $8F2F for the Beginner
  course, LD BC,$BB24 at $8F3A for the Champion course) changed to ADDR, a segment start of the course script
  (tools/course.py lists them), so play starts at that segment;
- --course 1|2: which of the two immediates --segment patches (the menu choice must match: option 2 for 2);
- --poke ADDR=BYTE: any other byte.

    python3 tools/warp_snapshot.py --immune --segment B896 --out work/snaps/warp-1-B896.z80
"""
import argparse
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ENTRY = os.path.join(HERE, '..', 'work', 'snaps', 'entry.z80')
SEGMENT_IMM = {1: 0x8F30, 2: 0x8F3B}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--immune', action='store_true')
    p.add_argument('--segment')
    p.add_argument('--course', type=int, default=1)
    p.add_argument('--poke', action='append', default=[])
    p.add_argument('--src', default=ENTRY)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    b = bytearray(open(args.src, 'rb').read())
    pokes = {}
    if args.immune:
        pokes[0xA7DD] = 0xC9
    if args.segment:
        a = int(args.segment, 16)
        imm = SEGMENT_IMM[args.course]
        pokes[imm], pokes[imm + 1] = a & 0xFF, a >> 8
    for item in args.poke:
        k, v = item.split('=')
        pokes[int(k, 16)] = int(v, 16)
    for a, v in pokes.items():
        b[30 + a - 0x4000] = v
    open(args.out, 'wb').write(b)
    print(args.out, ' '.join('$%04X=%02X' % kv for kv in sorted(pokes.items())))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The game bytes the recordings executed: the union of the L1 blocks of the given work folders, each block from its
first instruction to the end of its last one (the length decoded from the image by kit's Z80 length table).

    python3 tools/coverage.py work/c1 work/m1 work/w/*      # the total, and the unexecuted gaps of 16 bytes or more
    python3 tools/coverage.py --new work/m1 -- work/c1 work/w/*   # bytes m1 executed that the others did not
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import image  # noqa: E402

LO = image.GAME_AT


def oplen(m, a):
    """the length of the Z80 instruction at a"""
    b = m[a]
    if b in (0xDD, 0xFD):
        c = m[a + 1]
        if c == 0xCB:
            return 4
        if c in (0x21, 0x22, 0x2A, 0x36):
            return 4
        if c in (0x34, 0x35) or 0x46 <= c <= 0x7E and (c & 7 == 6 or c >> 3 & 7 == 6) and c != 0x76 \
                or c in (0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE):
            return 3
        return 1 + oplen(m, a + 1)
    if b == 0xED:
        c = m[a + 1]
        return 4 if c & 0xC7 == 0x43 else 2
    if b == 0xCB:
        return 2
    if b in (0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD) or b & 0xC7 in (0xC2, 0xC4):
        return 3
    if b in (0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0xD3, 0xDB) \
            or b & 0xC7 == 0xC6:
        return 2
    return 1


def executed(work, mem):
    d = json.load(open(os.path.join(work, 'l1.json')))
    out = set()
    for b in d['blocks']:
        s, e = int(b['start'][1:], 16), int(b['end'][1:], 16)
        if s < LO:
            continue
        out.update(range(s, e + oplen(mem, e)))
    return out


def main():
    args = sys.argv[1:]
    new = args[0] == '--new'
    if new:
        args = args[1:]
    mem = bytearray(0x10000 + 4)
    mem[LO:0x10000] = open(os.path.join(HERE, '..', 'work', 'mkgame', 'original.bin'), 'rb').read()
    if new:
        k = args.index('--')
        a = set().union(*(executed(w, mem) for w in args[:k]))
        b = set().union(*(executed(w, mem) for w in args[k + 1:]))
        sel = sorted(a - b)
        print(f'{len(sel)} bytes new')
    else:
        a = set().union(*(executed(w, mem) for w in args))
        print(f'{len(a)} bytes executed of {0x10000 - LO}')
        sel = sorted(set(range(LO, 0x10000)) - a)
    runs, start = [], None
    for i, x in enumerate(sel):
        if start is None:
            start = x
        if i + 1 == len(sel) or sel[i + 1] != x + 1:
            runs.append((start, x))
            start = None
    for s, e in runs:
        if new or e - s >= 15:
            print(f'{s:04X}-{e:04X}', end=' ')
    print()


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A plain Z80 listing of a 64 K memory dump (tools/z80mem.py OUT.bin), for reading code during the stages.

    python3 tools/z80list.py MEM.bin START [END|+COUNT]     # START, END hex; +COUNT instructions
"""
import sys

from z80dis import z80


def listing(mem, start, end=None, count=None):
    pc, n, out = start, 0, []
    while (end is None or pc < end) and (count is None or n < count) and pc < 0x10000:
        d = z80.decode(mem[pc:pc + 4] + b'\0\0\0\0', pc)
        ln = max(1, d.len)
        out.append(f'${pc:04X}  {mem[pc:pc + ln].hex(" ").upper():<12}  {z80.disasm(mem[pc:pc + 4] + bytes(4), pc)}')
        pc += ln
        n += 1
    return out


if __name__ == '__main__':
    mem = open(sys.argv[1], 'rb').read()
    s = int(sys.argv[2].lstrip('$'), 16)
    a = sys.argv[3] if len(sys.argv) > 3 else '+30'
    rows = listing(mem, s, count=int(a[1:])) if a.startswith('+') else listing(mem, s, int(a.lstrip('$'), 16))
    print('\n'.join(rows))

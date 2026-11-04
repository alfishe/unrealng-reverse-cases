#!/usr/bin/env python3
"""Unpack CODE "H_A_T_E.2" the way its depacker at $5B8C does, and write the 64 K image after it.

The block loads at $5FB4. Its first $64 bytes move the depacker to $5B8C, then move the packed data down by $64
bytes ($6018.. -> $5FB4..) with the ROM's LDIR; RET at $33C3 and return into the depacker. The depacker reads the
packed data backwards from $E9F6 down to $5FB4 and writes backwards from $FFFF:

    byte != $97          a literal
    $97 preceded by N    N & $80 set: N & $7F zeros if >= 3 (0 means 256), else N & $7F copies of $97
                         N & $80 clear: the byte before N, N times (0 means 256)
"""
import sys

MARKER = 0x97
LOAD = 0x5FB4
SHIFT = 0x64


def depack(mem, src_end, src_stop, dst):
    """Run the depacker on mem (a 64 K bytearray) and return the lowest address written."""
    hl, de = src_end, dst
    while hl != src_stop:
        a = mem[hl]
        if a != MARKER:
            mem[de] = a
            hl, de = hl - 1, de - 1
            continue
        hl -= 1
        b = mem[hl]
        if b & 0x80:
            b &= 0x7F
            a = 0 if (b == 0 or b >= 3) else MARKER
        else:
            hl -= 1
            a = mem[hl]
        for _ in range(b or 256):
            mem[de] = a
            de -= 1
        hl -= 1
    return de + 1


def main():
    block = open(sys.argv[1], 'rb').read()
    mem = bytearray(65536)
    mem[LOAD:LOAD + len(block)] = block
    mover_from = LOAD + SHIFT
    mem[LOAD:0x10000 - SHIFT] = mem[mover_from:0x10000]           # LDIR of $9FE8 bytes
    low = depack(mem, LOAD + len(block) - 1 - SHIFT, LOAD - 1, 0xFFFF)
    print(f'unpacked ${low:04X}-$FFFF ({0x10000 - low} bytes)')
    if len(sys.argv) > 2:
        open(sys.argv[2], 'wb').write(mem)


if __name__ == '__main__':
    main()

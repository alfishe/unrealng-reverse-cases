#!/usr/bin/env python3
"""The 48K memory ($4000-$FFFF, ROM area left zero) and the registers of an SZX snapshot, as a 64 K binary.

    python3 tools/szx.py state.szx out.bin        # writes the 64 K image, prints PC, SP, I, IM
"""
import struct
import sys
import zlib

PAGE_BASE_48K = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def read(path):
    data = open(path, 'rb').read()
    assert data[:4] == b'ZXST', 'not an SZX file'
    mem = bytearray(0x10000)
    regs = {}
    pos = 8
    while pos + 8 <= len(data):
        bid, size = data[pos:pos + 4], struct.unpack_from('<I', data, pos + 4)[0]
        body = data[pos + 8:pos + 8 + size]
        if bid == b'RAMP':
            flags, page = struct.unpack_from('<HB', body, 0)
            raw = body[3:]
            raw = zlib.decompress(raw) if flags & 1 else raw
            if page in PAGE_BASE_48K:
                base = PAGE_BASE_48K[page]
                mem[base:base + 0x4000] = raw[:0x4000]
        elif bid == b'Z80R':
            (af, bc, de, hl, af2, bc2, de2, hl2, ix, iy, sp, pc) = struct.unpack_from('<12H', body, 0)
            i, r, iff1, iff2, im = body[24], body[25], body[26], body[27], body[28]
            regs = dict(pc=pc, sp=sp, i=i, im=im, iff1=iff1, af=af, bc=bc, de=de, hl=hl, ix=ix, iy=iy)
        pos += 8 + size
    return mem, regs


if __name__ == '__main__':
    mem, regs = read(sys.argv[1])
    if len(sys.argv) > 2:
        open(sys.argv[2], 'wb').write(mem)
    print(' '.join(f'{k}={v:04X}' if k in ('pc', 'sp', 'ix', 'iy') else f'{k}={v}' for k, v in regs.items()
                   if k in ('pc', 'sp', 'i', 'im', 'iff1', 'ix')))

#!/usr/bin/env python3
"""The loading screen's unpacker ("picy", the block at $8000, entered at $8001), reimplemented.

    python3 depack_picy.py PICY.bin OUT.scr

The block holds its own offsets after the entry's JR: +3 the literal stream, +5 the mask stream, +7 the flag
stream (all relative to $8001), +9 the border colour. The 6912 screen bytes are written in order from $4000; per
8 x 8 bytes one flag bit (LSB first) says whether a mask byte follows in the mask stream (else the mask is 0); a mask
bit (LSB first) set repeats the previous screen byte, clear takes the next literal. The very first byte is a literal.
"""
import sys


def depack(blk, base=0x8000):
    entry = 0x8001 - base
    w = lambda o: blk[entry + o] | blk[entry + o + 1] << 8
    lit, masks, flags = entry + w(3), entry + w(5), entry + w(7)
    out = bytearray()
    first = True
    for _ in range(108):
        c = 1
        while c < 256:
            m = 0
            if blk[flags] & c:
                m = blk[masks]
                masks += 1
            b = 1
            while b < 256:
                if not first and m & b:
                    out.append(out[-1])
                else:
                    out.append(blk[lit])
                    lit += 1
                first = False
                b <<= 1
            c <<= 1
        flags += 1
    return bytes(out), dict(literal_end=lit + base, mask_end=masks + base, flag_end=flags + base,
                            border=blk[entry + 9])


if __name__ == '__main__':
    blk = open(sys.argv[1], 'rb').read()
    scr, info = depack(blk)
    open(sys.argv[2], 'wb').write(scr)
    print(len(scr), {k: (f'${v:04X}' if k != 'border' else v) for k, v in info.items()})

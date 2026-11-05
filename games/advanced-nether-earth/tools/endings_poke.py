#!/usr/bin/env python3
"""A start state for an ending's recording: a 128K SZX snapshot with bytes poked at Z80 addresses.

    python3 tools/endings_poke.py IN.szx OUT.szx ADDR=HEX [ADDR=HEX ...]

ADDR is a Z80 address (hex) as the CPU sees it in the snapshot: $4000-$7FFF bank 5, $8000-$BFFF bank 2, $C000-$FFFF
the bank port $7FFD selects (the SPCR block). Every other block is copied unchanged; the poked RAMP page is written
again compressed. Prints each poke with its old byte, so the start state of a recording is documented by the command
that wrote it (an experiment on the snapshot, never on the recording).
"""
import struct
import sys
import zlib


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    src, dst, pokes = sys.argv[1], sys.argv[2], sys.argv[3:]
    data = open(src, 'rb').read()
    if data[:4] != b'ZXST':
        sys.exit(f'{src}: not an SZX snapshot')
    blocks, at = [], 8
    while at < len(data):
        bid, size = data[at:at + 4], struct.unpack('<I', data[at + 4:at + 8])[0]
        blocks.append([bid, data[at + 8:at + 8 + size]])
        at += 8 + size
    spcr = next(body for bid, body in blocks if bid == b'SPCR')
    port = spcr[1]
    pages = {}
    for k, (bid, body) in enumerate(blocks):
        if bid == b'RAMP':
            flags, page = struct.unpack('<HB', body[:3])
            pages[page] = [k, bytearray(zlib.decompress(body[3:]) if flags & 1 else body[3:])]
    touched = set()
    for poke in pokes:
        a, _, value = poke.partition('=')
        a, value = int(a, 16), bytes.fromhex(value)
        for i, v in enumerate(value):
            addr = a + i
            page = {1: 5, 2: 2}.get(addr >> 14, port & 7) if addr >= 0x4000 else None
            if page is None:
                sys.exit(f'${addr:04X} is ROM')
            mem = pages[page][1]
            old = mem[addr & 0x3FFF]
            mem[addr & 0x3FFF] = v
            touched.add(page)
            print(f'${addr:04X} (bank {page} +${addr & 0x3FFF:04X}): ${old:02X} -> ${v:02X}')
    for page in touched:
        k, mem = pages[page]
        blocks[k][1] = struct.pack('<HB', 1, page) + zlib.compress(bytes(mem), 9)
    with open(dst, 'wb') as f:
        f.write(data[:8])
        for bid, body in blocks:
            f.write(bid + struct.pack('<I', len(body)) + body)
    print(f'{dst}: $7FFD = ${port:02X}')


if __name__ == '__main__':
    main()

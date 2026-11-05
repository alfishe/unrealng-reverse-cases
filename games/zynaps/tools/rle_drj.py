#!/usr/bin/env python3
"""The column-order RLE of the 1993 re-tape's zynaps0.c (src/tape/drj/zynaps0.asm), both ways.

    python3 tools/rle_drj.py pack SCREEN.scr OUT.rle
    python3 tools/rle_drj.py unpack IN.rle OUT.scr
    python3 tools/rle_drj.py check          # ZYNAPS.TAP's block 3: unpack, pack, the same stream

$D1 n: n zeros; $D4 v n: n times v (n = 0: 256); any other byte is itself. Every run of 3 or more (and any $D1 /
$D4 byte) is a token, runs at most 256. The pixels go column by column, the attributes in order.
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ZERO, VALUE = 0xD1, 0xD4


def order():
    out = []
    for x in range(32):
        for third in range(3):
            for row in range(8):
                for line in range(8):
                    out.append(0x800 * third + 0x20 * row + 0x100 * line + x)
    return out + list(range(6144, 6912))


def pack(scr):
    seq = bytes(scr[a] for a in order())
    out, i = bytearray(), 0
    while i < len(seq):
        v, n = seq[i], 1
        while i + n < len(seq) and seq[i + n] == v and n < 256:
            n += 1
        if n >= 3 or v in (ZERO, VALUE):
            out += bytes([ZERO, n & 255]) if v == 0 else bytes([VALUE, v, n & 255])
            i += n
        else:
            out.append(v)
            i += 1
    return bytes(out)


def unpack(data):
    seq, i = bytearray(), 0
    while len(seq) < 6912:
        b = data[i]
        if b == ZERO:
            seq += bytes(data[i + 1] or 256)
            i += 2
        elif b == VALUE:
            seq += bytes([data[i + 1]]) * (data[i + 2] or 256)
            i += 3
        else:
            seq.append(b)
            i += 1
    scr = bytearray(6912)
    for a, v in zip(order(), seq):
        scr[a] = v
    return bytes(scr), i


def tap_block(n):
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Zynaps.tap.zip')) as z:
        t = z.read('ZYNAPS.TAP')
    i = 0
    for _ in range(n):
        i += 2 + (t[i] | t[i + 1] << 8)
    return t[i + 3:i + 2 + (t[i] | t[i + 1] << 8) - 1]


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'pack':
        open(sys.argv[3], 'wb').write(pack(open(sys.argv[2], 'rb').read()))
    elif cmd == 'unpack':
        open(sys.argv[3], 'wb').write(unpack(open(sys.argv[2], 'rb').read())[0])
    elif cmd == 'check':
        stream = tap_block(3)[0x7F:]
        scr, used = unpack(stream)
        ok = used == len(stream) and pack(scr) == stream
        print(f'rle: {len(stream)} bytes for 6912; ' + ('repacked exactly' if ok else 'DIFFERS'))
        return 0 if ok else 1
    else:
        sys.exit(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main())

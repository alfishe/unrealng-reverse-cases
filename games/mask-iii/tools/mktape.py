#!/usr/bin/env python3
"""Write the tape of MASK III from the built parts, as orig/MASKIII-VENOMStrikesBack.tzx.zip holds it
(tools/build.sh):

    python3 tools/mktape.py src/tape/tape.txt OUT.tzx BUILD_DIR

The manifest (src/tape/tape.txt) lists the TZX blocks in order, one line a block (docs/03-build-and-load.md 3.1):

    tzx MAJOR.MINOR                       the file header ("ZXTape!", $1A, the version)
    text TEXT                             a text description block ($30)
    header PAUSE TYPE NAME LENGTH P1 P2   a standard ($10) ROM header block: flag $00, the type (0 Program, 3 Bytes),
                                          the name padded with spaces to 10, the length and P1 / P2 as numbers or
                                          "@FILE" (the file's length)
    data PAUSE FILE                       a standard ($10) block the ROM's LD-BYTES reads: flag $FF, the file's bytes,
                                          the XOR checksum (the XOR of all is 0)

PAUSE is the pause after the block in ms, as the original has it. Every block is a standard-speed block (pilot 2168
T, 8063 pulses for a header and 3223 for data, as the TZX's $10 block implies).
"""
import os
import sys


def std(pause, body):
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


def tape(manifest, build):
    def num(field):
        if field.startswith('@'):
            return len(open(os.path.join(build, field[1:]), 'rb').read())
        return int(field)

    out = bytearray()
    for line in open(manifest, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        kind, *f = line.split()
        if kind == 'tzx':
            major, minor = (int(x) for x in f[0].split('.'))
            out += b'ZXTape!\x1a' + bytes([major, minor])
        elif kind == 'text':
            text = line.split(None, 1)[1].encode('latin-1')
            out += bytes([0x30, len(text)]) + text
        elif kind == 'header':
            pause, typ, name, length, p1, p2 = f
            hdr = bytes([0, int(typ)]) + name.encode('ascii').ljust(10) + num(length).to_bytes(2, 'little') + \
                num(p1).to_bytes(2, 'little') + num(p2).to_bytes(2, 'little')
            out += std(int(pause), hdr + bytes([xor(hdr)]))
        elif kind == 'data':
            body = bytes([0xFF]) + open(os.path.join(build, f[1]), 'rb').read()
            out += std(int(f[0]), body + bytes([xor(body)]))
        else:
            sys.exit(f'{manifest}: cannot read: {line}')
    return bytes(out)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    open(sys.argv[2], 'wb').write(tape(sys.argv[1], sys.argv[3]))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Write a side of the tape of Rex from the built parts, as orig/Rex.tzx.zip holds it (tools/build.sh):

    python3 tools/mktape.py src/tape/side1.txt OUT.tzx BUILD_DIR
    python3 tools/mktape.py --orig 1|2 OUT.tzx                       # the original side, unchanged

A manifest (src/tape/side1.txt, side2.txt) lists the TZX blocks in order, one line a block (docs/03-build-and-load.md
3.1):

    tzx MAJOR.MINOR                       the file header ("ZXTape!", $1A, the version)
    text TEXT                             a text description block ($30)
    header PAUSE TYPE NAME LENGTH P1 P2   a standard ($10) ROM header block: flag $00, the type (0 Program, 3 Bytes),
                                          the name padded with spaces to 10 ("_" for a space), the length ("@FILE":
                                          the file's), P1 and P2
    data PAUSE FILE                       a standard ($10) block the ROM's LD-BYTES reads: flag $FF, the file's bytes,
                                          the XOR checksum

PAUSE is the pause after the block in ms, as the original has it. Every data block is at the ROM's standard timings,
which a $10 block implies.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import parts  # noqa: E402


def std(pause, body):
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


def with_sum(body):
    return body + bytes([xor(body)])


def tape(manifest, build):
    out = bytearray()
    for line in open(manifest, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        word, _, rest = line.partition(' ')
        if word == 'tzx':
            major, minor = (int(x) for x in rest.split('.'))
            out += b'ZXTape!\x1a' + bytes([major, minor])
        elif word == 'text':
            t = rest.encode('latin-1')
            out += bytes([0x30, len(t)]) + t
        elif word == 'header':
            pause, kind, name, length, p1, p2 = rest.split()
            if length.startswith('@'):
                length = len(open(os.path.join(build, length[1:]), 'rb').read())
            body = bytes([0, int(kind)]) + name.replace('_', ' ').ljust(10).encode('latin-1')
            body += int(length).to_bytes(2, 'little') + int(p1).to_bytes(2, 'little') + int(p2).to_bytes(2, 'little')
            out += std(int(pause), with_sum(body))
        elif word == 'data':
            pause, name = rest.split()
            out += std(int(pause), with_sum(b'\xff' + open(os.path.join(build, name), 'rb').read()))
        else:
            sys.exit(f'mktape: {manifest}: unknown line {line!r}')
    return bytes(out)


def main():
    a = sys.argv[1:]
    if a and a[0] == '--orig':
        open(a[2], 'wb').write(parts.side(int(a[1])))
        return
    if len(a) != 3:
        sys.exit(__doc__)
    open(a[1], 'wb').write(tape(a[0], a[2]))


if __name__ == '__main__':
    main()

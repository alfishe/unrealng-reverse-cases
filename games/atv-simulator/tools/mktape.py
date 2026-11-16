#!/usr/bin/env python3
"""Write ATV Simulator's TZX from a block list and the files the build makes (docs/03-build-and-load.md 3.1).

    python3 tools/mktape.py LIST.txt OUT.tzx BUILD_DIR

The list (src/tape/tape.txt), one TZX block a line, `#` a comment:

    version MAJOR MINOR                          the TZX header ("ZXTape!", $1A, MAJOR, MINOR)
    header PAUSE program NAME FILE LINE P2       a $10 standard-speed block: a ROM header (flag $00, type 0, NAME
                                                 padded to 10 with spaces, the length of FILE, LINE, P2)
    header PAUSE bytes NAME LENGTH START P2      a $10 block: a CODE header (type 3), its three words as given
    rom PAUSE SOURCE                             a $10 block: flag $FF, the bytes, the XOR checksum

PAUSE is the block's pause in ms. NAME `-` is the empty name (10 spaces). A SOURCE is a FILE in BUILD_DIR, or
`FILE@ORG:LO:HI` (the bytes LO to HI, HI exclusive, of a file that starts at address ORG; all hex).
"""
import os
import shlex
import sys


def u16(v):
    return v.to_bytes(2, 'little')


def block(flag, data):
    body = bytes([flag]) + data
    x = 0
    for b in body:
        x ^= b
    return body + bytes([x])


def source(spec, build):
    if '@' in spec:
        name, rng = spec.split('@')
        org, lo, hi = (int(v, 16) for v in rng.split(':'))
        return open(os.path.join(build, name), 'rb').read()[lo - org:hi - org]
    return open(os.path.join(build, spec), 'rb').read()


def lines(path):
    for n, line in enumerate(open(path), 1):
        line = line.strip()
        if line and not line.startswith('#'):
            yield n, shlex.split(line)


def num(v):
    return int(v[1:], 16) if v.startswith('$') else int(v)


def write(listing, out, build):
    tzx = bytearray()
    for n, w in lines(listing):
        if w[0] == 'version':
            tzx += b'ZXTape!\x1a' + bytes([int(w[1]), int(w[2])])
            continue
        pause = int(w[1])
        if w[0] == 'header':
            name = (b'' if w[3] == '-' else w[3].encode('ascii')).ljust(10)
            if w[2] == 'program':
                length = len(source(w[4], build))
                hdr = bytes([0]) + name + u16(length) + u16(num(w[5])) + u16(num(w[6]))
            else:
                hdr = bytes([3]) + name + u16(num(w[4])) + u16(num(w[5])) + u16(num(w[6]))
            data = block(0x00, hdr)
        elif w[0] == 'rom':
            data = block(0xFF, source(w[2], build))
        else:
            sys.exit(f'{listing}:{n}: unknown block "{w[0]}"')
        tzx += bytes([0x10]) + u16(pause) + u16(len(data)) + data
    open(out, 'wb').write(tzx)


if __name__ == '__main__':
    write(*sys.argv[1:4])

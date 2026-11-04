#!/usr/bin/env python3
"""Write a TZX (version 1.10) from a manifest, one block a line: the editor tape's own layout (tzx_blocks.py lists it).

    python3 tzx.py MANIFEST OUT.tzx

Manifest lines (paths relative to the manifest; `#` starts a comment):

    text TEXT...                               block $30, a text description
    header PAUSE program NAME LENGTH LINE      block $10: a standard header (flag 0) of a BASIC program
    header PAUSE bytes NAME LENGTH START [P2]  block $10: a CODE header (P2 default 32768)
    data PAUSE FLAG FILE                       block $10: FLAG, the file's bytes, the XOR checksum

PAUSE is the pause after the block in ms. NAME is padded to 10 characters (write `_` for a space inside it).
"""
import os
import sys


def std(pause, body):
    x = 0
    for b in body:
        x ^= b
    body = body + bytes([x])
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def build(manifest):
    base = os.path.dirname(os.path.abspath(manifest))
    out = bytearray(b'ZXTape!\x1a\x01\x0a')
    for line in open(manifest):
        line = line.split('#', 1)[0].rstrip('\n')
        if not line.strip():
            continue
        w = line.split()
        if w[0] == 'text':
            t = line.split(None, 1)[1].encode('latin-1')
            out += bytes([0x30, len(t)]) + t
        elif w[0] == 'header':
            pause, kind, name = int(w[1]), w[2], w[3].replace('_', ' ').encode('latin-1').ljust(10)
            nums = [int(v, 0) for v in w[4:]]
            if kind == 'program':
                length, line_no = nums
                h = bytes([0]) + name + length.to_bytes(2, 'little') + line_no.to_bytes(2, 'little') + \
                    length.to_bytes(2, 'little')
            else:
                length, start, p2 = (nums + [32768])[:3]
                h = bytes([3]) + name + length.to_bytes(2, 'little') + start.to_bytes(2, 'little') + \
                    p2.to_bytes(2, 'little')
            out += std(pause, bytes([0]) + h)
        elif w[0] == 'data':
            pause, flag = int(w[1]), int(w[2], 0)
            out += std(pause, bytes([flag]) + open(os.path.join(base, w[3]), 'rb').read())
        else:
            raise SystemExit(f'{manifest}: {line}')
    return bytes(out)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    open(sys.argv[2], 'wb').write(build(sys.argv[1]))

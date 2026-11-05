#!/usr/bin/env python3
"""The packer of Neart482's two self-extracting blocks (src/trd/neart482): the depacker in Python and a packer that
gives the original streams back, byte for byte.

    python3 tools/trd_lz.py unpack STREAM.bin OUT.bin            the stream -> the bytes (to its end code)
    python3 tools/trd_lz.py pack IN.bin OUT.bin --raw N            the bytes -> the stream, the last N bytes raw
    python3 tools/trd_lz.py tokens STREAM.bin                     one token a line

The packer is not named anywhere on the disk and the signature base has no entry for it (kit/sig_scan.py: no hit).
Its depacker (100 bytes, src/trd/neart482/sfx.asm) reads the stream forwards, byte-aligned, one token after
another:

    0LLLHHHH LLLLLLLL       a match: length LLL + 3 (3-10), from HHHH:LLLLLLLL (1-4095) bytes back; the source
                            never overlaps the bytes being written (offset >= length)
    10NNNNNN bytes          NNNNNN (1-63) literal bytes; $80 (N = 0) ends the stream
    11NNNNNN B              NNNNNN + 3 (3-66) copies of the byte B

The block's set-up moves the stream up with LDDR so that it ends where the unpacked bytes end, plus N raw bytes the
packer never coded: they arrive in place with the move (Neart482's outer block keeps 9, the inner one 2). The
depacker then writes from the output's start upwards over the moved stream.

The packer's choices (all 2164 tokens of the outer stream and all of the inner one reproduced): at each place the
longest match (at most 10, offset at most 4095, no overlap), the farthest of equal ones; a run of one byte wins
only when it is longer than the best match (3-66); otherwise the byte joins the current literal run, cut at 63.
"""
import argparse
import sys


def tokens(s):
    """[('m', length, offset) | ('l', bytes) | ('r', count, byte) | ('end',)], and the stream bytes used"""
    i, out = 0, []
    a = s[0]
    while True:
        if a & 0x80 == 0:
            out.append(('m', (a >> 4) + 3, (a & 15) << 8 | s[i + 1]))
            i += 2
        elif a & 0x7F == 0:
            out.append(('end',))
            return out, i + 1
        elif a & 0x40 == 0:
            n = a & 0x3F
            out.append(('l', bytes(s[i + 1:i + 1 + n])))
            i += 1 + n
        else:
            out.append(('r', (a & 0x3F) + 3, s[i + 1]))
            i += 2
        a = s[i]


def unpack(s):
    toks, used = tokens(s)
    o = bytearray()
    for t in toks:
        if t[0] == 'm':
            for _ in range(t[1]):
                o.append(o[len(o) - t[2]])
        elif t[0] == 'l':
            o += t[1]
        elif t[0] == 'r':
            o += bytes([t[2]]) * t[1]
    return bytes(o), used


def parse(d):
    out, lit, i, n = [], bytearray(), 0, len(d)
    where = {}

    def flush():
        nonlocal lit
        while lit:
            out.append(('l', bytes(lit[:63])))
            lit = lit[63:]

    def remember(a, b):
        for k in range(a, b):
            where.setdefault(d[k], []).append(k)

    while i < n:
        r = 1
        while i + r < n and d[i + r] == d[i] and r < 66:
            r += 1
        bl, bo = 0, 0
        for j in where.get(d[i], ()):
            off = i - j
            if off > 4095:
                continue
            length = 1
            while length < 10 and length < off and i + length < n and d[j + length] == d[i + length]:
                length += 1
            if length > bl:    # the candidates come farthest first: > keeps the farthest of equal ones
                bl, bo = length, off
        if r >= 3 and r > bl:
            flush()
            out.append(('r', r, d[i]))
            step = r
        elif bl >= 3:
            flush()
            out.append(('m', bl, bo))
            step = bl
        else:
            lit.append(d[i])
            step = 1
        remember(i, i + step)
        i += step
    flush()
    out.append(('end',))
    return out


def encode(toks):
    b = bytearray()
    for t in toks:
        if t[0] == 'm':
            b += bytes([(t[1] - 3) << 4 | t[2] >> 8, t[2] & 0xFF])
        elif t[0] == 'l':
            b += bytes([0x80 | len(t[1])]) + t[1]
        elif t[0] == 'r':
            b += bytes([0xC0 | (t[1] - 3), t[2]])
        else:
            b.append(0x80)
    return bytes(b)


def pack(data, raw):
    """the stream of data's bytes but the last raw, then those raw bytes"""
    return encode(parse(data[:len(data) - raw])) + data[len(data) - raw:]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    u = s.add_parser('unpack')
    u.add_argument('src')
    u.add_argument('dst')
    k = s.add_parser('pack')
    k.add_argument('src')
    k.add_argument('dst')
    k.add_argument('--raw', type=int, default=0)
    t = s.add_parser('tokens')
    t.add_argument('src')
    a = p.parse_args()
    data = open(a.src, 'rb').read()
    if a.cmd == 'unpack':
        out, used = unpack(data)
        open(a.dst, 'wb').write(out)
        print('%d stream bytes -> %d bytes' % (used, len(out)))
    elif a.cmd == 'pack':
        out = pack(data, a.raw)
        open(a.dst, 'wb').write(out)
        print('%d bytes -> %d stream bytes (%d raw)' % (len(data), len(out), a.raw))
    else:
        toks, used = tokens(data)
        for x in toks:
            print(x[0], *(x[1:] if x[0] != 'l' else [x[1].hex()]))
        print('# %d stream bytes' % used, file=sys.stderr)


if __name__ == '__main__':
    main()

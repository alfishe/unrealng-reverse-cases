#!/usr/bin/env python3
"""Hrust 1 (Dmitry Pyankov, "hrust-packer v1.3") with its "HR" header: the format of the two packed blocks of
ZYNAPS.B, which the depacker at `$5B00` (the file's second sector, src/loader/depacker.ann) unpacks in place. Both
ways: the depacker in Python, and a packer that gives the original streams back bit for bit.

    python3 tools/hrust1.py info BLOCK.bin                       the header
    python3 tools/hrust1.py unpack BLOCK.bin OUT.bin             the unpacked bytes
    python3 tools/hrust1.py tokens BLOCK.bin                     the token list, one a line (position, token)
    python3 tools/hrust1.py pack PLAIN.bin OUT.bin [--hints F] [--file NAME [--start ADDR]]
                                                                 the block: header and stream; with --file, padded
                                                                 to whole sectors with the packer's tail (below)
    python3 tools/hrust1.py check BLOCK.bin [--hints F]          unpack, pack again, compare

The header (12 bytes): "HR", the unpacked length (LE), the packed length (LE, header included), the last 6 bytes
of the unpacked data. The stream packs the data without those 6 bytes; the depacker writes them after the end code.
Bits come MSB first from 16-bit little-endian words; the first word sits before the first data byte (a raw literal),
each next word right where the previous one's 16th bit is used, so words and bytes interleave in the order the
depacker meets them; the last word's unused bits are 0.

The tokens (after the flag bit 0; a flag 1 is a literal byte):

    00 vvv                    1 byte from distance 8 - v (1-8)
    01 + 11 vvvvv             2 bytes, distance 32 - v (1-32)
         10 byte b < $E0      2 bytes, distance 256 - b (33-256)
         10 $FE               the window grows: expand + 1 (2 at the start: 1024 bytes; 3, 4, 5: 2, 4, 8 K)
         10 byte b >= $E0     X ? X: 1 byte, a literal, 1 byte, an even distance 18-78 (from rol(b) xor 2)
         01 byte              2 bytes, distance 512 - byte (257-512)
         00 byte              2 bytes, distance 768 - byte (513-768)
    10 D                      3 bytes, distance D
    11 + 01 D / 10 D          4 / 5 bytes
         11 bb.. D            6-15 bytes: 6 + bb, again while bb = 3 and the length < 15
         00 1 vvvv            X ? X with distance 16 - v (1-16)
         00 01 vvvv + bytes   (v + 6) * 2 literals (12-42)
         00 00 7 bits n       n = 15: the end; n > 15: n bytes; else n * 256 + a byte (up to 3839), then D
    D (a distance):  10 vvvvv (1-32) | 01 byte b < $E0 (33-256) | 01 byte b >= $E0: X ? X, an odd distance 17-79 |
                     00 byte (257-512) | 11 + expand bits v + byte: (2^expand - v) * 256 - byte (up to 256 << expand)

The packer (the original's choices, found on both blocks of this disk): at each byte the longest match within 8192
bytes back, the nearest of that length, the search stopping at the first match of 255 bytes or more (lengths up to
3839); if it is shorter than 3, a 2-byte match within 768 bytes; else an X ? X (distance up to 79), unless the byte
has a 1-byte match (distance up to 8) and the next byte can be coded better than a literal (a 1-byte match, a 2-byte
match within 768, or 3 bytes or more): then the 1-byte match; else the 1-byte match, else a literal. A run of 12 or
more literals between other tokens becomes one run token of the even count (an odd one leaves its last literal
alone). The window grows (the $FE token) right before the first match that needs it. On these two blocks this gives
every token but one (block 1, 12 105 bytes in: the original takes the 3-byte match at 5803, not the nearer one at
3756, inside the long match at 8348; the rule of its match finder that skips it is not known): the hints file names
it, as `POSITION m LENGTH DISTANCE`.

The packer's tail: hrust-packer v1.3 writes its output to whole sectors and fills the rest of the last one with a
TR-DOS descriptor of the file it packed (the name, type C, the start, the length, the sector count: 14 bytes, the
unpacked file's), CR LF, its signature (SIGNATURE) and zeros. Both blocks of ZYNAPS.B keep it: "INTRO" and "BLOK",
start $6000. A tail shorter than 64 bytes would not fit; neither block's is.
"""
import argparse
import struct
import sys
from collections import defaultdict
from pathlib import Path

WINDOW = 8192
MAXLEN = 3839
GOOD = 255
SIGNATURE = b'hrust-packer v1.3 by Dima Pyankov,Gorno-Altaisk.'


class Reader:
    def __init__(self, data, pos):
        self.d, self.p = data, pos
        self.left = 0
        self.bits = 0
        self.load()

    def byte(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def load(self):
        self.bits = self.d[self.p] | self.d[self.p + 1] << 8
        self.p += 2
        self.left = 16

    def get(self, n):
        v = 0
        for _ in range(n):
            v = v << 1 | (self.bits >> 15) & 1
            self.bits = (self.bits << 1) & 0xFFFF
            self.left -= 1
            if self.left == 0:
                self.load()
        return v


def rol8(b):
    return ((b << 1) & 0xFE) | (b >> 7)


def decode(data, pos):
    """(tokens, the unpacked bytes, the stream's end): ('lit', b), ('lits', bytes), ('m', length, distance),
    ('ins', distance, middle byte), ('expand',), ('end',)"""
    s = Reader(data, pos)
    out = bytearray()
    b = s.byte()
    out.append(b)
    toks = [('lit', b)]
    expand = 2

    def rep(d, n):
        for _ in range(n):
            out.append(out[-d])

    while True:
        if s.get(1):
            b = s.byte()
            out.append(b)
            toks.append(('lit', b))
            continue
        k = s.get(2)
        if k == 0:
            d = 8 - s.get(3)
            rep(d, 1)
            toks.append(('m', 1, d))
            continue
        ins = None
        if k == 1:
            j = s.get(2)
            if j == 0:
                d = 768 - s.byte()
            elif j == 1:
                d = 512 - s.byte()
            elif j == 2:
                b = s.byte()
                if b < 0xE0:
                    d = 256 - b
                elif b == 0xFE:
                    expand = expand + 1 if expand < 8 else 1
                    toks.append(('expand',))
                    continue
                else:
                    ins = 256 - (((rol8(b) ^ 0x02) - 15) & 0xFF)
            else:
                d = 32 - s.get(5)
            if ins is None:
                rep(d, 2)
                toks.append(('m', 2, d))
                continue
        else:
            if k == 2:
                mlen = 3
            else:
                j = s.get(2)
                mlen = None
                if j == 0:
                    if s.get(1):
                        ins = 16 - s.get(4)
                    elif s.get(1):
                        n = (s.get(4) + 6) * 2
                        run = bytes(s.byte() for _ in range(n))
                        out += run
                        toks.append(('lits', run))
                        continue
                    else:
                        b = s.get(7)
                        if b == 15:
                            toks.append(('end',))
                            return toks, bytes(out), s.p
                        mlen = b if b > 15 else (b << 8) + s.byte()
                elif j == 1:
                    mlen = 4
                elif j == 2:
                    mlen = 5
                else:
                    mlen = 6
                    while True:
                        b = s.get(2)
                        mlen += b
                        if not (b == 3 and mlen < 15):
                            break
            if ins is None:
                j = s.get(2)
                if j == 0:
                    d = 512 - s.byte()
                elif j == 1:
                    b = s.byte()
                    if b < 0xE0:
                        d = 256 - b
                    else:
                        ins = 256 - (((rol8(b) ^ 0x03) - 15) & 0xFF)
                elif j == 2:
                    d = 32 - s.get(5)
                else:
                    v = s.get(expand)
                    hi = -(1 << expand) | v
                    d = -(hi * 256 + s.byte())
                if ins is None:
                    rep(d, mlen)
                    toks.append(('m', mlen, d))
                    continue
        mid = s.byte()
        rep(ins, 1)
        out.append(mid)
        rep(ins, 1)
        toks.append(('ins', ins, mid))


class Writer:
    """the stream in the order the depacker reads it"""

    def __init__(self):
        self.out = bytearray(b'\0\0')
        self.slot = 0
        self.word = 0
        self.used = 0

    def bit(self, b):
        self.word = self.word << 1 | b
        self.used += 1
        if self.used == 16:
            self.out[self.slot] = self.word & 0xFF
            self.out[self.slot + 1] = self.word >> 8
            self.slot = len(self.out)
            self.out += b'\0\0'
            self.word = self.used = 0

    def bits(self, value, n):
        for k in range(n - 1, -1, -1):
            self.bit(value >> k & 1)

    def byte(self, v):
        self.out.append(v)

    def close(self):
        """the last word's unused bits are 0; when the end code took a word's 16th bit the depacker still fetches
        the next word: two zeros"""
        w = (self.word << (16 - self.used)) & 0xFFFF if self.used else 0
        self.out[self.slot] = w & 0xFF
        self.out[self.slot + 1] = w >> 8
        return bytes(self.out)


def ins_byte(d, x):
    for b in range(0xE0, 0x100):
        if x == 2 and b == 0xFE:
            continue
        if 256 - (((rol8(b) ^ x) - 15) & 0xFF) == d:
            return b
    raise ValueError(f'no X ? X code for distance {d}')


def distance(w, d, expand):
    if d <= 32:
        w.bits(0b10, 2)
        w.bits(32 - d, 5)
    elif d <= 256:
        w.bits(0b01, 2)
        w.byte(256 - d)
    elif d <= 512:
        w.bits(0b00, 2)
        w.byte(512 - d)
    else:
        if d > 256 << expand:
            raise ValueError(f'distance {d} past the window {256 << expand}')
        hi = -((d + 255) // 256)
        w.bits(0b11, 2)
        w.bits(hi & ((1 << expand) - 1), expand)
        w.byte((-d) - hi * 256)


def put(w, t, expand):
    """one token; returns the window's expand after it"""
    kind = t[0]
    if kind == 'lit':
        w.bit(1)
        w.byte(t[1])
        return expand
    w.bit(0)
    if kind == 'expand':
        w.bits(0b0110, 4)
        w.byte(0xFE)
        return expand + 1 if expand < 8 else 1
    if kind == 'end':
        w.bits(0b110000, 6)
        w.bits(15, 7)
        return expand
    if kind == 'lits':
        w.bits(0b110001, 6)
        w.bits(len(t[1]) // 2 - 6, 4)
        for b in t[1]:
            w.byte(b)
        return expand
    if kind == 'ins':
        d = t[1]
        if d <= 16:
            w.bits(0b11001, 5)
            w.bits(16 - d, 4)
        elif d % 2 == 0:
            w.bits(0b0110, 4)
            w.byte(ins_byte(d, 2))
        else:
            w.bits(0b1001, 4)
            w.byte(ins_byte(d, 3))
        w.byte(t[2])
        return expand
    _, length, d = t
    if length == 1:
        w.bits(0b00, 2)
        w.bits(8 - d, 3)
    elif length == 2:
        w.bits(0b01, 2)
        if d <= 32:
            w.bits(0b11, 2)
            w.bits(32 - d, 5)
        elif d <= 256:
            w.bits(0b10, 2)
            w.byte(256 - d)
        elif d <= 512:
            w.bits(0b01, 2)
            w.byte(512 - d)
        else:
            w.bits(0b00, 2)
            w.byte(768 - d)
    else:
        if length == 3:
            w.bits(0b10, 2)
        else:
            w.bits(0b11, 2)
            if length == 4:
                w.bits(0b01, 2)
            elif length == 5:
                w.bits(0b10, 2)
            elif length <= 15:
                w.bits(0b11, 2)
                m = 6
                while True:
                    b = min(3, length - m)
                    w.bits(b, 2)
                    m += b
                    if not (b == 3 and m < 15):
                        break
            else:
                w.bits(0b0000, 4)
                if length <= 127:
                    w.bits(length, 7)
                else:
                    w.bits(length >> 8, 7)
                    w.byte(length & 0xFF)
        distance(w, d, expand)
    return expand


def encode(tokens):
    """the stream of a token list (its first token the raw first literal)"""
    w = Writer()
    expand = 2
    w.byte(tokens[0][1])
    for t in tokens[1:]:
        expand = put(w, t, expand)
    return w.close()


def size(t):
    return {'lit': 1, 'ins': 3}.get(t[0]) or (len(t[1]) if t[0] == 'lits' else t[1] if t[0] == 'm' else 0)


class Finder:
    """matches through a chain of the positions of each 2-byte pair, nearest first"""

    def __init__(self, data):
        self.d, self.chain, self.upto = data, defaultdict(list), 0

    def _add(self, p):
        while self.upto < p:
            q = self.upto
            if q + 1 < len(self.d):
                self.chain[self.d[q:q + 2]].append(q)
            self.upto += 1

    def longest(self, p):
        self._add(p)
        d, n, best = self.d, len(self.d), (0, 0)
        if p + 1 >= n:
            return best
        for q in reversed(self.chain.get(d[p:p + 2], ())):
            if p - q > WINDOW:
                break
            k = 2
            while p + k < n and k < MAXLEN and d[p + k] == d[q + k]:
                k += 1
            if k > best[0]:
                best = (k, p - q)
                if k >= GOOD:
                    break
        return best

    def pair(self, p, limit=768):
        self._add(p)
        if p + 1 >= len(self.d):
            return 0
        for q in reversed(self.chain.get(self.d[p:p + 2], ())):
            return p - q if p - q <= limit else 0
        return 0


def near(d, p):
    for k in range(1, min(p, 8) + 1):
        if d[p] == d[p - k]:
            return k
    return 0


def xox(d, p):
    if p + 2 >= len(d):
        return 0
    for k in range(1, 80):
        if p >= k and d[p] == d[p - k] and d[p + 2] == d[p + 2 - k]:
            return k
    return 0


def choose(f, d, p):
    length, dist = f.longest(p)
    if length >= 3:
        return ('m', length, dist)
    k = f.pair(p)
    if k:
        return ('m', 2, k)
    i, a = xox(d, p), near(d, p)
    if i and not (a and (near(d, p + 1) or f.pair(p + 1) or f.longest(p + 1)[0] >= 3)):
        return ('ins', i, d[p + 1])
    if a:
        return ('m', 1, a)
    return ('lit', d[p])


def parse(data, hints=None):
    hints = hints or {}
    f = Finder(data)
    toks, p = [('lit', data[0])], 1
    while p < len(data):
        t = hints.get(p) or choose(f, data, p)
        toks.append(t)
        p += size(t)
    # runs of 12 or more literals: one run token of the even count
    out, run = [toks[0]], []

    def flush():
        while len(run) >= 12:
            n = min(42, len(run) & ~1)
            out.append(('lits', bytes(t[1] for t in run[:n])))
            del run[:n]
        out.extend(run)
        run.clear()
    for t in toks[1:]:
        if t[0] == 'lit':
            run.append(t)
        else:
            flush()
            out.append(t)
    flush()
    # the window grows right before the first match that needs it
    final, expand = [], 2
    for t in out:
        if t[0] == 'm' and t[1] >= 3 and t[2] > 512:
            while t[2] > 256 << expand:
                final.append(('expand',))
                expand += 1
        final.append(t)
    final.append(('end',))
    return final


def read_hints(path):
    hints = {}
    if path:
        for line in Path(path).read_text().splitlines():
            line = line.split(';')[0].split('#')[0].split()
            if line:
                p, kind, *v = line
                hints[int(p)] = (kind, *map(int, v))
    return hints


def pack(data, hints=None):
    body, last6 = data[:-6], data[-6:]
    stream = encode(parse(body, hints))
    return b'HR' + struct.pack('<HH', len(data), 12 + len(stream)) + last6 + stream


def header(block):
    if block[:2] != b'HR':
        raise SystemExit('no HR header')
    unp, pk = struct.unpack('<HH', block[2:6])
    return unp, pk, block[6:12]


def unpack(block):
    unp, pk, last6 = header(block)
    toks, body, end = decode(block, 12)
    out = body + last6
    if len(out) != unp:
        raise SystemExit(f'unpacked {len(out)} bytes, the header says {unp}')
    if end != pk:
        raise SystemExit(f'stream ends at {end}, the header says {pk}')
    return out, toks


def tail(packed_len, name, start, length):
    """the packer's tail after a block of packed_len bytes: the descriptor of the plain file, CR LF, the signature,
    zeros to the end of the last sector"""
    sectors = (packed_len + 64 + 255) // 256
    desc = name.ljust(8).encode('ascii') + b'C' + struct.pack('<HHB', start, length, (length + 255) // 256)
    body = desc + b'\r\n' + SIGNATURE
    return (body + bytes(sectors * 256 - packed_len - len(body)))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('mode', choices=['info', 'unpack', 'tokens', 'pack', 'check'])
    p.add_argument('src')
    p.add_argument('dst', nargs='?')
    p.add_argument('--hints')
    p.add_argument('--file', help='the plain file\'s TR-DOS name: write the packer\'s tail after the block')
    p.add_argument('--start', default='0x6000', help='the plain file\'s start for the tail (default $6000)')
    a = p.parse_args()
    data = Path(a.src).read_bytes()
    if a.mode == 'info':
        unp, pk, last6 = header(data)
        print(f'unpacked {unp} (#{unp:04X}), packed {pk} (#{pk:04X}), last 6 bytes {last6.hex()}')
    elif a.mode == 'unpack':
        out, toks = unpack(data)
        Path(a.dst).write_bytes(out)
        kinds = {}
        for t in toks:
            kinds[t[0]] = kinds.get(t[0], 0) + 1
        print(f'{len(out)} bytes (#{len(out):04X}); tokens {kinds}')
    elif a.mode == 'tokens':
        out, toks = unpack(data)
        pos = 0
        for t in toks:
            print(pos, t[0], *(t[1:] if t[0] != 'lits' else [t[1].hex()]))
            pos += size(t)
    elif a.mode == 'pack':
        block = pack(data, read_hints(a.hints))
        if a.file:
            block += tail(len(block), a.file, int(a.start.replace('$', '0x'), 0), len(data))
        Path(a.dst).write_bytes(block)
    else:
        unp, pk, _ = header(data)
        out, toks = unpack(data)
        mine = pack(out, read_hints(a.hints))
        orig = data[:pk]
        if mine == orig:
            print(f'{a.src}: packed again bit for bit ({pk} bytes, {len(toks)} tokens)')
            return 0
        i = next((i for i in range(min(len(mine), len(orig))) if mine[i] != orig[i]), min(len(mine), len(orig)))
        print(f'{a.src}: differs at byte {i} (packed {len(mine)}, original {len(orig)})')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

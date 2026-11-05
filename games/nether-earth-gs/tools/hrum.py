#!/usr/bin/env python3
"""HRUM 3.5 (Dmitry Pyankov): the depacker and a packer that gives the original streams.

Copied from ../advanced-nether-earth/tools/hrum.py (the case brief: shared tools are copied, never imported across
cases). Changed: `pack --prefer POS:OFFSET` (and pack(data, prefer)): at output position POS take the match at OFFSET
when it is as long as the best one. The TRD's boot menu (src/trd/boot) needs it once: at POS 2348 the original packer
took the 72-byte match at -264 where the model's nearest-first search finds the equally long one at -132; every other
token of that stream and of the 13 ANE streams is the model's own choice (work/stage2/NOTES-trd.md).

    python3 tools/hrum.py unpack IN.bin OUT.bin [--tail HEX]     the stream (from its first word) -> the bytes
    python3 tools/hrum.py pack IN.bin OUT.bin [--prefer POS:OFF]  the bytes -> the stream (5 tail bytes kept out)
    python3 tools/hrum.py tokens IN.bin                           the stream's tokens, one a line

The depacker (119 bytes, docs/03-build-and-load.md 4: the copy at $5B89 for the loader, at $FE4C for the game's
blocks) reads its stream upwards with POP: words for the bit buffer, bytes with DEC SP; POP AF.

- The first word: C = 16 (bits a word), B = the bits left in the first bit word; then the first bit word.
- A bit is the top bit of the bit word (ADD HL,HL); after its 16th bit the next word is read at once (POP HL),
  so a bit word sits in the stream where the last one ran out, between the bytes.
- After the first literal byte (always): bit 1 = a literal byte; bit 0 = a match. Its code: E = 1, then 2-bit
  values: 0-2 give code E + v and stop; 3 adds 3 to E and goes on, until E = 16 (code 16).
- Code 1: copy 1 byte from offset -8..-1 (3 bits: $F8 | bbb). Code 2: 2 bytes, offset -256..-1 (a byte, high
  $FF). Code 3: 3 bytes, codes 5-16: 4-15 bytes; code 4: the length in a byte (0 = the end). After a length of 3
  or more: one bit, 0 = offset -256..-1 (a byte), 1 = offset high from 4 bits ($F0 | bbbb), then the low byte.
- At the end the depacker copies 5 bytes kept in its own tail (the last 5 output bytes) after the output.
"""
import argparse
import sys


class BitReader:
    def __init__(self, data):
        self.d = data
        self.p = 0
        c = self.byte()
        b = self.byte()
        assert c == 16, 'C = %d' % c
        self.c = c
        self.b = b
        self.hl = self.word()

    def byte(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def word(self):
        v = self.d[self.p] | self.d[self.p + 1] << 8
        self.p += 2
        return v

    def bit(self):
        self.hl <<= 1
        bit = self.hl >> 16
        self.hl &= 0xFFFF
        self.b = (self.b - 1) & 0xFF
        if self.b == 0:
            self.hl = self.word()
            self.b = self.c
        return bit


def tokens(data):
    """[('lit', byte) | ('match', length, offset) | ('end',)] and the stream length used"""
    r = BitReader(data)
    out = [('lit', r.byte())]
    while True:
        if r.bit():
            out.append(('lit', r.byte()))
            continue
        e = 1
        while True:
            v = r.bit() << 1 | r.bit()
            if v < 3:
                code = e + v
                break
            e += 3
            if e == r.c:
                code = e
                break
        if code == 1:
            hi = 0xF8 | r.bit() << 2 | r.bit() << 1 | r.bit()
            out.append(('match', 1, hi - 0x100))
            continue
        if code == 2:
            out.append(('match', 2, r.byte() - 0x100))
            continue
        if code == 4:
            n = r.byte()
            if n == 0:
                out.append(('end',))
                return out, r.p
            length = n
        elif code == 3:
            length = 3
        else:
            length = code - 1
        if r.bit():
            hi = 0xF0 | r.bit() << 3 | r.bit() << 2 | r.bit() << 1 | r.bit()
            off = (hi << 8 | r.byte()) - 0x10000
        else:
            off = r.byte() - 0x100
        out.append(('match', length, off))


def unpack(data, tail=b''):
    toks, used = tokens(data)
    out = bytearray()
    for t in toks:
        if t[0] == 'lit':
            out.append(t[1])
        elif t[0] == 'match':
            src = len(out) + t[2]
            assert src >= 0, t
            for i in range(t[1]):
                out.append(out[src + i])
    return bytes(out) + bytes(tail), used


def parse(data, prefer=None):
    """the packer's choices: the longest match at each place, the nearest of equal ones; a match of 3 or more
    within 4096 bytes back, of 2 within 256, of 1 within 8; else a literal (the original streams, token for token)"""
    where = {}
    toks = [('lit', data[0])]
    where.setdefault(data[0], []).append(0)
    n = len(data)
    i = 1
    while i < n:
        best_len, best_off = 0, 0
        cand = where.get(data[i], ())
        for k in range(len(cand) - 1, -1, -1):
            j = cand[k]
            off = i - j
            if off > 4096:
                break
            length = 1
            while length < 255 and i + length < n and data[j + length] == data[i + length]:
                length += 1
            if length >= 3:
                if length > best_len:
                    best_len, best_off = length, off
                    if length == 255 or i + length == n:
                        break
            elif length == 2:
                if off <= 256 and best_len < 2:
                    best_len, best_off = 2, off
            elif off <= 8 and best_len < 1:
                best_len, best_off = 1, off
        if prefer and i in prefer and best_len >= 3:
            off = prefer[i]
            length = 0
            while length < 255 and i + length < n and data[i - off + length] == data[i + length]:
                length += 1
            if length == best_len:
                best_off = off
        step = best_len or 1
        toks.append(('match', best_len, -best_off) if best_len else ('lit', data[i]))
        for a in range(i, i + step):
            where.setdefault(data[a], []).append(a)
        i += step
    toks.append(('end',))
    return toks


class BitWriter:
    """bits into 16-bit words placed where the depacker reads them: a new word right after the last one's 16th bit"""

    def __init__(self):
        self.out = bytearray([16, 16, 0, 0])
        self.w = 2
        self.n = 0
        self.v = 0

    def bit(self, b):
        self.v = self.v << 1 | b
        self.n += 1
        if self.n == 16:
            self.out[self.w:self.w + 2] = self.v.to_bytes(2, 'little')
            self.w = len(self.out)
            self.out += b'\0\0'
            self.n = self.v = 0

    def bits(self, v, k):
        for i in range(k - 1, -1, -1):
            self.bit(v >> i & 1)

    def byte(self, b):
        self.out.append(b)

    def code(self, c):
        e = 1
        while True:
            if 0 <= c - e < 3:
                self.bits(c - e, 2)
                return
            self.bits(3, 2)
            e += 3
            if e == 16:
                return

    def finish(self):
        self.out[self.w:self.w + 2] = (self.v << (16 - self.n)).to_bytes(2, 'little')
        return bytes(self.out)


def encode(toks):
    w = BitWriter()
    w.byte(toks[0][1])
    for t in toks[1:]:
        if t[0] == 'lit':
            w.bit(1)
            w.byte(t[1])
            continue
        w.bit(0)
        if t[0] == 'end':
            w.code(4)
            w.byte(0)
            break
        length, off = t[1], t[2]
        if length == 1:
            w.code(1)
            w.bits(off & 7, 3)
            continue
        if length == 2:
            w.code(2)
            w.byte(off & 0xFF)
            continue
        if length == 3:
            w.code(3)
        elif length <= 15:
            w.code(length + 1)
        else:
            w.code(4)
            w.byte(length)
        if off >= -256:
            w.bit(0)
            w.byte(off & 0xFF)
        else:
            w.bit(1)
            w.bits(off >> 8 & 15, 4)
            w.byte(off & 0xFF)
    return w.finish()


def pack(data, prefer=None):
    """(stream, tail): the bytes but the last 5 packed, the last 5 for the depacker's tail; prefer: {position:
    offset} ties decided as the original packer did"""
    return encode(parse(data[:-5], prefer)), data[-5:]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    u = s.add_parser('unpack')
    u.add_argument('src')
    u.add_argument('dst')
    u.add_argument('--tail', default='')
    k = s.add_parser('pack')
    k.add_argument('src')
    k.add_argument('dst')
    k.add_argument('--prefer', action='append', default=[], help='POS:OFFSET (decimal), a tie the original decided')
    t = s.add_parser('tokens')
    t.add_argument('src')
    args = p.parse_args()
    data = open(args.src, 'rb').read()
    if args.cmd == 'unpack':
        out, used = unpack(data, bytes.fromhex(args.tail))
        open(args.dst, 'wb').write(out)
        print('%d stream bytes -> %d bytes' % (used, len(out)))
    elif args.cmd == 'pack':
        prefer = {int(p.split(':')[0]): int(p.split(':')[1]) for p in args.prefer}
        stream, tail = pack(data, prefer)
        open(args.dst, 'wb').write(stream)
        print('%d bytes -> %d stream bytes, tail %s' % (len(data), len(stream), tail.hex()))
    elif args.cmd == 'tokens':
        toks, used = tokens(data)
        for x in toks:
            print(*x)
        print('# %d stream bytes' % used, file=sys.stderr)


if __name__ == '__main__':
    main()

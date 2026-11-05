#!/usr/bin/env python3
"""Hrust 1 (Dmitry Pyankov), the screen packer of the boot program's pictures: the depacker ScreenDepack ($68C5)
in Python, and a packer that gives the original streams back.

    python3 tools/bootmenu_hrust.py unpack STREAM.bin OUT.bin [--offset N]
    python3 tools/bootmenu_hrust.py pack PLAIN.bin OUT.bin

The stream has no header: ScreenDepack takes it at HL and writes to $4000 until the end code. Bits come MSB first
from 16-bit little-endian words, read from the stream when the previous word's 16th bit is used (the first word
right at the start): words and bytes interleave in the stream in the order the depacker meets them.

    0                    a literal byte (from the stream)
    1 00                 length 3, then a distance
    1 010 + byte         length 2, distance byte + 1 (1-256)
    1 011 + byte X       X = $FF: the end; X = $FE: a little-endian word length; else length X + 10; then a distance
    1 10 b               length 4 + b, then a distance
    1 11 bb              length 6 + bb, then a distance
    distance: 1 + byte                    byte + 1 (1-256)
              0 + prefix + byte           (H * 256 + byte) + 1, H from the prefix:
                  3 bits v (0-1)          H = v + 1        (1-2)
                  4 bits v (4-7)          H = v - 1        (3-6)
                  5 bits v (16-22)        H = v - 9        (7-13)
                  6 bits v (46-63)        H = v & 31       (14-31)
"""
import argparse
import sys


class Bits:
    """the depacker's bit reader: the word is fetched when the previous one's last bit is taken"""

    def __init__(self, data, pos):
        self.data, self.pos = data, pos
        self.word = 0
        self.count = 1

    def byte(self):
        v = self.data[self.pos]
        self.pos += 1
        return v

    def bit(self):
        self.word <<= 1
        b = (self.word >> 16) & 1
        self.word &= 0xFFFF
        self.count -= 1
        if self.count == 0:
            self.word = self.data[self.pos] | self.data[self.pos + 1] << 8
            self.pos += 2
            self.count = 16
        return b


def unpack(data, pos=0, tokens=None):
    """(the unpacked bytes, the stream's end offset); tokens, a list, gets each token"""
    r = Bits(data, pos)
    r.bit()  # the first call only loads the first word
    out = bytearray()
    while True:
        if not r.bit():
            out.append(r.byte())
            if tokens is not None:
                tokens.append(('lit', out[-1]))
            continue
        a = r.bit() << 1
        a |= r.bit()
        if a:
            a = a << 1 | r.bit()
            if a >= 6:
                a = a << 1 | r.bit()
        if a == 2:
            length = 2
            dist = r.byte() + 1
            for _ in range(length):
                out.append(out[-dist])
            if tokens is not None:
                tokens.append(('m', length, dist, 'byte'))
            continue
        if a < 2:
            length = 3
        elif a == 3:
            x = r.byte()
            if x == 0xFF:
                if tokens is not None:
                    tokens.append(('end',))
                return bytes(out), r.pos
            if x == 0xFE:
                length = r.byte() | r.byte() << 8
            else:
                length = x + 10
        elif a < 6:
            length = a
        else:
            length = a - 6
        if r.bit():
            high, kind = 0, 'byte'
        else:
            v = r.bit() << 2 | r.bit() << 1 | r.bit()
            if v < 2:
                high = v + 1
            else:
                v = v << 1 | r.bit()
                if v < 8:
                    high = v - 1
                else:
                    v = v << 1 | r.bit()
                    if v < 0x17:
                        high = v - 9
                    else:
                        v = v << 1 | r.bit()
                        high = v & 0x1F
            kind = high
        dist = (high << 8 | r.byte()) + 1
        for _ in range(length):
            out.append(out[-dist])
        if tokens is not None:
            tokens.append(('m', length, dist, kind))


class Writer:
    """the stream in the order the depacker reads it: a word's two bytes are placed where the depacker fetches it"""

    def __init__(self):
        self.out = bytearray()
        self.slot = 0
        self.out += b'\0\0'
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
        """the last word's unused bits are ones; when the end code took a word's last bit, the depacker still fetches
        the next word, which the original packer leaves 0 (credits and tracks end so)"""
        free = 16 - self.used
        w = 0 if free == 16 else (self.word << free | ((1 << free) - 1)) & 0xFFFF
        self.out[self.slot] = w & 0xFF
        self.out[self.slot + 1] = w >> 8
        return bytes(self.out)


WINDOW = 8192


def pack(data):
    """greedy, as the original packer: at each byte the longest match within 8192 bytes back, the closest of that
    length; a 2-byte match only within 256 bytes (it has no long offset); a literal when there is none"""
    w = Writer()
    pos, n = 0, len(data)
    index = {}  # 2-byte key: positions, newest last
    while pos < n:
        best, bd = 0, 0
        if pos + 1 < n:
            for q in reversed(index.get(data[pos:pos + 2], ())):
                d = pos - q
                if d > WINDOW:
                    break
                length = 2
                while pos + length < n and data[pos + length] == data[pos + length - d]:
                    length += 1
                if length > best:
                    best, bd = length, d
        if best == 2 and bd > 256:
            best = 0
        if best < 2:
            w.bit(0)
            w.byte(data[pos])
            step = 1
        else:
            w.bit(1)
            emit_match(w, best, bd)
            step = best
        for k in range(pos, pos + step):
            if k + 1 < n:
                index.setdefault(data[k:k + 2], []).append(k)
        pos += step
    w.bit(1)
    w.bits(0b011, 3)
    w.byte(0xFF)
    return w.close()


def emit_match(w, length, dist):
    if length == 2:
        w.bits(0b010, 3)
        w.byte(dist - 1)
        return
    if length == 3:
        w.bits(0b00, 2)
    elif length < 6:
        w.bits(0b10, 2)
        w.bit(length - 4)
    elif length < 10:
        w.bits(0b11, 2)
        w.bits(length - 6, 2)
    else:
        w.bits(0b011, 3)
        if length - 10 < 0xFE:
            w.byte(length - 10)
        else:
            w.byte(0xFE)
            w.byte(length & 0xFF)
            w.byte(length >> 8)
    high, low = (dist - 1) >> 8, (dist - 1) & 0xFF
    if high == 0:
        w.bit(1)
    else:
        w.bit(0)
        if high <= 2:
            w.bits(high - 1, 3)
        elif high <= 6:
            w.bits(high + 1, 4)
        elif high <= 13:
            w.bits(high + 9, 5)
        else:
            w.bits(high + 32, 6)
    w.byte(low)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('mode', choices=['unpack', 'pack'])
    p.add_argument('src')
    p.add_argument('dst')
    p.add_argument('--offset', type=lambda s: int(s, 0), default=0)
    args = p.parse_args()
    data = open(args.src, 'rb').read()
    if args.mode == 'unpack':
        out, end = unpack(data, args.offset)
        open(args.dst, 'wb').write(out)
        print('%d bytes from %d stream bytes' % (len(out), end - args.offset))
    else:
        open(args.dst, 'wb').write(pack(data))


if __name__ == '__main__':
    sys.exit(main())

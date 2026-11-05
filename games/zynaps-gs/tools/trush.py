#!/usr/bin/env python3
"""The self-unpacking blocks of "COMPRESSOR BY ALEXANDER TRUSH ODESSA" (the name the depacker carries in its head):
read a block as the disk stores it and unpack it the way its Z80 depacker does.

  trush.py BLOCK.bin --base ADDR [--out OUT.bin]   unpack one block loaded at ADDR (hex)
  trush.py --scan DISK.bin [--out-dir DIR]         every block in a raw run of sectors (found by its head)

The block (loaded at base B, run at B):
  B+$00  DI; LD B,16; EXX; PUSH HL; LD HL,src_end; LD DE,dest_end; LD BC,packed_len; PUSH DE; LDDR
         EX DE,HL; INC HL; LD IX,0; ADD IX,SP; LD SP,HL        moves the packed stream to end at dest_end,
                                                               SP = its first byte
  B+$1A  LD HL,B+$4B; LD DE,B; LD BC,$CE; PUSH DE; JP $33C3   copies the depacker over the head (ROM LDIR; RET)
  B+$27  the name "COMPRESSOR BY ALEXANDER TRUSH ODESSA"
  B+$4B  the depacker ($CE bytes); its LD BC at +$C5 holds the unpacked length
  ...    the packed stream (bytes and 16-bit bit words interleaved, read through SP)

The depacker writes from B+$CE upwards, then LDDR moves the output to end at dest_end and returns (EI; RET).

The stream: a bit word is 16 bits, most significant first, read when the previous one is used up (the first word
is read at once, and each next one as soon as the last bit of the previous is taken). Tokens:
  0                    a literal byte (the next stream byte)
  1 then a length code 00 -> 3, 010 -> 2, 011 -> a length byte, 100 -> 4, 101 -> 5, 11xx -> 6..9
     length byte n: $FF end of the stream, $FE a 16-bit length word follows, else n + 10 (up to 265)
  offset (length 2: one byte, offset 1..256):  else a bit: 1 -> one byte (1..256);
     0 -> a high part from the bit code (000/001 -> 1/2, 01xx -> 3..6, 10xxx-10110 -> 7..13, 10111x-11111x -> 14..31)
     and a low byte: offset = high * 256 + low + 1
  copy `length` bytes from `offset` back (overlapping copies allowed, LDIR).
"""
import argparse
import os
import re
import struct
import sys

HEAD = b'\xf3\x06\x10\xd9\xe5\x21'


class Stream:
    def __init__(self, data, pos):
        self.d, self.p = data, pos
        self.word, self.left = 0, 0

    def byte(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def word16(self):
        v = self.d[self.p] | self.d[self.p + 1] << 8
        self.p += 2
        return v

    def bit(self):
        self.left -= 1
        b = self.word >> self.left & 1
        if self.left == 0:  # DJNZ hits 0: the next word is popped at once, before any byte that follows
            self.word, self.left = self.word16(), 16
        return b

    def bits(self, n, a=0):
        for _ in range(n):
            a = a << 1 | self.bit()
        return a


def header(block, base):
    assert block[:6] == HEAD, 'not a Trush block'
    src_end, dest_end, plen = struct.unpack('<H', block[6:8])[0], struct.unpack('<H', block[9:11])[0], \
        struct.unpack('<H', block[12:14])[0]
    i = block.find(b'\xdd\x39\xf9\x21')
    dsrc, dbase = struct.unpack('<HH', block[i + 4:i + 6] + block[i + 7:i + 9])
    assert dbase == base, f'block runs at {dbase:#x}, not {base:#x}'
    ulen = struct.unpack('<H', block[dsrc - base + 0xC6:dsrc - base + 0xC8])[0]
    return dict(src_end=src_end, dest_end=dest_end, packed_len=plen, unpacked_len=ulen, depacker=dsrc,
                stream=src_end - plen + 1 - base, size=src_end - base + 1)


def unpack(block, base):
    h = header(block, base)
    s = Stream(block, h['stream'])
    out = bytearray()
    s.word, s.left = s.word16(), 16
    while True:
        if not s.bit():
            out.append(s.byte())
            continue
        code = s.bits(2)
        if code:
            code = s.bits(1, code)
            if code >= 6:
                code = s.bits(1, code)
        high = 0
        if code == 2:
            n = 2
            off = s.byte() + 1
            _copy(out, off, n)
            continue
        if code == 3:
            v = s.byte()
            if v == 0xFF:
                break
            n = s.word16() if v == 0xFE else v + 10
        elif code == 0:
            n = 3
        elif code < 6:
            n = code
        else:
            n = code - 6
        if s.bit():
            off = s.byte() + 1
        else:
            a = s.bits(3)
            if a < 2:
                high = a + 1
            else:
                a = s.bits(1, a)
                if a < 8:
                    high = a - 1
                else:
                    a = s.bits(1, a)
                    if a < 0x17:
                        high = a - 9
                    else:
                        high = s.bits(1, a) & 0x1F
            off = (high << 8 | s.byte()) + 1
        _copy(out, off, n)
    assert len(out) == h['unpacked_len'], (len(out), h['unpacked_len'])
    h['dest_start'] = h['dest_end'] - len(out) + 1
    return h, bytes(out)


def _copy(out, off, n):
    assert off <= len(out), f'offset {off} before the start'
    for _ in range(n):
        out.append(out[-off])


# --- the packer ---

WINDOW = 8192      # the farthest offset: high part 31, low byte 255
SHORT = 256        # the farthest offset of a 2-byte match (its one-byte form)


def tokens(data):
    """the token choice of the original packer, found on all 38 blocks of the disk: at each position the longest
    match (2 bytes at most 256 back, 3 or more at most 8192 back), the nearest of equal length; a literal when there
    is none"""
    chains = {}
    out, p, n = [], 0, len(data)
    while p < n:
        best, off = 0, 0
        if p + 1 < n:
            for q in reversed(chains.get(data[p:p + 2], ())):
                d = p - q
                if d > WINDOW:
                    break
                k = 2
                while p + k < n and data[q + k] == data[p + k]:
                    k += 1
                if k == 2 and d > SHORT:
                    continue
                if k > best:
                    best, off = k, d
                    if p + k == n:
                        break
        step = best if best >= 2 else 1
        out.append((best, off) if best >= 2 else (1, 0))
        for q in range(p, p + step):
            if q + 1 < n:
                chains.setdefault(data[q:q + 2], []).append(q)
        p += step
    return out


class BitWriter:
    """bytes and 16-bit bit words interleaved as the depacker reads them through SP: a word's place is taken as
    soon as the previous one is full (the first one at the start); bits most significant first; the unused bits of
    the last word are 1s (a word left with no bit at all stays 0)"""

    def __init__(self):
        self.out = bytearray(2)
        self.at, self.word, self.n = 0, 0, 0

    def bit(self, b):
        self.word = self.word << 1 | b
        self.n += 1
        if self.n == 16:
            self.out[self.at:self.at + 2] = bytes((self.word & 255, self.word >> 8))
            self.at, self.word, self.n = len(self.out), 0, 0
            self.out += b'\0\0'

    def bits(self, value, count):
        for i in range(count - 1, -1, -1):
            self.bit(value >> i & 1)

    def byte(self, v):
        self.out.append(v)

    def end(self):
        if self.n:
            w = self.word << (16 - self.n) | ((1 << (16 - self.n)) - 1)
            self.out[self.at:self.at + 2] = bytes((w & 255, w >> 8))
        return bytes(self.out)


def pack(data):
    """the packed stream of data (the bytes after the depacker)"""
    w, p = BitWriter(), 0
    for length, off in tokens(data):
        if length == 1:
            w.bit(0)
            w.byte(data[p])
            p += 1
            continue
        w.bit(1)
        p += length
        if length == 2:
            w.bits(0b010, 3)
            w.byte(off - 1)
            continue
        if length == 3:
            w.bits(0b00, 2)
        elif length <= 5:
            w.bits(length, 3)                 # 100, 101
        elif length <= 9:
            w.bits(length + 6, 4)             # 1100..1111
        else:
            w.bits(0b011, 3)
            if length <= 265:
                w.byte(length - 10)
            else:
                w.byte(0xFE)
                w.byte(length & 255)
                w.byte(length >> 8)
        if off <= SHORT:
            w.bit(1)
            w.byte(off - 1)
        else:
            w.bit(0)
            high = (off - 1) >> 8
            if high <= 2:
                w.bits(high - 1, 3)           # 000, 001
            elif high <= 6:
                w.bits(high + 1, 4)           # 0100..0111
            elif high <= 13:
                w.bits(high + 9, 5)           # 10000..10110
            else:
                w.bits(high | 0x20, 6)        # 101110..111111
            w.byte((off - 1) & 255)
    w.bit(1)
    w.bits(0b011, 3)
    w.byte(0xFF)                              # the end
    return w.end()


def margin(data, dest_end, stream=None):
    """the in-place depack of data packed into a block loaded at dest_end - len(data) + 1 - $12C (the disk's rule:
    the output starts $12C above the base): the smallest distance, over the whole depack, from the last byte written
    (from base + $CE up) to the first stream byte not yet read (the stream ends at dest_end). Above 0 the depacker
    never overwrites its own stream; returns (margin, the stream's length)"""
    st = stream if stream is not None else pack(data)
    base = dest_end - len(data) + 1 - 0x12C
    start = dest_end - len(st) + 1
    s = Stream(st, 0)
    s.word, s.left = s.word16(), 16
    out, low = 0, 1 << 30

    def check():
        nonlocal low
        low = min(low, start + s.p - (base + 0xCE + out - 1))

    while True:
        if not s.bit():
            s.byte()
            out += 1
            check()
            continue
        code = s.bits(2)
        if code:
            code = s.bits(1, code)
            if code >= 6:
                code = s.bits(1, code)
        if code == 2:
            s.byte()
            out += 2
            check()
            continue
        if code == 3:
            v = s.byte()
            if v == 0xFF:
                break
            n = s.word16() if v == 0xFE else v + 10
        elif code == 0:
            n = 3
        elif code < 6:
            n = code
        else:
            n = code - 6
        if s.bit():
            s.byte()
        else:
            a = s.bits(3)
            if a >= 2:
                a = s.bits(1, a)
                if a >= 8:
                    a = s.bits(1, a)
                    if a >= 0x17:
                        s.bits(1, a)
            s.byte()
        out += n
        check()
    assert out == len(data)
    return low, len(st)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('block', nargs='?')
    ap.add_argument('--base')
    ap.add_argument('--out')
    ap.add_argument('--scan')
    ap.add_argument('--out-dir')
    a = ap.parse_args()
    if a.scan:
        disk = open(a.scan, 'rb').read()
        print('# n sector secs base  packed->dest            unpacked')
        for n, m in enumerate(re.finditer(re.escape(HEAD), disk)):
            o = m.start()
            j = disk.find(b'\xdd\x39\xf9\x21', o)
            base = struct.unpack('<H', disk[j + 7:j + 9])[0]
            h, data = unpack(disk[o:o + 0x10000], base)
            print(f"{n:2d} {o // 256:5d} {(h['size'] + 255) // 256:4d} ${base:04X} ${h['packed_len']:04X} -> "
                  f"${h['dest_start']:04X}-${h['dest_end']:04X} {len(data):6d}")
            if a.out_dir:
                os.makedirs(a.out_dir, exist_ok=True)
                open(os.path.join(a.out_dir, f"blk{n:02d}-s{o // 256:04d}-{h['dest_start']:04X}.bin"),
                     'wb').write(data)
        return
    block = open(a.block, 'rb').read()
    h, data = unpack(block, int(a.base, 16))
    print({k: (f'{v:#06x}' if isinstance(v, int) else v) for k, v in h.items()})
    if a.out:
        open(a.out, 'wb').write(data)


if __name__ == '__main__':
    sys.exit(main())

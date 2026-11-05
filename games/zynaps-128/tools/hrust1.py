#!/usr/bin/env python3
"""Hrust 1 (Dmitry Pyankov) with its "HR" header: the format of the two packed blocks of ZYNAPS.B, which the
depacker at `$5B00` (the file's second sector) unpacks in place.

    python3 tools/hrust1.py info BLOCK.bin               the header
    python3 tools/hrust1.py unpack BLOCK.bin OUT.bin     the unpacked bytes

The header (12 bytes): "HR", the unpacked length (LE), the packed length (LE, header included), the last 6 bytes
of the unpacked data. The bit stream follows: 16-bit little-endian words, bits MSB first, the next word fetched as
soon as the last bit of the previous one is used; the first data byte is a literal. The depacker moves the packed
block to the end of the destination (LDDR) when the two overlap, takes the six bytes aside, unpacks forward from
the destination and writes the six bytes after the end code.

The token grammar follows lvd's mhmt (mhmt-depack-hrust.c), as ported to unreal-ng's
core/src/loaders/snapshot/zxdepackers.cpp; the bit codes were checked here against the Z80 depacker at `$5B00`.
Stage 1: unpacking only; the packer (the original's choices) is stage 2.
"""
import struct
import sys
from pathlib import Path


class Stream:
    def __init__(self, data, pos):
        self.d, self.p = data, pos
        self.out = bytearray()
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

    def rep(self, disp, n):
        for _ in range(n):
            self.out.append(self.out[len(self.out) + disp])


def rol8(b):
    return ((b << 1) & 0xFE) | (b >> 7)


def unpack_stream(data, pos, tokens=None):
    s = Stream(data, pos)
    s.out.append(s.byte())
    expand = 2

    def tok(*t):
        if tokens is not None:
            tokens.append(t)

    while True:
        if s.get(1):
            s.out.append(s.byte())
            tok('lit',)
            continue
        disp, mlen, need_len, common, plus = 0, 0, False, False, False
        k = s.get(2)
        if k == 0:
            s.rep(-8 | s.get(3), 1)
            tok('m1',)
            continue
        if k == 1:
            mlen = 2
            j = s.get(2)
            if j == 0:
                disp, plus = -768, True
            elif j == 1:
                disp, plus = -512, True
            elif j == 2:
                b = s.byte()
                if b < 0xE0:
                    disp = -256 | b
                elif b == 0xFE:
                    expand = expand + 1 if expand < 8 else 1
                    tok('expand', expand)
                    continue
                else:
                    b = ((rol8(b) ^ 0x02) - 15) & 0xFF
                    disp, mlen = -256 | b, -3
            else:
                disp = -32 | s.get(5)
        elif k == 2:
            mlen, common = 3, True
        else:
            need_len = common = True
        if need_len:
            j = s.get(2)
            if j == 0:
                if s.get(1):
                    disp, mlen, common = -16 | s.get(4), -3, False
                elif s.get(1):
                    n = (s.get(4) + 6) * 2
                    for _ in range(n):
                        s.out.append(s.byte())
                    tok('lits', n)
                    continue
                else:
                    b = s.get(7)
                    if b == 15:
                        tok('end',)
                        return bytes(s.out), s.p
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
        if common:
            j = s.get(2)
            if j == 0:
                disp, plus = -512, True
            elif j == 1:
                b = s.byte()
                if b < 0xE0:
                    disp = -256 | b
                else:
                    b = ((rol8(b) ^ 0x03) - 15) & 0xFF
                    disp, mlen = -256 | b, -3
            elif j == 2:
                disp = -32 | s.get(5)
            else:
                top = -(1 << expand)
                disp = (top | s.get(expand)) * 256
                plus = True
        if plus:
            disp += s.byte()
        if mlen == -3:
            mid = s.byte()
            s.rep(disp, 1)
            s.out.append(mid)
            s.rep(disp, 1)
            tok('ins', disp)
        else:
            s.rep(disp, mlen)
            tok('m', mlen, disp)


def header(block):
    if block[:2] != b"HR":
        raise SystemExit("no HR header")
    unp, pk = struct.unpack("<HH", block[2:6])
    return unp, pk, block[6:12]


def unpack(block, tokens=None):
    unp, pk, last6 = header(block)
    body, end = unpack_stream(block, 12, tokens)
    out = body + last6
    if len(out) != unp:
        raise SystemExit(f"unpacked {len(out)} bytes, the header says {unp}")
    if end > pk:
        raise SystemExit(f"stream ends at {end}, past the packed length {pk}")
    return out, end


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["info"]:
        b = Path(a[1]).read_bytes()
        unp, pk, last6 = header(b)
        print(f"unpacked {unp} (#{unp:04X}), packed {pk} (#{pk:04X}), last 6 bytes {last6.hex()}")
    elif a[:1] == ["unpack"]:
        b = Path(a[1]).read_bytes()
        toks = []
        out, end = unpack(b, toks)
        Path(a[2]).write_bytes(out)
        kinds = {}
        for t in toks:
            kinds[t[0]] = kinds.get(t[0], 0) + 1
        print(f"{len(out)} bytes (#{len(out):04X}); stream ends at {end} of {len(b)}; tokens {kinds}")
    else:
        print(__doc__)

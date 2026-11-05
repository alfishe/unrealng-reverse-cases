#!/usr/bin/env python3
"""The self-unpacking blocks of "COMPRESSOR BY ALEXANDER TRUSH ODESSA" (the name the depacker carries in its head):
read a block as the disk stores it and unpack it the way its Z80 depacker does.

  trush.py BLOCK.bin --base ADDR [--out OUT.bin]   unpack one block loaded at ADDR (hex)
  trush.py --scan DISK.bin [--out-dir DIR]         every block in a raw run of sectors (found by its head)

The block (loaded at base B, run at B):
  B+$00  DI; LD B,16; EXX; PUSH HL; LD HL,src_end; LD DE,dest_end; LD BC,packed_len; PUSH DE; LDDR
         EX DE,HL; INC HL; LD IX,0; ADD IX,SP; LD SP,HL        moves the packed stream to end at dest_end,
                                                               SP = its first byte
  B+$22  LD HL,B+$4B; LD DE,B; LD BC,$CE; PUSH DE; JP $33C3   copies the depacker over the head (ROM LDIR; RET)
  B+$31  the name "COMPRESSOR BY ALEXANDER TRUSH ODESSA"
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

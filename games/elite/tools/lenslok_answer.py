#!/usr/bin/env python3
"""The Lenslok answer from the seed, the way the game computes it ($C2A0 onwards), with no emulator.

    python3 tools/lenslok_answer.py SEED [PREVIOUS]   # SEED: the word stored at $C784 (LD A,R twice at $C297);
                                                     # PREVIOUS: the two letters of the last attempt ($C79D), default none

Model of the code (docs/lenslok.md 4):
- Rand $C68E: L = (L + $31) mod 256 (H forced to 0), the result L mod n (repeated subtraction);
- $C37C: two Rand(128) draws, bit 0 cleared, kept at $C77F / $C780 (the bit patterns of the calibration marks);
- PickChar $C54B: a digit Rand(9)+'0', an upper-case letter Rand(25)+'A', a lower-case letter Rand(25)+'a', each drawn
  again while it is in the excluded set at $C7A9, then one of the three by Rand(3). The set is "TLWMIYfmwtzl" in the
  image, but the glyph gatherer $C733 writes one byte per drawn row of 8 into the 4-byte buffer at $C7A5, so before
  the first code is drawn "TLWM" are already glyph bytes: only "IYfmwtzl" is excluded (an original bug, docs/lenslok.md);
- PickCode $C6A6: two characters, each drawn again while it is in the last code ($C79D) or the code being built ($C799,
  which holds "OK" before the first attempt; the second draw also sees the first character).
"""
import sys

EXCLUDED_IMAGE = b'TLWMIYfmwtzl'
EXCLUDED = b'IYfmwtzl'  # what is left of it at run time ($C7A9-$C7AC overwritten by $C733)


class Lenslok:
    def __init__(self, seed):
        self.l = seed & 0xFF
        self.draws = []

    def rand(self, n):
        self.l = (self.l + 0x31) & 0xFF
        r = self.l % n
        self.draws.append((n, self.l, r))
        return r

    def pick_char(self):
        kinds = []
        for n, base in ((9, 0x30), (25, 0x41), (25, 0x61)):
            while True:
                c = self.rand(n) + base
                if c not in EXCLUDED:
                    break
            kinds.append(c)
        return kinds[self.rand(3)]

    def code(self, previous=b'\0\0', building=b'OK'):
        self.marks = (self.rand(128) & 0xFE, self.rand(128) & 0xFE)
        cur = bytearray(building)
        for k in range(2):
            while True:
                c = self.pick_char()
                if c in previous[:2] or c in cur[:2]:
                    continue
                break
            cur[k] = c
        return bytes(cur)


def main():
    seed = int(sys.argv[1], 16)
    prev = sys.argv[2].encode() if len(sys.argv) > 2 else b'\0\0'
    L = Lenslok(seed)
    code = L.code(prev)
    print(code.decode(), 'marks $%02X $%02X' % L.marks, f'{len(L.draws)} draws')


if __name__ == '__main__':
    sys.exit(main())

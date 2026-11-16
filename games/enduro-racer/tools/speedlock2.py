#!/usr/bin/env python3
"""Enduro Racer's SpeedLock 2 loader, both ways (docs/03-build-and-load.md).

    python3 tools/speedlock2.py plain BASIC2.bin OUT.bin        # the loader's plain view $FCA3-$FFBF from the tape
    python3 tools/speedlock2.py tape PLAIN.bin OUT.bin          # the tape's 797 bytes of $5EFD-$6219 (the build's step)
    python3 tools/speedlock2.py check BASIC2.bin                # both ways over the original

BASIC2.bin is the second BASIC block's data (1770 bytes at PROG $5CCB, no flag or checksum). The program runs off its
last line into an error, and the error handler's return address, poked to VARS by line 3, enters the code in the
variables area at $621A (src/tape/basic2.asm, Chain1). Three layers then make the loader:

    layer 1 ($62B4, Chain1Loop): the 797 bytes at $5EFD-$6219, each XORed with R (LD A,R / XOR (HL) / LD (HL),A /
            LDI), written in place and copied to $FCA3-$FFBF. R is $CD at the first byte and grows by 10 a byte
            (10 M1 cycles a turn: LD A,R 2, XOR (HL) 1, LD (HL),A 1, LDI 2, RET PO 1, DEC SP 1, DEC SP 1, RET PE 1;
            bit 7 stays as LD R,A set it, only the low 7 bits count);
    layer 2 ($FCC7, Chain2Loop): the 751 bytes $FCD1-$FFBF, XORed with R in place by the same loop; R goes on from
            layer 1: 40 M1 cycles from layer 1's last LD A,R to layer 2's first (R = $8D at the first byte);
    layer 3 ($FCD1, Chain3): 137 rounds over the 660 bytes $FD2C-$FFBF; each round runs A through them,
            A = A XOR byte, the byte = A (a running XOR), A starting at key(n) - C, key(n) the byte at $FCA3+n (the
            two decoders' own code) and C the last byte the round before wrote (round 0: the byte at $FFBF before
            the layer).

The plain view (src/loader/loader.asm) is each byte as it runs: $FCA3-$FCD0 after layer 1, $FCD1-$FD2B after
layer 2, $FD2C-$FFBF after layer 3. `tape` undoes the layers in reverse order. Layer 3 is undone round by round from
the last: a round's input is its output XORed with the output shifted by one byte, and the round's C is the last
input byte, so key(n) - C gives the start A for the first byte.
"""
import sys

ORG = 0xFCA3
END = 0xFFC0                       # the loader's plain view $FCA3-$FFBF
SRC = 0x5EFD                       # layer 1 reads $5EFD-$6219 (797 bytes) in the second BASIC
PROG = 0x5CCB
L2 = 0xFCD1                        # layer 2: $FCD1-$FFBF
L3 = 0xFD2C                        # layer 3: $FD2C-$FFBF
ROUNDS = 137
R1 = 0xCD                          # R at layer 1's first LD A,R ($62B4)
GAP = 40                           # M1 cycles from layer 1's last LD A,R to layer 2's first ($FCC7)


def r_keys(r0, n, step=10):
    """the R values n turns of a loop of `step` M1 cycles read, starting at r0 (bit 7 fixed)"""
    return [(r0 & 0x80) | ((r0 + step * i) & 0x7F) for i in range(n)]


def r2_start():
    last = r_keys(R1, END - ORG)[-1]
    return (last & 0x80) | ((last + GAP) & 0x7F)


def plain(tape):
    """the 797 tape bytes of $5EFD-$6219 -> the plain view of $FCA3-$FFBF"""
    assert len(tape) == END - ORG
    m = bytearray(b ^ k for b, k in zip(tape, r_keys(R1, len(tape))))          # layer 1
    o = L2 - ORG
    m[o:] = bytes(b ^ k for b, k in zip(m[o:], r_keys(r2_start(), len(m) - o)))  # layer 2
    o = L3 - ORG
    c = m[-1]
    for n in range(ROUNDS):                                                    # layer 3
        a = (m[n] - c) & 255
        for i in range(o, len(m)):
            a ^= m[i]
            m[i] = a
        c = a
    return bytes(m)


def tape(view):
    """the plain view of $FCA3-$FFBF -> the 797 tape bytes"""
    assert len(view) == END - ORG
    m = bytearray(view)
    o = L3 - ORG
    for n in range(ROUNDS - 1, -1, -1):
        z = m[o:]
        y = bytearray(len(z))
        for i in range(len(z) - 1, 0, -1):
            y[i] = z[i] ^ z[i - 1]
        y[0] = z[0] ^ ((m[n] - y[-1]) & 255)
        m[o:] = y
    o = L2 - ORG
    m[o:] = bytes(b ^ k for b, k in zip(m[o:], r_keys(r2_start(), len(m) - o)))
    return bytes(b ^ k for b, k in zip(m, r_keys(R1, len(m))))


def from_basic(basic):
    return basic[SRC - PROG:SRC - PROG + END - ORG]


def main():
    a = sys.argv[1:]
    if len(a) == 3 and a[0] == 'plain':
        open(a[2], 'wb').write(plain(from_basic(open(a[1], 'rb').read())))
    elif len(a) == 3 and a[0] == 'tape':
        open(a[2], 'wb').write(tape(open(a[1], 'rb').read()))
    elif len(a) == 2 and a[0] == 'check':
        t = from_basic(open(a[1], 'rb').read())
        p = plain(t)
        assert tape(p) == t, 'speedlock2: tape(plain(x)) != x'
        print('speedlock2: the 797 bytes both ways: identical; R at layer 2 = $%02X; the checksum of $FF37-$FFBF '
              '(137 bytes, Chain3) = $%04X' % (r2_start(), sum(p[0xFF37 - ORG:0xFF37 - ORG + ROUNDS])))
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

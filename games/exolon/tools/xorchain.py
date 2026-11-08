#!/usr/bin/env python3
"""The Countdown II loader's XOR chain, both ways (from the Zynaps case; docs/03-build-and-load.md 3.3).

    python3 tools/xorchain.py encrypt PLAIN.bin TAPE.bin     # the 768-byte block as the tape holds it
    python3 tools/xorchain.py decrypt TAPE.bin PLAIN.bin     # what Decrypt leaves at $FC00

Decrypt runs byte[i] ^= byte[i+1] forward over the range its plain head names (LD BC,count / LD HL,first: Exolon
$FC13-$FEA2, 656 bytes; Zynaps' was 652), each byte XORed with the next one as the tape holds it. The inverse runs
backwards from the plain byte after the range: tape[i] = plain[i] ^ tape[i+1].
"""
import sys


def span(data):
    """the chain's block offsets from the plain head: LD BC,n at +0, LD HL,first at +3"""
    count = data[1] | data[2] << 8
    first = (data[4] | data[5] << 8) - 0xFC00
    return first, first + count


def decrypt(data):
    b = bytearray(data)
    FIRST, END = span(data)
    for i in range(FIRST, END):
        b[i] ^= b[i + 1]
    return bytes(b)


def encrypt(data):
    b = bytearray(data)
    FIRST, END = span(data)
    for i in range(END - 1, FIRST - 1, -1):
        b[i] ^= b[i + 1]
    return bytes(b)


if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] not in ('encrypt', 'decrypt'):
        sys.exit(__doc__)
    data = open(sys.argv[2], 'rb').read()
    out = encrypt(data) if sys.argv[1] == 'encrypt' else decrypt(data)
    assert (decrypt(out) if sys.argv[1] == 'encrypt' else encrypt(out)) == data
    open(sys.argv[3], 'wb').write(out)

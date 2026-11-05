#!/usr/bin/env python3
"""The Countdown II loader's XOR chain, both ways (src/tape/loader.asm, docs/03-build-and-load.md 3.3).

    python3 tools/xorchain.py encrypt PLAIN.bin TAPE.bin     # the 768-byte block as the tape holds it
    python3 tools/xorchain.py decrypt TAPE.bin PLAIN.bin     # what Decrypt leaves at $FC00

Decrypt runs byte[i] ^= byte[i+1] forward over $FC13-$FE9E (block offsets $13-$29E), each byte XORed with the next
one as the tape holds it. The inverse runs backwards from the plain byte after the range: tape[i] = plain[i] ^
tape[i+1].
"""
import sys

FIRST, END = 0x13, 0x29F  # $FC13 .. $FE9E; $FE9F is plain


def decrypt(data):
    b = bytearray(data)
    for i in range(FIRST, END):
        b[i] ^= b[i + 1]
    return bytes(b)


def encrypt(data):
    b = bytearray(data)
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

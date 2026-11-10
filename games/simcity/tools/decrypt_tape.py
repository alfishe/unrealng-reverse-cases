#!/usr/bin/env python3
"""The SimCity tape's two transforms, both directions.

1. The loader block (512 bytes at `$FE00`) decrypts its own tail `$FE80-$FFFF` with the R register: after
   `XOR A; LD R,A` the loop `$FE07` (LD A,R; XOR (HL); LD (HL),A; INC HL; LD A,H; OR L; JP NZ) takes 8 M1 cycles a
   byte, so the key of byte k is (2 + 8 k) & `$7F`.
2. The tape loader `$FEBD` stores each data byte as received ^ key ^ E, with key += 3 before each byte (from 0, per
   block) and E the low byte of the bytes still to load (the length first).

    python3 tools/decrypt_tape.py loader IN.bin OUT.bin      # the 512-byte loader, its tail decrypted
    python3 tools/decrypt_tape.py block RAW OUT.bin          # a raw tape block (flag, data, parity) decrypted
    python3 tools/decrypt_tape.py check ORIG.tzx             # both ways against the tape: decrypt, encrypt, compare
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def loader_r(data, org=0xFE00, start=0xFE80):
    out = bytearray(data)
    for a in range(start, org + len(data)):
        out[a - org] ^= (2 + 8 * (a - start)) & 0x7F
    return bytes(out)


def decrypt(raw):
    """raw = flag + data + parity; returns the data as the loader stores it"""
    n = len(raw) - 2
    key, out = 0, bytearray()
    for i in range(n):
        key = (key + 3) & 0xFF
        out.append(raw[1 + i] ^ key ^ ((n - i) & 0xFF))
    return bytes(out)


def encrypt(data, flag=0):
    n = len(data)
    key, body = 0, bytearray([flag])
    for i in range(n):
        key = (key + 3) & 0xFF
        body.append(data[i] ^ key ^ ((n - i) & 0xFF))
    par = 0
    for b in body:
        par ^= b
    return bytes(body + bytes([par]))


def main():
    cmd = sys.argv[1]
    if cmd == 'loader':
        open(sys.argv[3], 'wb').write(loader_r(open(sys.argv[2], 'rb').read()))
    elif cmd == 'block':
        open(sys.argv[3], 'wb').write(decrypt(open(sys.argv[2], 'rb').read()))
    elif cmd == 'check':
        import tzxblocks
        blocks = [b['data'] for b in tzxblocks.parse(open(sys.argv[2], 'rb').read()) if 'data' in b]
        ld = blocks[3][1:-1]
        assert loader_r(loader_r(ld)) == ld
        for k in (4, 5, 6):
            raw = blocks[k]
            d = decrypt(raw)
            same = encrypt(d, raw[0]) == raw
            print(f'block {k + 1}: {len(d)} bytes, re-encrypted {"identical" if same else "DIFFERS"}')
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()

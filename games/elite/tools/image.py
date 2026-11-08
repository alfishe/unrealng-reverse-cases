#!/usr/bin/env python3
"""The game image as the loader leaves it at $70E0, decoded from the tape with no emulator.

    python3 tools/image.py OUT.bin [--side A] [--stage entry|prekick] [--check work/images/c1-entry.bin]

The steps are the loader's (docs/03-build-and-load.md 3.5-3.7):
1. the turbo block to $4000-$5BFF (the loading screen; the bytes bit-reversed, tools/softlock.py);
2. the 14 chunks at the addresses they land at: the reader's patches add 256 to the addresses of the chunks after
   TZX block 17 and take 256 off after block 31 (the patch chunks themselves at $5B1C);
3. Decrypt ($5B00): $6049-$D0A8 top down, plain = RLC((byte - key) XOR $6D) XOR $2E, the key the bytes from $5AFF
   down to $0001 (the loading screen and the 48K ROM), then from $5A00 down again;
4. the two ROM blocks: $D0BA-$FFA7 and $5B00-$6047;
5. the kickoff $D07F: $C800-$CFFF copied to $C000, the squares table at $BE00 / $BF00.
The image is 64 KB; the bytes the game owns are $5B00-$FFA7 (case.json lo / hi). Below $5B00 lie the loading
screen and the ROM; above $FFA7 the loader's leftovers and the stack the Lenslok check wrote.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import softlock as S  # noqa: E402

IY = 0x2E6D
LO, HI = 0x5B00, 0xFFA8


def rlc(a):
    return ((a << 1) | (a >> 7)) & 0xFF


def rrc(a):
    return ((a >> 1) | (a << 7)) & 0xFF


def key_addresses(n):
    """the IX of each decrypted byte, in order (the first for $D0A8)"""
    ix = 0x5AFF
    for _ in range(n):
        yield ix
        ix -= 1
        if ix == 0:
            ix = 0x5A00


def land(side):
    """memory after the stream: [(addr, data)] with the patch offsets applied"""
    shift = 0
    out = []
    for ih, idt, ln, ad, d in S.chunks(side):
        at = (ad + shift) & 0xFFFF
        out.append((at, d))
        if ad == 0x5B1C and ln == 2:
            shift = {b'\xdd\x24': 0x100, b'\xdd\x25': -0x100}[bytes(d)]
        if ad == 0x5A1C:        # LD IY,$2E6D over the end test: no more shifts
            shift = 0
    return out


def rom_blocks(side):
    bl = [b for b in E.tape_blocks(side) if b['id'] == 0x10][2:]
    return [(0xD0BA, bl[0]['data'][1:-1]), (0x5B00, bl[1]['data'][1:-1])]


def build(side='A', stage='entry'):
    """stage 'entry': at $70E0 (steps 1-5); 'prekick': after the two ROM blocks, before the Lenslok and the kickoff"""
    rom = open(os.path.join(E.K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()
    m = bytearray(0x10000)
    m[0:0x4000] = rom
    m[0x4000:0x5C00] = S.stream(side)[0][2][1:1 + 0x1C00]
    for at, d in land(side):
        for i, b in enumerate(d):
            if at + i >= 0x4000:
                m[(at + i) & 0xFFFF] = b
    for addr, ix in zip(range(0xD0A8, 0xD0A8 - 0x7060, -1), key_addresses(0x7060)):
        m[addr] = rlc(((m[addr] - m[ix]) & 0xFF) ^ (IY & 0xFF)) ^ (IY >> 8)
    for at, d in rom_blocks(side):
        m[at:at + len(d)] = d
    if stage == 'prekick':
        return m
    m[0xC000:0xC800] = m[0xC800:0xD000]
    for n in range(256):
        m[0xBE00 + n], m[0xBF00 + n] = (n * n) & 0xFF, (n * n) >> 8
    return m


def encrypt(plain, keymem):
    """the inverse of step 3 over $6049-$D0A8: plain is the 64 KB memory with the plain bytes, keymem the memory the
    key is read from (screen and ROM); returns the encrypted bytes for the same range"""
    out = bytearray(plain)
    for addr, ix in zip(range(0xD0A8, 0xD0A8 - 0x7060, -1), key_addresses(0x7060)):
        out[addr] = ((rrc(plain[addr] ^ (IY >> 8)) ^ (IY & 0xFF)) + keymem[ix]) & 0xFF
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('out')
    p.add_argument('--side', default='A')
    p.add_argument('--check')
    p.add_argument('--stage', default='entry', choices=['entry', 'prekick'])
    a = p.parse_args()
    m = build(a.side, a.stage)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    open(a.out, 'wb').write(m)
    if a.check:
        r = open(a.check, 'rb').read()
        diff = [x for x in range(LO, HI) if m[x] != r[x]]
        print(f'{len(diff)} bytes differ in ${LO:04X}-${HI - 1:04X}', ' '.join(f'${x:04X}' for x in diff[:20]))
        return 1 if diff else 0


if __name__ == '__main__':
    sys.exit(main())

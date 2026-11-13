#!/usr/bin/env python3
"""The 64 K image of the game as the ROM's LD-BYTES leaves it: BUMPY.TAP's block 3 (the loading screen) at $4000,
block 5 (BUMPY.CDE) at $61A8-$F8D3, zeros elsewhere. kit/mkgame.py reads $61A8-$F8D3 of it (case.json lo, hi).

    python3 tools/image.py OUT.bin
    python3 tools/image.py --block N OUT.bin     # TAP block N's data alone (1 the BASIC, 3 the screen, 5 the code)
    python3 tools/image.py --tap OUT.tap         # the original BUMPY.TAP as it is in orig/Bumpy.tap.zip
"""
import io
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def tap_blocks(data):
    """the data of each TAP block, flag and checksum removed"""
    out, at = [], 0
    while at < len(data):
        n = int.from_bytes(data[at:at + 2], 'little')
        out.append(data[at + 3:at + 1 + n])
        at += 2 + n
    return out


def original_tap():
    return zipfile.ZipFile(os.path.join(ROOT, 'orig', 'Bumpy.tap.zip')).read('BUMPY.TAP')


def main():
    if sys.argv[1] == '--tap':
        open(sys.argv[2], 'wb').write(original_tap())
        return
    blocks = tap_blocks(original_tap())
    if sys.argv[1] == '--block':
        os.makedirs(os.path.dirname(os.path.abspath(sys.argv[3])), exist_ok=True)
        open(sys.argv[3], 'wb').write(blocks[int(sys.argv[2])])
        return
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = blocks[3]
    mem[0x61A8:0x61A8 + len(blocks[5])] = blocks[5]
    os.makedirs(os.path.dirname(os.path.abspath(sys.argv[1])), exist_ok=True)
    open(sys.argv[1], 'wb').write(mem)


if __name__ == '__main__':
    main()

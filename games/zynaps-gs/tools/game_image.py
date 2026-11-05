#!/usr/bin/env python3
"""The game image kit/mkgame.py works on: Zynaps as the GS version's block 4 carries it, at its run addresses.

    python3 tools/game_image.py OUT.bin

orig/ZYNAP_GS.ZIP's TRD, Trush block 4 (the run's sector 227, loaded at $607C) unpacked to $61A8-$FFFF
(tools/trush.py); its Zynaps part to the 64 K image: $7400-$C7FF and $E000-$FFFF in place, the block's $C800-$DFFF
(Zynaps's $5C00-$73FF, which the installer's Mover moves down) at $5C00-$73FF. The image's $C800-$DFFF stays zero:
the block does not carry it (Zynaps's glyph cache, built in play; zero on the 48K tape as well). Below $5C00 nothing.
The game is $5C00-$FFFF (case.json lo / hi); block4.asm takes the three parts out of the assembled image.
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import trush  # noqa: E402

BLOCK4_SECTOR, BLOCK4_BASE, BLOCK4_DEST = 227, 0x607C, 0x61A8


def image():
    trd = zipfile.ZipFile(os.path.join(CASE, 'orig', 'ZYNAP_GS.ZIP')).read('ZYNAP_GS.TRD')
    run = trd[16 * 256:]
    h, data = trush.unpack(run[BLOCK4_SECTOR * 256:BLOCK4_SECTOR * 256 + 0x10000], BLOCK4_BASE)
    assert h['dest_start'] == BLOCK4_DEST and h['dest_end'] == 0xFFFF
    block = bytes(BLOCK4_DEST) + data
    mem = bytearray(0x10000)
    mem[0x7400:0xC800] = block[0x7400:0xC800]
    mem[0x5C00:0x7400] = block[0xC800:0xE000]
    mem[0xE000:] = block[0xE000:]
    return bytes(mem)


if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, 'wb').write(image())

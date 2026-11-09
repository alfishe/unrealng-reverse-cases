#!/usr/bin/env python3
"""The game image as the loader leaves it, from the original tape: TZX block 5 of `Video Pool.tzx` in
orig/VideoPool.tzx.zip (the turbo block, 25 000 data bytes) at $8000-$E1A7, where the $F000 loader's LD-BYTES copy
puts it (IX = $8000, DE = $61A8), and TZX block 4 (the 256-byte loader) at $F000-$F0FF; a 64 K file, zeros
elsewhere. The game is entered at $8000 (the loader's JP $8000 after the checksum).

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

import tzxblocks

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
GAME_AT, LOADER_AT, LENGTH, SUM = 0x8000, 0xF000, 25000, 0x2E3F


def tzx():
    """The bytes of `Video Pool.tzx` inside orig/VideoPool.tzx.zip"""
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'VideoPool.tzx.zip')) as z:
        return z.read('Video Pool.tzx')


def blocks():
    return list(tzxblocks.parse(tzx()))


def image():
    b = blocks()
    game, loader = b[5]['data'][1:-1], b[4]['data'][1:-1]
    assert len(game) == LENGTH and len(loader) == 256
    # the loader's own check: the 16-bit sum of the game's bytes against the word at $F03C
    assert sum(game) & 0xFFFF == SUM == loader[0x3C] | loader[0x3D] << 8
    mem = bytearray(0x10000)
    mem[GAME_AT:GAME_AT + LENGTH] = game
    mem[LOADER_AT:LOADER_AT + 256] = loader
    return bytes(mem)


if __name__ == '__main__':
    open(sys.argv[1], 'wb').write(image())

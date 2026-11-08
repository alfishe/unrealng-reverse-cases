#!/usr/bin/env python3
"""The game image as the loader leaves it, from the original tape: TZX block 8 (the code file, 37536 bytes, loaded
at $6590-$F82F) at $6D60-$FFFF, the place the loader's MoveStub LDDR puts it (docs/03-build-and-load.md); a 64 K
file, zeros elsewhere. The game is entered at $6D60.

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

import tzxblocks

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
GAME_AT = 0x6D60


def tzx():
    """The bytes of Exolon.tzx inside orig/Exolon.tzx.zip"""
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Exolon.tzx.zip')) as z:
        return z.read('Exolon.tzx')


def blocks():
    return list(tzxblocks.parse(tzx()))


def image():
    data = blocks()[8]['data'][1:-1]
    assert GAME_AT + len(data) == 0x10000
    mem = bytearray(0x10000)
    mem[GAME_AT:] = data
    return bytes(mem)


if __name__ == '__main__':
    open(sys.argv[1], 'wb').write(image())

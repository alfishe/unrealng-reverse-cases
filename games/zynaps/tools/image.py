#!/usr/bin/env python3
"""The game image as the loader leaves it, from the original tape: TZX block 8 (the `code` file, 40535 bytes) at
$61A8-$FFFE, the place MoveStub's LDDR puts it (docs/03-build-and-load.md 3.5); a 64 K file, zeros elsewhere.

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

import tzxblocks

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)


def tzx():
    """The bytes of Zynaps.tzx inside orig/Zynaps.tzx.zip"""
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Zynaps.tzx.zip')) as z:
        return z.read('Zynaps.tzx')


def blocks():
    return list(tzxblocks.parse(tzx()))


def image():
    data = blocks()[8]['data'][1:-1]
    mem = bytearray(0x10000)
    mem[0x61A8:0x61A8 + len(data)] = data
    return bytes(mem)


if __name__ == '__main__':
    open(sys.argv[1], 'wb').write(image())

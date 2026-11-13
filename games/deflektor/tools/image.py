#!/usr/bin/env python3
"""The 64 K image of the game at its entry `$8382` (the stage at `$FD00` has moved `$7D00-$FCFF` to `$6000-$DFFF`).

Stage 1: the image is the `c1` recording's memory at frame 15752 T 33930 (`time_travel memory_at`, tools/ttd_dump.py,
saved as work/stage1/images/entry.cpu.bin), the 10 Mega Games copy of the tape loaded at ROM timing; its turbo block is
the original's byte for byte with the same timing (README). Stage 2 replaces this with the image computed from
orig/Deflektor.tzx.zip: the loader's pulse code, the decrypting stage `$7B52` and the movers
(docs/03-build-and-load.md, 3.1).

    python3 tools/image.py work/mkgame/original.bin
"""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'work', 'stage1', 'images', 'entry.cpu.bin')

if __name__ == '__main__':
    data = open(SRC, 'rb').read()
    assert len(data) == 0x10000 and data[0xFD18:0xFD1B] == bytes([0xC3, 0x82, 0x83])
    os.makedirs(os.path.dirname(os.path.abspath(sys.argv[1])), exist_ok=True)
    shutil.copyfile(SRC, sys.argv[1])

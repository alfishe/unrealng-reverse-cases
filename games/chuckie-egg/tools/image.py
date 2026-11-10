#!/usr/bin/env python3
"""The game image as the loader leaves it, from the original tape `Chuckie Egg.tzx` in orig/ChuckieEgg.tzx.zip:
TZX block 2 (the BASIC program and its variables, 1624 bytes) at PROG `$5CCB-$6322`, block 3 (two bytes, `01 00`)
at ERR_SP `$5C3D`, block 4 (the game, 18 900 bytes) at `$8214-$CBE7`, where the loader at `$5EF3` puts them
(two calls of the ROM's LD-BYTES `$0556`: IX `$5C3D` DE 2, then IX `$8214` DE `$49D4`); a 64 K file, zeros
elsewhere. The game is entered at `$A410` (the loader's `JP $A410` at `$5FC1`).

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

import tzxblocks

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
PROG, ERR_SP, GAME_AT, GAME_LENGTH = 0x5CCB, 0x5C3D, 0x8214, 18900


def tzx():
    """The bytes of `Chuckie Egg.tzx` inside orig/ChuckieEgg.tzx.zip"""
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'ChuckieEgg.tzx.zip')) as z:
        return z.read('Chuckie Egg.tzx')


def blocks():
    return [b for b in tzxblocks.parse(tzx()) if b.get('data')]


def image():
    header, basic, errsp, game = (b['data'][1:-1] for b in blocks())
    assert header[0] == 0 and len(basic) == 1624 and errsp == b'\x01\x00' and len(game) == GAME_LENGTH
    mem = bytearray(0x10000)
    mem[PROG:PROG + len(basic)] = basic
    mem[ERR_SP:ERR_SP + 2] = errsp
    mem[GAME_AT:GAME_AT + GAME_LENGTH] = game
    return bytes(mem)


if __name__ == '__main__':
    open(sys.argv[1], 'wb').write(image())

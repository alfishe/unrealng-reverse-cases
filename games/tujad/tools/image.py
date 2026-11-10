#!/usr/bin/env python3
"""The Tujad image as the loader leaves it, from the original tape `Tujad.tzx` in orig/Tujad.tzx.zip: TZX block 4
(the CODE block "TUJAD", 6944 bytes: the loading screen and a 32-byte stub) at `$4000-$5B1F`, where the BASIC's
`LOAD "" CODE 16384` puts it (its header says 32768), and block 5 (the headerless game block, 40 256 bytes) at
`$60C0-$FDFF`, where the stub at `$5B00` loads it (`SCF; LD A,$FF; LD IX,$60C0; LD DE,$9D40; CALL $0556`); and
block 2 (the BASIC program, 88 bytes) at PROG `$5CCB-$5D22`, where the ROM's LOAD puts it (the source of
src/tape/basic.asm). A 64 K file, zeros elsewhere. The game is entered at `$6300` (the stub's `JP $6300` at `$5B0D`).

    python3 tools/image.py OUT.bin
"""
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
SCREEN_AT, SCREEN_LENGTH, GAME_AT, GAME_LENGTH, ENTRY = 0x4000, 6944, 0x60C0, 40256, 0x6300
PROG = 0x5CCB


def tzx():
    """The bytes of `Tujad.tzx` inside orig/Tujad.tzx.zip"""
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'Tujad.tzx.zip')) as z:
        return z.read('Tujad.tzx')


def blocks():
    return [b for b in tzxblocks.parse(tzx()) if b.get('data')]


def image():
    _, basic, _, code, game = (b['data'][1:-1] for b in blocks())
    assert len(basic) == 88 and len(code) == SCREEN_LENGTH and len(game) == GAME_LENGTH
    mem = bytearray(0x10000)
    mem[SCREEN_AT:SCREEN_AT + SCREEN_LENGTH] = code
    mem[GAME_AT:GAME_AT + GAME_LENGTH] = game
    mem[PROG:PROG + len(basic)] = basic
    return bytes(mem)


if __name__ == '__main__':
    open(sys.argv[1], 'wb').write(image())

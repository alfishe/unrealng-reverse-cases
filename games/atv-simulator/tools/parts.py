#!/usr/bin/env python3
"""The pieces of ATV Simulator's tape, cut from the original TZX for kit/mkgame.py's part files and the build's check
(work/parts/):

    python3 tools/parts.py

    basic-5ccb.bin    tape block 1, the BASIC loader (44 bytes at PROG $5CCB)
    loader-ffdc.bin   tape block 3, the machine-code loader (34 bytes at $FFDC)
    loading.scr       tape block 5, the loading screen (6912 bytes at $4000)
    game-6338.bin     tape block 7, the game (40000 bytes at $6338)
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import tapblocks  # noqa: E402


def original():
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'ATVSimulator.tzx.zip')) as z:
        return z.read('ATV Simulator.tzx')


def blocks():
    """the bytes of the eight data blocks, flag and checksum dropped"""
    return [bytes(b['data'][1:-1]) for b in tapblocks.parse_tzx(original()) if b.get('data')]


def main():
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    d = blocks()
    for name, data in (('basic-5ccb.bin', d[1]), ('loader-ffdc.bin', d[3]), ('loading.scr', d[5]),
                       ('game-6338.bin', d[7])):
        open(os.path.join(out, name), 'wb').write(data)
        print(f'{name}: {len(data)} bytes')


if __name__ == '__main__':
    main()

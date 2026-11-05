#!/usr/bin/env python3
"""The game image as the loaders leave it, from orig/ alone: the file neart001 (39536 bytes at $6590-$FFFF).

    python3 tools/game_image.py [--out work/mkgame] [--medium scl|tap]

Writes OUT/original.bin, a 64 K image: zeros, and neart001 at $6590 (the bytes below it are the screen, the system
variables and the loader, none of them the game's; case.json lo / hi). --medium scl reads the file from the SCL in
orig/NE_GS_TZ.zip (the TRD holds the same bytes), --medium tap from Hood's tape (4 bytes differ: docs/03 3.5).
The driver page is not part of this image: it is src/disk/driver.asm (bank 1) and src/tape/driver.asm (bank 6).
"""
import argparse
import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIP = os.path.join(ROOT, 'orig', 'NE_GS_TZ.zip')
TAP = os.path.join(ROOT, 'orig', 'Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap')
BASE, LENGTH = 0x6590, 39536


def scl_file(scl, name):
    """the declared bytes of a file of an SCL image"""
    n = scl[8]
    at = 9 + 14 * n
    for i in range(n):
        e = scl[9 + 14 * i:9 + 14 * i + 14]
        size = 256 * e[13]
        if e[:8].decode('latin-1') == name[:8] and chr(e[8]) == name[9]:
            return scl[at:at + int.from_bytes(e[11:13], 'little')]
        at += size
    raise SystemExit(f'{name}: not in the SCL')


def tap_file(tap, name):
    """the data block after the CODE header NAME"""
    at, header = 0, None
    while at < len(tap):
        n = int.from_bytes(tap[at:at + 2], 'little')
        block = tap[at + 2:at + 2 + n]
        at += 2 + n
        if block[0] == 0:
            header = block[2:12].decode('latin-1').rstrip()
        elif header == name:
            return block[1:-1]
    raise SystemExit(f'{name}: not on the tape')


def neart001(medium):
    if medium == 'tap':
        return tap_file(open(TAP, 'rb').read(), 'neart001')
    with zipfile.ZipFile(ZIP) as z:
        return scl_file(z.read('NE_GS_TZ.SCL'), 'neart001.C')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'work', 'mkgame'))
    p.add_argument('--medium', choices=('scl', 'tap'), default='scl')
    a = p.parse_args()
    data = neart001(a.medium)
    assert len(data) == LENGTH, len(data)
    image = bytearray(0x10000)
    image[BASE:] = data
    os.makedirs(a.out, exist_ok=True)
    open(os.path.join(a.out, 'original.bin'), 'wb').write(image)


if __name__ == '__main__':
    main()

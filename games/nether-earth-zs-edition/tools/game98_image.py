#!/usr/bin/env python3
"""The '98 game image as the REM loader leaves it, from orig/ alone (through tools/zs_media.py).

    python3 tools/game98_image.py [--out work/stage2/game98/mk]      # writes OUT/original.bin

`NEZSEd.B` (orig/NEZSED98.zip -> NEZSED98.SCL) is one BASIC monoblock; its sectors 44-156 (113 sectors, 28928
bytes) are read by the REM loader's second TR-DOS call (`#3D13`, `$5D91`) to `$6780-$D87F` and entered at `$A600`.
original.bin is a 64 K image with those bytes at `$6780` and zero everywhere else (the screen, the intro and the
work space past `$D87F` are not the game file's bytes).
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import zs_media  # noqa: E402

LO, FIRST_SECTOR, SECTORS = 0x6780, 44, 113


def game_bytes():
    """the 28928 bytes of the '98 game, as the file holds them"""
    files, _ = zs_media.scl_files(zs_media.scl_from_zip(zs_media.ZIP98))
    body = files[0]['body']
    data = body[FIRST_SECTOR * 256:(FIRST_SECTOR + SECTORS) * 256]
    assert len(data) == SECTORS * 256 == 0xD880 - LO, len(data)
    return data


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'work', 'stage2', 'game98', 'mk'))
    p.add_argument('--bin', help='also write the 28928 bytes alone to this file')
    a = p.parse_args()
    data = game_bytes()
    image = bytearray(0x10000)
    image[LO:LO + len(data)] = data
    os.makedirs(a.out, exist_ok=True)
    open(os.path.join(a.out, 'original.bin'), 'wb').write(image)
    if a.bin:
        open(a.bin, 'wb').write(data)


if __name__ == '__main__':
    main()

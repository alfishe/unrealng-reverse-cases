#!/usr/bin/env python3
"""Cuts the boot's pieces out of orig/boot.scl, where its BASIC loader puts them in memory.

    python3 tools/image.py            # work/mkgame/original.bin, work/parts/basic-5d3b.bin, work/parts/music-c000.bin

The one file `boot` holds 46 sectors. Sector 0 is the BASIC program (TR-DOS loads it at PROG, `$5D3B`); the loader
in its line 4 then reads the next sectors itself with TR-DOS `$3D13`: 15 to `$61A8` (the menu's code), 8 to `$A600`
(the font and the graphics), 22 to `$C000` (the music). original.bin is the 64 K memory with these three pieces in
place (zeros elsewhere): the game image of case.json, whose lo..hi ($61A8-$ADFF) holds the code and the graphics.
basic-5d3b.bin is sector 0, the BASIC part's image (src/basic); music-c000.bin the 22 sectors at $C000, the music
part's image (src/music).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import disk  # noqa: E402

# (address, sectors) of the pieces after the BASIC sector, in the order the loader reads them
PIECES = [(0x61A8, 15), (0xA600, 8), (0xC000, 22)]


def pieces(body):
    out, at = [], 256
    for addr, secs in PIECES:
        out.append((addr, body[at: at + 256 * secs]))
        at += 256 * secs
    return out


def main():
    boot = disk.read(os.path.join(ROOT, 'orig', 'boot.scl'))[0][0]
    mem = bytearray(0x10000)
    for addr, data in pieces(boot['body']):
        mem[addr: addr + len(data)] = data
    music = pieces(boot['body'])[2][1]
    for path, data in (('work/mkgame/original.bin', mem), ('work/parts/basic-5d3b.bin', boot['body'][:256]),
                       ('work/parts/music-c000.bin', music)):
        path = os.path.join(ROOT, path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)


if __name__ == '__main__':
    main()

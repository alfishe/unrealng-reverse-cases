#!/usr/bin/env python3
"""The 64 K image of the game as the tape leaves it on a 128K, cut from orig/Terramex.tzx.zip: the loading screen
(TZX block 3, 6912 bytes) at `$4000`, the selector block (block 4, 38 648 bytes) at `$6000-$F6F7`, then the game block
(block 5, 36 352 bytes) at `$7200-$FFFF` over it, as the BASIC loader's LD-BYTES calls place them
([doc 3.1](../docs/03-build-and-load.md#31-the-tape-block-by-block)). `$6000-$71FF` stays the selector block's first
4608 bytes. The RAM banks the 128K selector fills (1, 3, 4, 6) are not in this image.

    python3 tools/image.py work/mkgame/original.bin
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402


def blocks():
    with zipfile.ZipFile(os.path.join(HERE, '..', 'orig', 'Terramex.tzx.zip')) as z:
        t = z.read('Terramex.tzx')
    return [b['data'][1:-1] for b in tzxblocks.parse(t) if b.get('data')]


def image():
    hdr, basic, screen, sel, game = blocks()
    assert (len(screen), len(sel), len(game)) == (6912, 0x96F8, 0x8E00)
    img = bytearray(0x10000)
    img[0x4000:0x5B00] = screen
    img[0x6000:0x6000 + len(sel)] = sel
    img[0x7200:0x10000] = game
    return bytes(img)


if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, 'wb').write(image())
    print(f'{out}: 65536 bytes')

#!/usr/bin/env python3
"""The game's images as the original disk leaves them, for kit/mkgame.py (case.json `image_cmd`).

    python3 tools/game_image.py [--out work/mkgame]

Both come from orig/ alone: the HRUM 3.5 blocks read out of the SCL's sectors (src/disk.txt says where each lies)
and unpacked by tools/hrum.py.

- `original.bin`: the 64 K Z80 view in play, banks 5, 2, 0. The game block (the a_nether.E sectors 284-347 and the
  last 914 bytes at sector 251 + 158) unpacks to $6731-$D7D7; everything else is zero (the screen, the view buffer
  below $6731, the world state and the map past $D7D7 are built at run time).
- `bank3/original.bin`: a 64 K view with bank 3 at $C000 (sector 212, unpacked to $C000-$FE1E): Dead End and the
  game's main menu picture ($E73B-$F1ED), which the game calls through MenuPicture.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import hrum  # noqa: E402

SCL = os.path.join(ROOT, 'orig', 'Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl')
HEADER = 9 + 14 * 4     # "SINCLAIR", the file count, four catalogue entries
SETUP, DEPACKER = 31, 119


def sector(scl, n, offset=0):
    return HEADER + n * 256 + offset


def block_fields(blk):
    """(Out, OutLen, StreamLen) from a block's 31-byte set-up (src/sfx/hrum35.asm)"""
    word = lambda at: blk[at] | blk[at + 1] << 8  # noqa: E731
    out, last, stream = word(18), word(25), word(28)
    return out, last - out + 1, stream


def unpack(blk):
    out, length, stream = block_fields(blk)
    start = SETUP + DEPACKER
    data, used = hrum.unpack(blk[start:start + stream], blk[start - 5:start])
    assert used == stream and len(data) == length, (used, stream, len(data), length)
    return out, data


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'work', 'mkgame'))
    a = p.parse_args()
    scl = open(SCL, 'rb').read()
    # the game block: its first 16384 bytes at sector 284, the rest at sector 251 + 158
    head = scl[sector(scl, 284):sector(scl, 284) + 16384]
    _, _, stream = block_fields(head)
    tail = SETUP + DEPACKER + stream - 16384
    game = head + scl[sector(scl, 251, 158):sector(scl, 251, 158) + tail]
    out, data = unpack(game)
    assert out == 0x6731, hex(out)
    image = bytearray(0x10000)
    image[out:out + len(data)] = data
    os.makedirs(a.out, exist_ok=True)
    open(os.path.join(a.out, 'original.bin'), 'wb').write(image)
    # bank 3: Dead End and the menu picture
    first = sector(scl, 212)
    _, _, stream = block_fields(scl[first:first + SETUP])
    out, data = unpack(scl[first:first + SETUP + DEPACKER + stream])
    assert out == 0xC000, hex(out)
    image = bytearray(0x10000)
    image[out:out + len(data)] = data
    os.makedirs(os.path.join(a.out, 'bank3'), exist_ok=True)
    open(os.path.join(a.out, 'bank3', 'original.bin'), 'wb').write(image)


if __name__ == '__main__':
    main()

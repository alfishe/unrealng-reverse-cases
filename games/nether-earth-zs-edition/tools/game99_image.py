#!/usr/bin/env python3
"""The '99 game block and patches block as the disk leaves them, as 64 K images for tools/game99_mkgame.py.

    python3 tools/game99_image.py [--out work/stage2/game99/mkgame]

Everything comes from orig/NEZSED.ZIP through tools/zs_media.py (the block read by sector number, unpacked by
tools/zsdepack.py):

- `game/original.bin`: the game block's output `$6780-$D7D2` at its addresses (page 0 at `$C000`), the rest zero.
  This is the block AS UNPACKED: stage 3 later copies pieces of the patches block over `$A56A-$A5D5`, `$C100-$C17E`
  and `$C1FD-$C332`, LOAD MAP and the start-up menu patch operands; none of that is in this image.
- `patches-disk/original.bin`, `patches-tape/original.bin`: the patches block's output `$D800-$DB6F` holds eight
  pieces in two sets that stage 3 copies to the same run addresses (PIECES below); each set's pieces are placed at
  their run addresses, so that the source annotates them where they run.
- `patches-out.bin`, `game-out.bin`: the two outputs as bytes, for the build's check.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import zs_media  # noqa: E402

GAME_LO, GAME_HI = 0x6780, 0xD7D3
PATCH_LO, PATCH_HI = 0xD800, 0xDB70

# name, set, offset in the patches block's output ($D800 + offset), length, run address
PIECES = [
    ('diskread', 'disk', 0x000, 0x03E, 0xA598),
    ('diskmap', 'disk', 0x03E, 0x136, 0xC1FD),
    ('taperead', 'tape', 0x174, 0x038, 0xA598),
    ('tapemap', 'tape', 0x1AC, 0x093, 0xC1FD),
    ('paging128', 'disk', 0x23F, 0x029, 0xA56A),
    ('menu128', 'disk', 0x268, 0x07F, 0xC100),
    ('textload48', 'tape', 0x2E7, 0x02E, 0xA56A),
    ('menu48', 'tape', 0x315, 0x05B, 0xC100),
]


def blocks():
    """(game output, patches output) from the SCL"""
    files, _ = zs_media.scl_files(zs_media.scl_from_zip(zs_media.ZIP99))
    body = files[0]['body']
    out = {}
    for name, first, n, at, packed in zs_media.BLOCKS:
        if name in ('game', 'patches'):
            lo, data, _ = zs_media.unpack(body[first * 256:(first + n) * 256], at)
            out[name] = (lo, data)
    assert out['game'][0] == GAME_LO and len(out['game'][1]) == GAME_HI - GAME_LO
    assert out['patches'][0] == PATCH_LO and len(out['patches'][1]) == PATCH_HI - PATCH_LO
    return out['game'][1], out['patches'][1]


def piece_image(patches, which):
    image = bytearray(0x10000)
    for name, group, off, n, run in PIECES:
        if group == which:
            image[run:run + n] = patches[off:off + n]
    return bytes(image)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', default=os.path.join(ROOT, 'work', 'stage2', 'game99', 'mkgame'))
    a = p.parse_args()
    game, patches = blocks()
    assert sum(n for _, _, _, n, _ in PIECES) == len(patches)
    image = bytearray(0x10000)
    image[GAME_LO:GAME_HI] = game
    for sub, data in (('game', bytes(image)), ('patches-disk', piece_image(patches, 'disk')),
                      ('patches-tape', piece_image(patches, 'tape'))):
        os.makedirs(os.path.join(a.out, sub), exist_ok=True)
        open(os.path.join(a.out, sub, 'original.bin'), 'wb').write(data)
    open(os.path.join(a.out, 'game-out.bin'), 'wb').write(game)
    open(os.path.join(a.out, 'patches-out.bin'), 'wb').write(patches)


if __name__ == '__main__':
    main()

"""Bumpy's data as stage 1 found it, read from the image as loaded (work/mkgame/original.bin, case.json image_cmd;
or work/stage1/images/code.bin): the level records, the object sprites and colours, the platform sprites.

Level record: 75 bytes at `$8C3C` + 75 x level (levels 0-99, `$8C3C-$A987`), copied to `$AA20` by `$CF76`:
  bytes 0-35   one a cell, 6 x 6 cells row by row: low nibble the platform type (to `$AA6B`, handlers `$C5A8`),
               high nibble the wall type (to `$AA8F`, handlers `$C5C2`)
  byte 36      the ball's start cell (to `$AB1A`)
  bytes 37-38  not yet known
  bytes 39-74  one a cell: the object (0 none, 1-40; sprite `$6CB0` + 56 x object, colour `$C6F6` + object)
Object sprite: 14 rows of 4 bytes, each byte one 4-pixel nibble (its low four bits), drawn by `$E3E5`.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 0x61A8
LEVELS, RECORD = 0x8C3C, 75
OBJ_SPRITES, OBJ_COLOURS, OBJ_ROWS = 0x6CB0, 0xC6F6, 14

# platform type (low nibble) -> (sprite, width in nibbles, rows) of its main sprite, from the handlers at $C5A8
PLATFORMS = {1: (0x7788, 8, 4), 2: (0x7900, 8, 4), 3: (0x7A78, 6, 4), 4: (0x7B62, 4, 4), 5: (0x7BE2, 8, 4),
             6: (0x77A8, 8, 10), 7: (0x77F8, 8, 10), 8: (0x7788, 8, 4), 9: (0x7BE2, 8, 4), 12: (0x7D5A, 6, 7)}


def image():
    for p in (os.path.join(HERE, '..', 'work', 'mkgame', 'original.bin'),
              os.path.join(HERE, '..', 'work', 'stage1', 'images', 'code.bin')):
        if os.path.exists(p):
            return open(p, 'rb').read()
    raise SystemExit('no image: run the case.json image_cmd')


def peek(img, address, n=1):
    return img[address - BASE:address - BASE + n]


def level(img, n):
    r = peek(img, LEVELS + RECORD * n, RECORD)
    return {'address': LEVELS + RECORD * n, 'platform': [b & 15 for b in r[:36]], 'wall': [b >> 4 for b in r[:36]],
            'start': r[36], 'b37': r[37], 'b38': r[38], 'object': list(r[39:75])}


def nibble_sprite(img, address, width, rows):
    """rows of pixels (0/1), width nibbles of 4 pixels a row"""
    data = peek(img, address, width * rows)
    return [[(data[y * width + c] >> (3 - i)) & 1 for c in range(width) for i in range(4)] for y in range(rows)]


def object_sprite(img, k):
    return nibble_sprite(img, OBJ_SPRITES + 56 * k, 4, OBJ_ROWS)


def object_colour(img, k):
    return peek(img, OBJ_COLOURS + k)[0]

#!/usr/bin/env python3
"""The graphics of the game image as indexed PNG (src/res/gfx, README there), both ways; a plugin of res_formats.py.

Every picture is 1 bit a pixel, palette index 0 paper, 1 the drawn pixel, 2 the gap between frames and rows (not
data, never read back). The bytes are block 2's (the 48K tape's, the same): the sprite sets the start-up complements (`$E000-$E747`,
`$F048-$F107`) are stored as block 2 has them, a set bit the sprite's pixel (the game draws the complement: a
clear bit shows the object's paper colour).

| Resource | Bytes | Layout of the bytes | Picture |
| --- | --- | --- | --- |
| gfx/tiles.bin | 2048 | 8 line pages of 256: tile t line y at y * 256 + t | 16 x 16 tiles of 8 x 8 |
| gfx/wave-cells.bin | 1024 | 64 columns of 16 lines, column-major, top line first | 2 rows of 32 columns |
| gfx/sprites.bin | 1864 | the six sets of SPRITE_SETS, column-major | one row a set, its frames side by side |
| gfx/pod.bin | 192 | 4 frames (shifts 0, 2, 4, 6 pixels) of 3 columns x 16 lines | the frames side by side |
Copied from the 48K case (../zynaps/tools): the formats of the same bytes.
"""
import io

from PIL import Image

PALETTE = [24, 24, 32, 235, 235, 220, 200, 40, 40]
GAP = 2  # pixels between frames and between rows (index 2)

# gfx/sprites.bin from $E000: (offset, frames, columns, lines, name). Frame f of a set at offset + f * columns *
# lines; column c line y of a frame at c * lines + y (the drawing walks a column down, then the next).
SPRITE_SETS = [
    (0x000, 1, 1, 8, 'pad'),           # $E000: 8 bytes read above the first column when a sprite's Y is not 8-aligned
    (0x008, 8, 3, 24, 'player'),       # $E008: 8 shifts, descriptor $7E94
    (0x248, 8, 3, 24, 'sight'),        # $E248: 8 shifts, descriptor $7EAE (slot $F600)
    (0x488, 8, 2, 24, 'explosion'),    # $E488: 8 frames, descriptor $7EA1 (frame 1 first)
    (0x608, 4, 2, 8, 'laser'),         # $E608: shifts 0, 2, 4, 6, descriptor $7EC8
    (0x648, 8, 2, 16, 'ball'),         # $E648: 8 shifts, descriptor $7ED5 (enemy shots, plasma balls)
]
SPRITES_SIZE = 0x748
POD = (0, 4, 3, 16, 'pod')


def to_png(pixels, width, height):
    image = Image.new('P', (width, height), 2)
    image.putpalette(PALETTE)
    for (x, y), v in pixels.items():
        image.putpixel((x, y), v)
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=False)
    return out.getvalue()


def from_png(data, name):
    image = Image.open(io.BytesIO(data))
    if image.mode != 'P':
        raise SystemExit(f'res_gfx: {name}: not an indexed PNG')
    return image


def put_byte(pixels, x, y, value):
    for k in range(8):
        pixels[(x + k, y)] = (value >> (7 - k)) & 1


def get_byte(image, x, y, name):
    value = 0
    for k in range(8):
        v = image.getpixel((x + k, y))
        if v not in (0, 1):
            raise SystemExit(f'res_gfx: {name}: pixel ({x + k}, {y}) is {v}, not 0 or 1')
        value = value << 1 | v
    return value


# ------------------------------------------------------------------------------------------------- tiles

def tiles_to(data, name):
    pixels = {}
    for t in range(256):
        for y in range(8):
            put_byte(pixels, (t % 16) * 8, (t // 16) * 8 + y, data[y * 256 + t])
    return to_png(pixels, 128, 128)


def tiles_from(data, name):
    image = from_png(data, name)
    out = bytearray(2048)
    for t in range(256):
        for y in range(8):
            out[y * 256 + t] = get_byte(image, (t % 16) * 8, (t // 16) * 8 + y, name)
    return bytes(out)


# -------------------------------------------------------------------------------------------- wave cells

def cells_to(data, name):
    pixels = {}
    for col in range(64):
        for y in range(16):
            put_byte(pixels, (col % 32) * 8, (col // 32) * (16 + GAP) + y, data[col * 16 + y])
    return to_png(pixels, 256, 32 + GAP)


def cells_from(data, name):
    image = from_png(data, name)
    out = bytearray(1024)
    for col in range(64):
        for y in range(16):
            out[col * 16 + y] = get_byte(image, (col % 32) * 8, (col // 32) * (16 + GAP) + y, name)
    return bytes(out)


# --------------------------------------------------------------------------------------------- sprite sets

def layout(sets):
    """(x, y) of each set's top left in the picture, and the picture's size"""
    places, y, width = [], 0, 0
    for _off, frames, cols, lines, _n in sets:
        places.append((0, y))
        width = max(width, frames * (cols * 8 + GAP) - GAP)
        y += lines + GAP
    return places, width, y - GAP


def sets_to(data, sets):
    places, width, height = layout(sets)
    pixels = {}
    for (off, frames, cols, lines, _n), (x0, y0) in zip(sets, places):
        for f in range(frames):
            base = off + f * cols * lines
            for c in range(cols):
                for y in range(lines):
                    put_byte(pixels, x0 + f * (cols * 8 + GAP) + c * 8, y0 + y, data[base + c * lines + y])
    return to_png(pixels, width, height)


def sets_from(data, sets, size, name):
    image = from_png(data, name)
    places, _w, _h = layout(sets)
    out = bytearray(size)
    for (off, frames, cols, lines, _n), (x0, y0) in zip(sets, places):
        for f in range(frames):
            base = off + f * cols * lines
            for c in range(cols):
                for y in range(lines):
                    out[base + c * lines + y] = get_byte(image, x0 + f * (cols * 8 + GAP) + c * 8, y0 + y, name)
    return bytes(out)


CONVERTERS = {
    'gfx/tiles.bin': (tiles_to, tiles_from),
    'gfx/wave-cells.bin': (cells_to, cells_from),
    'gfx/sprites.bin': (lambda d, n: sets_to(d, SPRITE_SETS), lambda d, n: sets_from(d, SPRITE_SETS, SPRITES_SIZE, n)),
    'gfx/pod.bin': (lambda d, n: sets_to(d, [POD]), lambda d, n: sets_from(d, [POD], 192, n)),
}


def to_editable(data, name):
    return CONVERTERS[name][0](data, name)


def from_editable(data, name):
    return CONVERTERS[name][1](data, name)


# One kind for all: res_formats.sources() tells kinds apart by their suffix, so each kind needs its own.
KINDS = [('gfx/*.bin', '.gfx.png', to_editable, from_editable)]

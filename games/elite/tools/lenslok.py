#!/usr/bin/env python3
"""The Lenslok screen of Elite, drawn from the game's own tables the way its code draws it, and a model lens that
puts the slices back in order.

    python3 tools/lenslok.py draw CODE [--width 144] [--marks 32,62] --out OUT.png   # the screen the code draws
    python3 tools/lenslok.py lens SCREEN.scr [--width 144] --out OUT.png             # a screen seen through the lens

The model, routine by routine (docs/lenslok.md 4):
- GlyphRow $C6E6: row r (0-7) of the two code characters from the ROM font (CHARS+256), columns 1-6 of each
  (SRA drops column 7), char 1 then char 2: 12 bits; on row 7 char 2's byte is row 6's (glyph_bits);
- Scramble $C59C: 14 output bits per row: the row's bit of the first mark byte ($C77F), then output slot k (1..12)
  takes glyph column c with PERM[c-1] == k, then the row's bit of the second mark ($C780);
- DrawRow $C303: slice j (1..14) spans GEOM[j] = (a, b) in tenths of the scale from the centre x = 128, the scale
  being the calibrated width div 11; a set bit fills the slice h = 20 * scale div 100 pixel rows high, row r at
  PLOT y = 120 - h (r + 1) downwards; widths and offsets are each rounded down separately (the gaps of 1 pixel
  between some slices are the code's);
- the frame: the centre line x = 127-128 from PLOT y 88 to 175, the bracket $C4D0 (two 40-pixel posts and the bar
  at PLOT y 120, the width the player calibrated).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402

# The table at $C7B6 (IX): +0 the scale before calibration, +1..+28 the 14 slices (signed), +29..+40 the permutation
GEOM = [(-45, -40), (-40, -29), (-29, -22), (-21, -16), (-15, -11), (-10, -7), (-7, -2),
        (2, 7), (8, 12), (12, 17), (17, 22), (22, 30), (30, 38), (38, 43)]
PERM = [3, 2, 1, 7, 4, 5, 10, 6, 8, 9, 12, 11]
ROM = os.environ.get('ZX48ROM') or os.path.join(E.K.unreal_root(), 'data', 'rom', '48.rom')


def font():
    return open(ROM, 'rb').read()[0x3D00:0x4000]


def glyph_bits(code, row, f=None):
    """the 12 bits of a row. GlyphGather $C733 writes 8 - row bytes (its loop counter is the row loop's), so on the
    last row (7) it writes char 1 only and char 2's byte is still row 6's: the bottom row repeats char 2's row 6"""
    f = f or font()
    bits = []
    for i, ch in enumerate(code[:2]):
        b = f[(ch - 32) * 8 + (6 if row == 7 and i == 1 else row)]
        bits += [(b >> (6 - c)) & 1 for c in range(6)]   # columns 1..6 (bit 6 .. bit 1)
    return bits


def scramble(bits, row, marks):
    out = [(marks[0] >> row) & 1]
    for k in range(1, 13):
        c = PERM.index(k) + 1
        out.append(bits[c - 1])
    out.append((marks[1] >> row) & 1)
    return out


def slices(width):
    s = width // 11
    res = []
    for a, b in GEOM:
        if a < 0:
            w = (-a - -b) * s // 10
            x = 128 - (-a) * s // 10
        else:
            w = (b - a) * s // 10
            x = 128 + a * s // 10
        res.append((x, w))
    return s, res


def draw(code, width=144, marks=(0x32, 0x62)):
    """the 256 x 192 bitmap as a set of (x, row) pixels lit"""
    px = set()

    def plot(x, y):
        px.add((x, 175 - y))
    f = font()
    s, sl = slices(width)
    h = 20 * s // 100
    for y in range(88, 176):
        plot(128, y)
        plot(127, y)
    left = (255 - width) >> 1
    for y in range(100, 140):
        plot(left - 1, y)
        plot(left + width, y)
    for x in range(left, left + width):
        plot(x, 120)
    for r in range(8):
        out = scramble(glyph_bits(code, r, f), r, marks)
        top = 120 - h * (r + 1)
        for j, (x, w) in enumerate(sl):
            if out[j]:
                for dy in range(h):
                    for dx in range(w):
                        plot(x + dx, top - dy)
    return px


def image_of(px, scale=2):
    img = Image.new('1', (256, 192))
    for x, y in px:
        if 0 <= x < 256 and 0 <= y < 192:
            img.putpixel((x, y), 1)
    return img.convert('RGB').resize((256 * scale, 192 * scale), Image.NEAREST)


def screen_pixels(scr):
    px = set()
    for y in range(192):
        a = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for c in range(32):
            b = scr[a + c]
            for bit in range(8):
                if b & (0x80 >> bit):
                    px.add((c * 8 + bit, y))
    return px


def lens_view(px, width=144, aperture=12):
    """what the model lens shows: aperture i (glyph column i) looks at the slice PERM[i-1]+1 and widens it to `aperture`
    pixels; the 8 rows of bands keep their height. Returns an image (12 columns x the band area)"""
    s, sl = slices(width)
    h = max(1, 20 * s // 100)
    top = 175 - (120 - h)            # screen row of band row 0's top
    rows = 8 * h
    img = Image.new('RGB', (12 * aperture + 11 * 2, rows), (0, 0, 0))
    for i in range(12):
        x, w = sl[PERM[i]]           # slice index PERM[i] (0-based slice = output slot)
        for yy in range(rows):
            for dx in range(aperture):
                sx = x + dx * w // aperture
                if (sx, top + yy) in px:
                    img.putpixel((i * aperture + (i // 6) * 6 + (i % 6) * 0 + dx, yy), (255, 255, 255))
    return img


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('draw')
    d.add_argument('code')
    d.add_argument('--width', type=int, default=144)
    d.add_argument('--marks', default='32,62')
    d.add_argument('--out', required=True)
    v = sub.add_parser('lens')
    v.add_argument('screen')
    v.add_argument('--width', type=int, default=144)
    v.add_argument('--out', required=True)
    a = p.parse_args()
    if a.cmd == 'draw':
        marks = tuple(int(x, 16) for x in a.marks.split(','))
        image_of(draw(a.code.encode(), a.width, marks)).save(a.out)
    else:
        scr = open(a.screen, 'rb').read()
        lens_view(screen_pixels(scr), a.width).resize((300, 80), Image.NEAREST).save(a.out)
    print(a.out)


if __name__ == '__main__':
    sys.exit(main())

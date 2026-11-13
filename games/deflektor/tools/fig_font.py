#!/usr/bin/env python3
"""The text font Font $D200 (96 characters, 32-127) and the panel's LevelDigits $88B0 (0-9 and P), drawn from the
image (doc 08). Rows 2-6 of each glyph, the five the panel's printers and the COMPUTER line use, are marked.

    python3 tools/fig_font.py docs/img/hud/font.png
"""
import sys

from PIL import Image, ImageDraw

import figlib


def glyph(img, addr, scale, ink=(235, 235, 240), paper=(20, 20, 26), rows=None):
    im = Image.new('RGB', (8, 8), paper)
    px = im.load()
    for k in range(8):
        b = img[addr + k]
        for x in range(8):
            if b & (0x80 >> x):
                px[x, k] = ink if rows is None or k in rows else (110, 110, 120)
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def main():
    out = sys.argv[1]
    img = figlib.image()
    W = 1050
    o = Image.new('RGB', (W, 760), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'Font $D200: characters 32-127, glyph = $D200 + 8 x (code - 32)', 17, figlib.ACCENT)
    figlib.text(d, (10, 32), 'Bright rows 2-6: the rows the score, HIGH and COMPUTER-line printers copy; grey rows 0, 1, 7 '
                'only the full printers', 12, figlib.DIM)
    s = 5
    for i in range(96):
        r, c = divmod(i, 16)
        x = 22 + c * 63
        y = 60 + r * 74
        o.paste(glyph(img, 0xD200 + 8 * i, s, rows=range(2, 7)), (x, y))
        code = 32 + i
        ch = chr(code) if 33 <= code < 127 else ' '
        figlib.text(d, (x, y + 42), '$%02X %s' % (code, ch), 11, figlib.DIM)
    y0 = 60 + 6 * 74 + 20
    figlib.text(d, (10, y0), 'LevelDigits $88B0: the panel\'s LEVEL digits 0-9 and P (8 x 8, drawn from line 4 of row 20)',
                15, figlib.ACCENT)
    for i in range(11):
        x = 22 + i * 63
        o.paste(glyph(img, 0x88B0 + 8 * i, s, ink=(255, 255, 255)), (x, y0 + 30))
        figlib.text(d, (x, y0 + 72), '%s' % ('P' if i == 10 else i), 12, figlib.DIM)
    figlib.text(d, (10, y0 + 100), "In the font: ',' a small ring, '.' a small diamond, '@' the copyright sign; $61-$7A with "
                "'(' and ')' are the 30 pieces of the DEFLEKTOR logo.", 12, figlib.DIM)
    o = o.crop((0, 0, W, y0 + 130))
    o.save(out)


if __name__ == '__main__':
    main()

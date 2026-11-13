#!/usr/bin/env python3
"""The renderer's tables drawn from the image (doc 06).

    python3 tools/fig_render.py cells OUT    # cell codes to CellTable's four characters, their glyphs and colours
    python3 tools/fig_render.py beam OUT     # BeamGlyphBytes $8000: the four glyphs round a vertex, 16 directions

cells: for a set of cell codes, the code, CellTable $8200 + 4 x code (the four characters), each character from
CellGraphics $D700 + 8 x character in the colour CellColours $DF00 + character, and the cell as DrawMarkedChars
draws it.

beam: for each direction 0-15 the four bytes at $8000 + 4 x direction (set 0) as the four characters round a vertex
(up-left, up-right, down-left, down-right), each glyph BeamGlyphs $D500 + 8 x (byte AND $3F) tinted by the pass that
draws it (bits 7-6: 00 incoming, 01 outgoing, 10 corner); then the 39 glyphs.
"""
import sys

from PIL import Image, ImageDraw

import figlib

CELLS = [(0x00, 'empty'), (0x06, 'mirror 6'), (0x02, 'mirror 2'), (0x11, 'cyan polariser'),
         (0x19, 'yellow polar.'), (0x21 + 4, 'absorbing wall'), (0x30 + 9, 'reflecting wall'),
         (0x40, 'cell'), (0x41, 'mine'), (0x42, 'prism'), (0x47, 'laser'), (0x4B, 'receiver'),
         (0x50, 'fibre end'), (0x58, 'explosion 1')]
PASS = {0: ((255, 90, 90), 'incoming pass BeamInChar $9278'), 1: ((90, 220, 120), 'outgoing pass BeamOutChar $94FD'),
        2: ((90, 150, 255), 'corner pass BeamCornerChar $9440')}


def glyph(img, base, n, ink, paper=(20, 20, 26), scale=6):
    im = Image.new('RGB', (8, 8), paper)
    px = im.load()
    for k in range(8):
        b = img[base + 8 * n + k]
        for x in range(8):
            if b & (0x80 >> x):
                px[x, k] = ink
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def cells(out):
    img = figlib.image()
    W = 1050
    rowh = 92
    o = Image.new('RGB', (W, 80 + rowh * len(CELLS) // 2 + 60), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'A cell code to the screen: CellTable $8200, CellGraphics $D700, CellColours $DF00', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 34), 'Each row: the code, its four characters (top left, top right, bottom left, bottom right)'
                ' with their colours, the cell as drawn', 13, figlib.DIM)
    for i, (code, name) in enumerate(CELLS):
        col, r = divmod(i, (len(CELLS) + 1) // 2)
        x0 = 10 + col * 525
        y = 64 + r * rowh
        t = 0x8200 + 4 * code
        chars = list(img[t:t + 4])
        figlib.text(d, (x0, y + 4), '$%02X' % code, 16, figlib.FG)
        figlib.text(d, (x0, y + 26), name, 12, figlib.DIM)
        for k, ch in enumerate(chars):
            x = x0 + 120 + k * 64
            o.paste(figlib.char_image(img, ch, 6), (x, y))
            figlib.text(d, (x, y + 50), '$%02X' % ch, 12, figlib.FG)
            figlib.text(d, (x, y + 66), 'a $%02X' % img[0xDF00 + ch], 11, figlib.DIM)
        o.paste(figlib.cell_image(img, code, 3), (x0 + 120 + 4 * 64 + 20, y))
    figlib.text(d, (10, o.height - 30), 'Drawn from the image: the bytes of $8200, $D700 and $DF00 as DrawMarkedChars '
                '$8A09 reads them ("a" = the attribute)', 12, figlib.DIM)
    o.save(out)


def beam(out):
    img = figlib.image()
    W = 1050
    o = Image.new('RGB', (W, 700), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'BeamGlyphBytes $8000: the beam round a vertex for each of the 16 directions', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 34), 'Four characters round the vertex (the cross); glyphs tinted by the pass that draws '
                'them; 0 east, 4 south, 8 west, 12 north', 13, figlib.DIM)
    s = 5
    cw = 16 * s
    for dn in range(16):
        r, c = divmod(dn, 8)
        x = 18 + c * 128
        y = 64 + r * 150
        for k in range(4):
            b = img[0x8000 + 4 * dn + k]
            ink = PASS.get(b >> 6, ((200, 200, 200), ''))[0]
            o.paste(glyph(img, 0xD500, b & 0x3F, ink, scale=s), (x + (k & 1) * 8 * s, y + (k >> 1) * 8 * s))
        d.line([x + cw // 2, y - 3, x + cw // 2, y + cw + 3], fill=(90, 90, 100))
        d.line([x - 3, y + cw // 2, x + cw + 3, y + cw // 2], fill=(90, 90, 100))
        bs = ' '.join('%02X' % img[0x8000 + 4 * dn + k] for k in range(4))
        figlib.text(d, (x, y + cw + 6), 'dir %d' % dn, 13, figlib.FG)
        figlib.text(d, (x, y + cw + 24), bs, 11, figlib.DIM)
    y = 370
    for k, (col, lab) in PASS.items():
        d.rectangle([20 + k * 340, y, 34 + k * 340, y + 14], fill=col)
        figlib.text(d, (40 + k * 340, y - 1), lab, 12, figlib.FG)
    figlib.text(d, (10, 400), 'The 39 glyphs of BeamGlyphs $D500 (glyph n at $D500 + 8n)', 15, figlib.ACCENT)
    for n in range(39):
        r, c = divmod(n, 20)
        x = 18 + c * 51
        y = 430 + r * 80
        o.paste(glyph(img, 0xD500, n, (255, 85, 255), scale=5), (x, y))
        figlib.text(d, (x, y + 44), '%d' % n, 12, figlib.DIM)
    figlib.text(d, (10, 600), 'Byte bits 7-6: 00 incoming, 01 outgoing, 10 corner; bits 5-0: the glyph. '
                'Set 1 ($8040, the flashing beam) is not shown.', 12, figlib.DIM)
    o = o.crop((0, 0, W, 630))
    o.save(out)


if __name__ == '__main__':
    {'cells': cells, 'beam': beam}[sys.argv[1]](sys.argv[2])

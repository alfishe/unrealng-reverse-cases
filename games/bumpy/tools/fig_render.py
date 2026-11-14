#!/usr/bin/env python3
"""Doc 06's figures of the screen layout and the CPC-to-Spectrum conversion (no emulator):

    python3 tools/fig_render.py layout     docs/img/render/layout.png
    python3 tools/fig_render.py nibbles    docs/img/render/nibbles.png
    python3 tools/fig_render.py all

layout: a real frame (docs/img/play/l83-000100-play.png, rec/l83 frame 100) with the places the code draws at laid
over it: the 36 cell addresses CellAddresses $E131 (the platform's line), the 36 wall addresses WallAddresses $E179,
the ball's rest box (cell + $2F62), the HUD row and the side panels. Every CPC address is converted the way
ScreenAddrToLine $C71F and SpectrumLines $B52D do: line = (row x 8 + line in row) - 7, x = CPC byte column x 4.
nibbles: the round ball $67E8 (4 CPC bytes x 10 lines) byte by byte: the low nibbles DrawSprite $E318 and XorSprite
$E3EE keep, the high nibbles XorBricks $E4C4 keeps, the Spectrum bytes they make, and the CPC mode 1 picture both
planes make together.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CASE))
sys.path.insert(0, os.path.join(ROOT, 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'render')
BASE = 0x61A8
BIN = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()


def peek(a, n=1):
    return BIN[a - BASE:a - BASE + n]


def word(a):
    b = peek(a, 2)
    return b[0] | b[1] << 8


def cpc(addr):
    """CPC screen address -> (Spectrum line, x in pixels, CPC byte column)"""
    off = addr - 0xC000
    scan, rem = off // 0x800, off % 0x800
    row, col = rem // 80, rem % 80
    return row * 8 + scan - 7, col * 4, col


def layout():
    S = 2
    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'l83-000100-play.png')).convert('RGB')
    shot = shot.resize((256 * S, 192 * S), Image.NEAREST)
    W, H = 1050, 192 * S + 120
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    font, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    d.text((10, 8), 'Where the code draws: 36 cell addresses, 36 wall addresses, the ball, the HUD and the panels',
           fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'over rec/l83 frame 100 (level 83); CPC addresses converted as ScreenAddrToLine $C71F and '
           'SpectrumLines $B52D do', fill=kitlib.DIM, font=small)
    X0, Y0 = 10, 60
    im.paste(shot, (X0, Y0))
    ov = Image.new('RGBA', im.size, (0, 0, 0, 0))
    o = ImageDraw.Draw(ov)
    for c in range(36):
        line, x, _ = cpc(word(0xE131 + 2 * c))
        # the platform's line and the cell's 40 x 32 box above it
        o.rectangle((X0 + x * S, Y0 + (line - 26) * S, X0 + (x + 40) * S - 1, Y0 + (line + 6) * S - 1),
                    outline=(80, 200, 255, 200))
        o.line((X0 + x * S, Y0 + line * S, X0 + (x + 40) * S, Y0 + line * S), fill=(80, 200, 255, 255), width=2)
        o.text((X0 + x * S + 3, Y0 + (line - 24) * S), str(c), fill=(80, 200, 255, 255), font=small)
        wl, wx, _ = cpc(word(0xE179 + 2 * c))
        if c % 6 != 5:
            o.rectangle((X0 + wx * S, Y0 + max(wl, 0) * S, X0 + (wx + 8) * S - 1, Y0 + (wl + 24) * S - 1),
                        outline=(240, 120, 240, 255))
    bl, bx, _ = cpc(word(0xE131 + 2 * 14) + 0x2F62)
    o.rectangle((X0 + bx * S, Y0 + bl * S, X0 + (bx + 16) * S - 1, Y0 + (bl + 10) * S - 1), outline=(255, 230, 60, 255),
                width=2)
    o.rectangle((X0, Y0, X0 + 256 * S - 1, Y0 + 8 * S - 1), outline=(120, 255, 120, 255), width=2)
    for col in (0, 30):
        o.rectangle((X0 + col * 8 * S, Y0, X0 + (col + 1) * 8 * S - 1, Y0 + 192 * S - 1), outline=(255, 160, 60, 255),
                    width=2)
    im.paste(Image.alpha_composite(im.convert('RGBA'), ov).convert('RGB'))
    tx = X0 + 256 * S + 16
    notes = [
        ((80, 200, 255), 'cell c: CellAddresses $E131 + 2c'),
        (None, '  the platform line, 26 + 32 x row'),
        (None, '  x = 8 + 40 x column (10 CPC bytes)'),
        ((240, 120, 240), 'wall c: WallAddresses $E179 + 2c'),
        (None, '  8 px wide, 24 lines, at x = 40 + 40 x col'),
        ((255, 230, 60), 'the ball at rest on cell 14:'),
        (None, '  cell + $2F62: 10 lines over the platform'),
        ((120, 255, 120), 'the HUD: character row 0, drawn'),
        (None, '  every pass by DrawHud $E58B'),
        ((255, 160, 60), 'the side panels: columns 0 and 30'),
        (None, '  DrawSides $B488, yellow attributes'),
        (None, ''),
        (kitlib.TEXT, 'A CPC address $C000 + s x $800 + r x 80 + b'),
        (kitlib.TEXT, 'is Spectrum line 8r + s - 7, x = 4b.'),
        (kitlib.TEXT, 'CPC lines 0-6 and 199-206 go to the'),
        (kitlib.TEXT, 'scratch lines at $FCE0: drawn, never seen.'),
    ]
    y = Y0
    for col, t in notes:
        if col and col not in (kitlib.TEXT,):
            d.rectangle((tx, y + 3, tx + 10, y + 13), fill=col)
            d.text((tx + 16, y), t, fill=kitlib.TEXT, font=small)
        else:
            d.text((tx, y), t, fill=kitlib.DIM if col is None else col, font=small)
        y += 19
    d.text((10, Y0 + 192 * S + 10), 'Rows 0-5 of cells put their platforms on lines 26, 58, 90, 122, 154 and 186; a '
           'cell is 40 x 32 pixels; the board is 232 x 192 (x 8-239).', fill=kitlib.DIM, font=small)
    d.text((10, Y0 + 192 * S + 30), 'The top row\'s walls and objects share character row 0 with the HUD; a ball '
           'bouncing on the top row rises into the scratch lines.', fill=kitlib.DIM, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'layout.png')
    im.save(path)
    print('layout:', os.path.relpath(path, CASE))


def nibbles():
    rows = [peek(0x67E8 + 4 * r, 4) for r in range(10)]
    W, H = 1050, 560
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    font, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    d.text((10, 8), 'One CPC picture, two bit planes: the Spectrum shows the low nibbles (sprites) or the high ones '
           '(bricks)', fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'the round ball $67E8, 4 CPC bytes x 10 lines, as DrawSprite $E318 / XorSprite $E3EE and '
           'XorBricks $E4C4 pack it', fill=kitlib.DIM, font=small)
    y0 = 70
    hdr = ['CPC bytes', 'low nibbles', 'Spectrum (low)', 'high nibbles', 'Spectrum (high)']
    xs = [10, 160, 270, 400, 510]
    for x, h in zip(xs, hdr):
        d.text((x, y0 - 20), h, fill=kitlib.TEXT, font=small)
    for r, b in enumerate(rows):
        y = y0 + r * 22
        d.text((xs[0], y), ' '.join('%02X' % v for v in b), fill=kitlib.TEXT, font=small)
        d.text((xs[1], y), ' '.join('%X' % (v & 15) for v in b), fill=(90, 220, 255), font=small)
        lo = [(b[0] & 15) << 4 | (b[1] & 15), (b[2] & 15) << 4 | (b[3] & 15)]
        hi = [(b[0] & 0xF0) | b[1] >> 4, (b[2] & 0xF0) | b[3] >> 4]
        d.text((xs[2], y), ' '.join('%02X' % v for v in lo), fill=(90, 220, 255), font=small)
        d.text((xs[3], y), ' '.join('%X' % (v >> 4) for v in b), fill=(255, 170, 80), font=small)
        d.text((xs[4], y), ' '.join('%02X' % v for v in hi), fill=(255, 170, 80), font=small)
    # pictures
    def grid(x, y, bits_rows, colour, title, cell=14):
        d.text((x, y - 20), title, fill=kitlib.TEXT, font=small)
        for r, bits in enumerate(bits_rows):
            for i, bit in enumerate(bits):
                c = colour[bit] if isinstance(colour, dict) else (colour if bit else (30, 30, 42))
                d.rectangle((x + i * cell, y + r * cell, x + (i + 1) * cell - 2, y + (r + 1) * cell - 2), fill=c)
    lo_bits = [[(v >> (3 - i)) & 1 for v in b for i in range(4)] for b in rows]
    hi_bits = [[(v >> (7 - i)) & 1 for v in b for i in range(4)] for b in rows]
    mode1 = [[h << 1 | l for h, l in zip(hb, lb)] for hb, lb in zip(hi_bits, lo_bits)]
    gy = y0 + 10 * 22 + 90
    grid(10, gy, lo_bits, (90, 220, 255), 'what the Spectrum shows (low)')
    grid(260, gy, hi_bits, (255, 170, 80), 'the other plane (high)')
    pens = {0: (30, 30, 42), 1: (90, 220, 255), 2: (255, 170, 80), 3: (255, 255, 255)}
    grid(510, gy, mode1, pens, 'CPC mode 1: both planes, 4 pens')
    tx = 680
    lines = [
        'A CPC mode 1 byte holds 4 pixels of 2 bits:',
        'pixel i is bit 7-i (plane 0, the high nibble)',
        'and bit 3-i (plane 1, the low nibble).',
        '',
        'DrawSprite and XorSprite build a Spectrum byte',
        'from two CPC bytes: (b0 << 4) OR (b1 AND $0F).',
        'XorBricks: (b0 AND $F0) OR (b1 >> 4).',
        '',
        'One CPC byte is 4 Spectrum pixels, so the CPC',
        'byte column b is Spectrum x = 4b, and the',
        'Spectrum byte column is b / 2. An odd b starts',
        'with a lone low nibble (DrawSpriteLoop3 $E38B).',
        '',
        'Worked: line 3, CPC 10 2B 4D 80; low nibbles',
        '0 B D 0 give $0B $D0 = ....X.XX XX.X....',
    ]
    for i, t in enumerate(lines):
        d.text((tx, y0 - 20 + i * 19), t, fill=kitlib.TEXT if t else kitlib.DIM, font=small)
    path = os.path.join(OUT, 'nibbles.png')
    os.makedirs(OUT, exist_ok=True)
    im.save(path)
    print('nibbles:', os.path.relpath(path, CASE))


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if what in ('layout', 'all'):
        layout()
    if what in ('nibbles', 'all'):
        nibbles()


if __name__ == '__main__':
    main()

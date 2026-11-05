#!/usr/bin/env python3
"""The text figures and tables of docs/08 (and 01, 05): the fonts as sheets, the game's strings decoded.

    python3 tools/fig_text.py font      docs/img/text/game-font.png   (the game font, $C500, from the play image)
    python3 tools/fig_text.py helpfont  docs/img/text/help-fonts.png  (the help program's two fonts, $B19D / $B49D)
    python3 tools/fig_text.py strings   every PrintInline string of the game image, decoded (a Markdown table)

The game image is work/images/scl-play-cpu.bin (the Z80 view in play, stage 1's dump of work/stage1/s2 frame 11500:
bank 5 at $4000, bank 2 at $8000, bank 0 at $C000); the help program's is build/bootmenu/d05-6060.bin (the boot
program block as HRUM leaves it at $6060, built from src/bootmenu).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
from game_text import GLYPHS  # noqa: E402

PLAY = os.path.join(CASE, 'work', 'images', 'scl-play-cpu.bin')
BOOT = os.path.join(CASE, 'build', 'bootmenu', 'd05-6060.bin')  # built from src/bootmenu (bit-exact)
OUT = os.path.join(CASE, 'docs', 'img', 'text')
BG, FG, DIMC = K.BACKGROUND, K.TEXT, K.DIM
LOOK = set('ABCEHKMOPTXY')
C_LOOK = (110, 200, 120)     # a Russian letter drawn on the Latin letter it looks like
C_MOVED = (240, 150, 60)     # a Russian letter on a code whose Latin letter it does not resemble
C_SAME = (120, 120, 135)     # digits, punctuation: the ASCII glyph


def text(d, xy, s, size=12, fill=FG, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def glyph_image(rows, scale, ink=(235, 235, 235), paper=(30, 30, 40), width=8):
    im = Image.new('RGB', (width * scale, len(rows) * scale), paper)
    px = ImageDraw.Draw(im)
    for y, b in enumerate(rows):
        for x in range(width):
            if b >> (7 - x) & 1:
                px.rectangle([x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1], fill=ink)
    return im


def cmd_font():
    img = open(PLAY, 'rb').read()
    scale, cw, ch = 4, 104, 84
    cols = 8
    top = 70
    sheet = Image.new('RGB', (cols * cw + 20, top + 8 * ch + 60), BG)
    d = ImageDraw.Draw(sheet)
    text(d, (10, 8), 'The game font at $C500: 64 glyphs, codes $20-$5F; 30 of them are Russian letters', 17)
    text(d, (10, 32), 'Each cell: the glyph at 4x, the code, the letter it draws (and the key / ASCII character of the code)',
         12, DIMC)
    counts = {C_LOOK: 0, C_MOVED: 0, C_SAME: 0}
    for i in range(64):
        code = 0x20 + i
        rows = img[0xC400 + 8 * code:0xC400 + 8 * code + 8]
        x0, y0 = 10 + (i % cols) * cw, top + (i // cols) * ch
        ascii_ch = chr(code)
        letter = GLYPHS.get(code)
        if letter is None or code == 0x40:
            colour = C_SAME
            shown = '©' if code == 0x40 else ascii_ch
        elif ascii_ch in LOOK:
            colour = C_LOOK
            shown = letter
        else:
            colour = C_MOVED
            shown = letter
        if code == 0x40:
            colour = C_MOVED
        counts[colour] += 1
        sheet.paste(glyph_image(rows, scale), (x0, y0))
        d.rectangle([x0 - 1, y0 - 1, x0 + 32, y0 + 32], outline=colour)
        text(d, (x0 + 40, y0), f'${code:02X}', 12, DIMC)
        text(d, (x0 + 40, y0 + 14), shown, 18, colour)
        if code == 0x33:
            text(d, (x0 + 58, y0 + 14), '/3', 14, colour)
        text(d, (x0 + 40, y0 + 38), f"'{ascii_ch}'", 12, DIMC)
    y = top + 8 * ch + 8
    for (colour, label), x in zip(((C_LOOK, 'Russian letter on the Latin letter of the same shape (A = А, P = Р ...)'),
                                   (C_MOVED, 'Russian letter on a code of another shape (N = Ш, Q = Ы, [ = Б ...); © on @'),
                                   (C_SAME, 'digit or sign, as in ASCII')), (10, 10, 10)):
        d.rectangle([x, y + 2, x + 12, y + 14], fill=colour)
        text(d, (x + 20, y), f'{label}: {counts[colour]}', 13, colour)
        y += 17
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'game-font.png')
    sheet.save(path)
    print(path, counts)


def cmd_helpfont():
    img = open(BOOT, 'rb').read()
    scale, cw, ch, cols = 4, 52, 56, 16
    top = 64
    rows_n = 6
    sheet = Image.new('RGB', (cols * cw + 20, top + 2 * (rows_n * ch + 40) + 20), BG)
    d = ImageDraw.Draw(sheet)
    text(d, (10, 8), "The help's two fonts: 96 glyphs each, 4 pixels wide (both nibbles of a byte)", 17)
    text(d, (10, 32), 'byte 1 in a page selects font 1, byte 2 font 2 (the operand at $B0A1); '
         'label: the byte as ASCII, then what the glyph draws', 12, DIMC)
    names = {}
    import help_text
    for c in range(0x20, 0x80):
        names[c] = help_text.decode(chr(c))
    y = top
    for base, title in ((0xB09D, 'font 1, $B19D-$B49C: Latin (the credits pages, the English words)'),
                        (0xB39D, 'font 2, $B49D-$B79C: Cyrillic (the Russian pages; a = а, q = я, w = в, [ = ш ...)')):
        text(d, (10, y), title, 14, C_MOVED if base == 0xB39D else C_LOOK)
        y += 24
        for i in range(96):
            code = 0x20 + i
            a = base + 8 * code - 0x6060
            rows = [b >> 4 << 4 for b in img[a:a + 8]]
            x0, y0 = 10 + (i % cols) * cw, y + (i // cols) * ch
            sheet.paste(glyph_image(rows, scale, width=4), (x0, y0))
            label = chr(code) if base == 0xB09D else f'{chr(code)} {names[code]}'
            text(d, (x0 + 20, y0 + 2), label if code != 0x20 else 'sp', 12, FG)
            text(d, (x0, y0 + 34), f'{code:02X}', 10, DIMC)
        y += rows_n * ch + 16
    path = os.path.join(OUT, 'help-fonts.png')
    os.makedirs(OUT, exist_ok=True)
    sheet.save(path)
    print(path)


def decode_string(img, a):
    out = []
    while True:
        b = img[a]
        if b == 0:
            return ''.join(out), a + 1
        if b == 1:
            out.append(f'⟨{img[a + 1]},{img[a + 2]}⟩')
            a += 3
        elif b == 2:
            out.append(f'⟨a ${img[a + 1]:02X}⟩')
            a += 2
        elif b == 3:
            out.append(' / ')
            a += 1
        elif b == 4:
            out.append(f'⟨s ${img[a + 1]:02X}⟩')
            a += 2
        else:
            out.append(GLYPHS.get(b, chr(b)) if b != 0x40 else '©')
            a += 1


def cmd_strings():
    img = open(PLAY, 'rb').read()
    for a in range(0x6000, 0xFFF0):
        op = img[a:a + 3]
        if op in (b'\xCD\x2D\xD4', b'\xC3\x2D\xD4', b'\xCD\x0C\xC4'):
            s, _ = decode_string(img, a + 3)
            print(f'| `${a + 3:04X}` | {s} |')


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    {'font': cmd_font, 'helpfont': cmd_helpfont, 'strings': cmd_strings}[cmd]()


if __name__ == '__main__':
    main()

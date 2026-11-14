#!/usr/bin/env python3
"""Doc 08: the font and the HUD row.

    python3 tools/fig_text.py font docs/img/text/font.png
    python3 tools/fig_text.py hud docs/img/text/c1-30700.png docs/img/text/hud.png

font: the 43 glyphs of Font `$9E95` (8 bytes each, read from build/game.bin), each with its glyph number, the text byte
PrintText `$AA8D` turns into it (glyph + `$37`) and what the byte stands for in src/res/texts.
hud: char row 1 of a play screen (a 2x screenshot), enlarged, with the cells each HUD routine owns, its screen address,
the variable it shows and the glyph it draws.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 75)
FONT = 0x9E95
NAMES = [str(i) for i in range(10)] + [chr(65 + i) for i in range(26)] + \
    ['bullet', 'stick', 'face', ',', '.', '?', 'space']


def glyph(img, g):
    return [img[FONT + 8 * g + r - 0x5B00] for r in range(8)]


def cmd_font(png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    W, cols, cw, ch, s = 1050, 11, 92, 118, 6
    rows = (43 + cols - 1) // cols
    H = 100 + rows * ch + 90
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The font: 43 glyphs of 8 x 8 at Font $9E95, as PrintText and the HUD use them', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), 'tools/fig_text.py font, from build/game.bin. Under each glyph: its number and the text byte '
           'that prints it (glyph + $37).', fill=DIM, font=K.font(14))
    for g in range(43):
        x, y = 12 + (g % cols) * (cw + 3), 84 + (g // cols) * ch
        hud = 36 <= g <= 38
        d.rectangle((x, y, x + cw - 4, y + ch - 8), outline=(250, 210, 80) if hud else GRID, width=2 if hud else 1)
        gx, gy = x + (cw - 4 - 8 * s) // 2, y + 6
        d.rectangle((gx, gy, gx + 8 * s - 1, gy + 8 * s - 1), fill=(235, 235, 235))
        for r, b in enumerate(glyph(img, g)):
            for bit in range(8):
                if b >> (7 - bit) & 1:
                    d.rectangle((gx + bit * s, gy + r * s, gx + bit * s + s - 1, gy + r * s + s - 1), fill=(15, 15, 20))
        d.text((x + 6, y + 8 * s + 12), f'{g}  {NAMES[g]}', fill=TEXT, font=K.font(13 if hud else 14))
        d.text((x + 6, y + 8 * s + 32), f'byte ${g + 0x37:02X}', fill=DIM, font=K.font(13))
        d.text((x + 6, y + 8 * s + 50), f'${FONT + 8 * g:04X}', fill=DIM, font=K.font(13))
    yy = 84 + rows * ch + 6
    d.text((12, yy), 'Yellow frames: the three HUD pictures, drawn by DrawCounter $AA0E with L = $24, $25, $26. '
           'A space ($20) prints', fill=DIM, font=K.font(14))
    d.text((12, yy + 20), 'SpaceGlyph $AAE1, not glyph 42. The digits are the bytes $37-$40, so the text "C 1989" is '
           'stored as "C 8@?@".', fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size)


def cmd_hud(shot, png):
    src = Image.open(shot).convert('RGB')
    k = src.size[0] // 256
    row = src.crop((0, 8 * k, 256 * k, 16 * k))
    s = 4
    row = row.resize((256 * s, 8 * s), Image.NEAREST)
    W, H = 1050, 360
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The HUD: char row 1 of the screen, four counters of six cells', fill=TEXT, font=K.font(22))
    d.text((12, 44), f'tools/fig_text.py hud {os.path.relpath(shot, CASE)}: recording c1, frame '
           f'{os.path.basename(shot)[3:-4]}, enlarged 4 times.', fill=DIM, font=K.font(14))
    ox, oy = 13, 110
    out.paste(row, (ox, oy))
    for c in range(33):
        d.line((ox + c * 8 * s, oy - 6, ox + c * 8 * s, oy), fill=GRID)
    for c in range(0, 32, 4):
        d.text((ox + c * 8 * s + 2, oy - 26), f'{c}', fill=DIM, font=K.font(12))
    parts = [(1, 'DrawScore', '$4021', 'Score $A9BE', 'digits 0-9', (200, 120, 230)),
             (9, 'DrawDynamite', '$4029', '$A976 (the bullets)', 'glyph 36 $24', (250, 210, 80)),
             (17, 'DrawBullets', '$4031', '$A967 (the sticks)', 'glyph 37 $25', (110, 150, 250)),
             (25, 'DrawLives', '$4039', 'Lives $A958', 'glyph 38 $26', (110, 220, 120))]
    for c, name, addr, var, gl, col in parts:
        x0, x1 = ox + c * 8 * s, ox + (c + 6) * 8 * s
        d.rectangle((x0, oy - 2, x1, oy + 8 * s + 2), outline=col, width=2)
        y = oy + 8 * s + 16
        for i, t in enumerate((name, f'cells {c}-{c + 5}, {addr}', var, gl)):
            d.text((x0, y + 20 * i), t, fill=col if i == 0 else TEXT if i == 2 else DIM, font=K.font(14 if i else 15))
    y = oy + 8 * s + 110
    d.text((12, y), 'Cells 0, 7-8, 15-16, 23-24 and 31 always belong to the play area. In a counter, the cells past '
           'the count', fill=DIM, font=K.font(14))
    d.text((12, y + 20), 'are given back to the map: DrawCounter sets their flag at $6C00 + cell and the map char\'s '
           'attribute, and the next', fill=DIM, font=K.font(14))
    d.text((12, y + 40), 'map draw puts the scenery there. The routine names and the variables at $A967 / $A976 are '
           'swapped in the source:', fill=DIM, font=K.font(14))
    d.text((12, y + 60), 'the code fires with $A976 and drops sticks with $A967 (section 8.3).', fill=DIM,
           font=K.font(14))
    out.save(png)
    print(png, out.size)


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == 'font':
        cmd_font(a[1])
    elif len(a) == 3 and a[0] == 'hud':
        cmd_hud(a[1], a[2])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The figures of doc 8 (HUD and text), drawn from build/game.bin and from screens of the recordings.

    python3 tools/fig_hud.py font --out docs/img/hud/font.png
    python3 tools/fig_hud.py panel --scr SCR --out docs/img/hud/panel.png
    python3 tools/fig_hud.py code --scr SCR --digits 8883898669979809 --out docs/img/hud/code.png
    python3 tools/fig_hud.py texts --out docs/img/hud/texts.png
    python3 tools/fig_hud.py icons --out docs/img/hud/icons.png
    python3 tools/fig_hud.py sweep --out docs/img/hud/sweep.png
    python3 tools/fig_hud.py combo --out docs/img/hud/combo.png

font: the 64 characters of Font $60E0 (codes 32-95), each with its code and what the game uses it for. panel: the
HUD's three character rows at 4x from a screen, each field boxed and labelled with its screen and memory address, its
format and the routine that updates it. code: the CODE panel from a screen, and the 16 places of CodeDigits $A88C
with the variable each one comes from. texts: REX 1's text records printed by the PrintText algorithm on blank screens,
one screen a group, each record at its own column, pixel line and attribute. icons: the HUD's pictures at
SpriteHudIcons $8C0A. sweep and combo: HudSweep's and KillFlashFade's attributes pass by pass, simulated from the code.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_controls as FC  # noqa: E402
K = FC.K
WIDTH = FC.WIDTH
FONT = 0x60E0

SPECIAL = {
    '#': 'bar', '(': 'box', ')': 'box', '*': 'box', '+': 'box', ',': 'box', '-': 'box', '.': 'box',
    '/': 'box', ';': 'box', '<': 'box', '=': 'box', '>': 'box', '?': 'box',
    ']': 'icon', '\\': 'icon', '^': 'icon', '_': 'icon', '@': 'icon', '"': 'icon', '$': 'icon', '%': 'icon',
    '&': 'icon', "'": 'icon',
}


def draw_char(pic, x, y, data, scale, fg=(235, 235, 235), bg=(0, 0, 0)):
    d = ImageDraw.Draw(pic)
    d.rectangle([x, y, x + 8 * scale - 1, y + 8 * scale - 1], fill=bg)
    for r in range(8):
        for b in range(8):
            if data[r] & (0x80 >> b):
                d.rectangle([x + b * scale, y + r * scale, x + (b + 1) * scale - 1, y + (r + 1) * scale - 1],
                            fill=fg)


def read_scr(path):
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = open(path, 'rb').read()[:6912]
    return mem


def cmd_font(args):
    mem = FC.image()
    sc, cw, ch = 4, 64, 72
    pic = Image.new('RGB', (WIDTH, 44 + 4 * ch + 70), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    fs = K.font(12)
    FC.title(d, 'Font $60E0: codes 32-95, 8 bytes each at $5FE0 + 8 x code (build/game.bin)')
    colours = {'bar': (255, 210, 70), 'box': (90, 150, 250), 'icon': (230, 90, 80)}
    for i in range(64):
        code = 32 + i
        x = 12 + (i % 16) * cw
        y = 44 + (i // 16) * ch
        ch_ = chr(code)
        kind = SPECIAL.get(ch_)
        col = colours.get(kind, (235, 235, 235))
        draw_char(pic, x, y + 16, mem[FONT + 8 * i:FONT + 8 * i + 8], sc, fg=col)
        d.text((x, y), f'{code:02X} {ch_}', fill=K.TEXT if not kind else col, font=fs)
    y = 44 + 4 * ch + 4
    d.text((12, y), 'white: letters, digits and : (printed as text)', fill=K.TEXT, font=fs)
    d.text((12, y + 18), 'yellow: # the HUD bar   blue: the frame pieces of PanelBox $CE7B (edges from Font + $40, '
           '$50, $60, $78, $D8, $E8)', fill=K.TEXT, font=fs)
    d.text((12, y + 36), 'red: the combo row\'s pictures, row 2 of the HUD: ] ^ _ @ " $ % & \' are "1"-"9" with a "0", '
           '\\ is "00": "]\\" prints 100', fill=K.TEXT, font=fs)
    pic.save(args.out)
    print(args.out)


FIELDS = [
    # (col0, col1, row0, row1, colour, label lines)
    (1, 10, 0, 1, (90, 150, 250), ['weapon icons, cols 1-10, rows 0-1',
                                   'ShowWeaponIcons $A212 (DrawCharBlock $D8C0, 2 x 16 each)',
                                   'WeaponIcon $A04F: lit or dark; attribute 1;',
                                   'PowerBar: 2 x 2 attr PowerLevel + 2 at PowerBarPtr $A015']),
    (12, 18, 0, 0, (255, 210, 70), ['score, cols 12-18: Score $A03E x 100',
                                    'ShowScore $99AB: ToDigits, PrintDigits, 5 digits, units at col 16',
                                    'cols 17-18 are the text\'s fixed "00"']),
    (20, 21, 0, 0, (80, 210, 120), ['shield, cols 20-21: ShieldEnergy $A04D',
                                    'ShowShield $99FA: 2 digits; attribute $5814/$5815 = E / 16 + 1']),
    (23, 23, 0, 0, (200, 110, 230), ['lives, col 23: Lives $A063, 1 digit', 'ShowLives $99BB']),
    (11, 23, 1, 1, (240, 140, 60), ["the sweep, row 1: cols 11-23 ($582B + SweepPos 0-12)",
                                    'HudSweep: attribute $46 / $06 / $04 at $582B + SweepPos',
                                    'SweepWidth $A067 narrows every 5 sweeps']),
    (25, 30, 0, 1, (230, 90, 80), ['bombs, cols 25-30, rows 0-1: Bombs $A06C',
                                   'ShowBombs $A1C9: 3 icons, $C0 full / $A0 empty; attribute 2']),
    (1, 30, 2, 2, (70, 210, 220), ['the combo row, row 2: "100 200 ... 900", attr fading to 0',
                                   'HitObject: KillFlashPtr $A039 = $5843, +3 a hit (HitObjectHard)',
                                   'KillFlashFade: each cell -1 a pass, 2 cells at the pointer $07']),
]


def cmd_panel(args):
    mem = read_scr(args.scr)
    scr = K.render_screen(mem)
    sc = 4
    hud = scr.crop((0, 0, 256, 24)).resize((256 * sc, 24 * sc), Image.NEAREST)
    pic = Image.new('RGB', (WIDTH, 760), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    fs = K.font(12)
    FC.title(d, f'The HUD: three character rows, each field with its address, format and updater '
                f'({os.path.basename(args.scr)})')
    x0, y0 = 13, 44
    pic.paste(hud, (x0, y0))
    for c in range(33):
        d.line([x0 + c * 8 * sc, y0 + 24 * sc, x0 + c * 8 * sc, y0 + 24 * sc + 6], fill=K.DIM)
    for c in range(0, 32, 2):
        d.text((x0 + c * 8 * sc + 2, y0 + 24 * sc + 6), str(c), fill=K.DIM, font=K.font(10))
    for r in range(3):
        d.text((x0 - 12, y0 + r * 32 + 10), str(r), fill=K.DIM, font=K.font(10))
    ly = y0 + 24 * sc + 30
    for i, (c0, c1, r0, r1, col, lines) in enumerate(FIELDS):
        bx0, bx1 = x0 + c0 * 8 * sc, x0 + (c1 + 1) * 8 * sc - 1
        by0, by1 = y0 + r0 * 8 * sc, y0 + (r1 + 1) * 8 * sc - 1
        d.rectangle([bx0 + i % 2, by0 + i % 2, bx1 - i % 2, by1 - i % 2], outline=col, width=2)
        col_x = 12 + (i % 2) * 520
        row_y = ly + (i // 2) * 80
        d.rectangle([col_x, row_y + 2, col_x + 10, row_y + 12], fill=col)
        for k, line in enumerate(lines):
            d.text((col_x + 18, row_y + k * 17), line, fill=K.TEXT if k == 0 else K.DIM, font=fs)
    pic = pic.crop((0, 0, WIDTH, ly + 4 * 80 + 4))
    pic.save(args.out)
    print(args.out)


PLACES = ['double fire', 'score 1000s', 'spray', 'lives', 'laser', 'score 100s', 'multiple', 'score 1s',
          'shield 1s', 'score 10s', 'bombs', 'shield 10s', 'score 10000s', 'sum 1s', 'sum 100s', 'sum 10s']


def cmd_code(args):
    mem = read_scr(args.scr)
    scr = K.render_screen(mem)
    sc = 3
    box = (8, 64, 248, 104)
    crop = scr.crop(box).resize(((box[2] - box[0]) * sc, (box[3] - box[1]) * sc), Image.NEAREST)
    pic = Image.new('RGB', (WIDTH, 520), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    fs, f = K.font(12), K.font(13)
    FC.title(d, f'The CODE panel and its 16 places, CodeDigits $A88C ({os.path.basename(args.scr)})')
    pic.paste(crop, (12, 44))
    y = 44 + crop.height + 16
    digits = args.digits
    cw = 63
    for i, name in enumerate(PLACES):
        x = 12 + i * cw
        col = (80, 210, 120) if i < 13 else (240, 200, 70)
        d.rectangle([x, y, x + cw - 4, y + 40], outline=col, width=2)
        d.text((x + 22, y + 8), digits[i], fill=K.TEXT, font=K.font(20))
        d.text((x + 2, y + 44), f'+{i}', fill=K.DIM, font=fs)
        words = name.split(' ')
        for k, w in enumerate(words):
            d.text((x + 2, y + 60 + k * 15), w, fill=col, font=K.font(11))
        if i < 13:
            d.text((x + 2, y + 92), f'= {9 - int(digits[i])}', fill=K.TEXT, font=fs)
    y += 118
    s = sum(int(c) for c in digits[:13])
    d.text((12, y), 'Green, places 0-12: each value v is written as the digit 9 - v (the line "= v" is the value it '
           'carries).', fill=K.TEXT, font=f)
    d.text((12, y + 20), f'Yellow, places 13-15: the sum of the 13 written digits, {s}, as hundreds at +14, tens at +15, '
           f'units at +13.', fill=K.TEXT, font=f)
    d.text((12, y + 40), 'Score is kept in hundreds: the five score places give Score $A03E; the HUD adds the two '
           'zeros.', fill=K.TEXT, font=f)
    pic = pic.crop((0, 0, WIDTH, y + 64))
    pic.save(args.out)
    print(args.out, 'sum', s)


GROUPS = [
    ('GameTexts $AAAE (3 records): the start of a game', [0xAAAE, 0xAAC3, 0xAAD6]),
    ('PressFireText $AB25 (2 records): under GameTexts', [0xAB25, 0xAB33]),
    ('GameOverText $AAED, HiScoreText $AAFA, HumansKilledText $AB0E', [0xAAED, 0xAAFA, 0xAB0E]),
    ('BonusTexts $AB41: SPEED UP (all 5 at the same place)', [0xAB41]),
    ('MenuTexts $DF05 (5 records)', [0xDF05, 0xDF11, 0xDF1D, 0xDF2B, 0xDF37]),
    ('DefineTexts $DF9F (6 records; the keys go at column 15)', [0xDF9F, 0xDFA9, 0xDFB1, 0xDFBB, 0xDFC5, 0xDFD0]),
    ('DoubleFire $ABA2: the weapon panel record', [0xABA2]),
    ('Laser $ABB3', [0xABB3]),
    ('Multiple $ABBE', [0xABBE]),
    ('Spray $ABCC', [0xABCC]),
    ('HudTexts $A24C (3 records)', [0xA24C, 0xA25C, 0xA26C]),
    ('CodeText $A884 (the 16 places blank)', [0xA884]),
]


def print_text(mem, a):
    """PrintText $A307: [attribute][column][pixel line] characters, 0 ends"""
    attr, col, line = mem[a], mem[a + 1], mem[a + 2]
    a += 3
    while mem[a]:
        c = mem[a]
        for r in range(8):
            y = line + r
            addr = 0x4000 | (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2
            mem[addr + col] = mem[0x5FE0 + 8 * c + r]
        if c != 0x20:
            mem[0x5800 + (line & 0xF8) * 4 + col] = attr
        col += 1
        a += 1


def cmd_texts(args):
    rom = FC.image()
    pic = Image.new('RGB', (WIDTH, 1400), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    FC.title(d, "REX 1's text records drawn by PrintText $A307's rule from build/game.bin, 2x")
    d.text((8, 30), 'Each strip is the full screen width (columns 0-31) and the lines the records cover; '
           'the label gives the lines.', fill=K.DIM, font=K.font(12))
    ys = [56, 56]
    for i, (name, recs) in enumerate(GROUPS):
        mem = bytearray(rom)
        mem[0x4000:0x5B00] = bytes(0x1B00)
        for a in recs:
            print_text(mem, a)
        lines = [mem[a + 2] for a in recs]
        top, bottom = max(0, min(lines) - 4), min(192, max(lines) + 12)
        scr = K.render_screen(mem).crop((0, top, 256, bottom))
        scr = scr.resize((512, 2 * (bottom - top)), Image.NEAREST)
        col = i % 2
        x, y = 8 + col * 522, ys[col]
        pic.paste(scr, (x, y))
        d.rectangle([x - 1, y - 1, x + 512, y + scr.height], outline=K.DIM)
        d.text((x, y + scr.height + 4), f'{name}; lines {min(lines)}-{max(lines) + 7}', fill=K.TEXT,
               font=K.font(11))
        ys[col] = y + scr.height + 26
    pic = pic.crop((0, 0, WIDTH, max(ys)))
    pic.save(args.out)
    print(args.out)

def zx(attr):
    bright = attr >> 6 & 1
    return K.ink_colour(attr & 7, bright), K.ink_colour(attr >> 3 & 7, bright)


def draw_block(pic, x, y, mem, addr, wbytes, lines, sc, attr):
    ink, paper = zx(attr)
    d = ImageDraw.Draw(pic)
    for r in range(lines):
        for b in range(wbytes):
            v = mem[addr + r * wbytes + b]
            for k in range(8):
                d.rectangle([x + (8 * b + k) * sc, y + r * sc, x + (8 * b + k + 1) * sc - 1, y + (r + 1) * sc - 1],
                            fill=ink if v & (0x80 >> k) else paper)


def cmd_icons(args):
    mem = FC.image()
    sc = 5
    pic = Image.new('RGB', (WIDTH, 300), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    FC.title(d, 'The HUD pictures, SpriteHudIcons $8C0A: 2 bytes x 16 lines each, drawn by DrawCharBlock $D8C0')
    items = [(0x8C0A + 32 * i, f'+{32 * i:02X}: weapon {i}', 0x03 if i == 0 else 0x01) for i in range(5)]
    items += [(0x8CAA, '+A0: dark weapon: empty bomb', 0x01), (0x8CCA, '+C0: a bomb', 0x02)]
    for i, (a, label, attr) in enumerate(items):
        x = 12 + i * 146
        draw_block(pic, x, 50, mem, a, 2, 16, sc, attr)
        d.text((x, 50 + 16 * sc + 8), f'${a:04X}', fill=K.TEXT, font=K.font(12))
        for k, w in enumerate(label.split(': ')):
            d.text((x, 50 + 16 * sc + 26 + 16 * k), w, fill=K.DIM, font=K.font(11))
    d.text((12, 230), 'Colours as in play: weapons blue (attribute 1), the active one in the power colour '
           '(PowerLevel 1 + 2 = 3), bombs red (2).', fill=K.TEXT, font=K.font(12))
    d.text((12, 250), 'Weapon i: $8C0A + 32 i if WeaponIcon[i] is set, else $8CAA. A row of BombIcons $A202: '
           '$C0 full, $A0 empty.', fill=K.TEXT, font=K.font(12))
    pic = pic.crop((0, 0, WIDTH, 276))
    pic.save(args.out)
    print(args.out)


def cmd_sweep(args):
    """HudSweep $A0C4 run pass by pass from ResetSweep: SweepPos 0, SweepDir 0, width 12, count 5"""
    attrs = [0x06] * 13
    pos, sdir, width, count = 0, 0, 12, 5
    rows = []
    for n in range(60):
        attrs[pos] = 0x46
        if pos + 1 < 13 and attrs[pos + 1] != 0x04:
            attrs[pos + 1] = 0x06
        if sdir == 0:
            pos += 1
            if pos == width:
                sdir = 1
        else:
            pos -= 1
            if pos == 0:
                sdir = 0
                count -= 1
                if count == 0:
                    count, width = 5, width - 1
                    attrs[width + 1] = 0x04
        rows.append(list(attrs))
    cw, rh = 30, 13
    pic = Image.new('RGB', (WIDTH, 60 + 30 * rh + 60), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    FC.title(d, 'HudSweep $A0C4: the attributes of row 1, columns 11-23, pass by pass (simulated from the code)')
    for half in range(2):
        x0 = 60 + half * 500
        for c in range(13):
            d.text((x0 + c * cw + 6, 36), str(11 + c), fill=K.DIM, font=K.font(10))
        for r in range(30):
            n = half * 30 + r
            d.text((x0 - 50, 54 + r * rh), f'pass {n + 1}', fill=K.DIM, font=K.font(10))
            for c in range(13):
                a = rows[n][c]
                col = {0x46: (255, 240, 60), 0x06: (150, 140, 20), 0x04: (40, 170, 60)}[a]
                d.rectangle([x0 + c * cw, 54 + r * rh, x0 + (c + 1) * cw - 2, 54 + (r + 1) * rh - 2], fill=col)
    y = 54 + 30 * rh + 10
    d.text((12, y), 'bright yellow $46: the sweep has passed (going right); dim yellow $06: cleared on the way back; '
           'green $04: a cell lost.', fill=K.TEXT, font=K.font(12))
    d.text((12, y + 20), 'Width 12: a sweep is 24 passes. After 5 sweeps (120 passes) the width is 11 and cell 23 '
           'turns green; at width 0 Rex dies.', fill=K.TEXT, font=K.font(12))
    pic.save(args.out)
    print(args.out)


def cmd_combo(args):
    """KillFlashFade $9992 after four hits on passes 1, 3, 5, 7, then a kill on pass 9 (the pointer to rest)"""
    row = [0] * 30
    ptr = None
    events = {1: 3, 3: 6, 5: 9, 7: 12, 9: None}
    rows = []
    for n in range(1, 21):
        if n in events:
            ptr = events[n]
        row = [v - 1 if v else 0 for v in row]
        if ptr is not None:
            row[ptr] = row[ptr + 1] = 7
        rows.append(list(row))
    mem = FC.image()
    sc = 2
    pic = Image.new('RGB', (WIDTH, 60 + 20 * 26 + 50), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    FC.title(d, 'KillFlashFade $9992: row 2 of the HUD after four hits (passes 1, 3, 5, 7) and the kill (pass 9)')
    text = mem[0xA26F:0xA26F + 27]
    for r, attrs in enumerate(rows):
        y = 44 + r * 26
        d.text((12, y + 6), f'pass {r + 1}', fill=K.DIM, font=K.font(10))
        for c in range(27):
            code = text[c]
            glyph = mem[0x5FE0 + 8 * code:0x5FE0 + 8 * code + 8]
            pic_c = Image.new('RGB', (8, 8))
            ink = K.ink_colour(attrs[c + 3] & 7, 0)
            for yy in range(8):
                for xx in range(8):
                    pic_c.putpixel((xx, yy), ink if glyph[yy] & (0x80 >> xx) else (0, 0, 0))
            pic.paste(pic_c.resize((24, 24), Image.NEAREST), (80 + c * 24, y))
    y = 44 + 20 * 26 + 6
    d.text((12, y), 'Each hit moves KillFlashPtr 3 columns on and makes its two cells 7 (white). Every pass takes 1 '
           'off each cell.', fill=K.TEXT, font=K.font(12))
    d.text((12, y + 18), 'The kill sets the pointer to $E9FF. Ink: 7 white, 6 yellow, 5 cyan, 4 green, 3 magenta, '
           '2 red, 1 blue, 0 black.', fill=K.TEXT, font=K.font(12))
    pic = pic.crop((0, 0, WIDTH, y + 40))
    pic.save(args.out)
    print(args.out)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('font')
    s.add_argument('--out', required=True)
    s = sub.add_parser('panel')
    s.add_argument('--scr', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('code')
    s.add_argument('--scr', required=True)
    s.add_argument('--digits', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('texts')
    s.add_argument('--out', required=True)
    for name in ('icons', 'sweep', 'combo'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    args = p.parse_args()
    {'font': cmd_font, 'panel': cmd_panel, 'code': cmd_code, 'texts': cmd_texts, 'icons': cmd_icons,
     'sweep': cmd_sweep, 'combo': cmd_combo}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())

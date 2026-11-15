#!/usr/bin/env python3
"""Figures of doc 08 (the HUD and the texts), drawn from the bytes alone (build/game.bin, build/level8.bin).

    python3 tools/fig_hud.py font OUT.png      the font at $7AF0: 61 glyphs, each with its character and code
    python3 tools/fig_hud.py texts OUT.png     the HUD's and the messages' strings as the font draws them
    python3 tools/fig_hud.py closing OUT.png   level 8's object 32: the closing text no recording shows

The printer (PrintText $C081): the character AND $7F, minus $20 (0, a space, becomes $3B); the glyph at
$7AE8 + 8 x that, 8 bytes, one per pixel line. A string ends after the byte with bit 7 set.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
GAME_BASE = 0x7000
FONT = 0x7AF0
GLYPH_BASE = 0x7AE8

# what the HUD and the menus use each special glyph for (doc 08, 8.2)
ROLES = {
    '!': 'holds =B', '"': 'holds EAM', '#': 'TM', '&': 'copyright', '$': 'shown as !', '%': 'a life',
    '(': 'No., part 1', ')': 'No., part 2', '*': 'No., part 3', '+': 'No., part 4',
    ':': 'meter left', ';': 'meter right', '<': 'meter empty', '=': 'dash', '>': 'meter half', '@': 'meter full',
    '[': 'blank', '\\': 'rub out', ']': 'end',
}


def game():
    d = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[GAME_BASE:GAME_BASE + len(d)] = d
    return mem


def glyph(mem, ch):
    k = (ch & 0x7F) - 0x20
    if k == 0:
        k = 0x3B
    a = GLYPH_BASE + 8 * k
    return mem[a:a + 8]


def put_glyph(px, x0, y0, rows, ink, paper=(0, 0, 0), double=False):
    for y in range(8):
        for x in range(8):
            c = ink if rows[y] & (0x80 >> x) else paper
            if double:
                px[x0 + x, y0 + 2 * y] = c
                px[x0 + x, y0 + 2 * y + 1] = c
            else:
                px[x0 + x, y0 + y] = c


def text_of(mem, a, limit=64):
    out = []
    for i in range(limit):
        b = mem[a + i]
        out.append(b)
        if b & 0x80:
            break
    return out


def render(mem, codes, ink, double=False):
    im = Image.new('RGB', (8 * len(codes), 16 if double else 8), (0, 0, 0))
    px = im.load()
    for i, c in enumerate(codes):
        put_glyph(px, 8 * i, 0, glyph(mem, c), ink, double=double)
    return im


def cmd_font(out):
    mem = game()
    s = 6
    cw, ch = 85, 100
    cols = 12
    pic = Image.new('RGB', (WIDTH, 70 + 6 * ch), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    big, f, small = K.font(16), K.font(14), K.font(12)
    d.text((12, 10), 'The font at $7AF0: 61 glyphs, characters "!" to "]" ($21-$5D), 8 x 8, one byte a pixel line',
           fill=K.TEXT, font=big)
    d.text((12, 34), 'A space ($20) prints glyph $3B ("[", blank). Yellow: a glyph the game uses for something '
           'else than its character.', fill=K.TEXT, font=small)
    for k in range(1, 62):
        code = 0x20 + k
        i = k - 1
        x0, y0 = 12 + (i % cols) * cw, 64 + (i // cols) * ch
        im = Image.new('RGB', (8, 8))
        put_glyph(im.load(), 0, 0, mem[GLYPH_BASE + 8 * k:GLYPH_BASE + 8 * k + 8], (230, 230, 230), (20, 20, 28))
        pic.paste(im.resize((8 * s, 8 * s), Image.NEAREST), (x0 + 4, y0))
        ch_ = chr(code)
        role = ROLES.get(ch_)
        d.text((x0 + 4, y0 + 8 * s + 4), f'{ch_}  {code:02X}', fill=(255, 220, 120) if role else K.TEXT, font=f)
        if role:
            d.text((x0 + 4, y0 + 8 * s + 22), role, fill=(150, 200, 255), font=K.font(11))
    pic.save(out)


def cmd_texts(out):
    mem = game()
    rows = [
        ('$7188 BeamLabel, $83F3 BeamHudText, $7AF6 Font+6 (row 20, normal)', [0x7188, 0x83F3, 0x7AF6], (0, 230, 230), False),
        ('$72DE BeamMeterEmpty, ten "<"', [0x72DE], (0, 230, 230), False),
        ('$71C9 ScoreText (row 21, column 1)', [0x71C9], (0, 230, 0), False),
        ('$718D LifeChar x 5, then $718E BlankChar (row 21, from column 30 leftwards)', [0x718D] * 5 + [0x718E], (230, 230, 230), False),
        ('$7180 HiScoreLabel, $7CE1 HiScoreTable+9 (row 23, column 8)', [0x7180, 0x7CE1], (230, 0, 230), False),
        ('$70AC PilotStandByText (row 22, double height)', [0x70AC], (230, 230, 230), True),
        ('$70BD MissionOverText (row 22, double height)', [0x70BD], (230, 230, 230), True),
        ('$C49A PausedText', [0xC49A], (230, 230, 230), True),
        ('$74E3 EnterNameText', [0x74E3], (230, 230, 230), True),
        ('$73A8 "()*+ " and $73B3 DigitChars "1": the start of a high-score line', [0x73A8, 0x73B3], (230, 230, 230), True),
    ]
    s = 3
    pic = Image.new('RGB', (WIDTH, 60 + len(rows) * 82), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    big, small = K.font(16), K.font(13)
    d.text((12, 10), 'The strings as PrintText draws them (bytes of build/game.bin, no emulator)', fill=K.TEXT, font=big)
    y = 44
    for label, addrs, ink, double in rows:
        codes = []
        for a in addrs:
            t = text_of(mem, a)
            codes += t
        im = render(mem, codes, ink, double)
        raw = ''.join(chr(c & 0x7F) for c in codes)
        d.text((12, y), f'{label}:  "{raw}"', fill=K.TEXT, font=small)
        im = im.resize((im.width * s, im.height * s), Image.NEAREST)
        if im.width > WIDTH - 24:
            im = im.resize((WIDTH - 24, im.height * (WIDTH - 24) // im.width), Image.NEAREST)
        pic.paste(im, (12, y + 20))
        y += 26 + im.height + 8
    pic = pic.crop((0, 0, WIDTH, y + 4))
    pic.save(out)


def cmd_closing(out):
    import objsheet as O
    lv = O.Body(8)
    table = lv.word(0xC4BA)
    e = table + (32 - 1) * 4
    w, h, a = lv.byte(e), lv.byte(e + 1), lv.word(e + 2)
    cl, end = O.cells(lv, a, w, h)
    im = O.draw(lv, w, h, cl, 'rows')
    s = 4
    pic = Image.new('RGB', (WIDTH, 80 + h * 8 * s + 40), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    big, small = K.font(16), K.font(13)
    d.text((12, 10), f'Level 8, object 32: {w} x {h} cells at ${a:04X}-${end - 1:04X}, drawn from build/level8.bin',
           fill=K.TEXT, font=big)
    d.text((12, 36), 'The closing text. Grey: empty cells ($36). The wave script ends level 8 before the kinds '
           'that would draw it.', fill=K.TEXT, font=small)
    big_im = im.resize((w * 8 * s, h * 8 * s), Image.NEAREST)
    pic.paste(big_im, ((WIDTH - big_im.width) // 2, 64))
    pic.save(out)


def main():
    cmd, out = sys.argv[1], sys.argv[2]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    {'font': cmd_font, 'texts': cmd_texts, 'closing': cmd_closing}[cmd](out)


if __name__ == '__main__':
    main()

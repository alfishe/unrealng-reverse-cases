#!/usr/bin/env python3
"""Doc 05's key map, from the game's own tables (no emulator):

  python3 tools/fig_controls.py

docs/img/controls/key-codes.png: the 40 keys in their places, each with the game's key code (row x 8 + bit, row 0 the
half-row $7FFE as ReadControls $B418 reads them, row 8 the Kempston byte), coloured by what the game does with it.
The three sets are read from the built image (build/game.bin at $61A8): KeyboardKeys $F092, KempstonKeys $F09A,
SinclairKeys $F0A2; the fixed codes are the operands of the TestKey calls (menu 0-4, S, D, R, the cheat's R SPACE V).
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'controls')
BASE = 0x61A8

# The half-rows in ReadControls' order: $7FFE first; bit 0 is the outermost key.
ROWS = [['SPACE', 'SYM', 'M', 'N', 'B'], ['ENTER', 'L', 'K', 'J', 'H'], ['P', 'O', 'I', 'U', 'Y'],
        ['0', '9', '8', '7', '6'], ['1', '2', '3', '4', '5'], ['Q', 'W', 'E', 'R', 'T'],
        ['A', 'S', 'D', 'F', 'G'], ['CAPS', 'Z', 'X', 'C', 'V']]
PHYS = [list('1234567890'), list('QWERTYUIOP'), list('ASDFGHJKL') + ['ENTER'],
        ['CAPS'] + list('ZXCVBNM') + ['SYM', 'SPACE']]
SLOTS = ['up', 'down', 'left', 'right', 'fire', 'fire 2', 'pause', 'quit']
FIXED = {0x18: 'menu go', 0x20: 'players', 0x21: 'keyboard', 0x22: 'Sinclair',
         0x23: 'Kempston', 0x31: 'lose life', 0x32: 'cheat RET', 0x2B: 'quit,cheat',
         0x3C: 'cheat', 0x00: 'cheat'}
COL = {'keyboard': (240, 200, 70), 'sinclair': (90, 200, 120), 'fixed': (110, 160, 250), 'cheat': (230, 90, 80),
       'none': (60, 60, 72)}


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def sets():
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    get = lambda a: list(img[a - BASE:a - BASE + 8])  # noqa: E731
    return {'keyboard': get(0xF092), 'kempston': get(0xF09A), 'sinclair': get(0xF0A2)}


def main():
    s = sets()
    code = {k: r * 8 + b for r, keys in enumerate(ROWS) for b, k in enumerate(keys)}
    role = {}
    for name in ('keyboard', 'sinclair'):
        for i, c in enumerate(s[name]):
            if c < 0x40:
                role.setdefault(c, []).append(f'{name[:3]} {SLOTS[i]}')
    W, KW, KH, G = 1050, 92, 74, 8
    im = Image.new('RGB', (W, 640), (14, 14, 20))
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'Bumpy: the key codes (row x 8 + bit) and what each key does', fill=(220, 220, 230),
           font=font(18))
    for r, keys in enumerate(PHYS):
        x0 = 14 + r * 22
        y = 48 + r * (KH + G)
        for k in keys:
            c = code[k]
            kind = ('cheat' if c in (0x3C, 0x32) else 'fixed' if c in FIXED and c not in role
                    else 'keyboard' if any(t.startswith('key') for t in role.get(c, []))
                    else 'sinclair' if c in role else 'fixed' if c in FIXED else 'none')
            w = KW + 20 if k in ('ENTER', 'SPACE', 'CAPS') else KW
            d.rounded_rectangle((x0, y, x0 + w - 4, y + KH), 6, fill=(30, 30, 40), outline=COL[kind], width=3)
            d.text((x0 + 6, y + 4), k, fill=(235, 235, 240), font=font(16))
            d.text((x0 + w - 44, y + 6), f'${c:02X}', fill=(160, 160, 175), font=font(13))
            lines = role.get(c, [])
            if c in FIXED:
                lines = ([lines[0]] if lines else []) + [FIXED[c]]
            for j, t in enumerate(lines[:2]):
                d.text((x0 + 6, y + 30 + j * 18), t, fill=COL[kind] if j == 0 or kind != 'keyboard' else COL['fixed'], font=font(13))
            x0 += w
    y = 48 + 4 * (KH + G) + 6
    d.text((14, y), 'Row 8, the Kempston byte (IN A,($DF), complemented): bit 0 right $40, bit 1 left $41, '
           'bit 2 down $42,', fill=(220, 220, 230), font=font(14))
    d.text((14, y + 20), 'bit 3 up $43, bit 4 fire $44. Kempston set: ' + ' '.join(f'${c:02X}' for c in s['kempston'])
           + '; Sinclair fire 2 = $44.', fill=(220, 220, 230), font=font(14))
    y += 54
    for i, (kind, text) in enumerate([('keyboard', 'keyboard set (menu 2): KeyboardKeys $F092'),
                                      ('sinclair', 'Sinclair set (menu 3): SinclairKeys $F0A2'),
                                      ('fixed', 'fixed codes: menu 0-4, S $31, R $2B'),
                                      ('cheat', 'cheats: V $3C (with R, SPACE), D $32 (cut off)')]):
        xx, yy = 14 + (i % 2) * 520, y + (i // 2) * 26
        d.rectangle((xx, yy + 3, xx + 16, yy + 19), outline=COL[kind], width=3)
        d.text((xx + 26, yy), text, fill=(220, 220, 230), font=font(14))
    d.text((14, y + 62), 'Slots in KeySlots $F084: up, down, left, right, fire, fire 2, pause, quit. '
           'fire 2 and quit are never read:', fill=(160, 160, 175), font=font(13))
    d.text((14, y + 80), 'MainLoop tests R as the constant $2B; TestFire $B455 reads slot 0 (up).',
           fill=(160, 160, 175), font=font(13))
    im = im.crop((0, 0, W, y + 104))
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, 'key-codes.png'))
    print('key-codes.png', im.size, s)


if __name__ == '__main__':
    main()

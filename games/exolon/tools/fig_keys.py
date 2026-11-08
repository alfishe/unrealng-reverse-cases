#!/usr/bin/env python3
"""Exolon doc 05 figure (copied from B/tools/fig_keys.py): the Spectrum keyboard with every key the game reads.

    python3 tools/fig_keys.py --out docs/img/controls/keys.png

The roles and their witnesses (docs/05-controls.md): ReadKeyboard $7AE9's image defaults (O left, P right, Q jump,
A duck, M fire); ReadInterface2 $7B22 (port $EFFE: 6 left, 7 right, 8 duck, 9 jump, 0 fire); MainMenu $6DA1 (1-5);
PauseKey $AD21 (3 alone); AbortKeys $9A19 (0 9 8 7 together); CheatWord $7090 (ZORBA as the five defined keys).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

ROWS = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
        ['CAPS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYM', 'SPACE']]
KEYS = (90, 200, 120)
SINCLAIR = (250, 150, 60)
MENU = (240, 200, 70)
PLAY = (230, 90, 90)
CHEAT = (200, 120, 230)
ROLES = {
    'O': [('left', KEYS), ('cheat O', CHEAT)], 'P': [('right', KEYS)], 'Q': [('jump', KEYS)],
    'A': [('duck', KEYS), ('cheat A', CHEAT)], 'M': [('fire', KEYS)],
    'Z': [('cheat Z', CHEAT)], 'R': [('cheat R', CHEAT)], 'B': [('cheat B', CHEAT)],
    '1': [('start game', MENU)], '2': [('define keys', MENU)], '3': [('keyboard', MENU), ('pause', PLAY)],
    '4': [('Interface 2', MENU)], '5': [('Kempston', MENU)],
    '6': [('if2 left', SINCLAIR)], '7': [('if2 right', SINCLAIR), ('abort', PLAY)],
    '8': [('if2 duck', SINCLAIR), ('abort', PLAY)], '9': [('if2 jump', SINCLAIR), ('abort', PLAY)],
    '0': [('if2 fire', SINCLAIR), ('abort', PLAY)],
}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', required=True)
    args = p.parse_args()
    W, kw, kh, gap = 900, 78, 58, 6
    im = Image.new('RGB', (W, 420), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fk = K.font(11), K.font(15), K.font(16)
    d.text((10, 8), 'The keys Exolon reads: five defined keys, Interface 2 on 6-0, the menu on 1-5, pause 3, abort 7-0',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'Kempston (port $1F) needs no key; menu 2 redefines the green keys (any five), '
                     'and five keys typed as Z O R B A toggle infinite lives', fill=K.DIM, font=f)
    top = 60
    for r, row in enumerate(ROWS):
        x = 14 + r * 18
        y = top + r * (kh + gap)
        for key in row:
            roles = ROLES.get(key, [])
            outline = roles[0][1] if roles else (60, 60, 75)
            d.rounded_rectangle((x, y, x + kw, y + kh), radius=6, fill=(34, 34, 44), outline=outline,
                                width=2 if roles else 1)
            d.text((x + 6, y + 3), key, fill=K.TEXT if roles else K.DIM, font=fk)
            for i, (text, colour) in enumerate(roles):
                d.text((x + 6, y + 24 + 15 * i), text, fill=colour, font=f)
            x += kw + gap
    y = top + 4 * (kh + gap) + 10
    legend = [(KEYS, 'the defined keys, image defaults (ReadKeyboard $7AE9)'),
              (SINCLAIR, 'Interface 2 stick, port $EFFE (ReadInterface2 $7B22)'),
              (MENU, 'the menu (MainMenu $6DA1)'),
              (PLAY, 'in play: 3 pauses ($AD21); 7 8 9 0 abort ($9A19)'),
              (CHEAT, 'define keys typed Z O R B A: the cheat ($7046)')]
    for i, (colour, text) in enumerate(legend):
        x = 14 + (i % 2) * 440
        yy = y + (i // 2) * 20
        d.rectangle((x, yy + 2, x + 14, yy + 12), fill=colour)
        d.text((x + 22, yy), text, fill=K.TEXT, font=K.font(12))
    im = im.crop((0, 0, W, y + 66))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

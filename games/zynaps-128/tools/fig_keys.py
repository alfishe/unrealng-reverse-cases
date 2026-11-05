#!/usr/bin/env python3
"""Doc 05 figure: the Spectrum keyboard with every key the game reads and what it does (copied from
../zynaps/tools/fig_keys.py, the 2 in 1's defaults).

    python3 tools/fig_keys.py --out docs/img/controls/keys.png

The roles and their witnesses (docs/05-controls.md): KeyTable $8188 defaults of the 2 in 1 (SPACE fire, Q up, A down,
O left, P right; src/game/controldata.asm); ReadControls $A6B6 (cursor 5-8 + 0, Sinclair 6-0, 9 selects Sinclair, 5 back to cursor); the menu
(1, 2, 3); CheckPauseAndEnd (4 pauses; in the pause fire resumes, Q aborts the game).
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
CURSOR = (90, 150, 250)
SINCLAIR = (250, 150, 60)
MENU = (240, 200, 70)
ROLES = {
    'SPACE': [('fire', KEYS)], 'Q': [('up', KEYS), ('pause: quit', MENU)], 'A': [('down', KEYS)],
    'O': [('left', KEYS)], 'P': [('right', KEYS)],
    '1': [('1 player', MENU)], '2': [('2 players', MENU)], '3': [('define keys', MENU)], '4': [('pause', MENU)],
    '5': [('cur left', CURSOR), ('-> cursor', SINCLAIR)], '6': [('cur down', CURSOR), ('sin left', SINCLAIR)],
    '7': [('cur up', CURSOR), ('sin right', SINCLAIR)], '8': [('cur right', CURSOR), ('sin down', SINCLAIR)],
    '9': [('sin up', SINCLAIR), ('-> Sinclair', SINCLAIR)], '0': [('cur fire', CURSOR), ('sin fire', SINCLAIR)],
}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', required=True)
    args = p.parse_args()
    W, kw, kh, gap = 900, 78, 58, 6
    im = Image.new('RGB', (W, 420), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fk = K.font(11), K.font(15), K.font(16)
    d.text((10, 8), 'The keys Zynaps reads: five defined keys (defaults shown), two joysticks on 5-0, the menu, pause',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'Kempston ($1F) instead of 5-0 when play starts on Kempston fire; with K-MOUSE a click starts '
                     'it and the mouse replaces the Kempston', fill=K.DIM, font=f)
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
    legend = [(KEYS, 'the defined keys (KeyTable $8188, defaults)'), (CURSOR, 'cursor joystick: 5 6 7 8, 0 fire'),
              (SINCLAIR, 'Sinclair joystick: 6 7 8 9, 0 fire; 9 picks it, 5 drops it'),
              (MENU, 'menu and pause (4 also stops the AY music)')]
    for i, (colour, text) in enumerate(legend):
        x = 14 + (i % 2) * 440
        yy = y + (i // 2) * 20
        d.rectangle((x, yy + 2, x + 14, yy + 12), fill=colour)
        d.text((x + 22, yy), text, fill=K.TEXT, font=K.font(12))
    im = im.crop((0, 0, W, y + 46))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

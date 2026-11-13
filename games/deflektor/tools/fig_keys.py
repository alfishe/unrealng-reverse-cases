#!/usr/bin/env python3
"""The Spectrum keyboard with every key the game reads in play, coloured by its use (doc 05): the four control
methods' keys, the pause, the abort, the dormant cheat; each half-row labelled with its port.

    python3 tools/fig_keys.py docs/img/controls/keys.png
"""
import sys

from PIL import Image, ImageDraw

import figlib

ROWS = [('1 2 3 4 5 6 7 8 9 0', '$F7FE | $EFFE'), ('Q W E R T Y U I O P', '$FBFE | $DFFE'),
        ('A S D F G H J K L EN', '$FDFE | $BFFE'), ('CS Z X C V B N M SS SP', '$FEFE | $7FFE')]
USE = {  # key: (colour, short label)
    'Q': ('kbd', 'up'), 'A': ('kbd', 'down'), 'K': ('kbd', 'left'), 'L': ('kbd', 'right'),
    'CS': ('kbdf', 'fire'), 'Z': ('kbdf', 'fire'), 'X': ('kbdf', 'fire'), 'C': ('kbdf', 'fire'), 'V': ('kbdf', 'fire'),
    'B': ('kbdf', 'fire'), 'N': ('kbdf', 'fire'), 'M': ('kbdf', 'fire'), 'SS': ('kbdf', 'fire'), 'SP': ('kbdf', 'fire'),
    '1': ('sin', 'L'), '2': ('sin', 'R'), '3': ('sin', 'D'), '4': ('sin', 'U'), '5': ('pro', 'F | Pk L'),
    '6': ('pro', 'L | Pk D'), '7': ('pro', 'R | Pk U'), '8': ('pro', 'D | Pk R'), '9': ('sin', 'U'),
    '0': ('pro', 'F | Pk F'),
    'P': ('sys', 'pause'), 'EN': ('sys', 'go on'), 'U': ('abort', 'abort'), 'G': ('abort', 'abort'),
    'W': ('cheat', 'level+'), 'S': ('cheat', 'level-'), 'Y': ('cheat2', 'drop'), 'T': ('cheat2', 'drop'),
}
COL = {'kbd': ((90, 210, 120), '1 KEYBOARD: Q up, A down, K left, L right'),
       'kbdf': ((60, 140, 80), '1 KEYBOARD: fire, any key of the bottom row'),
       'sin': ((90, 150, 230), '2 SINCLAIR: 1-5 left (L), right (R), down (D), up (U), fire (F); 6-0 left, right, down, up, fire'),
       'pro': ((170, 120, 220), 'keys shared by 2 SINCLAIR and 4 PROTEK (Pk: 5 left, 8 right, 6 down, 7 up, 0 fire)'),
       'sys': ((240, 200, 80), 'P pause, ENTER go on'),
       'abort': ((230, 90, 90), 'U + G: abort the game'),
       'cheat': ((120, 120, 130), 'W / S: the dormant level cheat (jumped over)'),
       'cheat2': ((80, 80, 90), 'Y + T: drop a return address (never run)')}


def main():
    out = sys.argv[1]
    W = 1050
    kw, kh, gap = 86, 54, 6
    o = Image.new('RGB', (W, 620), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The keys of play: what each control method and the system keys read', 17, figlib.ACCENT)
    y = 46
    for r, (keys, port) in enumerate(ROWS):
        x = 20 + r * 18
        for k in keys.split():
            c, lab = USE.get(k, (None, ''))
            fill = COL[c][0] if c else (50, 50, 60)
            d.rounded_rectangle([x, y, x + kw - 2, y + kh - 2], 6, fill=fill)
            figlib.text(d, (x + 6, y + 4), {'EN': 'ENTER', 'CS': 'CAPS', 'SS': 'SYM', 'SP': 'SPACE'}.get(k, k), 15,
                        (0, 0, 0) if c else figlib.DIM)
            if lab:
                figlib.text(d, (x + 6, y + 30), lab, 11, (0, 0, 0))
            x += kw + gap
        y += kh + gap
    figlib.text(d, (20, y + 2), 'Ports: the left half of each row, then the right half: ' +
                ', '.join(p for _, p in ROWS) + '. Kempston (3): port $1F.', 12, figlib.DIM)
    y += 30
    for i, (c, (col, text)) in enumerate(COL.items()):
        d.rectangle([20, y + 4, 34, y + 16], fill=col)
        figlib.text(d, (42, y), text, 13, figlib.FG)
        y += 20
    o = o.crop((0, 0, W, y + 12))
    o.save(out)
    print(out, o.size)


if __name__ == '__main__':
    main()

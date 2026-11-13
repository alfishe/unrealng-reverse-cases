#!/usr/bin/env python3
"""The bottom panel (screen rows 20-23) of a recorded frame at 4x, each field boxed and numbered, with the routine
that writes it and the variable behind it (doc 01, doc 08).

    python3 tools/fig_panel.py docs/img/play/l01-001000-play.png docs/img/design/panel.png
"""
import sys

from PIL import Image, ImageDraw

import figlib

# (label, column, row, width, height in characters, colour, what writes it)
FIELDS = [
    ('1 LEVEL', 0, 20, 8, 1, (255, 220, 90), 'Level $81FF + 1: two digits from LevelDigits $88B0, by SetUpLevel $843C'),
    ('2 LIVES', 10, 21, 6, 1, (255, 120, 255), 'Lives $837D: three bars, one hollowed a life by LoseLife $866A'),
    ('3 OVERLOAD', 17, 21, 8, 1, (255, 90, 90), 'heat of the laser: UpdateOverload $A683, pointer $A50A; full = a life'),
    ('4 ENERGY', 17, 23, 8, 1, (90, 255, 90), 'time left: DrainEnergy $A613 one pixel every "rate" frames, pointer $A507'),
    ('5 SCORE', 26, 21, 6, 1, (90, 220, 255), 'score $9B3E, printed by $9B0A'),
    ('6 HIGH', 26, 23, 6, 1, (90, 220, 255), 'the hall of fame\'s top score, printed by $9B53'),
    ('7 COMPUTER', 0, 23, 16, 1, (255, 255, 255), 'MessageNumber $A104: scrolled and blinked by InterruptHandler $A32A'),
]
S = 4


def main():
    src, out = sys.argv[1], sys.argv[2]
    im = figlib.screen_png(src)
    k = im.width // 256
    p = im.crop((0, 160 * k, 256 * k, 192 * k)).resize((256 * S, 32 * S), Image.NEAREST)
    W = 1050
    top = 40
    h = top + p.height + 20 + 24 * len(FIELDS) + 40
    o = Image.new('RGB', (W, h), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The panel: screen rows 20-23, drawn by LevelPanel $8432 from the picture at $7B80', 17,
                figlib.ACCENT)
    x0 = (W - p.width) // 2
    o.paste(p, (x0, top))
    for lab, c, r, w, hh, col, _ in FIELDS:
        x, y = x0 + c * 8 * S, top + (r - 20) * 8 * S
        d.rectangle([x, y, x + w * 8 * S - 1, y + hh * 8 * S - 1], outline=col, width=3)
        d.rectangle([x, y, x + 18, y + 16], fill=col)
        figlib.text(d, (x + 4, y), lab.split()[0], 13, (0, 0, 0))
    y = top + p.height + 16
    for lab, c, r, w, hh, col, what in FIELDS:
        figlib.text(d, (20, y), lab, 14, col)
        figlib.text(d, (170, y), f'row {r}, columns {c}-{c + w - 1}: {what}', 13, figlib.FG)
        y += 24
    figlib.text(d, (20, y + 6), f'Frame: {src.split("/")[-1]} (recording work/stage2/rec/L01, frame 1000), 4x.', 12,
                figlib.DIM)
    o.save(out)
    print(out, o.size)


if __name__ == '__main__':
    main()

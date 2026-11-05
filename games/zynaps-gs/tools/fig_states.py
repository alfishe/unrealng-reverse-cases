#!/usr/bin/env python3
"""Doc 04 figure: the game's states from power-on to play as the screens of one recording, each with the code that
runs it and the frame it was entered.

    python3 tools/fig_states.py --work work/zgsA/r1 --out docs/img/loop/states.png

The frames are r1's (work/stage2/r1/session.ttd, power-on to play, music mode, level 1); each state's entry was
found with time_travel find_event exec (docs/04 4.1, work/docs/zgsA-NOTES.md). The screen is memory_at at the frame.
"""
import argparse
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
STATES = [
    (240, 'boot: loading screen', 'boot $5D3B: blocks 0-4', 'frames 158-811'),
    (830, 'options menu', 'menu $6D60 in block 4', 'from frame 812'),
    (1960, 'title pages', 'installer, then $B203', 'from frame 1500'),
    (2420, 'game start', 'GameStartHook: jingle', 'frames 2375-2468'),
    (2700, 'level load', 'RoundStartHook -> $C385', 'frames 2469-2950'),
    (3100, 'play', 'MainLoop, IM2 $A9A1', 'from frame 2951'),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--work', default=os.path.join(Z.CASE, 'work', 'zgsA', 'r1'))
    ap.add_argument('--out', default=Z.out('loop', 'states.png'))
    args = ap.parse_args()
    f, fb = K.font(12), K.font(15)
    cw, ch, top = 296, 268, 52
    im = Image.new('RGB', (3 * cw + 12, top + 2 * ch), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Six states from power-on to play; the GS adds the menu and the level load', fill=K.TEXT, font=fb)
    d.text((10, 28), 'r1 (music mode, level 1): the screen at the frame shown; arrows give the order', fill=K.DIM,
           font=f)
    for i, (frame, name, code, when) in enumerate(STATES):
        x, y = 10 + (i % 3) * cw, top + (i // 3) * ch
        d.text((x, y), f'{i + 1}. {name}', fill=(230, 230, 170), font=f)
        im.paste(Z.render(Z.cached(args.work, frame), 1).resize((256, 192)), (x, y + 18))
        d.text((x, y + 214), code, fill=K.TEXT, font=f)
        d.text((x, y + 230), f'{when}; picture: {frame}', fill=K.DIM, font=f)
        if i % 3 < 2:
            ax = x + 262
            d.line([ax, y + 114, ax + 24, y + 114], fill=(230, 230, 170), width=2)
            d.polygon([(ax + 24, y + 108), (ax + 30, y + 114), (ax + 24, y + 120)], fill=(230, 230, 170))
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 06 figure: the intro's three pictures as they appear, and the options screen's colour bars, from recording c1.

    python3 tools/fig_intro.py --work work/z128A/c1 --out docs/img/render/intro-reveal.gif

W holds c1 open (re_session.py open). One picture a frame (the bars every second frame), each read with time_travel
memory_at at the frame's end (exact):

  - the screen, 2x;
  - RowShown `$6315` (24 bytes, 1 when ShowPicture `$62A4` has given that attribute row its colours), drawn as a
    column of 24 boxes beside the screen, the rows revealed by this frame in yellow;
  - on the options screen, CycleColours' counter (the operand at `$60F3`, 0-3: the bars move at 0) and the two bar
    pointers (TopBar's operand `$60FC`, BottomBar's `$6159`).

The frames are those of c1: ShowPicture runs at 2185 (the title), 2602 (the options) and 2752 (the Hewson picture);
CycleColours from 2627 to 2751 (find_last, docs/06 6.9).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zalib as Z  # noqa: E402

K = Z.K
ROW_SHOWN = 0x6315
STRETCHES = [  # first, last, step, label
    (2184, 2212, 1, 'the title: ShowPicture $62A4, one attribute row a frame in random order'),
    (2602, 2630, 1, 'the options screen: ShowPicture again'),
    (2631, 2700, 2, 'the options screen waits: CycleColours $60F2 moves the two bars every 4th frame'),
    (2752, 2780, 1, 'the Hewson picture: ShowPicture; block 2 loads under it'),
]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--delay', type=int, default=120)
    args = p.parse_args()
    s = Z.session(args.work)
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    pictures, durations = [], []
    for first, last, step, label in STRETCHES:
        before = None
        for fr in range(first, last + 1, step):
            mem = bytearray(0x10000)
            mem[0x4000:0x5B00] = Z.read(s, fr, 0x4000, 6912)
            shown = Z.read(s, fr, ROW_SHOWN, 24)
            code = Z.read(s, fr, 0x60F2, 0x70)
            im = Image.new('RGB', (900, 470), K.BACKGROUND)
            d = ImageDraw.Draw(im)
            d.text((10, 8), 'The intro shows each picture pixels first, then its colours one random row a frame',
                   fill=K.TEXT, font=fb)
            d.text((10, 30), f'c1 frame {fr}: {label}', fill=(250, 220, 120), font=f)
            im.paste(K.render_screen(mem).resize((512, 384), Image.NEAREST), (10, 56))
            x0 = 534
            d.text((x0, 56), 'RowShown $6315', fill=K.TEXT, font=f)
            for r in range(24):
                y = 56 + 18 + r * 15
                new = before is not None and shown[r] and not before[r]
                colour = (250, 220, 120) if new else ((90, 200, 120) if shown[r] else (40, 40, 52))
                d.rectangle((x0, y, x0 + 26, y + 12), fill=colour)
                d.text((x0 + 32, y - 1), f'row {r}', fill=K.DIM, font=fs)
                d.line((10 + 512, 56 + r * 16 + 8, x0 - 2, y + 6), fill=(50, 50, 64))
            n = sum(1 for b in shown if b)
            d.text((x0 + 90, 74), f'{n} of 24 rows coloured', fill=K.TEXT, font=f)
            d.text((x0 + 90, 92), 'green: shown; yellow: shown this frame;', fill=K.DIM, font=fs)
            d.text((x0 + 90, 106), 'dark: still black (attribute 0)', fill=K.DIM, font=fs)
            if 2631 <= fr <= 2751:
                counter = code[1]
                top = code[0x60FC - 0x60F2] | code[0x60FD - 0x60F2] << 8
                bottom = code[0x6159 - 0x60F2] | code[0x615A - 0x60F2] << 8 if 0x615A - 0x60F2 < len(code) else 0
                d.text((x0 + 90, 140), f'CycleColours counter $60F3 = {counter}', fill=K.TEXT, font=f)
                d.text((x0 + 90, 158), '(the bars move when it is 0)', fill=K.DIM, font=fs)
                d.text((x0 + 90, 178), f'upper bar pointer $60FC = ${top:04X}', fill=K.TEXT, font=f)
                d.text((x0 + 90, 196), f'lower bar pointer $6159 = ${bottom:04X}', fill=K.TEXT, font=f)
                d.text((x0 + 90, 216), 'rows 0-7: one CycleTable byte a row;', fill=K.DIM, font=fs)
                d.text((x0 + 90, 230), 'rows 8-16: only cells of $46 or more', fill=K.DIM, font=fs)
            pictures.append(im)
            durations.append(args.delay * step)
            before = shown
        durations[-1] = 1500
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), 'pictures', os.path.getsize(args.out), 'bytes')


if __name__ == '__main__':
    main()

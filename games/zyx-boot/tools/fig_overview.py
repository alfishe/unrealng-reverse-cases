#!/usr/bin/env python3
"""The figures of doc 01 (what you see): every screen of the menu at named frames, and the screen's layout.

    python3 tools/fig_overview.py --c1 work/docs/zbA/c1 --c2 work/docs/zbA/c2

--c1 / --c2 are instances holding the recordings c1 and c2 (re_session.py open); the moments are kept in
work/docs/figcache/, so a second run needs no instance. Writes docs/img/overview/screens.png and layout.png.
"""
import argparse

from PIL import Image

import figzyx as Z

SHOTS = [
    ('c1', '850', 'c1 850: set-up; help lines, name mid-spin'),
    ('c1', '1000', 'c1 1000: idle, the reflection over them'),
    ('c1', '1075', 'c1 1075: the red glint on the logo'),
    ('c1', '1110', 'c1 1110: the cursor name turned 90 deg'),
    ('c2', '1500', 'c2 1500: page 1, 24 names, two columns'),
    ('c2', '2000', 'c2 2000: page 2 after SS, 7 names'),
    ('c2', '3500', 'c2 3500: the cursor in column 2'),
    ('c2', '3760', 'c2 3760: ENTER on T03, before the launch'),
    ('c2', '3778', 'c2 3778: ExitFade shifts the pixels out'),
    ('c2', '4300', 'c2 4300: TR-DOS ran T03: TEST 03'),
]


def fig_screens(works):
    scale = 2
    pw, ph = 256 * scale, 192 * scale
    rows = (len(SHOTS) + 1) // 2
    out, d = Z.canvas(70 + rows * (ph + 36))
    Z.title(d, 'Every screen of ZYX boot, from the set-up to the program it runs',
            'c1: the original disk (NO EXE FILES !); c2: the test disk many.scl (31 listed names); Pentagon 128K, '
            'frames of each recording')
    f = Z.font(13)
    for i, (rec, frame, text) in enumerate(SHOTS):
        mem = Z.moment(works[rec], frame)
        x = 8 + (i % 2) * (pw + 10)
        y = 66 + (i // 2) * (ph + 36)
        out.paste(Z.screen(mem).resize((pw, ph), Image.NEAREST), (x, y + 20))
        d.text((x, y), f'{i + 1}. {text}', fill=Z.TEXT, font=f)
    Z.save(out, 'docs/img/overview/screens.png')


def fig_layout(works):
    """The menu screen with its parts outlined and named"""
    scale = 3
    mem = Z.moment(works['c2'], '1500')
    scr = Z.screen(mem).resize((256 * scale, 192 * scale), Image.NEAREST)
    scr = Image.eval(scr, lambda v: v * 2 // 3)
    out, d = Z.canvas(192 * scale + 110)
    Z.title(d, 'The menu screen and its parts (c2 frame 1500, page 1)',
            'the boxes are character cells; the notes on the right name each part and the routine that draws it')
    x0, y0 = 12, 64
    out.paste(scr, (x0, y0))
    f = Z.font(12)
    parts = [
        ((0, 0, 5, 5), (240, 200, 70), 'rhombus A', 'PrintRombPhase'),
        ((27, 0, 5, 5), (240, 200, 70), 'rhombus B', ''),
        ((0, 19, 5, 5), (240, 200, 70), 'rhombus B', ''),
        ((27, 19, 5, 5), (240, 200, 70), 'rhombus A', ''),
        ((6, 0, 20, 5), (80, 220, 230), 'the logo rows 0-4, cols 6-25', 'DrawScreen'),
        ((6, 19, 20, 5), (200, 110, 230), 'the reflection rows 19-23', 'DrawReflection'),
        ((0, 6, 32, 12), (90, 220, 120), 'the files: rows 6-17', 'ListCatalogue, PrintColumn'),
    ]
    for (c, r, w, h), colour, name, who in parts:
        bx0, by0 = x0 + c * 8 * scale, y0 + r * 8 * scale
        d.rectangle([bx0, by0, bx0 + w * 8 * scale - 1, by0 + h * 8 * scale - 1], outline=colour, width=2)
    tx = x0 + 256 * scale + 14
    notes = [
        ('rhombi (yellow)', ['the four corners, 5 x 5 cells;', 'A turns about the vertical axis,',
                             'B about the horizontal one;', 'PrintRombPhase, MainLoop']),
        ('logo (cyan)', ['rows 0-4, columns 6-25;', 'DrawScreen']),
        ('reflection (purple)', ['rows 19-23, the logo upside', 'down over the help lines;', 'DrawReflection']),
        ('files (green)', ['rows 6-17, "A>  NAME";', '1-12: letters at column 10,', '13-24: at columns 2 and 18;',
                           'PrintColumn']),
        ('cursor', ["the attribute of the name's", 'cells, a new ink every 4', 'frames; Interrupt']),
        ('stars, twinkle', ['anywhere outside the text;', 'MoveStars, DrawTwinkle']),
    ]
    y = y0
    for a, lines in notes:
        d.text((tx, y), a, fill=Z.TEXT, font=Z.font(13))
        y += 18
        for line in lines:
            d.text((tx, y), line, fill=Z.DIM, font=f)
            y += 16
        y += 8
    for c in range(0, 32, 2):
        d.text((x0 + c * 8 * scale + 4, y0 + 192 * scale + 4), str(c), fill=Z.DIM, font=Z.font(10))
    d.text((x0, y0 + 192 * scale + 22), 'column numbers under the picture; drawn by tools/fig_overview.py from c2 '
                                        '(TTD memory_at)', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/overview/layout.png')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--c1', required=True)
    p.add_argument('--c2', required=True)
    args = p.parse_args()
    works = {'c1': args.c1, 'c2': args.c2}
    fig_screens(works)
    fig_layout(works)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The same moments of both games side by side, for the resources part of docs/13 (work/diff/resources.md): the
menus, the side-panel menus and the play screen with its status panel.

Both cases recorded the same scripted session: NE's tools/ill_ui.py tour (work/ill3/tour of the NE case) and ANE's
tools/fig_tour.py tour (work/docP/tour), the same 61 steps in the same order (a redefine, a build, orders, direct
control, combat, the distance menu, the pause, a day of hovering). Each samples.bin holds the screen every 2-4
frames; a picture here is the first sample at or after (step's frame + offset) in each recording. No emulator runs.

    python3 tools/fig_diff_res_screens.py menus    docs/img/diff/res-screens-menus.png
    python3 tools/fig_diff_res_screens.py panel    docs/img/diff/res-screens-panel.png
    python3 tools/fig_diff_res_screens.py all
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
R = os.path.abspath(os.path.join(CASE, '..', '..'))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'diff')
TOURS = {'NE': (os.path.join(R, 'games', 'nether-earth', 'work', 'ill3', 'tour'), 4),     # frame, screen
         'ANE': (os.path.join(CASE, 'work', 'docP', 'tour'), 5)}                         # frame, bank, screen
BG, FG, DIM, PANEL = K.BACKGROUND, K.TEXT, K.DIM, K.PANEL
MARK = K.WRITE_FADE[2]

# (title, step index in both events.json, frames after the step, what to note)
FULL = [('the main menu', 0, 300, 'NE: the title in the font, the menu, the beeper tune. ANE: a picture from bank 3, '
         'the menu moved to (10,1), the AY tune'),
        ('the redefine screen, all eight keys given', 9, 20, 'the same layout; the key names translated; SYM SH '
         'prints as ЯУМ ЯН'),
        ('the construction menu', 21, 12, 'the same layout and costs; ROBOT CONSTRUCTION -> ЦЕХ РОБОТОВ (robot '
         'workshop)')]
SIDE = [('robot menu', 26, 8), ('orders', 28, 30), ('search & capture', 29, 0), ('combat mode', 41, 0),
        ('distance', 50, 10)]
PLAY = ('the play screen', 57, 380)


def load(key):
    work, head = TOURS[key]
    events = [tuple(e) for e in json.load(open(os.path.join(work, 'events.json')))]
    raw = open(os.path.join(work, 'samples.bin'), 'rb').read()
    rec = head + 6912
    samples = [(int.from_bytes(raw[i:i + 4], 'little'), raw[i + head:i + rec]) for i in range(0, len(raw), rec)]
    return events, samples


def moment(tour, step, offset):
    events, samples = tour
    target = events[step][0] + offset
    for frame, mem in samples:
        if frame >= target:
            return frame, mem
    return samples[-1]


def screen(mem, scale=2, crop=None):
    im = K.render_screen(mem, 0)
    if crop:
        im = im.crop(crop)
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def mark(d, x0, y0, scale, row, col, width, text, crop_col=0):
    """a frame around `width` cells of character row `row` from column `col`, with a label"""
    x = x0 + (col - crop_col) * 8 * scale
    y = y0 + row * 8 * scale
    d.rectangle([x - 2, y - 2, x + width * 8 * scale + 1, y + 8 * scale + 1], outline=MARK, width=2)
    if text:
        d.text((x, y + 8 * scale + 3), text, fill=MARK, font=K.font(11))


def cmd_menus(args):
    ne, ane = load('NE'), load('ANE')
    s = 2
    W = 14 + 2 * (256 * s + 16) + 6
    row_h = 192 * s + 64
    H = 78 + len(FULL) * row_h + 30
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((14, 10), 'The menus at the same steps of the same scripted session: NE left, ANE right', fill=FG,
           font=K.font(17))
    d.text((14, 34), 'the layout and the colours stay; the texts are Russian in ANE\'s font. Recordings: NE '
           'work/ill3/tour (ill_ui.py tour),', fill=DIM, font=K.font(12))
    d.text((14, 49), 'ANE work/docP/tour (fig_tour.py tour)', fill=DIM, font=K.font(12))
    y = 72
    for title, step, offset, note in FULL:
        for k, (key, tour) in enumerate((('NE', ne), ('ANE', ane))):
            frame, mem = moment(tour, step, offset)
            x = 14 + k * (256 * s + 16)
            out.paste(screen(mem, s), (x, y + 20))
            d.text((x, y), '%s: %s, frame %d' % (key, title, frame), fill=FG, font=K.font(13))
        d.text((14, y + 20 + 192 * s + 6), note, fill=DIM, font=K.font(12))
        y += row_h
    d.text((14, H - 22), 'python3 tools/fig_diff_res_screens.py menus', fill=DIM, font=K.font(11))
    path = args.out or os.path.join(OUT, 'res-screens-menus.png')
    out.save(path)
    print(path, out.size)


def cmd_panel(args):
    ne, ane = load('NE'), load('ANE')
    s = 2
    crop_col = 22
    crop = (crop_col * 8, 0, 256, 192)          # the side panel, columns 22-31
    cw = (256 - crop_col * 8) * s
    W = max(14 + 2 * (256 * s + 16) + 6, 14 + len(SIDE) * (cw + 16) + 70)
    H = 76 + (192 * s + 60) + 2 * (192 * s + 40) + 70
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((14, 10), 'The play screen and the side-panel menus: same cells and colours, Russian words; two '
           'titles turn green', fill=FG, font=K.font(17))
    d.text((14, 34), 'the same steps of the scripted session in both recordings; orange frames: an attribute byte '
           'that is $20 (green paper, black ink) in ANE,', fill=DIM, font=K.font(12))
    d.text((14, 49), 'where NE has $46 or $4F', fill=DIM, font=K.font(12))
    y = 70
    title, step, offset = PLAY
    for k, (key, tour) in enumerate((('NE', ne), ('ANE', ane))):
        frame, mem = moment(tour, step, offset)
        x = 14 + k * (256 * s + 16)
        out.paste(screen(mem, s), (x, y + 20))
        d.text((x, y), '%s: %s, frame %d (a day of hovering)' % (key, title, frame), fill=FG, font=K.font(13))
    y += 192 * s + 34
    d.text((14, y), 'the panel: DAY / TIME, STATUS with INSG | HUMN (aliens | humans), the counts, RESOURCES, '
           'RADAR: all at the same cells in both', fill=DIM, font=K.font(12))
    y += 26
    for k, (key, tour) in enumerate((('NE', ne), ('ANE', ane))):
        d.text((14, y + 192 * s // 2 - 8), key, fill=FG, font=K.font(15))
        for i, (name, step, offset) in enumerate(SIDE):
            frame, mem = moment(tour, step, offset)
            x = 70 + i * (cw + 16)
            out.paste(screen(mem, s, crop), (x, y + 18))
            d.text((x, y), '%s, %d' % (name, frame), fill=FG if k == 0 else FG, font=K.font(11))
            if key == 'ANE' and name == 'robot menu':
                mark(d, x, y + 18, s, 17, 23, 8, '', crop_col)
                d.text((x, y + 18 + 192 * s + 2), 'ПРИКАЗ: $20 (NE $46)', fill=MARK, font=K.font(11))
            if key == 'ANE' and name == 'search & capture':
                mark(d, x, y + 18, s, 4, 23, 8, '', crop_col)
                mark(d, x, y + 18, s, 5, 23, 8, '', crop_col)
                d.text((x, y + 18 + 192 * s + 2), 'title: $20 (NE $4F)', fill=MARK, font=K.font(11))
        y += 192 * s + 40
    d.text((14, H - 40), 'RETREAT\'s title (НАЗАД, $AA32) has the same $20; the session does not open it. Bytes: '
           'python3 tools/diff_res.py --section strings', fill=DIM, font=K.font(12))
    d.text((14, H - 22), 'python3 tools/fig_diff_res_screens.py panel', fill=DIM, font=K.font(11))
    path = args.out or os.path.join(OUT, 'res-screens-panel.png')
    out.save(path)
    print(path, out.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('what', choices=['menus', 'panel', 'all'])
    p.add_argument('--out')
    args = p.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for w in (['menus', 'panel'] if args.what == 'all' else [args.what]):
        globals()['cmd_' + w](args if args.what != 'all' else argparse.Namespace(out=None))


if __name__ == '__main__':
    main()

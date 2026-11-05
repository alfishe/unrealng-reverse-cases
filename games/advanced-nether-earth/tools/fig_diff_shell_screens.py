#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): the screens around play, Nether Earth next to ANE: the main menu,
the save prompt, losing, winning, and the screens only ANE has.

    python3 tools/fig_diff_shell_screens.py --out docs/img/diff/shell-screens.png

The screens are recordings of both cases (all 256 x 192 or cropped to it):
  Nether Earth: ../nether-earth/work/ill3/tour/state-menu.png and state-gameover.png (its tour), work/diff/rec-ne-save/
      save-prompt.png (recorded for this report from the tour's start.szx, key 5 in play; inputs.txt beside it);
  ANE: work/docR/shots2/menu.png and card1.png (d1), work/stage3/r2/screens-rec/f7652.png (the save prompt) and
      f8932.png (the load prompt), work/stage3/r3/screens-rec/f100.png and f900.png (Dead End), work/stage3/r4/
      screens-rec/f100.png and f5000.png (Final Cut), work/stage3/r1/screens-rec/p8699.png, p9079.png and p10129.png
      (the boot menu, the help menu, a help page).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from PIL import Image  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

S3 = os.path.join(C.ANE, 'work/stage3')
ROWS = [  # row title, NE (path, caption) or None, [ANE (path, caption)]
    ('the game menu', (os.path.join(C.NE, 'work/ill3/tour/state-menu.png'), 'MainMenu $C100, beeper tune'),
     [(os.path.join(C.ANE, 'work/docR/shots2/menu.png'), 'the same menu in Russian,\nAY tune TAIGA, a picture')]),
    ('key 5 in play: save', (os.path.join(C.ANE, 'work/diff/rec-ne-save/save-prompt.png'),
                             'tape: "PRESS RECORD AND PLAY"'),
     [(os.path.join(S3, 'r2/screens-rec/f7652.png'), 'disk: the screen cleared,\nthe file name typed')]),
    ('losing', (os.path.join(C.NE, 'work/ill3/tour/state-gameover.png'), 'two lines under the view,\nback to Start'),
     [(os.path.join(S3, 'r3/screens-rec/f100.png'), 'Dead End: a picture,\nthe end tune'),
      (os.path.join(S3, 'r3/screens-rec/f900.png'), 'Dead End: GAME OVER,\nthen the game menu')]),
    ('winning', None,
     [(os.path.join(S3, 'r4/screens-rec/f100.png'), 'Final Cut: a picture,\nthe story'),
      (os.path.join(S3, 'r4/screens-rec/f5000.png'), 'Final Cut: never returns')]),
    ('only ANE', 'skip',
     [(os.path.join(S3, 'r1/screens-rec/p8699.png'), 'the boot menu'),
      (os.path.join(S3, 'r1/screens-rec/p9079.png'), 'the help menu (28 pages)'),
      (os.path.join(S3, 'r2/screens-rec/f8932.png'), 'key 5 in the menu: load')]),
]


def screen(path):
    im = Image.open(path).convert('RGB')
    if im.size == (352, 288):                 # with the border: keep the 256 x 192 paper
        im = im.crop((48, 48, 304, 240))
    return im.resize((256, 192), Image.NEAREST)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=C.out_path('shell-screens.png'))
    args = p.parse_args()
    fig = plt.figure(figsize=(13, 15.5), dpi=100)
    gs = fig.add_gridspec(len(ROWS), 4, width_ratios=[0.55, 1, 1, 1], wspace=0.06, hspace=0.36)
    C.style(fig, ())
    for r, (title, ne, anes) in enumerate(ROWS):
        t = fig.add_subplot(gs[r, 0])
        t.set_axis_off()
        t.text(1.0, 0.5, title, color=C.FG, fontsize=12, ha='right', va='center')
        cells = ([] if ne == 'skip' else [('NE', ne)]) + [('ANE', a) for a in anes]
        for c, (who, item) in enumerate(cells):
            a = fig.add_subplot(gs[r, 1 + c])
            a.set_xticks([])
            a.set_yticks([])
            col = C.NE_COL if who == 'NE' else C.ANE_COL
            if item is None:
                a.set_facecolor(C.PANEL)
                note = {'winning': 'two lines under the view\n"INSIGNIANS DESTROYED /\nYOU HAVE WON !",\nback to Start'}
                a.text(0.5, 0.5, note.get(title, 'no such screen'), color=C.DIM, fontsize=10, ha='center',
                       va='center', transform=a.transAxes)
                a.set_title('NE: no picture', color=col, fontsize=9.5, pad=4)
            else:
                a.imshow(screen(item[0]))
                a.set_title(f'{who}: {item[1]}', color=col, fontsize=9.5, pad=4)
            for s in a.spines.values():
                s.set_color(col)
                s.set_linewidth(2)
    fig.suptitle('Around play: the same game menu and keys, but every exit from play is a new screen in ANE\n'
                 '(blue frame: Nether Earth, orange: ANE)', color=C.FG, fontsize=13.5, x=0.08, ha='left', y=0.93)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


if __name__ == '__main__':
    sys.exit(main())

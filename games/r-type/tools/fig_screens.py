#!/usr/bin/env python3
"""Doc 01's contact sheets: the recordings' screenshots (docs/img/play/*.png, WALKTHROUGH 6.1), four to a row, each
labelled with its recording, its frame and what it shows.

    python3 tools/fig_screens.py around OUT.png     # the screens around play, in the order a player meets them
    python3 tools/fig_screens.py levels OUT.png     # each level in play and at its boss or end
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

PLAY = os.path.join(CASE, 'docs', 'img', 'play')
W, COLS, GAP = 1050, 4, 10

AROUND = [('c1-011784-loading-screen', '1 the loading screen'),
          ('c1-013784-rewind-side2', '2 REWIND SIDE 2'),
          ('c1-013858-searching-level1', '3 SEARCHING'),
          ('c1-016528-level1-loaded', '4 LOADED OK'),
          ('c1-016828-title', '5 the title'),
          ('c1-017278-best-pilots', "6 TODAY'S BEST PILOTS"),
          ('c1-017858-define-keys', '7 ENTER: define the keys'),
          ('c1-018302-level1-start', '8 level 1, the HUD'),
          ('c1-018630-beam-fired', '9 the beam fired'),
          ('c1-018778-pause', '10 PILOT STAND BY'),
          ('continue-003796-mission-over', '11 MISSION OVER'),
          ('hiscore-005247-enter-name', '12 ENTER YOUR NAME'),
          ('hiscore-005959-table', '13 the new table'),
          ('gameover-004165-continue-countdown', '14 CONTINUE, counting'),
          ('continue-003913-press-fire', '15 PRESS FIRE, CREDIT'),
          ('ending-001808-searching-level1', '16 after level 8')]
LEVELS = []
for n, a, b, what in [(1, 'l1-007009-level1', 'l1-014016-level1-boss', 'boss'),
                      (2, 'l2-007523-level2', 'l2-014504-level2-boss', 'boss'),
                      (3, 'l3-008505-level3', 'l3-016513-level3-end', 'end'),
                      (4, 'l4-007523-level4', 'l4-014018-level4-boss', 'boss'),
                      (5, 'l5-006504-level5', 'l5-012007-level5-end', 'end'),
                      (6, 'l6-005004-level6', 'l6-009520-level6-end', 'end'),
                      (7, 'l7-007515-level7', 'l7-014010-level7-end', 'end'),
                      (8, 'l8-004506-level8', 'l8-008505-level8-boss', 'boss')]:
    LEVELS += [(a, 'level %d' % n), (b, 'level %d, its %s' % (n, what))]


def label(name):
    m = re.match(r'(.+?)-(\d{6})-', name)
    return '%s %d' % (m.group(1), int(m.group(2)))


def sheet(items, title, out):
    cw = (W - GAP * (COLS + 1)) // COLS
    ch = cw * 192 // 256
    f_big, f = K.font(16), K.font(13)
    top, lab = 44, 38
    rows = (len(items) + COLS - 1) // COLS
    H = top + rows * (ch + lab + GAP) + GAP
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((GAP, 12), title, fill=K.TEXT, font=f_big)
    for i, (name, what) in enumerate(items):
        x = GAP + (i % COLS) * (cw + GAP)
        y = top + (i // COLS) * (ch + lab + GAP)
        shot = Image.open(os.path.join(PLAY, name + '.png')).convert('RGB').resize((cw, ch), Image.LANCZOS)
        im.paste(shot, (x, y))
        d.text((x, y + ch + 3), what, fill=K.TEXT, font=f)
        d.text((x, y + ch + 20), label(name), fill=K.DIM, font=f)
    im.save(out)


def main():
    what, out = sys.argv[1], sys.argv[2]
    if what == 'around':
        sheet(AROUND, 'The screens around play, in the order a player meets them (recording, frame)', out)
    elif what == 'levels':
        sheet(LEVELS, 'The eight levels in play, and each at its boss or its end (recording, frame)', out)
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()

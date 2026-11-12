#!/usr/bin/env python3
"""A sheet of screens from the case's own recordings, each with its recording and frame: the screens doc 1 shows
beside docs/img/play/screens.png (the loading screen, the title's steps, the 128K sound sign, the high-score table,
the 48K story, a fight, GAME OVER).

    python3 tools/fig_screens.py docs/img/play/screens-more.png

Each picture is a recording's screens/FFFFFF-name.png (tools/record.py: the screen at the start of that frame,
512 x 384, the 256 x 192 screen doubled, no border), scaled to a third of 1050 px.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

REC = os.path.join(HERE, '..', 'work')
SHOTS = [
    ('stage1/rec/c48/screens/003232-loading-6.png', 'c48 3232: the loading screen (48K)'),
    ('stage1/rec/menu/screens/003915-cycle-1.png', 'menu 3915: the title, the logo builds up'),
    ('stage2/rec/play48/screens/000759-punch.png', 'play48 759: a punch (48K)'),
    ('stage1/rec/menu/screens/000110-title-1-left.png', 'menu 110: the title, left: music (the note)'),
    ('stage1/rec/menu/screens/000156-title-1-right.png', 'menu 156: the title, right: effects (FX)'),
    ('stage1/rec/c48/screens/020701-intro-1.png', 'c48 20701: the 48K story at the boot'),
    ('stage2/rec/play48/screens/002219-fight-6.png', 'play48 2219: a fight (48K)'),
    ('stage1/rec/gameover/screens/002429-walk-03.png', 'gameover 2429: GAME OVER (lives poked to 0)'),
    ('stage1/rec/gameover/screens/006729-after.png', 'gameover 6729: the table, no entry'),
]


def main():
    out = sys.argv[1]
    W, cols = 1050, 3
    tw = W // cols
    th = tw * 3 // 4
    lab = 18
    rows = (len(SHOTS) + cols - 1) // cols
    sheet = Image.new('RGB', (W, 30 + rows * (th + lab)), (16, 16, 20))
    d = ImageDraw.Draw(sheet)
    d.text((8, 6), 'More screens from our recordings: the load, the title, the 128K sound sign, the 48K story, '
                   'a fight, GAME OVER', fill='white', font=K.font(14))
    for i, (path, label) in enumerate(SHOTS):
        r, c = divmod(i, cols)
        x, y = c * tw, 30 + r * (th + lab)
        im = Image.open(os.path.join(REC, path)).convert('RGB').resize((tw - 4, th - 3), Image.LANCZOS)
        sheet.paste(im, (x + 2, y))
        d.text((x + 4, y + th - 1), label, fill=(210, 210, 210), font=K.font(12))
    sheet.save(out)
    print(out, sheet.size)


if __name__ == '__main__':
    main()

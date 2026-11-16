#!/usr/bin/env python3
"""Every screen of Enduro Racer on one sheet, from the recordings' screenshots in docs/img/play (doc 01, 1.3).

    python3 tools/fig_screens.py [--out docs/img/design/screens.png] [--width 1050]

Each tile is a screenshot (docs/img/play/<recording>-<frame>-<moment>.png, 512 x 384, the screen at 2x) scaled to
the tile width, with its number, recording and frame under it. The list below is the order a player meets them.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

SCREENS = [
    ('c1-008282-loading-code', 'the loading screen, the code loading'),
    ('c1-011882-attract-0', 'the credits scroll'),
    ('c1-012482-attract-3', 'the demo race (DEMO)'),
    ('c1-013418-menu', 'the main menu'),
    ('c1-013578-control-popup', 'CHANGE CONTROL MODE'),
    ('c1-013878-define-keys', 'DEFINE KEYS'),
    ('c1-014075-go', 'the countdown, stage 1'),
    ('c1-016281-c1-1624', 'stage 1: a ramp across the road'),
    ('c1-014621-pause', 'paused (H)'),
    ('crash-003320-wheelie-3320', 'a fall: the bike down'),
    ('crash-004580-wheelie-4580', 'getting up'),
    ('c1-019265-time-up', 'the timer at 0'),
    ('c1-019465-after-0', 'the lap table, game over'),
    ('stages-003422-stage-01', 'stage 2: EXTENDED PLAY'),
    ('stages-005340-stage-02', 'stage 3, the dunes'),
    ('stages-007806-stage-03', 'stage 4, cacti'),
    ('stages-010272-stage-04', 'stage 5, the beach'),
    ('stages-013012-stage-05', 'after the finish'),
    ('stages-022204-table-held', 'the lap table, 5 stages'),
    ('stages-022308-hiscore', 'the high scores, the grid'),
    ('stages-022708-name-entered', 'the name entered'),
    ('twoplayer-010892-p2-10892', 'two players: 2UP'),
    ('m128-014689-m128-1008', 'the 128K (AY engine)'),
    ('reset3-006662-go-6662', 'stage 3: the jump before the reset'),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'design', 'screens.png'))
    ap.add_argument('--width', type=int, default=1050)
    ap.add_argument('--columns', type=int, default=3)
    a = ap.parse_args()
    gap, cap = 10, 40
    tw = (a.width - gap * (a.columns + 1)) // a.columns
    th = tw * 3 // 4
    rows = (len(SCREENS) + a.columns - 1) // a.columns
    title_h = 34
    im = Image.new('RGB', (a.width, title_h + rows * (th + cap + gap) + gap), (255, 255, 255))
    dr = ImageDraw.Draw(im)
    f, fb = kitlib.font(14), kitlib.font(18)
    dr.text((gap, 8), 'Enduro Racer: every screen and mode, in the order a player meets them', font=fb, fill=(0, 0, 0))
    for i, (name, what) in enumerate(SCREENS):
        r, c = divmod(i, a.columns)
        x = gap + c * (tw + gap)
        y = title_h + gap + r * (th + cap + gap)
        shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', name + '.png')).convert('RGB')
        im.paste(shot.resize((tw, th), Image.LANCZOS), (x, y))
        rec, frame = name.split('-')[0], int(name.split('-')[1])
        dr.text((x, y + th + 3), '%d. %s' % (i + 1, what), font=f, fill=(0, 0, 0))
        dr.text((x, y + th + 20), '%s, frame %d' % (rec, frame), font=f, fill=(90, 90, 90))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

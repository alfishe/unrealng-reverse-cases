#!/usr/bin/env python3
"""Doc 01's screen atlas: every screen of the game in the order a player meets it, from the screenshots in
docs/img/play (each named <recording>-<frame>-<what>.png and taken at the end of that frame by screen_shot or the
recording scripts), four to a row with a caption of the recording and frame.

    python3 tools/fig_screens.py docs/img/play/screens.png
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = [
    ('c1-003282-screen-loading', '1 loading screen'), ('c1-014300-credits', '2 credits (title, tune)'),
    ('c1-014500-title-logo', '3 logo, menu builds'), ('c1-014640-menu-hiscores', '4 menu + high scores'),
    ('menu-000552-two-players', '5 TWO PLAYERS'), ('menu-000160-keyboard-table', '6 redefine keys'),
    ('menu-000776-p2-control', '7 P2 control choice'), ('c1-014900-trail-intro', '8 trail number'),
    ('c1-015000-trail-name', '9 trail name'), ('c1-015060-first-pass', '10 START, rider on foot'),
    ('kb-000834-split-screen', '11 two players'), ('c1-015540-jump', '12 a jump'),
    ('c1-015580-tumble', '13 a crash'), ('c1-015800-on-foot', '14 walking back'),
    ('empty-000939-out-of-fuel', '15 OUT OF FUEL'), ('c1-019260-time-out', '16 TIME OUT'),
    ('trails-001640-finish-line', '17 the finish line'), ('trails-001700-extended-play', '18 EXTENDED PLAY'),
    ('warp-001163-bonus-band', '19 bonus count'), ('warp-016479-name-entry', '20 name entry'),
]


def font(n):
    try:
        return ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', n)
    except OSError:
        return ImageFont.load_default()


def main():
    out = sys.argv[1]
    cols, cw, chh, cap = 4, 256, 192, 34
    pad = (1050 - cols * cw) // (cols + 1)
    rows = (len(SHOTS) + cols - 1) // cols
    top = 36
    im = Image.new('RGB', (1050, top + rows * (chh + cap + 8)), (22, 22, 30))
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Every screen of ATV Simulator, in the order a player meets it', fill=(240, 240, 240), font=font(16))
    f = font(12)
    for i, (name, what) in enumerate(SHOTS):
        r, c = divmod(i, cols)
        x = pad + c * (cw + pad)
        y = top + r * (chh + cap + 8)
        shot = Image.open(os.path.join(CASE, 'docs/img/play', name + '.png')).convert('RGB').resize((cw, chh))
        im.paste(shot, (x, y))
        rec, frame = name.split('-')[:2]
        d.text((x, y + chh + 3), what, fill=(240, 220, 120), font=f)
        d.text((x, y + chh + 18), '%s frame %d' % (rec, int(frame)), fill=(180, 180, 190), font=f)
    im.save(out)
    print(out, im.size)


if __name__ == '__main__':
    main()

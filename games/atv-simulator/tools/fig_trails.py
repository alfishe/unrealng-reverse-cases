#!/usr/bin/env python3
"""Doc 01's map of the six trails, 1050 px wide: each trail drawn from src/res/trails (through tools/trail_map.py's
readers, the sprites of src/res/sprites/game.png and, for an item with flags bit 0, menu.png) as strips of 896 distance units, one unit a pixel, with a ruler
every 128 units, the start sign, the finish (the length less $48, FinishCheck) and the moments the recordings
witnessed on the trail (c1's crash, the trails bot's finish and its last crash, the speedcrash and wallcrash
recordings' crashes).

    python3 tools/fig_trails.py docs/img/maps/trails.png
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import trail_map as tm  # noqa: E402

WRAP, LEFT, BAND_A, BAND_B = 896, 140, 104, 62
MAX = ['60', '60', '60', '40', '50', '50']
INK = ['yellow sand', 'green grass', 'white ice', 'yellow sand', 'green grass', 'yellow sand']
# (trail, distance, text) seen in the recordings; distances are TrackPos ($D78A) samples at T 0 of the frame
MARKS = [
    (1, 381, 'c1 15580: crash, tumble'),
    (1, 1608, 'trails 1680: finish, lap 19.8'),
    (1, 613, 'speedcrash 1032: stop, throw'),
    (2, 296, 'wallcrash 1683: nose test'),
    (2, 898, 'trails: the bot stops here'),
]


def main():
    out = sys.argv[1]
    sp, menu, tr = tm.sprites(), tm.menu_sprites(), tm.trails()
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 13)
        small = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 12)
    except OSError:
        font = small = ImageFont.load_default()
    rows = [(t, r) for t in range(1, 7) for r in range((tr[t][0] + WRAP - 1) // WRAP)]
    strip = BAND_A + BAND_B + 34
    head = 44
    im = Image.new('RGB', (1050, head + strip * len(rows) + 8), (24, 24, 32))
    dr, px = ImageDraw.Draw(im), im.load()
    dr.text((8, 6), 'The six trails from src/res/trails: list A (ground and obstacles, blue) over list B (scenery, green),',
            fill=(235, 235, 235), font=font)
    dr.text((8, 23), 'one distance unit a pixel, wrapped every 896; red: the finish (length - $48); orange: recorded moments',
            fill=(235, 235, 235), font=font)
    for k, (t, r) in enumerate(rows):
        ln, la, lb = tr[t]
        y0, x0 = head + k * strip, LEFT - r * WRAP
        ga, gb = y0 + BAND_A, y0 + BAND_A + BAND_B
        if r == 0:
            dr.text((6, y0 + 4), '%d %s' % (t, tm.NAMES[t - 1]), fill=(240, 225, 120), font=font)
            dr.text((6, y0 + 22), 'length $%04X' % ln, fill=(205, 205, 205), font=small)
            dr.text((6, y0 + 38), 'finish %d' % (ln - 0x48), fill=(235, 120, 120), font=small)
            dr.text((6, y0 + 54), 'max time %s' % MAX[t - 1], fill=(205, 205, 205), font=small)
            dr.text((6, y0 + 70), 'A %d, B %d items' % (len(la), len(lb)), fill=(205, 205, 205), font=small)
        else:
            dr.text((6, y0 + 4), '%d from %d' % (t, r * WRAP), fill=(240, 225, 120), font=font)
        dr.text((6, ga - 16), 'list A', fill=(150, 190, 250), font=small)
        dr.text((6, gb - 16), 'list B', fill=(110, 200, 120), font=small)
        end = min(ln, (r + 1) * WRAP)
        for g in (ga, gb):
            dr.line([x0 + r * WRAP, g, x0 + end, g], fill=(90, 90, 110))
        for d in range(r * WRAP, end + 1, 128):
            dr.line([x0 + d, gb + 1, x0 + d, gb + 5], fill=(170, 170, 170))
            dr.text((x0 + d - 10, gb + 6), str(d), fill=(170, 170, 170), font=small)
        fin = ln - 0x48
        if r * WRAP <= fin < (r + 1) * WRAP:
            dr.line([x0 + fin, y0 + 2, x0 + fin, gb], fill=(230, 80, 80), width=2)
        for lst, base, colour in ((lb, gb, (110, 200, 120)), (la, ga, (150, 190, 250))):
            for d, y, s, fl, a in lst:
                if not r * WRAP - 64 <= d < (r + 1) * WRAP:
                    continue
                pic = tm.bank(sp, menu, s, fl)
                if pic:
                    tm.blit(px, im.size, pic, x0 + d, base, y, False, colour)
                if a is not None:
                    dr.rectangle([x0 + d, base + 2, x0 + d + 3, base + 5], fill=(230, 200, 60))
        for mt, d, text in MARKS:
            if mt == t and r * WRAP <= d < (r + 1) * WRAP:
                x = x0 + d
                dr.line([x, y0 + 2, x, ga], fill=(250, 160, 40), width=2)
                w = dr.textlength(text, font=small)
                tx = x + 4 if x + 4 + w < 1046 else x - 4 - w
                dr.text((tx, y0 + 2), text, fill=(250, 170, 60), font=small)
    im.save(out)
    print('%s: %d x %d' % (out, im.size[0], im.size[1]))


if __name__ == '__main__':
    main()

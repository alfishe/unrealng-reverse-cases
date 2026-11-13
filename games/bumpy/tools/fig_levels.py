#!/usr/bin/env python3
"""Draw Bumpy's levels from the resource src/res/levels/levels.txt: one picture a level and a contact sheet.

    python3 tools/fig_levels.py OUTDIR [--level N ...]

OUTDIR/level-NN.png: the 6 x 6 cells of level NN as the screen lays them out (LevelCellAddrs $E131: six columns,
six rows 32 lines apart), each platform a bar coloured by its kind, each wall a bar on the right of its cell, each
object its kind in hex (the prizes, kinds 5 and up, in yellow), the ball's start a circle, the exit cell a frame.
OUTDIR/levels.png: the 100 levels, 10 a row. The platform, wall and object kinds are in src/res/levels/README.md.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as RF  # noqa: E402

CW, CH = 48, 40
PLAT = {1: (200, 200, 200), 2: (120, 200, 255), 3: (80, 160, 255), 4: (40, 100, 255), 5: (255, 140, 200),
        6: (120, 255, 120), 7: (40, 180, 40), 8: (255, 110, 0), 9: (255, 60, 0), 10: (170, 90, 40),
        11: (255, 255, 255), 12: (255, 0, 0)}
WALL = {1: (230, 200, 60), 2: (200, 160, 40), 3: (170, 120, 20), 4: (160, 160, 160)}


def level_image(lv):
    img = Image.new('RGB', (6 * CW + 8, 6 * CH + 20), (0, 0, 40))
    d = ImageDraw.Draw(img)
    d.text((4, 2), 'level %02d  prizes %d' % (lv['level'], lv['prizes']), fill=(255, 255, 255))
    for c in range(36):
        row, col = divmod(c, 6)
        x, y = 4 + col * CW, 18 + row * CH
        p, w, o = lv['cells'][c] & 15, lv['cells'][c] >> 4, lv['objects'][c]
        if c == lv['exit']:
            d.rectangle((x + 2, y + 2, x + CW - 3, y + CH - 3), outline=(255, 255, 255))
        if p:
            d.rectangle((x + 4, y + CH - 9, x + CW - 5, y + CH - 4), fill=PLAT.get(p, (255, 0, 255)))
            d.text((x + 5, y + CH - 20), '%X' % p, fill=PLAT.get(p, (255, 0, 255)))
        if w and col < 5:
            d.rectangle((x + CW - 3, y + 6, x + CW + 1, y + CH - 4), fill=WALL.get(w, (255, 0, 255)))
        if o:
            d.text((x + 22, y + 8), '%02X' % o, fill=(255, 255, 0) if o >= 5 else (0, 255, 255))
        if c == lv['start']:
            d.ellipse((x + 8, y + 8, x + 18, y + 18), outline=(255, 120, 255), width=2)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('outdir')
    ap.add_argument('--level', type=int, nargs='*')
    a = ap.parse_args()
    levels = RF.levels_parse(open(os.path.join(RF.RES, 'levels', 'levels.txt'), 'rb').read())
    os.makedirs(a.outdir, exist_ok=True)
    imgs = []
    for lv in levels:
        im = level_image(lv)
        imgs.append(im)
        if a.level is None or lv['level'] in a.level:
            im.save(os.path.join(a.outdir, 'level-%02d.png' % lv['level']))
    w, h = imgs[0].size
    sheet = Image.new('RGB', (10 * w, 10 * h), (0, 0, 0))
    for i, im in enumerate(imgs):
        sheet.paste(im, ((i % 10) * w, (i // 10) * h))
    sheet.save(os.path.join(a.outdir, 'levels.png'))
    print('fig_levels: %d levels to %s' % (len(imgs), a.outdir))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 01 figure: the thirteen maps of the '99, the built-in one and the twelve LOAD MAP files
(docs/img/design/maps.png).

Each map is BuildMap's 512 x 16 cells drawn as tools/zs_level.py preview draws it: four strips of 128 columns
(the radar's width), the player's warbase green, the enemy's warbases yellow, the factories magenta, scenery in
blues (low, flat, high) and posts white. The counts under each come from the map's own lists (zs_level.lists):
warbases, factories, capture points (the tail byte $1F3; the built-in level: the code's operand, 2).

    python3 tools/fig_zs_maps.py --out docs/img/design/maps.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zs_level as L  # noqa: E402
from fig_common import font  # noqa: E402

BG, FG, DIM = (21, 22, 27), (230, 230, 230), (184, 188, 200)


def counts(data):
    ls, _ = L.lists(data)
    war = fac = 0
    for kind, _, _, recs, _ in ls:
        if kind == 'bases':
            for t, _, _ in recs:
                war, fac = (war + 1, fac) if t == 0 else (war, fac + 1)
    return war, fac


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    shapes = L.game_shapes()
    names = ['builtin'] + [f'NELEV_{i:02d}' for i in range(12)]
    cols, w, h, cap, pad = 3, 384, 201, 36, 14
    head = 64
    rows = (len(names) + cols - 1) // cols
    legend = 30
    sheet = Image.new('RGB', (cols * (w + pad) + pad, head + rows * (h + cap + pad) + legend), BG)
    d = ImageDraw.Draw(sheet)
    f_title, f_cap = font(17), font(13)
    d.text((pad, 10), "The '99's thirteen maps, 512 x 16 cells each in four strips of 128: the built-in one spells "
           "ЗАГРУЗИСЬ,", fill=FG, font=f_title)
    d.text((pad, 34), "the twelve LOAD MAP files hold 3 to 16 warbases (yellow, ours green) and 28 capture points "
           "but NELEV_08's 27", fill=FG, font=f_title)
    for i, n in enumerate(names):
        data = L.parse(open(os.path.join(L.MAPS, n + '.txt'), encoding='utf-8').read(), n)
        img = L.preview(data[:L.AREA], shapes)
        war, fac = counts(data)
        points = data[0x1F3] if len(data) == L.FILE else 2
        x, y = pad + (i % cols) * (w + pad), head + (i // cols) * (h + cap + pad)
        sheet.paste(img, (x, y))
        label = 'built-in ($BDA9 in the game)' if n == 'builtin' else n + '.N'
        d.text((x, y + h + 4), f'{label}: {war} warbases, {fac} factories, {points} points', fill=FG, font=f_cap)
    ly = sheet.height - legend + 6
    x = pad
    for name, key in (("our warbase", 'player'), ("the enemy's warbases", 'enemy'), ('factories', 'factory'),
                      ('low scenery', 'low'), ('flat', 'flat'), ('high (tall blocks)', 'high'), ('posts', 'post'),
                      ('ground', 'ground')):
        d.rectangle([x, ly + 2, x + 14, ly + 16], fill=L.COLOURS[key], outline=DIM)
        d.text((x + 20, ly + 1), name, fill=FG, font=f_cap)
        x += 28 + int(d.textlength(name, font=f_cap))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    sheet.save(a.out)
    print(a.out, sheet.size)


if __name__ == '__main__':
    main()

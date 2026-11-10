#!/usr/bin/env python3
"""The cast (doc 1.5): the resource sheets of src/res scaled up on one 1050 px page, each with its caption.

    python3 tools/fig_cast.py docs/img/play/cast.png

The sheets are the source's own (src/res/sprites/*.png, src/res/graphics/EdPieces.png), so the figure shows exactly
the bytes the build assembles; each is scaled by a whole factor with nearest-neighbour pixels.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

WIDTH, GAP, CAP = 1050, 14, 40
ROWS = [
    [('sprites/Droid.png', 2, 'droid: walk 0-7, turn 8-9, front 10, side 11-13'),
     ('sprites/Enemies.png', 2, 'the 9 enemy kinds, the explosion'),
     ('sprites/Objects.png', 2, '5 object kinds, death, blast')],
    [('sprites/Patrollers.png', 3, 'the patroller, right and left'),
     ('graphics/EdPieces.png', 3, 'the 50 ED pieces: 10 columns x 5 rows')],
    [('sprites/HudIcons.png', 4, 'HUD: weapons 0-3, GEN 19, energy, source'),
     ('sprites/Materialise.png', 4, 'an enemy materialising')],
    [('sprites/Probe.png', 4, "weapon 3's probe"),
     ('sprites/ShotGraphics.png', 4, 'the bolts of weapons 1 and 2')],
]


def main():
    out = sys.argv[1]
    f = kitlib.font(13)
    title = kitlib.font(17)
    rows = []
    for row in ROWS:
        cells = []
        for path, k, caption in row:
            im = Image.open(os.path.join(CASE, 'src', 'res', path)).convert('RGB')
            cells.append((im.resize((im.width * k, im.height * k), Image.NEAREST), caption, path, k))
        rows.append(cells)
    height = 40 + sum(max(c[0].height for c in r) + CAP + GAP for r in rows)
    img = Image.new('RGB', (WIDTH, height), kitlib.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((GAP, 10), 'The cast, from the source resources (src/res), scaled by the factor shown', font=title,
           fill=kitlib.TEXT)
    y = 40
    for r in rows:
        x = GAP
        for im, caption, path, k in r:
            w = max(im.width, int(d.textlength(caption, font=f)), int(d.textlength(f'{path} x{k}', font=f)))
            d.text((x, y), caption, font=f, fill=kitlib.TEXT)
            d.text((x, y + 17), f'{path} x{k}', font=f, fill=(150, 150, 165))
            img.paste(im, (x, y + CAP))
            x += w + 3 * GAP
        y += max(c[0].height for c in r) + CAP + GAP
    img.save(out)
    print(out, img.size)


if __name__ == '__main__':
    main()

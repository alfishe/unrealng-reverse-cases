#!/usr/bin/env python3
"""A first sprite sheet from the data (stage 1): the 41 object sprites (`$6CB0` + 56 x k, 16 x 14 pixels in nibbles,
ink from the colour table `$C6F6` + k) and the platform sprites the platform handlers (`$C5A8`) draw, each with its
address, from the image as loaded (tools/bumpydata.py).

    python3 tools/fig_sprites.py [--out docs/img/sprites/sheet.png]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import bumpydata as D  # noqa: E402
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

BG, TEXT, DIM, CELL = (24, 24, 30), (235, 235, 235), (170, 170, 180), (0, 0, 0)
PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0),
          (255, 255, 255)]
NAMES = {1: 'hammer', 2: 'key', 3: 'water'}
EXTRA = [('spikes', 0x814D, 6, 5), ('EXIT sign', 0x6698, 8, 7)]


def ink(attr):
    return (BRIGHT if attr & 0x40 else PAL)[attr & 7]


def sprite(rows, colour, zoom):
    im = Image.new('RGB', (len(rows[0]), len(rows)), CELL)
    px = im.load()
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v:
                px[x, y] = colour
    return im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'sprites', 'sheet.png'))
    a = p.parse_args()
    img = D.image()
    f_title, f_lab, f_note = K.font(24), K.font(17), K.font(15)
    zoom, cols, cw, ch = 3, 9, 102, 96
    orows = (41 + cols - 1) // cols
    platforms = [(f'type {t}', addr, w, r) for t, (addr, w, r) in sorted(D.PLATFORMS.items())] + EXTRA
    pcols, pw, ph = 5, 186, 76
    prows = (len(platforms) + pcols - 1) // pcols
    width = max(cols * cw, pcols * pw) + 24
    height = 96 + orows * ch + 40 + prows * ph + 10
    out = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'Sprites from the data (x3): objects and platforms', fill=TEXT, font=f_title)
    d.text((12, 44), 'Objects k = 0-40 at $6CB0 + 56k, ink from $C6F6 + k; level records name objects 1-40.',
           fill=DIM, font=f_note)
    y0 = 70
    d.text((12, y0), 'objects', fill=TEXT, font=f_lab)
    for k in range(41):
        x, y = 12 + (k % cols) * cw, y0 + 26 + (k // cols) * ch
        out.paste(sprite(D.object_sprite(img, k), ink(D.object_colour(img, k)), zoom), (x, y))
        d.text((x, y + 14 * zoom + 4), f'{k} ${D.OBJ_SPRITES + 56 * k:04X}', fill=DIM, font=f_note)
    y0 += 26 + orows * ch + 6
    d.text((12, y0), 'platforms (by type, low nibble of a cell) and two more sprites; white ink, the colour is the '
           'attributes', fill=TEXT, font=f_note)
    for k, (name, addr, w, r) in enumerate(platforms):
        x, y = 12 + (k % pcols) * pw, y0 + 26 + (k // pcols) * ph
        out.paste(sprite(D.nibble_sprite(img, addr, w, r), (230, 230, 230), zoom), (x, y))
        d.text((x, y + r * zoom + 4), f'{name} ${addr:04X}', fill=DIM, font=f_note)
    out = out.crop((0, 0, width, y0 + 26 + prows * ph + 6))
    out.save(a.out)
    print(a.out, out.size)


if __name__ == '__main__':
    main()

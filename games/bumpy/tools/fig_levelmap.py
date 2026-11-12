#!/usr/bin/env python3
"""The first level maps drawn from the data (stage 1): each level's 75-byte record (`$8C3C` + 75 x level,
tools/bumpydata.py) as its 6 x 6 cells, a cell 40 x 32 pixels: the platform by its type (low nibble; the sprite of
its handler in white, spikes red, type 10 as a red brick block), a wall (high nibble 1-4) as a magenta bar at the
cell's left, the object (bytes 39-74) as its sprite in its colour, the ball's start cell (byte 36) as a white frame.
The places are the cell grid's, not yet the handlers' exact offsets. 25 levels a figure, each with its record's
address.

    python3 tools/fig_levelmap.py [--out docs/img/maps]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import bumpydata as D  # noqa: E402
import kitlib as K  # noqa: E402
from fig_sprites import ink  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

BG, TEXT, DIM = (24, 24, 30), (235, 235, 235), (170, 170, 180)
WHITE, RED, MAGENTA = (230, 230, 230), (230, 40, 40), (210, 0, 210)


def blit(px, rows, x0, y0, colour):
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v:
                px[x0 + x, y0 + y] = colour


def draw_level(img, n):
    lv = D.level(img, n)
    im = Image.new('RGB', (256, 192), (0, 0, 0))
    px = im.load()
    d = ImageDraw.Draw(im)
    spikes = D.nibble_sprite(img, 0x814D, 6, 5)
    for cell in range(36):
        r, c = divmod(cell, 6)
        x, y = 8 + 40 * c, 32 * r
        t, w, k = lv['platform'][cell], lv['wall'][cell], lv['object'][cell]
        if t == 10:
            d.rectangle((x, y + 4, x + 31, y + 31), fill=(150, 20, 20))
        elif t in D.PLATFORMS:
            addr, wn, rows = D.PLATFORMS[t]
            sp = D.nibble_sprite(img, addr, wn, rows)
            blit(px, sp, x + (32 - 4 * wn) // 2, y + 32 - rows, WHITE)
            if t in (8, 9):
                blit(px, spikes, x + 4, y + 32 - rows - 5, RED)
        if w:
            d.rectangle((x - 4, y, x - 1, y + 31), fill=MAGENTA)
        if k:
            blit(px, D.object_sprite(img, k), x + 8, y + 12, ink(D.object_colour(img, k)))
        if cell == lv['start']:
            d.rectangle((x + 6, y + 10, x + 25, y + 27), outline=WHITE)
    d.rectangle((0, 0, 3, 191), fill=(200, 200, 0))
    d.rectangle((248, 0, 251, 191), fill=(200, 200, 0))
    return im, lv['address']


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'maps'))
    a = p.parse_args()
    img = D.image()
    tw, th, cols = 192, 144, 5
    f_title, f_lab, f_note = K.font(24), K.font(17), K.font(15)
    for part in range(4):
        levels = list(range(part * 25, part * 25 + 25))
        top = 78
        w = cols * (tw + 12) + 12
        h = top + 5 * (th + 30) + 8
        out = Image.new('RGB', (w, h), BG)
        d = ImageDraw.Draw(out)
        d.text((12, 10), f'Levels {levels[0]}-{levels[-1]} drawn from their records (half size)', fill=TEXT,
               font=f_title)
        d.text((12, 44), 'Platforms by type, walls magenta, objects, the start cell framed; the record address',
               fill=DIM, font=f_note)
        for k, n in enumerate(levels):
            im, addr = draw_level(img, n)
            x, y = 12 + (k % cols) * (tw + 12), top + (k // cols) * (th + 30)
            d.text((x, y), f'level {n}  ${addr:04X}', fill=DIM, font=f_lab)
            out.paste(im.resize((tw, th), Image.LANCZOS), (x, y + 24))
        path = os.path.join(a.out, f'data-levels-{levels[0]:02d}-{levels[-1]:02d}.png')
        out.save(path)
        print(path, out.size)


if __name__ == '__main__':
    main()

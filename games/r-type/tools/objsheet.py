#!/usr/bin/env python3
"""Draws a level's character-cell objects (the boss, the gun towers, the scenery pieces drawn into the playfield)
from the level block of the original tape: no emulator, only the bytes.

    python3 tools/objsheet.py LEVEL OUT.png [--order rows|columns] [--scale 2]

The level body loads to `$C4AE`; its word at `$C4BA` (ObjTable) points at 4-byte entries, one per object number n
(from 1; `$8E92`: (n - 1) * 4): the width and the height in character cells, then the address of the cells. A
cell is `$36` (empty: `$8D0B` skips it) or 9 bytes: the attribute, then 8 pixel bytes (`$8EA2`, `$8D2E`).
Entries of size 0 x 0 are left out.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import levelmap as L  # noqa: E402


def cells(lv, a, w, h):
    out = []
    for _ in range(w * h):
        if lv.byte(a) == 0x36:
            out.append(None)
            a += 1
        else:
            out.append(bytes(lv.d[a - L.BASE:a - L.BASE + 9]))
            a += 9
    return out, a


def draw(lv, w, h, cl, order):
    im = Image.new('RGB', (w * 8, h * 8), (90, 90, 90))
    px = im.load()
    for i, c in enumerate(cl):
        if c is None:
            continue
        cx, cy = (i % w, i // w) if order == 'rows' else (i // h, i % h)
        attr = c[0]
        pal = L.BRI if attr & 0x40 else L.PAL
        ink, paper = pal[attr & 7], pal[(attr >> 3) & 7]
        for y in range(8):
            for x in range(8):
                px[cx * 8 + x, cy * 8 + y] = ink if c[1 + y] & (0x80 >> x) else paper
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', type=int)
    ap.add_argument('out')
    ap.add_argument('--order', default='rows')
    ap.add_argument('--scale', type=int, default=2)
    a = ap.parse_args()
    lv = L.Level(L.levels()[a.level])
    t = lv.word(0xC4BA)
    ents = []
    n = 1
    while True:
        e = t + (n - 1) * 4
        w, h, p = lv.byte(e), lv.byte(e + 1), lv.word(e + 2)
        if w > 32 or h > 24 or not (L.BASE <= p < t):
            break
        if w and h:
            cl, end = cells(lv, p, w, h)
            ents.append((n, w, h, p, draw(lv, w, h, cl, a.order)))
        n += 1
    last = n - 1
    f = L.font(13)
    s = a.scale
    width = 900
    x = y = 0
    rowh = 0
    place = []
    for n, w, h, p, im in ents:
        bw, bh = max(im.width * s, 100) + 10, im.height * s + 34
        if x + bw > width:
            x, y, rowh = 0, y + rowh, 0
        place.append((x, y, n, w, h, p, im))
        x += bw
        rowh = max(rowh, bh)
    out = Image.new('RGB', (width, y + rowh + 26), (255, 255, 255))
    d = ImageDraw.Draw(out)
    d.text((4, 4), f'Level {a.level}: the objects of the table at ${t:04X} ({len(ents)} drawn, empty cells grey), x{s}',
           fill=(0, 0, 0), font=f)
    for x, y, n, w, h, p, im in place:
        out.paste(im.resize((im.width * s, im.height * s), Image.NEAREST), (x + 4, y + 24))
        d.text((x + 4, y + 26 + im.height * s), f'{n}: {w}x{h} ${p:04X}', fill=(0, 0, 0), font=f)
    out.save(a.out)
    print(len(ents), 'objects', f'table ${t:04X}', 'entries', last)


if __name__ == '__main__':
    main()

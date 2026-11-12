#!/usr/bin/env python3
"""A first sprite sheet of a level drawn from its data (stage 1). The sprites are in the level block, from `$C26D` to
the base of the maps (`$C204`), 128 bytes each: the rows to skip, the rows drawn (at most 24), then 6 bytes a row
that the blitter `$7329` pops as three data and three mask bytes (bytes 2, 1, 0 the data of columns 0, 1, 2; bytes 3,
5, 4 their masks: a screen byte becomes (byte AND mask) OR data). Rick's record `$9BAB` (+1 x, +2 y, +4 the sprite
address, +6 bit 7 mirror through the table at `$6500`) points into it. Drawn on grey: data bits white, cleared mask
bits black (the outline), the rest transparent; each sprite labelled with its number and address.

    python3 tools/sprite_sheet.py LEVEL OUT.png [--cols 12] [--scale 3]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import image as I  # noqa: E402
import kitlib as K  # noqa: E402

FIRST, SIZE = 0xC26D, 0x80


def sprite(mem, a):
    skip, rows = mem[a], mem[a + 1]
    im = Image.new('RGB', (24, 24), (110, 110, 110))
    px = im.load()
    for r in range(rows):
        b = mem[a + 2 + 6 * r:a + 8 + 6 * r]
        data, mask = (b[2], b[1], b[0]), (b[3], b[5], b[4])
        for c in range(3):
            for x in range(8):
                bit = 0x80 >> x
                if data[c] & bit:
                    px[8 * c + x, skip + r] = (255, 255, 255)
                elif not mask[c] & bit:
                    px[8 * c + x, skip + r] = (0, 0, 0)
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', type=int)
    ap.add_argument('out')
    ap.add_argument('--cols', type=int, default=12)
    ap.add_argument('--scale', type=int, default=3)
    a = ap.parse_args()
    mem = I.image(None if a.level == 1 else a.level)
    end = mem[0xC204] | mem[0xC205] << 8
    n = (end - FIRST) // SIZE
    s, lab = a.scale, 26
    cw, ch = 24 * s + 14, 24 * s + lab + 8
    rows = (n + a.cols - 1) // a.cols
    im = Image.new('RGB', (a.cols * cw, rows * ch), (40, 40, 40))
    d = ImageDraw.Draw(im)
    f = K.font(15)
    for i in range(n):
        addr = FIRST + SIZE * i
        x, y = (i % a.cols) * cw + 4, (i // a.cols) * ch + 4
        im.paste(sprite(mem, addr).resize((24 * s, 24 * s), Image.NEAREST), (x, y + lab))
        d.text((x, y), f'{i} {addr:04X}', fill=(255, 255, 255), font=f)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    im.save(a.out)
    print(a.out, n, 'sprites', im.size)


if __name__ == '__main__':
    main()

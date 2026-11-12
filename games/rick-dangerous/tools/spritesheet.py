#!/usr/bin/env python3
"""A first sprite sheet, drawn from the game image's data alone (tools/image.py).

    python3 tools/spritesheet.py work/mkgame/original.bin docs/img/sprites/sheet.png [--first 8401] [--count N]

The format, read from the sprite drawer `$A419-$A47x`: an object record (30 bytes from `$EA8E`) holds at bytes 4-5
the address of its frame; the drawer points SP at it and pops 21 rows of six bytes (B = `$15`): per row three
mask-and-pixel pairs for a 24-pixel row, popped as HL, BC, DE and used as (B and, C or), (D and, H or), (E and, L or)
on three bytes of the char buffer; with bit 0 of the record's byte 6 set it swaps the outer pairs and mirrors each
byte through the bit-reversal table at `$5B00` (the sprite faces the other way). So a frame is 126 bytes, and the
frames the play recordings point at lie 126 bytes apart from `$8401` (Rick `$84FD` = `$8401` + 2 x 126). Each frame
is drawn with its pixels black on white and the masked-off area grey, labelled with its index and address.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

B = 0x5B00
SIZE = 126


def frame(img, adr):
    """24 x 21 pixels: 0 transparent, 1 background kept by the mask, 2 ink"""
    rows = []
    for r in range(21):
        l, h, c, b, e, d = img[adr - B + r * 6:adr - B + r * 6 + 6]
        row = []
        for mask, pix in ((b, c), (d, h), (e, l)):
            for x in range(8):
                bit = 0x80 >> x
                row.append(2 if pix & bit else (0 if mask & bit else 1))
        rows.append(row)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('out')
    ap.add_argument('--first', default='8401')
    ap.add_argument('--count', type=int, default=0, help='frames (default 54: $8401-$9E94; what follows is not sprite data)')
    ap.add_argument('--cols', type=int, default=12)
    ap.add_argument('--scale', type=int, default=3)
    a = ap.parse_args()
    img = open(a.image, 'rb').read()
    first = int(a.first, 16)
    count = a.count or 54
    s, cw, ch = a.scale, 24 * a.scale + 12, 21 * a.scale + 34
    rows = (count + a.cols - 1) // a.cols
    out = Image.new('RGB', (a.cols * cw + 12, rows * ch + 50), (255, 255, 255))
    d = ImageDraw.Draw(out)
    f = K.font(14)
    d.text((8, 8), f'Sprite frames, 24 x 21, 126 bytes each from ${first:04X} (index: address)', fill=(0, 0, 0),
           font=K.font(20))
    colours = {0: (255, 255, 255), 1: (200, 200, 200), 2: (0, 0, 0)}
    for k in range(count):
        adr = first + k * SIZE
        x0, y0 = 8 + (k % a.cols) * cw, 44 + (k // a.cols) * ch
        for y, row in enumerate(frame(img, adr)):
            for x, v in enumerate(row):
                d.rectangle([x0 + x * s, y0 + y * s, x0 + x * s + s - 1, y0 + y * s + s - 1], fill=colours[v])
        d.text((x0, y0 + 21 * s + 2), f'{k}: ${adr:04X}', fill=(0, 0, 160), font=f)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    out.save(a.out)
    print(a.out, out.size, count, 'frames')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A first sprite sheet of MASK III from the loaded image (stage 1).

    python3 tools/spritesheet.py work/mkgame/original.bin OUT.png

The objects are character graphics, 8 bytes a cell, a frame's cells down the columns first. Matt: 8 frames of 4 x 4
cells (128 bytes) at `$CD60` (`$A37E`-`$A38E`: frame = (x / 4) & 7, 128 bytes a frame from `$CD60`); the other
objects: 2 x 2 cells (32 bytes) from `$D160` to `$DF7F` (`$A353`, `$A365` pick `$D160`, `$D1E0` for some kinds;
`$AA35` takes 32-byte frames from `$D580`; `$A3A5` copies one frame to `$DF80` through a random mask).
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

INK, PAPER, BG = (240, 240, 240), (0, 0, 0), (40, 40, 48)


def frame(img, addr, w, h):
    im = Image.new('RGB', (w * 8, h * 8), PAPER)
    px = im.load()
    for c in range(w * h):
        cx, cy = c // h, c % h
        for y in range(8):
            b = img[addr + 8 * c + y]
            for x in range(8):
                if b & (0x80 >> x):
                    px[cx * 8 + x, cy * 8 + y] = INK
    return im


def main():
    img = open(sys.argv[1], 'rb').read()
    scale, font = 4, kitlib.font(22)
    per = 16
    small = [(a, frame(img, a, 2, 2)) for a in range(0xD160, 0xDF80, 32)]
    rows = (len(small) + per - 1) // per
    cell = 16 * scale + 12
    width = per * cell + 16
    top = 40 + 32 * scale + 50
    sheet = Image.new('RGB', (width, top + rows * (cell + 26) + 10), BG)
    d = ImageDraw.Draw(sheet)
    d.text((8, 6), 'Matt: 8 frames of 4 x 4 cells at $CD60 (128 bytes each)', fill=INK, font=font)
    for k in range(8):
        a = 0xCD60 + 128 * k
        sheet.paste(frame(img, a, 4, 4).resize((32 * scale, 32 * scale), Image.NEAREST), (8 + k * (32 * scale + 12), 36))
    d.text((8, top - 36), 'objects: 2 x 2 cells (32 bytes) from $D160 to $DF7F; the address under each', fill=INK, font=font)
    for k, (a, im) in enumerate(small):
        x, y = 8 + (k % per) * cell, top + (k // per) * (cell + 26)
        sheet.paste(im.resize((16 * scale, 16 * scale), Image.NEAREST), (x, y))
        d.text((x, y + 16 * scale + 2), f'${a:04X}', fill=(170, 170, 170), font=kitlib.font(16))
    sheet.save(sys.argv[2])
    print(sys.argv[2], sheet.size, len(small), 'objects')


if __name__ == '__main__':
    main()

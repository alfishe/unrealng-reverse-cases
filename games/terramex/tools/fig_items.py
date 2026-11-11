#!/usr/bin/env python3
"""The 32 item sprites drawn from the image as loaded (work/mkgame/original.bin): 72 bytes an item at `$8400 + i * 72`,
24 x 24 pixels as three columns of 24 bytes (column-major; DrawItem's address `$8400 + index * 72`, `$9DE3`). The names
are the SkoolKit disassembly's (docs/Items-Format.md), to be checked in play.

    python3 tools/fig_items.py work/mkgame/original.bin docs/img/sprites/items.png
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

NAMES = ['Unicycle', 'Flashgun', 'Cricket Ball', 'Spurs', 'Beer Barrel', 'Umbrella', 'Bellows', 'Party Manifesto',
         'Cannon', 'Barrel Medium', 'Vacuum Cleaner', 'ACME Bridge', 'Flute', 'Silver Lining', 'Spring', 'Formula',
         'Switch', 'Button', 'Battery', 'Coat Hanger', 'Trampoline', 'Atomic Pile', 'Anti Rad. Pills', 'Cup of tea',
         'Energy Crystal', 'Busket', 'Balloon', 'Barrel Big', 'Barrel Small', 'Silver Cross', 'Busket', 'Lift']


def item(m, i, scale):
    a = 0x8400 + i * 72
    im = Image.new('RGB', (24, 24), (0, 0, 0))
    px = im.load()
    for c in range(3):
        for y in range(24):
            b = m[a + c * 24 + y]
            for x in range(8):
                if b & (0x80 >> x):
                    px[c * 8 + x, y] = (235, 235, 235)
    return im.resize((24 * scale, 24 * scale), Image.NEAREST)


def main():
    m = open(sys.argv[1], 'rb').read()
    scale, cw, ch = 4, 200, 140
    f, fs = K.font(22), K.font(17)
    o = Image.new('RGB', (8 * cw, 50 + 4 * ch), (24, 24, 28))
    d = ImageDraw.Draw(o)
    d.text((6, 8), 'The 32 items: 72 bytes each at $8400 + i * 72, 24 x 24 pixels in three byte columns', font=f,
           fill=(235, 235, 235))
    for i in range(32):
        x, y = (i % 8) * cw, 50 + (i // 8) * ch
        o.paste(item(m, i, scale), (x + (cw - 96) // 2, y))
        d.text((x + 6, y + 100), f'{i} ${0x8400 + i * 72:04X}', font=fs, fill=(255, 220, 90))
        d.text((x + 6, y + 118), NAMES[i], font=fs, fill=(200, 200, 200))
    o.save(sys.argv[2])


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A first sprite sheet of part 1 from its data (stage 1): Rex ($80F2: 3 bytes x 16 pixels, 48 bytes a picture, each pose
in four pre-shifts 0, 2, 4, 6 pixels to the right, the offset table `$AE5D` = 0, 0, 48, 48, 96, 96, 144, 144; drawn by
DrawSprite `$B258`, which ORs W bytes x H rows into the back buffer), the shield bubble ($88F2, 4 x 21, offsets
`$AE65`), and the object sprites: the banks the object records at `$5E66` (24 bytes each, the count in `$A092`) point
to in the RZX run rex1.rzx (IX+$16/$17 the bank, IX+$0E/$0F the width in bytes and the height), each bank shown as
its first pictures in a row.

    python3 tools/sprites.py work/mkgame/original.bin docs/img/sprites/part1-sheet.png
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

# (label, address, width in bytes, height, pictures, step in bytes between the pictures shown)
ROWS = [('Rex, four shifts', 0x80F2, 3, 16, 4, 48),
        ('the shield bubble', 0x88F2, 4, 21, 1, 84),
        ('bank $7F72', 0x7F72, 3, 16, 8, 48),
        ('bank $8032', 0x8032, 3, 16, 4, 48),
        ('bank $83F2', 0x83F2, 3, 16, 4, 48),
        ('bank $8632', 0x8632, 3, 16, 4, 48),
        ('bank $8B5A', 0x8B5A, 2, 16, 8, 32),
        ('bank $8D8A', 0x8D8A, 3, 16, 4, 48),
        ('bank $9022', 0x9022, 2, 8, 8, 16),
        ('bank $90A2', 0x90A2, 3, 12, 4, 36),
        ('bank $9132', 0x9132, 2, 8, 8, 16)]
S = 3


def main():
    m = open(sys.argv[1], 'rb').read()
    f = kitlib.font(20)
    rowh = [h * S + 30 for _, _, _, h, _, _ in ROWS]
    W = 330 + 8 * (4 * 8 * S + 12)
    im = Image.new('RGB', (W, sum(rowh) + 10), (40, 40, 40))
    dr = ImageDraw.Draw(im)
    y = 5
    for (label, a, w, h, n, step), rh in zip(ROWS, rowh):
        dr.text((8, y + 6), label, fill='white', font=f)
        x = 330
        for k in range(n):
            base = a + k * step
            dr.text((x, y), f'${base:04X}', fill=(200, 200, 120), font=kitlib.font(14))
            for r in range(h):
                for c in range(w):
                    v = m[base + r * w + c]
                    for bit in range(8):
                        col = (255, 255, 255) if v & (128 >> bit) else (0, 0, 0)
                        dr.rectangle((x + (c * 8 + bit) * S, y + 18 + r * S, x + (c * 8 + bit) * S + S - 1,
                                      y + 18 + r * S + S - 1), fill=col)
            x += 4 * 8 * S + 12
        y += rh
    im.save(sys.argv[2])
    print(sys.argv[2], im.size)


if __name__ == '__main__':
    main()

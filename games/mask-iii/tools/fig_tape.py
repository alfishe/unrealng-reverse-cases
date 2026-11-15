#!/usr/bin/env python3
"""Doc 3's tape picture: the blocks of "Mask III.tzx" on a time line at ROM speed, each with its pause, where it loads
and what it is (the times of doc 3, 3.1, from tools/tzxblocks.py list), and the loading screen it ends with.

    python3 tools/fig_tape.py      # docs/img/load/tape.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'load')
BG, FG, DIM, PAUSE = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 72)

# (block, what, loads at, bytes, seconds, pause after, colour)
BLOCKS = [
    (1, 'header "MASK3"', '', 17, 5.08, 1.015, (120, 120, 140)),
    (2, 'the BASIC', 'PROG', 36, 2.20, 6.073, (90, 160, 230)),
    (3, 'header "loader"', '', 17, 5.09, 1.010, (120, 120, 140)),
    (4, 'the loader', '$FF00', 256, 3.36, 7.425, (240, 200, 80)),
    (5, 'the screen', '$4000', 6912, 37.04, 8.282, (90, 200, 120)),
    (6, 'the game', '$6000-$FDFF', 40448, 218.85, 9.149, (220, 90, 90)),
    (7, 'the music, 128K only', 'RAM 4 $C000', 4000, 23.24, 9.117, (180, 110, 220)),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    big, mid = kitlib.font(17), kitlib.font(14)
    total = sum(b[4] + b[5] for b in BLOCKS)
    left, width = 20, 1010
    scale = width / total
    im = Image.new('RGB', (1050, 420), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), f'"Mask III.tzx" at ROM speed: 7 standard blocks, {total:.1f} s with the pauses', fill=FG, font=big)
    y0, h = 60, 60
    x = left
    for n, what, at, size, sec, pause, col in BLOCKS:
        w = sec * scale
        d.rectangle((x, y0, x + w, y0 + h), fill=col, outline=BG)
        if w > 26:
            d.text((x + 4, y0 + 20), str(n), fill=(15, 15, 20), font=big)
        x += w
        pw = pause * scale
        d.rectangle((x, y0 + h // 3, x + pw, y0 + 2 * h // 3), fill=PAUSE)
        x += pw
    for t in range(0, int(total) + 1, 30):
        tx = left + t * scale
        d.line((tx, y0 + h + 4, tx, y0 + h + 10), fill=DIM)
        d.text((tx - 8, y0 + h + 12), f'{t}', fill=DIM, font=mid)
    d.text((left + width - 70, y0 + h + 30), 'seconds', fill=DIM, font=mid)
    y = y0 + h + 60
    d.text((20, y), 'block', fill=DIM, font=mid)
    d.text((90, y), 'what', fill=DIM, font=mid)
    d.text((330, y), 'loads at', fill=DIM, font=mid)
    d.text((500, y), 'bytes', fill=DIM, font=mid)
    d.text((600, y), 'seconds', fill=DIM, font=mid)
    d.text((700, y), 'pause after', fill=DIM, font=mid)
    for i, (n, what, at, size, sec, pause, col) in enumerate(BLOCKS):
        yy = y + 24 + i * 24
        d.rectangle((20, yy + 2, 40, yy + 18), fill=col)
        d.text((50, yy), str(n), fill=FG, font=mid)
        d.text((90, yy), what, fill=FG, font=mid)
        d.text((330, yy), at, fill=FG, font=mid)
        d.text((500, yy), f'{size}', fill=FG, font=mid)
        d.text((600, yy), f'{sec:.2f}', fill=FG, font=mid)
        d.text((700, yy), f'{pause:.3f}', fill=FG, font=mid)
    d.text((20, y + 24 + 7 * 24 + 6), 'grey bars: the pauses; headers carry 17 bytes; on a 48K the loader stops '
                                      'after block 6', fill=DIM, font=mid)
    im.save(os.path.join(OUT, 'tape.png'))
    print(os.path.join(OUT, 'tape.png'), im.size)


if __name__ == '__main__':
    main()

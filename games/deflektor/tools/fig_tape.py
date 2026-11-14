#!/usr/bin/env python3
"""The tape as a picture (doc 03): the three TZX blocks of orig/Deflektor.tzx on a time line, then the turbo block's
eight loads (src/tape/tape.txt, the loader's order) by bytes, each with its address and what it is.

    python3 tools/fig_tape.py docs/img/load/tape.png
"""
import sys

from PIL import Image, ImageDraw

import figlib

BLOCKS = [  # (name, seconds, colour)
    ('header "DEFLEKTOR"', 5.09, (90, 150, 230)), ('pause', 0.989, (45, 45, 55)),
    ('BASIC + loader 1 (384)', 4.12, (90, 210, 120)), ('pause', 0.986, (45, 45, 55)),
    ('turbo block, 58 316 bytes', 296.74, (230, 90, 160)),
]
LOADS = [  # (address, bytes, what, colour)
    (0xB75A, 0xB869 - 0xB75A, 'loader 2, part 1', (240, 200, 80)),
    (0xB869, 0xB8DD - 0xB869, 'loader 2, part 2', (240, 200, 80)),
    (0xB8DD, 0xBBDF - 0xB8DD, 'loader 2, part 3', (240, 200, 80)),
    (0xB326, 472, 'the script font', (80, 200, 220)),
    (0x998E, 6552, 'the loading script', (170, 120, 220)),
    (0xC000, 0x4000, 'main block 9DF0-DDEF (moved down later)', (230, 90, 160)),
    (0x5C00, 0x4000, 'main block 5C00-9BFF', (230, 90, 160)),
    (0x9C00, 0x1F0, 'main block 9C00-9DEF', (230, 90, 160)),
]


def main():
    out = sys.argv[1]
    W = 1050
    o = Image.new('RGB', (W, 470), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The tape: three blocks, 307.9 s; the turbo block holds eight loads', 17, figlib.ACCENT)
    x0, x1 = 20, W - 20
    total = sum(b[1] for b in BLOCKS)
    y = 50
    figlib.text(d, (x0, y), 'Time line (seconds at ROM speed, tools/tzxblocks.py):', 13, figlib.DIM)
    y += 22
    x = x0
    for name, sec, col in BLOCKS:
        w = max(3, (x1 - x0) * sec / total)
        d.rectangle([x, y, x + w - 1, y + 34], fill=col)
        x += w
    # the small blocks get callouts
    x = x0
    for i, (name, sec, col) in enumerate(BLOCKS):
        w = (x1 - x0) * sec / total
        if name != 'pause':
            if w > 200:
                figlib.text(d, (x + 8, y + 9), f'{name}: {sec:.1f} s', 14, (0, 0, 0))
            else:
                ly = y + 44 + 18 * (i // 2)
                d.line([x + w / 2, y + 34, x + w / 2, ly + 6], fill=col, width=2)
                figlib.text(d, (x + w / 2 + 6, ly - 2), f'{name}: {sec:.2f} s', 13, col)
        x += w
    y += 110
    figlib.text(d, (x0, y), 'The turbo block by bytes, in the order the loader asks for them (src/tape/tape.txt):', 13,
                figlib.DIM)
    y += 22
    tb = sum(l[1] for l in LOADS)
    x = x0
    for i, (addr, n, what, col) in enumerate(LOADS):
        w = (x1 - x0) * n / tb
        d.rectangle([x, y, x + max(2, w) - 2, y + 34], fill=col)
        if w > 150:
            figlib.text(d, (x + 6, y + 9), f'{addr:04X}: {n} bytes', 13, (0, 0, 0))
        x += w
    y += 50
    for i, (addr, n, what, col) in enumerate(LOADS):
        d.rectangle([x0, y + 4, x0 + 12, y + 15], fill=col)
        figlib.text(d, (x0 + 20, y), f'{i + 1}. at {addr:04X}, {n:5d} bytes: {what}', 13, figlib.FG)
        y += 20
    figlib.text(d, (x0, y + 10), f'The eight loads hold {tb} bytes; the block\'s other bytes are the loader\'s padding pulse '
                'pairs and the script engine\'s runs (tools/mktape.py).', 12, figlib.DIM)
    o = o.crop((0, 0, W, y + 40))
    o.save(out)
    print(out, o.size)


if __name__ == '__main__':
    main()

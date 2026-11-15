#!/usr/bin/env python3
"""Doc 2's memory map: the 64 KB in play on a 128K, 4 KB a row, each range coloured by what it holds (the ranges of
doc 2, 2.2, from src/game/game.ann and the loader).

    python3 tools/fig_memmap.py      # docs/img/memory/memmap.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'memory')
BG, FG, DIM = (24, 24, 30), (235, 235, 235), (170, 170, 180)

KINDS = {
    'rom': ((90, 90, 100), 'ROM'),
    'screen': ((70, 120, 200), 'the screen'),
    'zone': ((60, 170, 90), 'zone sets, parked and live'),
    'map': ((200, 160, 60), 'room maps and blocks'),
    'code': ((200, 80, 80), 'code, tables and variables'),
    'sprite': ((170, 90, 200), 'sprites and pictures'),
    'buffer': ((60, 170, 180), 'buffers built at run time'),
    'im2': ((240, 220, 90), 'IM 2 table, stack, JP, flag, JR'),
}

# (from, to inclusive, kind, label)
RANGES = [
    (0x0000, 0x3FFF, 'rom', 'ROM (128K: ROM 1, the 48K BASIC)'),
    (0x4000, 0x5AFF, 'screen', 'screen $4000'),
    (0x5B00, 0x63FF, 'zone', 'zone 1 parked $5B00'),
    (0x6400, 0x6CFF, 'zone', 'zone 2 $6400'),
    (0x6D00, 0x75FF, 'zone', 'zone 3 $6D00'),
    (0x7600, 0x84FF, 'map', 'RoomMaps $7600'),
    (0x8500, 0x90FF, 'map', 'Blocks $8500'),
    (0x9100, 0x9722, 'code', 'entry, interrupt, rooms'),
    (0x9723, 0xA193, 'code', 'menu $9723'),
    (0xA194, 0xAD27, 'code', 'renderer, rooms'),
    (0xAD28, 0xB3EA, 'code', 'objects $AD28'),
    (0xB3EB, 0xBC95, 'code', 'matt $B3EB'),
    (0xBC96, 0xC9E9, 'code', 'objects $BC96'),
    (0xC9EA, 0xCC7F, 'code', 'renderer, main loop'),
    (0xCC80, 0xDF7F, 'sprite', 'sprites $CC80'),
    (0xDF80, 0xDFFF, 'buffer', ''),
    (0xE000, 0xE7FF, 'zone', 'live zone $E000'),
    (0xE800, 0xEDFF, 'buffer', 'SpriteChars $E800'),
    (0xEE00, 0xEEFF, 'buffer', 'attrs'),
    (0xEF00, 0xEFFF, 'zone', 'attrs'),
    (0xF000, 0xF07F, 'buffer', ''),
    (0xF080, 0xF2FF, 'buffer', 'character map $F080'),
    (0xF300, 0xF3BF, 'buffer', 'mirror'),
    (0xF3C0, 0xF5FF, 'buffer', 'dirty map $F3C0'),
    (0xF600, 0xFDFF, 'buffer', 'BuildTables tables $F600'),
    (0xFE00, 0xFF00, 'im2', 'IM 2'),
    (0xFF01, 0xFFFF, 'im2', 'stack'),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    big, mid, small = kitlib.font(17), kitlib.font(14), kitlib.font(14)
    left, width, row_h, gap = 70, 960, 34, 8
    rows = 16
    legend_h = 30 * ((len(KINDS) + 2) // 3)
    im = Image.new('RGB', (1050, 50 + rows * (row_h + gap) + legend_h + 20), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'MASK III in play: the 64 KB, 4 KB a row (doc 2, 2.2; the 128K pages RAM 4 in only in the '
                     'interrupt)', fill=FG, font=big)
    per = 4096 / width
    for r in range(rows):
        y = 44 + r * (row_h + gap)
        d.text((8, y + 9), f'${r * 0x1000:04X}', fill=DIM, font=mid)
        lo, hi = r * 0x1000, r * 0x1000 + 0xFFF
        for a, b, kind, label in RANGES:
            s, e = max(a, lo), min(b, hi)
            if s > e:
                continue
            x0 = left + int((s - lo) / per)
            x1 = left + int((e - lo + 1) / per) - 1
            d.rectangle((x0, y, x1, y + row_h), fill=KINDS[kind][0], outline=BG)
            if label and s == a:
                tw = d.textlength(label, font=small)
                if tw < x1 - x0 - 6:
                    d.text((x0 + 4, y + 10), label, fill=(15, 15, 20), font=small)
    y = 44 + rows * (row_h + gap) + 6
    for i, (kind, (col, name)) in enumerate(KINDS.items()):
        x = 10 + (i % 3) * 345
        yy = y + (i // 3) * 30
        d.rectangle((x, yy + 2, x + 20, yy + 20), fill=col)
        d.text((x + 28, yy + 3), name, fill=FG, font=mid)
    im.save(os.path.join(OUT, 'memmap.png'))
    print(os.path.join(OUT, 'memmap.png'), im.size)


if __name__ == '__main__':
    main()

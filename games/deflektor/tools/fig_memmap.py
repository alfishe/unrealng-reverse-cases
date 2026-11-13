#!/usr/bin/env python3
"""The game's 64 K as a picture (doc 02): one row a kilobyte, each byte coloured by what it holds, from the region
list below (taken from src/game/game.ann's entries); numbered regions and a legend.

    python3 tools/fig_memmap.py docs/img/arch/memmap.png
"""
import sys

from PIL import Image, ImageDraw

import figlib

C = {'rom': (70, 70, 80), 'screen': (90, 150, 230), 'loader': (110, 110, 110), 'picture': (170, 120, 220),
     'table': (240, 200, 80), 'var': (255, 120, 80), 'code': (90, 210, 120), 'level': (230, 90, 160),
     'gfx': (80, 200, 220), 'buffer': (40, 120, 200), 'grid': (250, 160, 40), 'im2': (200, 60, 60),
     'stack': (255, 255, 255), 'spare': (45, 45, 55)}
REGIONS = [
    (0x0000, 0x3FFF, 'rom', 'ROM (the game calls none of it)'),
    (0x4000, 0x5AFF, 'screen', 'the screen: field rows 0-19, panel rows 20-23'),
    (0x5B00, 0x5FFF, 'loader', "the loader's leftovers, never touched"),
    (0x6000, 0x7AFF, 'picture', 'TitlePicture: a whole screen'),
    (0x7B00, 0x7B7F, 'spare', 'Gap7B00: 128 zeros'),
    (0x7B80, 0x7FFF, 'picture', 'PanelPicture: rows 20-23'),
    (0x8000, 0x81B7, 'table', 'beam tables: glyph bytes, bounces, deltas'),
    (0x81B8, 0x81D3, 'var', 'ExplosionSlots'),
    (0x81D4, 0x81FB, 'table', 'the 8 sound records'),
    (0x81FC, 0x81FF, 'var', 'ControlMethod, Level'),
    (0x8200, 0x8373, 'table', 'CellTable: 4 characters a code'),
    (0x8374, 0x8381, 'var', 'the level variables'),
    (0x8382, 0xAD45, 'code', 'the code with its texts and tables'),
    (0xAD46, 0xAD78, 'spare', 'UnusedAD46: 51 zeros'),
    (0xAD79, 0xADEF, 'code', 'TitleTune, PlayNote'),
    (0xADF0, 0xAFFF, 'table', 'TitleTuneData: 176 notes'),
    (0xB000, 0xD1BF, 'level', 'LevelData: 64 slots of 135 bytes'),
    (0xD1C0, 0xD1FF, 'spare', 'SpareD1C0'),
    (0xD200, 0xD4FF, 'gfx', 'Font: 96 characters'),
    (0xD500, 0xD637, 'gfx', 'BeamGlyphs: 39 glyphs'),
    (0xD638, 0xD6FF, 'spare', 'SpareBeamGlyphs'),
    (0xD700, 0xDEFF, 'gfx', 'CellGraphics: 256 characters'),
    (0xDF00, 0xDFFF, 'gfx', 'CellColours'),
    (0xE000, 0xE27F, 'buffer', 'CharMap: 20 x 32'),
    (0xE280, 0xE2FF, 'spare', ''),
    (0xE300, 0xE57F, 'buffer', 'DrawMarks: 20 x 32'),
    (0xE580, 0xE5FF, 'spare', ''),
    (0xE600, 0xE87F, 'buffer', 'ColourBuffer: 20 x 32'),
    (0xE880, 0xE8FF, 'spare', ''),
    (0xE900, 0xFCFF, 'buffer', 'PixelBuffer: 160 rows of 32'),
    (0xFD00, 0xFDFA, 'grid', 'LevelGrid (the mover before the game)'),
    (0xFDFB, 0xFDFC, 'spare', ''),
    (0xFDFD, 0xFDFF, 'im2', 'JP InterruptHandler'),
    (0xFE00, 0xFF00, 'im2', 'the IM 2 table: 257 x FD'),
    (0xFF01, 0xFFF2, 'spare', 'stack space never reached'),
    (0xFFF3, 0xFFFF, 'stack', 'the stack: 13 bytes used'),
]


def main():
    out = sys.argv[1]
    W, left, top, rh = 1050, 70, 44, 11
    bw = 1024 * 0.9
    labelled = [r for r in REGIONS if r[3] and r[2] != 'spare' or r[3].startswith(('Gap', 'Unused', 'Spare', 'the loader', 'stack space'))]
    legend_h = 20 * ((len(labelled) + 1) // 2) + 20
    H = top + 64 * rh + 20 + legend_h + 30
    o = Image.new('RGB', (W, H), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The 64 K as the game uses it: one row a kilobyte, a pixel column a byte', 17, figlib.ACCENT)
    num = {}
    for i, r in enumerate(labelled):
        num[r] = i + 1
    for lo, hi, kind, name in REGIONS:
        a = lo
        while a <= hi:
            row = a >> 10
            end = min(hi, (row << 10) + 1023)
            x0 = left + (a & 1023) * 0.9
            x1 = left + ((end & 1023) + 1) * 0.9
            y = top + row * rh
            d.rectangle([x0, y, max(x0, x1 - 1), y + rh - 2], fill=C[kind])
            a = end + 1
    for row in range(0, 64, 4):
        figlib.text(d, (8, top + row * rh - 2), f'${row << 10:04X}', 11, figlib.DIM)
    for r in labelled:
        lo = r[0]
        row = lo >> 10
        x = left + (lo & 1023) * 0.9 + 2
        y = top + row * rh - 1
        if r[1] - r[0] > 40:
            figlib.text(d, (x, y), str(num[r]), 10, (0, 0, 0))
    y0 = top + 64 * rh + 16
    for i, r in enumerate(labelled):
        cx = 12 + (i % 2) * 520
        cy = y0 + (i // 2) * 20
        d.rectangle([cx, cy + 3, cx + 12, cy + 14], fill=C[r[2]])
        figlib.text(d, (cx + 18, cy), f'{num[r]:2d} ${r[0]:04X}-${r[1]:04X} {r[3]}', 12, figlib.FG)
    figlib.text(d, (12, y0 + legend_h - 8), 'Ranges from src/game/game.ann; the stack low mark FFF3 from the L1 of all '
                'recordings (2.3). Numbers on a band: the legend line.', 12, figlib.DIM)
    o.save(out)
    print(out, o.size)


if __name__ == '__main__':
    main()

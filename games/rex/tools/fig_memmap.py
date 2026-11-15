#!/usr/bin/env python3
"""The memory map of doc 2: REX 1 as the tape leaves it and REX 1 in play, side by side, `$4000-$FFFF`.

    python3 tools/fig_memmap.py [--out docs/img/arch/memory-map.png]

Each region is a box with its range, its name and its size. The scale is not linear: a region gets a height in
proportion to its size, but never less than one text line, so the variables (178 bytes) stay readable beside the
sprites (5384 bytes). The regions come from the listing's labels (build/game.lst) and stage 2's notes; the "in play"
column is what the RZX run's memory holds at a pass (`work/stage1/NOTES.md`: the bytes that differ from the image).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

SCREEN, SYSTEM, LEFT, DATA, SPRITE, CODE, VARS, MENU, BUF = (
    (90, 90, 200), (70, 70, 80), (180, 60, 120), (100, 160, 120), (120, 120, 140), (230, 80, 80), (250, 250, 250),
    (140, 110, 170), (60, 200, 200))
LOADED = [
    (0x4000, 0x5AFF, 'the loading screen', SCREEN),
    (0x5B00, 0x6017, 'system variables, BASIC (CLEAR 24599)', SYSTEM),
    (0x6018, 0x60DF, 'development link stub (leftover)', LEFT),
    (0x60E0, 0x62DF, 'Font: characters 32-95', DATA),
    (0x62E0, 0x63DF, 'CharFlags: a cell type a character', DATA),
    (0x63E0, 0x6BDF, 'CharGraphics: 256 characters', DATA),
    (0x6BE0, 0x6CDF, 'CharAttrs: an attribute a character', DATA),
    (0x6CE0, 0x75DF, 'BlockDefs: 256 blocks of 3 x 3', DATA),
    (0x75E0, 0x7F71, 'RoomMaps: 35 rooms of 7 x 10 blocks', DATA),
    (0x7F72, 0x9479, 'sprites, pre-shifted', SPRITE),
    (0x947A, 0xA011, 'code: entry, waits, main loop, score, death', CODE),
    (0xA012, 0xA0C3, 'variables', VARS),
    (0xA0C4, 0xDABF, 'code and tables: HUD, rooms, objects, sound', CODE),
    (0xDAC0, 0xFFF9, 'menu: code, roll call, the title screen data', MENU),
]
PLAY = [
    (0x4000, 0x57FF, 'screen bitmap: HUD rows 0-2, the room rows 3-23', SCREEN),
    (0x5800, 0x5AFF, 'screen attributes', SCREEN),
    (0x5B00, 0x5B5F, 'untouched', SYSTEM),
    (0x5B60, 0x5D21, "Rex's bullets: 30 records of 15 bytes", BUF),
    (0x5D22, 0x5E4D, "the enemies' bullets: 20 records of 15", BUF),
    (0x5E4E, 0x5E65, "the drones' table: 8 records of 3 bytes", BUF),
    (0x5E66, 0x5FE5, 'objects: up to 16 records of 24 bytes', BUF),
    (0x5FE2, 0x5FFF, 'stack: SP $6000, low mark $5FE2', SYSTEM),
    (0x6018, 0x60D7, 'ExplosionPicture, over the stub', SPRITE),
    (0x60E0, 0x9479, 'the tables and sprites, as loaded (read only)', DATA),
    (0x947A, 0xDABF, 'code, variables, tables, as loaded', CODE),
    (0xDAC0, 0xDE9E, 'menu code: dead in play', MENU),
    (0xDE9F, 0xE19E, 'CellIndexMap', BUF),
    (0xE19F, 0xE4FE, 'RoomGrid: the cell types of the room', BUF),
    (0xE4FF, 0xE7FE, 'attribute shadow (was title data)', BUF),
    (0xE7FF, 0xEAFF, 'lines above the play area: origins', BUF),
    (0xEB00, 0xFFFF, 'BackBuffer: 168 lines of 32 bytes (cleared $EAFF-$FFFE)', BUF),
]


def column(d, regions, x, w, top, height, font, small):
    total = sum(b - a + 1 for a, b, _, _ in regions)
    line = 22
    spare = height - line * len(regions)
    y = top
    for a, b, name, colour in regions:
        h = line + spare * (b - a + 1) / total
        d.rectangle((x, y, x + w, y + h - 2), fill=colour)
        ink = (0, 0, 0) if sum(colour) > 380 else (255, 255, 255)
        d.text((x + 6, y + 3), f'${a:04X}-${b:04X}  {b - a + 1} B', fill=ink, font=small)
        d.text((x + 6, y + 19 if h > 40 else y + 3), name if h > 40 else '', fill=ink, font=small)
        if h <= 40:
            d.text((x + 170, y + 3), name, fill=ink, font=small)
        y += h
    return y


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(C, 'docs/img/arch/memory-map.png'))
    a = p.parse_args()
    w, top, height = 1050, 64, 900
    im = Image.new('RGB', (w, top + height + 60), (24, 24, 30))
    d = ImageDraw.Draw(im)
    font, small = K.font(16), K.font(13)
    d.text((10, 8), 'REX 1 in memory: as the tape leaves it (left) and in play (right), $4000 at the top',
           fill=(240, 240, 240), font=font)
    d.text((10, 36), 'as loaded (c1 frame 13 701)', fill=(220, 220, 220), font=font)
    d.text((540, 36), 'in play (rzx-p1-*)', fill=(220, 220, 220), font=font)
    column(d, LOADED, 10, 500, top, height, font, small)
    end = column(d, PLAY, 540, 500, top, height, font, small)
    d.text((10, end + 10), 'Heights grow with the size but never fall under a line of text: the scale is not linear. '
           'Colours: blue screen, green level data,', fill=(220, 220, 220), font=small)
    d.text((10, end + 28), 'grey sprites, red code, white variables, purple menu, cyan buffers and records, '
           'mauve the leftover stub, dark grey system.', fill=(220, 220, 220), font=small)
    im = im.crop((0, 0, w, int(end + 50)))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    sys.exit(main())

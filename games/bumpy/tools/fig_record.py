#!/usr/bin/env python3
"""Doc 07's data sheets of the level record, from src/res/levels/levels.txt (no emulator):

    python3 tools/fig_record.py [--level N]

docs/img/objects/record-NN.png: the 75 bytes of level NN's record (LevelRecords $8C3C + 75 x NN) in their three
parts, each byte decoded, beside the 6 x 6 cells drawn from it (platform, wall, object, start, exit).
docs/img/objects/workarea-NN.png: the work area $AA20-$AAFA as BuildLevel $CF2E leaves it for that level: the copied
record, CellPlatforms $AA6B, CellWalls $AA8F, CellBurning $AAB3 (DrawFlames $D14B) and BrickLayers $AAD7
(DrawBricks $D180), computed from the record the way the builder does.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CASE))
sys.path.insert(0, os.path.join(ROOT, 'kit'))
sys.path.insert(0, HERE)
import kitlib  # noqa: E402
import res_formats as RF  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'objects')
PLAT = {0: ('none', (60, 60, 70)), 1: ('plain', (200, 200, 200)), 2: ('crumble 1', (120, 200, 255)),
        3: ('crumble 2', (80, 160, 255)), 4: ('crumble 3', (40, 110, 255)), 5: ('stopper', (255, 140, 200)),
        6: ('conv. left', (120, 255, 120)), 7: ('conv. right', (40, 190, 40)), 8: ('fire', (255, 120, 0)),
        9: ('fire stop', (255, 60, 0)), 10: ('bricks', (190, 110, 50)), 11: ('exit', (255, 255, 255)),
        12: ('spikes', (255, 30, 30))}
WALL = {0: ('', (60, 60, 70)), 1: ('lock 1', (240, 210, 70)), 2: ('lock 2', (210, 170, 50)),
        3: ('lock 3', (180, 130, 30)), 4: ('solid', (170, 170, 170))}
OBJ = {1: 'hammer', 2: 'key', 3: 'water', 4: 'bottle'}


def obj_name(k):
    return OBJ.get(k, 'prize %d' % k if k else '')


def record_figure(lv, n):
    font, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    W, H = 1050, 560
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    addr = 0x8C3C + 75 * n
    d.text((10, 8), 'Level %d\'s record: 75 bytes at LevelRecords+%d = $%04X, decoded byte by byte' % (n, 75 * n, addr),
           fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'left: the bytes as stored (cells: wall << 4 | platform; then start, prizes, exit; then the '
           'objects); right: the cells they make', fill=kitlib.DIM, font=small)
    # bytes
    x0, y0, bw, bh = 10, 64, 40, 26
    d.text((x0, y0), '+0..+35  the cells (row by row, top first)', fill=kitlib.TEXT, font=small)
    for c in range(36):
        r, col = divmod(c, 6)
        x, y = x0 + 60 + col * bw, y0 + 20 + r * bh
        v = lv['cells'][c]
        d.text((x0, y + 5), '+%d' % (6 * r) if col == 0 else '', fill=kitlib.DIM, font=tiny)
        d.rectangle((x, y, x + bw - 4, y + bh - 4), fill=(30, 30, 42))
        d.text((x + 4, y + 5), '%X' % (v >> 4), fill=WALL[v >> 4][1] if v >> 4 else kitlib.DIM, font=small)
        d.text((x + 14, y + 5), '%X' % (v & 15), fill=PLAT[v & 15][1] if v & 15 else kitlib.DIM, font=small)
    y = y0 + 20 + 6 * bh + 8
    for i, (k, what) in enumerate(((36, 'start'), (37, 'prizes'), (38, 'exit'))):
        val = lv['start'] if k == 36 else lv['prizes'] if k == 37 else lv['exit']
        d.rectangle((x0 + 60 + i * 2 * bw, y, x0 + 60 + i * 2 * bw + bw - 4, y + bh - 4), fill=(30, 30, 42))
        d.text((x0 + 60 + i * 2 * bw + 6, y + 5), '%02X' % val, fill=(255, 140, 255), font=small)
        d.text((x0 + 60 + i * 2 * bw + bw, y + 5), what, fill=kitlib.DIM, font=tiny)
    d.text((x0, y + 5), '+36', fill=kitlib.DIM, font=tiny)
    y += bh + 10
    d.text((x0, y), '+39..+74  the object in each cell', fill=kitlib.TEXT, font=small)
    for c in range(36):
        r, col = divmod(c, 6)
        x, yy = x0 + 60 + col * bw, y + 20 + r * bh
        v = lv['objects'][c]
        d.text((x0, yy + 5), '+%d' % (39 + 6 * r) if col == 0 else '', fill=kitlib.DIM, font=tiny)
        d.rectangle((x, yy, x + bw - 4, yy + bh - 4), fill=(30, 30, 42))
        d.text((x + 8, yy + 5), '%02X' % v, fill=((255, 230, 60) if v >= 5 else (90, 220, 255)) if v else kitlib.DIM,
               font=small)
    # the cells
    gx, gy, cw, ch = 330, 64, 116, 72
    for c in range(36):
        r, col = divmod(c, 6)
        x, yy = gx + col * cw, gy + r * ch
        v, o = lv['cells'][c], lv['objects'][c]
        p, wl = v & 15, v >> 4
        d.rectangle((x, yy, x + cw - 2, yy + ch - 2), outline=(40, 40, 52))
        d.text((x + 3, yy + 2), 'cell %d' % c, fill=kitlib.DIM, font=tiny)
        if c == lv['exit']:
            d.rectangle((x + 2, yy + 2, x + cw - 6, yy + ch - 6), outline=(255, 255, 255), width=2)
            d.text((x + 60, yy + 2), 'exit', fill=(255, 255, 255), font=tiny)
        if c == lv['start']:
            d.ellipse((x + 44, yy + 18, x + 64, yy + 38), outline=(255, 140, 255), width=2)
        if o:
            d.text((x + 4, yy + 18), obj_name(o), fill=(255, 230, 60) if o >= 5 else (90, 220, 255), font=small)
        if p:
            d.rectangle((x + 8, yy + ch - 18, x + cw - 24, yy + ch - 12), fill=PLAT[p][1])
            d.text((x + 6, yy + ch - 34), PLAT[p][0], fill=PLAT[p][1], font=tiny)
        if wl and col < 5:
            d.rectangle((x + cw - 12, yy + 6, x + cw - 4, yy + ch - 10), fill=WALL[wl][1])
            d.text((x + cw - 58, yy + 18), WALL[wl][0], fill=WALL[wl][1], font=tiny)
    d.text((gx, gy + 6 * ch + 6), 'ring: the start (byte 36); white frame: where the exit opens (byte 38); bars on '
           'the right: the wall', fill=kitlib.DIM, font=small)
    d.text((gx, gy + 6 * ch + 24), 'between this cell and the next (column 5\'s wall is never drawn); prizes '
           'yellow, tools cyan', fill=kitlib.DIM, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'record-%02d.png' % n)
    im.save(path)
    print('record:', os.path.relpath(path, CASE))


def workarea_figure(lv, n):
    font, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    rec = bytes(lv['cells']) + bytes([lv['start'], lv['prizes'], lv['exit']]) + bytes(lv['objects'])
    area = bytearray(0xAAFB - 0xAA20)
    area[0:75] = rec
    for c in range(36):
        area[0xAA6B - 0xAA20 + c] = rec[c] & 15
        area[0xAA8F - 0xAA20 + c] = rec[c] >> 4
        if rec[c] & 15 in (8, 9):
            area[0xAAB3 - 0xAA20 + c] = 1
        if rec[c] & 15 == 10:
            area[0xAAD7 - 0xAA20 + c] = 8
    rows = [('LevelRecord $AA20 (cells)', 0xAA20, 36), ('BallCell, PrizesLeft, ExitCell $AA44', 0xAA44, 3),
            ('CellObjects $AA47', 0xAA47, 36), ('CellPlatforms $AA6B', 0xAA6B, 36), ('CellWalls $AA8F', 0xAA8F, 36),
            ('CellBurning $AAB3', 0xAAB3, 36), ('BrickLayers $AAD7', 0xAAD7, 36)]
    W = 1050
    H = 70 + len(rows) * 62 + 40
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The work area $AA20-$AAFA after BuildLevel $CF2E built level %d: one table a field, one byte a '
           'cell' % n, fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'the record is copied whole, then each cell byte is split into two tables; the builder sets '
           'the burning flags and the brick layers as it draws', fill=kitlib.DIM, font=small)
    cw = 26
    for i, (name, a, k) in enumerate(rows):
        y = 64 + i * 62
        d.text((10, y), name, fill=kitlib.TEXT, font=small)
        for c in range(k):
            v = area[a - 0xAA20 + c]
            x = 10 + c * (cw + 2)
            col = kitlib.DIM if not v else (240, 200, 70) if 'Walls' in name else (90, 220, 255) if 'Objects' in name \
                else (255, 120, 0) if 'Burning' in name else (190, 110, 50) if 'Brick' in name else (220, 220, 230)
            d.rectangle((x, y + 18, x + cw, y + 42), fill=(30, 30, 42))
            d.text((x + 4, y + 23), '%02X' % v, fill=col, font=tiny)
            if i == 0 or k == 3:
                pass
        if k == 36:
            for r in range(6):
                d.line((10 + 6 * r * (cw + 2) - 1, y + 16, 10 + 6 * r * (cw + 2) - 1, y + 46), fill=(90, 90, 110))
    d.text((10, H - 30), 'thin lines: the start of each row of six cells. Cells are counted 0-35, left to right and '
           'top to bottom', fill=kitlib.DIM, font=small)
    path = os.path.join(OUT, 'workarea-%02d.png' % n)
    im.save(path)
    print('workarea:', os.path.relpath(path, CASE))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--level', type=int, default=1)
    a = ap.parse_args()
    levels = RF.levels_parse(open(os.path.join(RF.RES, 'levels', 'levels.txt'), 'rb').read())
    record_figure(levels[a.level], a.level)
    workarea_figure(levels[a.level], a.level)


if __name__ == '__main__':
    main()

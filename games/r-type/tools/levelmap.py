#!/usr/bin/env python3
"""Draws each level's scenery from the level block of the original tape, the way ScrollFeed (`$8979` -> `$8A13`)
builds it: no emulator, only the bytes.

    python3 tools/levelmap.py [--level N] [--per-row 28] [--scale 1] OUTDIR

The level body loads to `$C4AE` (LoadLevel `$FE03`). Its word at `$C4BC` (MapPtr) points at the map: 5 bytes per
column block (32 pixels wide), top to bottom, each a metatile row of 4 character rows (the playfield's 20 rows).
A map byte: bits 0-5 the metatile number n, bits 6-7 the variant drawn by `$8741` (as stored), `$8778` (mirrored left
to right: the cell order and each byte's bits reversed through the table at `$5D00`), `$87B8` (upside down: the 144
bytes read backwards) and `$87F2` (both). Metatile n is the 144 bytes at MapPtr - (n + 1) * 144 (`$882D`): 4 rows of 4
cells, a cell an attribute byte then 8 pixel bytes. The map ends where the attack-wave script starts (the word at
`$C4B4`).

Writes OUTDIR/level-N.png (the strip cut into rows of --per-row column blocks, each row labelled with its first
column block and the map address) and OUTDIR/level-N-tiles.png (the metatiles with their numbers and addresses).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import media_compare  # noqa: E402

CASE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
TAPE = os.path.join(CASE, 'work', 'stage1', 'media', 'rtype.tzx')
BASE = 0xC4AE
PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRI = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def levels():
    media_compare.MIN = 3
    b = media_compare.blocks(TAPE)
    return {n: b[k][1:-1] for n, k in enumerate(range(15, 30, 2), 1)}


class Level:
    def __init__(self, body):
        self.d = body

    def byte(self, a):
        return self.d[a - BASE]

    def word(self, a):
        return self.byte(a) | self.byte(a + 1) << 8

    @property
    def map(self):
        return self.word(0xC4BC)

    @property
    def columns(self):
        return (self.word(0xC4B4) - self.map) // 5

    def tile(self, n):
        a = self.map - (n + 1) * 144
        return a, self.d[a - BASE:a - BASE + 144]


def rev(b):
    return int(f'{b:08b}'[::-1], 2)


def draw_tile(img, x0, y0, t, variant):
    """Metatile bytes @p t (144) at (x0, y0), 32 x 32 pixels, in @p variant 0-3"""
    px = img.load()
    for r in range(4):
        for c in range(4):
            sr, sc = (3 - r if variant & 2 else r), (3 - c if variant & 1 else c)
            cell = t[sr * 36 + sc * 9: sr * 36 + sc * 9 + 9]
            attr, rows = cell[0], list(cell[1:])
            if variant & 2:
                rows = rows[::-1]
            if variant & 1:
                rows = [rev(b) for b in rows]
            pal = BRI if attr & 0x40 else PAL
            ink, paper = pal[attr & 7], pal[(attr >> 3) & 7]
            for y, b in enumerate(rows):
                for x in range(8):
                    px[x0 + c * 8 + x, y0 + r * 8 + y] = ink if b & (0x80 >> x) else paper


def strip(lv):
    img = Image.new('RGB', (lv.columns * 32, 160))
    for col in range(lv.columns):
        for row in range(5):
            m = lv.byte(lv.map + col * 5 + row)
            draw_tile(img, col * 32, row * 32, lv.tile(m & 0x3F)[1], m >> 6)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--level', type=int)
    ap.add_argument('--per-row', type=int, default=28)
    ap.add_argument('--scale', type=int, default=1)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    f = font(13)
    for n, body in levels().items():
        if a.level and n != a.level:
            continue
        lv = Level(body)
        s = strip(lv)
        per = a.per_row
        drawn = max(c for c in range(lv.columns) if any(lv.byte(lv.map + c * 5 + r) for r in range(5))) + 1
        nrows = (drawn + per - 1) // per
        lab = 18
        out = Image.new('RGB', (per * 32 + 8, nrows * (160 + lab + 6) + 22), (255, 255, 255))
        d = ImageDraw.Draw(out)
        tail = '' if drawn == lv.columns else f'; {lv.columns - drawn} more, all metatile 0, not drawn'
        d.text((4, 3), f'Level {n}: {lv.columns} column blocks of 32 pixels, map ${lv.map:04X}, '
                       f'5 bytes a column block{tail}', fill=(0, 0, 0), font=f)
        for i in range(nrows):
            c0 = i * per
            c1 = min(drawn, c0 + per)
            y = 22 + i * (160 + lab + 6)
            d.text((4, y + 1), f'column blocks {c0}-{c1 - 1}, map ${lv.map + c0 * 5:04X}-${lv.map + c1 * 5 - 1:04X}',
                   fill=(0, 0, 0), font=f)
            out.paste(s.crop((c0 * 32, 0, c1 * 32, 160)), (4, y + lab))
        if a.scale > 1:
            out = out.resize((out.width * a.scale, out.height * a.scale), Image.NEAREST)
        out.save(os.path.join(a.out, f'level-{n}.png'))
        used = sorted({lv.byte(lv.map + i) & 0x3F for i in range(lv.columns * 5)})
        cols = 12
        tw, th = 32 * 2 + 16, 32 * 2 + 34
        tiles = Image.new('RGB', (cols * tw + 8, ((max(used) + cols) // cols) * th + 24), (255, 255, 255))
        d = ImageDraw.Draw(tiles)
        d.text((4, 3), f'Level {n}: metatiles 0-{max(used)} (4 x 4 cells, 144 bytes each), x2', fill=(0, 0, 0), font=f)
        for t in range(max(used) + 1):
            addr, data = lv.tile(t)
            im = Image.new('RGB', (32, 32))
            draw_tile(im, 0, 0, data, 0)
            x, y = 4 + (t % cols) * tw, 24 + (t // cols) * th
            tiles.paste(im.resize((64, 64), Image.NEAREST), (x, y))
            d.text((x, y + 66), f'{t} ${addr:04X}' + ('' if t in used else ' unused'), fill=(0, 0, 0), font=f)
        tiles.save(os.path.join(a.out, f'level-{n}-tiles.png'))
        print(n, lv.columns, drawn, f'${lv.map:04X}', 'tiles', max(used) + 1)


if __name__ == '__main__':
    main()

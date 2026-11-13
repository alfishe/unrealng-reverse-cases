#!/usr/bin/env python3
"""Every zone and every level map of Rick Dangerous, drawn from the editable level text (src/res/levels):

    python3 tools/fig_rooms.py [--out work/stage2/fig] [--image work/mkgame/original.bin]

levels.txt gives each zone's char set, map rows, exits and objects; tiles.txt the 4 x 4 char codes of a tile. The
chars and their attributes are the game's (the 64K image): set 0 bitmaps `$7100`, attributes `$7900`; set 1 `$7A00`,
`$8200` (EnterZone `$AC83`). The drawing is tools/mapdraw.py's: a tile row is 32 pixels, 8 tiles a row.

Marks: an object at x = +3 AND `$F8`, y = ((+0 AND `$F8`) + (+3 AND 7)) x 8 (SpawnObjects `$FD7D`), a box coloured
by its kind's group (pic yellow, mark cyan, actor red) with the kind number; a taken object (kind bit 7) dashed.
An exit is a white triangle on its side at its map row, with the zone it leads to.
Writes zone-L1Z1.png ... (one a zone) and level1.png ... (the zones of a level side by side).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

sys.path.insert(0, HERE)
import res_levels as RL  # noqa: E402

CHARS = (0x7100, 0x7A00)
ATTRS = (0x7900, 0x8200)
NAMES = ('South America', 'Egypt', 'Schwarzendumpf castle', 'Missile base')
COLOURS = {'pic': (255, 220, 0), 'mark': (0, 230, 230), 'actor': (255, 60, 60), 'kind': (200, 200, 200)}


def read_levels(path):
    """[{id, level, set, map: [rows], exits: [(side, row, to, row2)], objs: [(y, kind, taken, flags, x, dy)]}]"""
    zones = []
    in_map = False
    for line in open(path):
        line = line.split('#', 1)[0].rstrip()
        if not line:
            continue
        f = line.split()
        if line.startswith('  ') and in_map:
            zones[-1]['map'].append([int(x, 16) for x in f])
            continue
        in_map = False
        if f[0] == 'zone':
            zones.append({'id': f[1], 'level': int(f[1][1:f[1].index('Z')]), 'set': RL.num(f[3]), 'map': [],
                          'exits': [], 'objs': []})
        elif f[0] == 'map':
            in_map = True
        elif f[0] == 'exit':
            zones[-1]['exits'].append((f[1], RL.num(f[2]), f[4], RL.num(f[5])))
        elif f[0] == 'obj':
            taken = f[3] == 'taken'
            rest = f[4:] if taken else f[3:]
            x, dy = rest[3].split('+')
            zones[-1]['objs'].append((RL.num(f[1]), f[2], taken, RL.num(rest[1]), RL.num(x), int(dy)))
    return zones


def read_tiles(path):
    return RL.tiles_from_text(open(path, 'rb').read())


def draw_zone(z, tiles, img, font):
    rows = len(z['map'])
    strip = Image.new('RGB', (256, rows * 32), (0, 0, 0))
    px = strip.load()
    cs = z['set']
    for r, row in enumerate(z['map']):
        for c, tile in enumerate(row):
            for k, code in enumerate(tiles[16 * tile:16 * tile + 16]):
                cx, cy = c * 32 + (k % 4) * 8, r * 32 + (k // 4) * 8
                attr = img[ATTRS[cs] + code]
                bright = bool(attr & 0x40)
                ink, paper = zxscreen.palette(attr & 7, bright), zxscreen.palette(attr >> 3 & 7, bright)
                for y in range(8):
                    bits = img[CHARS[cs] + code * 8 + y]
                    for x in range(8):
                        px[cx + x, cy + y] = ink if bits & 0x80 >> x else paper
    d = ImageDraw.Draw(strip)
    for y0, kind, taken, flags, x, dy in z['objs']:
        y = ((y0 & 0xF8) + dy) * 8
        group = kind.rstrip('0123456789')
        col = COLOURS[group]
        box = (x, y, min(x + 15, 255), y + 15)
        if taken:
            for i in range(box[0], box[2], 4):
                d.line((i, box[1], i + 1, box[1]), fill=col)
                d.line((i, box[3], i + 1, box[3]), fill=col)
        else:
            d.rectangle(box, outline=col, width=2)
        d.text((x + 2, y + 1), kind[len(group):], fill=col, font=font, stroke_width=2, stroke_fill=(0, 0, 0))
    for side, row, to, _row2 in z['exits']:
        y = row * 8
        if side == 'left':
            d.polygon([(0, y), (12, y - 10), (12, y + 10)], fill=(255, 255, 255))
            d.text((14, y - 9), to, fill=(255, 255, 255), font=font, stroke_width=2, stroke_fill=(0, 0, 0))
        else:
            d.polygon([(255, y), (243, y - 10), (243, y + 10)], fill=(255, 255, 255))
            tw = d.textlength(to, font=font)
            d.text((241 - tw, y - 9), to, fill=(255, 255, 255), font=font, stroke_width=2, stroke_fill=(0, 0, 0))
    return strip


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'work', 'stage2', 'fig'))
    ap.add_argument('--image', default=os.path.join(CASE, 'work', 'mkgame', 'original.bin'))
    ap.add_argument('--res', default=os.path.join(CASE, 'src', 'res', 'levels'))
    a = ap.parse_args()
    img = open(a.image, 'rb').read()
    if len(img) != 0x10000:
        sys.exit('%s: not a 64K image' % a.image)
    zones = read_levels(os.path.join(a.res, 'levels.txt'))
    tiles = read_tiles(os.path.join(a.res, 'tiles.txt'))
    os.makedirs(a.out, exist_ok=True)
    small, f1, f2 = K.font(14), K.font(30), K.font(20)
    strips = {}
    for z in zones:
        st = draw_zone(z, tiles, img, small)
        strips[z['id']] = st
        path = os.path.join(a.out, 'zone-%s.png' % z['id'])
        st.resize((st.width * 2, st.height * 2), Image.NEAREST).save(path)
    for lv in range(1, 5):
        mine = [z for z in zones if z['level'] == lv]
        cols = min(6, len(mine))
        grid = [mine[i:i + cols] for i in range(0, len(mine), cols)]
        heights = [max(strips[z['id']].height for z in row) + 44 for row in grid]
        out = Image.new('RGB', (cols * 272 + 16, 56 + sum(heights)), (40, 40, 40))
        d = ImageDraw.Draw(out)
        d.text((8, 8), 'Level %d: %s, %d zones, %d objects (src/res/levels)' % (
            lv, NAMES[lv - 1], len(mine), sum(len(z['objs']) for z in mine)), fill=(255, 255, 255), font=f1)
        y = 56
        for row, h in zip(grid, heights):
            for k, z in enumerate(row):
                x = 8 + k * 272
                d.text((x, y + 4), '%s %d rows' % (z['id'], len(z['map'])),
                       fill=(230, 230, 230), font=f2)
                out.paste(strips[z['id']], (x, y + 40))
            y += h
        path = os.path.join(a.out, 'level%d.png' % lv)
        out.save(path)
        print(path, out.size)
    print('%d zones drawn' % len(zones))


if __name__ == '__main__':
    main()

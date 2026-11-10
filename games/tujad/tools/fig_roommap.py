#!/usr/bin/env python3
"""The world map of Tujad drawn from the resources, not from screenshots: every room's play area as DrawRoom $6B22
draws it, from src/res/rooms/Rooms.txt (the layouts and the items), src/res/tiles/TileTables.txt and TileData.png
(the tiles), src/res/sprites/HudIcons.png and src/res/graphics/EdPieces.png (the items). The 128 rooms in a grid 8
across and 16 down (+1 east, +8 south); the 26 empty rooms grey. The stage 1 map from screenshots stays
docs/img/play/world-map.png (tools/fig_worldmap.py); this one shows every room, visited or not.

    python3 tools/fig_roommap.py docs/img/play/world-map-rooms.png [--scale 0.5]

The tiles go through the same address arithmetic as DrawRoomLayout $6C93-$6D8B (screen row = row + 5, the bytes
over the HUD rows 0-5 and under the screen skipped, the attribute fill that stops a row at the first skipped
cell), on a 6912-byte screen, then the items as DrawItem $6E0D puts them (Blit16 at the item's cell, its colour
on 2 x 2 cells; only kinds with bit 7, as DrawRoom draws them). A teleporter is marked by a thick red frame round its
2 x 2 cells and a red tag with the target room's number. The items are drawn where the image stores them, before
NewGame's deal (an odd number of ScrambleRooms rotations), so no game starts with exactly these items.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import res_formats as rf  # noqa: E402

RES = rf.RES
COLS, ROWS = 8, 16
TILE_TABLES, TILE_DATA, ROOMS_AT = 0x6EA8, 0xE822, 0xBD06
HUD_ICONS, ED_PIECES = 0x8C55, 0xE1E2
WEAPON_COLOURS = [0x43, 0x44, 0x46]


def load(rel, name):
    path = os.path.join(RES, rel)
    fmt = rf.editable(name)
    return fmt[2](name, open(path, 'rb').read())


def rgb(colour, bright):
    v = 255 if bright else 205
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


class Screen:
    def __init__(self):
        self.m = bytearray(0x10000)

    def draw_tile(self, mem, col, row, tile):
        """DrawRoomTile $6CAC-$6D8B on the 64 K self.m (screen at $4000), the tile data in mem"""
        m = self.m
        w = lambda a: mem[a] | mem[a + 1] << 8
        attr_ptr = w(TILE_TABLES + 0x8C + 2 * tile)
        de = w(TILE_TABLES - 2 + 2 * tile)
        l = ((row << 5) & 0xE0) | col
        h = (row & 0x18) | 0x40
        l += 0xA0
        if l > 0xFF:
            l &= 0xFF
            h += 8
        top_h, top_l = h, l
        c, b = mem[de], mem[de + 1]
        de += 2
        for _r in range(b):
            sh, sl = h, l
            for _k in range(c):
                if h & 0xF8 == 0x58:
                    continue
                if h & 0xF8 == 0x40 and (l & 0xE0) < 0xC0:
                    de += 1
                    continue
                m[h << 8 | l] = mem[de]
                l = (l + 1) & 0xFF
                de += 1
            h, l = sh, sl
            h += 1
            if h & 7 == 0:
                l += 0x20
                if l > 0xFF:
                    l &= 0xFF
                else:
                    h -= 8
        h = ((top_h >> 3) & 3) | 0x58
        l = top_l
        b >>= 3
        a0 = mem[attr_ptr]
        if not a0 & 0x80:
            de = attr_ptr
            for _r in range(b):
                sh, sl = h, l
                for _k in range(c):
                    ok = not (h >= 0x5B or (h == 0x58 and (l & 0xE0) < 0xC0))
                    if ok:
                        m[h << 8 | l] = mem[de]
                        l = (l + 1) & 0xFF
                    de += 1
                h, l = sh, sl
                l += 0x20
                if l > 0xFF:
                    l &= 0xFF
                    h += 1
        else:
            e = a0 & 0x7F
            for _r in range(b):
                sh, sl = h, l
                for _k in range(c):
                    if h >= 0x5B or (h == 0x58 and (l & 0xE0) < 0xC0):
                        break
                    m[h << 8 | l] = e
                    l = (l + 1) & 0xFF
                h, l = sh, sl
                l += 0x20
                if l > 0xFF:
                    l &= 0xFF
                    h += 1

    def blit16(self, col, row, data, colour):
        for y in range(16):
            py = row * 8 + y
            a = 0x4000 | ((py & 0xC0) << 5) | ((py & 7) << 8) | ((py & 0x38) << 2) | col
            self.m[a], self.m[a + 1] = data[2 * y], data[2 * y + 1]
        for dy in (0, 1):
            for dx in (0, 1):
                self.m[0x5800 + (row + dy) * 32 + col + dx] = colour

    def image(self):
        img = Image.new('RGB', (256, 144))
        px = img.load()
        for y in range(48, 192):
            for x in range(256):
                a = self.m[0x5800 + (y >> 3) * 32 + (x >> 3)]
                b = self.m[0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)]
                ink = (b >> (7 - (x & 7))) & 1
                px[x, y - 48] = rgb(a & 7 if ink else (a >> 3) & 7, (a >> 6) & 1)
        return img


def parse_rooms(text):
    rooms, cur = {}, None
    for ln in text.split('\n'):
        t = ln.split()
        if not t or ln.startswith('#'):
            continue
        if t[0] == 'room':
            cur = int(t[1])
            rooms[cur] = None if t[2:] == ['empty'] else {'tiles': [], 'items': [], 'teleport': None}
        elif t[0] == 'tile':
            c, r = (int(x) for x in t[3].split(','))
            rooms[cur]['tiles'].append((c, r, int(t[1])))
        elif t[0] in ('item1', 'item2') and t[1] != 'none':
            c, r = (int(x) for x in t[3].split(','))
            rooms[cur]['items'].append((rf.item_code(t[1]), c, r))
        elif t[0] == 'teleport' and t[1] != 'none':
            c, r = (int(x) for x in t[4].split(','))
            rooms[cur]['teleport'] = (int(t[2]), c, r)
    return rooms


def item_graphic(mem, kind):
    if kind == 0x80:
        return mem[0x8CD5:0x8CF5], 0x45
    if kind == 0x81:
        return mem[0x8D15:0x8D35], 0x42
    if kind & 0x40:
        n = kind & 3
        return mem[HUD_ICONS + 32 * n:HUD_ICONS + 32 * n + 32], WEAPON_COLOURS[n - 1]
    n = (kind & 0x7F) - 1
    tile = (n - 1) % 5 * 10 + (n - 1) // 5
    return mem[ED_PIECES + 32 * tile:ED_PIECES + 32 * tile + 32], 0x67


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--scale', type=float, default=0.5)
    args = ap.parse_args()
    mem = bytearray(0x10000)
    tables = load('tiles/TileTables.txt', 'tiles/TileTables.bin')
    mem[TILE_TABLES:TILE_TABLES + len(tables)] = tables
    data = load('tiles/TileData.png', 'tiles/TileData.bin')
    mem[TILE_DATA:TILE_DATA + len(data)] = data
    icons = load('sprites/HudIcons.png', 'sprites/HudIcons.bin')
    mem[HUD_ICONS:HUD_ICONS + len(icons)] = icons
    ed = load('graphics/EdPieces.png', 'graphics/EdPieces.bin')
    mem[ED_PIECES:ED_PIECES + len(ed)] = ed
    rooms = parse_rooms(open(os.path.join(RES, 'rooms', 'Rooms.txt'), encoding='utf-8').read())

    tw, th = int(256 * args.scale), int(144 * args.scale)
    lab = 14
    out = Image.new('RGB', (COLS * (tw + 2) + 2, ROWS * (th + lab + 2) + 2), (24, 24, 30))
    draw = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 11)
    except OSError:
        font = ImageFont.load_default()
    for n in range(128):
        x0 = 2 + (n % COLS) * (tw + 2)
        y0 = 2 + (n // COLS) * (th + lab + 2)
        r = rooms[n]
        if r is None:
            draw.rectangle([x0, y0 + lab, x0 + tw - 1, y0 + lab + th - 1], fill=(70, 70, 80))
            draw.text((x0 + 2, y0), '%d  no room' % n, fill=(150, 150, 160), font=font)
            continue
        s = Screen()
        for c, row, t in r['tiles']:
            s.draw_tile(mem, c, row, t)
        for kind, c, row in r['items']:
            if kind & 0x80:
                g, colour = item_graphic(mem, kind)
                s.blit16(c, row + 6, g, colour)
        img = s.image()
        if r['teleport']:
            to, c, row = r['teleport']
            d = ImageDraw.Draw(img)
            # a thick frame a cell wider than the 2 x 2 pad all round, so it shows after the scale-down
            d.rectangle([c * 8 - 8, row * 8 - 8, c * 8 + 23, row * 8 + 23], outline=(255, 40, 40), width=6)
        img = img.resize((tw, th), Image.LANCZOS)
        out.paste(img, (x0, y0 + lab))
        draw.text((x0 + 2, y0), '%d' % n, fill=(235, 235, 235), font=font)
        if r['teleport']:
            # the target on a red tag, so a teleporter room shows at a glance
            tag = 'T>%d' % r['teleport'][0]
            tx = x0 + tw - 8 * len(tag) - 6
            draw.rectangle([tx - 3, y0, x0 + tw - 2, y0 + lab - 1], fill=(200, 30, 30))
            draw.text((tx, y0), tag, fill=(255, 255, 255), font=font)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    out.save(args.out, optimize=True)
    print('%s: %d x %d' % (args.out, out.width, out.height))


if __name__ == '__main__':
    main()

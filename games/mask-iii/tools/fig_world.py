#!/usr/bin/env python3
"""The world of MASK III drawn from src/res (doc 1, 1.4): every room screen by screen, with the masks that lie in it
(PickupTable), the enemy kind of each screen and the room's exits (RoomTable), and an overview of all 16 rooms.

    python3 tools/fig_world.py            # docs/img/maps/world-overview.png and world-zone0..3.png

The rooms are drawn by tools/roommap.py from the resources (the maps, the blocks, the room table and the zone's
character set), as a new game has them; the screen shows character rows 2-19 of the 20 the map draws.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import roommap  # noqa: E402
import res_formats  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'maps')
ZONES = {0: 'zone 0, the surface', 1: 'zone 1, the caverns', 2: 'zone 2, the moon', 3: 'zone 3, the base'}
MASKS = ['EMPTY', 'PENETRATOR', 'ULTRA FLASH', 'MIRAGE', 'HEALER', 'JACKRABBIT', 'LIFTER', 'BLASTER', 'BACKLASH',
         'LAVA SHOT', 'STREAMER']
KINDS = {0: 'none', 1: 'flyer', 2: 'faller', 3: 'wave', 4: 'walker', 5: 'chaser', 6: 'kind 6', 7: 'riser',
         8: 'guard', 9: 'boss', 10: 'kind 10'}
BG, FG, DIM, MARK = (24, 24, 30), (235, 235, 235), (180, 180, 190), (255, 80, 80)


def resources():
    got = {}
    for source in res_formats.sources():
        name, data = res_formats.decode(source)
        got[name] = data
    return got


def room_strip(r):
    mem = roommap.res_memory(0)
    rec = mem[0x953B + 12 * r:0x953B + 12 * r + 12]
    mem = roommap.res_memory(rec[4])
    return rec, [roommap.draw_screen(mem, r, s) for s in range(6)]


def pickups(got):
    t = got['tables/pickups.bin']
    out = []
    for i in range(0, len(t) - 3, 4):
        if t[i] == 0xFF:
            break
        out.append((t[i] & 0x7F, t[i + 1], t[i + 2], t[i + 3]))
    return out


def exits_text(rec):
    parts = []
    for name, b in (('left', rec[0]), ('right', rec[1]), ('pod', rec[2])):
        if b != 0xFF:
            parts.append(f'{name} to room {b}')
    return ', '.join(parts) if parts else 'no exit: the end'


def zone_figure(got, zone, rooms):
    big, mid, small = kitlib.font(18), kitlib.font(15), kitlib.font(14)
    head, cap, sw, sh = 56, 22, 256, 144
    width = 1050
    x0 = (width - 4 * sw) // 2
    # each room: a title line, then two rows of three screens, each screen with a caption line above it
    room_h = head + 2 * (cap + sh) + 14
    im = Image.new('RGB', (width, 44 + len(rooms) * room_h), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), f'MASK III, {ZONES[zone]}: rooms {rooms[0]}-{rooms[-1]} drawn from src/res '
                     f'(tools/fig_world.py)', fill=FG, font=big)
    picks = pickups(got)
    y = 44
    for r in rooms:
        rec, screens = room_strip(r)
        mine = [p for p in picks if p[0] == r]
        d.text((10, y + 6), f'room {r}: {exits_text(rec)}; map ${0x7600 + 240 * r:04X}, record ${0x953B + 12 * r:04X}',
               fill=FG, font=big)
        if mine:
            text = '  '.join(f'{n} {MASKS[p[1]]} (screen {p[2] // 32})' for n, p in enumerate(mine, 1))
            d.text((10, y + 32), 'masks lying here: ' + text, fill=MARK, font=mid)
        for s in range(6):
            row, col = divmod(s, 3)
            sx = 10 + col * 345
            sy = y + head + row * (cap + sh)
            kind = rec[6 + s]
            d.text((sx, sy + 3), f'screen {s}: enemy kind {kind} ({KINDS[kind]})', fill=DIM, font=small)
            scr = screens[s]
            im.paste(scr, (sx, sy + cap))
            for n, (room, mk, px, py) in enumerate(mine, 1):
                if px // 32 == s:
                    bx, by = sx + (px % 32) * 8, sy + cap + py * 8
                    d.rectangle((bx - 2, by - 2, bx + 17, by + 17), outline=MARK, width=2)
                    d.rectangle((bx - 2, by - 22, bx + 14, by - 3), fill=MARK)
                    d.text((bx + 2, by - 21), str(n), fill=(0, 0, 0), font=mid)
        y += room_h
    return im


def overview(got):
    big, mid = kitlib.font(18), kitlib.font(14)
    width, label = 1050, 268
    sw, sh = 128, 72
    row_h = sh + 10
    im = Image.new('RGB', (width, 72 + 16 * row_h + 30), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'MASK III: the 16 rooms, six screens each, drawn from src/res at half size', fill=FG, font=big)
    d.text((10, 36), 'room, zone, exits (left, right, the pod at the room\'s end)', fill=DIM, font=mid)
    for r in range(16):
        rec, screens = room_strip(r)
        y = 64 + r * row_h
        d.text((10, y + 8), f'room {r:2d}, zone {rec[4]}', fill=FG, font=big)
        d.text((10, y + 34), exits_text(rec), fill=DIM, font=mid)
        for s in range(6):
            im.paste(screens[s].resize((sw, sh), Image.LANCZOS), (label + s * (sw + 2), y))
    d.text((10, 64 + 16 * row_h + 6), 'zones: 0 the surface (rooms 0-3), 1 the caverns (4-6), 2 the moon (7-9), '
                                       '3 the base (10-15)', fill=DIM, font=mid)
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    got = resources()
    overview(got).save(os.path.join(OUT, 'world-overview.png'))
    for zone, rooms in ((0, [0, 1, 2, 3]), (1, [4, 5, 6]), (2, [7, 8, 9]), (3, [10, 11, 12, 13, 14, 15])):
        zone_figure(got, zone, rooms).save(os.path.join(OUT, f'world-zone{zone}.png'))
    print(OUT, 'world-overview.png, world-zone0..3.png')


if __name__ == '__main__':
    main()

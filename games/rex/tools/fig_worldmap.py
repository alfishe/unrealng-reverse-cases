#!/usr/bin/env python3
"""The world maps of doc 1, drawn from src/res (through tools/room_maps.py): every room of REX 1 placed by its exits
from room 0 with an arrow on every exit (the exits are one-way), and REX 2's single route as a strip in route order.

    python3 tools/fig_worldmap.py

writes docs/img/maps/world-rex1.png and docs/img/maps/route-rex2.png (1050 px wide). The frame colour says which
recording entered the room: the RZX run (`work/stage2/roomwatch/p1`, `p2`), or a recording with a POKE (stage 2's
p1-room14/24/26/27/30, p2-room20; the docs' p1-rooms238). The weapon stations (cell types `$0A-$0D` in the room's
blocks) and the end exit 99 are marked.
"""
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, 'tools'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import room_maps  # noqa: E402

RZX = {'rex1': {0, 1, 4, 5, 6, 7, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 28, 29, 31, 32, 33, 34},
       'rex2': set(range(26))}
POKED = {'rex1': {2, 3, 8, 14, 24, 26, 27, 30}, 'rex2': set()}
STATION = {1: 'double', 6: 'laser', 23: 'multiple', 11: 'spray'}
STEP = [(0, -1), (1, 0), (0, 1), (-1, 0)]
GREEN, ORANGE = (90, 220, 110), (255, 160, 40)


def tile(pic, w, h):
    return pic.resize((w, h), Image.LANCZOS)


def arrow(d, x0, y0, x1, y1, colour):
    d.line((x0, y0, x1, y1), fill=colour, width=3)
    dx, dy = x1 - x0, y1 - y0
    n = max(1, (dx * dx + dy * dy) ** 0.5)
    ux, uy = dx / n, dy / n
    px, py = -uy, ux
    d.polygon([(x1, y1), (x1 - 9 * ux + 6 * px, y1 - 9 * uy + 6 * py), (x1 - 9 * ux - 6 * px, y1 - 9 * uy - 6 * py)],
              fill=colour)


def world_rex1(out):
    maps, exits, blocks, chars = room_maps.load('rex1')
    n = len(exits) // 6
    pos, queue = {0: (0, 0)}, [0]
    while queue:
        r = queue.pop(0)
        for k in range(4):
            e = exits[6 * r + k]
            if e and e != 99 and e not in pos:
                pos[e] = (pos[r][0] + STEP[k][0], pos[r][1] + STEP[k][1])
                queue.append(e)
    xs, ys = [p[0] for p in pos.values()], [p[1] for p in pos.values()]
    x0, y0 = min(xs), min(ys)
    cols, rows = max(xs) - x0 + 1, max(ys) - y0 + 1
    w, h, g, head, foot = 96, 67, 18, 40, 70
    left = (1050 - cols * (w + g) + g) // 2
    im = Image.new('RGB', (1050, head + rows * (h + g) + foot), (40, 40, 48))
    d = ImageDraw.Draw(im)
    font, small = K.font(16), K.font(13)
    d.text((10, 8), 'REX 1: the 35 rooms from src/res, placed by their exits from room 0; every exit is one-way',
           fill=(240, 240, 240), font=font)
    box = {}
    for r, (x, y) in pos.items():
        X, Y = left + (x - x0) * (w + g), head + (y - y0) * (h + g)
        box[r] = (X, Y)
        im.paste(tile(room_maps.room_picture(maps, blocks, chars, r), w, h), (X, Y))
        colour = GREEN if r in RZX['rex1'] else ORANGE
        d.rectangle((X - 2, Y - 2, X + w + 1, Y + h + 1), outline=colour, width=2)
        d.rectangle((X, Y, X + 24, Y + 16), fill=(255, 255, 255))
        d.text((X + 2, Y), str(r), fill=(0, 0, 0), font=small)
        if r in STATION:
            d.rectangle((X, Y + h - 16, X + 9 * len(STATION[r]) + 4, Y + h), fill=(255, 230, 0))
            d.text((X + 2, Y + h - 17), STATION[r], fill=(0, 0, 0), font=small)
        if 99 in exits[6 * r:6 * r + 4]:
            d.rectangle((X + w - 30, Y, X + w, Y + 16), fill=(255, 60, 60))
            d.text((X + w - 28, Y), 'end', fill=(255, 255, 255), font=small)
    for r, (X, Y) in box.items():
        for k in range(4):
            e = exits[6 * r + k]
            if not e or e == 99 or e not in box:
                continue
            ex, ey = box[e]
            cx, cy = X + w / 2, Y + h / 2
            if k == 1:
                arrow(d, X + w - 4, cy, ex + 6, cy, (255, 255, 255))
            elif k == 3:
                arrow(d, X + 4, cy, ex + w - 6, cy, (255, 255, 255))
            elif k == 0:
                arrow(d, cx + 8, Y + 4, cx + 8, ey + h - 6, (255, 255, 255))
            else:
                arrow(d, cx - 8, Y + h - 4, cx - 8, ey + 6, (255, 255, 255))
    y = im.height - foot + 12
    d.rectangle((10, y, 30, y + 14), outline=GREEN, width=3)
    d.text((36, y - 2), 'entered by the RZX run (rex1.rzx, roomwatch p1)', fill=(230, 230, 230), font=small)
    d.rectangle((520, y, 540, y + 14), outline=ORANGE, width=3)
    d.text((546, y - 2), 'entered only with a POKE (p1-room*, p1-rooms238)', fill=(230, 230, 230), font=small)
    d.text((10, y + 22), 'arrow: an exit, from the room to the room it leads to; yellow: a weapon station; end: '
           'exit 99, the CODE panel', fill=(230, 230, 230), font=small)
    im.save(out)
    print(out, im.size)


def route_rex2(out):
    maps, exits, blocks, chars = room_maps.load('rex2')
    route, r = [0], 0
    while True:
        nxt = [e for e in exits[6 * r:6 * r + 4] if e and e != 99]
        if not nxt or nxt[0] in route:
            break
        r = nxt[0]
        route.append(r)
    names = ['up', 'right', 'down', 'left']
    cols, w, h, gx, gy, head = 7, 128, 90, 18, 34, 40
    rows = (len(route) + cols - 1) // cols
    im = Image.new('RGB', (1050, head + rows * (h + gy) + 30), (40, 40, 48))
    d = ImageDraw.Draw(im)
    font, small = K.font(16), K.font(13)
    d.text((10, 8), 'REX 2: the one route, rooms 0-25 in the order the exits take them (read the rows left to right)',
           fill=(240, 240, 240), font=font)
    for i, r in enumerate(route):
        X, Y = 12 + (i % cols) * (w + gx), head + (i // cols) * (h + gy)
        im.paste(tile(room_maps.room_picture(maps, blocks, chars, r), w, h), (X, Y))
        colour = GREEN if r not in POKED['rex2'] else ORANGE
        d.rectangle((X - 2, Y - 2, X + w + 1, Y + h + 1), outline=colour, width=2)
        d.rectangle((X, Y, X + 24, Y + 16), fill=(255, 255, 255))
        d.text((X + 2, Y), str(r), fill=(0, 0, 0), font=small)
        way = [names[k] for k in range(4) if exits[6 * r + k] and exits[6 * r + k] != 99]
        label = ('exit ' + way[0]) if way else 'the boss: no exit'
        d.text((X, Y + h + 3), label, fill=(230, 230, 230), font=small)
    y = im.height - 24
    d.text((10, y), 'green frame: entered by the RZX run (roomwatch p2); every room but 0 is reached by one exit, '
           '25 has none', fill=(230, 230, 230), font=small)
    im.save(out)
    print(out, im.size, 'route', route)


def main():
    out = os.path.join(C, 'docs/img/maps')
    os.makedirs(out, exist_ok=True)
    world_rex1(os.path.join(out, 'world-rex1.png'))
    route_rex2(os.path.join(out, 'route-rex2.png'))


if __name__ == '__main__':
    sys.exit(main())

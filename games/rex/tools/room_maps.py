#!/usr/bin/env python3
"""Every room of a part and the part's world map, drawn from the resources (not from the image): src/res/rooms/PART.txt
(the maps, the exits), src/res/blocks/PART.csv (3 x 3 characters a block) and src/res/chars/PART.png (the 256
characters with their attributes), read back through tools/res_formats.py.

    python3 tools/room_maps.py [--part rex1|rex2|demo|all] [--out build/rooms] [--scale 1]

writes OUT/PART/room-NN.png (30 x 21 characters: 240 x 168 pixels) and OUT/PART/map.png: the rooms placed on a grid by
their exits from the first room (REX 1 and REX 2: room 1; DEMO: room 4, the first TutorRooms plays), each with its
number; a room the exits never reach goes in a row of its own below. An exit that disagrees with the grid is listed.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402
import res_formats as rf  # noqa: E402

FIRST = {'rex1': 1, 'rex2': 1, 'demo': 4}
PALETTE = [kitlib.ink_colour(i, b) for b in (0, 1) for i in range(8)]


def load(part):
    res = rf.RES
    rooms = rf.GROUPS['rooms/%s.txt' % part][2](open(os.path.join(res, 'rooms', part + '.txt'), 'rb').read())
    blocks = rf.SINGLES['blocks/%s.bin' % part][2](open(os.path.join(res, 'blocks', part + '.csv'), 'rb').read())
    chars = rf.png_to_chars(open(os.path.join(res, 'chars', part + '.png'), 'rb').read())
    maps, exits = rooms['rooms/%s-maps.bin' % part], rooms['rooms/%s-exits.bin' % part]
    return maps, exits, blocks, chars


def room_picture(maps, blocks, chars, room):
    im = Image.new('RGB', (240, 168))
    px = im.load()
    for by in range(7):
        for bx in range(10):
            block = maps[room * 70 + by * 10 + bx]
            for cy in range(3):
                for cx in range(3):
                    ch = blocks[block * 9 + cy * 3 + cx]
                    at = chars[2048 + ch]
                    bright = 8 if at & 64 else 0
                    ink, paper = PALETTE[(at & 7) + bright], PALETTE[((at >> 3) & 7) + bright]
                    for y in range(8):
                        row = chars[ch * 8 + y]
                        for x in range(8):
                            px[(bx * 3 + cx) * 8 + x, (by * 3 + cy) * 8 + y] = ink if row & (128 >> x) else paper
    return im


def draw_part(part, out, scale):
    maps, exits, blocks, chars = load(part)
    n_maps, n_exits = len(maps) // 70, len(exits) // 6
    os.makedirs(out, exist_ok=True)
    pics = {}
    for r in range(n_maps):
        pics[r] = room_picture(maps, blocks, chars, r)
        pics[r].resize((240 * scale, 168 * scale), Image.NEAREST).save(os.path.join(out, 'room-%02d.png' % r))
    step = [(0, -1), (1, 0), (0, 1), (-1, 0)]  # up, right, down, left
    first = FIRST[part]
    pos, queue, odd = {first: (0, 0)}, [first], []
    while queue:
        r = queue.pop(0)
        if r >= n_exits:
            continue
        for d in range(4):
            n = exits[6 * r + d]
            if not n or n == 99 or n >= n_maps:
                continue
            p = (pos[r][0] + step[d][0], pos[r][1] + step[d][1])
            if n not in pos:
                if p in pos.values():
                    odd.append('room %d from %d (exit %d): the cell is taken' % (n, r, d))
                pos[n] = p
                queue.append(n)
            elif pos[n] != p:
                odd.append('room %d from %d (exit %d): placed at %s, the exit says %s' % (n, r, d, pos[n], p))
    reached = len(pos)
    xs, ys = [p[0] for p in pos.values()], [p[1] for p in pos.values()]
    x0, y_end = min(xs), max(ys) + 1
    rest = [r for r in range(n_maps) if r not in pos]
    for i, r in enumerate(rest):
        pos[r] = (x0 + i % 8, y_end + i // 8)
    xs, ys = [p[0] for p in pos.values()], [p[1] for p in pos.values()]
    x0, y0 = min(xs), min(ys)
    W, H, G = 240, 168, 24
    o = Image.new('RGB', ((max(xs) - x0 + 1) * (W + G), (max(ys) - y0 + 1) * (H + G)), (60, 60, 60))
    dr = ImageDraw.Draw(o)
    f = kitlib.font(30)
    for r, (x, y) in pos.items():
        X, Y = (x - x0) * (W + G) + G // 2, (y - y0) * (H + G) + G // 2
        o.paste(pics[r], (X, Y))
        dr.rectangle((X, Y, X + 60, Y + 34), fill='white' if r not in rest else 'orange')
        dr.text((X + 3, Y + 1), str(r), fill='black', font=f)
        if r < n_exits and 99 in exits[6 * r:6 * r + 4]:
            dr.rectangle((X + 175, Y, X + 240, Y + 34), fill='yellow')
            dr.text((X + 180, Y + 1), 'end', fill='black', font=f)
    o.save(os.path.join(out, 'map.png'))
    print('%s: %d rooms drawn, %d placed by the exits from room %d, %d below (%s); map %dx%d'
          % (part, n_maps, reached, first, len(rest), ' '.join(map(str, rest)) or '-', o.size[0], o.size[1]))
    for line in odd:
        print('  ' + line)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--part', default='all', choices=['rex1', 'rex2', 'demo', 'all'])
    ap.add_argument('--out', default=os.path.join(rf.ROOT, 'build', 'rooms'))
    ap.add_argument('--scale', type=int, default=1)
    a = ap.parse_args()
    for part in (['rex1', 'rex2', 'demo'] if a.part == 'all' else [a.part]):
        draw_part(part, os.path.join(a.out, part), a.scale)


if __name__ == '__main__':
    main()

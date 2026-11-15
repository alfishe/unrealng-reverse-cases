#!/usr/bin/env python3
"""Rex's rooms drawn from the level data of a part's 64 K image (tools/image.py), a first look (stage 1):

- RoomExits `$B133` (part 1): 6 bytes a room, the rooms up, right, down and left (0: no exit; 99 the end) and a word,
  the room's object list (read at `$C8EF`);
- RoomMaps `$75E0`: 70 bytes a room, 7 rows of 10 block codes (`$C745`);
- BlockDefs `$6CE0`: 9 character codes a block, 3 x 3 (`$C788`);
- CharGraphics `$63E0`: 8 bytes a character (`$C818`), CharAttrs `$6BE0`: one attribute a character (`$C7EA`).

Part 2 holds the same tables 550 bytes higher or more: exits `$B1A7` (`$C965`), maps `$7806` (`$C7D4`), blocks `$6F06`,
characters `$6606`, attributes `$6E06` (`$C853`); 25 rooms.

A room is 30 x 21 characters, drawn at character row 3 of the screen (the attributes from `$5860`).

    python3 tools/rooms.py IMAGE OUTDIR [--part 1|2] [--scale 2]

writes OUTDIR/room-NN.png for each room and OUTDIR/map.png, the rooms placed on a grid by their exits from the
first room (a room whose exits disagree with the grid is drawn where it was first reached and listed).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

TABLES = {'1': dict(exits=0xB133, maps=0x75E0, blocks=0x6CE0, gfx=0x63E0, attrs=0x6BE0, rooms=35, first=1),
          '2': dict(exits=0xB1A7, maps=0x7806, blocks=0x6F06, gfx=0x6606, attrs=0x6E06, rooms=26, first=1)}
PALETTE = [kitlib.ink_colour(i, b) for b in (0, 1) for i in range(8)]


def room_picture(m, t, room):
    im = Image.new('RGB', (240, 168))
    px = im.load()
    for by in range(7):
        for bx in range(10):
            block = m[t['maps'] + room * 70 + by * 10 + bx]
            for cy in range(3):
                for cx in range(3):
                    ch = m[t['blocks'] + block * 9 + cy * 3 + cx]
                    at = m[t['attrs'] + ch]
                    ink, paper = PALETTE[(at & 7) + (8 if at & 64 else 0)], PALETTE[((at >> 3) & 7) + (8 if at & 64 else 0)]
                    for y in range(8):
                        row = m[t['gfx'] + ch * 8 + y]
                        for x in range(8):
                            px[(bx * 3 + cx) * 8 + x, (by * 3 + cy) * 8 + y] = ink if row & (128 >> x) else paper
    return im


def exits(m, t, room):
    e = m[t['exits'] + room * 6:t['exits'] + room * 6 + 6]
    return {'up': e[0], 'right': e[1], 'down': e[2], 'left': e[3]}, e[4] | e[5] << 8


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('out')
    ap.add_argument('--part', default='1')
    ap.add_argument('--scale', type=int, default=1)
    a = ap.parse_args()
    m = open(a.image, 'rb').read()
    t = TABLES[a.part]
    os.makedirs(a.out, exist_ok=True)
    pics = {}
    for r in range(1, t['rooms']):
        pics[r] = room_picture(m, t, r)
        pics[r].resize((240 * a.scale, 168 * a.scale), Image.NEAREST).save(os.path.join(a.out, f'room-{r:02d}.png'))
    step = {'up': (0, -1), 'right': (1, 0), 'down': (0, 1), 'left': (-1, 0)}
    pos, queue, odd = {t['first']: (0, 0)}, [t['first']], []
    while queue:
        r = queue.pop(0)
        for d, n in exits(m, t, r)[0].items():
            if not n or n == 99:
                continue
            p = (pos[r][0] + step[d][0], pos[r][1] + step[d][1])
            if n not in pos:
                if p in pos.values():
                    odd.append(f'room {n} from {r} {d}: the cell is taken')
                pos[n] = p
                queue.append(n)
            elif pos[n] != p:
                odd.append(f'room {n} from {r} {d}: placed at {pos[n]}, the exit says {p}')
    xs, ys = [p[0] for p in pos.values()], [p[1] for p in pos.values()]
    x0, y0 = min(xs), min(ys)
    W, H, G = 240, 168, 24
    o = Image.new('RGB', ((max(xs) - x0 + 1) * (W + G), (max(ys) - y0 + 1) * (H + G)), (60, 60, 60))
    dr = ImageDraw.Draw(o)
    f = kitlib.font(30)
    for r, (x, y) in pos.items():
        X, Y = (x - x0) * (W + G) + G // 2, (y - y0) * (H + G) + G // 2
        o.paste(pics[r], (X, Y))
        e, objs = exits(m, t, r)
        dr.rectangle((X, Y, X + 170, Y + 34), fill='white')
        dr.text((X + 3, Y + 1), f'{r} ${t["maps"] + r * 70:04X}', fill='black', font=f)
        if e['up'] == 99:
            dr.rectangle((X + 175, Y, X + 240, Y + 34), fill='yellow')
            dr.text((X + 180, Y + 1), 'end', fill='black', font=f)
    o.save(os.path.join(a.out, 'map.png'))
    print(f'{len(pos)} rooms placed of {t["rooms"] - 1}; size {o.size}')
    for line in odd:
        print(line)
    for r in range(1, t['rooms']):
        if r not in pos:
            print(f'room {r}: not reached from room {t["first"]}')


if __name__ == '__main__':
    main()

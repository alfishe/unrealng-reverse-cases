#!/usr/bin/env python3
"""The world map of Tujad: the 128 rooms as an 8 x 16 grid (room `$6363`: +1 east, +8 south), each cell the play
area (screen rows 48-191, below the panel) of one screenshot taken in that room by a stage 1 recording.

    python3 tools/fig_worldmap.py work/stage1/rec docs/img/play/world-map.png [--json work/stage1/world-map.json]

The shot of a room is, in this order of preference: one whose shots before and after (record.py --shot) are in
the same room (the room drawn whole), one whose shot before is in the same room, any shot in the room; within each,
a recording without a POKE before a room tour (the tours' panel is not shown here). A shot whose play area is mostly
grey (the ROM's editor: the recording crashed) is dropped with every later shot of its recording, one mostly yellow
(the progress screen) alone. In a room tour, a shot whose room is still the last value poked into `$6363` is
dropped: the game drew no room for it. The 26 table entries that share the empty record are drawn as "no room".
"""
import argparse
import glob
import json
import os

from PIL import Image, ImageDraw, ImageFont

COLS, ROWS, TW, TH = 8, 16, 112, 63
BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (150, 150, 160), (70, 70, 90)


def font(size):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def unusable(png):
    """A play area mostly grey (the ROM's editor after a crash) or yellow (the progress screen): not a room"""
    px = list(Image.open(png).convert('RGB').crop((0, 48, 256, 192)).getdata())
    grey = sum(1 for c in px if c[0] == c[1] == c[2] and c[0] > 150) / len(px)
    yellow = sum(1 for c in px if c[0] > 150 and c[1] > 150 and c[2] < 80) / len(px)
    return grey > 0.3, yellow > 0.3


def empty_rooms(image):
    """The rooms whose entry in the room table (`$DB53` + 2 x room, an offset from `$DB53`) is the shared empty
    record (the offset most entries share)"""
    o = open(image, 'rb').read()
    offs = [o[0xDB53 + 2 * r] | o[0xDB54 + 2 * r] << 8 for r in range(128)]
    common = max(set(offs), key=offs.count)
    return {r for r in range(128) if offs[r] == common}, 0xDB53 + common


def candidates(rec):
    out = {}
    for path in sorted(glob.glob(os.path.join(rec, '*', 'states.json'))):
        d = os.path.dirname(path)
        name = os.path.basename(d)
        if not os.path.exists(os.path.join(d, 'record.json')) or not os.path.exists(os.path.join(d, 'session.ttd')):
            continue
        info = json.load(open(os.path.join(d, 'record.json')))
        poked = bool(info.get('pokes'))
        room_pokes = []  # (frame, value) of every POKE of the room $6363
        for spec in info.get('pokes', []):
            lines = open(spec).read().split('\n') if os.path.exists(spec) else [spec.replace(',', ' ')]
            for ln in lines:
                f = ln.split()
                if len(f) == 3 and not ln.startswith('#') and int(f[1].replace('$', '0x'), 0) == 0x6363:
                    room_pokes.append((int(f[0]), int(f[2].replace('$', '0x'), 0)))
        st = json.load(open(path))
        crashed = False
        for i in range(1, len(st) - 1):
            r = st[i]['room']
            if not isinstance(r, int) or not 0 <= r < 128:
                continue
            last = [v for f, v in room_pokes if f < st[i]['frame']]
            if last and last[-1] == r:
                continue  # still the poked room: the game has not moved into a room it drew
            tier = 0 if st[i - 1]['room'] == r == st[i + 1]['room'] else 1 if st[i - 1]['room'] == r else 2
            png = os.path.join(d, 'screens', f"{st[i]['frame']:06d}.png")
            if not os.path.exists(png):
                continue
            grey, yellow = unusable(png)
            crashed = crashed or grey
            if crashed or yellow:
                continue
            key = (tier, poked, name, st[i]['frame'])
            if r not in out or key < out[r][0]:
                out[r] = (key, png)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('rec')
    p.add_argument('png')
    p.add_argument('--json')
    p.add_argument('--image', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'work', 'mkgame',
                                                   'original.bin'))
    a = p.parse_args()
    rooms = candidates(a.rec)
    empty, record = empty_rooms(a.image)
    top, left, gap = 78, 34, 4
    W = left + COLS * (TW + gap) + 8
    H = top + ROWS * (TH + gap) + 40
    S = Image.new('RGB', (W, H), BG)
    dr = ImageDraw.Draw(S)
    dr.text((8, 6), 'Tujad: the 128 rooms (8 x 16, room = 8 x row + column)', fill=TEXT, font=font(20))
    real = [r for r in range(128) if r not in empty]
    shot = [r for r in real if r in rooms]
    dr.text((8, 34), f'{len(shot)} of the {len(real)} rooms shot by the stage 1 recordings; number = room (decimal)',
            fill=DIM, font=font(13))
    dr.text((8, 52), f'"no room": the room table entry (${0xDB53:04X} + 2 x room) points to the empty record '
                     f'${record:04X}', fill=DIM, font=font(13))
    f = font(12)
    for row in range(ROWS):
        dr.text((4, top + row * (TH + gap) + TH // 2 - 7), f'{row * 8:3d}', fill=DIM, font=f)
        for col in range(COLS):
            r = row * 8 + col
            x, y = left + col * (TW + gap), top + row * (TH + gap)
            if r in empty:
                dr.rectangle((x, y, x + TW - 1, y + TH - 1), fill=(40, 40, 48), outline=GRID)
                dr.text((x + 2, y), f'{r}', fill=DIM, font=f)
                dr.text((x + 30, y + TH // 2 - 7), 'no room', fill=DIM, font=f)
            elif r in rooms:
                im = Image.open(rooms[r][1]).convert('RGB').crop((0, 48, 256, 192)).resize((TW, TH), Image.LANCZOS)
                S.paste(im, (x, y))
                tag = f'{r}' + ('*' if rooms[r][0][1] else '')
                dr.rectangle((x, y, x + 8 * len(tag) + 3, y + 14), fill=(0, 0, 0))
                dr.text((x + 2, y), tag, fill=(255, 255, 0), font=f)
            else:
                dr.rectangle((x, y, x + TW - 1, y + TH - 1), outline=GRID)
                dr.text((x + 2, y), f'{r}', fill=GRID, font=f)
    dr.text((8, H - 30), '* shot in a room tour (a POKE of the room $6363), else in a recording without a POKE',
            fill=DIM, font=f)
    os.makedirs(os.path.dirname(os.path.abspath(a.png)), exist_ok=True)
    S.save(a.png)
    if a.json:
        json.dump({str(r): {'png': v[1], 'poked': v[0][1], 'tier': v[0][0]} for r, v in sorted(rooms.items())}, open(a.json, 'w'),
                  indent=1)
    print(a.png, S.size, len(shot), 'of', len(real), 'rooms; missing', [r for r in real if r not in rooms],
          'empty', sorted(empty), f'record {record:04X}')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 7's room figures, drawn from the resources (src/res/rooms, blocks, chars, tables/*-char-flags.csv) through
tools/room_maps.py and tools/res_formats.py, never from the image.

    python3 tools/fig_rooms.py decode OUT.png [--part rex1] [--room 1]   one room decoded: the exits record and the
                                       object list as bytes, the 7 x 10 block codes over the room, one block taken
                                       apart into its 3 x 3 characters, the cell types (CharFlags) of the room grid
                                       with the list's objects placed
    python3 tools/fig_rooms.py types OUT.png [--part rex1]   every cell type of a part: the characters of each type
"""
import argparse
import csv
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402
import room_maps  # noqa: E402
import res_formats as rf  # noqa: E402

KINDS = {0: 'foot man', 1: 'stomper', 2: 'kind 2', 3: 'kind 3', 4: 'kind 4', 5: 'kind 5', 6: 'kind 6',
         7: 'kind 7', 8: 'scanner', 9: 'swing gun', 10: 'shooters', 11: 'launcher', 12: 'ramming pod',
         13: 'mine layer', 14: 'mine', 15: 'blob', 16: 'big gun', 17: 'swing gun 1', 18: 'swing gun 2',
         19: 'swing gun 3', 20: 'swing gun 4', 0x7D: 'bonus pod'}
TYPE_COLOURS = {0: None, 1: (90, 90, 110), 2: (200, 200, 210), 3: (230, 60, 60), 4: (240, 140, 60),
                5: (240, 200, 70), 6: (200, 110, 230), 7: (90, 220, 120), 8: (70, 210, 220), 9: (160, 220, 80),
                10: (250, 90, 160), 11: (250, 90, 160), 12: (250, 90, 160), 13: (250, 90, 160),
                14: (90, 150, 250), 15: (60, 100, 220), 16: (130, 170, 255), 17: (130, 170, 255),
                18: (255, 255, 255), 20: (150, 110, 70), 21: (175, 45, 65), 22: (175, 45, 65)}
TYPE_NAMES = {1: '1 ledge (stand on, walk through)', 2: '2 solid', 3: '3 kills a faller (REX 2)', 4: '4 solid, a bullet damages it',
              5: '5 solid, damaged', 6: '6 solid, damaged', 7: '7 restart marker', 8: '8 shield recharger',
              9: '9 conveyor (DEMO)', 10: '$0A laser station', 11: '$0B multiple station',
              12: '$0C spray station', 13: '$0D double station', 14: '$0E platform: a walker hops',
              15: '$0F platform: a walker drops', 16: '$10 platform: jump right', 17: '$11 platform: jump left',
              18: '$12 ladder or lift', 20: '$14 (DEMO)', 21: '$15 dissolves walkers (REX 2)',
              22: '$16 dissolves walkers (REX 2)'}


def char_flags(part):
    out = [0] * 256
    for row in csv.reader(open(os.path.join(rf.RES, 'tables', part + '-char-flags.csv'))):
        if row and row[0].strip().isdigit():
            out[int(row[0])] = rf.num(row[1].strip())
    return out


def object_lists(part):
    """{address: (header bytes, [(kind, x, y)])} from the rooms file's list lines"""
    out = {}
    for line in open(os.path.join(rf.RES, 'rooms', part + '.txt')):
        if not line.startswith('list '):
            continue
        head, _, rest = line.partition(':')
        addr = int(head.split()[1].lstrip('$'), 16)
        parts = [p.split() for p in rest.split('|')]
        header = [int(b.lstrip('$'), 16) for b in parts[0]]
        objs = [tuple(int(b.lstrip('$'), 16) for b in p) for p in parts[1:] if p and p[0] != '$FF']
        out[addr] = (header, objs)
    return out


def text(d, xy, s, f, fill=kitlib.TEXT, anchor='la'):
    d.text(xy, s, font=f, fill=fill, anchor=anchor)


def cmd_decode(args):
    part, room = args.part, args.room
    maps, exits, blocks, chars = room_maps.load(part)
    flags = char_flags(part)
    lists = object_lists(part)
    ex = exits[room * 6:room * 6 + 6]
    laddr = ex[4] | ex[5] << 8
    header, objs = lists[laddr]
    f = kitlib.font(13)
    fb = kitlib.font(15)
    fs = kitlib.font(12)
    W, S = 1050, 2
    pic = room_maps.room_picture(maps, blocks, chars, room).resize((240 * S, 168 * S), Image.NEAREST)
    H = 1040
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    text(d, (10, 8), f'{part.upper()} room {room}: the exits record, the object list, the block map and the cell '
         'grid, all from src/res', fb)
    # the exits record
    y = 36
    text(d, (10, y), f'RoomExits + 6 x {room} = ${0xB133 + 6 * room:04X}:' if part == 'rex1' else
         f'RoomExits + 6 x {room}:', f)
    labels = ['up', 'right', 'down', 'left', 'list lo', 'list hi']
    x = 250
    for k, b in enumerate(ex):
        d.rectangle((x, y - 2, x + 70, y + 36), outline=kitlib.DIM, fill=kitlib.PANEL)
        text(d, (x + 35, y), f'${b:02X}', fb, anchor='ma')
        text(d, (x + 35, y + 19), labels[k], fs, fill=kitlib.DIM, anchor='ma')
        x += 74
    text(d, (x + 6, y), f'exits: up {ex[0]}, right {ex[1]}, down {ex[2]}, left {ex[3]} (0 none)', fs)
    text(d, (x + 6, y + 18), f'object list at ${laddr:04X}', fs)
    # the object list
    y = 86
    text(d, (10, y), f'RoomObjectLists ${laddr:04X}:', f)
    x = 250
    hdr_lbl = [f'sides {"T" if header[0] & 128 else "-"}{"R" if header[0] & 64 else "-"}{"L" if header[0] & 32 else "-"}'
               f', {header[0] & 31} slots', f'period {header[1]}', f'spawn kind ${header[2]:02X}' if len(header) > 2 else '']
    for k, b in enumerate(header):
        d.rectangle((x, y - 2, x + 150, y + 36), outline=(240, 200, 70), fill=kitlib.PANEL)
        text(d, (x + 75, y), f'${b:02X}', fb, anchor='ma')
        text(d, (x + 75, y + 19), hdr_lbl[k], fs, fill=kitlib.DIM, anchor='ma')
        x += 154
    y = 132
    x = 10
    for n, (kind, ox, oy) in enumerate(objs):
        col = kitlib.ROUTINE_COLOURS[n % len(kitlib.ROUTINE_COLOURS)]
        d.rectangle((x, y - 2, x + 252, y + 36), outline=col, fill=kitlib.PANEL)
        text(d, (x + 6, y), f'${kind:02X} ${ox:02X} ${oy:02X}', fb)
        k = kind & 0x7F
        text(d, (x + 6, y + 19), f'{KINDS.get(k, "kind %d" % k)}{", faces left" if kind & 128 else ""}, '
             f'X {ox}, Y {oy * 8}', fs, fill=kitlib.DIM)
        x += 258
        if x > W - 250:
            x, y = 10, y + 44
    y += 44
    d.rectangle((x, y - 46, x + 60, y - 10), outline=kitlib.DIM, fill=kitlib.PANEL)
    text(d, (x + 30, y - 44), '$FF', fb, anchor='ma')
    text(d, (x + 30, y - 25), 'end', fs, fill=kitlib.DIM, anchor='ma')
    # the room with the block codes
    top = y + 10
    text(d, (10, top), 'RoomMaps: 7 x 10 block codes over the room', f)
    px0, py0 = 10, top + 22
    im.paste(pic, (px0, py0))
    for by in range(7):
        for bx in range(10):
            code = maps[room * 70 + by * 10 + bx]
            x0, y0 = px0 + bx * 24 * S, py0 + by * 24 * S
            d.rectangle((x0, y0, x0 + 24 * S - 1, y0 + 24 * S - 1), outline=(255, 255, 0))
            d.rectangle((x0 + 1, y0 + 1, x0 + 22, y0 + 16), fill=(0, 0, 0))
            text(d, (x0 + 3, y0 + 2), f'{code:02X}', fs, fill=(255, 255, 0))
    # the cell types with the objects
    tx0 = px0 + 240 * S + 20
    text(d, (tx0, top), 'the grid: CharFlags types; the list objects', f)
    cs = 16 if W - tx0 >= 30 * 16 else 15
    present = set()
    for cy in range(21):
        for cx in range(30):
            block = maps[room * 70 + (cy // 3) * 10 + cx // 3]
            ch = blocks[block * 9 + (cy % 3) * 3 + cx % 3]
            t = flags[ch]
            present.add(t)
            col = TYPE_COLOURS.get(t)
            x0, y0 = tx0 + cx * cs, py0 + cy * cs
            d.rectangle((x0, y0, x0 + cs - 1, y0 + cs - 1), fill=col or (30, 30, 40), outline=(50, 50, 60))
    for n, (kind, ox, oy) in enumerate(objs):
        col = kitlib.ROUTINE_COLOURS[n % len(kitlib.ROUTINE_COLOURS)]
        x0 = tx0 + (ox / 8) * cs
        y0 = py0 + (oy - 3) * cs        # the grid's play rows start at character row 3
        d.rectangle((x0, y0, x0 + 2 * cs, y0 + 2 * cs), outline=col, width=3)
        text(d, (x0 + 2, y0 + 2 * cs + 1), f'{n + 1}', fs, fill=col)
    # legend
    ly = py0 + 21 * cs + 8
    lx = tx0
    items = [t for t in sorted(present) if t] + [0]
    half = (len(items) + 1) // 2
    for k, t in enumerate(items):
        x = lx + (k // half) * 250
        y1 = ly + (k % half) * 17
        col = TYPE_COLOURS.get(t) or (30, 30, 40)
        d.rectangle((x, y1, x + 12, y1 + 12), fill=col, outline=(50, 50, 60))
        text(d, (x + 18, y1 - 1), TYPE_NAMES.get(t, '0 empty'), fs)
    legend_bottom = ly + half * 17
    # one block taken apart
    by0 = py0 + 168 * S + 16
    pick = args.block if args.block is not None else max(set(maps[room * 70:room * 70 + 70]) - {0},
                                                          key=lambda b: len({blocks[b * 9 + k] for k in range(9)}))
    text(d, (10, by0), f'block ${pick:02X} (BlockDefs + 9 x ${pick:02X}): its 9 characters', f)
    yy = by0 + 22
    for cy in range(3):
        for cx in range(3):
            ch = blocks[pick * 9 + cy * 3 + cx]
            x0 = 10 + cx * 150
            y0 = yy + cy * 54
            at = chars[2048 + ch]
            bright = 8 if at & 64 else 0
            ink, paper = room_maps.PALETTE[(at & 7) + bright], room_maps.PALETTE[((at >> 3) & 7) + bright]
            for r in range(8):
                row = chars[ch * 8 + r]
                for b in range(8):
                    d.rectangle((x0 + b * 6, y0 + r * 6, x0 + b * 6 + 5, y0 + r * 6 + 5),
                                fill=ink if row & (128 >> b) else paper)
            text(d, (x0 + 54, y0), f'char ${ch:02X}', fs)
            text(d, (x0 + 54, y0 + 16), f'attr ${at:02X}', fs, fill=kitlib.DIM)
            text(d, (x0 + 54, y0 + 32), f'type {flags[ch]}', fs, fill=kitlib.DIM)
    bottom = max(yy + 3 * 54, legend_bottom) + 10
    im = im.crop((0, 0, W, bottom))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


def cmd_types(args):
    part = args.part
    _, _, _, chars = room_maps.load(part)
    flags = char_flags(part)
    f = kitlib.font(13)
    fs = kitlib.font(12)
    W = 1050
    groups = {}
    for ch, t in enumerate(flags):
        if t:
            groups.setdefault(t, []).append(ch)
    rows = []
    for t in sorted(groups):
        n = len(groups[t])
        per = (W - 280) // 22
        rows.append((t, (n + per - 1) // per))
    H = 40 + sum(r * 24 + 8 for _, r in rows) + 10
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    text(d, (10, 8), f'{part.upper()}: the room characters of each cell type (CharFlags, '
         f'tables/{part}-char-flags.csv; type 0, empty, left out)', f)
    y = 36
    for t, nrows in rows:
        col = TYPE_COLOURS.get(t) or kitlib.TEXT
        d.rectangle((10, y + 2, 22, y + 14), fill=col)
        text(d, (28, y), TYPE_NAMES.get(t, str(t)), fs)
        x = 270
        for ch in groups[t]:
            at = chars[2048 + ch]
            bright = 8 if at & 64 else 0
            ink, paper = room_maps.PALETTE[(at & 7) + bright], room_maps.PALETTE[((at >> 3) & 7) + bright]
            for r in range(8):
                row = chars[ch * 8 + r]
                for b in range(8):
                    d.rectangle((x + b * 2, y + r * 2, x + b * 2 + 1, y + r * 2 + 1),
                                fill=ink if row & (128 >> b) else paper)
            x += 22
            if x > W - 24:
                x, y = 270, y + 24
        y += 24 + 8
    im.save(args.out)
    print(args.out, im.size)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('decode')
    p.add_argument('out')
    p.add_argument('--part', default='rex1')
    p.add_argument('--room', type=int, default=1)
    p.add_argument('--block', type=lambda s: int(s, 16))
    p = sub.add_parser('types')
    p.add_argument('out')
    p.add_argument('--part', default='rex1')
    a = ap.parse_args()
    {'decode': cmd_decode, 'types': cmd_types}[a.cmd](a)


if __name__ == '__main__':
    main()

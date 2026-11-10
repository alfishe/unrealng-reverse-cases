#!/usr/bin/env python3
"""The figures of doc 07 (objects), drawn from src/res, the RZX log and memory samples of the recordings.

    python3 tools/fig_objects.py block   --samples V.jsonl --frame F --out docs/img/objects/workspace.png
    python3 tools/fig_objects.py cells   --samples V.jsonl --cells C.jsonl --screens S.jsonl --frame F --out PNG
    python3 tools/fig_objects.py path    --samples V.jsonl --screens S.jsonl --frame F --from A --to B --out PNG
    python3 tools/fig_objects.py spawns  --log work/stage1/rzx/frames.bin --out docs/img/objects/spawns.png
    python3 tools/fig_objects.py world   --out docs/img/objects/world-objects.png
    python3 tools/fig_objects.py record  --room R --state SZX --out docs/img/objects/alien-record.png

A samples file is JSON lines {"frame": F, "hex": ...} written by work/docs/tjC/sample.py (TTD memory_at: the memory
at the start of frame F). V covers $6300-$63FF, C the cell table $60C0-$62FF, S the screen $4000-$5AFF. The RZX log
work/stage1/rzx/frames.bin holds $6300-$63FF after each of 81 000 RZX frames (tools/rzx_keys.py log).
Coordinates are the game's: the enemies' and objects' x and y are pixels of the screen (y from the top); the droid's
and the patrollers' x is a character column, their y a pixel row.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_roommap as RM  # noqa: E402
import res_formats as rf  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
WIDTH = 1050

# The work space $6303-$635D (start.asm), (first, last, name, owner)
FIELDS = [(0x6303 + 9 * k + o, 0x6303 + 9 * k + o + n - 1, f, 'enemy')
          for k in range(4) for o, n, f in ((0, 1, 'timer'), (1, 1, 'state'), (2, 1, 'x'), (3, 1, 'y'),
                                             (4, 2, 'graphic'), (6, 1, 'frame'), (7, 1, 'frames'), (8, 1, 'attr'))]
FIELDS += [(0x6327 + 10 * k + o, 0x6327 + 10 * k + o + n - 1, f, 'object')
           for k in range(2) for o, n, f in ((0, 1, 'kind'), (1, 1, 'state'), (2, 1, 'x'), (3, 1, 'y'),
                                              (4, 2, 'graphic'), (6, 1, 'frame'), (7, 1, 'frames'), (8, 1, 'mark'),
                                              (9, 1, 'attr'))]
FIELDS += [(0x633B + 8 * k + o, 0x633B + 8 * k + o + n - 1, f, 'patrol')
           for k in range(3) for o, n, f in ((0, 1, 'frame'), (1, 1, 'y+dir'), (2, 1, 'col'), (3, 1, 'room'),
                                              (4, 2, 'right end'), (6, 2, 'left end'))]
FIELDS += [(0x6353 + 2 * k, 0x6354 + 2 * k, f'P{k + 1} ptr', 'ptr') for k in range(3)]
FIELDS += [(0x6359 + o, 0x6359 + o, f, 'droid')
           for o, f in ((0, 'x'), (1, 'y'), (2, 'flags'), (3, 'frame'), (4, 'width'))]
OWNER = {'enemy': (235, 110, 90), 'object': (110, 200, 240), 'patrol': (230, 200, 80), 'ptr': (170, 170, 120),
         'droid': (120, 220, 120)}

CELL_COLOURS = {'empty': (20, 20, 26), 'wall': (90, 90, 105), 'enemy': (235, 90, 80), 'object': (90, 170, 250),
                'patrol': (235, 200, 60), 'item': (200, 110, 230), 'teleport': (70, 220, 200),
                'shot': (250, 250, 250), 'mixed': (250, 150, 40)}


def load_samples(path):
    out = {}
    for line in open(path):
        j = json.loads(line)
        out[j['frame']] = bytes.fromhex(j['hex'])
    return out


def screen_image(scr, scale=2, play_only=False):
    img = K.render_screen(scr + bytes(6912 - len(scr)) if len(scr) < 6912 else scr, 0)
    if play_only:
        img = img.crop((0, 48, 256, 192))
    return img.resize((img.width * scale, img.height * scale), Image.NEAREST)


def cell_kind(v):
    if v == 0:
        return 'empty'
    if v == 0xFF:
        return 'teleport'
    if v & 0x80:
        return 'item'
    if v == 1:
        return 'wall'
    if v & 0x70 and v & 1:
        return 'shot'
    marks = [k for b, k in ((2, 'enemy'), (4, 'object'), (8, 'patrol')) if v & b]
    return marks[0] if len(marks) == 1 else 'mixed'


def title(draw, text, y=8, size=17):
    draw.text((14, y), text, fill=TEXT, font=K.font(size))


def cmd_block(args):
    v = load_samples(args.samples)[args.frame]
    fnt, small = K.font(14), K.font(11)
    rows = [(0x6303, 9, 'enemy 0'), (0x630C, 9, 'enemy 1'), (0x6315, 9, 'enemy 2'), (0x631E, 9, 'enemy 3'),
            (0x6327, 10, 'object 1'), (0x6331, 10, 'object 2'),
            (0x633B, 8, 'patroller 1'), (0x6343, 8, 'patroller 2'), (0x634B, 8, 'patroller 3'),
            (0x6353, 6, 'PatrollerPtrs'), (0x6359, 5, 'droid')]
    bw, bh, x0, y0 = 82, 46, 190, 64
    img = Image.new('RGB', (WIDTH, y0 + len(rows) * (bh + 10) + 90), BG)
    d = ImageDraw.Draw(img)
    title(d, f'The work space $6303-$635D in {args.recording} frame {args.frame} (room {v[0x63]}), field by field')
    d.text((14, 34), 'each box: the byte (hex) and its field; the colour names the owner', fill=DIM, font=small)
    names = {a: (n, o) for lo, hi, n, o in FIELDS for a in range(lo, hi + 1)}
    for r, (base, n, label) in enumerate(rows):
        y = y0 + r * (bh + 10)
        d.text((14, y + 6), f'{label}', fill=TEXT, font=fnt)
        d.text((14, y + 24), f'${base:04X}', fill=DIM, font=small)
        for i in range(n):
            a = base + i
            name, owner = names[a]
            b = v[a - 0x6300]
            col = OWNER[owner]
            x = x0 + i * (bw + 4)
            d.rectangle([x, y, x + bw, y + bh], fill=tuple(c // 3 for c in col), outline=col)
            d.text((x + 6, y + 3), f'{b:02X}', fill=TEXT, font=fnt)
            d.text((x + 6, y + 25), name, fill=col, font=small)
    yl = y0 + len(rows) * (bh + 10) + 12
    for i, (k, lab) in enumerate((('enemy', 'enemy records (9 bytes)'), ('object', 'object records (10 bytes)'),
                                  ('patrol', 'patroller records (8 bytes)'), ('ptr', 'PatrollerPtrs (3 words)'),
                                  ('droid', 'DroidVars (5 bytes)'))):
        xl, yy = 14 + (i % 3) * 330, yl + (i // 3) * 24
        d.rectangle([xl, yy, xl + 20, yy + 16], fill=OWNER[k])
        d.text((xl + 28, yy), lab, fill=TEXT, font=small)
    img.save(args.out)
    print(args.out, img.size)


def cmd_cells(args):
    v = load_samples(args.samples)[args.frame]
    cells = load_samples(args.cells)[args.frame]
    scr = load_samples(args.screens)[args.frame]
    scale = 2
    shot = screen_image(scr, scale, play_only=True)
    cw = 15
    grid_w = 32 * cw
    img = Image.new('RGB', (WIDTH, 60 + shot.height + 90), BG)
    d = ImageDraw.Draw(img)
    title(d, f'The cell table $60C0 beside the screen: {args.recording} frame {args.frame}, room {v[0x63]}')
    img.paste(shot, (14, 50))
    gx, gy = 14 + shot.width + 24, 50
    ch = shot.height // 18
    small = K.font(10)
    for r in range(18):
        for c in range(32):
            val = cells[r * 32 + c]
            k = cell_kind(val)
            x, y = gx + c * cw, gy + r * ch
            d.rectangle([x, y, x + cw - 1, y + ch - 1], fill=CELL_COLOURS[k])
            if val not in (0, 1):
                d.text((x + 1, y + 3), f'{val:02X}', fill=(0, 0, 0) if k != 'empty' else TEXT, font=small)
    for r in range(0, 18, 3):
        d.text((gx - 22, gy + r * ch + 2), f'{r + 6}', fill=DIM, font=small)
    yl = 50 + shot.height + 14
    for i, (k, lab) in enumerate((('wall', '1 wall'), ('enemy', '2 an enemy'), ('object', '4 an object'),
                                  ('patrol', '8 a patroller'), ('item', '$80-$C3 an item'),
                                  ('teleport', '$FF a teleporter'), ('shot', 'a shot mark ($11/$21/$41)'),
                                  ('mixed', 'two marks'))):
        x = 14 + (i % 4) * 255
        y = yl + (i // 4) * 24
        d.rectangle([x, y, x + 18, y + 16], fill=CELL_COLOURS[k])
        d.text((x + 26, y), lab, fill=TEXT, font=K.font(12))
    d.text((gx, 34), 'rows 6-23 of the screen, 32 columns; the numbers left are screen rows', fill=DIM, font=small)
    img.save(args.out)
    print(args.out, img.size)


def mover_points(samples, lo, hi, which):
    pts = []
    for f in sorted(samples):
        if lo <= f <= hi:
            b = samples[f]
            if which.startswith('e'):
                k = int(which[1:])
                r = b[3 + 9 * k:12 + 9 * k]
                if r[0] and not (r[1] & 0xC0):
                    pts.append((f, r[2], r[3], r[1], 3, 16))
                elif r[0] and r[1] & 0x80:
                    pts.append((f, r[2], r[3], r[1], 3, 16))
            elif which.startswith('o'):
                k = int(which[1:])
                r = b[0x27 + 10 * k:0x31 + 10 * k]
                if r[0] & 3 and not r[1] & 0x10:
                    pts.append((f, r[2], r[3], r[1], 4, 24))
            elif which == 'droid':
                pts.append((f, b[0x59] * 8, b[0x5A], b[0x5B], b[0x5D], 40))
    return pts


def cmd_path(args):
    v = load_samples(args.samples)
    scr = load_samples(args.screens)[args.frame]
    scale = 3
    shot = screen_image(scr, scale, play_only=True).convert('RGB')
    shot = Image.blend(shot, Image.new('RGB', shot.size, (0, 0, 0)), 0.45)
    img = Image.new('RGB', (WIDTH, 70 + shot.height + 80), BG)
    img.paste(shot, ((WIDTH - shot.width) // 2, 56))
    d = ImageDraw.Draw(img)
    ox, oy = (WIDTH - shot.width) // 2, 56
    title(d, args.title)
    colours = [(255, 120, 90), (110, 230, 140), (120, 180, 255), (240, 220, 80), (230, 120, 230)]
    legend = []
    for i, which in enumerate(args.movers.split(',')):
        pts = mover_points(v, args.start, args.to, which)
        col = colours[i % len(colours)]
        prev = None
        for f, x, y, st, wb, h in pts:
            cx, cy = ox + (x + wb * 4) * scale, oy + (y - 48 + h // 2) * scale
            if prev and abs(prev[0] - cx) < 60 and abs(prev[1] - cy) < 60:
                d.line([prev, (cx, cy)], fill=col, width=3)
            prev = (cx, cy)
        for f, x, y, st, wb, h in pts[::max(1, len(pts) // 12)]:
            cx, cy = ox + (x + wb * 4) * scale, oy + (y - 48 + h // 2) * scale
            d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=col)
        if pts:
            f, x, y, st, wb, h = pts[0]
            d.rectangle([ox + x * scale, oy + (y - 48) * scale, ox + (x + wb * 8) * scale, oy + (y - 48 + h) * scale],
                        outline=col, width=2)
            legend.append((col, f'{which}: frames {pts[0][0]}-{pts[-1][0]}, from ({pts[0][1]}, {pts[0][2]}) '
                                f'to ({pts[-1][1]}, {pts[-1][2]})'))
    for i, (col, text) in enumerate(legend):
        y = oy + shot.height + 10 + i * 22
        d.rectangle([ox, y, ox + 18, y + 14], fill=col)
        d.text((ox + 26, y - 1), text, fill=TEXT, font=K.font(13))
    img.save(args.out)
    print(args.out, img.size)


def cmd_spawns(args):
    data = open(args.log, 'rb').read()
    n = len(data) // 256
    from collections import Counter
    count = Counter()
    for f in range(1, n):
        p, q = data[(f - 1) * 256:f * 256], data[f * 256:(f + 1) * 256]
        for k in range(4):
            a, b = p[3 + 9 * k:12 + 9 * k], q[3 + 9 * k:12 + 9 * k]
            if b[0] and b[1] & 0xFC == 0x44 and a[1] & 0xFC == 0x40:
                count[(b[2], b[3])] += 1
    xs = list(range(0x20, 0xD1, 8))
    ys = list(range(0x50, 0x79, 8))
    cw, ch = 34, 60
    gx, gy = 140, 90
    img = Image.new('RGB', (WIDTH, gy + len(ys) * ch + 120), BG)
    d = ImageDraw.Draw(img)
    total = sum(count.values())
    title(d, f'Where the enemies appeared: {total} spawns in the RZX game (frames 1-{n - 1}), by (x, y)')
    d.text((14, 34), 'MoveEnemy $90E7: x = Random OR $20 AND $F8 (at most $D0), y = Random OR $50 AND $78, '
                     'retried until the 2 x 2 cells are free', fill=DIM, font=K.font(12))
    top = max(count.values()) if count else 1
    small = K.font(11)
    for j, y in enumerate(ys):
        d.text((gx - 90, gy + j * ch + ch // 2 - 8), f'y ${y:02X} ({y})', fill=TEXT, font=small)
        for i, x in enumerate(xs):
            c = count.get((x, y), 0)
            t = c / top
            col = (int(30 + 220 * t), int(30 + 120 * t * t), int(60 + 40 * (1 - t))) if c else (30, 30, 36)
            d.rectangle([gx + i * cw, gy + j * ch, gx + i * cw + cw - 3, gy + j * ch + ch - 3], fill=col)
            if c:
                d.text((gx + i * cw + 4, gy + j * ch + ch // 2 - 8), str(c), fill=(0, 0, 0) if t > 0.5 else TEXT,
                       font=small)
    for i, x in enumerate(xs):
        if i % 2 == 0:
            d.text((gx + i * cw, gy + len(ys) * ch + 4), f'${x:02X}', fill=TEXT, font=small)
    d.text((gx, gy + len(ys) * ch + 24), 'x (pixels)', fill=DIM, font=small)
    other = sum(c for (x, y), c in count.items() if x not in xs or y not in ys)
    lines = [f'Spawn points outside the lattice: {other}.',
             'OR $20 keeps bit 5 set, so x is never $40-$5F, $80-$9F or $C0-$CF; OR $50 AND $78 keeps y off $60-$6F.',
             'The column at x $D0 collects every Random value from $E0 to $F8 (the clamp CP $D0): four times a column.']
    for i, text in enumerate(lines):
        d.text((14, gy + len(ys) * ch + 44 + 20 * i), text, fill=TEXT, font=K.font(13))
    img.save(args.out)
    print(args.out, img.size, total)


def parse_alien(text):
    rooms, cur = {}, None
    for ln in text.split('\n'):
        t = ln.split()
        if not t or ln.startswith('#'):
            continue
        if t[0] == 'room':
            cur = int(t[1])
            rooms[cur] = None if t[2:] == ['empty'] else {'items': [], 'teleport': None, 'enemies': [],
                                                          'objects': []}
        elif rooms.get(cur) is None:
            continue
        elif t[0] in ('item1', 'item2') and t[1] != 'none':
            rooms[cur]['items'].append(t[1])
        elif t[0] == 'teleport' and t[1] != 'none':
            rooms[cur]['teleport'] = int(t[2])
            rooms[cur]['teleport_at'] = tuple(int(v) for v in t[4].split(','))
        elif t[0] == 'enemies' and t[1] != 'none':
            rooms[cur]['enemies'] = [int(x) for x in t[1].split(',')]
        elif t[0] in ('object1', 'object2') and t[1] != 'none':
            kv = dict(x.split('=') for x in t[1:])
            rooms[cur]['objects'].append(kv)
    return rooms


def object_kind_name(kind):
    k = int(kind[1:], 16)
    for bit, name in ((4, 'head'), (5, 'brain'), (6, 'insect'), (7, 'ball')):
        if k & (1 << bit):
            return name
    return 'box'


PATROLLERS = [(0x98, 0x78, 0x13, 0x7B, 0x10), (0x90, 0x00, 0x1B, 0x05, 0x07), (0x98, 0x6B, 0x16, 0x6D, 0x19)]


def cmd_world(args):
    text = open(os.path.join(RM.RES, 'rooms', 'Rooms.txt'), encoding='utf-8').read()
    alien = parse_alien(text)
    lay = RM.parse_rooms(text)
    mem = bytearray(0x10000)
    tables = RM.load('tiles/TileTables.txt', 'tiles/TileTables.bin')
    mem[RM.TILE_TABLES:RM.TILE_TABLES + len(tables)] = tables
    data = RM.load('tiles/TileData.png', 'tiles/TileData.bin')
    mem[RM.TILE_DATA:RM.TILE_DATA + len(data)] = data
    cw, chh, lab = 128, 72, 40
    gx, gy = 14, 70
    img = Image.new('RGB', (WIDTH, gy + 16 * (chh + lab + 4) + 82), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The alien map $DB53 on the world: items, teleporters, enemies, objects and patrollers, room by room')
    d.text((14, 34), 'each room: its play area drawn from its layout (dimmed); below it the room number, the enemy '
                     'slots of its mask (E), the objects (O)', fill=DIM, font=K.font(11))
    d.text((14, 50), 'and the items as the image deals them (NewGame moves every non-weapon item, doc 10.9); a '
                     'teleporter is an orange square, joined to its target', fill=DIM, font=K.font(11))
    small, tiny = K.font(11), K.font(10)
    centres = {}
    for n in range(128):
        x0 = gx + (n % 8) * (cw + 2)
        y0 = gy + (n // 8) * (chh + lab + 4)
        centres[n] = (x0 + cw // 2, y0 + chh // 2)
        r = lay[n]
        if r is None:
            d.rectangle([x0, y0, x0 + cw - 1, y0 + chh - 1], fill=(44, 44, 52))
            d.text((x0 + 4, y0 + chh + 2), f'{n} empty', fill=DIM, font=small)
            continue
        s = RM.Screen()
        for c, rr, t in r['tiles']:
            s.draw_tile(mem, c, rr, t)
        th = s.image().resize((cw, chh), Image.BILINEAR)
        th = Image.blend(th, Image.new('RGB', th.size, (0, 0, 0)), 0.55)
        img.paste(th, (x0, y0))
        a = alien[n]
        ens = ''.join(str(e) for e in a['enemies']) or '-'
        d.text((x0 + 2, y0 + chh + 1), f'{n}', fill=TEXT, font=small)
        d.text((x0 + 30, y0 + chh + 1), f'E{ens}', fill=(235, 110, 90), font=small)
        if a['objects']:
            d.text((x0 + 62, y0 + chh + 1), 'O ' + ' '.join(object_kind_name(o['kind']) for o in a['objects']),
                   fill=(110, 200, 240), font=tiny)
        items = ' '.join(a['items'])
        d.text((x0 + 2, y0 + chh + 16), items.replace('weapon', 'w').replace('energy', 'en'),
               fill=(200, 140, 240), font=tiny)
        for o in a['objects']:
            ox, oy = int(o['x']), int(o['y'])
            px, py = x0 + int((ox + 16) * cw / 256), y0 + int((oy - 48 + 12) * chh / 144)
            d.ellipse([px - 5, py - 5, px + 5, py + 5], outline=(110, 200, 240), width=2)
    game = open(os.path.join(HERE, '..', 'build', 'game.bin'), 'rb').read()
    for n in range(128):
        if lay[n] is None:
            continue
        sx, sy = game[0x9484 - 0x60C0 + 2 * n], game[0x9485 - 0x60C0 + 2 * n]
        x0 = gx + (n % 8) * (cw + 2) + sx * cw // 32
        y0 = gy + (n // 8) * (chh + lab + 4) + (sy - 48) * chh // 144
        d.rectangle([x0, y0, x0 + 3 * cw // 32, y0 + 40 * chh // 144], outline=(250, 250, 250), width=2)
    for k, (y, lroom, lcol, rroom, rcol) in enumerate(PATROLLERS):
        rooms = list(range(lroom, rroom + 1))
        for rn in rooms:
            x0 = gx + (rn % 8) * (cw + 2)
            y0 = gy + (rn // 8) * (chh + lab + 4)
            a = lcol if rn == lroom else 0
            b = rcol if rn == rroom else 0x1D
            py = y0 + int((y - 48 + 12) * chh / 144)
            d.line([x0 + a * cw // 32, py, x0 + (b + 4) * cw // 32, py], fill=(240, 210, 60), width=4)
        x0 = gx + (lroom % 8) * (cw + 2)
        y0 = gy + (lroom // 8) * (chh + lab + 4)
        d.text((x0 + 2, y0 + 2), f'P{k + 1}', fill=(240, 210, 60), font=small)
    tel = (255, 140, 30)

    def tele_place(n):
        # The teleporter's top cells: column C, screen row R + 8 (ItemCell with the base CellTable + 64)
        c, r = alien[n]['teleport_at']
        return (gx + (n % 8) * (cw + 2) + c * cw // 32, gy + (n // 8) * (chh + lab + 4) + (r + 8 - 6) * chh // 18)

    for n in range(128):
        a = alien.get(n)
        if a and a['teleport'] is not None:
            (x1, y1) = tele_place(n)
            t = a['teleport']
            (x2, y2) = tele_place(t) if alien.get(t) and alien[t].get('teleport_at') else centres[t]
            d.line([x1 + 4, y1 + 4, x2 + 4, y2 + 4], fill=tel, width=2)
    for n in range(128):
        a = alien.get(n)
        if a and a['teleport'] is not None:
            (x1, y1) = tele_place(n)
            d.rectangle([x1 - 1, y1 - 1, x1 + 2 * cw // 32 + 1, y1 + 2 * chh // 18 + 1], fill=tel, outline=(255, 230, 180))
    yl = gy + 16 * (chh + lab + 4) + 6
    for i, (col, lab_) in enumerate((((235, 110, 90), 'E: the enemy slots (mask bits 0-3)'),
                                     ((110, 200, 240), 'O and circle: an object, its kind and start place'),
                                     ((200, 140, 240), 'the items (ed n, gen19, en, w n)'),
                                     ((240, 210, 60), 'P1-P3: a patroller\'s row, end to end'),
                                     ((255, 140, 30), 'teleporter: orange square at its cells, line to its target'),
                                     ((250, 250, 250), 'white frame: the droid at StartPositions $9484'))):
        x = 14 + (i % 2) * 520
        y = yl + (i // 2) * 22
        d.rectangle([x, y, x + 18, y + 14], fill=col)
        d.text((x + 24, y - 1), lab_, fill=TEXT, font=small)
    img.save(args.out)
    print(args.out, img.size)


def record_bytes(mem, room):
    base = 0xDB53
    off = mem[base + 2 * room] | mem[base + 2 * room + 1] << 8
    a = base + off
    fields = []
    p = a
    for name in ('item 1', 'item 2', 'teleporter'):
        if mem[p] == 0:
            fields.append((p, 1, name + ': none'))
            p += 1
        else:
            fields.append((p, 2, name))
            p += 2
    fields.append((p, 1, 'enemy mask'))
    p += 1
    for name in ('object 1', 'object 2'):
        if mem[p] == 0:
            fields.append((p, 1, name + ': none'))
            p += 1
        else:
            fields.append((p, 10, name))
            p += 10
    return a, fields


OBJ_FIELDS = ['kind', 'state', 'x', 'y', 'graphic', '', 'frame', 'frames', 'mark', 'attr']


def cmd_record(args):
    sys.path.insert(0, HERE)
    import szx
    img0 = None
    if args.image:
        raw = open(args.image, 'rb').read()
        img0 = bytearray(0x10000)
        img0[0x60C0:0x60C0 + len(raw)] = raw if len(raw) < 0x10000 else raw[0x60C0:]
    states = [(lab, szx.read(p)[0]) for lab, p in (x.split('=', 1) for x in args.state)]
    rows = [('the image', img0)] + states if img0 else states
    bw, bh = 46, 54
    width = WIDTH
    a, fields = record_bytes(rows[0][1], args.room)
    nbytes = sum(n for _, n, _ in fields)
    per_line = 20
    lines = (nbytes + per_line - 1) // per_line
    block_h = lines * (bh + 34) + 34
    img = Image.new('RGB', (width, 70 + len(rows) * block_h + 40), BG)
    d = ImageDraw.Draw(img)
    title(d, f'The alien record of room {args.room} at ${a:04X}, byte by byte: the image and the game')
    d.text((14, 36), 'the record is read field by field: a field that is 0 takes one byte; a changed byte is outlined '
                     'in white', fill=DIM, font=K.font(12))
    colours = {'item': (200, 140, 240), 'tele': (70, 220, 200), 'enem': (235, 110, 90), 'obje': (110, 200, 240)}
    fnt, small = K.font(14), K.font(10)
    for ri, (lab, mem) in enumerate(rows):
        y0 = 70 + ri * block_h
        d.text((14, y0), lab, fill=TEXT, font=K.font(14))
        i = 0
        for p, n, name in fields:
            col = colours[name[:4]]
            for j in range(n):
                x = 14 + (i % per_line) * (bw + 4)
                y = y0 + 24 + (i // per_line) * (bh + 34)
                b = mem[p + j]
                changed = ri > 0 and b != rows[0][1][p + j]
                d.rectangle([x, y, x + bw, y + bh], fill=tuple(c // 3 for c in col),
                            outline=(255, 255, 255) if changed else col, width=3 if changed else 1)
                d.text((x + 8, y + 4), f'{b:02X}', fill=TEXT, font=fnt)
                sub = name if j == 0 else ''
                if name.startswith('object') and n == 10:
                    sub = OBJ_FIELDS[j]
                elif name.startswith('item') or name.startswith('tele'):
                    sub = (name.split(':')[0] if j == 0 else ('kind' if name.startswith('item') else 'room'))
                    if j == 0 and n == 2:
                        sub = 'pos'
                sub = {'teleporter': 'tele', 'enemy mask': 'mask', 'item 1': 'item 1', 'item 2': 'item 2'}.get(
                    sub.split(':')[0], sub.split(':')[0])
                d.text((x + 3, y + 26), sub[:7], fill=col, font=small)
                d.text((x + 3, y + 39), f'{(p + j) & 0xFFF:03X}', fill=DIM, font=small)
                i += 1
    img.save(args.out)
    print(args.out, img.size)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('block')
    b.add_argument('--samples', required=True)
    b.add_argument('--frame', type=int, required=True)
    b.add_argument('--recording', default='rzx-010000')
    b.add_argument('--out', required=True)
    c = sub.add_parser('cells')
    for a in ('--samples', '--cells', '--screens', '--out'):
        c.add_argument(a, required=True)
    c.add_argument('--frame', type=int, required=True)
    c.add_argument('--recording', default='rzx-010000')
    t = sub.add_parser('path')
    for a in ('--samples', '--screens', '--out', '--title', '--movers'):
        t.add_argument(a, required=True)
    t.add_argument('--frame', type=int, required=True)
    t.add_argument('--from', dest='start', type=int, required=True)
    t.add_argument('--to', type=int, required=True)
    s = sub.add_parser('spawns')
    s.add_argument('--log', required=True)
    s.add_argument('--out', required=True)
    w = sub.add_parser('world')
    w.add_argument('--out', required=True)
    r = sub.add_parser('record')
    r.add_argument('--room', type=int, required=True)
    r.add_argument('--image')
    r.add_argument('--state', action='append', default=[], help='LABEL=state.szx')
    r.add_argument('--out', required=True)
    args = p.parse_args()
    {'block': cmd_block, 'cells': cmd_cells, 'path': cmd_path, 'spawns': cmd_spawns, 'world': cmd_world,
     'record': cmd_record}[args.cmd](args)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 07's figures: the room record and its decode, the cell planes, the map arrays, every object placed on the map,
an actor page, the kinds, the game variables over play48, the generator and a collision test.

    python3 tools/fig_objects.py [--only NAME[,NAME]] [--out docs/img/objects]

Every room figure is drawn from src/res and the 48K ROM alone (tools/fig_rooms.py, tools/swroom.py: the port of
BuildRoomPlanes $9F34 and RedrawCell $8867). The play48 figures read samples taken with TTD memory_at from
work/stage2/rec/play48 (work/docs/zsC/sample.py; a sample of frame N is the state at the start of frame N):

    play48-hiro.jsonl   frames 519-3768: $5D00 (66 bytes), $6642 (24 bytes), $6BDD
    play48-kill.jsonl   frames 2212-2220: the pages $5D-$61, $5C00 (16 bytes), $5D82 (128 bytes)

Names: record, decode, planes, map, placed, page, kinds, vars, random, collision.
"""
import argparse
import collections
import json
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import fig_rooms as FR  # noqa: E402
import res_formats as RF  # noqa: E402
import swroom as SW  # noqa: E402

W = 1050
SAMPLES = os.path.join(CASE, 'work', 'docs', 'zsC')
BG, FG, DIM, GRID = (255, 255, 255), (20, 20, 20), (110, 110, 110), (200, 200, 200)
FONT_DIR = os.path.join(os.path.dirname(__import__('matplotlib').__file__), 'mpl-data', 'fonts', 'ttf')


def font(size, bold=False, mono=False):
    name = 'DejaVuSansMono' if mono else 'DejaVuSans'
    return ImageFont.truetype(os.path.join(FONT_DIR, name + ('-Bold' if bold else '') + '.ttf'), size)


F14B, F13, F12, F12M, F11M, F14 = font(16, True), font(13), font(13), font(13, mono=True), font(12, mono=True), font(14)


def text_w(d, s, f):
    return d.textbbox((0, 0), s, font=f)[2]


def title(d, s, y=8):
    d.text((12, y), s, font=F14B, fill=FG)
    return y + 28


# ---- the rooms ---------------------------------------------------------------------------------------------------
ROOM = 8
SECTIONS = [  # (name, colour)
    ('header', (250, 210, 120)), ('placements', (160, 200, 250)), ('commands', (170, 230, 170)),
    ('zones', (240, 170, 200)), ('counts', (250, 250, 140)), ('enemy records', (250, 150, 120))]


class StepBuilder(SW.Builder):
    """The builder, keeping a copy of the six planes before each map command (the trace list's append)."""

    def __init__(self, mem, rom):
        super().__init__(mem, rom)
        outer = self

        class Trace(list):
            def append(self, item):
                outer.snaps.append((item, bytes(outer.m[0x6700:0x6D00])))
                super().append(item)
        self.snaps = []
        self.trace = Trace()


def room8():
    mem = FR.memory()
    rom = FR.rom48()
    grid = RF.map_grid(RF.load('rooms/map.bin'))
    b = StepBuilder(mem, rom)
    b.build(ROOM, FR.room_above(grid, ROOM))
    return mem, b


def room_picture(mem, planes, zones=0xFC, scale=1, force=False):
    m = bytearray(mem)
    m[0x6700:0x6D00] = planes
    if force:                                       # before the zones are built every cell is shown
        for cell in range(220):
            m[0x6700 + cell] |= 0x80
    pic, attrs = SW.render(m, revealed=zones)
    bm, at = SW.to_screen(pic, attrs)
    img = Image.new('RGB', (240, 176))
    px = img.load()
    for y in range(176):
        for x in range(240):
            px[x, y] = SW.SPECTRUM[FR.colour(bm, at, x + 8, y + 8)]
    return img.resize((240 * scale, 176 * scale), Image.NEAREST) if scale != 1 else img


def record_sections(mem, b):
    """(address, length, section, label) of every field of room 8's record"""
    a = SW.room_address(mem, ROOM)
    out = [(a, 1, 0, 'groups|0 2 0')]
    p = a + 1
    for _ in range(2):
        out.append((p, 1, 1, 'n%d|style%d' % (mem[p] >> 4, mem[p] & 15)))
        out.append((p + 1, 1, 1, 'cell|@%d.%d' % divmod(mem[p + 1], 20)))
        p += 2
    names = {4: 'surface', 9: 'bar 9', 10: 'bar A', 11: 'piece', 3: 'strings', 13: 'walls', 15: 'end'}
    zone_names = {}
    cmds = [t for t in b.trace]
    for i, (at, code, hi) in enumerate(cmds):
        end = cmds[i + 1][0] if i + 1 < len(cmds) else at + 1
        out.append((at, 1, 2, '%s|x%d' % (names[code], (hi & 1) + 1 if code == 13 else hi)))
        for q in range(at + 1, end):
            out.append((q, 1, 2, 'operand'))
    p = cmds[-1][0] + 1
    while p < b.objects_end - 3:
        out.append((p, 1, 3, 'zone|byte'))
        p += 1
    out.append((p, 1, 4, '%d enemy|%d items' % (mem[p] >> 4, mem[p] & 15)))
    out.append((p + 1, 1, 5, 'kind|$%02X' % mem[p + 1]))
    out.append((p + 2, 1, 5, 'cell|@%d.%d' % divmod(mem[p + 2], 20)))
    return a, out


def fig_record(out):
    mem, b = room8()
    a, fields = record_sections(mem, b)
    per = 16
    bw, bh = 62, 34
    rows = (len(fields) + per - 1) // per
    h = 60 + rows * (bh + 46) + 120
    img = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(img)
    y0 = title(d, 'Room 8 at $%04X: 46 bytes build the whole room (header, placements, commands, zones, enemies)' % a)
    x0 = (W - per * bw) // 2
    for i, (ad, _n, sec, label) in enumerate(fields):
        r, c = divmod(i, per)
        x, y = x0 + c * bw, y0 + 8 + r * (bh + 46)
        d.rectangle([x, y, x + bw - 2, y + bh], fill=SECTIONS[sec][1], outline=FG)
        s = '%02X' % mem[ad]
        d.text((x + (bw - text_w(d, s, F12M)) // 2, y + 9), s, font=F12M, fill=FG)
        d.text((x + 2, y - 15), '%04X' % ad, font=font(10, mono=True), fill=DIM)
        lab = label if label != 'operand' else ''
        for k, part in enumerate(lab.split('|')):
            d.text((x + 2, y + bh + 3 + 13 * k), part, font=font(11), fill=FG)
    ly = y0 + 8 + rows * (bh + 46) + 10
    x = 12
    for name, col in SECTIONS:
        d.rectangle([x, ly, x + 18, ly + 16], fill=col, outline=FG)
        d.text((x + 24, ly), name, font=F12, fill=FG)
        x += 40 + text_w(d, name, F12)
    d.text((12, ly + 28), 'How to read: one box a byte, its address above, its meaning below; unlabelled green boxes are '
           'the operands', font=F12, fill=FG)
    d.text((12, ly + 46), 'of the command before them. The point: a room is a program for the builder, not a picture; '
           'the cells are computed.', font=F12, fill=FG)
    d.text((12, ly + 64), 'Source: src/res/rooms/rooms.txt (room 8), decoded by tools/swroom.py.', font=F12, fill=DIM)
    img.save(out)


def fig_decode(out):
    mem, b = room8()
    names = {4: 'surface (code 4)', 9: 'bar 9 x2', 10: 'bar A x3', 11: 'pieces x3 (code $B)', 3: 'strings x4 (code 3)',
             13: 'walls (code $D)', 15: 'end (code $F, RoomPatch)'}
    panels = [('1. header + 2 placements', b.snaps[0][1])]
    for i, ((_at, code, _hi), _s) in enumerate(b.snaps):
        nxt = b.snaps[i + 1][1] if i + 1 < len(b.snaps) else None
        if nxt is not None:
            panels.append(('%d. + %s' % (len(panels) + 1, names[code]), nxt))
    panels.append(('%d. + end (RoomPatch), zones' % (len(panels) + 1), bytes(b.m[0x6700:0x6D00])))
    cols, sc = 3, 1.35
    pw, ph = int(240 * sc), int(176 * sc)
    rows = (len(panels) + cols - 1) // cols
    h = 50 + rows * (ph + 30) + 70
    img = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(img)
    y0 = title(d, 'Room 8 built command by command: each panel adds one command of the record')
    gap = (W - cols * pw) // (cols + 1)
    for i, (label, planes) in enumerate(panels):
        r, c = divmod(i, cols)
        x, y = gap + c * (pw + gap), y0 + r * (ph + 30)
        d.text((x, y), label, font=F13, fill=FG)
        pic = room_picture(mem, planes, force=True).resize((pw, ph), Image.NEAREST)
        img.paste(pic, (x, y + 18))
    ly = y0 + rows * (ph + 30) + 6
    d.text((12, ly), 'How to read: left to right, top to bottom; each panel is the six planes drawn as RedrawCell draws '
           'them, every zone shown.', font=F12, fill=FG)
    d.text((12, ly + 18), 'The point: the walls come from two placements, the sky and the ground from one surface '
           'command, the last commands only decorate.', font=F12, fill=FG)
    d.text((12, ly + 36), 'Command: python3 tools/fig_objects.py --only decode (src/res and the 48K ROM, no recording).',
           font=F12, fill=DIM)
    img.save(out)


PLANE_NAMES = {0x67: '$67 zones (bits 7-2), tile here (bit 0), item (bit 1)', 0x68: '$68 back tiles and walls',
               0x69: '$69 back tile 2', 0x6A: '$6A front tile 1', 0x6B: '$6B front tile 2',
               0x6C: '$6C colour (high nibble) and shade (low)'}


def plane_colour(page, v):
    if v == 0:
        return (245, 245, 245)
    if page == 0x67:
        return {0x80: (190, 220, 255), 0x40: (255, 220, 170)}.get(v & 0xC0, (220, 200, 255)) if v & 0xFC else (
            (150, 150, 150) if v & 1 else (250, 230, 120))
    hue = (v * 47) % 255
    return (150 + hue % 100, 150 + (hue * 3) % 100, 150 + (hue * 7) % 100)


def fig_planes(out, planes=None, caption=None):
    mem, b = room8()
    data = planes or bytes(b.m[0x6700:0x6D00])
    cw, chh = 24, 18
    gw = 20 * cw
    img = Image.new('RGB', (W, 50 + 3 * (11 * chh + 40) + 70), BG)
    d = ImageDraw.Draw(img)
    y0 = title(d, 'Room 8 in the six cell planes $6700-$6CFF: one byte a cell, cell = 20 x row + column')
    for k, page in enumerate(range(0x67, 0x6D)):
        r, c = divmod(k, 2)
        x, y = 30 + c * (gw + 50), y0 + r * (11 * chh + 40)
        d.text((x, y), PLANE_NAMES[page], font=F13, fill=FG)
        for cell in range(220):
            rr, cc = divmod(cell, 20)
            v = data[(page - 0x67) * 256 + cell]
            bx, by = x + cc * cw, y + 18 + rr * chh
            d.rectangle([bx, by, bx + cw - 1, by + chh - 1], fill=plane_colour(page, v), outline=GRID)
            if v:
                d.text((bx + 3, by + 2), '%02X' % v, font=font(11, mono=True), fill=FG)
    ly = y0 + 3 * (11 * chh + 40) - 6
    d.text((12, ly), 'How to read: a grid is one plane, 20 columns by 11 rows as on the screen; empty cells are 0. '
           'In $67 blue is zone 0, orange zone 1.', font=F12, fill=FG)
    d.text((12, ly + 18), caption or 'The point: everything the renderer and the collision tests need sits in these '
           '1320 bytes; the record is never read again.', font=F12, fill=FG)
    d.text((12, ly + 36), 'Source: tools/swroom.py build of room 8; play48 frame 2391 holds the same bytes '
           '(work/docs/zsC/play48-room8.jsonl).', font=F12, fill=DIM)
    img.save(out)


# ---- the map and the objects -------------------------------------------------------------------------------------
FRAGMENT_ROOMS = [15, 26, 29, 43, 56, 62, 63, 70, 71, 89, 93, 97, 101, 107, 120, 124]
GATE_ROOMS = {123: 'Havok', 93: 'giant', 58: 'giant', 8: 'gate', 39: 'giant', 136: '-'}
BOSS_ROOMS = {122: '$25 Havok', 39: '$26', 58: '$27', 112: '$28', 93: '$29'}


def objects_by_room():
    room = None
    pick, enem = collections.defaultdict(list), collections.defaultdict(list)
    for line in open(os.path.join(CASE, 'src', 'res', 'rooms', 'rooms.txt')):
        m = re.match(r'room (\d+)', line)
        if m:
            room = int(m.group(1))
            continue
        m = re.match(r'\s+pickup t(\d+) n(\d+) @(\d+)\.(\d+)', line)
        if m:
            pick[room].append(tuple(map(int, m.groups())))
        m = re.match(r'\s+enemy \$([0-9A-F]+) @(\d+)\.(\d+)', line)
        if m:
            enem[room].append((int(m.group(1), 16), int(m.group(2)), int(m.group(3))))
    return pick, enem


KIND_GROUPS = [  # (name, test, colour)
    ('pickups $01-$22 (shown)', lambda k: 1 <= k <= 0x22, (60, 170, 60)),
    ('fragment $18', lambda k: k == 0x18, (230, 40, 40)),
    ('timed pickups $81-$9F', lambda k: k >= 0x80, (140, 220, 140)),
    ('bosses $25-$29, gate $2A', lambda k: 0x25 <= k <= 0x2A, (120, 0, 160)),
    ('patrol $2B', lambda k: k == 0x2B, (240, 150, 0)),
    ('chasers $2C, $37-$3D', lambda k: k == 0x2C or 0x37 <= k <= 0x3D, (30, 110, 220)),
    ('traps $2E-$31, $34', lambda k: k in (0x2E, 0x2F, 0x30, 0x31, 0x34), (200, 60, 160)),
    ('fliers $32, $33, $35', lambda k: k in (0x32, 0x33, 0x35), (0, 170, 190)),
    ('stalactite $36', lambda k: k == 0x36, (120, 80, 40)),
    ('decor $3E, trigger $3F', lambda k: k in (0x3E, 0x3F), (130, 130, 130)),
]


def group_of(k):
    for i, (_n, t, _c) in enumerate(KIND_GROUPS):
        if i == 0 and k == 0x18:
            continue
        if t(k):
            return i
    return None


def fig_map(out):
    grid = RF.map_grid(RF.load('rooms/map.bin'))
    data = RF.load('rooms/map.bin')
    cw, ch = 31, 30
    x0, y0 = 150, 70
    img = Image.new('RGB', (W, y0 + 20 * ch + 110), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The map: 20 rows, the rooms numbered row by row, found by MapColumns, MapRowCounts and MapRowStarts')
    d.text((10, y0 - 22), 'row count start', font=F12, fill=FG)
    counts = data[0x7F:0x7F + 20]
    starts = data[0x93:0x93 + 20]
    for c in range(30):
        d.text((x0 + c * cw + 8, y0 - 20), '%d' % c, font=font(10), fill=DIM)
    for r in range(20):
        d.text((14, y0 + r * ch + 7), '%2d  %5d  %5d' % (r, counts[r], starts[r]), font=F12M, fill=FG)
    for room, (r, c) in grid.items():
        x, y = x0 + c * cw, y0 + r * ch
        col = (235, 235, 235)
        if room in FRAGMENT_ROOMS:
            col = (255, 170, 170)
        if room in BOSS_ROOMS:
            col = (200, 160, 240)
        if room == 8:
            col = (255, 220, 120)
        d.rectangle([x, y, x + cw - 2, y + ch - 2], fill=col, outline=DIM)
        s = '%d' % room
        d.text((x + (cw - text_w(d, s, F12)) // 2, y + 7), s, font=F12, fill=FG)
    ly = y0 + 20 * ch + 8
    x = 12
    for name, col in (('a Fireblade fragment', (255, 170, 170)), ('a boss (122/123 Havok, 39, 58, 93, 112 giants)',
                                                                  (200, 160, 240)), ('room 8 (doc 07 example)',
                                                                                     (255, 220, 120))):
        d.rectangle([x, ly, x + 18, ly + 16], fill=col, outline=DIM)
        d.text((x + 24, ly), name, font=F12, fill=FG)
        x += 50 + text_w(d, name, F12)
    d.text((12, ly + 26), 'How to read: MapColumns ($7048) lists each room\'s column; row r holds MapRowCounts[r] '
           'rooms from index MapRowStarts[r]; room = index + 1.', font=F12, fill=FG)
    d.text((12, ly + 44), 'The point: the map is a list of columns, not a grid; moving up or down is a search of the '
           'next row for the same column (CPIR).', font=F12, fill=FG)
    d.text((12, ly + 62), 'Source: src/res/rooms/map.txt; command: python3 tools/fig_objects.py --only map.',
           font=F12, fill=DIM)
    img.save(out)


def fig_placed(out):
    grid = RF.map_grid(RF.load('rooms/map.bin'))
    pick, enem = objects_by_room()
    cw, ch = 34, 44
    x0, y0 = 8, 50
    img = Image.new('RGB', (W, y0 + 20 * ch + 150), BG)
    d = ImageDraw.Draw(img)
    title(d, 'Every object on the map: %d enemy records (actors) and %d hidden-item records (in blocks)'
          % (sum(len(v) for v in enem.values()), sum(len(v) for v in pick.values())))
    for room, (r, c) in grid.items():
        x, y = x0 + c * cw, y0 + r * ch
        d.rectangle([x, y, x + cw - 2, y + ch - 2], fill=(248, 248, 248), outline=GRID)
        d.text((x + 2, y + 1), '%d' % room, font=font(10), fill=DIM)
        dots = [group_of(k) for k, _r, _c in enem[room]]
        for i, g in enumerate(dots):
            if g is None:
                continue
            px, py = x + 3 + (i % 5) * 6, y + 15 + (i // 5) * 6
            d.rectangle([px, py, px + 4, py + 4], fill=KIND_GROUPS[g][2])
        hidden = [n for _t, n, _r, _c in pick[room] if n]
        if hidden:
            d.text((x + 2, y + ch - 15), '+%d' % len(hidden), font=font(10, True), fill=(60, 120, 60))
    ly = y0 + 20 * ch + 6
    x, yy = 12, ly
    counts = collections.Counter(group_of(k) for v in enem.values() for k, _r, _c in v)
    for i, (name, _t, col) in enumerate(KIND_GROUPS):
        s = '%s: %d' % (name, counts[i])
        if x + 40 + text_w(d, s, F12) > W:
            x, yy = 12, yy + 20
        d.rectangle([x, yy + 3, x + 10, yy + 13], fill=col)
        d.text((x + 16, yy), s, font=F12, fill=FG)
        x += 34 + text_w(d, s, F12)
    yy += 26
    d.text((12, yy), 'How to read: a box is a room at its map place; a square is one enemy record, coloured by its '
           'behaviour; "+n" counts hidden items with content.', font=F12, fill=FG)
    d.text((12, yy + 18), 'The point: the giants and Havok each own one room; the fragments are records like enemies; '
           'chasers are the common foe.', font=F12, fill=FG)
    d.text((12, yy + 36), 'Source: src/res/rooms/rooms.txt; command: python3 tools/fig_objects.py --only placed.',
           font=F12, fill=DIM)
    img.save(out)


# ---- the actors ----------------------------------------------------------------------------------------------------
FIELDS = {0x00: 'Y', 0x01: 'X', 0x02: 'flags', 0x03: 'handler', 0x04: 'handler', 0x05: 'walk', 0x06: 'page',
          0x07: 'turn', 0x08: 'fall', 0x09: 'hurt', 0x0A: 'still', 0x0B: 'score', 0x0C: 'delay', 0x0D: 'rnd mask',
          0x0E: 'alert', 0x0F: 'death', 0x10: 'behave', 0x11: 'zone', 0x12: 'dir', 0x13: 'hits', 0x14: 'size',
          0x15: 'sizes', 0x16: 'sizes', 0x17: 'sizes', 0x18: 'sizes', 0x19: 'sizes', 0x1A: 'reload', 0x1B: 'facing',
          0x1C: 'kind', 0x1D: 'due', 0x1E: 'timer', 0x1F: 'timer', 0x20: 'draw', 0x21: 'last dX', 0x22: 'last dY',
          0x23: 'frame', 0x24: 'run', 0x25: 'steps', 0x26: 'falls', 0x27: 'scratch', 0x28: 'hold', 0x29: 'slot',
          0x2A: 'left', 0x2B: 'right', 0x2C: 'top', 0x2D: 'bottom', 0x2E: 'box w', 0x2F: 'box h', 0x30: 'jump',
          0x31: 'fall/hurt', 0x32: 'pose', 0x33: 'turn', 0x34: 'action', 0x35: 'hard land', 0x36: 'hang',
          0x37: 'death', 0x38: 'rise', 0x39: 'bonus', 0x3A: 'script', 0x3B: 'script', 0x3C: 'spawn sz',
          0x3D: 'X offs', 0x3E: 'path', 0x3F: 'path', 0x40: 'path', 0x41: 'unused'}
FIELD_GROUP = [(0x00, 0x02, (250, 210, 120)), (0x03, 0x0F, (160, 200, 250)), (0x10, 0x1C, (170, 230, 170)),
               (0x1D, 0x29, (240, 240, 150)), (0x2A, 0x2F, (240, 170, 200)), (0x30, 0x38, (250, 150, 120)),
               (0x39, 0x41, (210, 210, 210))]


def samples(name):
    return {json.loads(l)['frame']: json.loads(l) for l in open(os.path.join(SAMPLES, name))}


def fig_page(out, frame=1104):
    rows = samples('play48-hiro.jsonl')
    page = bytes.fromhex(rows[frame]['5D00'])
    per, bw, bh = 11, 92, 30
    img = Image.new('RGB', (W, 50 + 6 * (bh + 30) + 110), BG)
    d = ImageDraw.Draw(img)
    y0 = title(d, 'Hiro\'s actor page $5D00 at play48 frame %d (mid-jump): 66 bytes, the same layout for every actor'
               % frame)
    x0 = (W - per * bw) // 2
    for i in range(0x42):
        r, c = divmod(i, per)
        x, y = x0 + c * bw, y0 + 4 + r * (bh + 30)
        col = next(cl for a, b, cl in FIELD_GROUP if a <= i <= b)
        d.rectangle([x, y, x + bw - 3, y + bh], fill=col, outline=FG)
        d.text((x + 4, y + 7), '+%02X' % i, font=font(11, mono=True), fill=DIM)
        d.text((x + 46, y + 6), '%02X' % page[i], font=F12M, fill=FG)
        d.text((x + 2, y + bh + 2), FIELDS[i], font=font(11), fill=FG)
    ly = y0 + 4 + 6 * (bh + 30) + 4
    x = 12
    for (a, b, col), name in zip(FIELD_GROUP, ['place', 'scripts', 'behaviour', 'timing', 'box (cells)',
                                                'sequence slots', 'scratch']):
        d.rectangle([x, ly, x + 18, ly + 16], fill=col, outline=FG)
        d.text((x + 24, ly), '%s +%02X-+%02X' % (name, a, b), font=F12, fill=FG)
        x += 40 + text_w(d, '%s +%02X-+%02X' % (name, a, b), F12)
    d.text((12, ly + 26), 'How to read: offset, value (hex), and the field\'s short name; +30 = $10 is the jump slot '
           'counting down, +3/+4 = $9333 is HiroControl.', font=F12, fill=FG)
    d.text((12, ly + 44), 'The point: an actor is a 66-byte record at a page start; the code addresses it with H = '
           'page and L = field, so a field read costs one LD L,n.', font=F12, fill=FG)
    d.text((12, ly + 62), 'Recording play48, memory_at frame %d (the state at its start); work/docs/zsC/'
           'play48-hiro.jsonl; command: python3 tools/fig_objects.py --only page.' % frame, font=F12, fill=DIM)
    img.save(out)


KINDS = [  # (first, last, handler, label, colour)
    (0x00, 0x00, None, 'none', (230, 230, 230)), (0x01, 0x22, 'StillControl $937E', 'pickups', (60, 170, 60)),
    (0x23, 0x23, None, 'item template', (200, 200, 200)), (0x24, 0x24, 'HiroControl $9333', 'Hiro', (250, 210, 0)),
    (0x25, 0x29, 'PathControl $93FB', 'Havok, giants', (120, 0, 160)), (0x2A, 0x2A, 'StillControl', 'gate', (90, 90, 90)),
    (0x2B, 0x2B, 'PatrolControl $93AF', 'patrol', (240, 150, 0)),
    (0x2C, 0x2C, 'ChaserControl $9348', 'chaser', (30, 110, 220)),
    (0x2D, 0x2D, 'PathControlShot $940A', 'boss shot', (160, 60, 220)),
    (0x2E, 0x31, 'TrapControl $93D6', 'traps', (200, 60, 160)), (0x32, 0x33, 'PathControl', 'fliers', (0, 170, 190)),
    (0x34, 0x34, 'TrapControl', 'trap', (200, 60, 160)), (0x35, 0x35, 'PathControl', 'flier', (0, 170, 190)),
    (0x36, 0x36, 'StalactiteControl $93A8', 'stalactite', (120, 80, 40)),
    (0x37, 0x3D, 'ChaserControl', 'chasers', (30, 110, 220)), (0x3E, 0x3E, 'DecorControl $9387', 'decor', (150, 150, 150)),
    (0x3F, 0x3F, 'TriggerControl $9390', 'trigger', (110, 110, 110)),
    (0x40, 0x46, 'WeaponControl $9514', 'weapons', (230, 60, 60)), (0x47, 0x47, 'PathControl', 'sparks', (255, 120, 120)),
    (0x48, 0x48, 'PathControl + ShieldFollow', 'energy ball', (255, 200, 200))]


def fig_kinds(out):
    per, bw, bh = 12, 84, 40
    img = Image.new('RGB', (W, 50 + 7 * (bh + 8) + 230), BG)
    d = ImageDraw.Draw(img)
    y0 = title(d, 'The 73 kinds $00-$48: one template each (KindTemplates $7200), eleven behaviour handlers')
    x0 = (W - per * bw) // 2
    for k in range(0x49):
        r, c = divmod(k, per)
        x, y = x0 + c * bw, y0 + r * (bh + 8)
        first, last, handler, label, col = next(e for e in KINDS if e[0] <= k <= e[1])
        d.rectangle([x, y, x + bw - 4, y + bh], fill=col, outline=FG)
        light = sum(col) > 420
        d.text((x + 4, y + 3), '$%02X' % k, font=F12M, fill=FG if light else (255, 255, 255))
        d.text((x + 4, y + 21), label[:12], font=font(11), fill=FG if light else (255, 255, 255))
    ly = y0 + 7 * (bh + 8) + 4
    seen, x, yy = set(), 12, ly
    for first, last, handler, label, col in KINDS:
        if not handler or handler.split()[0] in seen:
            continue
        seen.add(handler.split()[0])
        s = handler
        if x + 30 + text_w(d, s, F12) > W:
            x, yy = 12, yy + 20
        d.rectangle([x, yy + 3, x + 10, yy + 13], fill=col)
        d.text((x + 16, yy), s, font=F12, fill=FG)
        x += 34 + text_w(d, s, F12)
    yy += 30
    for i, s in enumerate([
            'How to read: a box is a kind number; the colour is the state handler its template puts in +3/+4.',
            'Bit 7 on a kind in a room record means a timed pickup: a random hold, then 255 frames of life.',
            'The point: behaviour lives in the template, not the kind; the same handler drives many kinds',
            'with different paths, scripts, speeds and hit points (src/res/tables/actor-templates.csv).',
            'Command: python3 tools/fig_objects.py --only kinds.']):
        d.text((12, yy + 18 * i), s, font=F12, fill=FG if i < 4 else DIM)
    img.save(out)


def fig_vars(out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    rows = samples('play48-hiro.jsonl')
    fr = sorted(rows)
    g = {f: bytes.fromhex(rows[f]['6642']) for f in fr}
    room = [int(rows[f]['6BDD'], 16) for f in fr]
    energy = [g[f][0] for f in fr]
    charge = [g[f][3] for f in fr]
    lives = [g[f][0x0B] for f in fr]
    inv = [g[f][0x0F] for f in fr]
    score = [int(g[f][0x11:0x15].hex()) for f in fr]
    fig, ax = plt.subplots(5, 1, figsize=(10.5, 8.4), dpi=100, sharex=True)
    plt.rcParams.update({'font.size': 11})
    series = [(room, 'Room $6BDD', 'tab:blue'), (energy, 'Vitality $6642', 'tab:red'), (charge, 'Charge $6645', 'tab:orange'),
              (lives, 'Lives $664D', 'tab:green'), (score, 'Score $6653 (BCD)', 'tab:purple')]
    for a, (v, name, col) in zip(ax, series):
        a.step(fr, v, where='post', color=col)
        a.set_ylabel(name, fontsize=11)
        a.grid(alpha=0.3)
    for f0, f1 in [(f, f2) for f, f2 in zip(fr, fr[1:]) if not inv[fr.index(f)] and inv[fr.index(f2)]]:
        for a in ax:
            a.axvline(f1, color='k', ls=':', lw=1)
    ax[1].text(1314, 33, ' a life lost', fontsize=10)
    ax[4].set_xlabel('play48 frame (memory_at: the state at the start of the frame)', fontsize=11)
    fig.suptitle('The game variables over play48: rooms 4-9, 28 touches, one 32-step fall, 4 lives lost, 160 points', fontsize=13,
                 fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


def random_seq(seed, n):
    """Random $A632 called n times from the 16-bit seed: (the new seed, A) each call"""
    out = []
    for _ in range(n):
        for _r in range(15):
            hl = seed
            de = ((hl & 0xFF) << 8) | (hl >> 8)
            hl = (hl + de) & 0xFFFF
            e = ((seed >> 8) + (hl & 0xFF)) & 0xFF
            dd = ((seed & 0xFF) + (hl >> 8)) & 0xFF
            de = dd << 8 | e
            hl = (hl * 4 + de) & 0xFFFF
            hl = (hl * 8 + de) & 0xFFFF
            seed = hl
        out.append((seed, seed & 0xFF))
    return out


def fig_random(out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    first = [random_seq(t, 1)[0][1] for t in range(4096)]
    fig, ax = plt.subplots(1, 2, figsize=(10.5, 3.9), dpi=100)
    ax[0].plot(range(4096), first, ',', color='tab:blue')
    ax[0].set_xlabel('the frame counter $8473 when Random is called', fontsize=11)
    ax[0].set_ylabel('A returned (low byte)', fontsize=11)
    ax[0].set_title('one call: A against the counter', fontsize=11)
    seq = random_seq(0x0105, 4000)
    c7 = collections.Counter(a & 7 for _s, a in seq)
    cnt = collections.Counter(a & 0x0D for _s, a in seq)
    ax[1].bar([str(k) for k in range(8)], [c7[k] for k in range(8)], color='tab:orange', label='A AND 7 (speeds)')
    ax[1].bar([str(k) for k in sorted(cnt) if k > 7], [cnt[k] for k in sorted(cnt) if k > 7], color='tab:green',
              label='A AND $0D (holds) above 7')
    ax[1].set_title('4000 chained calls from $0105: the values used', fontsize=11)
    ax[1].legend(fontsize=10)
    fig.suptitle('Random $A632: 15 rounds over the frame counter, which it also overwrites', fontsize=13,
                 fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


def fig_collision(out):
    rows = samples('play48-kill.jsonl')
    f = 2219
    hiro = bytes.fromhex(rows[f]['5D00'])
    foe = bytes.fromhex(rows[f]['5E00'])
    cw, ch = 22, 26
    c0, c1, r0, r1 = 0x32, 0x42, 4, 11
    x0, y0 = 60, 70
    img = Image.new('RGB', (W, y0 + (r1 - r0 + 1) * ch + 160), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The strike at play48 frame 2219: the sweep\'s one-row box meets the patroller\'s box and kills it')
    for c in range(c0, c1 + 1):
        d.text((x0 + (c - c0) * cw + 2, y0 - 18), '%02X' % c, font=font(10, mono=True), fill=DIM)
    for r in range(r0, r1 + 1):
        d.text((x0 - 30, y0 + (r - r0) * ch + 6), '%d' % r, font=F12, fill=DIM)
        for c in range(c0, c1 + 1):
            x, y = x0 + (c - c0) * cw, y0 + (r - r0) * ch
            d.rectangle([x, y, x + cw, y + ch], outline=GRID)

    def box(b, col, width, label, dy=0):
        x = x0 + (b[0] - c0) * cw
        y = y0 + (b[2] - r0) * ch
        d.rectangle([x + dy, y + dy, x0 + (b[1] - c0 + 1) * cw - dy, y0 + (b[3] - r0 + 1) * ch - dy], outline=col,
                    width=width)
        if label:
            d.text((x0 + (b[1] - c0 + 1) * cw + 6, y - 20), label, font=F12, fill=col)
    hb = (hiro[0x2A], hiro[0x2B], hiro[0x2C], hiro[0x2D])
    fb = (foe[0x2A], foe[0x2B], foe[0x2C], foe[0x2D])
    sb = (hb[1] - 1, hb[1], hb[2] + 2, hb[2] + 2)
    box(hb, (200, 160, 0), 3, 'Hiro +2A-+2D = %02X %02X %d %d' % hb)
    box(fb, (30, 110, 220), 3, '', dy=0)
    d.text((x0 + (fb[0] - c0) * cw, y0 + (fb[3] - r0 + 1) * ch + 30), 'patroller (kind $2B, page $5E) +2A-+2D = '
           '%02X %02X %d %d' % fb, font=F12, fill=(30, 110, 220))
    x = x0 + (sb[0] - c0) * cw
    y = y0 + (sb[2] - r0) * ch
    d.rectangle([x, y, x0 + (sb[1] - c0 + 1) * cw, y + ch], fill=(255, 120, 120), outline=(200, 0, 0), width=2)
    d.text((x0 + (c1 - c0 + 1) * cw + 10, y0 + 0 * ch), 'strike box: right column and the one before,',
           font=F12, fill=(200, 0, 0))
    d.text((x0 + (c1 - c0 + 1) * cw + 10, y0 + 0 * ch + 18), 'row top + 2 (the sweep, strike 3)', font=F12,
           fill=(200, 0, 0))
    ly = y0 + (r1 - r0 + 1) * ch + 14
    for i, s in enumerate([
            'How to read: columns are 3-pixel units (X / 2), rows are 8-pixel lines (Y / 8), as the box bytes +2A-+2D '
            'hold them.',
            'Hiro X $6C Y $30 faces right; the patroller X $78 Y $40 has 2 hit points; the sweep does 3: 2 - 3 < 0, '
            'KillActor, 50 points.',
            'The point: a strike is a box test with a narrowed box; nothing about the sprites\' pixels is used.',
            'Recording play48 frames 2212-2220 (memory_at, work/docs/zsC/play48-kill.jsonl); the hit points go 02 -> FF '
            'between the samples of 2219 and 2220.',
            'Command: python3 tools/fig_objects.py --only collision.']):
        d.text((12, ly + 18 * i), s, font=F12, fill=FG if i < 3 else DIM)
    img.save(out)


FIGS = {'record': fig_record, 'decode': fig_decode, 'planes': fig_planes, 'map': fig_map, 'placed': fig_placed,
        'page': fig_page, 'kinds': fig_kinds, 'vars': fig_vars, 'random': fig_random, 'collision': fig_collision}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'objects'))
    p.add_argument('--only')
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name in (a.only.split(',') if a.only else FIGS):
        path = os.path.join(a.out, name + '.png')
        FIGS[name](path)
        print(os.path.relpath(path, CASE), Image.open(path).size)


if __name__ == '__main__':
    main()

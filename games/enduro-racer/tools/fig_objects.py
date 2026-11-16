#!/usr/bin/env python3
"""Enduro Racer's objects for doc 7: the data sheets, every object type's sprites by distance, the riders' sprites,
and a stretch of the track decoded byte by byte. Everything is read from the case's build (build/game.bin at $5B00)
and src/res; nothing runs.

    python3 tools/fig_objects.py fig-formats OUT.png   the segment byte, the track's commands, the pattern frame,
                                                       the object list entry, the rider record, as data sheets
    python3 tools/fig_objects.py fig-types OUT.png     the eight object types: every size of each, nearest first,
                                                       with its row threshold and collision box
    python3 tools/fig_objects.py fig-riders OUT.png    RiderSprites: 7 distance bands x 5 poses
    python3 tools/fig_objects.py fig-stretch OUT.png   stage 1's first 1024 units: the bytes, their meaning and the
                                                       objects they place
    python3 tools/fig_objects.py fig-ring OUT.png C1.jsonl ST.jsonl
                                                       the riders' rows against the frame: c1's first minute
                                                       (riders 0-3) and stage 4 of stages (the trucks)
    python3 tools/fig_objects.py fig-fields OUT.png A.png B.png  two screenshots side by side with the segment fields
    python3 tools/fig_objects.py anim-stretch SCREEN.gif FROM STEP VARS.jsonl OUT.gif
                                                       the stretch decoded as c1 drives it: the screen (a
                                                       screen_anim GIF) beside the track bytes, TrackPtr and the
                                                       pattern frame, from a sample.py file of the same frames
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import res_formats as rf  # noqa: E402
import course  # noqa: E402

BASE = 0x5B00
IMAGE = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
COPY = 0x5E80 - 0xEB00            # a copy address minus this is the image's address


def peek(a, n=1):
    return IMAGE[a - BASE:a - BASE + n]


def word(a):
    b = peek(a, 2)
    return b[0] | b[1] << 8


TYPE_NAMES = {0: 'ramp', 1: 'stone', 2: 'fir', 3: 'palm', 4: 'shrub', 5: 'cactus', 6: 'rock spire', 7: 'tree'}
TYPE_ORDER_ADDR = 0x975B
COLLISIONS = 0xA1B9
RIDER_SPRITES = 0x917E


def object_lists():
    """{type: (farthest row, aligned row, [(threshold, y offset, rows, width, address)])}"""
    out = {}
    for t in range(8):
        a = word(TYPE_ORDER_ADDR + 2 * t)
        far, aligned = peek(a, 2)
        entries, e = [], a + 2
        while True:
            th, yo, rows, width = peek(e, 4)
            entries.append((th, yo, rows, width, word(e + 4)))
            e += 6
            if th >= far:
                break
        out[t] = (far, aligned, entries)
    return out


def sprite_image(addr, width, rows, scale, ink=(20, 20, 20), paper=(235, 235, 225)):
    img = Image.new('RGB', (width * 8 * scale, rows * scale), paper)
    px = img.load()
    for r in range(rows):
        for c in range(width):
            b = IMAGE[addr - BASE + r * width + c]
            for bit in range(8):
                if b & (0x80 >> bit):
                    for dy in range(scale):
                        for dx in range(scale):
                            px[(c * 8 + bit) * scale + dx, r * scale + dy] = ink
    return img


def box_sheet(rows, title, out, width=1050, note=None):
    """a byte-by-byte data sheet: rows of (label, [(bytes, top text, bottom text, colour)]); wraps a row when full"""
    ft, fl, fs = kitlib.font(18), kitlib.font(15), kitlib.font(13)
    left, bh, gap = 250, 50, 14
    layout, y = [], 56
    for label, fields in rows:
        x, line_y, placed = left, y, []
        for nbytes, top, bottom, colour in fields:
            w = max(44 * nbytes, int(max(fs.getlength(top), fs.getlength(bottom))) + 12)
            if x + w > width - 10:
                x, line_y = left, line_y + bh + 6
            placed.append((x, line_y, w, top, bottom, colour))
            x += w
        layout.append((label, y, placed))
        y = line_y + bh + gap
    h = y + (50 if note else 10)
    img = Image.new('RGB', (width, h), 'white')
    d = ImageDraw.Draw(img)
    d.text((12, 14), title, fill='black', font=ft)
    for label, ly, placed in layout:
        d.text((12, ly + 14), label, fill='black', font=fl)
        for x, yy, w, top, bottom, colour in placed:
            d.rectangle([x, yy, x + w - 3, yy + bh], fill=colour, outline='black')
            d.text((x + 5, yy + 6), top, fill='black', font=fs)
            d.text((x + 5, yy + 27), bottom, fill='#333333', font=fs)
    if note:
        for k, part in enumerate(note.split('\n')):
            d.text((12, h - 46 + 18 * k), part, fill='#333333', font=fs)
    img.save(out)


BLUE, ORANGE, GREEN, PINK, GREY, WHITE = '#c6dbef', '#fdd0a2', '#d9f0d3', '#fde0ef', '#e5e5e5', '#ffffff'


def cmd_fig_formats(out):
    rows = [
        ('Segment byte (StageList)', [(1, 'bits 7-6: %10', 'length code', GREY), (1, 'bit 5', 'stage end', PINK),
                                      (1, 'bit 4', 'curve dir', ORANGE), (1, 'bits 3-2', 'curve 0-3', ORANGE),
                                      (1, 'bits 1-0', 'hill 0-3', GREEN), (1, '$9C', '0.3.1', WHITE),
                                      (1, '$A0', 'stage 1 last', WHITE)]),
        ('Element: 2 bytes', [(1, 'hi nibble', 'type 0-7, 10', BLUE), (1, 'lo nibble n', 'gap: 2n units from the last', GREEN),
                              (1, 'x', 'signed, road centre 0', ORANGE), (2, '7A C8', 'type 7, 20 on, x -56',
                                                                         WHITE)]),
        ('Commands', [(5, '$E0 lo hi LEN', 'call a pattern, LEN units ($FFFF: to its ret)', PINK),
                      (1, '$D0', 'ret', PINK), (2, '$C0 d', 'jump by d', GREY),
                      (1, '$F0', 'gap mark', GREEN), (1, '$B0+n', 'VarObject = 2n', BLUE)]),
        ('TrackStack $5E37: 13 bytes', [(1, '+0', 'depth', GREY), (2, '+1 +2', 'return', PINK),
                                        (2, '+3 +4', 'length', PINK), (2, '+5 +6', 'distance done', PINK),
                                        (6, '+7 .. +12', 'second frame', WHITE)]),
        ('Object list (ObjectTypes)', [(1, 'far', 'farthest row', GREY), (1, 'aligned', 'rows < it: DrawSprite', GREY),
                                       (1, 'thresh', 'row limit', BLUE), (1, 'y off', 'lift', GREEN),
                                       (1, 'rows', 'height', GREEN), (1, 'width', 'bytes', GREEN),
                                       (2, 'address', 'the sprite', ORANGE)]),
        ('Rider (Riders $5C80): 15', [(1, '+0', 'flags', GREY), (1, '+1', '', WHITE), (1, '+2', 'x', ORANGE),
                                      (2, '+3 +4', 'distance', BLUE), (2, '+5 +6', 'speed', BLUE),
                                      (1, '+7', 'accel', GREEN), (1, '+8', 'top', GREEN), (1, '+9', 'pose', PINK),
                                      (1, '+A', 'hill pose', PINK), (2, '+B +C', 'jump height', ORANGE),
                                      (2, '+D +E', 'jump speed', ORANGE)]),
    ]
    box_sheet(rows, 'The track, the object lists and the rider record, byte by byte', out,
              note='Distances in track units (128 a segment); the low bytes of distance and speed are fractions.\n'
                   'Flags: bit 7 out of the race, bit 0 a truck.')


def cmd_fig_types(out):
    lists = object_lists()
    order = list(range(8))
    scale = 2
    font, small = kitlib.font(15), kitlib.font(12)
    blocks = []
    for t in order:
        far, aligned, entries = lists[t]
        hw, ht = peek(COLLISIONS + 2 * t, 2)
        pics = []
        for th, yo, rows, width, addr in entries:
            pics.append((sprite_image(addr, width, rows, scale), th, yo, rows, width, addr))
        blocks.append((t, far, aligned, hw, ht, pics))
    width = 1050
    y = 50
    placed = []
    for t, far, aligned, hw, ht, pics in blocks:
        lines, line, x = [], [], 190
        for p in pics:
            if x + p[0].width > width - 10 and line:
                lines.append(line)
                line, x = [], 190
            line.append((x, p))
            x += max(p[0].width, 44) + 12
        lines.append(line)
        for k, line in enumerate(lines):
            rowh = max(max(p[0].height for _, p in line) + 34, 84 if k == 0 else 0)
            placed.append((y, rowh, t, far, aligned, hw, ht, line, len(pics), k))
            y += rowh + 8
    img = Image.new('RGB', (width, y + 10), 'white')
    d = ImageDraw.Draw(img)
    d.text((12, 12), 'The eight object types: each size its list holds, nearest first (drawn 2 x)', fill='black',
           font=kitlib.font(18))
    for y0, rowh, t, far, aligned, hw, ht, line, n, k in placed:
        if k == 0:
            d.line([0, y0 - 5, width, y0 - 5], fill='#cccccc')
            d.text((12, y0 + 4), 'type %d: %s' % (t, TYPE_NAMES[t]), fill='black', font=font)
            d.text((12, y0 + 26), 'rows 0-%d, %d sizes' % (far - 1, n), fill='#333333', font=small)
            d.text((12, y0 + 44), 'byte-aligned at rows < %d' % aligned, fill='#333333', font=small)
            d.text((12, y0 + 62), 'hit box %d x %d' % (hw, ht), fill='#333333', font=small)
        for x, (pic, th, yo, rows, w, addr) in line:
            img.paste(pic, (x, y0 + rowh - 30 - pic.height))
            d.text((x, y0 + rowh - 27), '<%d' % th, fill='#1f4e9e', font=small)
            d.text((x, y0 + rowh - 13), '%04X' % addr, fill='#666666', font=kitlib.font(11))
    img.save(out)


def cmd_fig_riders(out):
    scale = 2
    font, small = kitlib.font(15), kitlib.font(12)
    poses = ['0 in the air', '1 bend, most', '2 bend', '3 straight', '4 truck']
    bands = []
    for b in range(7):
        a = RIDER_SPRITES + 21 * b
        th = peek(a)[0]
        cells = []
        for p in range(5):
            rows, width, lo, hi = peek(a + 1 + 4 * p, 4)
            addr = lo | hi << 8
            cells.append((rows & 0x7F, width & 0x7F, addr, rows >> 7, width >> 7))
        bands.append((th, cells))
    colw = [max(170, max(c[1] for _, cells in bands for c in [cells[p]]) * 8 * scale + 30) for p in range(5)]
    width = 1050
    x0 = 120
    y = 74
    rowhs = [max(c[0] for c in cells) * scale + 24 for _, cells in bands]
    img = Image.new('RGB', (width, y + sum(rowhs) + 20), 'white')
    d = ImageDraw.Draw(img)
    d.text((12, 12), 'RiderSprites $917E: pose = column, row = band (2 x; m never mirrored, a byte-aligned)',
           fill='black', font=kitlib.font(18))
    x = x0
    for p in range(5):
        d.text((x, 46), poses[p], fill='black', font=font)
        x += colw[p]
    for (th, cells), rh in zip(bands, rowhs):
        d.line([0, y - 4, width, y - 4], fill='#cccccc')
        d.text((12, y + 4), 'rows < %d' % th, fill='black', font=font)
        x = x0
        for p, (rows, w, addr, mirror, aligned) in enumerate(cells):
            pic = sprite_image(addr, w, rows, scale)
            img.paste(pic, (x, y))
            tag = '$%04X%s%s' % (addr, ' m' if mirror else '', ' a' if aligned else '')
            d.text((x, y + pic.height + 2), tag, fill='#555555', font=kitlib.font(10))
            x += colw[p]
        y += rh
    img.save(out)


def game_walk(limit=1024):
    """the track walked as AdvanceTrack and TrackStep walk it: [(position, element address, type, x, VarObject)].
    An element's low nibble x 2 is its distance from the previous element. A pattern's count takes that distance when
    the walk arrives at the element; the element that brings the count to the call's length is skipped (the walk
    returns to the caller from it), so a call places only the elements less than its length from where it began.
    game_walk.calls: {the call's address: the position it counts from (the last element before it)}"""
    mem = bytearray(0x10000)
    mem[0x5B00:0x5B00 + len(IMAGE)] = IMAGE
    mem[0x5E80:0x5E80 + 0x0630] = IMAGE[0xEB00 - BASE:0xEB00 - BASE + 0x0630]
    frames, var, pending = [], 0, []
    ptr, pos, out = 0x60D0, 0, []
    game_walk.calls = {}

    def step(hl):
        nonlocal var
        hl += 2
        while True:
            b = mem[hl]
            h = b & 0xF0
            if h == 0xF0:
                hl += 1
            elif h == 0xE0:
                pending.append(hl)
                frames.append([hl + 5, mem[hl + 3] | mem[hl + 4] << 8, 0])
                hl = mem[hl + 1] | mem[hl + 2] << 8
            elif h == 0xD0:
                hl = frames.pop()[0]
            elif h == 0xC0:
                d = mem[hl + 1] - (256 if mem[hl + 1] > 127 else 0)
                hl += 2 + d
            elif h == 0xB0:
                var = (b & 15) * 2
                hl += 1
            else:
                gap, back = (b & 15) * 2, None
                for k in range(len(frames) - 1, -1, -1):
                    frames[k][2] += gap
                    if frames[k][2] >= frames[k][1]:
                        back = k
                if back is not None:
                    hl = frames[back][0]
                    del frames[back:]
                    continue
                return hl

    while pos < limit:
        b = mem[ptr]
        x = mem[ptr + 1] - (256 if mem[ptr + 1] > 127 else 0)
        out.append((pos, ptr, b >> 4, x, var))
        ptr = step(ptr)
        for a in pending:
            game_walk.calls.setdefault(a, pos)
        del pending[:]
        pos += (mem[ptr] & 15) * 2
    return out


def stretch_events(limit=1024):
    data = rf.load('track/tables.bin')
    top = rf.track_walk(data)
    events = [(p, 'obj', t, x) for p, _a, t, x, _v in game_walk(limit)]
    return data, top, events


def cmd_fig_stretch(out):
    data, top, events = stretch_events(1024)
    width, height = 1050, 900
    img = Image.new('RGB', (width, height), 'white')
    d = ImageDraw.Draw(img)
    mono, small, big = kitlib.font(13), kitlib.font(12), kitlib.font(18)
    d.text((12, 12), 'Stage 1\'s first 1024 units: the track bytes at $60D0 and the objects they place',
           fill='black', font=big)
    # left: the bytes
    y = 52
    lines = []
    for o, w, dist in top:
        if dist >= 1024:
            break
        a = rf.COPY_ORG + o
        n = {'call': 5, 'jump': 2, 'obj': 2}.get(w[0], 1)
        raw = ' '.join('%02X' % x for x in data[o:o + n])
        lines.append(('$%04X' % a, raw, ' '.join(w), game_walk.calls.get(a, dist)))
    pats = {}
    for _a, _raw, text, _dist in lines:
        if text.startswith('call'):
            p = int(text.split()[1][1:], 16)
            pats.setdefault(p, [])
    for p in pats:
        cmds = course.commands(data, p)
        for a, w in cmds:
            n = {'call': 5, 'jump': 2, 'obj': 2}.get(w[0], 1)
            o = a - rf.COPY_ORG
            pats[p].append(('$%04X' % a, ' '.join('%02X' % x for x in data[o:o + n]), ' '.join(w)))
            if w[0] in ('jump', 'ret'):
                break
    d.text((12, y), 'Track $60D0 (the copy); @: where each call counts from', fill='black', font=small)
    y += 20
    for a, raw, text, dist in lines:
        d.text((12, y), a, fill='#666666', font=mono)
        d.text((70, y), raw, fill='#1f4e9e', font=mono)
        d.text((240, y), text, fill='black', font=mono)
        d.text((420, y), '@%d' % dist, fill='#b04000', font=mono)
        y += 18
    y += 10
    for p, cmds in sorted(pats.items()):
        d.text((12, y), 'pattern $%04X' % p, fill='black', font=small)
        y += 18
        for a, raw, text in cmds[:6]:
            d.text((12, y), a, fill='#666666', font=mono)
            d.text((70, y), raw, fill='#1f4e9e', font=mono)
            d.text((240, y), text, fill='black', font=mono)
            y += 18
        if len(cmds) > 6:
            d.text((70, y), '... %d more' % (len(cmds) - 6), fill='#666666', font=small)
            y += 18
        y += 6
    # right: the strip, distance up the page (the road ahead), x across
    x0, x1, top_y, bot_y = 520, 1030, 60, height - 30
    d.rectangle([x0, top_y, x1, bot_y], fill='#3d6b35')
    cx = (x0 + x1) // 2
    sx = (x1 - x0) / 300.0
    d.rectangle([cx - 64 * sx, top_y, cx + 64 * sx, bot_y], fill='#777777')
    sy = (bot_y - top_y) / 1024.0
    for s in range(9):
        yy = bot_y - s * 128 * sy
        d.line([x0, yy, x1, yy], fill='#9fbf8f')
        d.text((x0 + 2, yy - 14), '%d' % (s * 128), fill='white', font=small)
    for a, raw, text, dist in lines:
        if text.startswith('call'):
            yy = bot_y - dist * sy
            d.line([x0, yy, x1, yy], fill='#ffd040', width=2)
            d.text((x1 - 120, yy - 15), text.split()[1], fill='#ffd040', font=small)
    for dist, kind, typ, x in events:
        yy = bot_y - dist * sy
        px = cx + x * sx
        col = course.COLOURS.get(typ, (255, 0, 0))
        d.ellipse([px - 4, yy - 4, px + 4, yy + 4], fill=col, outline='black')
    d.text((x0, bot_y + 6), 'x -150 ... 150 across, distance up; yellow: where each call counts from', fill='black', font=small)
    lx, ly = 12, height - 70
    for i, (t, name) in enumerate(((7, 'tree (7)'), (2, 'fir (2)'), (0, 'ramp (0)'), (1, 'stone (1)'),
                                   (10, 'element 10: VarObject 4, a fir'))):
        xx = lx + 160 * (i % 3)
        yy = ly + 20 * (i // 3)
        d.ellipse([xx, yy + 3, xx + 9, yy + 12], fill=course.COLOURS.get(t, (255, 0, 0)), outline='black')
        d.text((xx + 14, yy), name, fill='black', font=small)
    img.save(out)


def anim_lines():
    """the stretch's track and pattern lines: [(address, raw, text)] with a blank (None) between blocks"""
    data = rf.load('track/tables.bin')
    game_walk(1100)
    out = [('', '', 'track $60D0 (@: where each call counts from)', 'head')]
    for o, w, dist in rf.track_walk(data):
        if dist >= 1024:
            break
        n = {'call': 5, 'jump': 2, 'obj': 2}.get(w[0], 1)
        a = rf.COPY_ORG + o
        out.append((a, ' '.join('%02X' % x for x in data[o:o + n]), ' '.join(w), game_walk.calls.get(a, dist)))
    for p in (0x60BA, 0x5F5F):
        out.append(('', '', 'pattern $%04X' % p, 'head'))
        for a, w in course.commands(data, p):
            n = {'call': 5, 'jump': 2, 'obj': 2}.get(w[0], 1)
            o = a - rf.COPY_ORG
            out.append((a, ' '.join('%02X' % x for x in data[o:o + n]), ' '.join(w), None))
            if w[0] in ('jump', 'ret'):
                break
    return out


def cmd_anim_stretch(screen_gif, first, step, vars_path, out):
    sys.path.insert(0, os.path.join(CASE, 'work', 'docs', 'erC'))
    import json
    samples = {}
    for line in open(vars_path):
        r = json.loads(line)
        mem = {}
        for k, v in r.items():
            if k != 'f' and v:
                for i, x in enumerate(bytes.fromhex(v)):
                    mem[int(k, 16) + i] = x
        samples[r['f']] = mem
    src = Image.open(screen_gif)
    lines = anim_lines()
    mono, small, big = kitlib.font(14), kitlib.font(13), kitlib.font(17)
    pictures = []
    k = 0
    while True:
        try:
            src.seek(k)
        except EOFError:
            break
        f = first + step * k
        k += 1
        mem = samples.get(f)
        if mem is None:
            continue
        w16 = lambda a: mem[a] | mem[a + 1] << 8  # noqa: E731
        ptr, dist, scroll = w16(0x5E27), w16(0x5E29), w16(0x9136)
        seg, var = w16(0x5E25), mem[0x5E36]
        depth, ret, length, done = mem[0x5E37], w16(0x5E38), w16(0x5E3A), w16(0x5E3C)
        img = Image.new('RGB', (1050, 560), 'white')
        img.paste(src.convert('RGB'), (0, 40))
        d = ImageDraw.Draw(img)
        d.text((12, 10), 'c1 frame %d: TrackStep walks the track as the bike drives' % f, fill='black', font=big)
        x0, y = 530, 44
        call_line = ret - 5 if depth else None
        for a, raw, text, extra in lines:
            if extra == 'head':
                y += 4
                d.text((x0, y), text, fill='black', font=small)
                y += 19
                continue
            if a == ptr:
                d.rectangle([x0 - 4, y - 1, 1046, y + 17], fill='#ffe08a')
            elif a == call_line:
                d.rectangle([x0 - 4, y - 1, 1046, y + 17], fill='#cfe3ff')
            d.text((x0, y), '%04X' % a, fill='#666666', font=mono)
            d.text((x0 + 46, y), raw, fill='#1f4e9e', font=mono)
            d.text((x0 + 186, y), text, fill='black', font=mono)
            if extra is not None:
                d.text((x0 + 380, y), '@%d' % extra, fill='#b04000', font=mono)
            y += 19
        y = 430
        rows = [('TrackPtr', '$%04X (yellow: the next element ahead)' % ptr),
                ('TrackStack', 'depth %d, return $%04X (blue: its call)' % (depth, ret) if depth else 'depth 0'),
                ('  frame', 'length %d, done %d units' % (length, done) if depth else ''),
                ('TrackDistance', '$%04X: %d.%02d units past the element' % (dist, dist >> 8, (dist & 255) * 100 // 256)),
                ('ScrollStep', '$%04X: %.1f units a pass' % (scroll, scroll / 256)),
                ('SegmentLeft', '$%04X, VarObject %d' % (seg, var))]
        for name, text in rows:
            d.text((x0, y), name, fill='black', font=small)
            d.text((x0 + 120, y), text, fill='#333333', font=small)
            y += 20
        pictures.append(img)
    kitlib.save_gif(out, pictures, [160] * (len(pictures) - 1) + [2000])
    print('%s: %d pictures' % (os.path.relpath(out, CASE), len(pictures)))


def load_rows(path, lo, hi):
    import json
    out = []
    for line in open(path):
        r = json.loads(line)
        if not lo <= r['f'] <= hi or not r.get('5C80'):
            continue
        b = bytes.fromhex(r['5C80'])
        spd = bytes.fromhex(r['7C2E'])[6] if r.get('7C2E') else 0
        out.append((r['f'], [b[15 * k:15 * k + 15] for k in range(6)], spd))
    return out


def cmd_fig_ring(out, c1_path, st_path):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11})
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 7.6), dpi=100)
    colours = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    for ax, path, lo, hi, who, title in (
            (axes[0], c1_path, 14075, 16100, range(4), 'c1, stage 1: riders 0-3 from the start'),
            (axes[1], st_path, 7800, 9300, (4, 5), 'stages, stage 4: the trucks (riders 4 and 5)')):
        rows = load_rows(path, lo, hi)
        fs = [f for f, _, _ in rows]
        for k in who:
            ys = []
            for f, recs, _ in rows:
                rec = recs[k]
                ys.append(None if rec[0] & 0x80 else rec[4])
            xs, yy = [], []
            for f, y in zip(fs, ys):
                if y is None:
                    continue
                if yy and abs(y - yy[-1]) > 128:
                    ax.plot(xs, yy, '.', ms=2, color=colours[k])
                    xs, yy = [], []
                xs.append(f)
                yy.append(y)
            ax.plot(xs, yy, '.', ms=2, color=colours[k], label='rider %d%s' % (k, ' (truck)' if k >= 4 else ''))
        ax.axhspan(0, 0x50, color='#e8f0ff', zorder=0)
        ax.axhline(0, color='black', lw=0.8)
        ax2 = ax.twinx()
        ax2.plot(fs, [s for _, _, s in rows], color='#888888', lw=1)
        ax2.set_ylabel('SPEED (km/h), grey')
        ax2.set_ylim(0, 400)
        ax.set_ylim(0, 255)
        ax.set_yticks([0, 0x50, 128, 192, 255])
        ax.set_yticklabels(['0: the bike', '80: drawn below', '128', '192', '255'])
        ax.set_xlabel('TTD frame')
        ax.set_ylabel('distance high byte')
        ax.set_title(title)
        ax.legend(loc='upper right', markerscale=5, fontsize=10)
    fig.suptitle('The riders on a ring of 256 rows: a row falls through 0 when the bike overtakes and wraps to 255')
    fig.tight_layout()
    fig.savefig(out)


def cmd_fig_fields(out, a_path, b_path):
    """c1 at a segment of field 2-3 only and one of field 0-1 only (screen_shot.py --scale 2 pictures)"""
    a, b = Image.open(a_path).convert('RGB'), Image.open(b_path).convert('RGB')
    w = 1050
    scale = (w - 30) / 2 / a.width
    a = a.resize((int(a.width * scale), int(a.height * scale)), Image.NEAREST)
    b = b.resize(a.size, Image.NEAREST)
    img = Image.new('RGB', (w, a.height + 92), 'white')
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'The two segment fields on screen (c1)', fill='black', font=kitlib.font(18))
    img.paste(a, (10, 40))
    img.paste(b, (20 + a.width, 40))
    f = kitlib.font(14)
    d.text((10, 46 + a.height), 'frame 14 960, $9C: bits 2-3 = 3, bits 0-1 = 0', fill='black', font=f)
    d.text((10, 66 + a.height), 'the rows move up or down; the road runs straight', fill='#333333', font=f)
    d.text((20 + a.width, 46 + a.height), 'frame 15 250, $91: bits 0-1 = 1, bits 2-3 = 0',
           fill='black', font=f)
    d.text((20 + a.width, 66 + a.height), 'a bend: the row centres shift sideways', fill='#333333',
           font=f)
    img.save(out)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    cmd, out = sys.argv[1], sys.argv[2]
    if cmd == 'fig-fields':
        cmd_fig_fields(out, sys.argv[3], sys.argv[4])
        return 0
    if cmd == 'fig-ring':
        cmd_fig_ring(out, sys.argv[3], sys.argv[4])
        return 0
    if cmd == 'anim-stretch':
        cmd_anim_stretch(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5], sys.argv[6])
        return 0
    {'fig-formats': cmd_fig_formats, 'fig-types': cmd_fig_types, 'fig-riders': cmd_fig_riders,
     'fig-stretch': cmd_fig_stretch}[cmd](out)
    return 0


if __name__ == '__main__':
    sys.exit(main())

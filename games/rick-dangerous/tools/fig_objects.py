#!/usr/bin/env python3
"""Doc 07: a zone decoded byte by byte, and the object slot record as a data sheet.

    python3 tools/fig_rooms.py --out work/stage2/fig                     # the zone pictures (once)
    python3 tools/fig_objects.py zone L1Z1 docs/img/objects/zone-L1Z1.png
    python3 tools/fig_objects.py record work/images/play.view.bin docs/img/objects/record.png
    python3 tools/fig_objects.py kinds docs/img/objects/kinds.png
    python3 tools/fig_objects.py path L1Z1 42 docs/img/objects/boulder-path.png
    python3 tools/fig_objects.py frames docs/img/sprites/sheet.png

zone: the zone's picture (tools/fig_rooms.py: the tiles, the objects' boxes, the exits) beside the bytes of its zone
record, its exit list and its object list, each field decoded, all read from build/game.bin.
record: the object table `$EA8E` of a memory image (a 64K view), slot by slot, each of the 30 bytes under its field's
name; Rick's slot and a zone enemy's are spelled out.
kinds: the 72 kind records `$D31C` (8 bytes each) as a sheet: each kind's first picture (its graphic, or the first
frame of its animation list), its group, its size bytes +0/+1 and its trigger box +6/+7 (chars).
path: one actor's movement script walked step by step from its spawn point over the zone's picture, as TrapMove
`$EE0B` walks it (x leaves 0-`$E7`: the path ends).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 75)
HI = (250, 210, 80)
ZONES = 0xD55C
KIND_NAMES = {0: 'free', 1: 'Rick', 2: 'bullet', 3: 'dynamite', 22: 'bonus start', 23: 'bonus end', 42: 'boulder',
              16: 'dynamite box', 17: 'bullet box'}


def kind_name(k):
    k &= 0x7F
    if k in KIND_NAMES:
        return KIND_NAMES[k]
    if 4 <= k <= 15:
        return ('patrol', 'tracker', 'climber')[(k - 4) % 3] + ' enemy'
    if 18 <= k <= 21:
        return 'treasure'
    if k >= 24:
        return 'trap / actor'
    return f'kind {k}'


def zone_index(name):
    order = [6, 7, 12, 9]
    lv, z = int(name[1:name.index('Z')]), int(name[name.index('Z') + 1:])
    return sum(order[:lv - 1]) + z - 1


def cmd_zone(name, png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    m = (lambda a: img[a - 0x5B00])
    w = (lambda a: m(a) | m(a + 1) << 8)
    zi = zone_index(name)
    rec = ZONES + 7 * zi
    pic = Image.open(os.path.join(CASE, 'work', 'stage2', 'fig', f'zone-{name}.png')).convert('RGB')
    W = 1050
    ph = 760
    pw = round(pic.width * ph / pic.height)
    pic = pic.resize((pw, ph), Image.NEAREST)
    H = 100 + ph + 20
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), f'Zone {name} decoded: its 7-byte record, its exits and its objects, byte by byte', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), 'From build/game.bin by tools/fig_objects.py. The picture is tools/fig_rooms.py\'s: the tiles, '
           'the objects\' boxes and kinds, the exits.', fill=DIM, font=K.font(14))
    out.paste(pic, (12, 80))
    x0, y = 12 + pw + 24, 80
    f, fs = K.font(15), K.font(14)

    def line(text, col=TEXT, font=f, dy=21):
        nonlocal y
        d.text((x0, y), text, fill=col, font=font)
        y += dy

    raw = ' '.join(f'{m(rec + i):02X}' for i in range(7))
    line(f'zone record ${rec:04X} = ZONES + 7 x {zi}:', HI)
    line(f'  {raw}', TEXT)
    mp, ex, ob = w(rec + 1), w(rec + 3), w(rec + 5)
    line(f'  +0    {m(rec):02X}     char set {m(rec)} (${0x7100 if m(rec) == 0 else 0x7A00:04X})', DIM, fs, 19)
    line(f'  +1-2  {m(rec + 1):02X} {m(rec + 2):02X}  map ${mp:04X}', DIM, fs, 19)
    line(f'  +3-4  {m(rec + 3):02X} {m(rec + 4):02X}  exits ${ex:04X}', DIM, fs, 19)
    line(f'  +5-6  {m(rec + 5):02X} {m(rec + 6):02X}  objects ${ob:04X}', DIM, fs, 19)
    y += 8
    line(f'map ${mp:04X}: rows of 8 tile numbers', HI)
    nrows = (w(rec + 8) - mp) // 8 if zi < 33 else 15
    for r in (0, 5, 6, 7):
        line(f'  row {r:2}: ' + ' '.join(f'{m(mp + 8 * r + i):02X}' for i in range(8)), DIM, fs, 19)
    t = m(mp + 40)
    line(f'  tile ${t:02X} at ${0xC31C + 16 * t:04X}: ' + ' '.join(f'{m(0xC31C + 16 * t + i):02X}' for i in range(4))
         + ' / ...', DIM, fs, 19)
    line(f'  {nrows} rows = {nrows * 4} char rows', DIM, fs, 19)
    y += 8
    line(f'exits ${ex:04X}: side, row, zone, row there', HI)
    a = ex
    while m(a) != 0xFF:
        side, row, to, row2 = m(a), m(a + 1), w(a + 2), m(a + 4)
        dest = 'the level\'s end' if to == 0xFFFF else f'zone ${to:04X} (Z{(to - ZONES) // 7 - zi + int(name[name.index("Z") + 1:])})'
        line(f'  {" ".join(f"{m(a + i):02X}" for i in range(5))}  {"left " if side == 0 else "right"} at row ${row:02X}'
             f' -> {dest}, row ${row2:02X}', DIM, fs, 19)
        a += 5
    line('  FF  the list\'s end', DIM, fs, 19)
    y += 8
    line(f'objects ${ob:04X}: row, kind, flags, x, q', HI)
    a = ob
    while m(a) != 0xFF:
        row, kind, flags, x, q = (m(a + i) for i in range(5))
        line(f'  {row:02X} {kind:02X} {flags:02X} {x:02X} {q:02X}  row ${row:02X}, kind {kind & 0x7F} '
             f'({kind_name(kind)}), x {x & 0xF8}', DIM, fs, 19)
        a += 5
    line('  FF  then the 4 bytes "term" (never read)', DIM, fs, 19)
    out.save(png)
    print(png, out.size)


FIELDS = [(0, 1, 'type'), (1, 1, 'x'), (2, 2, 'y'), (4, 2, 'frame'), (6, 1, 'mir'), (7, 1, 'wid'),
          (8, 1, 'hgt'), (9, 2, 'list entry'), (11, 1, 'flag'), (12, 1, 'trg x'), (13, 2, 'trig y'), (15, 1, 'hm x'),
          (16, 2, 'home y'), (18, 2, 'frame base'), (20, 2, 'path start'), (22, 2, 'path ptr'), (24, 1, 'step'),
          (25, 1, 'cnt'), (26, 1, 'frac'), (27, 2, 'y speed'), (29, 1, 'stun')]


def cmd_record(view, png):
    mem = open(view, 'rb').read()
    W = 1050
    cw = 29
    x0 = 168
    H = 150 + 12 * 30 + 260
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The object table $EA8E: 12 slots of 30 bytes, in play', fill=TEXT, font=K.font(22))
    d.text((12, 44), f'{os.path.basename(view)} (c1 frame 31 500, level 1). From the image by tools/fig_objects.py '
           'record. Each column one byte of a slot.', fill=DIM, font=K.font(14))
    colours = [(70, 80, 120), (60, 100, 70)]
    for i, (off, n, name) in enumerate(FIELDS):
        xa = x0 + off * cw
        d.rectangle((xa, 74, xa + n * cw - 3, 122), fill=colours[i % 2])
        d.text((xa + 2, 76), f'+{off}', fill=TEXT, font=K.font(12))
        words = name.split(' ')
        for k, wd in enumerate(words[:2]):
            d.text((xa + 2, 92 + 14 * k), wd, fill=TEXT, font=K.font(11))
    owners = ['0 block', '1 Rick', '2 bullet', '3 dynamite'] + [f'{s} zone' for s in range(4, 12)]
    for s in range(12):
        a = 0xEA8E + 30 * s
        yy = 132 + 30 * s
        rec = mem[a:a + 30]
        col = HI if s in (1, 10) else (TEXT if rec[0] else DIM)
        d.text((12, yy), f'${a:04X} {owners[s]}', fill=col, font=K.font(13))
        for i, b in enumerate(rec):
            d.text((x0 + i * cw + 4, yy), f'{b:02X}', fill=col, font=K.font(13))
    yy = 132 + 30 * 12 + 16
    r = mem[0xEAAC:0xEAAC + 30]
    e = mem[0xEBBA:0xEBBA + 30]
    lines = [
        ('Rick, slot 1 ($EAAC):', HI),
        (f'  type {r[0]:02X} = kind 1 (Rick); x ${r[1]:02X} = {r[1]}; y ${r[3]:02X}{r[2]:02X} = {r[2] | r[3] << 8} '
         f'(pixels from the view top row); frame ${r[5]:02X}{r[4]:02X} = sprite frame {((r[4] | r[5] << 8) - 0x8401) // 126}', TEXT),
        (f'  mirror {r[6]:02X} (bit 0 set: drawn mirrored); width ${r[7]:02X} = 24, height ${r[8]:02X} = 21 pixels', TEXT),
        ('A zone enemy, slot 10 ($EBBA):', HI),
        (f'  type {e[0]:02X} = kind {e[0] & 0x7F} ({kind_name(e[0])}); x {e[1]}, y {e[2] | e[3] << 8}; frame '
         f'${e[5]:02X}{e[4]:02X} = frame {((e[4] | e[5] << 8) - 0x8401) // 126}; mirror {e[6]:02X}', TEXT),
        (f'  list entry ${e[10]:02X}{e[9]:02X}; flags ${e[11]:02X}; frame base ${e[19]:02X}{e[18]:02X} = frame '
         f'{((e[18] | e[19] << 8) - 0x8401) // 126}; walk step {e[24] - 256 if e[24] > 127 else e[24]}; '
         f'count {e[25]}', TEXT),
        ('Grey: a free slot (+0 = 0). The $FF after slot 11 ($EBF6) ends the table.', DIM),
    ]
    for text, col in lines:
        d.text((12, yy), text, fill=col, font=K.font(15))
        yy += 24
    out.save(png)
    print(png, out.size)


def frame_pixels(img, addr):
    """21 rows x 24 pixels: (mask, ink) per pixel of the 126-byte frame at addr (POP order OR3 OR2 OR1 AND1 AND3 AND2)"""
    src = {0x6A80: 0x6BA4, 0x7080: 0x6C22}.get(addr, addr)
    raw = img[src - 0x5B00:src - 0x5B00 + 126]
    rows = []
    for r in range(21):
        or3, or2, or1, and1, and3, and2 = raw[6 * r:6 * r + 6]
        row = []
        for m, p in ((and1, or1), (and2, or2), (and3, or3)):
            for b in range(7, -1, -1):
                row.append((m >> b & 1, p >> b & 1))
        rows.append(row)
    return rows


def draw_sprite(d, rows, ox, oy, cell, mirror=False):
    for y, row in enumerate(rows):
        row = row[::-1] if mirror else row
        for x, (keep, ink) in enumerate(row):
            if keep and not ink:
                continue
            col = (230, 230, 230) if ink else (0, 0, 0)
            d.rectangle((ox + x * cell, oy + y * cell, ox + x * cell + cell - 1, oy + y * cell + cell - 1), fill=col)


def kind_picture(img, k):
    """(frame address, mirror) of kind k's first picture, or None"""
    m = (lambda a: img[a - 0x5B00])
    a = 0xD31C + 8 * k
    g = m(a + 2) | m(a + 3) << 8
    if g == 0:
        return None
    if k < 24:
        return g, False
    for i in range(16):
        b = m(g + i)
        if b == 0xFF:
            return None
        if b & 0x7F:
            return 0x8383 + 126 * (b & 0x7F), bool(b & 0x80)
    return None


def cmd_kinds(png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    m = (lambda a: img[a - 0x5B00])
    W, cw, ch, cols = 1050, 104, 118, 10
    kinds = [1] + list(range(4, 71))
    rows = (len(kinds) + cols - 1) // cols
    H = 96 + rows * ch + 40
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The object kinds: 72 records of 8 bytes at $D31C, each with its first picture', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), 'From build/game.bin by tools/fig_objects.py kinds. Under each: kind and group; +0 x +1 (pixels); '
           '+6 x +7 (trigger box, chars).', fill=DIM, font=K.font(13))
    d.text((12, 64), 'Kinds 0, 2, 3 and 71 are all zeros (the bullet and the stick are drawn by their own code).',
           fill=DIM, font=K.font(14))
    groups = {'pic': (255, 220, 0), 'mark': (0, 230, 230), 'actor': (255, 90, 90), 'Rick': (120, 220, 120)}
    for i, k in enumerate(kinds):
        x0, y0 = 12 + (i % cols) * cw, 96 + (i // cols) * ch
        a = 0xD31C + 8 * k
        grp = 'Rick' if k == 1 else 'pic' if k < 22 else 'mark' if k < 24 else 'actor'
        d.rectangle((x0, y0, x0 + cw - 6, y0 + ch - 6), outline=GRID)
        d.rectangle((x0 + 1, y0 + 1, x0 + 72 + 4, y0 + 63 + 4), fill=(40, 70, 90))
        pic = kind_picture(img, k) if k != 1 else (0x8401 + 126, False)
        if pic:
            draw_sprite(d, frame_pixels(img, pic[0]), x0 + 3, y0 + 3, 3, pic[1])
        d.text((x0 + 4, y0 + 70), f'{k} {grp}', fill=groups[grp], font=K.font(13))
        d.text((x0 + 4, y0 + 88), f'{m(a)}x{m(a + 1)}  {m(a + 6)}x{m(a + 7)}', fill=DIM, font=K.font(12))
    out.save(png)
    print(png, out.size)


def cmd_path(name, kind, png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    m = (lambda a: img[a - 0x5B00])
    w = (lambda a: m(a) | m(a + 1) << 8)
    zi = zone_index(name)
    rec = ZONES + 7 * zi
    ob = w(rec + 5)
    a = ob
    while m(a) != 0xFF and (m(a + 1) & 0x7F) != kind:
        a += 5
    row, k, flags, xb, q = (m(a + i) for i in range(5))
    x, y = xb & 0xF8, ((row & 0xF8) + (xb & 7)) * 8 + 3
    kr = 0xD31C + 8 * kind
    sc = w(kr + 4)
    steps = []
    p = sc
    while m(p) != 0xFF:
        steps.append((m(p), (m(p + 1) ^ 128) - 128, (m(p + 2) ^ 128) - 128))
        p += 3
    pic = Image.open(os.path.join(CASE, 'work', 'stage2', 'fig', f'zone-{name}.png')).convert('RGB')
    s = pic.width / 256
    W = 1050
    out = Image.new('RGB', (W, 96 + pic.height + 120), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), f'Kind {kind} in {name}: its movement script ${sc:04X} walked from its spawn point', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), f'tools/fig_objects.py path, from build/game.bin. Object record ${a:04X}. Zone picture: '
           'fig_rooms.py, 2 pixels a map pixel.', fill=DIM, font=K.font(14))
    out.paste(pic, (12, 80))
    ox, oy = 12, 80
    tx, ty = q & 0xF8, (row & 0xF8) * 8 + 3
    tw, th = m(kr + 6) * 8, m(kr + 7) * 8
    d.rectangle((ox + tx * s, oy + ty * s, ox + (tx + tw) * s, oy + (ty + th) * s), outline=(80, 255, 80), width=3)
    pts = [(x, y)]
    lines = []
    for i, (n, dx, dy) in enumerate(steps):
        nx, ny, cut = x, y, n
        for j in range(n):
            if not 0 <= nx + dx < 0xE8:
                cut = j
                break
            nx, ny = nx + dx, ny + dy
        lines.append((i, n, dx, dy, x, y, nx, ny, cut))
        x, y = nx, ny
        pts.append((x, y))
        if cut < n:
            break
    cols = [(255, 120, 60), (255, 220, 0)]
    for i, (_, n, dx, dy, x1, y1, x2, y2, cut) in enumerate(lines):
        c = cols[i % 2]
        d.line((ox + (x1 + 12) * s, oy + (y1 + 10) * s, ox + (x2 + 12) * s, oy + (y2 + 10) * s), fill=c, width=4)
        d.ellipse((ox + (x2 + 12) * s - 6, oy + (y2 + 10) * s - 6, ox + (x2 + 12) * s + 6, oy + (y2 + 10) * s + 6),
                  fill=c)
        d.text((ox + (x2 + 12) * s + 8, oy + (y2 + 10) * s - 18), str(i), fill=c, font=K.font(16))
    x0 = 12 + pic.width + 24
    yy = 80
    f = K.font(15)
    for t, c in ((f'object record ${a:04X}:', HI), ('  ' + ' '.join(f'{m(a + i):02X}' for i in range(5)), TEXT),
                 (f'  row ${row:02X}, kind {k & 0x7F}, flags ${flags:02X}', DIM),
                 (f'  x ${xb:02X}: x {xb & 0xF8}, row offset {xb & 7}', DIM),
                 (f'  +4 ${q:02X}: trigger x {q & 0xF8}', DIM),
                 (f'spawn point (map pixels): x {pts[0][0]}, y {pts[0][1]}', DIM),
                 (f'trigger box (green): {tw} x {th} pixels', (80, 255, 80)),
                 ('', DIM), (f'script ${sc:04X}: count, dx, dy', HI)):
        d.text((x0, yy), t, fill=c, font=f)
        yy += 22
    for i, n, dx, dy, x1, y1, x2, y2, cut in lines:
        note = '' if cut == n else f' (x < 0 after {cut})'
        d.text((x0, yy), f'{i}: {n:3} x ({dx:+d},{dy:+d})  to x {x2}, y {y2}{note}', fill=cols[i % 2], font=f)
        yy += 22
    yy += 10
    for t in ('The line follows the sprite\'s middle', '(x + 12, y + 10), one pass a step.',
              'Slot y is the map y less 8 x ViewTopRow;', 'a slot y of $12A or more also ends', 'the path (with the start view, map y 362).',
              'Then the path ends: a one-shot object', 'goes; this one (flag bit 0 clear) goes back',
              'to its spawn point and waits again.'):
        d.text((x0, yy), t, fill=DIM, font=K.font(14))
        yy += 20
    out.save(png)
    print(png, out.size)


def frame_users(img):
    """frame number -> the kinds whose record names it (a picture for kinds under 24, the animation list for the rest)"""
    m = (lambda a: img[a - 0x5B00])
    use = {}
    for k in range(72):
        a = 0xD31C + 8 * k
        g = m(a + 2) | m(a + 3) << 8
        if not g:
            continue
        if k < 24:
            if 0x8401 <= g < 0x9E95 and (g - 0x8401) % 126 == 0:
                use.setdefault((g - 0x8401) // 126, set()).add(k)
            continue
        for i in range(64):
            b = m(g + i)
            if b == 0xFF:
                break
            if b & 0x7F:
                use.setdefault((b & 0x7F) - 1, set()).add(k)
    return use


def cmd_frames(png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    use = frame_users(img)
    W, cols, cw, ch = 1050, 9, 115, 136
    rows = 6
    H = 96 + rows * ch + 70
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The 54 sprite frames at $8401, 126 bytes each, with the kinds that name them', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), 'tools/fig_objects.py frames, from build/game.bin. White: pixels; black: cleared by the mask; '
           'blue: background kept.', fill=DIM, font=K.font(14))
    d.text((12, 64), 'Under each: frame number, address, and the kinds whose record ($D31C) or animation list '
           'names it.', fill=DIM, font=K.font(14))
    for f in range(54):
        x0, y0 = 12 + (f % cols) * cw, 96 + (f // cols) * ch
        d.rectangle((x0, y0, x0 + cw - 6, y0 + ch - 6), outline=GRID)
        d.rectangle((x0 + 1, y0 + 1, x0 + 72 + 4, y0 + 63 + 4), fill=(40, 70, 90))
        draw_sprite(d, frame_pixels(img, 0x8401 + 126 * f), x0 + 3, y0 + 3, 3)
        d.text((x0 + 4, y0 + 70), f'{f}  ${0x8401 + 126 * f:04X}', fill=TEXT, font=K.font(13))
        ks = sorted(use.get(f, ()))
        label = 'by code' if not ks else ' '.join(str(k) for k in ks)
        col = DIM if not ks else HI
        words, line, yy = label.split(' '), '', y0 + 88
        for w_ in words:
            if len(line) + len(w_) + 1 > 13:
                d.text((x0 + 4, yy), line, fill=col, font=K.font(12))
                line, yy = w_, yy + 15
            else:
                line = (line + ' ' + w_).strip()
        d.text((x0 + 4, yy), line, fill=col, font=K.font(12))
    y = 96 + rows * ch + 6
    d.text((12, y), '"by code": no kind record names the frame; the code picks it (Rick\'s frames, the enemies\' '
           'walk cycles).', fill=DIM, font=K.font(14))
    d.text((12, y + 20), 'Kinds 16 and 19 point outside the sheet, at $6A80 and $7080: two frames Start copies there '
           'from $6BA4.', fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size)


def main():
    a = sys.argv[1:]
    if len(a) == 3 and a[0] == 'zone':
        cmd_zone(a[1], a[2])
    elif len(a) == 3 and a[0] == 'record':
        cmd_record(a[1], a[2])
    elif len(a) == 2 and a[0] == 'kinds':
        cmd_kinds(a[1])
    elif len(a) == 4 and a[0] == 'path':
        cmd_path(a[1], int(a[2]), a[3])
    elif len(a) == 2 and a[0] == 'frames':
        cmd_frames(a[1])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

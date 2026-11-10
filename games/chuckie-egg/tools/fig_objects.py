#!/usr/bin/env python3
"""The figures of doc 07 (objects), drawn from src/res and from memory samples of the recordings.

    python3 tools/fig_objects.py levels  --out docs/img/objects/levels-objects.png
    python3 tools/fig_objects.py tables  --out docs/img/objects/hen-lift-tables.png
    python3 tools/fig_objects.py block   --samples S.jsonl --frame F --screen SCR.jsonl --out docs/img/objects/block.png
    python3 tools/fig_objects.py livemap --samples MAPS.jsonl --frame F --out docs/img/objects/livemaps.png
    python3 tools/fig_objects.py henwalk --samples S.jsonl --screens SCR.jsonl --frames A-B --hen N --out PNG

A samples file is JSON lines {"frame": F, "hex": ...} written by work/docs/ceC/sample.py (TTD memory_at, the memory
at the start of the frame). The block samples cover $72D8-$7375, the map samples $61A8-$6EC7, the screen samples
$4000-$5AFF. Coordinates are the game's: x from the left, y from the bottom of the screen; a map row r covers
y = 8r .. 8r + 7, row 0 at the bottom; the map figure is the play area, rows 0-20, so a pixel (x, y) is at
(x, 167 - y) in it before scaling.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import res_formats as rf  # noqa: E402
import fig_maps  # noqa: E402
import kitlib as K  # noqa: E402

BLOCK = 0x72D8
INK = fig_maps.INK
BG = K.BACKGROUND
TEXT = K.TEXT
DIM = K.DIM
STATE = {1: 'walk left', 2: 'walk right', 3: 'climb down', 4: 'climb up', 7: 'peck left', 8: 'peck right'}

# The object block $72D8-$7375 by owner (game.ann @equ); (start, end inclusive, name, owner)
FIELDS = [
    (0x72D8, 0x72D8, 'HarryX', 'harry'), (0x72D9, 0x72D9, 'HarryY', 'harry'),
    (0x72DA, 0x72DA, 'HarryFrame', 'harry'), (0x72DB, 0x72DB, 'HarryDir', 'harry'),
    (0x72DC, 0x72DC, 'PassCounter', 'clock'),
    (0x7325, 0x7325, 'JumpState', 'jump'), (0x7326, 0x7326, 'JumpDx', 'jump'),
    (0x7327, 0x7327, 'JumpCount', 'jump'), (0x7328, 0x7328, 'JumpDelay', 'jump'),
    (0x732A, 0x732A, 'JumpDy', 'jump'),
    (0x733C, 0x733C, 'LiftDelay', 'clock'),
    (0x733F, 0x7341, 'BonusDigits', 'hud'), (0x7342, 0x7344, 'TimeDigits', 'hud'),
    (0x7345, 0x7345, 'BonusDelay', 'clock'), (0x7346, 0x7346, 'TimeDelay', 'clock'),
    (0x7347, 0x7347, 'BonusRunning', 'hud'),
    (0x7348, 0x7348, 'DuckX', 'duck'), (0x7349, 0x7349, 'DuckY', 'duck'),
    (0x734A, 0x734A, 'DuckDx', 'duck'), (0x734B, 0x734B, 'DuckDy', 'duck'),
    (0x734C, 0x734C, 'DuckDelay', 'clock'), (0x734D, 0x734D, 'DuckFrame', 'duck'),
    (0x734E, 0x734F, 'Lift1', 'lift'), (0x7350, 0x7350, 'LiftX', 'lift'), (0x7351, 0x7351, 'Lift1Row', 'lift'),
    (0x7352, 0x7353, 'Lift2', 'lift'), (0x7354, 0x7354, 'Lift2Row', 'lift'), (0x7355, 0x7355, 'OnLift', 'lift'),
    (0x7356, 0x7356, 'HenTurn', 'hen'), (0x7357, 0x736A, 'Hens', 'hen'),
    (0x736B, 0x736B, 'HenDelay', 'clock'), (0x736C, 0x736D, 'RandomPtr', 'hen'),
]
OWNER = {'harry': ((235, 200, 60), 'Harry'), 'jump': ((240, 140, 60), 'jump / fall'),
         'lift': ((80, 200, 230), 'lifts'), 'duck': ((230, 230, 110), 'duck'),
         'hen': ((110, 220, 140), 'hens'), 'clock': ((190, 140, 240), 'slow-tick counters'),
         'hud': ((200, 120, 120), 'bonus / time digits')}


def font(n):
    return K.font(n)


def load_samples(path):
    out = {}
    with open(path) as f:
        for line in f:
            d = json.loads(line)
            out[d['frame']] = bytes.fromhex(d['hex'])
    return out


def res(path):
    with open(os.path.join(rf.RES, path), 'rb') as f:
        return f.read()


def sprites():
    return rf.png_to_sheet(res('sprites/Sprites.png')), rf.png_to_sheet(res('sprites/HenSprites.png'))


def hen_table():
    rows = rf.csv_rows(res('tables/HenTable.csv'))
    return {int(r[0]): [int(v) for v in r[1:]] for r in rows}


def lift_table():
    rows = rf.csv_rows(res('tables/LiftTable.csv'))
    return {r[0]: (rf.num(r[1]), int(r[2]), int(r[3])) for r in rows}


def level_cells(n):
    return rf.map_in(res('maps/Level%d.txt' % n))


def put_sprite(img, frame_bytes, x, top, colour, scale):
    """OR a 16 x 16 frame (two bytes a row, top row first) at map pixel (x, top) of a scaled map image"""
    px = img.load()
    for row in range(16):
        for half in range(2):
            b = frame_bytes[row * 2 + half]
            for bit in range(8):
                if b >> (7 - bit) & 1:
                    cx, cy = x + half * 8 + bit, top + row
                    if 0 <= cx < 256 and 0 <= cy < 168:
                        for dy in range(scale):
                            for dx in range(scale):
                                px[cx * scale + dx, cy * scale + dy] = colour


def map_image(n, scale=2):
    _rd, glyphs, attrs = fig_maps.load()
    return fig_maps.draw(level_cells(n), glyphs, attrs).resize((256 * scale, 168 * scale), Image.NEAREST)


def cmd_levels(args):
    spr, hen = sprites()
    ht, lt = hen_table(), lift_table()
    scale = 2
    mw, mh = 256 * scale, 168 * scale
    pad, head = 8, 52
    cols, rows = 2, 4
    legend_h = 240
    W = cols * mw + (cols + 1) * pad
    H = 64 + rows * (mh + head + pad) + legend_h
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((pad, 10), 'The eight level maps with their objects: what SetupLevel $AE9C puts on each (src/res)',
           fill=TEXT, font=font(20))
    d.text((pad, 38), 'Level n uses map ((n - 1) AND 7) + 1: levels 9-16, 17-24, ... repeat these eight maps.',
           fill=DIM, font=font(15))
    for n in range(1, 9):
        cells = level_cells(n)
        ox = pad + ((n - 1) % cols) * (mw + pad)
        oy = 64 + ((n - 1) // cols) * (mh + head + pad)
        m = map_image(n, scale)
        row = ht[n]
        count = row[0] // 4
        recs = [row[1 + 4 * k:4 + 4 * k] for k in range(5)]
        # the hens: solid for the level's own, outlined for the extra records used from level 25 on
        for k, (hx, hy, hs) in enumerate(recs):
            frame = {1: 0, 2: 1, 3: 2, 4: 3}.get(hs, 0)
            colour = INK[5] if k < count else (70, 110, 110)
            put_sprite(m, hen[frame * 32:frame * 32 + 32], hx, 167 - (hy + 15), colour, scale)
        put_sprite(m, spr[0:32], 100, 167 - 23, INK[6], scale)          # Harry at (100, 23), frame 0
        md = ImageDraw.Draw(m)
        for k, (hx, hy, hs) in enumerate(recs):
            tx, ty = hx * scale, (167 - (hy + 15)) * scale - 15
            arrow = {1: '<', 2: '>', 3: 'v', 4: '^'}.get(hs, '?')
            md.text((tx, max(0, ty)), '%d%s' % (k + 1, arrow), fill=INK[5] if k < count else (110, 160, 160),
                    font=font(13))
        # grain and eggs ringed
        grains = eggs = 0
        for r in range(21):
            for c in range(32):
                code = cells[r * 32 + c]
                if code in (3, 4):
                    x0, y0 = c * 8 * scale, (20 - r) * 8 * scale
                    col = (255, 255, 255) if code == 3 else (255, 210, 60)
                    md.rectangle([x0 - 1, y0 - 1, x0 + 8 * scale, y0 + 8 * scale], outline=col)
                    if code == 3:
                        eggs += 1
                    else:
                        grains += 1
        # the lift shaft
        _a, lx, _r = lt[str(n)]
        if lx != 255:
            x0 = lx * scale
            for yy in range(0, mh, 8):
                md.line([x0 - 2, yy, x0 - 2, yy + 4], fill=(80, 200, 230))
                md.line([x0 + 16 * scale + 1, yy, x0 + 16 * scale + 1, yy + 4], fill=(80, 200, 230))
            for y in (3, 67):  # the two platforms at the start (rows 3 and $43)
                yy = (167 - y) * scale
                md.rectangle([x0, yy, x0 + 16 * scale - 1, yy + 4 * scale - 1], fill=(80, 200, 230))
        img.paste(m, (ox, oy + head))
        n_h = count
        lift = 'lift at x %d' % lx if lx != 255 else 'no lift'
        d.text((ox, oy + 4), 'Level %d (and %d, %d, ...)' % (n, n + 8, n + 16), fill=TEXT, font=font(17))
        d.text((ox, oy + 27), '%d eggs, %d grain, %d hens (5 from level 25), %s' % (eggs, grains, n_h, lift),
               fill=DIM, font=font(14))
    ly = 64 + rows * (mh + head + pad) + 6
    items = [((255, 255, 255), 'egg (code 3): white box'), ((255, 210, 60), 'grain (code 4): yellow box'),
             (INK[5], 'hen at its start, number and first move (< > walk, v ^ climb)'),
             ((110, 160, 160), 'grey-green: the extra hen records copied only from level 25 on'),
             (INK[6], 'Harry at his start (100, 23); the duck in its cage at the top left'),
             ((80, 200, 230), 'lift: the shaft (dashes) and both platforms at their start rows 3 and 67')]
    for k, (c, t) in enumerate(items):
        x = pad
        y = ly + k * 26
        d.rectangle([x, y + 3, x + 16, y + 17], fill=c)
        d.text((x + 24, y), t, fill=TEXT, font=font(15))
    d.text((pad, ly + 160), 'Ladders are the magenta columns (codes 1 and 2), platforms the green bricks (code 5).',
           fill=DIM, font=font(15))
    d.text((pad, ly + 186), 'Drawn by tools/fig_objects.py levels from src/res/maps, tables/HenTable.csv, '
           'tables/LiftTable.csv, sprites/*.png', fill=DIM, font=font(14))
    img.save(args.out)
    print(args.out, img.size)


def cell_box(d, x, y, w, h, text, fill, outline=(60, 60, 75), tf=None, colour=(0, 0, 0)):
    d.rectangle([x, y, x + w, y + h], fill=fill, outline=outline)
    f = tf or font(14)
    tw = d.textlength(text, font=f)
    d.text((x + (w - tw) / 2, y + (h - 16) / 2), text, fill=colour, font=f)


def cmd_tables(args):
    ht, lt = hen_table(), lift_table()
    W = 1050
    bw, bh = 28, 26
    img = Image.new('RGB', (W, 900), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), 'HenTable $945B and LiftTable $9787: the per-level objects, byte by byte', fill=TEXT, font=font(20))
    d.text((10, 38), 'Row n is read for levels n, n + 8, n + 16, ... (SetupLevel $AE9C: (Level AND 7) + 1); '
           'HenTable row 0 is never read.', fill=DIM, font=font(14))
    y = 72
    d.text((10, y), 'HenTable: 21 bytes a row = count, then five records (x, y, state, pad)', fill=TEXT, font=font(16))
    y += 44
    x0 = 92
    heads = ['n'] + ['x', 'y', 's', 'p'] * 5
    d.text((10, y + 4), 'level', fill=DIM, font=font(14))
    for k, h in enumerate(heads):
        d.text((x0 + k * (bw + 3) + 8, y + 4), h, fill=DIM, font=font(13))
    for k in range(5):
        d.text((x0 + (1 + 4 * k) * (bw + 3) + 30, y - 18), 'hen %d' % (k + 1), fill=DIM, font=font(13))
    y += 24
    for n in range(0, 9):
        row = ht[n]
        cnt = row[0]
        d.text((10, y + 4), ('%d ' % n) + ('(unread)' if n == 0 else 'lv %d' % n), fill=TEXT if n else DIM,
               font=font(13))
        for k, v in enumerate(row):
            if k == 0:
                fill = (190, 140, 240)
            else:
                rec = (k - 1) // 4
                used = n > 0 and rec < cnt // 4
                fill = OWNER['hen'][0] if used else ((60, 90, 70) if n > 0 else (50, 50, 60))
                if (k - 1) % 4 == 3:
                    fill = (90, 90, 100) if n else (50, 50, 60)
            cell_box(d, x0 + k * (bw + 3), y, bw, bh - 4, '%02X' % v, fill, tf=font(12))
        y += bh
    d.text((10, y + 6), 'Purple: the byte count (8, 12 or 16 = 2, 3 or 4 hens; 20 from level 25 on).', fill=DIM, font=font(13))
    d.text((10, y + 24), 'Bright green: copied on levels 1-8 and 17-24; dark green: only from level 25 on; grey: '
           'the pad (never read).', fill=DIM, font=font(13))
    d.text((10, y + 42), 'States: 1 walk left, 2 walk right, 3 climb down, 4 climb up (MoveHen $911E).', fill=DIM,
           font=font(13))
    y += 78
    d.text((10, y), 'LiftTable: 4 bytes a row = screen address (low, high), x, start row', fill=TEXT, font=font(16))
    y += 26
    for name in ['current', '1', '2', '3', '4', '5', '6', '7', '8']:
        a, x, r = lt[name]
        d.text((10, y + 4), name if name == 'current' else 'lv ' + name, fill=TEXT, font=font(13))
        vals = [a & 255, a >> 8, x, r]
        for k, v in enumerate(vals):
            fill = OWNER['lift'][0] if x != 255 else (60, 70, 80)
            cell_box(d, x0 + k * (bw + 3), y, bw, bh - 4, '%02X' % v, fill, tf=font(12))
        if x != 255:
            third, line, crow = (a >> 11) & 3, (a >> 8) & 7, (a >> 5) & 7
            sy = third * 64 + crow * 8 + line
            d.text((x0 + 4 * (bw + 3) + 12, y + 4), '$%04X: column %d, line %d from the top = y %d; platform 2: $%04X, y %d' % (
                       a, a & 31, sy, 191 - sy, a - 0x800, 191 - sy + 64),
                   fill=TEXT, font=font(13))
        else:
            d.text((x0 + 4 * (bw + 3) + 12, y + 4), 'x $FF: no lift (MoveLifts and CatchLift return at once)',
                   fill=DIM, font=font(13))
        y += bh
    d.text((10, y + 8), 'Drawn by tools/fig_objects.py tables from src/res/tables/HenTable.csv and LiftTable.csv.',
           fill=DIM, font=font(13))
    img = img.crop((0, 0, W, y + 34))
    img.save(args.out)
    print(args.out, img.size)


def cmd_block(args):
    S = load_samples(args.samples)
    m = S[args.frame]
    W = 1050
    img = Image.new('RGB', (W, 760), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), 'The object block $72D8-$736D in %s frame %d: every byte by its owner' % (args.label, args.frame),
           fill=TEXT, font=font(19))
    d.text((10, 36), 'The memory at the start of the frame (TTD memory_at). $72DD-$7324 is CellBuffer (DrawSprite), '
           'not shown.', fill=DIM, font=font(14))
    owner = {}
    names = {}
    for a0, a1, name, own in FIELDS:
        for a in range(a0, a1 + 1):
            owner[a] = own
        names[a0] = name
    rowsets = [(0x72D8, 0x72DD), (0x7325, 0x736E)]
    bw, bh = 56, 30
    y = 70
    for lo, hi in rowsets:
        a = lo
        while a < hi:
            n = min(16, hi - a)
            d.text((10, y + 7), '$%04X' % a, fill=DIM, font=font(14))
            for k in range(n):
                addr = a + k
                v = m[addr - BLOCK]
                own = owner.get(addr)
                fill = OWNER[own][0] if own else (50, 50, 60)
                cell_box(d, 70 + k * (bw + 4), y, bw, bh, '%02X' % v, fill, tf=font(15))
            y += bh + 6
            a += n
        y += 10
    # decoded view
    g = lambda a: m[a - BLOCK]  # noqa: E731
    lines = [
        'Harry: x %d, y %d (top of the sprite), frame %d, dir %d; PassCounter %d' % (
            g(0x72D8), g(0x72D9), g(0x72DA), g(0x72DB), g(0x72DC)),
        'jump: state %d, dx %d, count %d, delay %d, dy %d' % (
            g(0x7325), (g(0x7326) ^ 128) - 128, g(0x7327), g(0x7328), (g(0x732A) ^ 128) - 128),
        'bonus %d%d%d0, time %d%d%d; delays: lift %d, bonus %d, time %d, duck %d, hen %d' % (
            g(0x733F), g(0x7340), g(0x7341), g(0x7342), g(0x7343), g(0x7344), g(0x733C), g(0x7345), g(0x7346),
            g(0x734C), g(0x736B)),
        'duck: (%d, %d), speed (%d, %d), wing frame %d' % (
            g(0x7348), g(0x7349), (g(0x734A) ^ 128) - 128, (g(0x734B) ^ 128) - 128, g(0x734D)),
        'lifts: x %d, platform 1 at $%04X row %d, platform 2 at $%04X row %d, OnLift %d' % (
            g(0x7350), g(0x734E) | g(0x734F) << 8, g(0x7351), g(0x7352) | g(0x7353) << 8, g(0x7354), g(0x7355)),
    ]
    hens = []
    for k in range(5):
        x, yy, s = g(0x7357 + 4 * k), g(0x7358 + 4 * k), g(0x7359 + 4 * k)
        hens.append('none' if x == 255 else '(%d, %d) %s' % (x, yy, STATE.get(s, str(s))))
    lines.append('hens (HenTurn %d, RandomPtr $%04X): ' % (g(0x7356), g(0x736C) | g(0x736D) << 8) +
                 ', '.join('%d %s' % (k + 1, h) for k, h in enumerate(hens[:2])) + ',')
    lines.append('    ' + ', '.join('%d %s' % (k + 3, h) for k, h in enumerate(hens[2:])))
    for t in lines:
        d.text((10, y), t, fill=TEXT, font=font(15))
        y += 24
    y += 8
    x = 10
    for own, (c, t) in OWNER.items():
        d.rectangle([x, y + 3, x + 16, y + 17], fill=c)
        d.text((x + 22, y), t, fill=TEXT, font=font(14))
        x += 30 + d.textlength(t, font=font(14))
        if x > W - 150:
            x = 10
            y += 24
    y += 26
    d.rectangle([10, y + 3, 26, y + 17], fill=(50, 50, 60))
    d.text((32, y), 'other: ScrollDelay, TextIndex, KeyType, KeyTable, Players, Player, ScoreScreenAddr '
           '(docs 05, 08), or unnamed', fill=DIM, font=font(14))
    y += 26
    d.text((10, y), 'Drawn by tools/fig_objects.py block from %s' % os.path.relpath(args.samples, rf.ROOT),
           fill=DIM, font=font(13))
    img = img.crop((0, 0, W, y + 26))
    img.save(args.out)
    print(args.out, img.size)


def cmd_livemap(args):
    S = load_samples(args.samples)
    m = S[args.frame]
    _rd, glyphs, attrs = fig_maps.load()
    scale = 1
    tiles = []
    for k in range(5):
        cells = m[k * 672:(k + 1) * 672]
        tiles.append(fig_maps.draw(cells, glyphs, attrs).resize((256, 168), Image.NEAREST))
    live = m[0:672]
    W = 1050
    img = Image.new('RGB', (W, 760), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), 'LiveMap $61A8 in %s frame %d: the map in play and the four players\' copies' % (
        args.label, args.frame), fill=TEXT, font=font(19))
    d.text((10, 36), 'Five maps of 672 bytes, 21 rows of 32 cells, row 0 at the bottom. The game reads and writes '
           'slot 0 only.', fill=DIM, font=font(14))
    big = tiles[0].resize((512, 336), Image.NEAREST)
    bd = ImageDraw.Draw(big)
    ref = m[672:1344]
    for r in range(21):
        for c in range(32):
            if live[r * 32 + c] != ref[r * 32 + c]:
                x0, y0 = c * 16, (20 - r) * 16
                bd.rectangle([x0, y0, x0 + 15, y0 + 15], outline=(255, 60, 60), width=2)
    img.paste(big, (10, 70))
    d.text((10, 410), 'slot 0 $61A8 (in play); red: cells unlike slot 1', fill=TEXT, font=font(14))
    for k in range(1, 5):
        x = 540 + ((k - 1) % 2) * 256 + ((k - 1) % 2) * 0
        y = 70 + ((k - 1) // 2) * 200
        img.paste(tiles[k], (532 + ((k - 1) % 2) * 260, y))
        d.text((532 + ((k - 1) % 2) * 260, y + 170), 'slot %d $%04X (player %d)' % (k, 0x61A8 + 672 * k, k),
               fill=TEXT, font=font(13))
    # a hex row as the worked example
    r = args.row
    y = 476
    d.text((10, y), 'Row %d of slot 0, $%04X-$%04X; the cell of pixel (x, y) is LiveMap + x / 8 + 4 x (y AND $F8):' % (
        r, 0x61A8 + 32 * r, 0x61A8 + 32 * r + 31), fill=TEXT, font=font(15))
    y += 26
    bw = 30
    for c in range(32):
        v = live[r * 32 + c]
        col = {0: (40, 40, 50), 1: INK[3], 2: INK[3], 3: (230, 230, 230), 4: (220, 190, 60), 5: INK[4]}.get(
            v, (200, 200, 90))
        cell_box(d, 10 + c * (bw + 2), y, bw, 26, '%02X' % v, col, tf=font(13))
        if c % 4 == 0:
            d.text((10 + c * (bw + 2), y + 30), str(c), fill=DIM, font=font(12))
    y += 58
    legend = [((40, 40, 50), '00 empty'), (INK[3], '01 / 02 ladder left / right'), ((230, 230, 230), '03 egg'),
              ((220, 190, 60), '04 grain'), (INK[4], '05 brick'), ((200, 200, 90), 'A8-B5 the cage')]
    x = 10
    for c, t in legend:
        d.rectangle([x, y + 3, x + 16, y + 17], fill=c)
        d.text((x + 22, y), t, fill=TEXT, font=font(14))
        x += 40 + d.textlength(t, font=font(14))
    y += 30
    for t in args.note or []:
        d.text((10, y), t, fill=TEXT, font=font(14))
        y += 22
    d.text((10, y + 4), 'Drawn by tools/fig_objects.py livemap from %s' % os.path.relpath(args.samples, rf.ROOT),
           fill=DIM, font=font(13))
    img = img.crop((0, 0, W, y + 30))
    img.save(args.out)
    print(args.out, img.size)


def cmd_henwalk(args):
    """A filmstrip: the hen's record and the screen around it, one picture a hen move"""
    S = load_samples(args.samples)
    SC = load_samples(args.screens)
    a, _, b = args.frames.partition('-')
    a, b = int(a), int(b)
    k = args.hen - 1
    frames = []
    prev = None
    for f in range(a, b + 1):
        if f not in S or f not in SC:
            continue
        rec = S[f][0x7357 + 4 * k - BLOCK:0x735A + 4 * k - BLOCK]
        if rec != prev:
            frames.append((f, rec))
            prev = rec
    frames = frames[:args.max]
    cw, ch = 168, 120  # crop of the screen, scaled 2: 84 x 60 pixels
    cols = 6
    rows = (len(frames) + cols - 1) // cols
    W = 1050
    img = Image.new('RGB', (W, 80 + rows * (ch + 70) + 40), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 10), args.title, fill=TEXT, font=font(18))
    d.text((10, 36), 'One picture a change of the record $%04X (x, y, state); the screen at the start of that frame, '
           '84 x 60 pixels, doubled.' % (0x7357 + 4 * k), fill=DIM, font=font(13))
    for i, (f, rec) in enumerate(frames):
        x, y, s = rec
        scr = K.render_screen(bytes(0x4000) + SC[f])
        x1, y1 = frames[0][1][0], frames[0][1][1]
        cx = max(0, min(256 - 84, x1 - 30))
        top = max(0, min(192 - 60, (191 - y1) - 40))
        crop = scr.crop((cx, top, cx + 84, top + 60)).resize((cw, ch), Image.NEAREST)
        ox = 10 + (i % cols) * (cw + 4)
        oy = 64 + (i // cols) * (ch + 70)
        img.paste(crop, (ox, oy))
        d.text((ox, oy + ch + 4), 'frame %d' % f, fill=TEXT, font=font(13))
        d.text((ox, oy + ch + 22), '%02X %02X %02X' % (x, y, s), fill=(110, 220, 140), font=font(13))
        d.text((ox, oy + ch + 40), '%d,%d %s' % (x, y, STATE.get(s, s)), fill=TEXT, font=font(12))
    d.text((10, img.height - 28), 'Drawn by tools/fig_objects.py henwalk from %s and %s' % (
        os.path.relpath(args.samples, rf.ROOT), os.path.relpath(args.screens, rf.ROOT)), fill=DIM, font=font(13))
    img.save(args.out)
    print(args.out, img.size, len(frames))


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('levels')
    s.add_argument('--out', required=True)
    s = sub.add_parser('tables')
    s.add_argument('--out', required=True)
    s = sub.add_parser('block')
    s.add_argument('--samples', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--label', default='levels-1-9')
    s.add_argument('--out', required=True)
    s = sub.add_parser('livemap')
    s.add_argument('--samples', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--row', type=int, default=4)
    s.add_argument('--label', default='levels-1-9')
    s.add_argument('--note', action='append')
    s.add_argument('--out', required=True)
    s = sub.add_parser('henwalk')
    s.add_argument('--samples', required=True)
    s.add_argument('--screens', required=True)
    s.add_argument('--frames', required=True)
    s.add_argument('--hen', type=int, default=1)
    s.add_argument('--max', type=int, default=18)
    s.add_argument('--title', default='A hen\'s walk with its state')
    s.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    globals()['cmd_' + args.cmd](args)


if __name__ == '__main__':
    main()

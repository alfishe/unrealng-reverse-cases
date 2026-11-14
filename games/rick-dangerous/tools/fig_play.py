#!/usr/bin/env python3
"""Doc 10: the world's char properties, and Rick's jump as the code computes it.

    python3 tools/fig_play.py props docs/img/play/props.png
    python3 tools/fig_play.py jump docs/img/play/jump-arc.png
    python3 tools/fig_play.py course work/docs/rdA/course-level1.json docs/img/play/course-level1.png
    python3 tools/fig_play.py zones docs/img/maps/zones.png   # after python3 tools/fig_rooms.py --out work/stage2/fig

zones: the 34 zone pictures of tools/fig_rooms.py (drawn from src/res/levels) on one contact sheet, level by level.

course: a recording's game state sampled every 20 frames (work/docs/rdA/course.py through `time_travel memory_at`:
Lives `$A958`, Dynamite `$A967`, Bullets `$A976`, Score `$A9BE`, the zone record RestartScreenRecord `$AD27`, Dying
`$FD68`) as stacked panels over the frames.

props: both char sets (bitmaps `$7100` / `$7A00`, attributes `$7900` / `$8200`), each char tinted by the property
BuildCharProps `$F6A9` gives it from the run-length tables CharPropsSet0 `$F6C0` / CharPropsSet1 `$F6D0` (read here
from build/game.bin, as the routine reads them).
jump: Rick's y pass by pass from a standing jump, as MoveRick `$F85D` computes it: y += the 8.8 speed, then the speed
+= `$80` up to `$0800`; the start speed is Jump's `$FA80`. With right held, x += 2 a pass (WalkRick `$F903`).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 75)
PROPS = {0x00: ('nothing', (60, 60, 75)), 0x02: ('ladder (bit 1)', (60, 200, 60)),
         0x04: ('deadly (bit 2)', (230, 50, 50)), 0x08: ('in front (bit 3)', (90, 120, 220)),
         0x10: ('platform (bit 4)', (230, 200, 40)), 0x60: ('spring + wall (bits 5, 6)', (230, 90, 230)),
         0x40: ('wall (bit 6)', (150, 150, 150)), 0x80: ('floor (bit 7)', (240, 140, 40))}


def load():
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    return img, (lambda a: img[a - 0x5B00])


def props_of(m, table):
    out = []
    for i in range(8):
        n, p = m(table + 2 * i), m(table + 2 * i + 1)
        out += [p] * n
    return out[:256]


def cmd_props(png):
    img, m = load()
    W, cell = 1050, 31
    H = 110 + 16 * cell + 120
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The char properties: what each char of the two sets is to Rick', fill=TEXT, font=K.font(22))
    d.text((12, 44), 'tools/fig_play.py props, from build/game.bin: BuildCharProps $F6A9 expands 8 (count, property) '
           'pairs into $5C00.', fill=DIM, font=K.font(14))
    for s, (chars, table, label) in enumerate(((0x7100, 0xF6C0, 'set 0 ($7100), levels 1-2'),
                                               (0x7A00, 0xF6D0, 'set 1 ($7A00), levels 3-4'))):
        pr = props_of(m, table)
        ox, oy = 12 + s * (16 * cell + 18), 100
        d.text((ox, oy - 26), label, fill=TEXT, font=K.font(16))
        for c in range(256):
            x, y = ox + (c % 16) * cell, oy + (c // 16) * cell
            d.rectangle((x, y, x + cell - 2, y + cell - 2), fill=PROPS[pr[c]][1])
            for r in range(8):
                b = m(chars + 8 * c + r)
                for bit in range(8):
                    if b >> (7 - bit) & 1:
                        d.rectangle((x + 4 + 3 * bit, y + 4 + 3 * r, x + 6 + 3 * bit, y + 6 + 3 * r), fill=(15, 15, 20))
        for r in range(16):
            d.text((ox - 2 + 16 * cell + 2, oy + r * cell + 8), '', fill=DIM, font=K.font(11))
    ly = 100 + 16 * cell + 14
    for i, (v, (name, col)) in enumerate(PROPS.items()):
        x, y = 12 + (i % 4) * 258, ly + (i // 4) * 26
        d.rectangle((x, y + 2, x + 18, y + 18), fill=col)
        d.text((x + 26, y), name, fill=TEXT, font=K.font(15))
    d.text((12, ly + 60), 'A char a cell, 16 a row: char n at row n / 16, column n mod 16. Its pixels are drawn dark '
           'over its property colour.', fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size)


def jump_path():
    y, frac, v, x = 0, 0, 0xFA80, 0
    pts = [(0, 0, 0, v)]
    for p in range(1, 60):
        sv = v - 0x10000 if v & 0x8000 else v
        tot = (y << 8 | frac) + sv
        y, frac = tot >> 8, tot & 0xFF
        x += 2
        if y >= 0 and p > 1:
            pts.append((p, x, 0, v))
            break
        v = (v + 0x80) & 0xFFFF
        if not v & 0x8000 and v > 0x800:
            v = 0x800
        pts.append((p, x, y, v))
    return pts


def cmd_jump(png):
    pts = jump_path()
    W, H = 1050, 500
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'Rick\'s jump, pass by pass, as MoveRick computes it', fill=TEXT, font=K.font(22))
    d.text((12, 44), 'tools/fig_play.py jump: start speed $FA80 (-5.5 pixels a pass), gravity $80 (0.5) a pass, '
           'right held (2 pixels a pass).', fill=DIM, font=K.font(14))
    s = 8
    ox, oy = 60, 120 + 34 * s // 1
    top = min(p[2] for p in pts)
    oy = 110 - top * s
    d.line((ox - 10, oy, ox + 70 * s, oy), fill=GRID, width=2)
    for yy in range(0, top - 1, -8):
        d.line((ox - 6, oy + yy * s, ox, oy + yy * s), fill=DIM)
        d.text((12, oy + yy * s - 9), f'{-yy:3}', fill=DIM, font=K.font(13))
    prev = None
    for p, x, y, v in pts:
        cx, cy = ox + x * s, oy + y * s
        if prev:
            d.line((prev[0], prev[1], cx, cy), fill=(250, 210, 80), width=2)
        d.rectangle((cx - 4, cy - 4, cx + 4, cy + 4), fill=(250, 210, 80))
        prev = (cx, cy)
    for p, x, y, v in pts:
        if p in (0, 5, 10, 15, 20) or p == pts[-1][0]:
            d.text((ox + x * s - 10, oy + y * s + 8), f'{p}', fill=TEXT, font=K.font(13))
    apex = min(pts, key=lambda q: q[2])
    tx = ox + 70 * s + 30 - 300
    lines = [('pass  y   speed (8.8)', TEXT)] + [
        (f'{p:3} {y:4}   ${v:04X}', (250, 210, 80) if p == apex[0] else DIM) for p, x, y, v in pts[::2]]
    yy = 110
    for t, c in lines:
        d.text((W - 260, yy), t, fill=c, font=K.font(14))
        yy += 19
    d.text((60, oy + 40), f'Up {-apex[2]} pixels at pass {apex[0]}; back on the floor at pass {pts[-1][0]}, '
           f'{pts[-1][1]} pixels on.', fill=TEXT, font=K.font(16))
    d.text((60, oy + 66), 'Numbers under the squares: passes since the jump. One pass is 2 frames in play '
           '(doc 4), so the jump lasts about', fill=DIM, font=K.font(14))
    d.text((60, oy + 86), f'{2 * pts[-1][0]} frames. A ceiling or a floor met on the way ends it at LandRick $F95D.',
           fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size, pts[-1], apex)


def cmd_course(js, png):
    import json
    rows = json.load(open(js))
    zones = {0xD55C + 7 * i: n for i, n in enumerate(
        [f'L1Z{k}' for k in range(1, 7)] + [f'L2Z{k}' for k in range(1, 8)] + [f'L3Z{k}' for k in range(1, 13)]
        + [f'L4Z{k}' for k in range(1, 10)])}
    W, H = 1050, 660
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), f'The course of a game: {os.path.basename(js).replace("course-", "").replace(".json", "")}, '
           'sampled every 20 frames', fill=TEXT, font=K.font(22))
    d.text((12, 44), f'tools/fig_play.py course {js}: the game\'s own variables read from the recording.',
           fill=DIM, font=K.font(14))
    x0, x1 = 110, W - 20
    f0, f1 = rows[0]['f'], rows[-1]['f']
    X = (lambda f: x0 + (f - f0) * (x1 - x0) / max(1, f1 - f0))
    panels = [('zone', 90), ('score', 130), ('lives', 90), ('bullets', 70), ('dynamite', 70)]
    y = 80
    boxes = {}
    for name, h in panels:
        boxes[name] = (y, y + h)
        d.rectangle((x0, y, x1, y + h), outline=GRID)
        d.text((12, y + h // 2 - 9), name, fill=TEXT, font=K.font(15))
        y += h + 14
    # deaths: Dying set
    for r in rows:
        if r['dying'] and r['type']:
            d.line((X(r['f']), 80, X(r['f']), y - 14), fill=(110, 40, 40))
    def series(name, val, top):
        ya, yb = boxes[name]
        pts = [(X(r['f']), yb - 6 - (yb - ya - 12) * min(val(r), top) / top) for r in rows]
        d.line(pts, fill=(250, 210, 80), width=2)
        d.text((x0 - 30, ya), f'{top:g}', fill=DIM, font=K.font(12))
        d.text((x0 - 30, yb - 16), '0', fill=DIM, font=K.font(12))
    series('score', lambda r: int(r['score']), 5000)
    series('lives', lambda r: r['lives'], 6)
    series('bullets', lambda r: r['bul'], 6)
    series('dynamite', lambda r: r['dyn'], 6)
    ya, yb = boxes['zone']
    names = sorted({zones.get(r['zone'], '-') for r in rows if r['zone'] in zones})
    for i, n in enumerate(names):
        yy = yb - 14 - i * (yb - ya - 20) / max(1, len(names) - 1)
        d.text((x0 - 50, yy - 8), n, fill=DIM, font=K.font(12))
    prev = None
    for r in rows:
        if r['zone'] in zones and r['type']:
            i = names.index(zones[r['zone']])
            yy = yb - 14 - i * (yb - ya - 20) / max(1, len(names) - 1)
            d.rectangle((X(r['f']) - 1, yy - 2, X(r['f']) + 1, yy + 2), fill=(120, 220, 120))
    for f in range(0, f1 + 1, 500):
        d.line((X(f), y - 14, X(f), y - 8), fill=DIM)
        d.text((X(f) - 14, y - 6), f'{f}', fill=DIM, font=K.font(12))
    d.text((x0, y + 14), 'Dark red: Rick dying ($FD68 set). Green: Rick\'s zone (gaps: no game in play). Values above '
           'the top are drawn at it.', fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size)


def cmd_zones(png):
    fig = os.path.join(CASE, 'work', 'stage2', 'fig')
    counts = {1: 6, 2: 7, 3: 12, 4: 9}
    names = {1: 'South America', 2: 'Egypt', 3: 'the castle', 4: 'the missile base'}
    rows = [(1, 2), (3,), (4,)]
    W, zw, gap = 1050, 74, 4
    sc = zw / 512
    pics = {(lv, z): Image.open(os.path.join(fig, f'zone-L{lv}Z{z}.png')).convert('RGB')
            for lv in counts for z in range(1, counts[lv] + 1)}
    heights = [max(int(pics[(lv, z)].size[1] * sc) for lv in row for z in range(1, counts[lv] + 1)) for row in rows]
    H = 84 + sum(h + 64 for h in heights) + 50
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'The four levels and their 34 zones, drawn from the level data', fill=TEXT, font=K.font(22))
    d.text((12, 44), 'tools/fig_play.py zones, from the zone pictures of tools/fig_rooms.py (src/res/levels). '
           'Each zone is 256 pixels wide.', fill=DIM, font=K.font(14))
    y = 84
    for row, h in zip(rows, heights):
        x = 12
        for lv in row:
            d.text((x, y), f'Level {lv}: {names[lv]}, {counts[lv]} zones', fill=TEXT, font=K.font(15))
            for z in range(1, counts[lv] + 1):
                im = pics[(lv, z)]
                im = im.resize((zw, max(1, int(im.size[1] * sc))), Image.LANCZOS)
                out.paste(im, (x, y + 44))
                d.text((x + 2, y + 24), f'L{lv}Z{z}', fill=DIM, font=K.font(13))
                x += zw + gap
            x += 12
        y += h + 64
    d.text((12, H - 40), 'A level starts in its first zone. White triangles: the exits. Full size, level by level: '
           'docs/img/maps/level1-4.png.', fill=DIM, font=K.font(14))
    out.save(png)
    print(png, out.size)


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == 'props':
        cmd_props(a[1])
    elif len(a) == 2 and a[0] == 'jump':
        cmd_jump(a[1])
    elif len(a) == 3 and a[0] == 'course':
        cmd_course(a[1], a[2])
    elif len(a) == 2 and a[0] == 'zones':
        cmd_zones(a[1])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

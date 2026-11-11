#!/usr/bin/env python3
"""Doc 10's figures: the scan order, objects moving pass by pass, the password records.

    python3 tools/fig_rules.py scan [--out docs/img/rules/scan-order.png]
    python3 tools/fig_rules.py passes --samples F.jsonl --cave N --frames A-B --cols C0-C1 --rows R0-R1
                              --title TEXT --out docs/img/rules/NAME.png [--per-row 8]
    python3 tools/fig_rules.py statelog --cave N --frames A-B --cols C0-C1 --rows R0-R1 --title TEXT --out ...
                              [--cell PIXELS] [--label CELL,CELL]   (both for passes too)
    python3 tools/fig_rules.py passwords [--out docs/img/rules/passwords.png]
    python3 tools/fig_rules.py census [--out docs/img/rules/census.png]

`passes` draws a window of the cave grid from TTD memory_at samples of `$FD7A-$FFFF` (JSON lines {"frame", "hex"},
work/docs/esC/sample.py), one panel for each sample whose grid differs from the one before: the state at the start of
that frame. `statelog` does the same from an RZX state log work/stage1/rzx/earthNN.ins.state.bin (`$FD7E-$FFFF`
after each RZX frame, 642 bytes a frame; the RZX's own play, not a recording of ours). A cell that changed is framed:
yellow when it got an object, red when it got the vacated mark `$20` (drawn hatched), grey when it was emptied.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import fig_caves  # noqa: E402
import kitlib as K  # noqa: E402
import res_formats  # noqa: E402

BG, FG, DIM, GRID = (22, 22, 28), (236, 236, 236), (160, 160, 170), (70, 70, 84)
YEL, RED, GREY, BLUE = (255, 230, 60), (255, 70, 70), (150, 150, 150), (120, 200, 255)


def rng(text):
    a, _, b = text.partition('-')
    return int(a), int(b or a)


def scan(out):
    f, fb, fs = K.font(15), K.font(17), K.font(13)
    cw, ch, x0, y0 = 30, 24, 70, 80
    img = Image.new('RGB', (1050, y0 + 20 * ch + 140), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'The order of ScanCells $8075: row 18 to row 0, each row from column 29 to column 0', font=fb,
           fill=FG)
    d.text((14, 36), 'Each cell is numbered by its turn (1 = the first cell visited). Row 19 (dark) is never a source:',
           font=fs, fill=DIM)
    d.text((14, 54), 'it is only the cell below of row 18.', font=fs, fill=DIM)
    for r in range(20):
        d.text((x0 - 52, y0 + r * ch + 4), f'row {r:2d}', font=fs, fill=DIM)
        for c in range(30):
            x, y = x0 + c * cw, y0 + r * ch
            if r == 19:
                d.rectangle((x, y, x + cw - 2, y + ch - 2), fill=(50, 30, 30))
                continue
            k = (18 - r) * 30 + (29 - c)  # 0 first
            t = k / 569
            col = (int(40 + 180 * (1 - t)), int(60 + 100 * t), int(90 + 140 * t))
            d.rectangle((x, y, x + cw - 2, y + ch - 2), fill=col)
            if c in (29, 0) or (r in (18, 0) and c % 5 == 4):
                d.text((x + 2, y + 5), f'{k + 1}', font=K.font(11), fill=(0, 0, 0))
    for c in range(0, 30, 5):
        d.text((x0 + c * cw + 4, y0 + 20 * ch + 4), f'c{c}', font=fs, fill=DIM)
    # the direction of a row, in the margin right of the grid
    for r in (18, 17):
        y = y0 + r * ch + ch // 2
        xr = x0 + 30 * cw + 8
        d.line((xr + 50, y, xr + 6, y), fill=FG, width=2)
        d.polygon([(xr, y), (xr + 10, y - 5), (xr + 10, y + 5)], fill=FG)
    d.text((x0 + 30 * cw + 8, y0 + 16 * ch), 'start', font=fs, fill=FG)
    yb = y0 + 20 * ch + 30
    lines = [
        'An object moves down into a row the scan has already passed: it moves at most one row a pass.',
        'An object rolling left moves into the next cell to be visited; the 20 written under that cell stops it',
        'from falling again in the same pass.',
        'The cell an object leaves gets 20, so the object above it waits a pass: a falling column opens one-cell gaps.',
        'python3 tools/fig_rules.py scan',
    ]
    for i, t in enumerate(lines):
        d.text((14, yb + i * 20), t, font=fs, fill=DIM if i == len(lines) - 1 else FG)
    img.save(out)


def grids_from_samples(path, lo, hi):
    out = []
    for ln in open(path):
        s = json.loads(ln)
        if lo <= s['frame'] <= hi:
            m = bytes.fromhex(s['hex'])
            out.append((s['frame'], m[0xFDA8 - 0xFD7A:0xFDA8 - 0xFD7A + 600], m[0xFD9C - 0xFD7A] | m[0xFD9D - 0xFD7A] << 8))
    return out


def grids_from_statelog(cave, lo, hi):
    data = open(os.path.join(CASE, 'work', 'stage1', 'rzx', f'earth{cave:02d}.ins.state.bin'), 'rb').read()
    out = []
    for fr in range(lo, min(hi, len(data) // 642 - 1) + 1):
        r = data[fr * 642:(fr + 1) * 642]
        out.append((fr, r[0xFDA8 - 0xFD7E:0xFDA8 - 0xFD7E + 600], r[0xFD9C - 0xFD7E] | r[0xFD9D - 0xFD7E] << 8))
    return out


def passes(out, grids, cave, cols, rows, title, per_row, source, cell=0, labels=()):
    params = res_formats.read_caves()[cave - 1][0]
    m = fig_caves.cave_setup(fig_caves.resource_memory(), params)
    cache = {}

    def gfx(v):
        if v not in cache:
            cache[v] = fig_caves.graphic(m, v & 0x1F)[0]
        return cache[v]

    panels, prev = [], None
    for fr, g, pi in grids:
        if prev is None or g != prev:
            panels.append((fr, g, prev, pi))
        prev = g
    c0, c1 = cols
    r0, r1 = rows
    nc, nr = c1 - c0 + 1, r1 - r0 + 1
    cell = cell or (16 if nc * 16 * per_row < 960 else 12)
    pw, ph = nc * cell, nr * cell
    fb, fs = K.font(17), K.font(13)
    gap = 14
    nrows = (len(panels) + per_row - 1) // per_row
    width = max(1050, per_row * (pw + gap) + 28)
    img = Image.new('RGB', (width, 76 + nrows * (ph + 34) + 74), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), title, font=fb, fill=FG)
    d.text((14, 36), f'cave {cave}, columns {c0}-{c1}, rows {r0}-{r1}; one panel each time the grid changed, labelled '
           'with its frame', font=fs, fill=DIM)
    for i, (fr, g, pg, pi) in enumerate(panels):
        x0 = 14 + (i % per_row) * (pw + gap)
        y0 = 64 + (i // per_row) * (ph + 34)
        d.text((x0, y0), f'{fr}', font=fs, fill=FG)
        y0 += 18
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                v = g[r * 30 + c]
                x, y = x0 + (c - c0) * cell, y0 + (r - r0) * cell
                t = gfx(v) if v != 0x20 else None
                if t:
                    img.paste(t.resize((cell, cell), Image.NEAREST), (x, y))
                if v == 0x20:
                    for k in range(0, cell, 4):
                        d.line((x + k, y, x, y + k), fill=RED)
                if pg is not None and pg[r * 30 + c] != v:
                    col = RED if v == 0x20 else (GREY if v == 0 else YEL)
                    d.rectangle((x, y, x + cell - 1, y + cell - 1), outline=col, width=2)
                if i == 0 and r * 30 + c in labels:
                    tx = f'{r * 30 + c}'
                    d.rectangle((x + 2, y + 2, x + 4 + 7 * len(tx), y + 15), fill=BG)
                    d.text((x + 3, y + 1), tx, font=K.font(11), fill=FG)
    yb = 64 + nrows * (ph + 34) + 4
    for x, (col, t) in zip((14, 330, 620), ((YEL, 'got an object (or the player)'), (RED, 'got 20, the vacated mark'),
                                           (GREY, 'emptied (20 cleared, or left)'))):
        d.rectangle((x, yb + 2, x + 14, yb + 16), outline=col, width=2)
        d.text((x + 22, yb), t, font=fs, fill=FG)
    d.text((14, yb + 26), source, font=fs, fill=DIM)
    img.save(out)


def passwords(out):
    image = open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read()
    syms = res_formats.symbols()[0]
    labels = sorted((a, n) for a, n in syms.items() if 0x9700 <= a < 0x9B00)
    f, fb, fs = K.font(14), K.font(17), K.font(12)
    rh = 19
    img = Image.new('RGB', (1050, 70 + 50 * rh + 60), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'The 50 records FindPassword $8E91 compares: 32 cave names, then 18 records over code and data',
           font=fb, fill=FG)
    d.text((14, 36), 'record, address, the 20 bytes (letters as text, other bytes in hex), what lies there', font=fs,
           fill=DIM)
    ok = set(b' ABCDEFGHIJKLMNOPQRSTUVWXYZ')
    for r in range(50):
        a = 0x9700 + 20 * r
        rec = image[a:a + 20]
        y = 60 + r * rh
        col = FG if r < 32 else (GREY if all(b == 0 for b in rec) else RED)
        d.text((14, y), f'{r + 1:2d}  ${a:04X}', font=f, fill=DIM)
        if r < 32:
            d.text((130, y), '"' + rec.decode('latin-1') + '"', font=f, fill=FG)
            d.text((420, y), f'cave {r + 1}: a match starts here', font=fs, fill=BLUE)
        else:
            d.text((130, y), ' '.join(f'{b:02X}' for b in rec), font=fs, fill=col)
            owners = [n for la, n in labels if la < a + 20 and la >= a - 200]
            here = [n for la, n in labels if la <= a][-1:]
            names = sorted(set(here + [n for la, n in labels if a <= la < a + 20]), key=lambda n: syms_rev(syms, n))
            typable = all(b in ok for b in rec)
            names = names[:2] + (['...'] if len(names) > 2 else [])
            d.text((560, y), ', '.join(names) + ('' if typable else '  (untypable)'), font=fs, fill=col)
    d.text((14, 66 + 50 * rh), 'EnterPassword stores only space and A-Z, so records 33-50 can never match.   '
           'python3 tools/fig_rules.py passwords', font=fs, fill=DIM)
    img.save(out)


def census(out):
    caves = res_formats.read_caves()
    names = [ln.strip()[1:-1].strip() for ln in open(os.path.join(CASE, 'src', 'res', 'texts', 'cave-names.txt'))
             if ln.startswith('"')]
    cols = [('boulder', 2), ('gems', 7), ('needed', 'need'), ('points', 'val'), ('jelly', 8), ('field', 9),
            ('arrow', 10), ('switch', 11), ('potion', 12), ('telep.', 13), ('bubble', 14), ('fire', 15),
            ('RZX fr.', 'rzx')]
    rows = []
    for n, (prm, cells) in enumerate(caves, 1):
        log = os.path.join(CASE, 'work', 'stage1', 'rzx', f'earth{n:02d}.ins.state.bin')
        frames = os.path.getsize(log) // 642 if os.path.exists(log) else 0
        r = []
        for _, k in cols:
            r.append(cells.count(k) if isinstance(k, int) else
                     {'need': prm['gems_needed'], 'val': prm['gem_value'], 'rzx': frames}[k])
        rows.append(r)
    mx = [max(r[i] for r in rows) or 1 for i in range(len(cols))]
    fb, fs, f = K.font(17), K.font(12), K.font(13)
    rh, x0, cw = 22, 250, 60
    img = Image.new('RGB', (1050, 96 + 32 * rh + 70), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'What each cave holds: the cells of its record, its two numbers and the RZX run that solved it',
           font=fb, fill=FG)
    d.text((14, 36), 'Shade = the value against the column maximum. RZX frames: the length of the RZX player\'s run '
           '(other players\' play), not ours.', font=fs, fill=DIM)
    for i, (t, _) in enumerate(cols):
        d.text((x0 + i * cw + 4, 66), t, font=fs, fill=DIM)
    for n, r in enumerate(rows):
        y = 86 + n * rh
        d.text((14, y + 3), f'{n + 1:2d} {names[n][:26]}', font=f, fill=FG)
        for i, v in enumerate(r):
            t = v / mx[i]
            col = (int(30 + 200 * t), int(40 + 90 * t), int(60 + 20 * (1 - t)))
            d.rectangle((x0 + i * cw, y, x0 + (i + 1) * cw - 3, y + rh - 3), fill=col if v else (34, 34, 42))
            d.text((x0 + i * cw + 6, y + 3), str(v) if v else '', font=f, fill=(0, 0, 0) if t > 0.55 else FG)
    yb = 90 + 32 * rh
    d.text((14, yb), 'Cells counted in src/res/caves/caves.txt; RZX frames from work/stage1/rzx/earthNN.ins.state.bin.',
           font=fs, fill=DIM)
    d.text((14, yb + 20), 'python3 tools/fig_rules.py census', font=fs, fill=DIM)
    img.save(out)


def syms_rev(syms, name):
    for a, n in syms.items():
        if n == name:
            return a
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('scan', 'passes', 'statelog', 'passwords', 'census'))
    ap.add_argument('--out')
    ap.add_argument('--samples')
    ap.add_argument('--cave', type=int, default=1)
    ap.add_argument('--frames', default='0-0')
    ap.add_argument('--cols', default='0-29')
    ap.add_argument('--rows', default='0-19')
    ap.add_argument('--title', default='')
    ap.add_argument('--per-row', type=int, default=8)
    ap.add_argument('--source', default='')
    ap.add_argument('--cell', type=int, default=0, help='pixels a cell (default 16, or 12 for wide windows)')
    ap.add_argument('--label', default='', help='cells to number in the first panel, comma-separated')
    a = ap.parse_args()
    d = os.path.join(CASE, 'docs', 'img', 'rules')
    os.makedirs(d, exist_ok=True)
    if a.what == 'scan':
        scan(a.out or os.path.join(d, 'scan-order.png'))
    elif a.what == 'census':
        census(a.out or os.path.join(d, 'census.png'))
    elif a.what == 'passwords':
        passwords(a.out or os.path.join(d, 'passwords.png'))
    else:
        lo, hi = rng(a.frames)
        grids = grids_from_samples(a.samples, lo, hi) if a.what == 'passes' else grids_from_statelog(a.cave, lo, hi)
        cmd = 'python3 tools/fig_rules.py ' + ' '.join(sys.argv[1:])
        passes(a.out, grids, a.cave, rng(a.cols), rng(a.rows), a.title, a.per_row, a.source or cmd, a.cell,
               {int(x) for x in a.label.split(',') if x.strip()})


if __name__ == '__main__':
    main()

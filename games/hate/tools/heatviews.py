#!/usr/bin/env python3
"""Heatmaps of H.A.T.E. shaped like the data they show, from unreal-ng L1 builds (l1.json, byte_counts):

    records   the object list $C000-$C26F as a table, one row a 16-byte record, one column a field
              (docs/07-objects.md): reads and writes per byte
    screen    the writes into $4000-$5AFF drawn where they land on the screen: bitmap bytes as 8 x 1 pixels,
              attributes as 8 x 8 cells (docs/06-rendering.md, docs/08-hud-and-text.md)
    coverage  the code executed in one build against another: bytes run in both, only in the first, only in the
              second (docs/10-gameplay-logic.md)
    routines  the routines by their own t-states (L1 profile), the top N as bars (docs/04-game-loop.md)
    modules   which module's code reads and writes which memory: one row a module of src/game, one column a
              256-byte page, the shade the bytes its routines touch there (L1 profile ranges); below, the screen
              writes of every module that draws, in the screen's geometry (docs/02-architecture.md)

    python3 heatviews.py records work/p2/l1.json docs/img/heat-records.png
    python3 heatviews.py screen work/p2/l1.json docs/img/heat-screen.png
    python3 heatviews.py coverage work/p2/l1.json docs/img/heat-coverage.png --other work/m1/l1.json
    python3 heatviews.py routines work/p2/l1.json docs/img/routines-time.png [--top 24]
    python3 heatviews.py modules work/p2/l1.json docs/img/heat-modules.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import heatmap  # noqa: E402

FIELDS = ['+0 type', '+1 pos', '+2 pos', '+3 across', '+4 height', '+5 dir', '+6 speed', '+7 behav.', '+8 expl.',
          '+9 strip', '+A strip', '+B strip', '+C motion', '+D', '+E motion', '+F fire']
SLOTS = [(0xC000, 'player'), (0xC010, 'shot 1'), (0xC020, 'shot 2'), (0xC030, 'shot 3'), (0xC040, 'shot 4'),
         (0xC050, 'shot 5'), (0xC060, 'pod 1'), (0xC070, 'pod 2'), (0xC080, 'pod 3'), (0xC090, 'pod 4'),
         (0xC0A0, 'parked vehicle')] + \
        [(0xC0B0 + 16 * i, f'course object {i + 1}') for i in range(16)] + \
        [(0xC1B0 + 16 * i, f'launched {i + 1}') for i in range(6)] + \
        [(0xC210 + 16 * i, f'enemy shot {i + 1}') for i in range(5)] + [(0xC260, 'vehicle before')]



def routine_names():
    """The code entries of src/game/game.ann: {'$ADDR': Name}"""
    import re
    names = {}
    path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'src', 'game', 'game.ann')
    for line in open(path):
        m = re.match(r'\$([0-9A-F]{4})\s+c\s+(\w+)', line)
        if m:
            names['$' + m.group(1)] = m.group(2)
    return names


NAMES = routine_names()


def font(size):
    for path in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def records(l1, out):
    _, reads, writes, _, replay = heatmap.load(l1, heatmap.BASES_48K)
    cell, label_w, top = 26, 130, 54
    f, small = font(12), font(10)
    width = label_w + 2 * 16 * cell + 40
    img = Image.new('RGB', (width, top + len(SLOTS) * cell + 30), (24, 24, 30))
    draw = ImageDraw.Draw(img)
    lo, hi = 0xC000, 0xC26F
    for n, (values, title) in enumerate(((reads, 'reads'), (writes, 'writes'))):
        norm, peak = heatmap.scale(values, lo, hi)
        x0 = label_w + n * (16 * cell + 20)
        draw.text((x0, 6), f'{title} (log, peak {peak:,})', fill=(230, 230, 210), font=f)
        for k, name in enumerate(FIELDS):
            draw.text((x0 + k * cell + 3, 26 + (k % 2) * 12), name.split()[0], fill=(180, 180, 170), font=small)
        for row, (base, _) in enumerate(SLOTS):
            for k in range(16):
                y = top + row * cell
                draw.rectangle((x0 + k * cell, y, x0 + (k + 1) * cell - 2, y + cell - 2),
                               fill=heatmap.heat(norm(base + k)))
    for row, (base, name) in enumerate(SLOTS):
        draw.text((6, top + row * cell + 6), f'${base:04X} {name}', fill=(220, 220, 200), font=small)
    draw.text((6, top + len(SLOTS) * cell + 8),
              f'frames {replay["first_frame"]}-{replay["last_frame"]}; fields: ' +
              ', '.join(FIELDS[k] for k in (0, 1, 3, 4, 5, 6, 7, 8, 15)), fill=(170, 170, 160), font=small)
    img.save(out)


def screen(l1, out):
    _, _, writes, _, replay = heatmap.load(l1, heatmap.BASES_48K)
    s = 3
    f = font(12)
    norm_b, peak_b = heatmap.scale(writes, 0x4000, 0x57FF)
    norm_a, peak_a = heatmap.scale(writes, 0x5800, 0x5AFF)
    img = Image.new('RGB', (2 * 256 * s + 48, 192 * s + 44), (24, 24, 30))
    bitmap = Image.new('RGB', (256 * s, 192 * s), (12, 12, 16))
    attrs = Image.new('RGB', (256 * s, 192 * s), (12, 12, 16))
    db, da = ImageDraw.Draw(bitmap), ImageDraw.Draw(attrs)
    for a in range(0x4000, 0x5800):
        y = ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)
        x = (a & 31) * 8
        if writes[a]:
            db.rectangle((x * s, y * s, (x + 8) * s - 1, (y + 1) * s - 1), fill=heatmap.heat(norm_b(a)))
    for a in range(0x5800, 0x5B00):
        x, y = ((a - 0x5800) & 31) * 8, ((a - 0x5800) >> 5) * 8
        if writes[a]:
            da.rectangle((x * s, y * s, (x + 8) * s - 2, (y + 8) * s - 2), fill=heatmap.heat(norm_a(a)))
    img.paste(bitmap, (16, 32))
    img.paste(attrs, (256 * s + 32, 32))
    draw = ImageDraw.Draw(img)
    draw.text((16, 8), f'bitmap writes $4000-$57FF (log, peak {peak_b:,})', fill=(230, 230, 210), font=f)
    draw.text((256 * s + 32, 8), f'attribute writes $5800-$5AFF (log, peak {peak_a:,})', fill=(230, 230, 210),
              font=f)
    draw.text((16, 192 * s + 36 - 4), f'frames {replay["first_frame"]}-{replay["last_frame"]}',
              fill=(170, 170, 160), font=font(10))
    img.save(out)


def coverage(l1, other, out, lo, hi):
    ex_a = heatmap.load(l1, heatmap.BASES_48K)[0]
    ex_b = heatmap.load(other, heatmap.BASES_48K)[0]
    both, only_a, only_b = (90, 90, 100), (250, 170, 40), (60, 140, 230)
    counts = [0, 0, 0]

    def colour(a):
        if ex_a[a] and ex_b[a]:
            counts[0] += 1
            return both
        if ex_a[a]:
            counts[1] += 1
            return only_a
        if ex_b[a]:
            counts[2] += 1
            return only_b
        return (12, 12, 16)

    cell = 3
    grid = heatmap.panel(lo, hi, cell, colour)
    f = font(12)
    img = Image.new('RGB', (grid.width + 300, grid.height + 40), (24, 24, 30))
    img.paste(grid, (16, 30))
    draw = ImageDraw.Draw(img)
    draw.text((16, 8), f'executed bytes ${lo:04X}-${hi:04X}, one row = 256 bytes', fill=(230, 230, 210), font=f)
    x = grid.width + 90
    for n, (c, text) in enumerate(((both, f'both: {counts[0]:,}'),
                                   (only_a, f'only {os.path.basename(os.path.dirname(l1))}: {counts[1]:,}'),
                                   (only_b, f'only {os.path.basename(os.path.dirname(other))}: {counts[2]:,}'))):
        draw.rectangle((x, 40 + n * 22, x + 14, 54 + n * 22), fill=c)
        draw.text((x + 22, 40 + n * 22), text, fill=(220, 220, 200), font=f)
    first = (lo >> 8) << 8
    for page in range(first, hi + 1, 0x800):
        if page >= lo:
            draw.text((grid.width + 24, 30 + ((page - lo) >> 8) * cell - 5), f'${page:04X}', fill=(160, 160, 150), font=font(10))
    img.save(out)
    print(f'both {counts[0]} only-first {counts[1]} only-second {counts[2]}')


def routines(l1, out, top):
    import json
    doc = json.load(open(l1))
    rows = sorted(((r['profile']['tstates'], r['entry'], r['profile']['entries']) for r in doc['routines']),
                  reverse=True)[:top]
    total = doc['replay']['tstates']
    f, small = font(12), font(11)
    bar_w, row_h, label_w = 560, 22, 250
    img = Image.new('RGB', (label_w + bar_w + 190, 40 + row_h * len(rows)), (24, 24, 30))
    draw = ImageDraw.Draw(img)
    draw.text((16, 8), f'own t-states per routine, {total:,} in all over frames '
                       f'{doc["replay"]["first_frame"]}-{doc["replay"]["last_frame"]}', fill=(230, 230, 210), font=f)
    peak = rows[0][0] or 1
    for n, (t, entry, entries) in enumerate(rows):
        y = 34 + n * row_h
        draw.text((16, y + 3), f'{entry} {NAMES.get(entry, "")}', fill=(220, 220, 200), font=small)
        draw.rectangle((label_w, y + 2, label_w + int(bar_w * t / peak), y + row_h - 4),
                       fill=heatmap.heat(0.35 + 0.65 * t / peak))
        draw.text((label_w + int(bar_w * t / peak) + 8, y + 3), f'{100 * t / total:.1f} %  ({entries:,} calls)',
                  fill=(200, 200, 190), font=small)
    img.save(out)


def module_ranges():
    """[(start, name)] of the @module lines of src/game/game.ann, in address order"""
    case = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sys.path.insert(0, os.path.join(case, '..', '..', 'kit'))
    import mkgame
    mkgame.load_case(case)
    ann = mkgame.Annotations(os.path.join(case, 'src', 'game', 'game.ann'))
    return sorted(ann.modules)


def modules(l1, out):
    import bisect
    import json
    doc = json.load(open(l1))
    mods = module_ranges()
    starts = [m[0] for m in mods]

    def module_of(a):
        i = bisect.bisect_right(starts, a) - 1
        return mods[i][1] if i >= 0 else None

    touched = {}  # module -> {'reads': set(addr), 'writes': set(addr)}
    for r in doc['routines']:
        if r['page'] not in (0, 2, 5):
            continue
        m = module_of(int(r['entry'][1:], 16))
        if m is None:
            continue
        t = touched.setdefault(m, {'reads': set(), 'writes': set()})
        for kind in ('reads', 'writes'):
            for x in r['profile'][kind]:
                if x['page'] in (0, 2, 5):
                    t[kind].update(range(int(x['from'][1:], 16), int(x['to'][1:], 16) + 1))
    rows = [m for _, m in mods if m in touched]
    cw, ch, label_w, top = 4, 18, 96, 58
    f, small = font(12), font(10)
    panel_w = 192 * cw
    width = label_w + 2 * panel_w + 30
    drawing = [m for m in rows if any(0x4000 <= a < 0x5B00 for a in touched[m]['writes'])]
    inset_scale = 1
    sample = heatmap.screen_view(lambda a: (0, 0, 0), inset_scale)
    per_row = max(1, (width - 6) // (sample.width + 14))
    inset_rows = (len(drawing) + per_row - 1) // per_row
    height = top + len(rows) * ch + 52 + inset_rows * (sample.height + 20)
    img = Image.new('RGB', (width, height), (24, 24, 30))
    draw = ImageDraw.Draw(img)
    palette = [(90, 120, 200), (200, 120, 80), (110, 180, 110), (190, 170, 80), (170, 100, 180), (90, 170, 180)]
    for n, kind in enumerate(('reads', 'writes')):
        x0 = label_w + n * (panel_w + 20)
        draw.text((x0, 4), f'{kind}: bytes touched per 256-byte page (log)', fill=(230, 230, 210), font=f)
        # the module that owns each page, as a coloured band, and the address ticks
        for page in range(0x40, 0x100):
            a = page << 8
            owner = module_of(a) if a >= 0x5FB4 else None
            colour = (60, 60, 70) if owner is None else palette[[m for _, m in mods].index(owner) % len(palette)]
            if 0x40 <= page < 0x5B:
                colour = (120, 120, 120)
            x = x0 + (page - 0x40) * cw
            draw.rectangle((x, 40, x + cw - 1, 50), fill=colour)
        for page in range(0x40, 0x101, 0x20):
            x = x0 + (page - 0x40) * cw
            draw.line((x, 36, x, 52), fill=(160, 160, 150))
            draw.text((x + 2, 22), f'${page << 8:04X}' if page < 0x100 else '', fill=(170, 170, 160), font=small)
        peak = max(len([a for a in touched[m][kind] if a >> 8 == p]) for m in rows for p in range(0x40, 0x100)) or 1
        for row, m in enumerate(rows):
            counts = [0] * 256
            for a in touched[m][kind]:
                counts[a >> 8] += 1
            y = top + row * ch
            for page in range(0x40, 0x100):
                if counts[page]:
                    import math
                    v = math.log1p(counts[page]) / math.log1p(256)
                    x = x0 + (page - 0x40) * cw
                    draw.rectangle((x, y, x + cw - 1, y + ch - 2), fill=heatmap.heat(v))
            draw.line((x0, y + ch - 1, x0 + panel_w, y + ch - 1), fill=(40, 40, 50))
    for row, m in enumerate(rows):
        draw.text((6, top + row * ch + 3), m, fill=(220, 220, 200), font=small)
    y = top + len(rows) * ch + 8
    draw.text((6, y), f'frames {doc["replay"]["first_frame"]}-{doc["replay"]["last_frame"]}; band: the module that '
              'owns the page (grey: the screen, dark: below the image); a full cell = all 256 bytes',
              fill=(170, 170, 160), font=small)
    # Picture in picture: each drawing module's screen writes where they land on the screen
    y += 22
    draw.text((6, y), 'screen writes per module, in the screen\'s geometry (bitmap, then attributes)',
              fill=(230, 230, 210), font=f)
    for k, m in enumerate(drawing):
        w = touched[m]['writes']
        view = heatmap.screen_view(lambda a: (240, 190, 70) if a in w else (30, 30, 38), inset_scale)
        x = 6 + (k % per_row) * (view.width + 14)
        yy = y + 18 + (k // per_row) * (view.height + 20)
        img.paste(view, (x, yy))
        draw.text((x, yy + view.height + 2), m, fill=(220, 220, 200), font=small)
    img.save(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('view', choices=['records', 'screen', 'coverage', 'routines', 'modules'])
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--other', help='coverage: the build to compare with')
    p.add_argument('--from', dest='lo', default='5FB4')
    p.add_argument('--to', dest='hi', default='FFFF')
    p.add_argument('--top', type=int, default=24)
    args = p.parse_args()
    if args.view == 'records':
        records(args.l1, args.png)
    elif args.view == 'screen':
        screen(args.l1, args.png)
    elif args.view == 'coverage':
        coverage(args.l1, args.other, args.png, int(args.lo, 16), int(args.hi, 16))
    elif args.view == 'modules':
        modules(args.l1, args.png)
    else:
        routines(args.l1, args.png, args.top)


if __name__ == '__main__':
    main()

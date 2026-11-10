#!/usr/bin/env python3
"""The figures of docs 07 (the city's data) and 10 (the simulation), 1050 px wide.

Every figure is drawn from the resources (src/res), the stage 2 states and the samples of own instances
(work/docs/scC/*.jsonl, written by work/docs/scC/sample.py: one JSON line per frame, each range as hex text, the
sample of frame N is the memory at the start of frame N).

    python3 tools/fig_sim.py cells     --out docs/img/sim/cells.png
    python3 tools/fig_sim.py building  --state work/stage2/ceiling-end.szx --out docs/img/sim/building.png
    python3 tools/fig_sim.py zone      --samples work/docs/scC/city-vars.jsonl --at 45,32 --out docs/img/sim/zone.png
    python3 tools/fig_sim.py arrays    --state work/stage1/rec/metro/end.szx --label 'metro end.szx, frame 96 503' \
                                       --out docs/img/sim/arrays.png
    python3 tools/fig_sim.py course    --samples work/docs/scC/city-vars.jsonl --out docs/img/sim/course.png
    python3 tools/fig_sim.py save      --tap work/stage1/rec/menus/town.tap --out docs/img/sim/save.png
    python3 tools/fig_sim.py score     --out docs/img/sim/score.png
    python3 tools/fig_sim.py kernels   --out docs/img/sim/kernels.png
    python3 tools/fig_sim.py demand    --samples work/docs/scC/city-vars.jsonl --out docs/img/sim/demand.png
    python3 tools/fig_sim.py ceiling   --log work/stage2/ceiling.log --out docs/img/sim/ceiling.png
    python3 tools/fig_sim.py landscape --gene 3 --out docs/img/sim/landscape.png
    python3 tools/fig_sim.py disasters --samples work/docs/scC/dis-vars.jsonl --out docs/img/sim/disasters.png
    python3 tools/fig_sim.py funding   --out docs/img/sim/funding.png
    python3 tools/fig_sim.py random    --out docs/img/sim/random.png
"""
import argparse
import csv
import json
import os
import re
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_city  # noqa: E402
import landscape  # noqa: E402
import res_formats as RF  # noqa: E402

TABLES = os.path.join(RF.RES, 'tables')
W = 10.5                     # inches at 100 dpi: 1050 px
plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'legend.fontsize': 10, 'xtick.labelsize': 10,
                     'ytick.labelsize': 10, 'font.family': 'DejaVu Sans', 'text.parse_math': False})


def table(name):
    rows = [r for r in csv.reader(open(os.path.join(TABLES, name + '.csv'))) if r and not r[0].startswith('#')]
    return rows[1:]


def num(t):
    t = t.strip()
    if t.startswith('%'):
        return int(t[1:], 2)
    if t.startswith('$'):
        return int(t[1:], 16)
    return int(t)


def samples(path):
    return [json.loads(line) for line in open(path)]


def get(d, addr, n=1):
    for k, v in d.items():
        if k == 'frame':
            continue
        lo = int(k, 16)
        if lo <= addr and addr + n <= lo + len(v) // 2:
            return bytes.fromhex(v[(addr - lo) * 2:(addr - lo + n) * 2])
    raise KeyError('%04X' % addr)


def u(d, addr, n=2):
    return int.from_bytes(get(d, addr, n), 'little')


def s16(d, addr):
    v = u(d, addr)
    return v - 0x10000 if v & 0x8000 else v


def save(fig, out):
    os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
    fig.savefig(out, dpi=100)
    plt.close(fig)
    from PIL import Image
    print('fig_sim: %s %s' % (out, Image.open(out).size))


def city_rgb(city):
    return np.asarray(fig_city.draw(city))


def tile_rgb(n, sheet='Cells.png'):
    t, a = fig_city.tiles(sheet)
    img = np.zeros((8, 8, 3), np.uint8)
    attr = a[n]
    for y in range(8):
        b = t[n * 8 + y]
        for x in range(8):
            ink = (b >> (7 - x)) & 1
            img[y, x] = RF.zx_rgb(attr & 7 if ink else (attr >> 3) & 7, (attr >> 6) & 1)
    return img


CELL_NAMES = {0: 'water', 1: 'coast', 2: 'land', 3: 'coast', 4: 'coast', 5: 'coast', 6: 'trees',
              0x12: 'road brdg', 0x13: 'road brdg', 0x1F: 'rail brdg', 0x20: 'rail brdg',
              0x34: 'traffic', 0x35: 'traffic', 0x36: 'traffic', 0x37: 'traffic', 0x38: 'park', 0x39: 'park',
              0x3A: 'rubble', 0x3B: 'blank', 0x44: 'flood', 0x45: 'fire', 0x46: 'rubble an', 0x47: 'rubble an',
              0x48: 'rubble an', 0x51: 'R centre', 0x52: 'C centre', 0x53: 'I centre', 0x54: 'R unpow',
              0x55: 'C unpow', 0x56: 'I unpow', 0x57: 'not placed', 0x58: 'not placed', 0x59: 'radiation'}
BITS = [(0, 'not reshaped', '#999999'), (1, 'rail', '#8c564b'), (2, 'road', '#1f77b4'),
        (3, 'conducts', '#ffbf00'), (4, 'zone', '#2ca02c'), (6, 'developed', '#9467bd'),
        (7, 'flammable', '#d62728')]


def cell_name(code, flags):
    if code in CELL_NAMES:
        return CELL_NAMES[code]
    if 0x3C <= code <= 0x43:
        return 'house %d' % (code - 0x3B)
    if 0x49 <= code <= 0x50:
        return 'frame %d' % (code - 0x49)
    road, rail, power = flags & 4, flags & 2, flags & 8
    if road and rail:
        return 'road+rail'
    if road and power:
        return 'road+pow'
    if rail and power:
        return 'rail+pow'
    if road:
        return 'road'
    if rail:
        return 'rail'
    if power:
        return 'power ln'
    return '-'


def fig_cells(a):
    rows = [(num(c), num(f)) for c, f in table('CellFlags')]
    cols, nrows = 12, 8
    fig = plt.figure(figsize=(W, 9.6))
    fig.suptitle('The 90 cell codes $00-$59 that CellFlags covers: tile (Cells.png), code, name, flag bits', y=0.985)
    cw, ch = 1.0 / cols, 0.86 / nrows
    for i, (code, flags) in enumerate(rows):
        c, r = i % cols, i // cols
        x0, y0 = c * cw, 0.93 - (r + 1) * ch
        ax = fig.add_axes([x0 + cw * 0.28, y0 + ch * 0.36, cw * 0.44, ch * 0.44])
        ax.imshow(tile_rgb(code), interpolation='nearest')
        ax.set_xticks([])
        ax.set_yticks([])
        fig.text(x0 + cw / 2, y0 + ch * 0.86, '$%02X' % code, ha='center', va='center', fontsize=11,
                 fontweight='bold')
        fig.text(x0 + cw / 2, y0 + ch * 0.24, cell_name(code, flags), ha='center', va='center', fontsize=10)
        for k, (bit, _, colour) in enumerate(BITS):
            on = flags >> bit & 1
            fig.patches.append(plt.Rectangle((x0 + cw * (0.12 + k * 0.11), y0 + ch * 0.04), cw * 0.09, ch * 0.09,
                                             transform=fig.transFigure, facecolor=colour if on else 'white',
                                             edgecolor='#666666', linewidth=0.6))
    for k, (bit, name, colour) in enumerate(BITS):
        x = 0.02 + k * 0.14
        fig.patches.append(plt.Rectangle((x, 0.02), 0.014, 0.016, transform=fig.transFigure, facecolor=colour,
                                         edgecolor='#666666'))
        fig.text(x + 0.02, 0.028, 'bit %d %s' % (bit, name), va='center', fontsize=10)
    save(fig, a.out)


def draw_bytes(ax, grid, title):
    h, w = len(grid), len(grid[0])
    colours = {'top': '#ffd27f', 'row': '#ffe9bf', 'num': '#bfe0ff', 'fill': '#e8e8e8', 'cell': '#d9f2d0'}
    for r, row in enumerate(grid):
        for c, (v, kind) in enumerate(row):
            ax.add_patch(plt.Rectangle((c, h - 1 - r), 1, 1, facecolor=colours[kind], edgecolor='#444444'))
            ax.text(c + 0.5, h - 0.5 - r, '%02X' % v, ha='center', va='center', fontsize=12, family='monospace')
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)
    ax.set_aspect('equal')
    ax.axis('off')
    ax.set_title(title, fontsize=11)


def classify(row):
    out = []
    for k, v in enumerate(row):
        if v < 0x80:
            out.append((v, 'cell'))
        elif v < 0xC0:
            out.append((v, 'top' if v & 0x20 else 'row'))
        elif k in (1, 2) and row[0] >= 0x80 and row[0] < 0xC0:
            out.append((v, 'num'))
        else:
            out.append((v, 'fill'))
    return out


def fig_building(a):
    import szx
    mem = szx.read(a.state)[0]
    city = bytes(mem[0xC450:0xC450 + 9216])
    rgb = city_rgb(city)
    cases = [(37, 58, 4, 'nuclear plant at (row 37, column 58)'), (53, 54, 3, 'R block at (53, 54)'),
             (45, 31, 3, 'R zone of houses at (44-46, 31-33)')]
    fig = plt.figure(figsize=(W, 8.6))
    fig.suptitle('Buildings and a zone in the map, byte by byte (ceiling-end.szx, frame 80 000 of the ceiling run)',
                 y=0.985)
    for i, (r0, c0, w, name) in enumerate(cases):
        if w == 3 and 'zone' in name:
            r0 -= 1
        y = 0.64 - i * 0.30
        ax = fig.add_axes([0.01, y, 0.2, 0.27])
        ax.imshow(rgb[r0 * 8:(r0 + w) * 8, c0 * 8:(c0 + w) * 8], interpolation='nearest')
        ax.set_xticks([])
        ax.set_yticks([])
        fig.text(0.01, y + 0.28, name + ': the picture and the %d x %d bytes at CityMap + 96 row + column'
                 % (w, w), fontsize=11, fontweight='bold')
        grid = [classify([city[(r0 + r) * 96 + c0 + c] for c in range(w)]) for r in range(w)]
        bx = fig.add_axes([0.23, y, 0.22, 0.25])
        draw_bytes(bx, grid, '')
        top = city[r0 * 96 + c0]
        lines = []
        if top >= 0x80:
            n0 = (city[r0 * 96 + c0 + 1] & 0x3F) * 8 + (city[r0 * 96 + c0 + 2] & 7)
            t = city[r0 * 96 + c0 + 1] & 0x3F
            kinds = {num(r[0]): r for r in table('BuildingKinds') if r[0] != 'end'}
            k = kinds.get(t)
            lines = ['top row byte %02X = 1 0 %d %d . %s:' % (top, top >> 5 & 1, top >> 4 & 1,
                                                                format(top & 7, '03b')),
                     '  bit 5 top row, bit 4 powered = %d, width %d' % (top >> 4 & 1, top & 7),
                     'next rows: %02X (bit 5 clear)' % city[(r0 + 1) * 96 + c0],
                     'bytes 2, 3: $C0|(n>>3), $C0|(n AND 7)',
                     '  row 1: n = %d (tiles n .. n+%d)' % (n0, w - 1),
                     '  each row its own n: %s' % ', '.join(
                         str((city[(r0 + r) * 96 + c0 + 1] & 0x3F) * 8 + (city[(r0 + r) * 96 + c0 + 2] & 7))
                         for r in range(w)),
                     'type = byte 2 of the top row AND $3F = $%02X' % t]
            if k:
                lines.append('BuildingKinds: routine %s, level %s, density %s' % (k[1], k[2], k[3]))
            lines.append('cells past byte 3: $C0 fillers')
        else:
            cells = [city[(r0 + r) * 96 + c0 + c] for r in range(3) for c in range(3)]
            dens = sum(v - 0x3B for v in cells if 0x3C <= v <= 0x43)
            lines = ['centre %02X: R centre, powered ($54 when not)' % cells[4],
                     'eight frame cells: $49-$50 empty, or a house',
                     'house $3C-$43 = 1-8: the cell value - $3B',
                     'Density = %s = %d' % (
                         '+'.join(str(v - 0x3B) for v in cells if 0x3C <= v <= 0x43), dens),
                     'people = 16 x Density = %d each pass' % (16 * dens),
                     'at Density 63+ the zone becomes a building',
                     'the zone has no record: the map is its state']
        fig.text(0.47, y + 0.25, '\n'.join(lines), va='top', fontsize=10.5, family='monospace')
    for k, (kind, label, colour) in enumerate([('top', 'top row byte $A0-$BF', '#ffd27f'),
                                               ('row', 'next row byte $80-$9F', '#ffe9bf'),
                                               ('num', 'tile number bytes', '#bfe0ff'),
                                               ('fill', '$C0 filler', '#e8e8e8'),
                                               ('cell', 'cell below $80', '#d9f2d0')]):
        x = 0.02 + k * 0.195
        fig.patches.append(plt.Rectangle((x, 0.02), 0.018, 0.022, transform=fig.transFigure, facecolor=colour,
                                         edgecolor='#444444'))
        fig.text(x + 0.024, 0.031, label, va='center', fontsize=10)
    save(fig, a.out)


def zone_density(m, r, c):
    return sum(m[(r + dr) * 96 + c + dc] - 0x3B for dr in (-1, 0, 1) for dc in (-1, 0, 1)
               if 0x3C <= m[(r + dr) * 96 + c + dc] <= 0x43)


def fig_zone(a):
    rows = samples(a.samples)
    r, c = map(int, a.at.split(','))
    picks = [int(x) for x in a.frames.split(',')]
    fig = plt.figure(figsize=(W, 6.8))
    fig.suptitle('An R zone growing: (row %d, column %d) in the city recording' % (r, c), y=0.985)
    byf = {d['frame']: d for d in rows}
    for i, f in enumerate(picks):
        d = byf[f]
        m = get(d, 0xC450, 9216)
        rgb = city_rgb(m)
        ax = fig.add_axes([0.01 + i * (0.98 / len(picks)), 0.53, 0.98 / len(picks) - 0.01, 0.37])
        ax.imshow(rgb[(r - 2) * 8:(r + 3) * 8, (c - 2) * 8:(c + 3) * 8], interpolation='nearest')
        ax.add_patch(plt.Rectangle((7.5, 7.5), 24, 24, fill=False, edgecolor='#ff00ff', linewidth=1.5))
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title('frame %d\nDensity %d' % (f, zone_density(m, r, c)), fontsize=10)
    ax = fig.add_axes([0.07, 0.09, 0.9, 0.4])
    fr = [d['frame'] for d in rows]
    dens = [zone_density(get(d, 0xC450, 9216), r, c) for d in rows]
    cent = [get(d, 0xC450 + r * 96 + c)[0] for d in rows]
    ax.plot(fr, dens, color='#1f77b4', label='Density of the zone (sum of the houses, 0-64)')
    ax.plot(fr, [16 if v == 0x51 else 0 for v in cent], color='#ff7f0e', drawstyle='steps-post',
            label='centre $51 powered (16) / other (0)')
    for f in picks:
        ax.axvline(f, color='#ff00ff', linewidth=0.8, linestyle=':')
    ax.set_xlabel('frame (sample = memory at the start of the frame, every 250 frames)')
    ax.set_ylabel('Density')
    ax.legend(loc='lower right')
    ax.grid(alpha=0.3)
    save(fig, a.out)


def array_img(d, base, side, scale=1):
    return np.frombuffer(get(d, base, side * side), np.uint8).reshape(side, side).astype(float) * scale


def fig_arrays(a):
    if a.state:
        import szx
        mem = bytes(szx.read(a.state)[0])
        arr = {'frame': 0, 'A950': mem[0xA950:0xC450].hex()}
        city = mem[0xC450:0xC450 + 9216]
        where = a.label
    else:
        arr = {d['frame']: d for d in samples(a.samples)}[a.frame]
        maps = {d['frame']: d for d in samples(a.maps)}[a.frame]
        city = get(maps, 0xC450, 9216)
        where = 'growth recording, sample of frame %d' % a.frame
    pm = get(arr, 0xBFD0, 96 * 12)
    power = np.array([[pm[r * 12 + c // 8] >> (7 - c % 8) & 1 for c in range(96)] for r in range(96)])
    big = [i for i, v in enumerate(city) if v >= 0x80 or 0x3C <= v <= 0x56]
    r0, r1 = min(i // 96 for i in big) - 4, max(i // 96 for i in big) + 5
    c0, c1 = min(i % 96 for i in big) - 4, max(i % 96 for i in big) + 5
    panels = [('CityMap $C450, cells', city_rgb(city), None, None),
              ('PowerMap $BFD0, 1 bit a cell', power, 'Greys', (0, 1)),
              ('FireCover $A950, 24 x 24', array_img(arr, 0xA950, 24), 'Reds', (0, 15)),
              ('PoliceCover $AB90, 24 x 24', array_img(arr, 0xAB90, 24), 'Blues', (0, 15)),
              ('Pollution $ADD0, 48 x 48', array_img(arr, 0xADD0, 48), 'YlOrBr', (0, 255)),
              ('Traffic $B6D0, 48 x 48', array_img(arr, 0xB6D0, 48), 'Purples', (0, 255))]
    fig, axs = plt.subplots(2, 3, figsize=(W, 6.6))
    fig.suptitle('The side arrays over the same map, map rows %d-%d, columns %d-%d: %s' % (r0, r1, c0, c1, where),
                 y=0.99)
    for ax, (title, img, cmap, lim) in zip(axs.flat, panels):
        if cmap is None:
            ax.imshow(img, interpolation='nearest', extent=(0, 96, 96, 0))
        else:
            im = ax.imshow(img, cmap=cmap, vmin=lim[0], vmax=lim[1], interpolation='nearest', extent=(0, 96, 96, 0))
            cb = fig.colorbar(im, ax=ax, fraction=0.04, pad=0.02)
            cb.set_ticks([lim[0], (lim[0] + lim[1]) // 2, lim[1]])
        ax.set_xlim(c0, c1)
        ax.set_ylim(r1, r0)
        ax.set_title(title, fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, a.out)


def fig_course(a):
    rows = samples(a.samples)
    fr = np.array([d['frame'] for d in rows])
    fig, axs = plt.subplots(3, 1, figsize=(W, 8.4), sharex=True)
    fig.suptitle('The city variables over the city recording (sample every 250 frames, at the start of the frame)',
                 y=0.99)
    ax = axs[0]
    ax.plot(fr, [u(d, 0x8E8A, 3) for d in rows], label='LastPop $8E8A (Population at the last month end)')
    ax.plot(fr, [u(d, 0x8E90, 3) for d in rows], label='PopLastYear $8E90 (at the last December)', linewidth=2)
    ax.plot(fr, [u(d, 0x8443, 3) for d in rows], label='Population $8443 (sum so far in this pass)', alpha=0.35)
    ax.set_ylim(0, 8000)
    ax.set_ylabel('people')
    ax.legend(loc='upper left')
    ax = axs[1]
    ax.plot(fr, [u(d, 0x8F97, 3) for d in rows], color='#2ca02c', label='Funds $8F97')
    ax.set_ylabel('dollars')
    t = ax.twinx()
    t.plot(fr, [u(d, 0x8F9C) + u(d, 0x8F9B, 1) / 12 for d in rows], color='#7f7f7f', label='Year + Month / 12')
    t.set_ylabel('year')
    ax.legend(loc='upper left')
    t.legend(loc='upper right')
    ax = axs[2]
    ax.plot(fr, [u(d, 0x975F, 1) for d in rows], label='Category $975F (0 VILLAGE, 1 TOWN)', color='black',
            linewidth=2)
    ax.plot(fr, [u(d, 0x91E4, 1) for d in rows], label='TaxRate $91E4 (%)', color='#d62728')
    ax.plot(fr, [u(d, 0x9996, 1) for d in rows], '.', ms=4, label='Advice $9996 (message index)', color='#9467bd')
    ax.set_ylabel('value')
    ax.set_xlabel('frame')
    ax.legend(loc='upper right')
    for ax in axs:
        ax.grid(alpha=0.3)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, a.out)


def fig_save(a):
    city, header = fig_city.load_city(a.tap)
    fields = [(0, 12, 'file name', '#bfe0ff'), (12, 3, 'Funds', '#ffd27f'), (15, 1, 'spare', '#e8e8e8'),
              (16, 1, 'Month', '#d9f2d0'), (17, 2, 'Year', '#c7f0c0'), (19, 1, 'spare', '#e8e8e8'),
              (20, 11, 'city name', '#f2c9e8')]
    fig = plt.figure(figsize=(W, 4.6))
    fig.suptitle('The save: header block (31 bytes, flag $FF), then the 9216-byte map (flag $FF); town.tap', y=0.98)
    ax = fig.add_axes([0.01, 0.42, 0.98, 0.4])
    for off, n, name, colour in fields:
        for k in range(n):
            i = off + k
            x = i % 16
            y = 1 - i // 16
            ax.add_patch(plt.Rectangle((x, y), 1, 1, facecolor=colour, edgecolor='#444444'))
            v = header[i]
            ax.text(x + 0.5, y + 0.62, '%02X' % v, ha='center', va='center', fontsize=12, family='monospace')
            ax.text(x + 0.5, y + 0.25, chr(v) if 32 <= v < 127 else '.', ha='center', va='center', fontsize=10,
                    color='#555555')
    for i in range(32):
        ax.text(i % 16 + 0.5, 2 - i // 16 + 0.05 if i < 16 else 1.05 - 1, '', fontsize=1)
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 2)
    ax.axis('off')
    funds = header[12] | header[13] << 8 | header[14] << 16
    year = header[17] | header[18] << 8
    months = 'JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'.split()
    for k, (off, n, name, colour) in enumerate(fields):
        x = 0.01 + k * 0.14
        fig.patches.append(plt.Rectangle((x, 0.30), 0.016, 0.04, transform=fig.transFigure, facecolor=colour,
                                         edgecolor='#444444'))
        fig.text(x + 0.02, 0.32, '+%d %s' % (off, name), va='center', fontsize=10)
    fig.text(0.01, 0.2, 'decoded: file %r, Funds %d, Month %d (%s), Year %d, city %r; the map block: %d bytes, %d '
             'building top rows' % (header[:12].decode('latin-1'), funds, header[16], months[header[16]], year,
                                    header[20:31].decode('latin-1'), len(city),
                                    sum(1 for v in city if 0xA0 <= v < 0xC0)), fontsize=10.5)
    fig.text(0.01, 0.1, 'Bytes +12..+18 are the 7 bytes Funds $8F97 .. Year $8F9C (LDIR); +20 takes 12 bytes from '
             'CityName $5F68,', fontsize=10.5)
    fig.text(0.01, 0.04, 'but the block is 31 bytes long ($A930-$A94E): the twelfth letter at $A94F never reaches '
             'the tape.', fontsize=10.5)
    save(fig, a.out)


WORKED = [('growth 9000, R zone', 151, 9, 6, 56, -26), ('city 15750, R zone', 150, 7, 6, 56, -34),
          ('growth 8100, C zone', 191, 0, 4, 56, -22)]


def fig_score(a):
    fig, axs = plt.subplots(1, len(WORKED), figsize=(W, 4.8), sharey=True)
    fig.suptitle('ZoneScoreOf on three sampled zones: land value minus pollution, crime and tax, plus demand',
                 y=0.98)
    for ax, (name, lv, p, crime, tax, dem) in zip(axs, WORKED):
        steps = [('LV', lv), ('-P', -p), ('-crime', -crime), ('-tax', -tax), ('+demand', dem)]
        level = 0
        for i, (lab, v) in enumerate(steps):
            nxt = max(0, level + v) if lab != '+demand' else level + v
            ax.bar(i, nxt - level, bottom=level, color='#2ca02c' if v >= 0 else '#d62728', edgecolor='black')
            ax.text(i, max(level, nxt) + 4, '%+d' % v if i else str(v), ha='center', fontsize=10)
            level = nxt
        score = max(0, min(255, level))
        ax.bar(len(steps), score, color='#1f77b4', edgecolor='black')
        ax.text(len(steps), score + 4, str(score), ha='center', fontsize=10, fontweight='bold')
        ax.set_xticks(range(len(steps) + 1))
        ax.set_xticklabels([s[0] for s in steps] + ['score'], rotation=30)
        ax.set_title(name, fontsize=11)
        ax.axhline(128, color='#7f7f7f', linestyle=':', linewidth=1)
        ax.grid(axis='y', alpha=0.3)
    axs[0].set_ylim(0, 215)
    axs[0].set_ylabel('points (128: an R zone may build a block)')
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    save(fig, a.out)


def kernel(name):
    return np.array([[int(x) for x in r] for r in table(name)])


def fig_kernels(a):
    ks = [('CoverKernel $7BEF (5 x 5)\nFireStrength 15: 15 >> (k - 1)', kernel('CoverKernel'), 15),
          ('PollutionKernel $7C77 (6 x 6)\ncoal plant $FF: 255 >> (k - 1)', kernel('PollutionKernel'), 255),
          ('TrafficKernel $7C9B (6 x 6)\na trip cell, strength 5', kernel('TrafficKernel'), 5)]
    fig, axs = plt.subplots(1, 3, figsize=(W, 4.4))
    fig.suptitle('The stamp kernels: each entry is a shift k (9 = none); the value added is strength >> (k - 1)',
                 y=0.98)
    for ax, (title, k, s) in zip(axs, ks):
        v = np.where(k == 9, 0, s >> np.clip(k - 1, 0, 8))
        ax.imshow(v, cmap='YlOrRd', vmin=0, vmax=s)
        for (r, c), kk in np.ndenumerate(k):
            ax.text(c, r - 0.15, 'k%d' % kk if kk != 9 else '-', ha='center', va='center', fontsize=10)
            ax.text(c, r + 0.22, str(v[r, c]) if kk != 9 else '', ha='center', va='center', fontsize=10,
                    fontweight='bold')
        ax.set_title(title, fontsize=11)
        ax.set_xticks(range(k.shape[1]))
        ax.set_yticks(range(k.shape[0]))
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    save(fig, a.out)


def fig_demand(a):
    rows = samples(a.samples)
    fr = [d['frame'] for d in rows]
    fig, axs = plt.subplots(2, 1, figsize=(W, 6.6), sharex=True)
    fig.suptitle('R/C/I demand in the city recording (sample every 250 frames, at the start of the frame)', y=0.99)
    for addr, name, col in ((0x827C, 'ResDemand', '#2ca02c'), (0x827E, 'ComDemand', '#1f77b4'),
                            (0x8280, 'IndDemand', '#ff7f0e')):
        axs[0].plot(fr, [s16(d, addr) for d in rows], color=col, label='%s $%04X' % (name, addr))
    axs[0].plot(fr, [s16(d, 0x8265) for d in rows], color='black', alpha=0.5, label='PopBalance $8265')
    axs[0].axhline(0, color='#7f7f7f', linewidth=0.8)
    axs[0].set_ylabel('signed 16 bits')
    axs[0].legend(loc='lower left', ncol=2)
    for addr, name, col in ((0x844C, 'PoliceCount', '#1f77b4'), (0x844E, 'FireCount', '#d62728'),
                            (0x8458, 'StadiumCount', '#9467bd'), (0x845C, 'SeaportCount', '#17becf'),
                            (0x845A, 'AirportCount', '#7f7f7f')):
        v = [u(d, addr) for d in rows]
        axs[1].plot(fr, [max(v[max(0, i - 2):i + 3]) for i in range(len(v))], color=col,
                    label='%s $%04X' % (name, addr))
    for addr, name, col in ((0x8446, 'ResPop', '#2ca02c'), (0x8448, 'ComPop', '#1f77b4'),
                            (0x844A, 'IndPop', '#ff7f0e')):
        v = [u(d, addr) for d in rows]
        axs[1].plot(fr, [max(v[max(0, i - 2):i + 3]) for i in range(len(v))], color=col, linestyle='--',
                    label='%s $%04X (zones)' % (name, addr))
    axs[1].set_ylabel('count (max of 5 samples)')
    axs[1].set_xlabel('frame')
    axs[1].legend(loc='upper left', ncol=3)
    for ax in axs:
        ax.grid(alpha=0.3)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, a.out)


def fig_ceiling(a):
    recs = []
    for line in open(a.log):
        m = re.match(r'frames (\d+) PopLastYear (\d+) month (\d+) year (\d+) tax (\d+) R zones (\d+) densities '
                     r'\[([^\]]*)\]', line)
        if m:
            recs.append((int(m[1]), int(m[2]), int(m[3]), int(m[4]), [int(x) for x in m[7].split(',')]))
    fig, axs = plt.subplots(1, 2, figsize=(W, 4.8), gridspec_kw={'width_ratios': [3, 2]})
    fig.suptitle('The ceiling run: metro end state, TaxRate 0, Funds 999 999, FAST (work/stage2/ceiling.log)',
                 y=0.98)
    ax = axs[0]
    fr = [r[0] for r in recs]
    ax.plot(fr, [r[1] for r in recs], 'o-', label='PopLastYear $8E90')
    ax.plot(fr, [16 * sum(r[4]) for r in recs], 's--', alpha=0.6, label='16 x the sum of R densities (log line)')
    ax.axhline(10000, color='#d62728', linestyle=':', label='CITY from 10 000 (CategoryLimits)')
    ax.axhline(9248, color='#7f7f7f', linestyle=':', label='metro end: 9248')
    for r in recs[::3]:
        ax.annotate('%s %d' % ('JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'.split()[r[2]], r[3]),
                    (r[0], r[1]), textcoords='offset points', xytext=(0, 8), fontsize=10, ha='center')
    ax.set_xlabel('frames from the start of the run')
    ax.set_ylabel('people')
    ax.legend(loc='lower right')
    ax.grid(alpha=0.3)
    ax = axs[1]
    first, last = recs[0][4], recs[-1][4]
    bins = range(0, 72, 8)
    ax.hist([first, last], bins=bins, label=['frame %d' % recs[0][0], 'frame %d' % recs[-1][0]],
            color=['#aec7e8', '#1f77b4'])
    ax.axvline(63, color='#d62728', linestyle=':', label='63: a block')
    ax.set_xlabel('R zone Density')
    ax.set_ylabel('zones')
    ax.legend(loc='upper left')
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    save(fig, a.out)


def fig_landscape(a):
    st = landscape.generate(a.gene)
    fig, axs = plt.subplots(1, 4, figsize=(W, 3.6))
    fig.suptitle('NewLandscape for gene %05d, stage by stage (tools/landscape.py; equals the growth samples)'
                 % a.gene, y=0.97)
    for ax, (name, m, calls) in zip(axs, st):
        ax.imshow(city_rgb(m)[::2, ::2], interpolation='nearest')
        ax.set_title('%s\nRandom calls: %d' % (name, calls), fontsize=10)
        ax.set_xticks([])
        ax.set_yticks([])
    fig.tight_layout(rect=(0, 0, 1, 0.92))
    save(fig, a.out)


def fig_disasters(a):
    rows = samples(a.samples)
    fr = [d['frame'] for d in rows]
    counts = {k: [] for k in ('fire $45', 'flood $44', 'rubble $3A', 'radiation $59')}
    for d in rows:
        m = get(d, 0xC450, 9216)
        counts['fire $45'].append(m.count(0x45))
        counts['flood $44'].append(m.count(0x44))
        counts['rubble $3A'].append(m.count(0x3A))
        counts['radiation $59'].append(m.count(0x59))
    fig, axs = plt.subplots(2, 1, figsize=(W, 6.4), sharex=True, gridspec_kw={'height_ratios': [3, 1]})
    fig.suptitle('The disasters recording: the cells of each kind on the map (sample every 50 frames)', y=0.99)
    for (k, v), col in zip(counts.items(), ('#d62728', '#1f77b4', '#7f7f7f', '#2ca02c')):
        axs[0].plot(fr, v, color=col, label=k)
    for f, name in ((150, "FIRE"), (2250, "FLOOD"), (4450, "EARTHQUAKE"), (6600, "AIR CRASH: none"), (8800, "TORNADO"),
                    (11050, "MELTDOWN")):
        for ax in axs:
            ax.axvline(f, color='black', linestyle=':', linewidth=0.8)
        axs[0].text(f + 40, 0.97, name, transform=axs[0].get_xaxis_transform(), fontsize=10, va='top')
    axs[0].set_ylabel('cells')
    axs[0].legend(loc='center left')
    axs[1].plot(fr, [u(d, 0x8985, 1) for d in rows], color='#1f77b4', label='FloodLeft $8985')
    axs[1].plot(fr, [50 * u(d, 0x7997, 1) for d in rows], color='#9467bd', label='TornadoOut $7997 x 50')
    axs[1].plot(fr, [50 * u(d, 0x7879, 1) for d in rows], color='#ff7f0e', label='PlaneOut $7879 x 50')
    axs[1].set_xlabel('frame')
    axs[1].legend(loc='upper right', ncol=3)
    for ax in axs:
        ax.grid(alpha=0.3)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, a.out)


def fig_funding(a):
    rows = [(num(s), num(m), num(t)) for s, m, t in table('Funding')]
    fig, ax = plt.subplots(figsize=(W, 4.2))
    fig.suptitle('Funding $950A: the share granted (funded / (cost / 8)) sets the decay mask and the strength',
                 y=0.97)
    sh = [r[0] for r in rows]
    ax.bar([s - 0.2 for s in sh], [r[2] for r in rows], width=0.4, color='#d62728',
           label='strength (FireStrength / PoliceStrength, the stamp)')
    t = ax.twinx()
    t.bar([s + 0.2 for s in sh], [bin(r[1]).count('1') for r in rows], width=0.4, color='#1f77b4',
          label='decay mask bits (RoadDecay / RailDecay): more bits, rarer crumbling')
    for s, m, st in rows:
        t.text(s + 0.2, bin(m).count('1') + 0.1, '$%02X' % m, ha='center', fontsize=10)
    ax.set_xlabel('share (8 = fully funded; the table goes on above 8)')
    ax.set_ylabel('strength')
    t.set_ylabel('mask bits')
    ax.legend(loc='upper left')
    t.legend(loc='lower right')
    ax.set_xticks(sh)
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    save(fig, a.out)


def fig_random(a):
    r = landscape.Rng(0)
    seen, outs = {}, []
    while r.seed not in seen:
        seen[r.seed] = r.calls
        outs.append(r.next())
    period = r.calls - seen[r.seed]
    ok = all((254 * (x + 1) - 1) % 65537 == landscape_step(x) for x in range(0, 65536, 97))
    fig, axs = plt.subplots(1, 2, figsize=(W, 4.8))
    fig.suptitle('Random $5CC6: one cycle of %d seeds; (254 (seed + 1) - 1) mod 65537 %s'
                 % (period, 'matches the Z80 steps' if ok else 'differs'), y=0.98)
    x = np.array(outs[:6000])
    axs[0].plot(x[:-1], x[1:], '.', ms=2)
    axs[0].set_xlabel('A of call n')
    axs[0].set_ylabel('A of call n + 1')
    axs[0].set_title('successive results (6000 calls): no visible lattice', fontsize=11)
    hits = [i for i, v in enumerate(outs) if v & 0x7F == 0]
    gaps = np.diff(hits)
    axs[1].hist(gaps, bins=range(0, 600, 16), color='#d62728')
    axs[1].axvline(128, color='black', linestyle=':', label='128: the mean of an ideal 1 in 128')
    axs[1].set_xlabel('calls between two results with A AND $7F = 0 (StartFires)')
    axs[1].set_ylabel('count over the period')
    axs[1].set_title('mean gap %.1f calls' % gaps.mean(), fontsize=11)
    axs[1].legend()
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    save(fig, a.out)


def landscape_step(x):
    r = landscape.Rng(x)
    r.next()
    return r.seed


def main():
    p = argparse.ArgumentParser()
    p.add_argument('figure')
    p.add_argument('--out', required=True)
    p.add_argument('--samples')
    p.add_argument('--maps')
    p.add_argument('--state')
    p.add_argument('--tap')
    p.add_argument('--log')
    p.add_argument('--label', default='')
    p.add_argument('--at', default='45,32')
    p.add_argument('--frames', default='15500,16250,18000,20000,23000,27000,35000')
    p.add_argument('--frame', type=int, default=24000)
    p.add_argument('--gene', type=int, default=3)
    a = p.parse_args()
    globals()['fig_' + a.figure](a)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The figures of doc 02 (architecture): the memory map and the module map, drawn from the sources' .ann files.

    python3 tools/fig_arch.py memmap docs/img/arch/memmap.png
    python3 tools/fig_arch.py modules docs/img/arch/modules.png

memmap: the 64 K the CPU sees in play on a 128K (ROM, RAM 5, RAM 2, RAM 0), each region of REGIONS drawn to scale,
and RAM 1 beside it with the music's four modules (src/music/music.ann). modules: the game's code block
`$7080-$A7FF` (src/game/game.ann), 512 bytes a row, each byte coloured by the @module its entry belongs to, as
kit/mkgame.py cuts the source; under it each module's size.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
BG, TEXT, DIM, PANEL = K.BACKGROUND, K.TEXT, K.DIM, K.PANEL
COL = K.ROUTINE_COLOURS

# (start, end, name, colour index): the 64 K in play on a 128K (doc 02 2.2)
REGIONS = [
    (0x0000, 0x3FFF, 'ROM 1 (48 BASIC): not used in play', None),
    (0x4000, 0x57FF, 'screen bitmap: HUD row 0, view rows 1-23', 2),
    (0x5800, 0x5AFF, 'screen attributes', 2),
    (0x5B00, 0x5DFF, 'system variables', None),
    (0x5E00, 0x5FFF, 'SpareCells: the composed cells (to $61BF at most, over the dead MusicImage)', 3),
    (0x6000, 0x64FF, 'MusicImage as loaded (runs to $707F; dead after CopyMusic)', 9),
    (0x6500, 0x65FF, 'MirrorTable', 4),
    (0x6600, 0x6AFF, 'DirtyMap 32 x 40', 3),
    (0x6B00, 0x707F, 'ViewCells 32 x 44', 3),
    (0x7080, 0xA7FF, 'the game: code, tables, variables (18 modules)', 1),
    (0xA800, 0xC1FF, 'level: cells (flags, pixels, attrs), blocks', 5),
    (0xC200, 0xC26C, 'LevelHeader, hooks, SpriteFrameMap', 5),
    (0xC26D, 0xE1EC, 'level: sprites (to the maps\' base)', 6),
    (0xE1ED, 0xFCFF, 'level: maps, sections, kinds; L5 code', 7),
    (0xFD00, 0xFE00, 'Im2Table: 257 x $FE', 0),
    (0xFE01, 0xFEFD, '(free)', None),
    (0xFEFE, 0xFF20, 'Im2Handler (copied from $7C39)', 0),
    (0xFF21, 0xFFFF, 'loader tail; the stack below $0000', 8),
]
BANKS = [(0x0000, 'ROM 1'), (0x4000, 'RAM 5'), (0x8000, 'RAM 2'), (0xC000, 'RAM 0')]


def ann_modules(path):
    """[(address, module)] for every entry of an .ann, in file order, the module as mkgame cuts it."""
    out, cur = [], None
    for line in open(path):
        m = re.match(r'@module (\w+)', line)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) [cbwts]', line)
        if m and cur:
            out.append((int(m.group(1), 16), cur))
    return sorted(out)


def module_of(entries, end):
    """A byte-by-byte module map from the entries up to end (inclusive)."""
    res = {}
    for i, (a, mod) in enumerate(entries):
        b = entries[i + 1][0] if i + 1 < len(entries) else end + 1
        for x in range(a, b):
            res[x] = mod
    return res


def fig_memmap(out):
    H = 1200
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'The memory map in play on a 128K: one 64 K view, RAM 1 for the music', font=K.font(18), fill=TEXT)
    d.text((12, 36), 'to scale, 1 px = 64 bytes; colours: the parts of the source; grey: not the game\'s',
           font=K.font(13), fill=DIM)
    top, x0, bw = 70, 110, 120
    f = K.font(13)
    for a, name in BANKS:
        y = top + a // 64
        d.line((x0 - 70, y, x0, y), fill=DIM)
        d.text((12, y + 2), '$%04X' % a, font=f, fill=TEXT)
        d.text((12, y + 18), name, font=f, fill=DIM)
    d.line((x0 - 70, top + 0x10000 // 64, x0, top + 0x10000 // 64), fill=DIM)
    d.text((12, top + 0x10000 // 64 + 2), '$FFFF', font=f, fill=TEXT)
    # the regions, labels pushed apart
    mids = [(top + s // 64 + top + (e + 1) // 64) // 2 for s, e, _, _ in REGIONS]
    lys = []
    for mid in mids:
        lys.append(max(mid - 8, lys[-1] + 17 if lys else top))
    limit = top + 0x10000 // 64 + 60
    for i in range(len(lys) - 1, -1, -1):
        lys[i] = min(lys[i], limit - 17 * (len(lys) - i))
    for (s, e, name, c), mid, ly in zip(REGIONS, mids, lys):
        y1, y2 = top + s // 64, top + (e + 1) // 64
        colour = (60, 60, 70) if c is None else COL[c]
        d.rectangle((x0, y1, x0 + bw, max(y1, y2 - 1)), fill=colour, outline=BG)
        lx = x0 + bw + 70
        d.line((x0 + bw, mid, x0 + bw + 20, mid, lx - 4, ly + 8), fill=DIM)
        d.text((lx, ly), '$%04X-$%04X %s' % (s, e, name), font=f, fill=TEXT if c is not None else DIM)
    # RAM 1
    rx = 800
    d.text((rx, top - 20), 'RAM 1 at $C000 (128K only)', font=f, fill=TEXT)
    music = ann_modules(os.path.join(CASE, 'src', 'music', 'music.ann'))
    mm = module_of(music, 0xD07F)
    cols = {'tunes': 7, 'effects': 9, 'player': 2, 'sequencer': 4}
    for a in range(0xC000, 0x10000, 64):
        mod = mm.get(a)
        y = top + a // 64
        colour = COL[cols[mod]] if mod else (40, 40, 50)
        d.rectangle((rx, y, rx + 60, y), fill=colour)
    d.rectangle((rx, top + 0xC000 // 64, rx + 60, top + 0x10000 // 64 - 1), outline=DIM)
    ly = top + 0xC000 // 64
    for mod in ['tunes', 'effects', 'player', 'sequencer']:
        addrs = [a for a, m in music if m == mod]
        d.rectangle((rx + 70, ly + 3, rx + 80, ly + 13), fill=COL[cols[mod]])
        d.text((rx + 86, ly), '%s from $%04X' % (mod, min(addrs)), font=f, fill=TEXT)
        ly += 18
    d.text((rx + 70, ly + 4), '$D080-$FFFF unused', font=f, fill=DIM)
    d.text((rx, top + 0xC000 // 64 - 90), 'paged in only inside\nCallRam1 ($7A77), with DI:\nMusicFrame each interrupt,\n'
           'MusicStart, MusicEffect', font=f, fill=DIM)
    img.save(out)
    print(out, img.size)


def fig_modules(out):
    entries = ann_modules(os.path.join(CASE, 'src', 'game', 'game.ann'))
    mm = module_of(entries, 0xA7FF)
    sizes = {}
    for a in range(0x7080, 0xA800):
        sizes[mm[a]] = sizes.get(mm[a], 0) + 1
    order = sorted(sizes, key=lambda m: -sizes[m])
    colour = {m: COL[i % len(COL)] for i, m in enumerate(order)}
    per, px, rh = 448, 2, 18
    rows = (0xA800 - 0x7080 + per - 1) // per
    top = 64
    H = top + rows * rh + 40 + ((len(order) + 2) // 3) * 22 + 20
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    f = K.font(13)
    d.text((12, 10), 'The game block $7080-$A7FF by module: 18 modules, interleaved in memory', font=K.font(18), fill=TEXT)
    d.text((12, 36), 'one row = 448 bytes, 2 px a byte; each byte coloured by the @module of its entry in src/game/game.ann',
           font=f, fill=DIM)
    x0 = 12
    for r in range(rows):
        base = 0x7080 + r * per
        y = top + r * rh
        d.text((x0, y + 1), '$%04X' % base, font=f, fill=TEXT)
        for i in range(per):
            a = base + i
            if a > 0xA7FF:
                break
            xx = x0 + 62 + i * px
            d.rectangle((xx, y, xx + px - 1, y + rh - 3), fill=colour[mm[a]])
    y = top + rows * rh + 16
    for i, m in enumerate(order):
        cx = 12 + (i % 3) * 345
        cy = y + (i // 3) * 22
        d.rectangle((cx, cy + 3, cx + 12, cy + 15), fill=colour[m])
        d.text((cx + 18, cy), '%-10s %5d bytes' % (m, sizes[m]), font=f, fill=TEXT)
    img.save(out)
    print(out, img.size)
    for m in order:
        print(m, sizes[m])


if __name__ == '__main__':
    what, out = sys.argv[1], sys.argv[2]
    {'memmap': fig_memmap, 'modules': fig_modules}[what](out)

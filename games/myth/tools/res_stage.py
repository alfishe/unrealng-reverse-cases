#!/usr/bin/env python3
"""The stage blocks' resources (src/res/stageN/): the formats tools/res_formats.py loads (FORMATS below). Every
format works on any stage: the stage is the resource's folder (`stage1/rooms.bin`, `stage3/rooms.bin`), the kind is
the file's name. The stages hold the same engine, so their data have the same shapes (docs/02-architecture.md 2.3).

    NAME (under stageN/)        editable form       what
    graphics.bin                graphics.txt        the RLE-packed tiles, blocks and map (Unrle's input): the text
                                + tiles.png         holds the packer's settings, the tile kinds, the blocks and
                                                    the map grids; the tiles' pixels and attributes are tiles.png
    tiles.png                   (itself)            the tile sheet graphics.txt reads (checked on its own too)
    rooms.bin                   rooms.txt           the grid records, their room tables and the placement lists
    sprites-NAME.bin            sprites-NAME.png    a sprite set: the frames' bitmaps followed by their frame table
    bitmaps-NAME-WxH.bin        bitmaps-NAME-WxH.png  plain 1-bit frames of W bytes x H lines, one after another
    picture-NAME-WxH.bin        picture-NAME-WxH.png  a linear picture of W bytes x H lines and its attributes
    rowpicture-NAME.bin         rowpicture-NAME.png   a row-packed picture: each line's skip and bytes
    table-NAME.bin              table-NAME.csv      a table of fixed rows, the columns in TABLES[NAME]
    text-NAME.bin               text-NAME.txt       text: one quoted string a line
    anything else               the bytes

**graphics.txt.** The packed block (stage 1 `$B4B2`, 3583 bytes) unpacks (Unrle `$A424`: escape byte first, then a
byte other than the escape is itself, `ESC n v` is n copies of v, `ESC ESC` ends) into five words and five sections
at `$5B00`: the words are the sections' offsets from `$5B0A` (tile kinds, tile pixels, tile attributes, blocks,
map). The text gives the escape byte and the packer's one quirk, `literal OFFSET COUNT`: a stretch of equal bytes
the original packer left unpacked (one blank tile in each stage); the packer here is greedy (every run of 4 to 255
equal bytes is `ESC n v`) and gives the original bytes bit for bit with that stretch. Then `kinds` (one number a
tile), `block N: t0 t1 t2 t3` (top left, top right, bottom left, bottom right) and the map as `grid` sections of
block numbers (hex, one row of the grid a line; the grid sizes are the stage's grid records, GRIDS below, which
tools/fig_rooms.py and rooms.txt agree with). The tile pixels and attributes are tiles.png beside it.

**tiles.png.** Colour cells: a palette of 64 Spectrum entries, index = flash x 32 + ink x 16 + bright x 8 + colour
(the ink bit says whether the pixel is ink or paper), and grey (64) for the lines between the tiles, 16 tiles a
row. A cell all ink or all paper cannot show its other colour: the text chunk `tx-cells` keeps those attributes.

**rooms.txt.** The grid records in memory order, each followed by its room table, then the placement lists:
`grid W H COLUMN ROW ROOMS MAP STEP` (width and height in blocks, the start window's column and row in blocks, the
room table's address, the grid's offset in the map section, rooms per grid row), `rooms` with the room table one
grid row of rooms a line (each room's exit bits: 1 right, 2 left, 4 up, 8 down), and `placements` sections, one
`KIND X Y` line a placement (X, Y in cells over the whole grid; `done` when bit 7 of the kind is set) ended by
`end` (the `$FF $FF $FF` record).

**sprites-NAME.png.** A frame table of 6-byte records (dx, dy, width in bytes, height in lines, the offset word of
the frame's bitmap from the set's base) follows its bitmaps (SetActorFrame `$AA02`). Indexed PNG: 0 paper (black),
1 ink (white), 2 the grid (grey), the frames in a row. The text chunk `tx-frames` keeps the table (dx, dy and the
offsets; width and height are the frames' boxes).

Each stageN/README.md lists the files with their addresses and readers.
"""
import io
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(HERE), 'src', 'res')

# The grids of each stage's map, in the order of the map section: (width, height) in blocks, from the stage's grid
# records (stage 1: $9B6F, $9B8A, $9B96). rooms.txt holds the records themselves; this is only the map's layout.
GRIDS = {
    'stage1': [(69, 21), (14, 21), (14, 9)],
    'stage2': [(69, 9), (47, 15), (14, 9)],
    'stage3': [(47, 9), (124, 9), (14, 9)],
    'stage4': [(25, 9), (14, 9), (47, 9), (14, 15), (47, 9), (58, 9), (58, 9), (36, 9), (36, 9)],
}

# The tables: NAME (the file is table-NAME.bin): the columns, each (name, kind); kinds: u8, s8, x8 (hex byte),
# x16 (hex word, low byte first), u16.
TABLES = {
    'burst-steps': [('dx', 's8'), ('dy', 's8')],
    'kinds': [('y', 'u8'), ('handler', 'x16'), ('counter', 'x8'), ('flags', 'x8'), ('state', 'x8'),
              ('item', 'x8'), ('attribute', 'x8'), ('keep', 'x8')],
    'actor-templates': [('x', 'u8'), ('y', 'u8'), ('width', 'u8'), ('height', 'u8'), ('frame', 'x16'),
                        ('handler', 'x16'), ('counter', 'x8'), ('flags', 'x8'), ('state', 'x8'), ('item', 'x8'),
                        ('attribute', 'x8'), ('entry_x', 'u8'), ('entry_y', 'u8'), ('keep', 'x8'),
                        ('placement', 'x8'), ('shift', 'u8')],
    'startitems': [('item', 'u8')],
    'arena-attributes': [('c%d' % i, 'x8') for i in range(16)],
    'burst-glyphs': [('glyph', 'u8')],
    'burst-directions': [('s%d' % i, 'u8') for i in range(32)],
    'itemicons': [('icon', 'x16')],
    'throne-attributes': [('c%d' % i, 'x8') for i in range(5)],
    'dragon-attributes': [('c%d' % i, 'x8') for i in range(9)],
    'dragon-head-frames': [('dx', 's8'), ('dy', 's8'), ('width', 'u8'), ('height', 'u8'), ('offset', 'u16')],
    'dameron-path': [('dx', 's8'), ('dy', 's8')],
    'frame-offsets': [('offset', 'x16')],
    'burst-directions-cut': [('s%d' % i, 'u8') for i in range(26)],
    'boss-colours': [('c%d' % i, 'x8') for i in range(8)],
    'boss-hit-colours': [('c%d' % i, 'x8') for i in range(8)],
    'arc-steps': [('dy', 's8')],
    'boss-fall-steps': [('dy', 's8')],
    'boss-hover-path': [('dy', 's8')],
    'shot-directions': [('dx', 's8'), ('dy', 's8'), ('frame', 'u8'), ('mirrored', 'u8')],
    'star-pixels': [('p%d_l%d' % (p, l), 'x8') for p in range(4) for l in range(2)],
    'pace-waits': [('rounds', 'x16')],
}


def stage_of(name):
    return name.split('/')[0]


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.lstrip().startswith('#')]


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


# ---------------------------------------------------------------------------------------------------------------
# RLE (Unrle $A424) both ways
# ---------------------------------------------------------------------------------------------------------------
def unrle(d):
    """(the unpacked bytes, the escape byte, the stretches of 4 or more equal bytes left as literals)"""
    esc = d[0]
    i, out, lits = 1, bytearray(), []
    run_v, run_n, run_at = None, 0, 0
    while True:
        a = d[i]
        i += 1
        if a != esc:
            if a == run_v:
                run_n += 1
            else:
                if run_n >= 4:
                    lits.append((run_at, run_n))
                run_v, run_n, run_at = a, 1, len(out)
            out.append(a)
            continue
        if run_n >= 4:
            lits.append((run_at, run_n))
        run_v, run_n = None, 0
        if d[i] == esc:
            if i + 1 != len(d):
                raise ValueError('rle: %d bytes after the end mark' % (len(d) - i - 1))
            return bytes(out), esc, lits
        out += bytes([d[i + 1]]) * (d[i] or 256)
        i += 2


def rle(d, esc, literal=()):
    """the greedy packer: a run of 4-255 equal bytes is ESC n v, unless it starts in a literal stretch"""
    if esc in d:
        raise ValueError('rle: the escape byte $%02X occurs in the data' % esc)
    o, i = bytearray([esc]), 0
    while i < len(d):
        j = i
        while j < len(d) and d[j] == d[i] and j - i < 255:
            j += 1
        if j - i >= 4 and not any(a <= i < a + n for a, n in literal):
            o += bytes([esc, j - i, d[i]])
            i = j
        else:
            o.append(d[i])
            i += 1
    return bytes(o + bytes([esc, esc]))


# ---------------------------------------------------------------------------------------------------------------
# PNG helpers: colour cells and mono frames
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return [((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v]


COLOURS = []
for _i in range(64):
    COLOURS += zx_rgb(_i & 7, (_i >> 3) & 1)
GREY = 64
COLOURS += [128, 128, 128]
MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]


def png_new(w, h, fill, palette):
    from PIL import Image
    img = Image.new('P', (w, h), fill)
    img.putpalette(palette + [0] * (768 - len(palette)))
    return img, img.load()


def png_bytes(img, key, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text(key, json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_open(raw, key):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    return img, img.load(), json.loads(img.text[key])


def tiles_to_png(pixels, attrs, cols=16):
    n = len(attrs)
    rows = (n + cols - 1) // cols
    img, px = png_new(1 + cols * 9, 1 + max(rows, 1) * 9, GREY, COLOURS)
    hidden = []
    for t in range(n):
        x0, y0 = 1 + (t % cols) * 9, 1 + (t // cols) * 9
        a, seen = attrs[t], set()
        for r in range(8):
            for b in range(8):
                ink = (pixels[8 * t + r] >> (7 - b)) & 1
                seen.add(ink)
                px[x0 + b, y0 + r] = (a >> 7) * 32 + ink * 16 + ((a >> 6) & 1) * 8 + (a & 7 if ink else (a >> 3) & 7)
        if len(seen) < 2:
            hidden.append([t, a])
    return png_bytes(img, 'tx-cells', {'tiles': n, 'cols': cols, 'hidden': hidden})


def png_to_tiles(raw):
    _img, px, meta = png_open(raw, 'tx-cells')
    hidden = dict((t, a) for t, a in meta['hidden'])
    pixels, attrs = bytearray(), bytearray()
    for t in range(meta['tiles']):
        x0, y0 = 1 + (t % meta['cols']) * 9, 1 + (t // meta['cols']) * 9
        ink_c = paper_c = flash = bright = 0
        for r in range(8):
            v = 0
            for b in range(8):
                i = px[x0 + b, y0 + r]
                ink = (i >> 4) & 1
                v = v << 1 | ink
                flash, bright = i >> 5, (i >> 3) & 1
                if ink:
                    ink_c = i & 7
                else:
                    paper_c = i & 7
            pixels.append(v)
        attrs.append(hidden[t] if t in hidden else flash << 7 | bright << 6 | paper_c << 3 | ink_c)
    return bytes(pixels), bytes(attrs)


def frames_to_png(bitmaps, sizes, key, meta):
    """frames (each w bytes x h lines, rows top first) in one row, a grey line between them"""
    width = 1 + sum(w * 8 + 1 for w, _ in sizes)
    height = 2 + max([h for _, h in sizes] or [1])
    img, px = png_new(width, height, 2, MONO)
    x0 = 1
    for bm, (w, h) in zip(bitmaps, sizes):
        for y in range(height - 2):
            for x in range(w * 8):
                px[x0 + x, 1 + y] = ((bm[y * w + x // 8] >> (7 - x % 8)) & 1) if y < h else 2
        x0 += w * 8 + 1
    return png_bytes(img, key, meta)


def png_to_frames(raw, key):
    _img, px, meta = png_open(raw, key)
    out, x0 = [], 1
    for w, h in meta['sizes']:
        bm = bytearray(w * h)
        for y in range(h):
            for x in range(w * 8):
                if px[x0 + x, 1 + y] == 1:
                    bm[y * w + x // 8] |= 0x80 >> (x % 8)
        out.append(bytes(bm))
        x0 += w * 8 + 1
    return out, meta


# ---------------------------------------------------------------------------------------------------------------
# graphics.bin: the packed tiles, blocks and map
# ---------------------------------------------------------------------------------------------------------------
def unpack_sections(d):
    w = [d[i] | d[i + 1] << 8 for i in range(0, 10, 2)]
    kinds, pix, att, blk, mp = (10 + x for x in w)
    n = pix - kinds
    if w[0] != 0 or att - pix != 8 * n or blk - att != n or (mp - blk) % 4:
        raise ValueError('graphics: the section offsets %s are not kinds, pixels, attributes, blocks, map' % w)
    return w, d[kinds:pix], d[pix:att], d[att:blk], d[blk:mp], d[mp:]


def graphics_out(name, data):
    d, esc, lits = unrle(data)
    w, kinds, pix, att, blk, mp = unpack_sections(d)
    stage = stage_of(name)
    folder = os.path.join(RES, stage)
    os.makedirs(folder, exist_ok=True)
    open(os.path.join(folder, 'tiles.png'), 'wb').write(tiles_to_png(pix, att))
    lines = ['# %s: the RLE-packed tiles, blocks and map (tools/res_stage.py; pixels and attributes: tiles.png)' % stage,
             '# unpacked %d bytes: %d tiles, %d blocks, map %d bytes' % (len(d), len(kinds), len(blk) // 4, len(mp)),
             'escape $%02X' % esc]
    lines += ['literal %d %d' % x for x in lits]
    lines.append('# tile kinds, one a tile (16 a line)')
    for i in range(0, len(kinds), 16):
        lines.append('kinds ' + ' '.join('%d' % k for k in kinds[i:i + 16]))
    lines.append('# blocks: top left, top right, bottom left, bottom right tile')
    for b in range(len(blk) // 4):
        lines.append('block %d: %s' % (b, ' '.join('%d' % t for t in blk[4 * b:4 * b + 4])))
    grids = GRIDS.get(stage) or [(32, (len(mp) + 31) // 32)]
    k = 0
    for g, (gw, gh) in enumerate(grids):
        lines.append('grid %d: %d x %d blocks (hex block numbers, one row a line)' % (g, gw, gh))
        for _ in range(gh):
            row = mp[k:k + gw]
            if row:
                lines.append(' '.join('%02X' % v for v in row))
            k += gw
    if k < len(mp):
        lines.append('rest: ' + ' '.join('%02X' % v for v in mp[k:]))
    return text_file(lines)


def graphics_in(name, raw):
    stage = stage_of(name)
    pix, att = png_to_tiles(open(os.path.join(RES, stage, 'tiles.png'), 'rb').read())
    esc, lits, kinds, blocks, mp = None, [], [], [], []
    for ln in lines_of(raw):
        t = ln.split()
        if t[0] == 'escape':
            esc = num(t[1])
        elif t[0] == 'literal':
            lits.append((int(t[1]), int(t[2])))
        elif t[0] == 'kinds':
            kinds += [int(x) for x in t[1:]]
        elif t[0] == 'block':
            blocks += [int(x) for x in t[2:]]
        elif t[0] == 'grid':
            continue
        elif t[0] == 'rest:':
            mp += [int(x, 16) for x in t[1:]]
        else:
            mp += [int(x, 16) for x in t]
    n = len(kinds)
    if len(att) != n:
        raise ValueError('graphics: %d tile kinds, %d tiles in tiles.png' % (n, len(att)))
    offs = [0, n, 9 * n, 10 * n, 10 * n + len(blocks)]
    d = b''.join(bytes([o & 255, o >> 8]) for o in offs) + bytes(kinds) + pix + att + bytes(blocks) + bytes(mp)
    return rle(d, esc, lits)


def tiles_png_check_out(name, data):
    n = len(data) // 9
    return tiles_to_png(data[:8 * n], data[8 * n:])


def tiles_png_check_in(name, raw):
    pix, att = png_to_tiles(raw)
    return pix + att


# ---------------------------------------------------------------------------------------------------------------
# rooms.bin: the grid records, room tables and placement lists
# ---------------------------------------------------------------------------------------------------------------
def rooms_per_grid(gw, gh):
    return ((gw - 14 + 10) // 11 + 1) * ((gh - 9 + 5) // 6 + 1)


def rooms_out(name, data, base=None):
    lines = ['# %s: the map grids, their room tables and the placement lists (tools/res_stage.py)' % stage_of(name),
             '# grid W H COLUMN ROW ROOMS MAP STEP: blocks wide and high, the start window (blocks), the room table,',
             '#   the grid\'s offset in the map, rooms a grid row; rooms: one exit byte a room (1 right, 2 left, 4 up,',
             '#   8 down), a grid row of rooms a line; placements: KIND X Y (cells over the grid), "done" = bit 7']
    if base is None:
        base = (data[4] | data[5] << 8) - 9
    lines.append('base $%04X' % base)
    i = 0
    while i + 9 <= len(data) and (data[i + 4] | data[i + 5] << 8) == base + i + 9 and data[i] >= 14 and data[i + 1] >= 9:
        gw, gh, col, row = data[i:i + 4]
        mo = data[i + 6] | data[i + 7] << 8
        step = data[i + 8]
        lines.append('grid %d %d %d %d $%04X %d %d' % (gw, gh, col, row, base + i + 9, mo, step))
        n = rooms_per_grid(gw, gh)
        tab = data[i + 9:i + 9 + n]
        for r in range(0, n, max(step, 1)):
            lines.append('rooms ' + ' '.join('%X' % v for v in tab[r:r + max(step, 1)]))
        i += 9 + n
    while i < len(data):
        lines.append('placements')
        while i < len(data) and data[i] != 0xFF:
            k, x, y = data[i:i + 3]
            lines.append('%d %d %d%s' % (k & 0x7F, x, y, ' done' if k & 0x80 else ''))
            i += 3
        tail = data[i:i + 3]
        if tail != b'\xff\xff\xff':
            raise ValueError('rooms: a placement list ends in %s at +%d' % (tail.hex(), i))
        lines.append('end')
        i += 3
    return text_file(lines)


def rooms_in(name, raw):
    out = bytearray()
    for ln in lines_of(raw):
        t = ln.split()
        if t[0] in ('base', 'placements'):
            continue
        if t[0] == 'grid':
            gw, gh, col, row = (int(x) for x in t[1:5])
            rooms, mo, step = num(t[5]), int(t[6]), int(t[7])
            out += bytes([gw, gh, col, row, rooms & 255, rooms >> 8, mo & 255, mo >> 8, step])
        elif t[0] == 'rooms':
            out += bytes(int(x, 16) for x in t[1:])
        elif t[0] == 'end':
            out += b'\xff\xff\xff'
        else:
            out += bytes([int(t[0]) | (0x80 if len(t) > 3 and t[3] == 'done' else 0), int(t[1]), int(t[2])])
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# sprites-NAME.bin: bitmaps followed by their frame table; bitmaps-NAME-WxH.bin: plain frames
# ---------------------------------------------------------------------------------------------------------------
def frame_table(data):
    """the count of 6-byte frame records at the end of a sprite set: the largest n whose records all lie in the
    bitmaps before them and cover them to the last byte"""
    best = None
    for n in range(1, len(data) // 6):
        g = len(data) - 6 * n
        recs = [data[g + 6 * k:g + 6 * k + 6] for k in range(n)]
        if all(1 <= r[2] <= 8 and 1 <= r[3] and (r[4] | r[5] << 8) + r[2] * r[3] <= g for r in recs) and \
                max((r[4] | r[5] << 8) + r[2] * r[3] for r in recs) == g:
            best = n
    if best is None:
        raise ValueError('sprites: no frame table at the end')
    return best


def sprites_out(name, data):
    n = frame_table(data)
    g = len(data) - 6 * n
    recs = [data[g + 6 * k:g + 6 * k + 6] for k in range(n)]
    sizes = [(r[2], r[3]) for r in recs]
    offs = [r[4] | r[5] << 8 for r in recs]
    bms = [data[o:o + w * h] for o, (w, h) in zip(offs, sizes)]
    cover = bytearray(g)
    for o, (w, h) in zip(offs, sizes):
        for k in range(o, o + w * h):
            cover[k] = 1
    rest = [[k, data[k]] for k in range(g) if not cover[k]]
    meta = {'bitmaps': g, 'sizes': sizes, 'frames': [[r[0] - 256 if r[0] > 127 else r[0],
                                                       r[1] - 256 if r[1] > 127 else r[1], o]
                                                      for r, o in zip(recs, offs)], 'rest': rest}
    return frames_to_png(bms, sizes, 'tx-frames', meta)


def sprites_in(name, raw):
    bms, meta = png_to_frames(raw, 'tx-frames')
    g = bytearray(meta['bitmaps'])
    seen = {}
    for bm, (dx, dy, o) in zip(bms, meta['frames']):
        for k, v in enumerate(bm):
            if o + k in seen and seen[o + k] != v:
                raise ValueError('sprites: two frames share byte %d with other values' % (o + k))
            seen[o + k] = v
            g[o + k] = v
    for k, v in meta['rest']:
        g[k] = v
    tab = bytearray()
    for (w, h), (dx, dy, o) in zip(meta['sizes'], meta['frames']):
        tab += bytes([dx & 255, dy & 255, w, h, o & 255, o >> 8])
    return bytes(g + tab)


def bitmaps_geometry(name):
    m = re.search(r'-(\d+)x(\d+)\.bin$', name)
    return int(m.group(1)), int(m.group(2))


def bitmaps_out(name, data):
    w, h = bitmaps_geometry(name)
    n, rest = divmod(len(data), w * h)
    return frames_to_png([data[k * w * h:(k + 1) * w * h] for k in range(n)], [(w, h)] * n, 'tx-frames',
                         {'sizes': [(w, h)] * n, 'rest': data[n * w * h:].hex()})


def bitmaps_in(name, raw):
    bms, meta = png_to_frames(raw, 'tx-frames')
    return b''.join(bms) + bytes.fromhex(meta['rest'])


# ---------------------------------------------------------------------------------------------------------------
# picture-NAME-WxH.bin: a linear picture (H lines of W bytes, top first) followed by its attributes (H / 8 rows of W)
# ---------------------------------------------------------------------------------------------------------------
def picture_out(name, data):
    w, h = bitmaps_geometry(name)
    if len(data) != w * h + w * (h // 8) or h % 8:
        raise ValueError('picture: %d bytes, not %d lines of %d and their attributes' % (len(data), h, w))
    img, px = png_new(w * 8, h, 0, COLOURS)
    hidden = []
    for row in range(h // 8):
        for col in range(w):
            a, seen = data[w * h + row * w + col], set()
            for r in range(8):
                v = data[(row * 8 + r) * w + col]
                for b in range(8):
                    ink = (v >> (7 - b)) & 1
                    seen.add(ink)
                    px[col * 8 + b, row * 8 + r] = (a >> 7) * 32 + ink * 16 + ((a >> 6) & 1) * 8 + \
                        (a & 7 if ink else (a >> 3) & 7)
            if len(seen) < 2:
                hidden.append([row * w + col, a])
    return png_bytes(img, 'tx-cells', {'hidden': hidden})


def picture_in(name, raw):
    w, h = bitmaps_geometry(name)
    _img, px, meta = png_open(raw, 'tx-cells')
    hidden = dict((c, a) for c, a in meta['hidden'])
    bitmap, attrs = bytearray(w * h), bytearray()
    for row in range(h // 8):
        for col in range(w):
            ink_c = paper_c = flash = bright = 0
            for r in range(8):
                v = 0
                for b in range(8):
                    i = px[col * 8 + b, row * 8 + r]
                    v = v << 1 | (i >> 4) & 1
                    flash, bright = i >> 5, (i >> 3) & 1
                    if (i >> 4) & 1:
                        ink_c = i & 7
                    else:
                        paper_c = i & 7
                bitmap[(row * 8 + r) * w + col] = v
            c = row * w + col
            attrs.append(hidden[c] if c in hidden else flash << 7 | bright << 6 | paper_c << 3 | ink_c)
    return bytes(bitmap + attrs)


# ---------------------------------------------------------------------------------------------------------------
# rowpicture-NAME.bin: a row-packed picture (DrawRowPicture $8B03): each row a byte LEN << 4 | SKIP, then LEN bytes
# drawn SKIP bytes into the row; the next row 32 bytes on
# ---------------------------------------------------------------------------------------------------------------
def rowpicture_out(name, data):
    rows, i = [], 0
    while i < len(data) and i + 1 + (data[i] >> 4) <= len(data):
        rows.append([data[i] & 15, data[i] >> 4])
        i += 1 + (data[i] >> 4)
    width = max([s + n for s, n in rows] or [1])
    img, px = png_new(width * 8, max(len(rows), 1), 2, MONO)
    i = 0
    for y, (skip, n) in enumerate(rows):
        for k in range(n):
            v = data[i + 1 + k]
            for b in range(8):
                px[(skip + k) * 8 + b, y] = (v >> (7 - b)) & 1
        i += 1 + n
    return png_bytes(img, 'tx-rows', {'rows': rows, 'rest': data[i:].hex()})


def rowpicture_in(name, raw):
    _img, px, meta = png_open(raw, 'tx-rows')
    out = bytearray()
    for y, (skip, n) in enumerate(meta['rows']):
        out.append(n << 4 | skip)
        for k in range(n):
            v = 0
            for b in range(8):
                v = v << 1 | (px[(skip + k) * 8 + b, y] == 1)
            out.append(v)
    return bytes(out) + bytes.fromhex(meta['rest'])


# ---------------------------------------------------------------------------------------------------------------
# tables and texts
# ---------------------------------------------------------------------------------------------------------------
SIZE = {'u8': 1, 's8': 1, 'x8': 1, 'x16': 2, 'u16': 2}


def table_spec(name):
    key = re.sub(r'^.*/table-', '', name)[:-len('.bin')]
    if key not in TABLES:
        raise ValueError('table: no columns for %s in res_stage.TABLES' % key)
    return key, TABLES[key]


def table_out(name, data):
    key, cols = table_spec(name)
    size = sum(SIZE[k] for _, k in cols)
    if len(data) % size:
        raise ValueError('table %s: %d bytes, not rows of %d' % (key, len(data), size))
    lines = ['# %s: table %s, %d rows of %d bytes (tools/res_stage.py TABLES)' % (stage_of(name), key,
                                                                                 len(data) // size, size),
             'row,' + ','.join(c for c, _ in cols)]
    for r in range(len(data) // size):
        i, cells = r * size, []
        for _, k in cols:
            v = data[i] if SIZE[k] == 1 else data[i] | data[i + 1] << 8
            i += SIZE[k]
            cells.append(('%d' % (v - 256 if v > 127 else v)) if k == 's8' else
                         ('$%02X' % v) if k == 'x8' else ('$%04X' % v) if k == 'x16' else '%d' % v)
        lines.append('%d,' % r + ','.join(cells))
    return text_file(lines)


def table_in(name, raw):
    _key, cols = table_spec(name)
    out = bytearray()
    for ln in lines_of(raw)[1:]:
        cells = ln.split(',')[1:]
        for (_, k), c in zip(cols, cells):
            v = num(c)
            out += bytes([v & 255]) if SIZE[k] == 1 else bytes([v & 255, (v >> 8) & 255])
    return bytes(out)


def quote(bs):
    s = ''
    for b in bs:
        s += chr(b) if 32 <= b < 127 and b not in (34, 92) else '\\"' if b == 34 else '\\\\' if b == 92 else \
            '\\x%02X' % b
    return '"' + s + '"'


def unquote(s):
    s = s.strip()
    if not (s.startswith('"') and s.endswith('"')):
        raise ValueError('text: not a quoted line: %s' % s)
    s, out, i = s[1:-1], bytearray(), 0
    while i < len(s):
        if s[i] == '\\':
            if s[i + 1] == 'x':
                out.append(int(s[i + 2:i + 4], 16))
                i += 4
                continue
            out.append(ord(s[i + 1]))
            i += 2
            continue
        out.append(ord(s[i]))
        i += 1
    return bytes(out)


def text_out(name, data):
    lines = ['# %s: text, one quoted string a line (a line ends after a byte of $80 and up, $00 or $FF);' % stage_of(
        name), '# printable ASCII as itself, \\xNN any other byte; the build joins the lines']
    cur = bytearray()
    for b in data:
        cur.append(b)
        if b >= 0x80 or b == 0:
            lines.append(quote(cur))
            cur = bytearray()
    if cur:
        lines.append(quote(cur))
    return text_file(lines)


def text_in(name, raw):
    return b''.join(unquote(ln) for ln in lines_of(raw))


FORMATS = [
    (r'^stage\d/graphics\.bin$', '.txt', graphics_out, graphics_in),
    (r'^stage\d/tiles\.bin$', '.png', tiles_png_check_out, tiles_png_check_in),
    (r'^stage\d/rooms\.bin$', '.txt', rooms_out, rooms_in),
    (r'^stage\d/sprites-[a-z0-9-]+\.bin$', '.png', sprites_out, sprites_in),
    (r'^stage\d/bitmaps-[a-z0-9-]+-\d+x\d+\.bin$', '.png', bitmaps_out, bitmaps_in),
    (r'^stage\d/picture-[a-z0-9-]+-\d+x\d+\.bin$', '.png', picture_out, picture_in),
    (r'^stage\d/rowpicture-[a-z0-9-]+\.bin$', '.png', rowpicture_out, rowpicture_in),
    (r'^stage\d/table-[a-z0-9-]+\.bin$', '.csv', table_out, table_in),
    (r'^stage\d/text-[a-z0-9-]+\.bin$', '.txt', text_out, text_in),
]

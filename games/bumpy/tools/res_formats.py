#!/usr/bin/env python3
"""Bumpy's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of a part (the game, the screen).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against DIR       # ... and gives the bytes of DIR/<name>.bin

The formats (each folder's README.md lists its files, addresses and readers):
- screens/loading.png: the loading screen as colour cells: a PNG whose palette has 64 Spectrum entries, index =
  flash x 32 + ink x 16 + bright x 8 + colour; a cell that is all ink or all paper keeps its attribute in the PNG
  text chunk `tx-cells`.
- CPC sprites (sprites/*.png): the game's graphics are Amstrad CPC mode-1 bytes (4 pixels a byte, pen = bit 7-i
  of the byte + 2 x bit 3-i). An indexed PNG with pens 0-3 (0 black, 1 grey, 2 yellow, 3 white) and 4 for the grid
  between frames; the text chunk `tx-cpc` holds the frame width in bytes, the height, the frame count and the
  columns of the sheet. The Spectrum shows one plane of it (see sprites/README.md).
- Mono sprites (fonts/font.png): 0 paper, 1 ink, 2 grid, `tx-sheet` as in Terramex's tools.
- levels/levels.txt: the 100 level records as text grids (levels/README.md).
- texts/*.txt: UTF-8, one quoted string a line, `#` lines comments; printable ASCII as itself, `\\xNN` any other
  byte, `\\"` and `\\\\` escaped. The build joins the strings.
- tables/*.csv: a header line naming the columns, `#` lines comments, numbers decimal or `$hex`.
Any other file (leftovers/) stays its bytes.
"""
import argparse
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.startswith('#')]


def head(comments):
    return ['# ' + c if c else '#' for c in comments]


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


# ---------------------------------------------------------------------------------------------------------------
# Colour cells: 8 x 8 pixels with one attribute
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


PALETTE = []
for _i in range(64):
    PALETTE += zx_rgb(_i & 7, (_i >> 3) & 1)
GREY = 64
PALETTE += [128, 128, 128]


def new_png(w, h, fill, palette):
    from PIL import Image
    img = Image.new('P', (w, h), fill)
    img.putpalette(palette + [0] * (768 - len(palette)))
    return img, img.load()


def save(img, key, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text(key, json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def open_png(raw, key):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    return img, img.load(), json.loads(img.text[key])


def paint_cell(px, x0, y0, rows, attr):
    """8 pixel rows with one attribute at x0, y0; True when a colour is hidden (all ink or all paper)"""
    seen = set()
    for r in range(8):
        for bit in range(8):
            ink = (rows[r] >> (7 - bit)) & 1
            seen.add(ink)
            colour = attr & 7 if ink else (attr >> 3) & 7
            px[x0 + bit, y0 + r] = (attr >> 7) * 32 + ink * 16 + ((attr >> 6) & 1) * 8 + colour
    return len(seen) < 2


def read_cell(px, x0, y0, hidden_attr):
    """(8 pixel rows, the attribute) of the cell at x0, y0"""
    rows, ink_c, paper_c, flash, bright = [], 0, 0, 0, 0
    for r in range(8):
        b = 0
        for bit in range(8):
            i = px[x0 + bit, y0 + r]
            ink = (i >> 4) & 1
            b = b << 1 | ink
            flash, bright = i >> 5, (i >> 3) & 1
            if ink:
                ink_c = i & 7
            else:
                paper_c = i & 7
        rows.append(b)
    if hidden_attr is not None:
        return rows, hidden_attr
    return rows, flash << 7 | bright << 6 | paper_c << 3 | ink_c


def tiles_to_png(pixels, attrs, cols=16):
    """tiles of 8 bytes and their attributes as a colour sheet, cols a row, a grey line between them"""
    n = len(attrs)
    if len(pixels) != 8 * n:
        raise ValueError('tiles: %d pixel bytes for %d attributes' % (len(pixels), n))
    rows = (n + cols - 1) // cols
    img, px = new_png(1 + cols * 9, 1 + rows * 9, GREY, PALETTE)
    hidden = []
    for t in range(n):
        if paint_cell(px, 1 + (t % cols) * 9, 1 + (t // cols) * 9, pixels[8 * t:8 * t + 8], attrs[t]):
            hidden.append([t, attrs[t]])
    return save(img, 'tx-cells', {'tiles': n, 'cols': cols, 'hidden': hidden})


def png_to_tiles(raw):
    _img, px, meta = open_png(raw, 'tx-cells')
    hidden = {t: a for t, a in meta['hidden']}
    pixels, attrs = bytearray(), bytearray()
    for t in range(meta['tiles']):
        rows, a = read_cell(px, 1 + (t % meta['cols']) * 9, 1 + (t // meta['cols']) * 9, hidden.get(t))
        pixels += bytes(rows)
        attrs.append(a)
    return bytes(pixels), bytes(attrs)


def screen_to_png(data, thirds=3):
    """a screen (6912 bytes; or `thirds` thirds: 2048 x thirds pixel bytes, then 256 x thirds attributes) as a
    256-pixel-wide colour picture"""
    n = thirds * 256
    if len(data) != 9 * n:
        raise ValueError('screen: %d bytes, not %d' % (len(data), 9 * n))
    img, px = new_png(256, thirds * 64, GREY, PALETTE)
    hidden = []
    for c in range(n):
        cy, cx = divmod(c, 32)
        rows = [data[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] for r in range(8)]
        if paint_cell(px, cx * 8, cy * 8, rows, data[8 * n + c]):
            hidden.append([c, data[8 * n + c]])
    return save(img, 'tx-cells', {'thirds': thirds, 'hidden': hidden})


def png_to_screen(raw):
    _img, px, meta = open_png(raw, 'tx-cells')
    hidden = {c: a for c, a in meta['hidden']}
    n = meta.get('thirds', 3) * 256
    out = bytearray(9 * n)
    for c in range(n):
        cy, cx = divmod(c, 32)
        rows, a = read_cell(px, cx * 8, cy * 8, hidden.get(c))
        for r in range(8):
            out[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] = rows[r]
        out[8 * n + c] = a
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Mono sprites
# ---------------------------------------------------------------------------------------------------------------
MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]


def sprite_bit(order, w, h, x, y):
    """(byte offset in the frame, bit mask) of pixel x, y: 'columns' = column after column of h bytes, top first;
    'rows' = line after line of w / 8 bytes"""
    if order == 'columns':
        return (x // 8) * h + y, 0x80 >> (x % 8)
    return y * (w // 8) + x // 8, 0x80 >> (x % 8)


def sprites_to_png(data, w, h, order, cols):
    size = w * h // 8
    if len(data) % size:
        raise ValueError('sprites: %d bytes is no whole number of %d-byte frames' % (len(data), size))
    n = len(data) // size
    rows = (n + cols - 1) // cols
    img, px = new_png(1 + min(n, cols) * (w + 1), 1 + rows * (h + 1), 2, MONO)
    for f in range(n):
        x0, y0 = 1 + (f % cols) * (w + 1), 1 + (f // cols) * (h + 1)
        for y in range(h):
            for x in range(w):
                o, m = sprite_bit(order, w, h, x, y)
                px[x0 + x, y0 + y] = 1 if data[f * size + o] & m else 0
    return save(img, 'tx-sheet', {'w': w, 'h': h, 'order': order, 'cols': cols, 'frames': n})


def png_to_sprites(raw):
    _img, px, m = open_png(raw, 'tx-sheet')
    w, h, size = m['w'], m['h'], m['w'] * m['h'] // 8
    out = bytearray(size * m['frames'])
    for f in range(m['frames']):
        x0, y0 = 1 + (f % m['cols']) * (w + 1), 1 + (f // m['cols']) * (h + 1)
        for y in range(h):
            for x in range(w):
                if px[x0 + x, y0 + y] == 1:
                    o, bit = sprite_bit(m['order'], w, h, x, y)
                    out[f * size + o] |= bit
    return bytes(out)


def sprites(w, h, order, cols):
    return '.png', lambda d: sprites_to_png(d, w, h, order, cols), png_to_sprites


# ---------------------------------------------------------------------------------------------------------------
GLYPHS = {}  # Bumpy's own font (Font, $F5C9): codes 32-122 print as ASCII; 123-127 are HUD icons, written \xNN
CODES = {v: k for k, v in GLYPHS.items()}


def quote(bs):
    out = ''
    for b in bs:
        c = chr(b)
        if b in GLYPHS:
            out += GLYPHS[b]
        else:
            out += '\\"' if c == '"' else '\\\\' if c == '\\' else c if 32 <= b < 127 else '\\x%02X' % b
    return '"' + out + '"'


def unquote(s):
    s = s.strip()
    if len(s) < 2 or s[0] != '"' or s[-1] != '"':
        raise ValueError('text: not a quoted line: %r' % s)
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
        out.append(CODES.get(s[i], ord(s[i])))
        i += 1
    return bytes(out)


def split_after(ends):
    def f(d):
        out, cur = [], bytearray()
        for b in d:
            cur.append(b)
            if b in ends:
                out.append(bytes(cur))
                cur = bytearray()
        return out + ([bytes(cur)] if cur else [])
    return f


def text(comments, ends=(0x00, 0x0D)):
    """a text, one quoted line a piece ending in one of ends ($0D a new line, $00 the end, \\x0D written)"""
    return ('.txt', lambda d: text_file(head(comments) + [quote(p) for p in split_after(ends)(d)]),
            lambda raw: b''.join(unquote(ln) for ln in lines_of(raw)))


def cell(v, kind):
    if kind == 'hex':
        return '$%02X' % v
    if kind == 'signed':
        return str(v - 256 if v > 127 else v)
    return str(v)


def table(columns, comments, index=None, kinds=None):
    """records of one byte a column as CSV with a header; index: a first column numbering the records (written, not
    read back); kinds: column -> 'hex' / 'signed' / 'dec' (default 'hex')"""
    kinds = kinds or {}

    def out(d):
        n = len(columns)
        if len(d) % n:
            raise ValueError('table: %d bytes is no whole number of %d-byte records' % (len(d), n))
        lines = head(comments) + [','.join(([index] if index else []) + columns)]
        for r in range(len(d) // n):
            cells = [cell(d[r * n + i], kinds.get(c, 'hex')) for i, c in enumerate(columns)]
            lines.append(','.join(([str(r)] if index else []) + cells))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        for ln in lines_of(raw)[1:]:
            vals = ln.split(',')[1 if index else 0:]
            d += bytes(num(v) & 255 for v in vals)
        return bytes(d)

    return '.csv', out, back


def lists(comments, end=0xFF, kind='hex'):
    """lists that end in `end` (frame lists, tile lists), one a line; bytes after the last end on a line of their own"""
    def out(d):
        parts = split_after((end,))(d) if end is not None else [d[i:i + 16] for i in range(0, len(d), 16)]
        return text_file(head(comments) + [' '.join(cell(b, kind) for b in p) for p in parts])
    return '.txt', out, lambda raw: bytes(num(x) & 255 for ln in lines_of(raw) for x in ln.split())




# ---------------------------------------------------------------------------------------------------------------
# CPC mode-1 sprites: 4 pixels a byte, two planes
# ---------------------------------------------------------------------------------------------------------------
CPC = [0, 0, 0, 96, 96, 96, 255, 255, 0, 255, 255, 255, 64, 64, 160]


def cpc_to_png(data, w, h, cols):
    """frames of w bytes x h lines (4w x h pixels), cols frames a row, a grid line (index 4) between them"""
    size = w * h
    if not data or len(data) % size:
        raise ValueError('cpc: %d bytes is no whole number of %d-byte frames' % (len(data), size))
    n = len(data) // size
    rows = (n + cols - 1) // cols
    img, px = new_png(1 + min(n, cols) * (4 * w + 1), 1 + rows * (h + 1), 4, CPC)
    for f in range(n):
        x0, y0 = 1 + (f % cols) * (4 * w + 1), 1 + (f // cols) * (h + 1)
        for y in range(h):
            for x in range(w):
                b = data[f * size + y * w + x]
                for i in range(4):
                    px[x0 + 4 * x + i, y0 + y] = ((b >> (7 - i)) & 1) | (((b >> (3 - i)) & 1) << 1)
    return save(img, 'tx-cpc', {'w': w, 'h': h, 'frames': n, 'cols': cols})


def png_to_cpc(raw):
    _img, px, m = open_png(raw, 'tx-cpc')
    w, h, cols = m['w'], m['h'], m['cols']
    out = bytearray()
    for f in range(m['frames']):
        x0, y0 = 1 + (f % cols) * (4 * w + 1), 1 + (f // cols) * (h + 1)
        for y in range(h):
            for x in range(w):
                b = 0
                for i in range(4):
                    p = px[x0 + 4 * x + i, y0 + y]
                    if p > 3:
                        raise ValueError('cpc: pixel %d,%d of frame %d is the grid colour' % (4 * x + i, y, f))
                    b |= (p & 1) << (7 - i) | ((p >> 1) & 1) << (3 - i)
                out.append(b)
    return bytes(out)


def cpc(w, h, cols=8):
    return '.png', lambda d: cpc_to_png(d, w, h, cols), png_to_cpc


# ---------------------------------------------------------------------------------------------------------------
# Levels: 100 records of 75 bytes (LevelRecords $8C3C)
# ---------------------------------------------------------------------------------------------------------------
LEVELS, RECORD, CELLS, COLS = 100, 75, 36, 6
LEVEL_HELP = [
    'Bumpy levels: 100 records of 75 bytes at LevelRecords $8C3C (tools/res_formats.py; levels/README.md).',
    'Each level: a line "level NN start C exit C prizes N", then 6 lines, one a row of the screen, top first:',
    'six platforms (hex digit, . for 0) | six walls (digit, . for 0; the wall on the right of the cell) |',
    'six objects (two hex digits, .. for 0). Cells count 0-35 left to right, top to bottom (cell = 6 x row + col).',
    'Record: +0..+35 cells (wall << 4 | platform), +36 the ball\'s start cell, +37 the prizes to take, +38 the',
    'cell the exit appears in, +39..+74 the object in each cell.']


def levels_out(d):
    if len(d) != LEVELS * RECORD:
        raise ValueError('levels: %d bytes, not %d' % (len(d), LEVELS * RECORD))
    lines = head(LEVEL_HELP)
    for lv in range(LEVELS):
        r = d[lv * RECORD:(lv + 1) * RECORD]
        lines.append('level %02d start %d exit %d prizes %d' % (lv, r[36], r[38], r[37]))
        for row in range(6):
            cells = r[row * COLS:(row + 1) * COLS]
            objs = r[39 + row * COLS:39 + (row + 1) * COLS]
            plat = ' '.join('%X' % (c & 15) if c & 15 else '.' for c in cells)
            wall = ' '.join('%X' % (c >> 4) if c >> 4 else '.' for c in cells)
            obj = ' '.join('%02X' % o if o else '..' for o in objs)
            lines.append('  %s | %s | %s' % (plat, wall, obj))
    return text_file(lines)


def levels_in(raw):
    out, lns, i = bytearray(), lines_of(raw), 0
    while i < len(lns):
        t = lns[i].split()
        if t[0] != 'level' or t[2] != 'start' or t[4] != 'exit' or t[6] != 'prizes':
            raise ValueError('levels: expected a level line, got %r' % lns[i])
        cells, objs = [], []
        for row in lns[i + 1:i + 7]:
            p, w, o = (s.split() for s in row.split('|'))
            if len(p) != 6 or len(w) != 6 or len(o) != 6:
                raise ValueError('levels: level %s: a row of %d/%d/%d cells' % (t[1], len(p), len(w), len(o)))
            cells += [(0 if b == '.' else int(b, 16)) << 4 | (0 if a == '.' else int(a, 16)) for a, b in zip(p, w)]
            objs += [0 if x == '..' else int(x, 16) for x in o]
        out += bytes(cells) + bytes([int(t[3]), int(t[7]), int(t[5])]) + bytes(objs)
        i += 7
    return bytes(out)


def levels_parse(raw):
    """[{level, start, exit, prizes, cells[36] (wall << 4 | platform), objects[36]}] of levels.txt (fig_levels.py)"""
    d = levels_in(raw)
    return [{'level': lv, 'cells': list(d[lv * RECORD:lv * RECORD + 36]), 'start': d[lv * RECORD + 36],
             'prizes': d[lv * RECORD + 37], 'exit': d[lv * RECORD + 38],
             'objects': list(d[lv * RECORD + 39:lv * RECORD + 75])} for lv in range(len(d) // RECORD)]


def split_before(code):
    def f(d):
        out, cur = [], bytearray()
        for b in d:
            if b == code and cur:
                out.append(bytes(cur))
                cur = bytearray()
            cur.append(b)
        return out + ([bytes(cur)] if cur else [])
    return f


def printtext(comments):
    """a PrintText string ($E667): a line before each AT ($16), the $00 end on the last line"""
    return ('.txt', lambda d: text_file(head(comments) + [quote(p) for p in split_before(0x16)(d)]),
            lambda raw: b''.join(unquote(ln) for ln in lines_of(raw)))


def fixed(comments, n):
    """strings of n bytes, one a line"""
    return ('.txt', lambda d: text_file(head(comments) + [quote(d[i:i + n]) for i in range(0, len(d), n)]),
            lambda raw: b''.join(unquote(ln) for ln in lines_of(raw)))


def letters(comments):
    """the editor's strings: A = 1 ... Z = 26, a space 0? no: each string ends in $00; one a line, letters as
    themselves, any other byte \\xNN"""
    def enc(p):
        return '"' + ''.join(chr(64 + b) if 1 <= b <= 26 else '\\x%02X' % b for b in p) + '"'

    def dec(ln):
        t = unquote(ln)
        return bytes(b - 64 if 65 <= b <= 90 else b for b in t)
    return ('.txt', lambda d: text_file(head(comments) + [enc(p) for p in split_after((0,))(d)]),
            lambda raw: b''.join(dec(ln) for ln in lines_of(raw)))


def records(comments, size):
    """records of `size` bytes: the text up to and with its $00 quoted, the rest as hex bytes"""
    def out(d):
        lines = head(comments)
        for i in range(0, len(d), size):
            r = d[i:i + size]
            k = r.index(0) + 1
            lines.append(quote(r[:k]) + ' ' + ' '.join('$%02X' % b for b in r[k:]))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        for ln in lines_of(raw):
            q = ln.rindex('"') + 1
            d += unquote(ln[:q]) + bytes(num(x) & 255 for x in ln[q:].split())
        return bytes(d)
    return '.txt', out, back


def words(column, comments, index):
    """little-endian words as CSV: the index (written, not read back) and the word in hex"""
    def out(d):
        lines = head(comments) + [index + ',' + column]
        for i in range(len(d) // 2):
            lines.append('%d,$%04X' % (i, d[2 * i] | d[2 * i + 1] << 8))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        for ln in lines_of(raw)[1:]:
            v = num(ln.split(',')[1])
            d += bytes((v & 255, v >> 8))
        return bytes(d)
    return '.csv', out, back


GROUPS = {}

# .bin name -> (suffix, to_editable(bytes), from_editable(raw))
SINGLES = {
    'screens/loading.bin': ('.png', screen_to_png, png_to_screen),
    'levels/levels.bin': ('.txt', levels_out, levels_in),
    'fonts/font.bin': ('.png', lambda d: sprites_to_png(d, 8, 8, 'rows', 16), png_to_sprites),
    'sprites/editor-font.bin': ('.png', lambda d: sprites_to_png(d, 8, 5, 'rows', 13), png_to_sprites),
    'sprites/sides.bin': cpc(2, 192, 2),
    'sprites/exit-sign.bin': cpc(8, 7, 2),
    'sprites/ball.bin': cpc(4, 10, 16),
    'sprites/objects.bin': cpc(4, 14, 10),
    'sprites/platform-1.bin': cpc(8, 47, 1),
    'sprites/platform-2.bin': cpc(8, 47, 1),
    'sprites/platform-3.bin': cpc(6, 39, 1),
    'sprites/platform-4.bin': cpc(4, 32, 1),
    'sprites/platform-5.bin': cpc(8, 47, 1),
    'sprites/spikes.bin': cpc(6, 7, 1),
    'sprites/crumble-8.bin': cpc(8, 4, 1),
    'sprites/crumble-6.bin': cpc(6, 4, 3),
    'sprites/crumble-4.bin': cpc(4, 4, 3),
    'sprites/crumble-2.bin': cpc(2, 4, 3),
    'sprites/crumble-bits.bin': cpc(2, 5, 4),
    'sprites/walls.bin': cpc(2, 24, 13),
    'sprites/exit-mark.bin': cpc(1, 9, 1),
    'sprites/exit.bin': cpc(6, 5, 4),
    'sprites/fire.bin': cpc(6, 5, 3),
    'sprites/steam.bin': cpc(6, 11, 1),
    'sprites/steam-small.bin': cpc(4, 3, 1),
    'sprites/burst.bin': cpc(4, 14, 6),
    'sprites/bricks.bin': cpc(8, 8, 1),
    'sprites/logo.bin': cpc(18, 60, 1),
    'sprites/panel.bin': cpc(18, 200, 1),
    'texts/menu.bin': printtext(['The menu (MenuText, PrintText $E667): $16 AT row col, $01/$02 single/double height,',
                                 '$10 INK, $13 BRIGHT, $00 the end.']),
    'texts/menu-backdrop.bin': printtext(['The menu backdrop (PrintText $E667); $14 n sets the attribute.']),
    'texts/hall-of-fame-title.bin': printtext(['The hall of fame screen\'s frame and title (PrintText $E667);',
                                               '$09 moves one column on.']),
    'texts/once-upon-a-time.bin': printtext(['"Erase Una Vez ...", never printed: $1F is the CPC firmware\'s LOCATE',
                                             '(PrintOnceUponATime $E7C6, unrun).']),
    'texts/players.bin': fixed(['The menu\'s option 1: two 16-byte strings (one player, two players).'], 16),
    'texts/editor.bin': letters(['The CPC level editor\'s menu, never read on the Spectrum: letters A = 1 ... Z = 26,',
                                 'each string ending in $00.']),
    'tables/hall-of-fame.bin': records(['The hall of fame: 4 records of 32 bytes: the PrintText line ($16 row col,',
                                        '$14 attr, $02 double height, name, " : ", five digits, $00), then the score',
                                        'word and 12 zero bytes.'], 32),
    'tables/object-inks.bin': table(['attr'], ['ObjectInks $C6F6: the attribute each object kind is drawn in',
                                               '(kind 0 never read).'], index='kind'),
    'tables/demo-moves.bin': table(['move'], ['DemoMoves $D25A: the demo\'s decisions, one a landing: 0-5 the next',
                                              'state, 9 arm the spring (byte 0 never read).'], index='index',
                                   kinds={'move': 'dec'}),
    'tables/level-colours.bin': table(['pen1', 'pen2', 'pen3'], ['LevelColours $E119: the CPC firmware inks (0-26)',
                                                                 'of pens 1-3 by level mod 7 + 1 (row 0 never',
                                                                 'read); a RET on the Spectrum.'], index='row',
                                      kinds={'pen1': 'dec', 'pen2': 'dec', 'pen3': 'dec'}),
    'tables/brick-steps.bin': table(['layers'], ['BrickSteps $E1C1: the brick layer count the rising ball touches',
                                                 'at each up step.'], index='step', kinds={'layers': 'dec'}),
    'tables/control-sets.bin': table(['up', 'down', 'left', 'right', 'fire', 'fire2', 'pause', 'quit'],
                                     ['The control sets (KeyboardKeys $F092): key codes row x 8 + bit (row 8 the',
                                      'Kempston byte); sets: keyboard, Kempston, Sinclair.'], index='set'),
    'tables/cell-addresses.bin': words('address', ['CellAddresses $E131: the CPC screen address of each cell'],
                                       'cell'),
    'tables/wall-addresses.bin': words('address', ['WallAddresses $E179: the CPC screen address of the wall',
                                                   'right of each cell (0: none)'], 'cell'),
}


def group_of(name):
    for ed, (bins, _to, _from) in GROUPS.items():
        if name in bins:
            return ed
    return None


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def install(files):
    done = set()
    for ed, (bins, to_ed, from_ed) in GROUPS.items():
        if not all(b in files for b in bins):
            continue
        part = {b: files[b] for b in bins}
        out = to_ed(part)
        if from_ed(out) != part:
            raise SystemExit('res: %s does not convert back to its bytes' % ed)
        write(os.path.join(RES, ed), out)
        done |= set(bins)
    for name, data in files.items():
        if name in done:
            continue
        if group_of(name):
            raise SystemExit('res: %s is part of %s, whose other resources were not given' % (name, group_of(name)))
        if name in SINGLES:
            suffix, to_ed, from_ed = SINGLES[name]
            out = to_ed(data)
            if from_ed(out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            write(os.path.join(RES, os.path.splitext(name)[0] + suffix), out)
        else:
            write(os.path.join(RES, name), data)


def sources():
    """(src path, rel, kind) for every file of src/res: kind 'group', 'single' or None (bytes)"""
    for top, _dirs, names in sorted(os.walk(RES)):
        for f in sorted(names):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            if rel in GROUPS:
                yield src, rel, 'group'
            elif not rel.endswith('.bin') and os.path.splitext(rel)[0] + '.bin' in SINGLES:
                yield src, rel, 'single'
            else:
                yield src, rel, None


def to_bytes(rel, kind, raw):
    """{bin name: bytes} of one src/res file"""
    if kind == 'group':
        return GROUPS[rel][2](raw)
    if kind == 'single':
        name = os.path.splitext(rel)[0] + '.bin'
        return {name: SINGLES[name][2](raw)}
    return {rel: raw}


def build(out):
    for src, rel, kind in sources():
        for name, data in to_bytes(rel, kind, open(src, 'rb').read()).items():
            write(os.path.join(out, name), data)


def check(against=None):
    bad = count = 0
    for src, rel, kind in sources():
        raw = open(src, 'rb').read()
        data = {}
        if kind:
            count += 1
            try:
                data = to_bytes(rel, kind, raw)
                if kind == 'group':
                    again = GROUPS[rel][1](data)
                else:
                    (name, d), = data.items()
                    again = SINGLES[name][1](d)
                ok = again == raw and to_bytes(rel, kind, again) == data
            except (ValueError, KeyError, IndexError) as e:
                print('res: %s: %s' % (src, e))
                ok = False
            if not ok:
                print('res: %s does not round-trip' % os.path.relpath(src, ROOT))
                bad += 1
        else:
            data = {rel: raw}
        for name, d in data.items():
            ref = os.path.join(against, name) if against else None
            if ref and os.path.exists(ref) and open(ref, 'rb').read() != d:
                print('res: %s differs from %s' % (os.path.relpath(src, ROOT), ref))
                bad += 1
    print('res: %d editable files, %d bad' % (count, bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--against')
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    return check(args.against)


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of a part (the game or one of the tape's parts).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against DIR       # ... and gives the bytes of DIR/<name>.bin

The formats (each folder's README.md lists its files, addresses and readers):
- Colour cells (tiles/*.png, screens/*.png): a colour PNG whose palette has 64 Spectrum entries, index = flash x 32
  + ink x 16 + bright x 8 + colour, and grey (64) for the grid. Each pixel shows its colour and says by its index
  whether it is ink or paper, so pixels and attribute come back exactly. A cell whose 64 pixels are all paper (or all
  ink) cannot show its other colour: the PNG text chunk `tx-cells` keeps those cells' attributes. A tile sheet is
  one PNG built from two resources, the pixel bytes (8 a tile) and the attribute bytes (1 a tile): a group.
- Mono sprites (sprites/*.png): an indexed PNG, 0 paper (black), 1 ink (white), 2 grid (grey), the frames in a grid;
  the text chunk `tx-sheet` holds the frame size, the byte order and the count.
- rooms/rooms.txt: the rooms as text, a group of three resources (the back-tile grids, the room records, the list of
  the rooms on the alternate tile set): each room a header, 4 lines of 8 back-tile indices and its record.
- rooms/backtiles.txt: the back-tiles, each a line of 4 x 4 tile indices (hex), `|` between the rows.
- texts/*.txt: UTF-8, one quoted string a line, `#` lines comments; printable ASCII as itself, `\\xNN` any other byte,
  `\\"` and `\\\\` escaped. The build joins the strings.
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
# Rooms and back-tiles
# ---------------------------------------------------------------------------------------------------------------
ROOMS = 72          # 70 rooms on the map and two more ($46, $47) in both tables
RECORD = 12         # RoomCreatures: 3 creature records of 4 bytes a room
CREATURE_TYPES = ['none', 'walker', 'climber', 'leftflier', 'rightflier', 'drop', 'still', 'riser', 'scenery']


def creature_text(rec):
    """one 4-byte RoomCreatures record as words: type, frame, x, y, dir, hit, hitframe"""
    if not any(rec):
        return '-'
    t = rec[0] & 15
    name = CREATURE_TYPES[t] if t < len(CREATURE_TYPES) else 'type%d' % t
    return '%s frame=$%02X x=$%02X y=$%02X dir=%d hit=%d hitframe=%d' % (
        name, rec[1], rec[2], rec[3] & 0x7F, rec[3] >> 7, rec[0] >> 7, (rec[0] >> 4) & 7)


def creature_bytes(words):
    if words == ['-']:
        return bytes(4)
    t = CREATURE_TYPES.index(words[0]) if words[0] in CREATURE_TYPES else int(words[0][4:])
    v = dict(w.split('=') for w in words[1:])
    return bytes([num(v['hit']) << 7 | num(v['hitframe']) << 4 | t, num(v['frame']), num(v['x']),
                  num(v['dir']) << 7 | num(v['y'])])


def rooms_out(bins):
    grids, table, alt = bins['rooms/grids.bin'], bins['rooms/table.bin'], bins['rooms/alt-rooms.bin']
    if len(grids) != ROOMS * 32 or len(table) != ROOMS * RECORD:
        raise ValueError('rooms: %d grid bytes, %d record bytes' % (len(grids), len(table)))
    out = head([
        'The rooms of Terramex (tools/res_formats.py; src/res/rooms/README.md). Room R = level x 12 + column.',
        'The rooms drawn with the alternate tiles $80-$FF (RoomsOnAltTiles), in the order of their list:',
    ])
    out.append('alternate ' + ' '.join('$%02X' % r for r in alt))
    out += head(['',
                 'Each room: its header; 4 lines of 8 back-tile indices (RoomGrids, hex; back-tiles in backtiles.txt);',
                 'its three creatures (RoomCreatures, one line each, "-" an empty record): the type (CreatureHandlers),',
                 'the first sprite frame of its animation, the start X and Y, dir 1 = moving right or down; hit 0 =',
                 'never hits (types 1-4, 6, 7), hit 1 with hitframe 4 or more = every frame, else at the frame',
                 'index = hitframe (AnimateCreature); the drop (type 5) always tests (JP HitExplorer at $C037).'])
    for r in range(ROOMS):
        lv, col = divmod(r, 12)
        out.append('')
        out.append('room $%02X level %d column %d%s' % (r, lv, col, ' alternate' if r in alt else ''))
        for row in range(4):
            out.append('  ' + ' '.join('%02X' % b for b in grids[r * 32 + row * 8:r * 32 + row * 8 + 8]))
        for k in range(3):
            out.append('  creature ' + creature_text(table[r * RECORD + 4 * k:r * RECORD + 4 * k + 4]))
    return text_file(out)


def rooms_in(raw):
    grids, table, alt = bytearray(), bytearray(), b''
    for ln in lines_of(raw):
        f = ln.split()
        if f[0] == 'alternate':
            alt = bytes(num(x) for x in f[1:])
        elif f[0] == 'room':
            pass
        elif f[0] == 'creature':
            table += creature_bytes(f[1:])
        else:
            grids += bytes(int(x, 16) for x in f)
    return {'rooms/grids.bin': bytes(grids), 'rooms/table.bin': bytes(table), 'rooms/alt-rooms.bin': alt}


def backtiles_out(d):
    out = head(['The back-tiles (BackTiles $C600): each 4 x 4 tile indices (hex), the rows split by |; tile indices',
                'from $80 come from the upper half of the tile set (tiles/base.png, or tiles/alt.png in the',
                'alternate rooms).'])
    for b in range(len(d) // 16):
        rows = [' '.join('%02X' % x for x in d[b * 16 + r * 4:b * 16 + r * 4 + 4]) for r in range(4)]
        out.append('%02X: %s' % (b, ' | '.join(rows)))
    return text_file(out)


def backtiles_in(raw):
    out = bytearray()
    for ln in lines_of(raw):
        out += bytes(int(x, 16) for x in ln.split(':', 1)[1].replace('|', ' ').split())
    return bytes(out)


def hexgrid(per_line, comments):
    """bytes as hex, per_line a line (a tile map, a leftover)"""
    def out(d):
        return text_file(head(comments) + [' '.join('%02X' % b for b in d[i:i + per_line])
                                           for i in range(0, len(d), per_line)])
    return '.txt', out, lambda raw: bytes(int(x, 16) for ln in lines_of(raw) for x in ln.split())


# ---------------------------------------------------------------------------------------------------------------
# Texts and tables
# ---------------------------------------------------------------------------------------------------------------
GLYPHS = {0x7F: '©'}  # the Spectrum's character set: $7F is the copyright sign
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


def item_places(comments):
    """ItemPlaces: [room + taken bit 7, item + X bits 3-5 in bits 5-7, X bits 6-7 in bits 0-1 + Y / 8 in bits 2-7];
    PlaceItem $B95F: X = (byte 2 AND 3) x 64 + (byte 1 AND $E0) / 4, Y = (byte 2 AND $FC) x 2 (ADD A,A: mod 256)"""
    cols = ['record', 'room', 'taken', 'item', 'x', 'y', 'name']

    def out(d):
        lines = head(comments) + [','.join(cols)]
        for r in range(len(d) // 3):
            b0, b1, b2 = d[3 * r:3 * r + 3]
            x, y = (b2 & 3) * 64 + (b1 & 0xE0) // 4, (b2 >> 2) * 8
            lines.append('%d,$%02X,%d,%d,$%02X,$%02X,%s' % (r, b0 & 0x7F, b0 >> 7, b1 & 31, x, y, ITEM_NAMES[b1 & 31]))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        for ln in lines_of(raw)[1:]:
            _r, room, taken, item, x, y = ln.split(',')[:6]
            x, y = num(x), num(y)
            if x & 7 or y & 7 or x > 255 or y > 511:
                raise ValueError('item-places: X and Y must be multiples of 8 (X below 256, Y below 512): %s' % ln)
            d += bytes([num(taken) << 7 | num(room), num(item) | (x >> 3 & 7) << 5, (x >> 6) | (y >> 3) << 2])
        return bytes(d)

    return '.csv', out, back


ITEM_NAMES = ['Unicycle', 'Flashgun', 'Cricket Ball', 'Spurs', 'Beer Barrel', 'Umbrella', 'Bellows',
              'Party Manifesto', 'Cannon', 'Barrel Medium', 'Vacuum Cleaner', 'ACME Bridge', 'Flute', 'Silver Lining',
              'Spring', 'Formula', 'Switch', 'Button', 'Battery', 'Coat Hanger', 'Trampoline', 'Atomic Pile',
              'Anti Rad. Pills', 'Cup of tea', 'Energy Crystal', 'Basket', 'Balloon', 'Barrel Big', 'Barrel Small',
              'Silver Cross', 'Basket 2', 'Lift']


def third_to_png(pixels, attrs):
    """a screen third (2048 pixel bytes in the screen's layout, 256 attributes) as a 256 x 64 colour picture"""
    return screen_to_png(bytes(pixels) + bytes(attrs), 1)


def png_to_third(raw):
    data = png_to_screen(raw)
    return data[0:2048], data[2048:2304]


# ---------------------------------------------------------------------------------------------------------------
# The music (RAM 6): the tunes as text
# ---------------------------------------------------------------------------------------------------------------
TUNES_AT = 0xC967            # TuneTable in RAM 6; the file runs to the last pattern ($CD35)
TUNE_BLOCKS = [  # (name, kind) in address order: the music part's entries (src/music/music.ann)
    ('TuneTable', 'tunes'), ('Tune0OrderA', 'order'), ('Tune0OrderB', 'order'), ('Tune0OrderC', 'order'),
    ('Tune1OrderA', 'order'), ('Tune1OrderB', 'order'), ('Tune1OrderC', 'order'), ('TuneSpare', 'bytes'),
    ('PatternLo', 'lo'), ('PatternHi', 'hi')] + [('Pattern%d' % n, 'pattern') for n in range(27)]
NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note_name(n):
    midi = n + 32  # period-table index n + 20 = MIDI + 12 (MUS.md)
    return '%s%d' % (NOTE_NAMES[midi % 12], midi // 12 - 1)


def tune_events(kind, d):
    """[(words, bytes)] of a block; a byte that starts no whole event becomes `byte $XX`"""
    out, i = [], 0
    while i < len(d):
        b, rest = d[i], len(d) - i - 1
        if kind == 'order':
            if b < 0x80:
                ev = ('pattern %d' % b, 1)
            elif b < 0xA0 and rest >= 1:
                ev = ('transpose %d%s' % (d[i + 1] - 256 if d[i + 1] > 127 else d[i + 1],
                                          '' if b == 0x80 else ' cmd=$%02X' % b), 2)
            elif 0xA0 <= b < 0xC0:
                ev = ('repeat %d' % (b & 31), 1)
            elif 0xC0 <= b < 0xE0 and rest >= 1:
                ev = ('detune %d%s' % (d[i + 1], '' if b == 0xC0 else ' cmd=$%02X' % b), 2)
            elif 0xE0 <= b < 0xFF and rest >= 1:
                ev = ('slot %d %d' % (b & 31, d[i + 1]), 2)
            elif b == 0xFF:
                ev = ('end', 1)
            else:
                ev = ('byte $%02X' % b, 1)
        else:  # pattern
            if b < 0x80 and rest >= 1:
                ev = ('note %d %d ; %s' % (b, d[i + 1], note_name(b)), 2)
            elif b == 0xA0 and rest >= 1:
                ev = ('rest %d' % d[i + 1], 1 + 1)
            elif 0x80 <= b < 0x90:
                ev = ('instr %d' % (b & 15), 1)
            elif 0x90 <= b < 0xA0 or 0xA1 <= b < 0xBF:
                ev = ('arp $%02X' % b, 1)
            elif b == 0xBF:
                ev = ('slideoff', 1)
            elif 0xC0 <= b < 0xFF and rest >= 3:
                ev = ('slide $%02X %d %d' % (b, d[i + 1] | d[i + 2] << 8, d[i + 3]), 4)
            elif b == 0xFF:
                ev = ('end', 1)
            else:
                ev = ('byte $%02X' % b, 1)
        out.append(ev[0])
        i += ev[1]
    return out


def tune_bytes(kind, words):
    w = words[0]
    a = [num(x) if x[0] in '$0123456789-' else x for x in words[1:]]
    if w == 'byte':
        return bytes([a[0]])
    if w == 'end':
        return b'\xff'
    if kind == 'order':
        if w == 'pattern':
            return bytes([a[0]])
        if w in ('transpose', 'detune'):
            cmd = 0x80 if w == 'transpose' else 0xC0
            if len(words) > 2:
                cmd = num(words[2].split('=')[1])
            return bytes([cmd, a[0] & 255])
        if w == 'repeat':
            return bytes([0xA0 | a[0]])
        if w == 'slot':
            return bytes([0xE0 | a[0], a[1]])
    else:
        if w == 'note':
            return bytes([a[0], a[1]])
        if w == 'rest':
            return bytes([0xA0, a[0]])
        if w == 'instr':
            return bytes([0x80 | a[0]])
        if w == 'arp':
            return bytes([a[0]])
        if w == 'slideoff':
            return b'\xbf'
        if w == 'slide':
            return bytes([a[0], a[1] & 255, a[1] >> 8, a[2]])
    raise ValueError('tunes: %r in a %s block' % (' '.join(words), kind))


def tunes_split(d, starts):
    """the blocks' bytes, given their start addresses (the music part's entries)"""
    ends = starts[1:] + [TUNES_AT + len(d)]
    return [d[a - TUNES_AT:e - TUNES_AT] for a, e in zip(starts, ends)]


def tunes_out(d):
    # the block starts: TuneTable 24 bytes, the order lists and patterns found through the pointers
    table = [d[i] | d[i + 1] << 8 for i in range(0, 24, 2)]
    lo_at, hi_at = 0xCA37, 0xCA52
    pats = [d[lo_at - TUNES_AT + n] | d[hi_at - TUNES_AT + n] << 8 for n in range(27)]
    orders = sorted(set(table))
    starts = [TUNES_AT] + orders + [0xCA35, lo_at, hi_at] + pats
    if starts != sorted(starts) or len(set(starts)) != len(starts) or len(orders) != 6:
        raise ValueError('tunes: the pointers do not give the expected layout')
    names = {a: n for a, (n, _k) in zip(starts, TUNE_BLOCKS)}
    blocks = tunes_split(d, starts)
    out = head(['The tunes of the AY player (src/music/music.ann; MUS format in src/res/music/README.md): the blocks in',
                'address order from TuneTable $C967. TuneTable: four tunes, each the order lists of channels A B C;',
                'PatternLo/PatternHi: the 27 patterns. Order lists: pattern N, transpose T, repeat N (the next',
                'pattern N times), detune D, slot N R (SlotTable[8 x channel + N] = R), end. Patterns: note N D',
                '(D frames; the name at transpose 0 after ";"), rest D, instr N, arp $XX, slideoff,',
                'slide $CMD STEP COUNT, end. byte $XX: a byte that starts no event.'])
    for (name, kind), blk in zip(TUNE_BLOCKS, blocks):
        out.append('')
        out.append('block ' + name)
        if kind == 'tunes':
            for t in range(4):
                out.append('  tune %d %s' % (t, ' '.join(names[table[3 * t + c]] for c in range(3))))
        elif kind in ('lo', 'hi'):
            out.append('  patterns' if kind == 'lo' else '  (the high bytes of the same addresses)')
        elif kind == 'bytes':
            out.append('  ' + ' '.join('byte $%02X' % b for b in blk).replace(' byte', '\n  byte'))
        else:
            out += ['  ' + e for e in tune_events(kind, blk)]
    return text_file(out)


def tunes_in(raw):
    blocks, cur = [], None
    for ln in lines_of(raw):
        ln = ln.split(';')[0].strip()
        if not ln:
            continue
        if ln.startswith('block '):
            cur = [ln.split()[1], []]
            blocks.append(cur)
        else:
            cur[1].append(ln.split())
    kinds = dict(TUNE_BLOCKS)
    # sizes first: every block but the tables is its events' bytes
    body = {}
    for name, rows in blocks:
        k = kinds[name]
        if k in ('order', 'pattern', 'bytes'):
            body[name] = b''.join(tune_bytes(k, r) for r in rows)
    sizes = {'TuneTable': 24, 'PatternLo': 27, 'PatternHi': 27}
    addr, at = TUNES_AT, {}
    for name, _rows in blocks:
        at[name] = addr
        addr += sizes.get(name, len(body.get(name, b'')))
    pats = [at['Pattern%d' % n] for n in range(27)]
    tunes = {}
    for name, rows in blocks:
        if name == 'TuneTable':
            for r in rows:
                tunes[int(r[1])] = [at[x] for x in r[2:5]]
    body['TuneTable'] = b''.join(bytes([a & 255, a >> 8]) for t in range(4) for a in tunes[t])
    body['PatternLo'] = bytes(a & 255 for a in pats)
    body['PatternHi'] = bytes(a >> 8 for a in pats)
    return b''.join(body[name] for name, _rows in blocks)


INSTRUMENT = ['pw_lo', 'pw_hi', 'wave', 'attack_decay', 'sustain_release', 'gate_off', 'b6', 'vibrato', 'peak']


# ---------------------------------------------------------------------------------------------------------------
# The dispatch
# ---------------------------------------------------------------------------------------------------------------
def tiles_group(pix, att, cols=16):
    return ((pix, att), lambda b: tiles_to_png(b[pix], b[att], cols),
            lambda raw: dict(zip((pix, att), png_to_tiles(raw))))


# editable file -> (the .bin names it builds, to_editable({name: bytes}), from_editable(raw) -> {name: bytes})
def periods_out(b):
    """PeriodLo $C82E and PeriodHi $C89A (RAM 6) as one CSV: index, the note (not read back), the period"""
    lo, hi = b['music/period-lo.bin'], b['music/period-hi.bin']
    if len(lo) != len(hi):
        raise ValueError('periods: %d low bytes, %d high bytes' % (len(lo), len(hi)))
    lines = head(['The AY tone periods (PeriodLo $C82E, PeriodHi $C89A in RAM 6): period = PeriodLo[i] + 256 x',
                  'PeriodHi[i] at the AY clock of 1.7734 MHz; index i is MIDI note i + 12 (57: A4). The note column',
                  'is not read back. Every C# is 0.38 semitone flat and index 8 repeats G0 (src/music/music.ann).',
                  'The last 8 high bytes are also VibratoTable-8\'s record 0.'])
    lines.append('index,note,period')
    for i in range(len(lo)):
        midi = i + 12
        lines.append('%d,%s%d,%d' % (i, NOTE_NAMES[midi % 12], midi // 12 - 1, lo[i] + 256 * hi[i]))
    return text_file(lines)


def periods_in(raw):
    lo, hi = bytearray(), bytearray()
    for ln in lines_of(raw)[1:]:
        v = num(ln.split(',')[2])
        lo.append(v & 255)
        hi.append(v >> 8)
    return {'music/period-lo.bin': bytes(lo), 'music/period-hi.bin': bytes(hi)}


GROUPS = {
    'music/periods.csv': (('music/period-lo.bin', 'music/period-hi.bin'), periods_out, periods_in),
    'tiles/base.png': tiles_group('tiles/base-pixels.bin', 'tiles/base-attrs.bin'),
    'tiles/alt.png': tiles_group('tiles/alt-pixels.bin', 'tiles/alt-attrs.bin'),
    'rooms/rooms.txt': (('rooms/grids.bin', 'rooms/table.bin', 'rooms/alt-rooms.bin'), rooms_out, rooms_in),
    'screens/panel.png': (('screens/panel-pixels.bin', 'screens/panel-attrs.bin'),
                          lambda b: third_to_png(b['screens/panel-pixels.bin'], b['screens/panel-attrs.bin']),
                          lambda raw: dict(zip(('screens/panel-pixels.bin', 'screens/panel-attrs.bin'),
                                               png_to_third(raw)))),
}

ANIM = ['Hero frame lists (sprite frames $00-$3F of the explorer set, $40-$7E creatures), each $FF ended,',
        'played one frame a pass (FrameListPlay / NextFrame); one list a line.']

# .bin name -> (suffix, to_editable(bytes), from_editable(raw))
SINGLES = {
    'screens/loading.bin': ('.png', screen_to_png, png_to_screen),
    'sprites/items.bin': sprites(24, 24, 'columns', 8),
    'sprites/creatures.bin': sprites(24, 24, 'columns', 16),
    'sprites/bearers.bin': sprites(24, 24, 'columns', 4),
    **{'sprites/explorer-%d.bin' % n: sprites(24, 24, 'columns', 16) for n in range(5)},
    'graphics/title-logo.bin': sprites(8, 8, 'rows', 25),
    'graphics/capsules.bin': sprites(8, 8, 'rows', 8),
    'graphics/flames.bin': sprites(8, 8, 'rows', 4),
    'graphics/cursor.bin': sprites(24, 16, 'columns', 8),
    'screens/selector.bin': ('.png', screen_to_png, png_to_screen),
    'rooms/backtiles.bin': ('.txt', backtiles_out, backtiles_in),
    'leftovers/tile-map-tape.bin': hexgrid(32, ['TileMap $F800 as the tape holds it: 16 rows of 32 tile indices, a',
                                                'room\'s map left over from the saving; rebuilt on every room entry.']),
    'texts/menu.bin': text(['MenuText $9540: the device options, printed by PrintMenuText $94EF.']),
    'texts/credits.bin': text(['CreditsText $9579: the credits under the menu, rows 17-21.']),
    'texts/collision.bin': text(['CollisionText $B07C: the telescope view (TelescopeView $A7B9); the numbers',
                                 'are printed into the gaps.']),
    'texts/stop-tape.bin': text(['StopTapeText (selector, 48K): the message after block 4.']),
    'texts/start-tape.bin': text(['StartTapeText (selector, 48K): the message after the choice.']),
    'texts/help-48k.bin': text(['Help48KText (selector): the 48K page of Help.']),
    'texts/help-title.bin': text(['HelpTitle (selector).']),
    'texts/help-page1.bin': text(['HelpPage1 (selector): PrintPage codes $16 c r (AT), $0D, $01 (pause), $00 (wait).']),
    'texts/help-page2.bin': text(['HelpPage2 (selector).']),
    'texts/help-page3.bin': text(['HelpPage3 (selector).']),
    'texts/break-message.bin': text(['BreakMessage (loader): AT 10,4, INK 7, PAPER 1 and the text.']),
    'tables/checkpoint-rooms.bin': lists(['CheckpointRooms $9AF5: the rooms whose entry records the respawn point,',
                                          '$FF ended.']),
    'tables/floor-tiles.bin': lists(['FloorTiles $A234: the tiles stood on but walked through (the list runs on',
                                     'into SolidTiles).'], end=0x00),
    'tables/solid-tiles.bin': lists(['SolidTiles $A24B: the solid tiles of the base set, $00 ended.'], end=0x00),
    'tables/alt-floor-tiles.bin': lists(['AltFloorTiles $A264: the floor tiles of the alternate set.'], end=0x00),
    'tables/alt-solid-tiles.bin': lists(['AltSolidTiles $A271: the solid tiles of the alternate set, $00 ended.'],
                                        end=0x00),
    'tables/explorer-rooms.bin': table(['room'], ['ExplorerRooms $A66C: the room left of room $29 for each explorer.'],
                                       index='explorer'),
    'tables/think-hints.bin': table(['item'], ['ThinkHints $A6E6: the item the hero thinks of in each room, $FF none.'],
                                    index='room'),
    'tables/lift-stops.bin': table(['room', 'y'], ['LiftStops $A9E6: the lift\'s stop in each room of its shaft.']),
    'tables/barrel-arcs.bin': lists(['BarrelArc $AAFA: the Y steps of the barrel rides, one a pass, signed;',
                                     'the long arc (84 steps), then the short one.'], end=None, kind='signed'),
    'tables/jump.bin': lists(['JumpFrames $AE8D: the 17 frames of the jump, then the 17 Y steps (signed).'],
                             end=None, kind='signed'),
    'tables/teleport-pads.bin': table(['room', 'y', 'x'], ['TeleportPads $B073: the three teleport pads.']),
    'tables/snakes-1a.bin': table(['x', 'y', 'frame', 'flags'], ['SnakeTemplate $B5D1: the snakes of room $1A.']),
    'tables/wanted-items.bin': table(['item'], ['WantedItems $B6BB: the professor\'s six wishes, in order.'],
                                     index='gift'),
    'tables/item-places.bin': item_places(['ItemPlaces $B99D: where the items lie at the start (taken = 1: not there',
                                           'until put in place); X and Y multiples of 8; the name column is',
                                           'not read back.']),
    'tables/bridge-tiles.bin': lists(['BridgeTiles $BB51: the bridge tiles of room $19, then of room $3A.'],
                                     end=None),
    'music/tunes.bin': ('.txt', tunes_out, tunes_in),
    'music/instruments.bin': table(INSTRUMENT, ['Instruments $C028 (RAM 6): 27 records of 9 bytes. wave bit 7: noise;',
                                                'attack_decay: the attack (high) and decay (low) nibbles, AttackRates /',
                                                'DecayRates; sustain_release: the sustain level (high) and release',
                                                '(low); gate_off: the release starts that many frames before the end;',
                                                'vibrato: the VibratoTable offset (0 none); peak: the peak volume.',
                                                'pw_lo, pw_hi, b6 and the other wave bits are never read (C64 values).'],
                                   index='record'),
    'music/slots.bin': table(['slot%d' % n for n in range(8)],
                             ['SlotTable $C11B: per channel row (8 x channel + slot) the record offset (9 x record).',
                              'Rows 0-2 are channels A, B, C; rows 3-5 are never indexed by a tune.'], index='row'),
    'music/vibratos.bin': table(['head'] + ['d%d' % n for n in range(1, 8)],
                                ['VibratoTable $C906: byte 0 the delay (bit 7 clear) or cycles (set), then 7 signed',
                                 'period deltas.'], kinds={'d%d' % n: 'signed' for n in range(1, 8)}),
    'music/arpeggios.bin': table(['head'] + ['s%d' % n for n in range(1, 8)],
                                 ['ArpeggioTable $C927: record n (8 bytes): head bit 7 loop, bits 3-6 + 1 the first',
                                  'hold, bits 0-2 the step count; each step bits 3-7 semitones, bits 0-2 the hold.'],
                                 index='record'),
    'music/envelope-rates.bin': lists(['AttackRates $CD36 (the first line) and DecayRates $CD46: by nibble 0-15;',
                                       '< $80: steps a frame, $80 + n: one step every n frames.'], end=None),
    **{'anims/%s.bin' % n: lists(ANIM) for n in ('telescope', 'room-2d', 'room-43', 'deaths', 'teleport', 'sink',
                                                 'think', 'refuse', 'room-2e', 'professor')},
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

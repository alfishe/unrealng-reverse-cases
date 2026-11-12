#!/usr/bin/env python3
"""Switchblade's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of a part (the game, bank 4, the loader's stage 2, the BASIC).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against DIR       # ... and gives the bytes of DIR/<name>.bin

The formats (src/res/README.md and each folder's README.md list the files, addresses and readers):
- 3-bit column pictures (graphics/tiles.png, the sprite sets, the title pieces): the game's own picture format, 3-pixel
  units packed eight to three bytes, column by column (ROOM.md section 2). An indexed PNG, 0 paper (black), 1 ink
  (white), 2 the grid (grey); the frames in a grid; the text chunk `sw-col3` holds the units across, the rows and the
  frame count.
- Plain 1-bit rows (the font, the end picture, the intro glyphs, the loader's logo and scroll): bytes of 8 pixels, a
  frame `wb` bytes wide and `h` rows tall; the same palette; `sw-rows` holds the layout, `lead` (rows of grey before
  the first byte) and `bytes` (the count, so a last part frame is grey after it).
- Text records (texts/*.txt): the print records of PrintString `$837B` (Y, X, two style bytes, the text, `$FF` a new
  line, 0 the end) as `text Y X S1 S2` and one quoted line a text line; the picture records of PrintGlyphs `$61E5` /
  PrintStoryString `$D863` (Y, X, glyph numbers, `$FF` a new line, 0 the end) as `picture Y X` and one line of hex
  glyph numbers a row; `raw "..."` any other bytes. In quotes: printable ASCII ($20-$5A and the punctuation) as itself,
  `\\xNN` any other byte, `\\"` and `\\\\` escaped.
- Tables (tables/*.csv, rooms/*.csv, music/*.csv): a header line naming the columns, `#` lines comments, numbers
  decimal or `$hex`; a column whose name starts with `_` is written for the reader and not read back.
- Hex lines (*.txt): bytes in hex, a line a record or a list; `$ADDR:` at a line's start and `#` lines are comments.
- rooms/rooms.txt: the 126 room records (127 rooms; 122 and 123 share one), one block a room (rooms/README.md).
- rooms/map.txt: the map, 20 rows of the rooms' numbers at their columns.
- music/tunes.txt: the patterns and the order lists of bank 4's three tunes (music/README.md); the pointer tables
  (PatternAddrLo/Hi, TuneTable) are computed from them.
Any other file (leftovers/) stays its bytes.
"""
import argparse
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')


def num(t):
    t = t.strip()
    if t.startswith('$'):
        return int(t[1:], 16)
    if t.startswith('-$'):
        return -int(t[2:], 16)
    return int(t, 0)


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.lstrip().startswith('#')]


def head(comments):
    return ['# ' + c if c else '#' for c in comments]


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


def hx(b):
    return '$%02X' % b


# ---------------------------------------------------------------------------------------------------------------
# PNG helpers: an indexed picture, 0 paper, 1 ink, 2 grey (the grid and the places with no byte)
# ---------------------------------------------------------------------------------------------------------------
MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]


def new_png(w, h):
    from PIL import Image
    img = Image.new('P', (w, h), 2)
    img.putpalette(MONO + [0] * (768 - len(MONO)))
    return img, img.load()


def save_png(img, key, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text(key, json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def open_png(raw, key):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    if img.mode != 'P':
        raise ValueError('not an indexed PNG (palette mode P)')
    return img, img.load(), json.loads(img.text[key])


def ink(px, x, y):
    v = px[x, y]
    if v not in (0, 1):
        raise ValueError('pixel %d,%d is %d, neither paper (0) nor ink (1)' % (x, y, v))
    return v


# ---------------------------------------------------------------------------------------------------------------
# 3-bit column pictures (UnpackGroups $8BC8): eight 3-bit values in three bytes, MSB first; a column `rows` values
# ---------------------------------------------------------------------------------------------------------------
def unpack3(data, count):
    out, bits, nbits, i = [], 0, 0, 0
    while len(out) < count:
        if nbits < 3:
            bits = (bits << 8) | data[i]
            i += 1
            nbits += 8
        nbits -= 3
        out.append((bits >> nbits) & 7)
    return out


def pack3(values):
    if len(values) % 8:
        raise ValueError('3-bit values: %d is no multiple of 8' % len(values))
    out = bytearray()
    for i in range(0, len(values), 8):
        g = 0
        for v in values[i:i + 8]:
            g = g << 3 | v
        out += g.to_bytes(3, 'big')
    return bytes(out)


def col3_frame(data, cols, rows):
    """a frame's bytes -> rows of pixels (3 x cols wide)"""
    per = rows * 3 // 8
    columns = [unpack3(data[c * per:(c + 1) * per], rows) for c in range(cols)]
    return [[(columns[x // 3][y] >> (2 - x % 3)) & 1 for x in range(3 * cols)] for y in range(rows)]


def col3_to_png(data, cols, rows, sheet):
    size = cols * rows * 3 // 8
    if len(data) % size:
        raise ValueError('col3: %d bytes is no whole number of %d-byte frames' % (len(data), size))
    n = len(data) // size
    w, h = 3 * cols, rows
    across = min(n, sheet)
    img, px = new_png(1 + across * (w + 1), 1 + ((n + sheet - 1) // sheet) * (h + 1))
    for f in range(n):
        x0, y0 = 1 + (f % sheet) * (w + 1), 1 + (f // sheet) * (h + 1)
        for y, line in enumerate(col3_frame(data[f * size:(f + 1) * size], cols, rows)):
            for x, p in enumerate(line):
                px[x0 + x, y0 + y] = p
    return save_png(img, 'sw-col3', {'cols': cols, 'rows': rows, 'frames': n, 'sheet': sheet})


def png_to_col3(raw):
    _img, px, m = open_png(raw, 'sw-col3')
    cols, rows, sheet = m['cols'], m['rows'], m['sheet']
    w, h = 3 * cols, rows
    out = bytearray()
    for f in range(m['frames']):
        x0, y0 = 1 + (f % sheet) * (w + 1), 1 + (f // sheet) * (h + 1)
        values = []
        for c in range(cols):
            for y in range(rows):
                values.append(ink(px, x0 + 3 * c, y0 + y) << 2 | ink(px, x0 + 3 * c + 1, y0 + y) << 1 |
                              ink(px, x0 + 3 * c + 2, y0 + y))
        out += pack3(values)
    return bytes(out)


def col3(cols, rows, sheet=16):
    return '.png', lambda d: col3_to_png(d, cols, rows, sheet), png_to_col3


def frames_of(raw):
    """the frames of a col3 PNG as pixel rows (for the figures)"""
    _img, px, m = open_png(raw, 'sw-col3')
    data = png_to_col3(raw)
    size = m['cols'] * m['rows'] * 3 // 8
    return [col3_frame(data[f * size:(f + 1) * size], m['cols'], m['rows']) for f in range(m['frames'])]


# ---------------------------------------------------------------------------------------------------------------
# Plain 1-bit rows: frames of h rows of wb bytes; `lead` grey rows before the first byte, a last part frame
# ---------------------------------------------------------------------------------------------------------------
def rows_to_png(data, wb, h, sheet, lead=0, first=0):
    size = wb * h
    total = lead * wb + len(data)
    n = (total + size - 1) // size
    w = 8 * wb
    across = min(n, sheet)
    img, px = new_png(1 + across * (w + 1), 1 + ((n + sheet - 1) // sheet) * (h + 1))
    for i, b in enumerate(data):
        k = lead * wb + i
        f, r = divmod(k, size)
        y, xb = divmod(r, wb)
        x0, y0 = 1 + (f % sheet) * (w + 1), 1 + (f // sheet) * (h + 1)
        for bit in range(8):
            px[x0 + 8 * xb + bit, y0 + y] = (b >> (7 - bit)) & 1
    return save_png(img, 'sw-rows', {'wb': wb, 'h': h, 'sheet': sheet, 'lead': lead, 'bytes': len(data),
                                     'first': first})


def png_to_rows(raw):
    _img, px, m = open_png(raw, 'sw-rows')
    wb, h, sheet, lead = m['wb'], m['h'], m['sheet'], m['lead']
    size, w = wb * h, 8 * wb
    out = bytearray()
    for i in range(m['bytes']):
        k = lead * wb + i
        f, r = divmod(k, size)
        y, xb = divmod(r, wb)
        x0, y0 = 1 + (f % sheet) * (w + 1), 1 + (f // sheet) * (h + 1)
        b = 0
        for bit in range(8):
            b = b << 1 | ink(px, x0 + 8 * xb + bit, y0 + y)
        out.append(b)
    return bytes(out)


def rows(wb, h, sheet=16, lead=0, first=0):
    return '.png', lambda d: rows_to_png(d, wb, h, sheet, lead, first), png_to_rows


# ---------------------------------------------------------------------------------------------------------------
# Text and picture records
# ---------------------------------------------------------------------------------------------------------------
PLAIN = set(range(0x20, 0x5B)) - {0x22, 0x5C}


def quote(bs):
    out = ''
    for b in bs:
        if b == 0x22:
            out += '\\"'
        elif b == 0x5C:
            out += '\\\\'
        elif b in PLAIN:
            out += chr(b)
        else:
            out += '\\x%02X' % b
    return '"' + out + '"'


def unquote(s):
    s = s.strip()
    if len(s) < 2 or s[0] != '"' or s[-1] != '"':
        raise ValueError('text: not a quoted line: %r' % s)
    s, out, i = s[1:-1], bytearray(), 0
    while i < len(s):
        c = s[i]
        if c == '\\':
            if s[i + 1] == 'x':
                out.append(int(s[i + 2:i + 4], 16))
                i += 4
                continue
            out.append(ord(s[i + 1]))
            i += 2
            continue
        if ord(c) not in PLAIN:
            raise ValueError('text: %r must be written \\xNN' % c)
        out.append(ord(c))
        i += 1
    return bytes(out)


def records_out(layout, comments):
    """layout: [(offset, kind, name)], kind 'text', 'picture' or 'raw'; a record runs to the next one's offset"""
    def out(d):
        lines = head(comments)
        bounds = [o for o, _k, _n in layout] + [len(d)]
        if bounds[0] != 0 or bounds[-2] >= len(d):
            raise ValueError('records: the layout does not cover %d bytes' % len(d))
        for (o, kind, name), end in zip(layout, bounds[1:]):
            rec = d[o:end]
            lines.append('')
            lines.append('# %s' % name)
            if kind in ('text', 'picture') and (len(rec) < (5 if kind == 'text' else 3) or rec[-1] != 0):
                kind = 'raw'
            if kind == 'text':
                lines.append('text %s %s %s %s' % tuple(hx(b) for b in rec[:4]))
                for part in rec[4:-1].split(b'\xff'):
                    lines.append('  ' + quote(part))
            elif kind == 'picture':
                lines.append('picture %s %s' % (hx(rec[0]), hx(rec[1])))
                for part in rec[2:-1].split(b'\xff'):
                    lines.append('  ' + (' '.join('%02X' % b for b in part) if part else '-'))
            else:
                lines.append('raw ' + quote(rec))
        return text_file(lines)

    def back(raw):
        d, cur = bytearray(), None
        for ln in lines_of(raw) + ['end']:
            f = ln.split()
            if f[0] in ('text', 'picture', 'raw', 'end'):
                if cur is not None:
                    kind, hdr, parts = cur
                    d += hdr + b'\xff'.join(parts) + b'\x00'
                    cur = None
                if f[0] == 'text':
                    cur = ('text', bytes(num(x) for x in f[1:5]), [])
                elif f[0] == 'picture':
                    cur = ('picture', bytes(num(x) for x in f[1:3]), [])
                elif f[0] == 'raw':
                    d += unquote(ln.strip()[3:])
            elif cur is None:
                raise ValueError('records: %r outside a record' % ln)
            elif cur[0] == 'text':
                cur[2].append(unquote(ln))
            else:
                cur[2].append(b'' if f == ['-'] else bytes(int(x, 16) for x in f))
        return bytes(d)

    return '.txt', out, back


# ---------------------------------------------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------------------------------------------
def cell(v, kind):
    if kind == 'hex':
        return hx(v)
    if kind == 'word':
        return '$%04X' % v
    if kind == 'signed':
        return str(v - 256 if v > 127 else v)
    if kind == 'bcd':
        return '%02X' % v
    return str(v)


def table(columns, comments, index=None, notes=None):
    """fixed records as CSV: columns [(name, kind)], kind 'hex', 'dec', 'signed' (a byte), 'word' (two bytes, low
    first), 'wordbe' (two bytes, high first), 'bcd3' (three BCD bytes as six digits); index: a first column numbering
    the records (written, not read back); notes(record number) -> a last column `_note` (not read back)"""
    sizes = {'word': 2, 'wordbe': 2, 'bcd3': 3}
    size = sum(sizes.get(k, 1) for _n, k in columns)

    def out(d):
        if len(d) % size:
            raise ValueError('table: %d bytes is no whole number of %d-byte records' % (len(d), size))
        names = ([index] if index else []) + [n for n, _k in columns] + (['_note'] if notes else [])
        lines = head(comments) + [','.join(names)]
        for r in range(len(d) // size):
            p, cells = r * size, []
            for _n, k in columns:
                if k == 'word':
                    cells.append('$%04X' % (d[p] | d[p + 1] << 8))
                elif k == 'wordbe':
                    cells.append('$%04X' % (d[p] << 8 | d[p + 1]))
                elif k == 'bcd3':
                    cells.append('%02X%02X%02X' % tuple(d[p:p + 3]))
                else:
                    cells.append(cell(d[p], k))
                p += sizes.get(k, 1)
            lines.append(','.join(([str(r)] if index else []) + cells + ([notes(r)] if notes else [])))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        rows_ = lines_of(raw)
        names = rows_[0].split(',')
        for ln in rows_[1:]:
            vals = dict(zip(names, ln.split(',')))
            for n, k in columns:
                v = vals[n].strip()
                if k == 'word':
                    w = num(v)
                    d += bytes([w & 255, w >> 8 & 255])
                elif k == 'wordbe':
                    w = num(v)
                    d += bytes([w >> 8 & 255, w & 255])
                elif k == 'bcd3':
                    if not re.fullmatch(r'[0-9A-Fa-f]{6}', v):
                        raise ValueError('table: %r is not six BCD digits' % v)
                    d += bytes.fromhex(v)
                else:
                    d.append(num(v) & 255)
        return bytes(d)

    return '.csv', out, back


def rows_table(layout, columns, comments):
    """records of several sizes as CSV: layout [(offset, note)] cuts the bytes (a record runs to the next offset);
    each row: `_at` (the address, not read back), the bytes as `$hex` in columns b0.., `_note`"""
    def out(d):
        bounds = [o for o, _n in layout] + [len(d)]
        width = max(b - a for a, b in zip(bounds, bounds[1:]))
        names = ['_at'] + (columns + ['b%d' % i for i in range(len(columns), width)])[:width] + ['_note']
        lines = head(comments) + [','.join(names)]
        for (o, note), end in zip(layout, bounds[1:]):
            rec = [hx(b) for b in d[o:end]]
            lines.append(','.join([note[0]] + rec + [''] * (width - len(rec)) + [note[1]]))
        return text_file(lines)

    def back(raw):
        d = bytearray()
        rows_ = lines_of(raw)
        names = rows_[0].split(',')
        for ln in rows_[1:]:
            for n, v in zip(names, ln.split(',')):
                if not n.startswith('_') and v.strip():
                    d.append(num(v) & 255)
        return bytes(d)

    return '.csv', out, back


def columns_table(names, count, comments, kinds=None, index='n'):
    """a table stored column by column (count values of the first column, then of the second ...) as CSV rows"""
    kinds = kinds or {}

    def out(d):
        if len(d) != count * len(names):
            raise ValueError('columns: %d bytes, not %d' % (len(d), count * len(names)))
        lines = head(comments) + [','.join([index] + names)]
        for r in range(count):
            lines.append(','.join([str(r)] + [cell(d[c * count + r], kinds.get(n, 'hex')) for c, n in enumerate(names)]))
        return text_file(lines)

    def back(raw):
        rows_ = lines_of(raw)
        hdr = rows_[0].split(',')
        vals = [dict(zip(hdr, ln.split(','))) for ln in rows_[1:]]
        return bytes(num(v[n]) & 255 for n in names for v in vals)

    return '.csv', out, back


def hexlines(comments, cut, base=None):
    """bytes as hex lines; cut(d) -> the offsets where lines start; base: the address of byte 0, written `$ADDR:` at
    each line's start (a comment); a cut may carry a name (offset, name): written as a `#` line before it"""
    def out(d):
        lines = head(comments)
        cuts = sorted(set(c if isinstance(c, tuple) else (c, None) for c in cut(d)) | {(0, None)},
                      key=lambda c: c[0])
        starts = sorted({c for c, _n in cuts})
        names = {c: n for c, n in cuts if n}
        for a, b in zip(starts, starts[1:] + [len(d)]):
            if a >= len(d):
                break
            if a in names:
                lines.append('# ' + names[a])
            pre = '$%04X: ' % (base + a) if base is not None else ''
            lines.append(pre + ' '.join('%02X' % x for x in d[a:b]))
        return text_file(lines)

    def back(raw):
        out_ = bytearray()
        for ln in lines_of(raw):
            ln = re.sub(r'^\s*\$[0-9A-Fa-f]{4}:', '', ln)
            out_ += bytes(int(x, 16) for x in ln.split())
        return bytes(out_)

    return '.txt', out, back


def every(n, names=None):
    """cuts every n bytes, and at the named offsets ({offset: name})"""
    names = names or {}
    return lambda d: sorted(set(range(0, len(d), n)) | set(names)) + [(o, nm) for o, nm in names.items()]


# ---------------------------------------------------------------------------------------------------------------
# Rooms: the 126 records $A928-$D0F8 (DecodeRoom $9F63, SetupRoomObjects $A41E)
# ---------------------------------------------------------------------------------------------------------------
ROOMS_AT = 0xA928
SHARED = 122                # the record of rooms 122 and 123
BARS = {5: 'bar right ($75AD)', 6: 'bar down ($7400)', 7: 'bar on $69 ($7571)', 8: 'bar on $6A ($7571)',
        9: 'bar down ($7436)', 0xA: 'bar right ($7511)', 0xC: 'bar on $68 ($7496)'}


def at(c):
    return '@%d.%d' % divmod(c, 20)


def unat(t):
    if not t.startswith('@'):
        raise ValueError('rooms: a cell is @row.column, not %r' % t)
    r, c = t[1:].split('.')
    r, c = int(r), int(c)
    if not 0 <= c < 20 or not 0 <= 20 * r + c < 256:
        raise ValueError('rooms: no cell %r' % t)
    return 20 * r + c


def room_record_end(d, p):
    """the end of the record at p: (the end, the decoded lines)"""
    lines = []
    hdr = d[p]
    groups = [hdr & 7, (hdr >> 3) & 7, hdr >> 6]
    lines.append('groups %d %d %d' % tuple(groups))
    p += 1
    for g, n in enumerate(groups):
        for _ in range(n):
            b1, l = d[p], d[p + 1]
            lines.append('place %d n%d style%d %s' % (g, b1 >> 4, b1 & 15, at(l)))
            p += 2
    while True:
        b = d[p]
        code, hi = b & 15, b >> 4
        p += 1
        if code == 0xD:
            k = (hi & 1) + 1
            lines.append('walls style%d %s' % (b >> 5, ' '.join(at(x) for x in d[p:p + k])))
            p += k
            continue
        if hi == 0:
            lines.append('nop $%02X' % b)
            continue
        if code == 0xF:
            lines.append('end x%d' % hi)
            break
        if code == 4:
            lines.append('surface x%d' % hi)
            continue
        ops = [d[p + 2 * i:p + 2 * i + 2] for i in range(hi)]
        p += 2 * hi
        if code <= 3:
            lines.append('strings $%02X %s' % (0x68 + code, ' '.join('%s=$%02X' % (at(c), s) for c, s in ops)))
        elif code in BARS:
            lines.append('bar%X %s' % (code, ' ; '.join('s%d n%d %s' % (o >> 4, (o & 15) or 16, at(c))
                                                         for o, c in ops)))
        elif code == 0xB:
            lines.append('piece %s' % ' ; '.join('k%d n%d %s' % (o >> 4, o & 15, at(c)) for o, c in ops))
        elif code == 0xE:
            lines.append('decor %s' % ' ; '.join('set%d n%d %s' % (o >> 4, (o & 15) or 16, at(c)) for o, c in ops))
    if d[p] == 0:
        lines.append('zones default')
        p += 1
    else:
        while True:
            b = d[p]
            n, last, e = (b >> 4) & 7, b & 8, b & 7
            rects = d[p + 1:p + 1 + 2 * n]
            cells = d[p + 1 + 2 * n:p + 1 + 2 * n + e]
            words = ['zone'] + ['%s-%s' % (at(rects[2 * i]), at(rects[2 * i + 1])[1:]) for i in range(n)]
            words += [at(c) for c in cells]
            if b & 0x80:
                words.append('bit7')
            if last:
                words.append('last')
            lines.append(' '.join(words))
            p += 1 + 2 * n + e
            if last:
                break
    cnt = d[p]
    p += 1
    for i in range(cnt & 15):
        b0, c = d[p], d[p + 1]
        lines.append('pickup t%d n%d %s' % (b0 >> 5, b0 & 31, at(c)))
        p += 2
    for i in range(cnt >> 4):
        lines.append('enemy $%02X %s' % (d[p], at(d[p + 1])))
        p += 2
    return p, lines


def room_numbers(k):
    """record k (0-based) -> its rooms"""
    if k + 1 < SHARED:
        return [k + 1]
    if k + 1 == SHARED:
        return [SHARED, SHARED + 1]
    return [k + 2]


ROOM_COMMENTS = [
    'The rooms of Switchblade (tools/res_formats.py; src/res/rooms/README.md): one block a record, in address order',
    'from Room1 $A928 (the room table $7100 points at them; rooms 122 and 123 share one record). A cell is @row.column',
    '(cell = 20 x row + column; rows 0-10 are the room, 12 holds the row above). The lines of a block, in order:',
    '  groups G0 G1 G2      the header: the placements in the groups 0, 1, 2 (0-7, 0-7, 0-3)',
    '  place G nN styleS @c  a wall outline: count N (0 = 256 steps), style S (RoomPatternStarts), first cell',
    '  strings $PG @c=$EE ... tile strings (RoomShapes $7345) on plane $PG ($68-$6B: command code 0-3)',
    '  surface xN           the open-air rows (code 4), N times',
    '  barC sS nN @c ; ...  a bar of code C (5, 6, 7, 8, 9, A, C), style S, N cells (1-16) from @c',
    '  piece kK nN @c ; ... code $B: sub-command K (RoomCodeHandlersB $75EF), N its count nibble',
    '  walls styleS @c [@c] code $D: fill and shade the walls from one or two cells, wall tile $1A + S',
    '  decor setH nN @c ; ... code $E: a row of N front tiles (set 2: ShapeTilesA, else ShapeTilesB)',
    '  nop $XX              a command byte whose repeat nibble is 0 (does nothing)',
    '  end xN               code $F (RoomPatch): the end of the map commands',
    '  zones default        no zone records (the whole room is zone 0: EmptyObjectList $75FB), or',
    '  zone @a-b.c ... @c ... [last]  a reveal zone: rectangles (first cell - last cell), single cells',
    '  pickup tT nN @c      a pickup of type T (ObjectTilePlaces $7BD8), N its taken bit, its cell',
    '  enemy $KK @c         an enemy start: kind $KK (KindTemplates $7200), its cell',
    'The counts byte (enemies << 4 | pickups) is written from the pickup and enemy lines. A record must keep its',
    'size (the source INCBINs it at fixed offsets).',
]


def rooms_out(d):
    out = head(ROOM_COMMENTS)
    p, k = 0, 0
    while p < len(d):
        end, lines = room_record_end(d, p)
        rooms = room_numbers(k)
        out.append('')
        out.append('room %s ; $%04X, %d bytes' % (' '.join(str(r) for r in rooms), ROOMS_AT + p, end - p))
        out += ['  ' + ln for ln in lines]
        p, k = end, k + 1
    if p != len(d):
        raise ValueError('rooms: the records run past the file')
    return text_file(out)


def rooms_in(raw):
    out = bytearray()
    rec = None

    def flush():
        if rec is None:
            return
        hdr, places, body, pickups, enemies = rec
        out.append(hdr)
        out.extend(places)
        out.extend(body)
        out.append(len(enemies) // 2 << 4 | len(pickups) // 2)
        out.extend(pickups)
        out.extend(enemies)

    for ln in lines_of(raw):
        ln = ln.split(';', 1)[0] if ln.startswith('room') else ln
        f = ln.split()
        w = f[0]
        if w == 'room':
            flush()
            rec = [0, bytearray(), bytearray(), bytearray(), bytearray()]
        elif w == 'groups':
            g = [int(x) for x in f[1:4]]
            if g[0] > 7 or g[1] > 7 or g[2] > 3:
                raise ValueError('rooms: groups %s out of range' % g)
            rec[0] = g[0] | g[1] << 3 | g[2] << 6
        elif w == 'place':
            rec[1] += bytes([int(f[2][1:]) << 4 | int(f[3][5:]), unat(f[4])])
        elif w == 'walls':
            cells = [unat(x) for x in f[2:]]
            rec[2] += bytes([int(f[1][5:]) << 5 | (len(cells) - 1) << 4 | 0xD] + cells)
        elif w == 'nop':
            rec[2].append(num(f[1]))
        elif w == 'end':
            rec[2].append(int(f[1][1:]) << 4 | 0xF)
        elif w == 'surface':
            rec[2].append(int(f[1][1:]) << 4 | 4)
        elif w == 'strings':
            ops = f[2:]
            rec[2].append(len(ops) << 4 | (num(f[1]) - 0x68))
            for o in ops:
                c, s = o.split('=')
                rec[2] += bytes([unat(c), num(s)])
        elif w.startswith('bar') or w in ('piece', 'decor'):
            code = int(w[3:], 16) if w.startswith('bar') else 0xB if w == 'piece' else 0xE
            groups = [g.split() for g in ln.split(None, 1)[1].split(';')]
            rec[2].append(len(groups) << 4 | code)
            for g in groups:
                hi = int(re.sub(r'^[a-z]+', '', g[0]))
                lo = int(g[1][1:])
                if w != 'piece':
                    lo &= 15            # 16 cells is the nibble 0
                rec[2] += bytes([hi << 4 | lo, unat(g[2])])
        elif w == 'zones':
            rec[2].append(0)
        elif w == 'zone':
            rects = [x for x in f[1:] if '-' in x]
            cells = [x for x in f[1:] if x.startswith('@') and '-' not in x]
            rec[2].append((0x80 if 'bit7' in f else 0) | len(rects) << 4 | (8 if 'last' in f else 0) | len(cells))
            for r_ in rects:
                a, b = r_.split('-')
                rec[2] += bytes([unat(a), unat('@' + b)])
            rec[2] += bytes(unat(c) for c in cells)
        elif w == 'pickup':
            rec[3] += bytes([int(f[1][1:]) << 5 | int(f[2][1:]), unat(f[3])])
        elif w == 'enemy':
            rec[4] += bytes([num(f[1]), unat(f[2])])
        else:
            raise ValueError('rooms: unknown line %r' % ln)
    flush()
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The map: MapColumns $7048 (127), MapRowCounts $70C7 (20), MapRowStarts $70DB (20)
# ---------------------------------------------------------------------------------------------------------------
MAP_ROWS = 20


def map_out(d):
    cols, counts, starts = d[:127], d[127:147], d[147:167]
    width = max(cols) + 1
    out = head(['The map (MapColumns $7048, MapRowCounts $70C7, MapRowStarts $70DB; tools/res_formats.py): 20 rows,',
                'each the room numbers at their columns (`.` no room). Rooms are numbered row by row: a row\'s rooms',
                'must follow the previous row\'s. The room above a room has its column on the row above (RoomAbove).',
                '',
                'column  ' + ' '.join('%3d' % c for c in range(width))])
    for r in range(MAP_ROWS):
        line = ['  .'] * width
        for i in range(counts[r]):
            line[cols[starts[r] + i]] = '%3d' % (starts[r] + i + 1)
        out.append('row %2d: ' % r + ' '.join(line))
    return text_file(out)


def map_in(raw):
    places = []
    for ln in lines_of(raw):
        if not ln.startswith('row'):
            continue
        head_, cells = ln.split(':', 1)
        r = int(head_.split()[1])
        for c, v in enumerate(cells.split()):
            if v != '.':
                places.append((int(v), r, c))
    places.sort()
    if [p[0] for p in places] != list(range(1, len(places) + 1)) or len(places) != 127:
        raise ValueError('map: the rooms must be 1-127, each once')
    if [p[1] for p in places] != sorted(p[1] for p in places):
        raise ValueError('map: the rooms must be numbered row by row')
    cols = bytes(p[2] for p in places)
    counts = bytes(sum(1 for p in places if p[1] == r) for r in range(MAP_ROWS))
    starts = bytes(sum(counts[:r]) for r in range(MAP_ROWS))
    return cols + counts + starts


def map_grid(d):
    """room -> (row, column) from the map bytes (for the figures)"""
    cols, counts, starts = d[:127], d[127:147], d[147:167]
    return {starts[r] + i + 1: (r, cols[starts[r] + i]) for r in range(MAP_ROWS) for i in range(counts[r])}


# ---------------------------------------------------------------------------------------------------------------
# Music: bank 4's patterns, pointer tables, tune table and order lists ($C4B8-$CE8B)
# ---------------------------------------------------------------------------------------------------------------
PATTERNS_AT, NPATS, NTUNES = 0xC4B8, 45, 3
NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
NOTE_INDEX = {}
for _n in range(0x7E):
    NOTE_INDEX['%s%d' % (NOTE_NAMES[(40 + _n) % 12], (40 + _n) // 12 - 1)] = _n


def note_name(n):
    m = 40 + n
    return '%s%d' % (NOTE_NAMES[m % 12], m // 12 - 1)


def sgn(b):
    return b - 256 if b & 0x80 else b


def pattern_events(d, p):
    out = []
    while True:
        c = d[p]
        if c == 0xFF:
            return p + 1, out
        if c < 0x7E:
            out.append('%s:%d' % (note_name(c), d[p + 1]))
            p += 2
        elif c == 0x7E:
            out.append('per$%04X:%d' % (d[p + 1] | d[p + 2] << 8, d[p + 3]))
            p += 4
        elif c == 0x7F:
            out.append('r:%d' % d[p + 1])
            p += 2
        elif c < 0x8C:
            out.append('i%d' % (c & 15))
            p += 1
        elif 0x90 <= c < 0xA0:
            out.append('arp%d' % (c & 15))
            p += 1
        elif c == 0xC0:
            out.append('port(%d,%d,%d)' % (d[p + 1], d[p + 2], sgn(d[p + 3])))
            p += 4
        elif c == 0xC1:
            out.append('portoff')
            p += 1
        elif c == 0xFC:
            out.append('drumoff')
            p += 1
        elif c == 0xFD:
            out.append('drum(%d,%d)' % (d[p + 1], d[p + 2]))
            p += 3
        else:
            out.append('$%02X' % c)
            p += 1


def pattern_bytes(words):
    out = bytearray()
    for w in words:
        m = re.fullmatch(r'([A-G]#?-?\d+|per\$[0-9A-Fa-f]{4}|r):(\d+)', w)
        if m:
            name, dur = m.group(1), int(m.group(2))
            if name == 'r':
                out += bytes([0x7F, dur])
            elif name.startswith('per'):
                v = int(name[4:], 16)
                out += bytes([0x7E, v & 255, v >> 8, dur])
            else:
                out += bytes([NOTE_INDEX[name], dur])
        elif re.fullmatch(r'i\d+', w):
            out.append(0x80 | int(w[1:]))
        elif re.fullmatch(r'arp\d+', w):
            out.append(0x90 | int(w[3:]))
        elif w.startswith('port('):
            a, b, c = (int(x) for x in w[5:-1].split(','))
            out += bytes([0xC0, a, b, c & 255])
        elif w == 'portoff':
            out.append(0xC1)
        elif w == 'drumoff':
            out.append(0xFC)
        elif w.startswith('drum('):
            a, b = (int(x) for x in w[5:-1].split(','))
            out += bytes([0xFD, a, b])
        elif re.fullmatch(r'\$[0-9A-Fa-f]{2}', w):
            out.append(int(w[1:], 16))
        else:
            raise ValueError('tunes: unknown pattern event %r' % w)
    return bytes(out) + b'\xff'


def order_events(d, p):
    out = []
    while True:
        c = d[p]
        if c < 0x80:
            out.append('P%02d' % c)
            p += 1
        elif c < 0xC0:
            out.append('x%d' % (c & 0x1F) if c < 0xA0 else '$%02X' % c)
            p += 1
        elif c < 0xFC and c & 0xF0 == 0xC0:
            out.append('slot%d=ins%d' % (c & 15, d[p + 1]))
            p += 2
        elif c == 0xFE:
            out.append('tr%+d' % sgn(d[p + 1]))
            p += 2
        elif c == 0xFF:
            return p + 1, out
        elif c == 0xFD:
            out.append('fd(%d,%d)' % (d[p + 1], d[p + 2]))
            p += 3
        elif c < 0xFC:
            out.append('slot$%02X=ins%d' % (c, d[p + 1]))
            p += 2
        else:
            out.append('$%02X' % c)
            p += 1


def order_bytes(words):
    out = bytearray()
    for w in words:
        if re.fullmatch(r'P\d+', w):
            out.append(int(w[1:]))
        elif re.fullmatch(r'x\d+', w):
            out.append(0x80 | int(w[1:]))
        elif w.startswith('slot$'):
            s, i = w[5:].split('=ins')
            out += bytes([int(s, 16), int(i)])
        elif w.startswith('slot'):
            s, i = w[4:].split('=ins')
            out += bytes([0xC0 | int(s), int(i)])
        elif w.startswith('tr'):
            out += bytes([0xFE, int(w[2:]) & 255])
        elif w.startswith('fd('):
            a, b = (int(x) for x in w[3:-1].split(','))
            out += bytes([0xFD, a, b])
        elif re.fullmatch(r'\$[0-9A-Fa-f]{2}', w):
            out.append(int(w[1:], 16))
        else:
            raise ValueError('tunes: unknown order event %r' % w)
    return bytes(out) + b'\xff'


TUNE_NAMES = ['the title', 'the in-game music', 'the start jingle']


def tunes_out(d):
    def word(a):
        return d[a - PATTERNS_AT] | d[a - PATTERNS_AT + 1] << 8
    # the patterns run in order from PATTERNS_AT; their ends give the pointer tables' place
    p, pats = PATTERNS_AT, []
    for n in range(NPATS):
        end, ev = pattern_events(d, p - PATTERNS_AT)
        pats.append((p, ev))
        p = PATTERNS_AT + end
    lo_at = p
    hi_at, tt_at = lo_at + NPATS, lo_at + 2 * NPATS
    for n, (a, _ev) in enumerate(pats):
        if d[lo_at - PATTERNS_AT + n] | d[hi_at - PATTERNS_AT + n] << 8 != a:
            raise ValueError('tunes: pattern %d is not at its pointer' % n)
    lists = [word(tt_at + 2 * i) for i in range(3 * NTUNES)]
    if lists[0] != tt_at + 6 * NTUNES:
        raise ValueError('tunes: the order lists do not follow the tune table')
    out = head(['The tunes of bank 4 (Ben Daglish; tools/res_formats.py, src/res/music/README.md), $C4B8-$CE8B.',
                'Patterns in address order from Pattern00 $C4B8, then the order lists (tune 0 A, B, C, tune 1 ...).',
                'PatternAddrLo/Hi and TuneTable are written from them. Pattern events: NOTE:frames (NoteTable index',
                'n named as MIDI 40 + n, E2 = 0, as channels B and C play it; channel A sounds an octave lower),',
                'r:frames a rest, per$XXXX:frames a raw period, iN instrument slot N, arpN arpeggio N, port(a,b,c)',
                'a slide (after a frames, over b frames, c semitones), portoff, drum(len,noise), drumoff, $XX a byte',
                'the player skips. Order events: Pnn a pattern, xN the next pattern N times, trN the transpose',
                '(semitones, stays), slotS=insI, fd(a,b) (ignored), $XX. Every list and pattern ends at the end of',
                'its line. Sizes must stay (the source INCBINs the file at fixed offsets).'])
    out.append('')
    for n, (a, ev) in enumerate(pats):
        out.append('pattern %02d ; $%04X' % (n, a))
        out.append('  ' + ' '.join(ev) if ev else '  -')
    out.append('')
    p = lists[0]
    for t in range(NTUNES):
        out.append('# tune %d: %s' % (t, TUNE_NAMES[t]))
        for ch in range(3):
            a = lists[3 * t + ch]
            if a != p:
                raise ValueError('tunes: order list %d.%d is not where the last ended' % (t, ch))
            end, ev = order_events(d, a - PATTERNS_AT)
            out.append('order %d %s ; $%04X' % (t, 'ABC'[ch], a))
            out.append('  ' + ' '.join(ev))
            p = PATTERNS_AT + end
    if p - PATTERNS_AT != len(d):
        raise ValueError('tunes: the order lists end at $%04X, the file at $%04X' % (p, PATTERNS_AT + len(d)))
    return text_file(out)


def tunes_in(raw):
    pats, orders, cur = [], [], None
    for ln in lines_of(raw):
        f = ln.split(';')[0].split()
        if f[0] == 'pattern':
            cur = pats
        elif f[0] == 'order':
            cur = orders
        else:
            words = [] if f == ['-'] else f
            cur.append(pattern_bytes(words) if cur is pats else order_bytes(words))
    if len(pats) != NPATS or len(orders) != 3 * NTUNES:
        raise ValueError('tunes: %d patterns and %d order lists, not %d and %d' % (len(pats), len(orders), NPATS,
                                                                                  3 * NTUNES))
    out, ptrs = bytearray(), []
    for b in pats:
        ptrs.append(PATTERNS_AT + len(out))
        out += b
    out += bytes(a & 255 for a in ptrs) + bytes(a >> 8 for a in ptrs)
    tt_at = PATTERNS_AT + len(out)
    p = tt_at + 6 * NTUNES
    table_, lists = bytearray(), bytearray()
    for b in orders:
        table_ += bytes([p & 255, p >> 8])
        lists += b
        p += len(b)
    return bytes(out + table_ + lists)


# ---------------------------------------------------------------------------------------------------------------
# The resources: name -> format; the README of each folder lists them with their addresses and readers
# ---------------------------------------------------------------------------------------------------------------
# The page-tail item records (frame, score record, two bytes), $6BAC-$6C35: the kinds whose KindTemplates word
# points at each (KindTemplates $7200; run-time address = $5D82 / $5E82 + offset)
ITEM_KINDS = {0x5DD2: '$01 gem 50', 0x5DD6: '$02 gem 100', 0x5DDA: '$03 gem 200', 0x5DDE: '$04 gem 400',
              0x5DE2: '$05 gem 700', 0x5DE6: '$06 flask', 0x5DEA: '$20 orb', 0x5DEE: '$21 orb', 0x5DF2: '$22 orb',
              0x5DF6: '$11 weapon shield 0', 0x5DFA: '$12 weapon shield 1', 0x5E82: '$13 weapon shield 2',
              0x5E86: '$17 weapon shield 6', 0x5E8A: '$18 Fireblade fragment', 0x5E8E: '$16 weapon shield 5',
              0x5E92: '$14 weapon shield 3', 0x5E96: '$15 weapon shield 4', 0x5E9A: '$1B bullet shield',
              0x5E9E: '$1E vitality', 0x5EA2: '$1F invulnerability', 0x5EA6: '$07 E', 0x5EAA: '$08 X',
              0x5EAE: '$09 T', 0x5EB2: '$0A R', 0x5EB6: '$0B A', 0x5EBA: '$0C B', 0x5EBE: '$0D O', 0x5EC2: '$0E N',
              0x5EC6: '$0F U', 0x5ECA: '$10 S', 0x5ECE: '$19 power-up shield', 0x5ED2: '$1A speed-up shield',
              0x5ED6: '$1C power-up reset', 0x5EDA: '$1D speed-up reset'}


def item_layout():
    lay = []
    for o in range(0, 44, 4):
        rt = 0x5DD2 + o
        lay.append((o, ('$%04X' % (0x6BAC + o), 'run time $%04X: kind %s' % (rt, ITEM_KINDS.get(rt, '-')))))
    lay.append((44, ('$6BD8', 'spare (run time $5DFE-$5DFF)')))
    for o in range(0, 92, 4):
        rt = 0x5E82 + o
        lay.append((46 + o, ('$%04X' % (0x6BDA + o), 'run time $%04X: kind %s' % (rt, ITEM_KINDS.get(rt, '-')))))
    return lay


WEAPON_KINDS = {0x5EF9: '$41', 0x5F82: '$44', 0x5F89: '$40', 0x5F90: '$45', 0x5F97: '$46', 0x5F9E: '$42',
                0x5FA5: '$43'}
TEMPLATE_KINDS = {}
for _k, _a in {0x23: 0x65B8, 0x24: 0x65CA, 0x25: 0x6182, 0x26: 0x6194, 0x27: 0x61A6, 0x28: 0x61B8, 0x29: 0x61CA,
               0x2A: 0x64B8, 0x2B: 0x62CA, 0x2C: 0x62EE, 0x2D: 0x61DC, 0x2E: 0x63EE, 0x2F: 0x6494, 0x30: 0x6482,
               0x31: 0x64A6, 0x32: 0x63CA, 0x33: 0x63DC, 0x34: 0x62DC, 0x35: 0x63A6, 0x36: 0x63B8, 0x37: 0x61EE,
               0x38: 0x6282, 0x39: 0x6294, 0x3A: 0x62A6, 0x3B: 0x62B8, 0x3C: 0x6382, 0x3D: 0x6394, 0x3E: 0x64DC,
               0x3F: 0x64CA, 0x47: 0x6582, 0x48: 0x6594}.items():
    TEMPLATE_KINDS.setdefault(_a, []).append('$%02X' % _k)
TEMPLATE_AT = [0x6182 + 0x100 * (i // 7) + 18 * (i % 7) for i in range(28)] + [0x6582 + 18 * i for i in range(6)]
TEMPLATE_NAMES = {0x64EE: 'WeaponTemplate', 0x65A6: 'the message banner', 0x65B8: 'the items (SharedEnemyTemplate)',
                  0x65CA: 'Hiro (HiroTemplate)', 0x65DC: 'TitlePieceTemplate'}


def template_note(r):
    a = TEMPLATE_AT[r]
    kinds = TEMPLATE_KINDS.get(a)
    return 'run time $%04X%s%s' % (a, ': kind ' + ' '.join(kinds) if kinds else '',
                                   ': ' + TEMPLATE_NAMES[a] if a in TEMPLATE_NAMES else '')


SET_NAMES = ['Tiles', 'EnemyFrames', 'GiantFrames', 'HiroFrames', 'HiroFrames15', 'HiroFrames18', 'HiroFrames21',
             'SparkFrames', 'ShotFrames', 'ScoreFrames', 'MessageFrames', 'GremlinLogo'] + \
            ['TitlePiece%d' % n for n in range(12, 24)]

TITLE_PIECES = {12: (2, 32), 13: (2, 40), 14: (2, 48), 15: (5, 40), 16: (6, 24), 17: (6, 32), 18: (6, 40),
                19: (8, 8), 20: (8, 24), 21: (8, 40), 22: (4, 8), 23: (14, 32)}

EFFECT48 = [('time', 'dec'), ('sweep_delay', 'dec'), ('sweep_period', 'dec'), ('mixer', 'hex'),
            ('sweep_step', 'wordbe'), ('pitch', 'hex'), ('attack', 'signed'), ('decay', 'signed'),
            ('sustain', 'dec'), ('release', 'signed'), ('peak', 'dec')]
EFFECT48_NOTES = ['Hiro hit', 'a hard landing', 'an enemy killed', 'the guardian killed, the gate opens',
                  'the end and the end picture\'s fade', '', '', '', '', '', '', '', '', '']

TEMPLATE_COLS = [('state', 'word'), ('walk_list', 'hex'), ('script_page', 'hex'), ('turn', 'hex'),
                 ('fall', 'hex'), ('hurt', 'hex'), ('still_frame', 'hex'), ('score', 'hex'), ('step_delay', 'hex'),
                 ('b0D', 'hex'), ('alert', 'hex'), ('death', 'hex'), ('behaviour', 'hex'), ('touch_zone', 'hex'),
                 ('direction', 'hex'), ('hits', 'hex'), ('size_class', 'hex')]

INSTRUMENT = [('attack', 'dec'), ('decay', 'signed'), ('sustain', 'dec'), ('release', 'signed'), ('peak', 'hex'),
              ('vib_delay', 'dec'), ('vib_width', 'hex'), ('vib_step', 'word'), ('flags', 'hex')]

GAME_SCRIPT_NAMES = {0x7A46: 'StrikeScript1', 0x7A51: 'WalkScript', 0x7A7A: 'RunScript', 0x7AAF: 'TileActionScript',
                     0x7AB6: 'LandScript', 0x7ABC: 'HardLandScript', 0x7ACE: 'StrikeScript2', 0x7ADB: 'StrikeScript3',
                     0x7AE8: 'TileActionEndScript', 0x7AEF: 'Script92F5', 0x7AFB: 'Script9C0E',
                     0x7B00: 'StandScript', 0x7B5D: 'Script911A', 0x7B63: 'MessageNumber (a variable)',
                     0x7B80: 'SpawnTriples', 0x7B89: 'SpawnedScript', 0x7BB5: 'Script9115'}


def named(base, names):
    return {a - base: n for a, n in names.items()}


SINGLES = {
    # ---- rooms ----
    'rooms/rooms.bin': ('.txt', rooms_out, rooms_in),
    'rooms/map.bin': ('.txt', map_out, map_in),
    'rooms/outline-starts.bin': table([('start', 'hex')], [
        'RoomPatternStarts $7300: the low byte in page $73 of each placement style\'s outline shapes (BuildMap',
        '$9F63: style = the low nibble of a placement\'s first byte).'], index='style'),
    'rooms/outlines-1.bin': hexlines([
        'RoomPatterns $7310-$7329: the outline shapes, a byte a step: bit 7 two tiles (2, 3) else tile 1, bit 6',
        'back to the style\'s first shape, bits 0-5 the step to the next cell. One line a style\'s list as',
        'RoomPatternStarts cuts them.'], lambda d: [s - 0x10 for s in (0x10, 0x12, 0x14, 0x16, 0x17, 0x18, 0x1B, 0x1E,
                                                                     0x22, 0x27) if s - 0x10 < len(d)], base=0x7310),
    'rooms/outlines-2.bin': hexlines([
        'RoomPatternsMore $732E-$7344: the outline shapes of styles 9-13 and 15 (after DrawColumnPos).'],
        lambda d: [s - 0x2E for s in (0x2E, 0x2F, 0x33, 0x3B, 0x40, 0x41)], base=0x732E),
    'rooms/strings.bin': hexlines([
        'RoomShapes $7345-$73BC: tile strings for the commands 0-3 (PlotPattern $A02E): (tile, step) pairs, a step',
        'with bit 7 ends; a string is found by its low byte in page $73 (the `$73xx:` before each line).'],
        lambda d: [0] + [i + 2 for i in range(1, len(d), 2) if d[i] & 0x80 and i + 2 < len(d)], base=0x7345),
    'rooms/decor-tiles.bin': hexlines([
        'ShapeTilesA $73BD (4 bytes) and ShapeTilesB $73C1 (4): the decor rows of command $E (RoomOpLedge $A357): the',
        'tile, the tile put over tiles 3 and 4, those two tiles.'], every(4), base=0x73BD),
    'rooms/ledge-tiles.bin': hexlines(['SpecialTiles $73C5: the two ledge tiles ($55, $54) searched by $9CB1.'],
                                      every(2), base=0x73C5),
    'rooms/bars-1.bin': table([('page', 'hex'), ('after_wall', 'hex'), ('first', 'hex'), ('middle_a', 'hex'),
                               ('middle_b', 'hex'), ('last', 'hex')], [
        'StructureRecords $7400-$74F5: the bar styles (6 bytes: the plane page, bit 7 mark the cells; the piece',
        'after a wall, the first piece, two alternating middle pieces, the last piece). Record = (address - $7400)',
        '/ 6: $7400 set A (code 6, $A0C4), $7436 set B (record 9, code 9), $7496 set C (record 25, code $C);',
        'record 31 ($74BA) is the variable ComposeDest (a word) and four bytes of set C.'], index='record'),
    'rooms/horizon.bin': hexlines([
        'RoomStrip $74F6-$7510: the horizon row of the open-air rooms: BuildSurface $A039 copies 20 bytes from $74F5 +',
        'the room (1-8) into row 4 of plane $68.'], every(27), base=0x74F6),
    'rooms/bars-2.bin': table([('page', 'hex'), ('after_wall', 'hex'), ('first', 'hex'), ('middle_a', 'hex'),
                               ('middle_b', 'hex'), ('last', 'hex')], [
        'StructureSetD $7511 (code $A), StructureSetE $7571 (record 10, codes 7 and 8), StructureSetF $75AD',
        '(record 20, code 5), to $75EE: bar styles as in bars-1.csv.'], index='record'),
    'rooms/default-zone.bin': hexlines([
        'EmptyObjectList $75FB: the zone record of a room with none (one rectangle, cells 0-$DB), and two zero',
        'bytes.'], every(5), base=0x75FB),
    'rooms/solid-tiles.bin': rows_table(
        [(2 * i, ('$%04X' % (0x7292 + 2 * i), 'SolidTiles' if i == 0 else 'from $7294 (SolidTiles + 2)' if i == 1
                  else 'LedgeTiles' if 0x7292 + 2 * i == 0x72B4 else 'TopTiles' if 0x7292 + 2 * i == 0x72D8 else ''))
         for i in range(38)], ['page', 'tile'], [
            'SolidTiles $7292-$72D7 and TopTiles $72D8-$72DD: (plane page, tile) pairs. TestCellSolid $A334 reads 33',
            'pairs from $7292 or 34 from $7294, 3 from LedgeTiles $72B4; FillBackRow $A265 the three of TopTiles.']),
    'rooms/pickup-tiles.bin': rows_table(
        [(2 * i, ('$%04X' % (0x7BD8 + 2 * i), 'type %d' % i)) for i in range(6)] + [(12, ('$7BE4', 'unread'))],
        ['tile', 'page'], ['ObjectTilePlaces $7BD8: per pickup type, the tile and the plane page (RoomObjects',
                           '$A41E puts it at the pickup\'s cell); $7BE4 one zero byte nothing reads.']),
    # ---- graphics ----
    'graphics/tiles.bin': col3(4, 16),
    'graphics/enemies.bin': col3(4, 16),
    'graphics/giants.bin': col3(8, 32, 10),
    'graphics/hiro.bin': col3(4, 32),
    'graphics/hiro-15.bin': col3(5, 32, 8),
    'graphics/hiro-18.bin': col3(6, 32, 8),
    'graphics/hiro-21.bin': col3(7, 32, 8),
    'graphics/sparks.bin': col3(2, 8),
    'graphics/shots.bin': col3(3, 8, 10),
    'graphics/scores.bin': col3(5, 8, 10),
    'graphics/messages.bin': col3(9, 16, 4),
    'graphics/gremlin-logo.bin': col3(11, 16, 1),
    **{'graphics/title-%d.bin' % n: col3(c, r, 2) for n, (c, r) in TITLE_PIECES.items()},
    'graphics/font.bin': rows(1, 8, 16, first=0x20),
    'graphics/havok.bin': rows(6, 61, 1),
    'graphics/intro-glyphs-1.bin': rows(1, 8, 16, first=1),
    'graphics/intro-glyphs-2.bin': rows(1, 8, 16, lead=4, first=125),
    'graphics/story-font.bin': rows(1, 8, 16, first=1),
    'graphics/loader-logo.bin': rows(26, 48, 1),
    'graphics/loader-scroll.bin': rows(59, 7, 1),
    'graphics/fireblade-icons.bin': hexlines([
        'FirebladeIcons $7F1D: the 16 panel pictures of the Fireblade as it grows, six glyph codes of the font',
        'each (PanelFragments $FF3C copies picture n = the fragments found into FirebladePanelText).'],
        every(6), base=0x7F1D),
    'graphics/intro-attrs.bin': hexlines([
        'IntroAttrsA $6225 (5 rows of 3), IntroAttrsB $6234 (5 rows of 3), IntroAttrsC $6243 (13 rows of 16): the',
        '48K intro\'s attribute blocks (CopyAttrBlock $6212).'],
        lambda d: list(range(0, 30, 3)) + list(range(30, len(d), 16)) + [(0, 'IntroAttrsA'), (15, 'IntroAttrsB'),
                                                                        (30, 'IntroAttrsC')], base=0x6225),
    'graphics/story-attrs.bin': hexlines([
        'StoryAttrs1 $D8A3 (5 rows of 3), StoryAttrs2 $D8B2 (5 rows of 3), PortraitAttrs $D8C1 (13 rows of 16):',
        'the 128K story pages\' attribute blocks (CopyAttrBlock $D890).'],
        lambda d: list(range(0, 30, 3)) + list(range(30, len(d), 16)) + [(0, 'StoryAttrs1'), (15, 'StoryAttrs2'),
                                                                        (30, 'PortraitAttrs')], base=0xD8A3),
    'graphics/panel-meter.bin': hexlines([
        'MeterGradient $FFB7 (the partial byte for value AND 3), MeterStrip $FFBB: 7 full bytes, MeterPartial (a',
        'variable), 8 empty bytes; DrawMeter $FF7C shows 8 of them from $FF00 + C.'],
        lambda d: [0, (4, 'MeterStrip'), (11, 'MeterPartial'), (12, 'MeterEmpty')], base=0xFFB7),
    'graphics/panel-attrs.bin': hexlines([
        'PanelAttrs $FFCB: the panel\'s attribute row at $5AE0 (PanelAttrsRoom $FFEB): the meters, EXTRA, the',
        'weapon bar, BONUS.'], every(16), base=0xFFCB),
    'graphics/letter-attrs.bin': hexlines([
        'ExtraBonusUnlit $5C38 and ExtraBonusLit $5C3D: the attribute of an unlit and a lit EXTRA / BONUS letter',
        '(the letter check $999F).'], every(5), base=0x5C38),
    # ---- texts ----
    'texts/hiscore-texts.bin': records_out([(0, 'text', 'CursorEraseText $80EB: erases the name cursor'),
                                            (16, 'text', 'HiScoreHeading $80FB'),
                                            (36, 'text', 'HiScoreRankText $810F: the rank, the two digits are '
                                                         'written in')], [
        'The high-score page\'s strings (PrintString $837B records: text Y X style style, the lines). The',
        'Havok room stash (HavokRoomEnter) moves $80EB-$817A away while Hiro is in room 123.']),
    'texts/hiscores.bin': records_out([(0, 'text', 'HiScoreTableHead $8119 and HiScoreEntries $811D: ten entries, '
                                                   '8 score digits, \\x04 (skip 4), 10 name letters, two lines down')],
                                      ['The high-score table as one print record (PrintStringTall $836E): JEFF C ...',
                                       'KEV; NewGame moves the entries when a score enters.']),
    'texts/copyright.bin': records_out([(0, 'text', 'CopyrightText $81F0')], ['The title page\'s copyright line.']),
    'texts/sloppy.bin': records_out([(0, 'raw', 'SpareName $8214: the 11th name; a high-score name SLOPPY is the '
                                                'cheat (keys 1-4 choose the start room)')],
                                    ['SpareName $8214: 10 letters, no record header.']),
    'texts/strings.bin': records_out([
        (0, 'text', 'MusicIconText $821E: the note icon (glyphs $65 $66), 128K glue'),
        (0x8225 - 0x821E, 'text', 'EffectsIconText $8225: the effects icon (glyphs $2A $26)'),
        (0x822C - 0x821E, 'text', 'HighScoreMessage $822C'),
        (0x826A - 0x821E, 'text', 'NameGridText $826A: < deletes, + ends'),
        (0x82AE - 0x821E, 'text', 'NameCursorText $82AE: the 3 x 3 frame of glyphs $22-$29'),
        (0x82BE - 0x821E, 'text', 'NameEntryText $82BE: the ten letters typed (NameEntryLetters $82C2)'),
        (0x82CD - 0x821E, 'text', 'NameEntryMark $82CD'),
        (0x82D5 - 0x821E, 'text', 'FirebladePanelText $82D5: six glyph codes from FirebladeIcons (FirebladeGlyphs $82D9)'),
        (0x82E0 - 0x821E, 'text', 'EndText $82E0: printed by HavokFade $872B')], [
        'The menu, high-score entry, panel and end strings (PrintString $837B records).']),
    'texts/control-menu.bin': records_out([(0, 'text', 'ControlMenuText $6ACB (ControlMenu $6A7B)')],
                                          ['The control menu, printed tall ($836E) before the 48K intro.']),
    'texts/panel.bin': records_out([(0, 'text', 'ScoreLineInit $5C15: the score digits, \\x07 skips 7 cells, the '
                                                'lives'),
                                    (16, 'text', 'StatusLineInit $5C25: EXTRA, the weapon bar glyphs $85 $5B $5C $86, '
                                                 'BONUS')], [
        'The panel\'s two lines as GlobalsInit holds them: NewGame copies $5C00-$5C37 to $6642 (ScoreLine $6657,',
        'StatusLine $6667 at run time).']),
    'texts/intro.bin': records_out([
        (0x5E4D - 0x5E4D, 'picture', 'the eyes (IntroGlyphs glyph numbers)'),
        (0x5E64 - 0x5E4D, 'text', 'scene 1'), (0x5EB5 - 0x5E4D, 'text', 'scene 1, second text'),
        (0x5F06 - 0x5E4D, 'picture', 'the eyes open, frame 1'), (0x5F10 - 0x5E4D, 'picture', 'frame 2'),
        (0x5F1A - 0x5E4D, 'picture', 'frame 3'), (0x5F24 - 0x5E4D, 'picture', 'the Fireblade'),
        (0x5F56 - 0x5E4D, 'text', 'scene 2'), (0x5FA0 - 0x5E4D, 'picture', 'the shattered Fireblade'),
        (0x5FD2 - 0x5E4D, 'text', 'scene 2, second text'), (0x601E - 0x5E4D, 'picture', 'Havok'),
        (0x60FD - 0x5E4D, 'text', 'scene 3'), (0x6161 - 0x5E4D, 'text', 'scene 4')], [
        'IntroScript $5E4D-$61E4: the 48K intro (Intro48 $5D4F) in the order it shows them: picture records',
        '(glyph numbers 1-$ED of IntroGlyphs, the rows) and text records (PrintString). From $5FC0 on the bytes',
        'are under the run-time code of the page tails (SetTune ...): the labels there stay.']),
    'texts/story.bin': records_out([
        (0xD4CB - 0xD4CB, 'picture', 'StoryEyesClosed'), (0xD4E2 - 0xD4CB, 'text', 'StoryText1'),
        (0xD533 - 0xD4CB, 'text', 'StoryText2'), (0xD584 - 0xD4CB, 'picture', 'StoryEyesOpen1'),
        (0xD58E - 0xD4CB, 'picture', 'StoryEyesOpen2'), (0xD598 - 0xD4CB, 'picture', 'StoryEyesOpen3'),
        (0xD5A2 - 0xD4CB, 'picture', 'StoryFireblade'), (0xD5D4 - 0xD4CB, 'text', 'StoryText3'),
        (0xD61E - 0xD4CB, 'picture', 'StoryBladeShattered'), (0xD650 - 0xD4CB, 'text', 'StoryText4'),
        (0xD69C - 0xD4CB, 'picture', 'StoryPortrait'), (0xD77B - 0xD4CB, 'text', 'StoryText5'),
        (0xD7DF - 0xD4CB, 'text', 'StoryText6')], [
        'Bank 4\'s story pages (StoryPages $D3D0, read in order through IY): picture records in StoryFont, text',
        'records in the game font. The 128K copy of the 48K intro script.']),
    'texts/tape-error.bin': records_out([(0, 'raw', 'TapeErrorText $FFD8 (printed by RST $10)')],
                                        ['The tape loader\'s error message.']),
    # ---- tables ----
    'tables/score-table.bin': table([('sprite', 'dec'), ('points', 'bcd3')], [
        'The score records (page tail row 0, PageTailTemplate $6B5C; Hiro\'s page $5D82 + 4 x n at run time):',
        'the score sprite (ScoreFrames, 0 none) and the points, six BCD digits (AddScore $99E7). The record',
        'byte the code holds is $82 + 4 x n.'], index='n'),
    'tables/items.bin': rows_table(item_layout(), ['frame', 'score', 'b2', 'b3'], [
        'ItemRecords $6BAC-$6C35 (page tails of $5D00 and $5E00): a pickup kind\'s record (KindTemplates $7200',
        'points at it): the frame (Tiles), the score record ($82 + 4n of score-table.csv), two bytes',
        '(CollectPickup $98B6, SetWeapon $98F3).']),
    'tables/walk-lists.bin': hexlines([
        'WalkLists $6C36-$6C50 (page tail of $5E00, run time $5EDE): walk frame lists, [n] then n frames',
        '(an actor\'s +$05; $9BF2).'], lambda d: [0, 5, 9, 13, 15, 17, 21, 23, 25], base=0x6C36),
    'tables/weapons.bin': rows_table(
        [(7 * i, ('$%04X' % (0x6C51 + 7 * i), 'run time $%04X: kind %s' % (a, WEAPON_KINDS[a])))
         for i, a in enumerate([0x5EF9, 0x5F82, 0x5F89, 0x5F90, 0x5F97, 0x5F9E, 0x5FA5])],
        ['state_lo', 'state_hi', 'b2', 'b3', 'b4', 'b5', 'b6'], [
            'WeaponRecords $6C51-$6C81: the thrown weapons\' records (kinds $40-$46, KindTemplates $7200),',
            '7 bytes, patched into WeaponTemplate $64EE by HiroAttack $926E.']),
    'tables/touch-zones.bin': table([('y_from', 'signed'), ('y_to', 'signed'), ('x_from', 'signed'),
                                     ('x_to', 'signed')], [
        'TouchZoneRecords $6C82 (the touch zones $5FAC at run time): Hiro\'s place relative to an actor, [from, to),',
        'read by HiroInZone $9529 for the actor\'s +$11.'], index='zone'),
    'tables/sprite-sets.bin': table([('half_cols', 'dec'), ('rows', 'dec'), ('bytes', 'dec'), ('address', 'word')], [
        'PageTail60 $6CD6 (SizeClasses $6082 at run time): the 24 picture sets, 5 bytes: the width in half',
        'columns (2 x units), the rows, the bytes of a frame, the address (InitActor $A65D copies a record to',
        '+$15-+$19). Set 0 is the tiles.'], index='set', notes=lambda r: SET_NAMES[r] if r < 24 else ''),
    'tables/actor-templates.bin': table(TEMPLATE_COLS, [
        'PageTail61 $6D54-$6FB7 (page tails of $6100-$6500): 18 bytes copied to an actor\'s +$03-+$14 by',
        'InitActor $A65D (LOOP.md section 4: the state handler, the scripts, the score +$0B, the hits +$13, the',
        'size class +$14); KindTemplates names the kinds.'], index='n', notes=template_note),
    'tables/cell-colours.bin': table([('attr', 'hex')], [
        'CellColoursTemplate $703F (CellColours $66F7 at run time): a revealed cell\'s attribute by the high',
        'nibble of its plane $6C byte ($88BA); the last six are TitleColours.'], index='n'),
    'tables/kind-templates.bin': table([('template', 'word')], [
        'KindTemplates $7200: per actor kind, the run-time address of its template (kinds $23 up) or of its item',
        'record (below $23; tables/items.csv, weapons.csv, actor-templates.csv). TemplateForKind $A652.'],
        index='kind'),
    'tables/effects-48k.bin': table(EFFECT48, [
        'EffectTable $8683: the 48K\'s 14 sound effects, 12 bytes (StartEffect / EffectSound, through IY): the',
        'time, the sweep delay and period, the mixer bits, the sweep step (big end), the pitch (bits 5-7 used),',
        'the attack, decay (signed), sustain, release (signed) and peak.'], index='effect',
        notes=lambda r: EFFECT48_NOTES[r]),
    'tables/gates.bin': columns_table(['room', 'closed', 'x', 'side'], 6, [
        'GateRooms $76D2: the six rooms with an invisible gate (BarrierFind $8F28), GateClosed (set by NewGame,',
        'cleared by BarrierOpen $8F22), GateX (Hiro\'s X) and GateSide (bit 0: 0 blocks left, 1 right).'],
        kinds={'room': 'dec'}, index='gate'),
    'tables/title-actors.bin': table([('x', 'hex'), ('y', 'hex'), ('kind', 'hex'), ('b3', 'hex'), ('b4', 'hex'),
                                      ('b5', 'hex'), ('b6', 'hex')], [
        'TitleActors $7600: the title scene\'s 26 actors (15, then 11 from $7669): X, Y, the kind, three bytes to',
        '+$3F-+$41 and one to +$0A (LoadTitlePieces $A7D7).'], index='n'),
    'tables/title-order.bin': table([('page', 'hex')], [
        'TitleActorOrder $76B6: the actor pages in the order the title scene steps them (TitleMovePiece $A775).'],
        index='step'),
    'tables/scripts-76.bin': hexlines([
        'ActorScripts $76EA-$79FE: actor scripts (LOOP.md section 6: [count] [speed] [X offset left] [X offset',
        'right] [size class], then a frame a step; the jump and fall scripts three bytes a step). Lines of 16.'],
        every(16), base=0x76EA),
    'tables/scripts-7a.bin': hexlines([
        'ActorScriptsMore $7A08-$7B7F, SpawnTriples $7B80, SpawnedScript $7B89-$7BD7: actor scripts, Hiro\'s among',
        'them; a named start begins a line (the names are the .ann\'s).'],
        every(16, named(0x7A08, GAME_SCRIPT_NAMES)), base=0x7A08),
    'tables/reverse-codes.bin': table([('mirrored', 'dec')], [
        'ReverseCodes $7A00: a 3-bit picture value mirrored (MirroredColumn $8C51).'], index='value'),
    'tables/packer-phases.bin': table([('address', 'word'), ('mask', 'hex')], [
        'PackerPhases $FD98: PackRow $8CE5\'s records: 0-7 the packer entry for a window starting at unit p of a',
        'group and the left mask; 8-30 the INC H where the window ends (a RET is planted) and the right mask. The',
        'addresses are code (PackUnits0 $8D45 ...): they move if the packer moves.'], index='n'),
    'tables/unit-offsets.bin': table([('byte', 'dec')], [
        'UnitByteOffsets $FDF5: the byte of a 3-byte group holding unit n (SpriteScreenAddress $8828).'], index='unit'),
    # ---- music ----
    'music/tunes.bin': ('.txt', tunes_out, tunes_in),
    'music/arpeggios.bin': table([('head', 'hex')] + [('s%d' % i, 'hex') for i in range(1, 8)], [
        'Arpeggios $CE8C: arpeggios 1-9 (arpeggio 0 is none; its place is the end of the order lists): the head',
        '(bit 7 loop, bits 3-5 the note\'s own frames, bits 0-2 + 1 the steps), steps (bits 3-7 semitones, bits',
        '0-2 frames). UpdateArpeggio $C390.'], index='n'),
    'music/instruments.bin': table(INSTRUMENT, [
        'Instruments $CED4: 14 x 10 bytes: the attack step, decay step, sustain level, release step, peak (volume',
        '0-$7F), the vibrato delay, width and step (a word), the flags (bit 0 tone, 1 noise, 2 the hardware',
        'envelope). StartNote $D0DA, the envelope phases.'], index='n'),
    'music/effects.bin': table(INSTRUMENT + [('period', 'word'), ('gate', 'dec')], [
        'Effects $CF60: the 128K\'s 14 sound effects on channel A: an instrument (10 bytes), the tone period and',
        'the gate time (PlayEffect $C011).'], index='n'),
    'music/notes.bin': table([('period', 'word')], [
        'NoteTable $D016: 67 tone periods (AY clock 1.7734 MHz, f = 110837 / period); index n is MIDI 40 + n on',
        'channels B and C. Entries 2, 6 and 66 are off the scale.'], index='n',
        notes=lambda r: note_name(r)),
}


def install(files):
    for name, data in files.items():
        if name in SINGLES:
            suffix, to_ed, from_ed = SINGLES[name]
            out = to_ed(data)
            if from_ed(out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            write(os.path.join(RES, os.path.splitext(name)[0] + suffix), out)
            old = os.path.join(RES, name)
            if os.path.exists(old):
                os.remove(old)
        else:
            write(os.path.join(RES, name), data)


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path) and open(path, 'rb').read() == data:
        return
    open(path, 'wb').write(data)


def sources():
    """(src path, rel, single) for every file of src/res: single True when it is an editable form"""
    for top, _dirs, names in sorted(os.walk(RES)):
        for f in sorted(names):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            yield src, rel, not rel.endswith('.bin') and os.path.splitext(rel)[0] + '.bin' in SINGLES


def to_bytes(rel, single, raw):
    if single:
        name = os.path.splitext(rel)[0] + '.bin'
        return name, SINGLES[name][2](raw)
    return rel, raw


def load(rel):
    """the bytes of a resource (by its .bin name) from src/res, for the figures"""
    name = rel
    if rel in SINGLES:
        src = os.path.join(RES, os.path.splitext(rel)[0] + SINGLES[rel][0])
        return SINGLES[rel][2](open(src, 'rb').read())
    return open(os.path.join(RES, name), 'rb').read()


def build(out):
    for src, rel, single in sources():
        name, data = to_bytes(rel, single, open(src, 'rb').read())
        write(os.path.join(out, name), data)


def check(against=None):
    bad = count = 0
    for src, rel, single in sources():
        raw = open(src, 'rb').read()
        name, data = rel, raw
        if single:
            count += 1
            try:
                name, data = to_bytes(rel, single, raw)
                again = SINGLES[name][1](data)
                ok = again == raw
                if not ok:
                    print('res: %s is not as install writes it (bytes -> editable -> bytes do not match)' % rel)
            except (ValueError, KeyError, IndexError) as e:
                print('res: %s: %s' % (rel, e))
                ok = False
            if not ok:
                bad += 1
        if against:
            ref = os.path.join(against, name)
            if os.path.exists(ref) and open(ref, 'rb').read() != data:
                print('res: %s differs from %s' % (rel, ref))
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

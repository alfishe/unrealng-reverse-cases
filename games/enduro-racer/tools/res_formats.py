#!/usr/bin/env python3
"""Enduro Racer's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install
calls install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build [--out build/res]   # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file -> bytes -> the same file again,
                                                           # and the bytes against work/mkgame/res when it exists
    python3 tools/res_formats.py export [--from DIR]       # .bin files (DIR, default work/mkgame/res) -> src/res

| @res name | Editable file(s) | Format |
| --- | --- | --- |
| `texts/NAME.bin` | `texts/NAME.txt` | UTF-8, one string a line, joined with nothing; `{XX}` a byte outside $20-$7E or a trailing space |
| `tables/NAME.bin`, `sound/notes.bin` | `.csv` | a header of field names, one record a line (TABLES); a `tail` line holds bytes after the last whole record |
| `tables/bends.bin`, `tables/rowscale.bin` | `.csv` | tables kept as consecutive columns (COLUMNS): one line a row, one field a column |
| `font/font.bin`, `font/bigdigits.bin`, `tables/countglyphs.bin` | `.png` | glyphs side by side (GLYPHS): index 0 paper, 1 ink, 2 no glyph |
| `horizons/NAME.bin` | `horizons/NAME.png` | 256 pixels wide, one line of 32 bytes a pixel row |
| `sprites/objects.bin`, `sprites/sprites.bin` | `.png`, `.csv` | every sprite the descriptors name, placed on a sheet; the CSV a line a sprite (address, width in bytes, rows, place on the sheet, who uses it) and `bytes` lines for bytes no descriptor holds |
| `sound/tunes.bin` | `sound/tunes.txt` | the four channel streams as commands (TUNE_HELP) |
| `track/tables.bin` | `track/stage1.txt` ... `stage5.txt`, `track/patterns.txt` | the stage list, the track's patterns and the track, as text (TRACK_HELP) |
| `screens/loading.scr` | itself | a SCREEN$ file (the tape's loading screen); `loading.png` beside it is a view only |

Other tools read a resource with load('track/tables.bin'): the bytes built from its editable files.
"""
import argparse
import csv
import io
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
ZX = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0), (215, 215, 215),
      (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]

# texts: the strings as the code takes them (PrintList lengths, the layouts' counts); the rest of a file one more line
TEXTS = {
    'menu': ['ENDURO RACER', 'FROM SEGA', '# 1987 ACTIVISION', 'START GAME', 'ONE', 'TWO', ' PLAYERS',
             'CHANGE CONTROL MODE ', 'DEFINE KEYS ', 'SPACE OR FIRE TO EXECUTE', 'ANY OTHER KEY TO ADVANCE',
             'KEYBOARD', 'KEMPSTON', 'SINCLAIR RIGHT', 'SINCLAIR LEFT', 'CURSOR', 'EXIT', 'THROTTLE', 'WHEELIE',
             'LEFT', 'RIGHT', 'BRAKES', 'PAUSE', 'RESET', '        '],
    'credits': ['ENDURO RACER FROM SEGA', 'PRESENTED BY ACTIVISION', 'PROGRAMMED BY GIGA GAMES',
                'GRAPHICS BY FOCUS'],
    'hud': ['TOP', 'STAGE', 'SPEED', 'K<>', 'SCORE', 'TIME', 'NAME'],
    'lap': ['TOTAL', 'RECORD', 'PLAYER', 'LAPTIME', ' 0\'00"00'],
    'namegrid': ['[%\\+/])^', '()*/+&%$', 'QWERTYUIOP=?789', 'ASDFGHJKL:;\'456', 'ZXCVBNM,.!@0123'],
    'keymap': ['BNM\x01\x03', 'HJKL\x02', 'YUIOP', '67890', '54321', 'TREWQ', 'GFDSA', 'VCXZ\x04'],
    'keynames': ['SYM', 'ENT', 'SPC', 'CPS'],
}
# tables: (record size, [(field, kind)]); kinds: d a byte in decimal, x a byte in hex, s a signed byte, w a word in
# hex, b a BCD byte (two digits), tN N characters. The riders' rows and widths keep their bit 7 flags (mirror,
# aligned) as +128.
TABLES = {
    'controls': (10, [('throttle_row', 'x'), ('wheelie_row', 'x'), ('left_row', 'x'), ('right_row', 'x'),
                      ('brakes_row', 'x'), ('throttle_mask', 'x'), ('wheelie_mask', 'x'), ('left_mask', 'x'),
                      ('right_mask', 'x'), ('brakes_mask', 'x')]),
    'hiscores': (22, [('score', 't7'), ('name', 't8'), ('time', 't7')]),
    'records': (2, [('seconds', 'b'), ('hundredths', 'b')]),
    'perspective': (1, [('depth', 'd')]),
    'crest': (1, [('line_shift', 'd')]),
    'edges': (3, [('byte1', 'x'), ('byte2', 'x'), ('byte3', 'x')]),
    'edges2': (3, [('byte1', 'x'), ('byte2', 'x'), ('byte3', 'x')]),
    'notes': (2, [('period', 'w')]),
    'riderstarts': (4, [('x', 's'), ('acceleration', 'd'), ('top_speed', 'd'), ('bend_pose', 'd')]),
    'riders': (21, [('threshold', 'd')] + [(f'{f}{p}', k) for p in range(5)
                                          for f, k in (('rows', 'd'), ('width', 'd'), ('address', 'w'))]),
    'objects': (6, []),  # objects_export: eight lists, a head (farthest row, aligned row) then 6-byte entries
    'stages': (4, [('horizon', 'w'), ('lines', 'd'), ('bottom', 'x')]),
    'stageparams': (10, [('road', 'w'), ('rows', 'w'), ('offroad', 'w'), ('attribute', 'x'), ('copy_mode', 'd'),
                         ('unused1', 'x'), ('unused2', 'x')]),
    'collisions': (2, [('half_width', 'd'), ('height', 'd')]),
    'lean': (1, [('force', 'x')]),
    'steer': (1, [('force', 'd')]),
    'dotmasks': (1, [('mask', 'x')]),
    'dust': (1, [('x_offset', 's')]),
    'ayeffect': (2, [('register', 'd'), ('value', 'x')]),
    'bendblend': (1, [('step', 'd')]),
}
COLUMNS = {
    'bends': ['bend1', 'bend2', 'bend3'],
    'rowscale': ['scale', 'half_width'],
}
# glyph sets: (glyph width in bytes, [rows of each glyph])
GLYPHS = {
    'font/font.bin': (1, [8] * 63),
    'font/bigdigits.bin': (2, [15] * 10),
    'tables/countglyphs.bin': (1, [8, 8, 10, 10, 10]),
}
TUNE_HELP = """# The AY tune streams ($66CA-$67FA, PlayChannel). One command a line:
#   LEN NOTE      a note: LEN (0-199) interrupts, NOTE in hex: low nibble 1-11 the semitone (NoteTable word n),
#                 0 a rest; high nibble the octave (how many times the period is halved, plus the channel's transpose)
#   repeat N      ($FE N) the commands up to `end` N times;   end   ($FD)
#   call $ADDR    ($FC ADDR) the phrase at ADDR, back at `return` ($FB)
#   restart       ($C9) from the channel's start again, and clear TuneMark;   mark   ($CA) set TuneMark
#   byte XX       any other byte
# `stream $ADDR NAME` lines mark where a stream or a phrase starts (checked by the build)."""
TRACK_HELP = """# The track's patterns (Init copies $EB00-$F0AF to $5E80; the addresses here are the copy's).
# Commands (TrackStep; distances in SegmentLeft's units, 128 a segment):
#   obj TYPE LEN X  an object (type 0 ramp, 1-7 ObjectTypes, 10 the VarObject), LEN*2 units after the previous
#                   element, at X (signed, the road's centre 0)
#   call $ADDR LEN  run the pattern at ADDR for LEN units counted from the element before the call: its elements
#                   less than LEN from there are placed, the one that reaches LEN is not (forever: until its `ret`)
#   ret | jump $ADDR | mark N (a gap end, stage 3) | var N (VarObject = 2N)
#   bytes XX ...    bytes past the track's end (leftovers)
# `pattern $ADDR` starts a pattern; `#` starts a comment (the distances, the stage borders)."""
STAGE_HELP = """# segments: one token a segment of 128 units, BEND.CREST.DIR (bend 0 straight, 1-3 BendProfiles; crest 0
#   level, 1-3 CrestTable; DIR BendDir, the bend's side, 0 or 1); a suffix /XX keeps bits 6-7 other than $80
#   (none); the build sets bit 5 on the stage's last segment. track: the commands (patterns.txt has the format),
#   the number after # the distance from the race's start as TrackStep counts it (game_walk)."""
SPRITE_EXTRA = [  # the descriptors in the code, not in a resource: BikePoses (sprite, wheel patch), splash, dust
    (0xDBED, 3, 58, 'bike pose 0'), (0xDEC9, 1, 10, 'bike pose 0 wheels'), (0xDC9B, 3, 60, 'bike pose 1'),
    (0xDAF4, 3, 83, 'bike pose 2'), (0xD9EC, 6, 44, 'bike pose 3'), (0xDEB5, 2, 10, 'bike pose 3 wheels'),
    (0xD6DE, 5, 46, 'bike pose 4'), (0xDE9B, 2, 13, 'bike pose 4 wheels'), (0xD49A, 4, 47, 'bike pose 5'),
    (0xDE82, 2, 12, 'bike pose 5 wheels'), (0xD28B, 3, 48, 'bike pose 6'), (0xDE75, 1, 13, 'bike pose 6 wheels'),
    (0xDFCC, 7, 55, 'bike pose 7'), (0xE14D, 6, 41, 'bike pose 8'), (0xE243, 5, 25, 'bike pose 9'),
    (0xDED3, 5, 20, 'splash 1'), (0xDF37, 3, 15, 'splash 2'), (0xDF64, 4, 12, 'dust 1'), (0xDF94, 4, 14, 'dust 2'),
]
SPRITE_FILES = {'sprites/objects.bin': 0x6BE8, 'sprites/sprites.bin': 0xB306}
OBJECT_ORDER = [4, 5, 1, 6, 2, 0, 3, 7]  # the object lists' types in their order (ObjectTypes)
TRACK_ORG, COPY_ORG = 0xEB00, 0x5E80
TRACK_START = 0x60D0  # the copy's Track (TrackPtr at a new game)
TRACK_END = 0xF0AB    # the track's last command (a forever call) ends at $F0AA; $F0AB-$F0AF are leftovers
INSTALLING = {}


def load(name):
    """the bytes of a resource, built from its editable files"""
    if name in INSTALLING:
        return INSTALLING[name]
    out = {}
    build_one(name, out)
    return out[name]


# ---- texts
def esc(s):
    out = ''.join(c if 0x20 <= ord(c) < 0x7F and c not in '{}' else '{%02X}' % ord(c) for c in s)
    n = len(out) - len(out.rstrip(' '))
    return out[:len(out) - n] + '{20}' * n if n else out


def unesc(line):
    return re.sub(r'\{([0-9A-F]{2})\}', lambda m: chr(int(m.group(1), 16)), line)


def text_export(name, data):
    s = data.decode('latin-1')
    lines, pos = [], 0
    for part in TEXTS.get(name, []):
        if s[pos:pos + len(part)] != part:
            break
        lines.append(part)
        pos += len(part)
    if pos < len(s):
        lines.append(s[pos:])
    return '\n'.join(esc(x) for x in lines) + '\n'


def text_import(txt):
    return ''.join(unesc(x) for x in txt.split('\n') if x != '').encode('latin-1')


# ---- tables
def fmt(kind, data):
    if kind == 'd':
        return str(data[0])
    if kind == 's':
        return str(data[0] - 256 if data[0] > 127 else data[0])
    if kind == 'x':
        return '$%02X' % data[0]
    if kind == 'b':
        return '%02X' % data[0]
    if kind == 'w':
        return '$%04X' % (data[0] | data[1] << 8)
    return data.decode('latin-1')


def size(kind):
    return 2 if kind == 'w' else int(kind[1:]) if kind[0] == 't' else 1


def parse(kind, text):
    if kind in 'ds':
        return bytes([int(text) & 255])
    if kind == 'x':
        return bytes([int(text.lstrip('$'), 16)])
    if kind == 'b':
        return bytes([int(text, 16)])
    if kind == 'w':
        v = int(text.lstrip('$'), 16)
        return bytes([v & 255, v >> 8])
    return text.encode('latin-1')


def table_export(name, data):
    if name == 'objects':
        return objects_export(data)
    rec, fields = TABLES[name]
    f = io.StringIO()
    w = csv.writer(f, lineterminator='\n')
    w.writerow([n for n, _ in fields])
    whole = len(data) // rec * rec
    for i in range(0, whole, rec):
        row, o = [], i
        for _, k in fields:
            row.append(fmt(k, data[o:o + size(k)]))
            o += size(k)
        w.writerow(row)
    if whole < len(data):
        w.writerow(['tail'] + ['$%02X' % b for b in data[whole:]])
    return f.getvalue()


def table_import(name, txt):
    if name == 'objects':
        return objects_import(txt)
    _rec, fields = TABLES[name]
    out = bytearray()
    for row in list(csv.reader(io.StringIO(txt)))[1:]:
        if row and row[0] == 'tail':
            out += bytes(int(x.lstrip('$'), 16) for x in row[1:])
            continue
        for (_, k), v in zip(fields, row):
            out += parse(k, v)
    return bytes(out)


def objects_export(data):
    """the eight lists: a head line (farthest row, aligned row) then the entries up to the farthest row"""
    f = io.StringIO()
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['kind', 'type', 'threshold', 'y_offset', 'rows', 'width', 'address'])
    o, n = 0, 0
    while o < len(data):
        far, aligned = data[o], data[o + 1]
        w.writerow(['head', OBJECT_ORDER[n], far, aligned, '', '', ''])
        o += 2
        while True:
            e = data[o:o + 6]
            w.writerow(['entry', OBJECT_ORDER[n], e[0], e[1], e[2], e[3], '$%04X' % (e[4] | e[5] << 8)])
            o += 6
            if e[0] >= far:
                break
        n += 1
    return f.getvalue()


def objects_import(txt):
    out = bytearray()
    for row in list(csv.reader(io.StringIO(txt)))[1:]:
        if row[0] == 'head':
            out += bytes([int(row[2]), int(row[3])])
        else:
            a = int(row[6].lstrip('$'), 16)
            out += bytes([int(row[2]), int(row[3]), int(row[4]), int(row[5]), a & 255, a >> 8])
    return bytes(out)


def columns_export(name, data):
    cols = COLUMNS[name]
    n = len(data) // len(cols)
    f = io.StringIO()
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['row'] + cols)
    for r in range(n):
        w.writerow([r] + [data[c * n + r] for c in range(len(cols))])
    return f.getvalue()


def columns_import(name, txt):
    rows = list(csv.reader(io.StringIO(txt)))[1:]
    return bytes(int(rows[r][1 + c]) for c in range(len(COLUMNS[name])) for r in range(len(rows)))


# ---- pictures
def new_image(w, h, fill):
    img = Image.new('P', (w, h), fill)
    img.putpalette(sum(PALETTE, ()))
    return img


def put_bits(img, x, y, b):
    for bit in range(8):
        img.putpixel((x + bit, y), (b >> (7 - bit)) & 1)


def get_bits(img, x, y):
    b = 0
    for bit in range(8):
        b = b << 1 | (img.getpixel((x + bit, y)) == 1)
    return b


def glyphs_export(name, data):
    width, heights = GLYPHS[name]
    img = new_image(8 * width * len(heights), max(heights), 2)
    o = 0
    for g, gh in enumerate(heights):
        for y in range(gh):
            for xb in range(width):
                put_bits(img, 8 * width * g + 8 * xb, y, data[o])
                o += 1
    return img


def glyphs_import(name, img):
    width, heights = GLYPHS[name]
    return bytes(get_bits(img, 8 * width * g + 8 * xb, y)
                 for g, gh in enumerate(heights) for y in range(gh) for xb in range(width))


def bitmap_export(data, width):
    img = new_image(8 * width, len(data) // width, 0)
    for i, b in enumerate(data):
        put_bits(img, 8 * (i % width), i // width, b)
    return img


def bitmap_import(img, x0=0, y0=0, width=None, rows=None):
    width = width or img.width // 8
    rows = rows or img.height
    return bytes(get_bits(img, x0 + 8 * xb, y0 + y) for y in range(rows) for xb in range(width))


def screen_view(scr):
    img = Image.new('RGB', (256, 192))
    for y in range(192):
        line = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for xb in range(32):
            b, attr = scr[line + xb], scr[6144 + 32 * (y // 8) + xb]
            bright = 8 if attr & 64 else 0
            for bit in range(8):
                ink = (b >> (7 - bit)) & 1
                img.putpixel((8 * xb + bit, y), ZX[(attr & 7 if ink else (attr >> 3) & 7) + bright])
    return img


# ---- sprites
def sprite_list(name, files):
    """the descriptors of the sprites in one file: (address, width, rows, users)"""
    lo = SPRITE_FILES[name]
    hi = lo + len(files[name])
    found = {}

    def add(a, w, r, who):
        if lo <= a < hi:
            found.setdefault((a, w, r), []).append(who)
    obj = files.get('tables/objects.bin') or load('tables/objects.bin')
    o, n = 0, 0
    while o < len(obj):
        far = obj[o]
        o += 2
        k = 0
        while True:
            e = obj[o:o + 6]
            add(e[4] | e[5] << 8, e[3], e[2], 'object type %d size %d' % (OBJECT_ORDER[n], k))
            o += 6
            k += 1
            if e[0] >= far:
                break
        n += 1
    rid = files.get('tables/riders.bin') or load('tables/riders.bin')
    for band in range(7):
        e = rid[21 * band:21 * band + 21]
        for p in range(5):
            add(e[3 + 4 * p] | e[4 + 4 * p] << 8, e[2 + 4 * p] & 127, e[1 + 4 * p] & 127,
                'rider band %d pose %d' % (band, p))
    for a, w, r, who in SPRITE_EXTRA:
        add(a, w, r, who)
    return sorted((a, w, r, users) for (a, w, r), users in found.items())


def sprites_export(name, data, files):
    lo = SPRITE_FILES[name]
    sprites = sprite_list(name, dict(files, **{name: data}))
    sheet_w, x, y, row_h, places = 256, 0, 0, 0, []
    for a, w, r, users in sprites:
        if x + 8 * w > sheet_w:
            x, y, row_h = 0, y + row_h + 2, 0
        places.append((a, w, r, x, y, users))
        x += 8 * w + 2
        row_h = max(row_h, r)
    img = new_image(sheet_w, y + row_h, 2)
    held = bytearray(len(data))
    for a, w, r, px, py, _ in places:
        for i in range(w * r):
            held[a - lo + i] = 1
            put_bits(img, px + 8 * (i % w), py + i // w, data[a - lo + i])
    f = io.StringIO()
    wr = csv.writer(f, lineterminator='\n')
    wr.writerow(['address', 'width', 'rows', 'x', 'y', 'users'])
    for a, w, r, px, py, users in places:
        wr.writerow(['$%04X' % a, w, r, px, py, '; '.join(users)])
    for i, h in enumerate(held):
        if not h:
            wr.writerow(['bytes', '$%04X' % (lo + i), '$%02X' % data[i], '', '', 'held by no descriptor'])
    return img, f.getvalue()


def sprites_import(name, img, txt):
    lo = SPRITE_FILES[name]
    parts = []
    for row in list(csv.reader(io.StringIO(txt)))[1:]:
        if row[0] == 'bytes':
            parts.append((int(row[1].lstrip('$'), 16), bytes([int(row[2].lstrip('$'), 16)])))
        else:
            a, w, r, x, y = int(row[0].lstrip('$'), 16), int(row[1]), int(row[2]), int(row[3]), int(row[4])
            parts.append((a, bitmap_import(img, x, y, w, r)))
    out = bytearray(max(a + len(d) for a, d in parts) - lo)
    for a, d in parts:
        out[a - lo:a - lo + len(d)] = d
    return bytes(out)


# ---- tunes
def tunes_export(data, org=0x66CA):
    names = {0x66CA: 'Tune2A', 0x6701: 'Tune1A', 0x6725: 'Tune2B', 0x6790: 'Tune1B'}
    calls, o = set(), 0
    while o < len(data):  # the phrases' addresses first
        b = data[o]
        if b == 0xFC:
            calls.add(data[o + 1] | data[o + 2] << 8)
        o += 2 if b < 0xC8 or b == 0xFE else 3 if b == 0xFC else 1
    lines, o = [TUNE_HELP], 0
    while o < len(data):
        a = org + o
        if a in names or a in calls:
            lines.append('stream $%04X %s' % (a, names.get(a, 'Phrase%04X' % a)))
        b = data[o]
        if b < 0xC8:
            lines.append('  %d %02X' % (b, data[o + 1]))
            o += 2
        elif b == 0xFE:
            lines.append('  repeat %d' % data[o + 1])
            o += 2
        elif b == 0xFC:
            lines.append('  call $%04X' % (data[o + 1] | data[o + 2] << 8))
            o += 3
        else:
            lines.append('  ' + {0xFD: 'end', 0xFB: 'return', 0xC9: 'restart', 0xCA: 'mark'}.get(b, 'byte %02X' % b))
            o += 1
    return '\n'.join(lines) + '\n'


def tunes_import(txt, org=0x66CA):
    out = bytearray()
    for line in txt.split('\n'):
        w = line.split('#')[0].split()
        if not w:
            continue
        if w[0] == 'stream':
            assert int(w[1].lstrip('$'), 16) == org + len(out), 'tunes.txt: %s is not at its address' % line
        elif w[0] == 'repeat':
            out += bytes([0xFE, int(w[1])])
        elif w[0] == 'call':
            a = int(w[1].lstrip('$'), 16)
            out += bytes([0xFC, a & 255, a >> 8])
        elif w[0] in ('end', 'return', 'restart', 'mark'):
            out.append({'end': 0xFD, 'return': 0xFB, 'restart': 0xC9, 'mark': 0xCA}[w[0]])
        elif w[0] == 'byte':
            out.append(int(w[1], 16))
        else:
            out += bytes([int(w[0]), int(w[1], 16)])
    return bytes(out)


# ---- the track
def track_parse(data, start, end):
    """the commands from start to end (offsets in data): [(offset, words)]"""
    out, o = [], start
    while o < end:
        b = data[o]
        h = b & 0xF0
        if h == 0xE0:
            a, n = data[o + 1] | data[o + 2] << 8, data[o + 3] | data[o + 4] << 8
            out.append((o, ['call', '$%04X' % a, 'forever' if n == 0xFFFF else str(n)]
                        + ([] if b == 0xE0 else ['/%02X' % b])))
            o += 5
        elif h == 0xC0:
            d = data[o + 1] - (256 if data[o + 1] > 127 else 0)
            out.append((o, ['jump', '$%04X' % (COPY_ORG + o + 2 + d)] + ([] if b == 0xC0 else ['/%02X' % b])))
            o += 2
        elif h in (0xD0, 0xF0, 0xB0):
            out.append((o, [{0xD0: 'ret', 0xF0: 'mark', 0xB0: 'var'}[h], str(b & 15)]))
            o += 1
        else:
            x = data[o + 1] - (256 if data[o + 1] > 127 else 0)
            out.append((o, ['obj', str(h >> 4), str(b & 15), str(x)]))
            o += 2
    return out


def track_stages(data):
    """the stage list: [[segment bytes] for each stage], the offset after it"""
    stages, cur, o = [], [], 0
    while len(stages) < 5:
        cur.append(data[o])
        o += 1
        if data[o - 1] & 0x20:
            stages.append(cur)
            cur = []
    return stages, o


def pattern_length(data, a):
    """the sum of the gaps of a pattern that ends in ret (None for one that loops); TrackStep does not count so
    (game_walk), this is the pattern's own extent"""
    d = 0
    for _, w in track_parse(data, a - COPY_ORG, TRACK_START - COPY_ORG):
        if w[0] == 'obj':
            d += 2 * int(w[2])
        elif w[0] == 'ret':
            return d
        elif w[0] in ('jump', 'call'):
            return None
    return None


RACE_END = 128 * 140 + 512  # past the race's end (stage 5's last pattern loops for ever): the walk stops there


def game_walk(data, limit=RACE_END):
    """the track walked as AdvanceTrack and TrackStep walk it (copy addresses):
    (elements [(position, address, type, x, VarObject)], marks [(position, address)], calls {address: position}).
    An element's gap (low nibble x 2) is its distance from the previous element. TrackStep adds the gap to every open
    call's count when it arrives at the element; the call whose count reaches its length returns to its caller from
    that element, which is not placed: a call places only the elements less than its length from where it began,
    and it counts from the last element before it (calls: that position). A mark or a call met while stepping from an
    element gets that element's position."""
    mem = bytearray(0x10000)
    mem[COPY_ORG:COPY_ORG + len(data)] = data
    frames, var, ptr, pos = [], 0, TRACK_START, 0
    elements, marks, calls = [], [], {}

    def step(hl):
        nonlocal var
        hl += 2
        for _ in range(100000):
            b = mem[hl]
            h = b & 0xF0
            if h == 0xF0:
                marks.append((pos, hl))
                hl += 1
            elif h == 0xE0:
                calls.setdefault(hl, pos)
                frames.append([hl + 5, mem[hl + 3] | mem[hl + 4] << 8, 0])
                hl = mem[hl + 1] | mem[hl + 2] << 8
            elif h == 0xD0:
                hl = frames.pop()[0]
            elif h == 0xC0:
                d = mem[hl + 1] - (256 if mem[hl + 1] > 127 else 0)
                calls.setdefault(hl, pos)
                hl += 2 + d
            elif h == 0xB0:
                calls.setdefault(hl, pos)
                var = (b & 15) * 2
                hl += 1
            else:
                gap, back = (b & 15) * 2, None
                for k in range(len(frames) - 1, -1, -1):
                    frames[k][2] += gap
                    if frames[k][2] >= frames[k][1]:
                        back = k
                if back is None:
                    return hl
                hl = frames[back][0]
                del frames[back:]
        raise ValueError('track: no element after $%04X' % hl)

    while pos < limit:
        elements.append((pos, ptr, mem[ptr] >> 4, mem[ptr + 1] - (256 if mem[ptr + 1] > 127 else 0), var))
        ptr = step(ptr)
        pos += (mem[ptr] & 15) * 2
    return elements, marks, calls


def track_walk(data):
    """the track's top-level commands with the distance at each, as the game counts it (game_walk): an element its
    position, a call, jump, mark or var the position of the element before it; None for a command the walk never
    reaches: [(offset, words, distance)]"""
    elements, marks, calls = game_walk(data)
    at = {a: p for p, a, _t, _x, _v in elements}
    at.update({a: p for p, a in marks})
    at.update(calls)
    return [(o, w, at.get(COPY_ORG + o)) for o, w in track_parse(data, TRACK_START - COPY_ORG, TRACK_END - TRACK_ORG)]


def track_export(data):
    """{file: text}: track/stage1.txt ... stage5.txt (segments and the track's part), track/patterns.txt"""
    stages, list_end = track_stages(data)
    track_start = TRACK_START - COPY_ORG
    pats = track_parse(data, list_end, track_start)
    walk = track_walk(data)
    starts = {int(w[1].lstrip('$'), 16) for _, w, _ in walk if w[0] == 'call'}
    starts |= {int(w[1].lstrip('$'), 16) for _, w in pats if w[0] in ('call', 'jump')}
    lines = [TRACK_HELP, 'patterns']
    for o, w in pats:
        a = COPY_ORG + o
        if a in starts or o == list_end:
            lines.append('pattern $%04X%s' % (a, '' if a in starts else '  # no call or jump reaches it'))
        lines.append('  ' + ' '.join(w))
    files = {'track/patterns.txt': '\n'.join(lines) + '\n'}
    borders, total = [], 0
    for s in stages:
        total += 128 * len(s)
        borders.append(total)
    k, part = 0, [[] for _ in stages]
    for _o, w, dist in walk:
        while k < 4 and dist is not None and dist >= borders[k]:
            k += 1
        part[k].append('  %s  # %s' % (' '.join(w), 'not reached' if dist is None else dist))
    part[4].append('  bytes %s  # leftovers after the track' % ' '.join('%02X' % b for b in data[TRACK_END - TRACK_ORG:]))
    for n, s in enumerate(stages):
        toks = ['%d.%d.%d' % (b & 3, (b >> 2) & 3, (b >> 4) & 1) + ('' if b & 0xC0 == 0x80 else '/%02X' % (b & 0xC0))
                for b in s]
        head = ['# Stage %d: %d segments, %d units; the track from %d to %d'
                % (n + 1, len(s), 128 * len(s), borders[n] - 128 * len(s), borders[n]), STAGE_HELP, 'segments']
        head += ['  ' + ' '.join(toks[i:i + 8]) for i in range(0, len(toks), 8)] + ['track']
        files['track/stage%d.txt' % (n + 1)] = '\n'.join(head + part[n]) + '\n'
    return files


def track_import(texts):
    segs, cmds = [], []
    for n in range(1, 6):
        mode, stage = None, []
        for line in texts['track/stage%d.txt' % n].split('\n'):
            w = line.split('#')[0].split()
            if not w:
                continue
            if w[0] in ('segments', 'track'):
                mode = w[0]
            elif mode == 'segments':
                for t in w:
                    v, _, hi = t.partition('/')
                    hl, cv, dr = (int(x) for x in v.split('.'))
                    stage.append(hl | cv << 2 | dr << 4 | (int(hi, 16) if hi else 0x80))
            else:
                cmds.append(w)
        stage[-1] |= 0x20
        segs += stage
    pats = [w for w in (line.split('#')[0].split() for line in texts['track/patterns.txt'].split('\n'))
            if w and w[0] not in ('patterns', 'pattern')]
    out = bytearray(segs)
    for w in pats + cmds:
        if w[0] == 'call':
            a, n = int(w[1].lstrip('$'), 16), 0xFFFF if w[2] == 'forever' else int(w[2])
            out += bytes([int(w[3][1:], 16) if len(w) > 3 else 0xE0, a & 255, a >> 8, n & 255, n >> 8])
        elif w[0] == 'jump':
            d = int(w[1].lstrip('$'), 16) - (COPY_ORG + len(out) + 2)
            out += bytes([int(w[2][1:], 16) if len(w) > 2 else 0xC0, d & 255])
        elif w[0] in ('ret', 'mark', 'var'):
            out.append({'ret': 0xD0, 'mark': 0xF0, 'var': 0xB0}[w[0]] | int(w[1]))
        elif w[0] == 'obj':
            out += bytes([int(w[1]) << 4 | int(w[2]), int(w[3]) & 255])
        elif w[0] == 'bytes':
            out += bytes(int(x, 16) for x in w[1:])
    return bytes(out)


# ---- install, build, check
def kind(name):
    stem = os.path.splitext(os.path.basename(name))[0]
    if name.startswith('texts/'):
        return 'text'
    if name in GLYPHS:
        return 'glyphs'
    if name.startswith('tables/') and stem in COLUMNS:
        return 'columns'
    if name.startswith('tables/') and stem in TABLES or name == 'sound/notes.bin':
        return 'table'
    if name.startswith('horizons/'):
        return 'bitmap'
    if name in SPRITE_FILES:
        return 'sprites'
    if name == 'sound/tunes.bin':
        return 'tunes'
    if name == 'track/tables.bin':
        return 'track'
    return None


def editable(name, data, files):
    """{path under src/res: str, Image or bytes} for one resource"""
    base = os.path.splitext(name)[0]
    stem = os.path.basename(base)
    k = kind(name)
    if k == 'text':
        return {base + '.txt': text_export(stem, data)}
    if k == 'table':
        return {base + '.csv': table_export(stem, data)}
    if k == 'columns':
        return {base + '.csv': columns_export(stem, data)}
    if k == 'glyphs':
        return {base + '.png': glyphs_export(name, data)}
    if k == 'bitmap':
        return {base + '.png': bitmap_export(data, 32)}
    if k == 'sprites':
        img, txt = sprites_export(name, data, files)
        return {base + '.png': img, base + '.csv': txt}
    if k == 'tunes':
        return {base + '.txt': tunes_export(data)}
    if k == 'track':
        return track_export(data)
    return {name: data}


def write(path, value):
    full = os.path.join(RES, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    if isinstance(value, Image.Image):
        value.save(full)
    elif isinstance(value, str):
        open(full, 'w', encoding='utf-8').write(value)
    else:
        open(full, 'wb').write(value)


def install(files):
    INSTALLING.clear()
    INSTALLING.update(files)
    written = {}
    for name, data in files.items():
        for path, value in editable(name, data, files).items():
            write(path, value)
            written.setdefault(name, path)
        if name == 'screens/loading.scr':
            write('screens/loading.png', screen_view(data))
    INSTALLING.clear()
    return written


def read_text(path):
    return open(os.path.join(RES, path), encoding='utf-8').read()


def build_one(name, out):
    base = os.path.splitext(name)[0]
    stem = os.path.basename(base)
    k = kind(name)
    if k == 'text':
        out[name] = text_import(read_text(base + '.txt'))
    elif k == 'table':
        out[name] = table_import(stem, read_text(base + '.csv'))
    elif k == 'columns':
        out[name] = columns_import(stem, read_text(base + '.csv'))
    elif k == 'glyphs':
        out[name] = glyphs_import(name, Image.open(os.path.join(RES, base + '.png')))
    elif k == 'bitmap':
        out[name] = bitmap_import(Image.open(os.path.join(RES, base + '.png')))
    elif k == 'sprites':
        out[name] = sprites_import(name, Image.open(os.path.join(RES, base + '.png')), read_text(base + '.csv'))
    elif k == 'tunes':
        out[name] = tunes_import(read_text(base + '.txt'))
    elif k == 'track':
        out[name] = track_import({p: read_text(p) for p in ['track/patterns.txt'] +
                                  ['track/stage%d.txt' % n for n in range(1, 6)]})
    else:
        out[name] = open(os.path.join(RES, name), 'rb').read()


def resources():
    """the @res names, from the editable files present (views and READMEs left out)"""
    names = set()
    for top, _dirs, files in os.walk(RES):
        for n in files:
            rel = os.path.relpath(os.path.join(top, n), RES)
            if n == 'README.md' or rel == 'screens/loading.png' or rel.startswith('track/course'):
                continue
            if rel.startswith('track/'):
                names.add('track/tables.bin')
                continue
            base, ext = os.path.splitext(rel)
            names.add(rel if ext in ('.scr', '.bin') else base + '.bin')
    return sorted(names)


def build(out_dir):
    out = {}
    for name in resources():
        build_one(name, out)
    for name, data in out.items():
        path = os.path.join(out_dir, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)
    return out


def check():
    bad = 0
    built = build(os.path.join(ROOT, 'work', 'stage2', 'res-check'))
    ref = os.path.join(ROOT, 'work', 'mkgame', 'res')
    for name, data in sorted(built.items()):
        status = 'ok'
        for path, value in editable(name, data, built).items():
            full = os.path.join(RES, path)
            if isinstance(value, Image.Image):
                old = Image.open(full)
                same = old.size == value.size and list(old.getdata()) == list(value.getdata())
            elif isinstance(value, str):
                same = open(full, encoding='utf-8').read() == value
            else:
                same = open(full, 'rb').read() == value
            if not same:
                status = 'BAD: %s does not come back the same' % path
        r = os.path.join(ref, name)
        if os.path.exists(r) and open(r, 'rb').read() != data:
            status = 'BAD: the bytes differ from work/mkgame/res/%s' % name
        bad += status != 'ok'
        print('%-26s %6d bytes  %s' % (name, len(data), status))
    print('res: %d resources, %d bad' % (len(built), bad))
    return bad


def export(src):
    files = {}
    for top, _dirs, names in os.walk(src):
        for n in names:
            p = os.path.join(top, n)
            files[os.path.relpath(p, src)] = open(p, 'rb').read()
    install(files)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check', 'export'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--from', dest='src', default=os.path.join(ROOT, 'work', 'mkgame', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    if args.command == 'export':
        export(args.src)
        return 0
    return 1 if check() else 0


if __name__ == '__main__':
    sys.exit(main())

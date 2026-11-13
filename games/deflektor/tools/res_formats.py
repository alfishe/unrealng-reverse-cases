#!/usr/bin/env python3
"""Deflektor's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of src/game/game.ann.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN (and the tape loads)
    python3 tools/res_formats.py check                     # every file -> bytes = the image's bytes, and back unchanged
    python3 tools/res_formats.py install-from-image        # install() with the bytes of the image and work/parts

The formats (src/res/README.md and each folder's README.md list the files, addresses and readers):
- Attribute pictures (screens/title.png, screens/panel.png, graphics/cells.png): an indexed PNG whose palette index
  holds the whole attribute and the pixel: index = BRIGHT x 128 + pixel x 64 + INK x 8 + PAPER, each index coloured as
  the Spectrum shows it. Every pixel of a character cell must carry the same attribute (bits 7, 5-0 of the index);
  FLASH is in the text chunk `dk` (`flash`: the list of flashing cells). The layout is in `dk` too:
  `screen` (the Spectrum's 6912-byte screen), `linear` (pixel rows of 32 bytes top to bottom, then the attributes:
  PanelPicture, as DrawPanel `$A50C` copies it), `chars` (two blocks: 8 bytes a character, and one attribute a
  character; 16 characters a row of the sheet: CellGraphics `$D700` and CellColours `$DF00` in one file).
- 1-bit glyphs (graphics/font.png, graphics/beam-glyphs.png, leftovers/beam-glyphs-spare.png, loader/glyphs.png):
  8 x 8 characters, 8 bytes each, 16 a row; palette 0 paper (black), 1 ink (white), 2 grey (no character there);
  `dk` holds the count and the first character's number.
- Levels (levels/levels.txt): the 64 slots of LevelData `$B000`, one `slot N` line and 9 lines of 15 cell tokens each
  (levels/README.md has the legend).
- Tables (tables/*.csv): `#` lines comments, a header line naming the columns, then one record a line; numbers decimal
  or `$hex`; a column whose name starts with `_` is written for the reader and not read back.
- Hex text (loader/script.txt): `"text"` for printable runs, two hex digits a byte otherwise; `$ADDR:` at a line's start
  and `#` lines are comments.
Any other file (leftovers/*.bin) stays its bytes.
"""
import argparse
import csv
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
IMAGE = os.path.join(ROOT, 'work', 'mkgame', 'original.bin')
PARTS = os.path.join(ROOT, 'work', 'parts')


def num(t):
    t = t.strip()
    neg = t.startswith('-')
    t = t.lstrip('-')
    v = int(t[1:], 16) if t.startswith('$') else int(t, 0)
    return -v if neg else v


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.lstrip().startswith('#')]


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


def hx(b):
    return '$%02X' % b


def sgn(b):
    return b - 256 if b > 127 else b


def sw(lo, hi):
    v = lo | hi << 8
    return v - 65536 if v > 32767 else v


# ---------------------------------------------------------------------------------------------------------------
# PNG helpers
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    level = 0xFF if bright else 0xCD
    return [level if colour & 2 else 0, level if colour & 4 else 0, level if colour & 1 else 0]


def attr_palette():
    pal = []
    for i in range(256):
        bright, bit, ink, paper = i >> 7, i >> 6 & 1, i >> 3 & 7, i & 7
        pal += zx_rgb(ink if bit else paper, bright)
    return pal


MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]


def save_png(img, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text('dk', json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def open_png(raw):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    if img.mode != 'P':
        raise ValueError('not an indexed PNG (palette mode P)')
    return img, img.load(), json.loads(img.text['dk'])


# ---------------------------------------------------------------------------------------------------------------
# Attribute pictures: cells of 8 x 8 pixels, each cell one attribute
# ---------------------------------------------------------------------------------------------------------------
def screen_offset(y, cx):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | cx


def attr_png(cols, rows, pixel, attr, meta):
    """pixel(cx, y) -> the byte, attr(cx, cy) -> the attribute, or None for no cell (left at index 0)"""
    from PIL import Image
    img = Image.new('P', (cols * 8, rows * 8), 0)
    img.putpalette(attr_palette())
    px = img.load()
    flash = []
    for cy in range(rows):
        for cx in range(cols):
            a = attr(cx, cy)
            if a is None:
                continue
            if a & 0x80:
                flash.append(cy * cols + cx)
            base = (a & 0x40) << 1 | (a & 7) << 3 | (a >> 3 & 7)
            for k in range(8):
                b = pixel(cx, cy * 8 + k)
                for x in range(8):
                    px[cx * 8 + x, cy * 8 + k] = base | ((b >> (7 - x)) & 1) << 6
    return save_png(img, dict(meta, flash=flash))


def read_attr_png(raw, cells):
    """-> {(cx, cy): (attribute, [8 bytes])} for the cells listed"""
    img, px, meta = open_png(raw)
    flash = set(meta.get('flash', []))
    cols = img.size[0] // 8
    out = {}
    for cx, cy in cells:
        a = None
        rows = []
        for k in range(8):
            b = 0
            for x in range(8):
                i = px[cx * 8 + x, cy * 8 + k]
                v = (i >> 7) << 6 | (i & 7) << 3 | (i >> 3 & 7)
                if a is None:
                    a = v
                elif v != a:
                    raise ValueError('cell (%d, %d) holds two attributes' % (cx, cy))
                b = b << 1 | (i >> 6 & 1)
            rows.append(b)
        if cy * cols + cx in flash:
            a |= 0x80
        out[(cx, cy)] = (a, rows)
    return out


def screen_to_png(d):
    if len(d) != 6912:
        raise ValueError('a screen is 6912 bytes, not %d' % len(d))
    return attr_png(32, 24, lambda cx, y: d[screen_offset(y, cx)], lambda cx, cy: d[6144 + cy * 32 + cx],
                    {'layout': 'screen'})


def png_to_screen(raw):
    cells = read_attr_png(raw, [(cx, cy) for cy in range(24) for cx in range(32)])
    out = bytearray(6912)
    for (cx, cy), (a, rows) in cells.items():
        out[6144 + cy * 32 + cx] = a
        for k in range(8):
            out[screen_offset(cy * 8 + k, cx)] = rows[k]
    return bytes(out)


def linear_to_png(d, char_rows=4):
    n = char_rows * 32
    if len(d) != n * 9:
        raise ValueError('a %d-row linear picture is %d bytes, not %d' % (char_rows, n * 9, len(d)))
    return attr_png(32, char_rows, lambda cx, y: d[y * 32 + cx], lambda cx, cy: d[n * 8 + cy * 32 + cx],
                    {'layout': 'linear', 'rows': char_rows})


def png_to_linear(raw):
    _, _, meta = open_png(raw)
    rows = meta['rows']
    cells = read_attr_png(raw, [(cx, cy) for cy in range(rows) for cx in range(32)])
    out = bytearray(rows * 32 * 9)
    for (cx, cy), (a, px) in cells.items():
        out[rows * 256 + cy * 32 + cx] = a
        for k in range(8):
            out[(cy * 8 + k) * 32 + cx] = px[k]
    return bytes(out)


def chars_to_png(glyph_bytes, colours):
    """CellGraphics (8 bytes a character) and CellColours (a byte a character): one cell a character, 16 a row"""
    count = len(colours)
    if len(glyph_bytes) != 8 * count:
        raise ValueError('%d glyph bytes for %d colours' % (len(glyph_bytes), count))
    rows = (count + 15) // 16

    def attr(cx, cy):
        n = cy * 16 + cx
        return colours[n] if n < count else None

    def pixel(cx, y):
        n = (y >> 3) * 16 + cx
        return glyph_bytes[8 * n + (y & 7)] if n < count else 0
    return attr_png(16, rows, pixel, attr, {'layout': 'chars', 'count': count})


def png_to_chars(raw):
    _, _, meta = open_png(raw)
    count = meta['count']
    cells = read_attr_png(raw, [(n % 16, n // 16) for n in range(count)])
    graphics, colours = bytearray(), bytearray()
    for n in range(count):
        a, px = cells[(n % 16, n // 16)]
        graphics += bytes(px)
        colours.append(a)
    return [bytes(graphics), bytes(colours)]


# ---------------------------------------------------------------------------------------------------------------
# 1-bit glyphs: 8 x 8, 8 bytes each, 16 a row
# ---------------------------------------------------------------------------------------------------------------
def glyphs_to_png(d, first=0):
    from PIL import Image
    if len(d) % 8:
        raise ValueError('%d bytes: no whole 8-byte glyphs' % len(d))
    count = len(d) // 8
    rows = (count + 15) // 16
    img = Image.new('P', (128, rows * 8), 2)
    img.putpalette(MONO + [0] * (768 - len(MONO)))
    px = img.load()
    for n in range(count):
        for k in range(8):
            b = d[8 * n + k]
            for x in range(8):
                px[(n % 16) * 8 + x, (n // 16) * 8 + k] = (b >> (7 - x)) & 1
    return save_png(img, {'layout': 'glyphs', 'count': count, 'first': first})


def png_to_glyphs(raw):
    _, px, meta = open_png(raw)
    out = bytearray()
    for n in range(meta['count']):
        for k in range(8):
            b = 0
            for x in range(8):
                v = px[(n % 16) * 8 + x, (n // 16) * 8 + k]
                if v not in (0, 1):
                    raise ValueError('glyph %d, pixel %d,%d is %d, neither paper (0) nor ink (1)' % (n, x, k, v))
                b = b << 1 | v
            out.append(b)
    return bytes(out)


def glyphs(first=0):
    return ('.png', lambda d: glyphs_to_png(d, first), png_to_glyphs)


# ---------------------------------------------------------------------------------------------------------------
# Levels: LevelData $B000, 64 slots of 135 cell codes (9 rows of 15)
# ---------------------------------------------------------------------------------------------------------------
WALL_MASKS = [1, 2, 4, 8, 3, 12, 5, 10, 9, 6, 7, 11, 14, 13, 15]  # codes $21-$2F / $30-$3E: quarters TL 1 TR 2 BL 4 BR 8
DIRS = 'ESWN'


def cell_token(c):
    base, turning = c & 0x7F, c & 0x80
    if turning and not 0x01 <= base <= 0x20:
        return '$%02X' % c
    if base == 0:
        return '...'
    if base <= 0x10:
        t = 'M%02d' % (base - 1)
    elif base <= 0x18:
        t = 'PC%d' % (base - 0x11)
    elif base <= 0x20:
        t = 'PY%d' % (base - 0x19)
    elif base <= 0x2F:
        return 'WA%X' % WALL_MASKS[base - 0x21]
    elif 0x30 <= base <= 0x3E:
        return 'WR%X' % WALL_MASKS[base - 0x30]
    elif base == 0x40:
        return 'CEL'
    elif base == 0x41:
        return 'MIN'
    elif base == 0x42:
        return 'PRS'
    elif 0x47 <= base <= 0x4A:
        return 'L-' + DIRS[base - 0x47]
    elif 0x4B <= base <= 0x4E:
        return 'R-' + DIRS[base - 0x4B]
    elif 0x50 <= base <= 0x57:
        return 'F%d%s' % ((base - 0x50) >> 1, 'ab'[base & 1])
    else:
        return '$%02X' % c
    return t.lower() if turning else t


TOKENS = {cell_token(c): c for c in range(256)}
assert len(TOKENS) == 256


def slot_title(s):
    if s < 60:
        return 'level %d' % (s + 1)
    if s < 63:
        return 'practice P%d' % (s - 59)
    return 'unused (never set up)'


def levels_out(d):
    if len(d) != 64 * 135:
        raise ValueError('LevelData is 64 x 135 bytes, not %d' % len(d))
    out = ['# LevelData $B000: the 64 level slots, 135 bytes each (9 rows of 15 cells), in slot order.',
           '# A `slot N` line starts a slot (the words after N are a comment); then 9 rows of 15 tokens. Legend in',
           '# levels/README.md: ... empty, Mnn mirror (angle nn), PCn / PYn cyan / yellow polariser (angle n), WAm / WRm',
           '# absorbing / reflecting wall (quarters m: 1 top left, 2 top right, 4 bottom left, 8 bottom right), CEL cell,',
           '# MIN mine, PRS prism, L-d laser, R-d receiver (d: E S W N), Fna / Fnb fibre-optic pair n; lower case: the',
           '# element turns by itself (bit 7); $HH any other code.']
    for s in range(64):
        out.append('')
        out.append('slot %d  %s  $%04X' % (s, slot_title(s), 0xB000 + 135 * s))
        for r in range(9):
            row = d[135 * s + 15 * r:135 * s + 15 * r + 15]
            out.append(' '.join(cell_token(c) for c in row))
    return text_file(out)


def levels_in(raw):
    out = bytearray()
    expect = 0
    rows = 0
    for ln in lines_of(raw):
        w = ln.split()
        if w[0] == 'slot':
            if rows != 9 * expect or int(w[1]) != expect:
                raise ValueError('slot %s out of order (expected slot %d after 9 rows each)' % (w[1], expect))
            expect += 1
            continue
        if len(w) != 15:
            raise ValueError('a row has %d tokens, not 15: %s' % (len(w), ln))
        for t in w:
            if t not in TOKENS:
                raise ValueError('unknown cell token %r' % t)
            out.append(TOKENS[t])
        rows += 1
    if expect != 64 or rows != 64 * 9:
        raise ValueError('%d slots, %d rows: 64 slots of 9 rows wanted' % (expect, rows))
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Tables (CSV)
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, header, rows):
    s = io.StringIO()
    for c in comments:
        s.write('# ' + c + '\n')
    w = csv.writer(s, lineterminator='\n')
    w.writerow(header)
    for r in rows:
        w.writerow(r)
    return s.getvalue().encode('utf-8')


def csv_in(raw):
    lines = [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.startswith('#')]
    rows = list(csv.reader(lines))
    header = rows[0]
    return [{k: v for k, v in zip(header, r) if not k.startswith('_')} for r in rows[1:]]


PASS = {0: 'in', 1: 'out', 2: 'corner', 3: 'both'}
UNPASS = {v: k for k, v in PASS.items()}


def glyph_byte(b):
    return '%s:%d' % (PASS[b >> 6], b & 0x3F)


def unglyph(t):
    p, g = t.split(':')
    return UNPASS[p.strip()] << 6 | num(g)


def beam_glyphs_out(d):
    rows = [[i >> 4, i & 15] + [glyph_byte(b) for b in d[4 * i:4 * i + 4]] for i in range(32)]
    return csv_out(['BeamGlyphBytes $8000: four bytes a direction (the characters up-left, up-right, down-left,',
                    'down-right of the vertex); set 0 at $8000 (steady), set 1 at $8040 (the flashing set: BeamGlyphSet',
                    '$8381 = $40). PASS:GLYPH: the pass that draws it (in = BeamInChar $9278, out = BeamOutChar $94FD,',
                    'corner = BeamCornerChar $9440; bits 7-6 of the byte) and the glyph, BeamGlyphs $D500 + 8 x GLYPH.'],
                   ['set', 'direction', 'up_left', 'up_right', 'down_left', 'down_right'], rows)


def beam_glyphs_in(raw):
    out = bytearray()
    for r in csv_in(raw):
        out += bytes(unglyph(r[k]) for k in ('up_left', 'up_right', 'down_left', 'down_right'))
    return bytes(out)


def word(v):
    return (num(v) & 0xFFFF).to_bytes(2, 'little') if isinstance(v, str) else (v & 0xFFFF).to_bytes(2, 'little')


def out_bounce_out(d):
    rows = []
    for i in range(16):
        e = d[8 * i:8 * i + 8]
        rows.append([i, sw(e[0], e[1]), sw(e[2], e[3])] + list(e[4:8]))
    return csv_out(['OutBounceTable $8080: 8 bytes for each new direction (BeamReflectOut $965A, BeamCornerChar $94E9).',
                    'test1 / test2: offsets (words) from the up-left character of the vertex in the character map;',
                    'none / first / second / both: the bounced direction by which of the two characters are walls',
                    '($31-$72). The corner pass reads only `both`. The axis directions\' rows are not read.'],
                   ['direction', 'test1', 'test2', 'none', 'first', 'second', 'both'], rows)


def out_bounce_in(raw):
    out = bytearray()
    for r in csv_in(raw):
        out += word(r['test1']) + word(r['test2']) + bytes(num(r[k]) & 0xFF for k in ('none', 'first', 'second', 'both'))
    return bytes(out)


def in_corner_out(d):
    rows = []
    for i in range(4):
        e = d[16 * i:16 * i + 16]
        r = [4 * i + 2, sw(e[0], e[1]), sw(e[2], e[3])]
        for k in range(4):
            r += [e[4 + 3 * k], sgn(e[5 + 3 * k]), sgn(e[6 + 3 * k])]
        rows.append(r)
    head = ['diagonal', 'test1', 'test2']
    for k in ('none', 'first', 'second', 'both'):
        head += [k, k + '_dx', k + '_dy']
    return csv_out(['InCornerTable $8100: 16 bytes for each diagonal direction (2, 6, 10, 14), reached by BeamReflectIn',
                    '$93F2 through InBounceTable ($80 + 16 n). test1 / test2: offsets (words) from the up-left character',
                    'of the vertex; then for none / first / second / both of them walls: the new direction and the step',
                    '(dx, dy) to the vertex the beam leaves from. Known only from the code: no recording ran it.'],
                   head, rows)


def in_corner_in(raw):
    out = bytearray()
    for r in csv_in(raw):
        out += word(r['test1']) + word(r['test2'])
        for k in ('none', 'first', 'second', 'both'):
            out += bytes([num(r[k]) & 0xFF, num(r[k + '_dx']) & 0xFF, num(r[k + '_dy']) & 0xFF])
    return bytes(out)


def in_bounce_out(d):
    rows = []
    for i in range(16):
        e = d[3 * i:3 * i + 3]
        rows.append([i, hx(e[0]) if e[0] & 0x80 else e[0], sgn(e[1]), sgn(e[2])])
    return csv_out(['InBounceTable $8140: 3 bytes for each incoming direction (BeamReflectIn $93DE), read for the',
                    'slopes and diagonals only. new: the bounced direction, or $80 + n for a diagonal (InCornerTable',
                    '$8100 + n decides); dx, dy: the step to the vertex the beam leaves from.'],
                   ['direction', 'new', 'dx', 'dy'], rows)


def in_bounce_in(raw):
    return bytes(b for r in csv_in(raw) for b in (num(r['new']) & 0xFF, num(r['dx']) & 0xFF, num(r['dy']) & 0xFF))


def deltas_out(d):
    return csv_out(['BeamDeltas $8170: the step of each of the 16 directions in half-cells (dx, dy): 0 east, 4 south,',
                    '8 west, 12 north, clockwise. Read by FindLaser $8AF7, OpenReceiver $8B6A, BeamStep $9230.'],
                   ['direction', 'dx', 'dy'], [[i, sgn(d[2 * i]), sgn(d[2 * i + 1])] for i in range(16)])


def deltas_in(raw):
    return bytes(b for r in csv_in(raw) for b in (num(r['dx']) & 0xFF, num(r['dy']) & 0xFF))


def words_out(comments, names, per):
    def out(d):
        rows = []
        for i in range(len(d) // (2 * per)):
            rows.append([names[i]] + [sw(d[2 * (per * i + k)], d[2 * (per * i + k) + 1]) for k in range(per)])
        return csv_out(comments, ['_row'] + ['w%d' % k for k in range(per)], rows)
    return out


def words_in(per):
    def back(raw):
        return b''.join(word(r['w%d' % k]) for r in csv_in(raw) for k in range(per))
    return back


GRAZE_COMMENT = ['GrazeOffsets $8190: 8 words, offsets in the character map from the character in which an axis beam',
                 'meets a wall to the character across the beam line (BeamAbsorbIn $9357, BeamReflectIn $93A2, the',
                 'outgoing tests $95D5, $9620). Word index = (character of the pass - 1) + direction / 2; for',
                 'direction 12 the third and fourth characters would read on into PolariserCells $81A0.']
POLAR_COMMENT = ['PolariserCells $81A0: 6 bytes for each of a polariser\'s four characters by the character code AND 3',
                 '(characters $31-$70 run top left, top right, bottom left, bottom right from $x1: 0 is the bottom',
                 'right one, 1 top left, 2 top right, 3 bottom left), the offsets (words) of the other three in the',
                 'character map (PolariserPassIn $9320, the outgoing pass $959E): a beam along the axis marks and',
                 'lights them.']

SOUND_NAMES = ['BurnSound', 'MineSound', 'LaserBackSound', 'BurningNoise', 'ChargeWarble', 'GremlinSound',
               'ChargedSound', 'ContactSound']


def sounds_out(d):
    rows = []
    for i, n in enumerate(SOUND_NAMES):
        e = d[5 * i:5 * i + 5]
        rows.append([n, e[0]] + [hx(b) for b in e[1:]])
    return csv_out(['The PlaySound $A8C0 records $81D4-$81FB: 5 bytes each, the kind then four parameters.',
                    'kind 0 PlayTone $A83F: p1 L (the tone), p2 H (x 256 loops), p3 p4 not read.',
                    'kind 1 PlaySweep $A85E: p1 H (the delay step, signed), p2 L (half-cycles a step), p3 D (the first',
                    'delay), p4 E (steps). kind 2 PlayNoise $A87A: p1 D (period mask), p2 E (bursts), p3 C (length',
                    'mask), p4 the opcode stored at NoiseOp $A89F ($A2 = AND D). Records 0-4 are SoundFlags bits 0-4',
                    '(PlaySoundFlags $A8A7). `_name` is the entry\'s label in game.ann; keep the rows in this order.'],
                   ['_name', 'kind', 'p1', 'p2', 'p3', 'p4'], rows)


def sounds_in(raw):
    return b''.join(bytes([num(r['kind'])] + [num(r[k]) & 0xFF for k in ('p1', 'p2', 'p3', 'p4')])
                    for r in csv_in(raw))


def cell_what(c):
    if c == 0:
        return 'empty'
    if c <= 0x10:
        return 'mirror, angle %d' % (c - 1)
    if c <= 0x18:
        return 'cyan polariser, angle %d' % (c - 0x11)
    if c <= 0x20:
        return 'yellow polariser, angle %d' % (c - 0x19)
    if c <= 0x2F:
        return 'absorbing wall, quarters %X' % WALL_MASKS[c - 0x21]
    if c <= 0x3E:
        return 'reflecting wall, quarters %X' % WALL_MASKS[c - 0x30]
    named = {0x3F: 'unused (the cell\'s characters)', 0x40: 'cell', 0x41: 'mine', 0x42: 'prism',
             0x43: 'unused (laser east, other characters)', 0x44: 'unused (laser south, other characters)',
             0x45: 'unused (laser west, other characters)', 0x46: 'unused (laser north, other characters)',
             0x47: 'laser east', 0x48: 'laser south', 0x49: 'laser west', 0x4A: 'laser north',
             0x4B: 'receiver east', 0x4C: 'receiver south', 0x4D: 'receiver west', 0x4E: 'receiver north',
             0x4F: 'unused (blank)'}
    if c in named:
        return named[c]
    if c <= 0x57:
        return 'fibre-optic end, pair %d %s' % ((c - 0x50) >> 1, 'ab'[c & 1])
    return 'explosion frame %d' % (c - 0x58)


def cell_table_out(d):
    rows = [[hx(c), hx(d[4 * c]), hx(d[4 * c + 1]), hx(d[4 * c + 2]), hx(d[4 * c + 3]), cell_what(c)]
            for c in range(len(d) // 4)]
    return csv_out(['CellTable $8200: the four character codes of each cell code (RenderGrid $8960): top left, top',
                    'right, bottom left, bottom right; each character is drawn from CellGraphics $D700 + 8 x character',
                    'in the colour CellColours $DF00 + character. Codes $00-$5C (bit 7 of a grid code is cleared first).'],
                   ['code', 'top_left', 'top_right', 'bottom_left', 'bottom_right', '_what'], rows)


def cell_table_in(raw):
    out = bytearray()
    for i, r in enumerate(csv_in(raw)):
        if num(r['code']) != i:
            raise ValueError('cell table row %d has code %s' % (i, r['code']))
        out += bytes(num(r[k]) for k in ('top_left', 'top_right', 'bottom_left', 'bottom_right'))
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Hex text: "text" runs and hex bytes
# ---------------------------------------------------------------------------------------------------------------
def printable(b):
    return 0x20 <= b < 0x7F and b not in (0x22, 0x5C)


def hextext_out(org, comments):
    def out(d):
        lines = ['# ' + c for c in comments]
        i = 0
        while i < len(d):
            start, toks, n = i, [], 0
            while i < len(d) and n < 16:
                j = i
                while j < len(d) and printable(d[j]):
                    j += 1
                if j - i >= 3:
                    toks.append('"%s"' % d[i:j].decode('ascii'))
                    n += j - i
                    i = j
                else:
                    toks.append('%02X' % d[i])
                    n += 1
                    i += 1
            lines.append('$%04X: %s' % (org + start, ' '.join(toks)))
        return text_file(lines)
    return out


def hextext_in(raw):
    out = bytearray()
    for ln in lines_of(raw):
        s = ln.strip()
        if s.startswith('$') and ':' in s[:7]:
            s = s[s.index(':') + 1:]
        i = 0
        while i < len(s):
            if s[i].isspace():
                i += 1
            elif s[i] == '"':
                j = s.index('"', i + 1)
                out += s[i + 1:j].encode('ascii')
                i = j + 1
            else:
                out.append(int(s[i:i + 2], 16))
                i += 2
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The resources: .bin name -> (suffix, bytes -> editable, editable -> bytes); groups: one editable, several .bin
# ---------------------------------------------------------------------------------------------------------------
SINGLES = {
    'screens/title.bin': ('.png', screen_to_png, png_to_screen),
    'screens/panel.bin': ('.png', linear_to_png, png_to_linear),
    'levels/levels.bin': ('.txt', levels_out, levels_in),
    'graphics/font.bin': glyphs(32),
    'graphics/beam-glyphs.bin': glyphs(0),
    'leftovers/beam-glyphs-spare.bin': glyphs(39),
    'tables/beam-glyph-bytes.bin': ('.csv', beam_glyphs_out, beam_glyphs_in),
    'tables/out-bounce.bin': ('.csv', out_bounce_out, out_bounce_in),
    'tables/in-corner.bin': ('.csv', in_corner_out, in_corner_in),
    'tables/in-bounce.bin': ('.csv', in_bounce_out, in_bounce_in),
    'tables/beam-deltas.bin': ('.csv', deltas_out, deltas_in),
    'tables/graze-offsets.bin': ('.csv', words_out(GRAZE_COMMENT, ['%d' % i for i in range(8)], 1), words_in(1)),
    'tables/polariser-cells.bin': ('.csv', words_out(POLAR_COMMENT, ['0 bottom-right', '1 top-left', '2 top-right', '3 bottom-left'],
                                                     3), words_in(3)),
    'tables/sounds.bin': ('.csv', sounds_out, sounds_in),
    'tables/cell-table.bin': ('.csv', cell_table_out, cell_table_in),
    'loader/glyphs.bin': glyphs(32),
    'loader/script.bin': ('.txt', hextext_out(0x998E, [
        'The loading screen\'s script: 6552 bytes the turbo block loads at $998E, run by stage 2\'s engine',
        '($B78E, the control codes $B8DD; work/stage2/dis/stage2.asm) while the game loads. Kept as bytes:',
        '"..." a printable run (3 or more characters $20-$7E), two hex digits any other byte; the control codes are',
        'not decoded here (loader/README.md). `$ADDR:` at a line\'s start is the address of its first byte.']),
        hextext_in),
}

GROUPS = {  # editable file -> (the .bin names, [bytes] -> editable, editable -> [bytes])
    'graphics/cells.png': (['graphics/cell-graphics.bin', 'graphics/cell-colours.bin'],
                           lambda bs: chars_to_png(bs[0], bs[1]), png_to_chars),
}

# where each resource's bytes are: (address, length) in the game image, or a file of work/parts (the loader's)
WHERE = {
    'screens/title.bin': (0x6000, 6912),
    'leftovers/gap-7b00.bin': (0x7B00, 128),
    'screens/panel.bin': (0x7B80, 1152),
    'tables/beam-glyph-bytes.bin': (0x8000, 128),
    'tables/out-bounce.bin': (0x8080, 128),
    'tables/in-corner.bin': (0x8100, 64),
    'tables/in-bounce.bin': (0x8140, 48),
    'tables/beam-deltas.bin': (0x8170, 32),
    'tables/graze-offsets.bin': (0x8190, 16),
    'tables/polariser-cells.bin': (0x81A0, 24),
    'tables/sounds.bin': (0x81D4, 40),
    'tables/cell-table.bin': (0x8200, 372),
    'levels/levels.bin': (0xB000, 8640),
    'leftovers/spare-d1c0.bin': (0xD1C0, 64),
    'graphics/font.bin': (0xD200, 768),
    'graphics/beam-glyphs.bin': (0xD500, 312),
    'leftovers/beam-glyphs-spare.bin': (0xD638, 200),
    'graphics/cell-graphics.bin': (0xD700, 1696),
    'leftovers/cell-graphics-spare.bin': (0xDDA0, 352),
    'graphics/cell-colours.bin': (0xDF00, 212),
    'leftovers/cell-colours-spare.bin': (0xDFD4, 44),
    'loader/glyphs.bin': 'glyphs-b326.bin',
    'loader/script.bin': 'script-998e.bin',
}


def image():
    if os.path.exists(IMAGE):
        return open(IMAGE, 'rb').read()
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import image as img  # noqa: E402  (decodes orig/Deflektor.tzx.zip in SkoolKit's simulator)
    return img.entry_image()


def original(name, mem=None):
    w = WHERE[name]
    if isinstance(w, str):
        path = os.path.join(PARTS, w)
        if not os.path.exists(path):
            sys.path.insert(0, os.path.join(ROOT, 'tools'))
            import parts  # noqa: E402  (cuts the parts from orig/Deflektor.tzx.zip)
            return parts.parts()[w]
        return open(path, 'rb').read()
    return (mem or image())[w[0]:w[0] + w[1]]


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path) and open(path, 'rb').read() == data:
        return
    open(path, 'wb').write(data)


def install(files):
    """the bytes of the @res entries (and of the loader's two parts) -> their editable files in src/res"""
    done = set()
    for ed, (names, to_ed, from_ed) in GROUPS.items():
        if all(n in files for n in names):
            parts = [bytes(files[n]) for n in names]
            out = to_ed(parts)
            if from_ed(out) != parts:
                raise SystemExit('res: %s does not convert back to its bytes' % ed)
            write(os.path.join(RES, ed), out)
            for n in names:
                done.add(n)
                if os.path.exists(os.path.join(RES, n)):
                    os.remove(os.path.join(RES, n))
    for name, data in files.items():
        if name in done:
            continue
        data = bytes(data)
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


def sources():
    """(rel, raw, group, single) for every file of src/res: group / single the format when it is an editable form"""
    single_of = {os.path.splitext(n)[0] + v[0]: n for n, v in SINGLES.items()}
    for top, _dirs, names in sorted(os.walk(RES)):
        for f in sorted(names):
            if f == 'README.md' or f.startswith('.'):
                continue
            rel = os.path.relpath(os.path.join(top, f), RES)
            raw = open(os.path.join(top, f), 'rb').read()
            yield rel, raw, GROUPS.get(rel), single_of.get(rel)


def to_bytes(rel, raw, group, single):
    if group:
        return list(zip(group[0], group[2](raw)))
    if single:
        return [(single, SINGLES[single][2](raw))]
    return [(rel, raw)]


def load(name):
    """the bytes of a resource (by its .bin name) from src/res, for the figures (tools/level_maps.py)"""
    for rel, raw, group, single in sources():
        for n, data in to_bytes(rel, raw, group, single):
            if n == name:
                return data
    raise KeyError(name)


def build(out):
    for rel, raw, group, single in sources():
        for name, data in to_bytes(rel, raw, group, single):
            write(os.path.join(out, name), data)


def check():
    mem = image()
    bad = count = 0
    seen = set()
    for rel, raw, group, single in sources():
        count += 1
        try:
            pairs = to_bytes(rel, raw, group, single)
            if group:
                again = group[1]([d for _, d in pairs])
            elif single:
                again = SINGLES[single][1](pairs[0][1])
            else:
                again = raw
            ok = again == raw
            if not ok:
                print('res: %s is not as install writes it (editable -> bytes -> editable differ)' % rel)
            for name, data in pairs:
                seen.add(name)
                if name not in WHERE:
                    print('res: %s: no known place for %s' % (rel, name))
                    ok = False
                elif data != original(name, mem):
                    print('res: %s: %s differs from the original bytes' % (rel, name))
                    ok = False
        except (ValueError, KeyError, IndexError) as e:
            print('res: %s: %s' % (rel, e))
            ok = False
        if not ok:
            bad += 1
    for name in sorted(set(WHERE) - seen):
        print('res: %s is missing' % name)
        bad += 1
    print('res: %d files (%d resources), %d bad' % (count, len(seen), bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check', 'install-from-image'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    if args.command == 'install-from-image':
        mem = image()
        install({n: original(n, mem) for n in WHERE})
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

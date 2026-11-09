#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- graphics/, fonts/: an indexed PNG sheet, frames left to right in rows, one grid pixel between frames; palette 0
  paper (black), 1 ink (white), 2 grid (grey). The PNG text chunk `vp-sheet` holds the layout (bytes across, bytes a
  frame, frames a row, frame count), so a sheet builds back on its own. SHEETS gives each file's layout.
- tables/: CSV with a header line naming the columns (TABLES below says what each column means); `#` lines are
  comments, not data.
- text/: the strings as UTF-8 text (TEXT below).
Any other file stays its bytes.
"""
import argparse
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

# ---------------------------------------------------------------------------------------------------------------
# PNG sheets
# ---------------------------------------------------------------------------------------------------------------
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128]

# the .bin name of the .ann's @res -> (bytes across, bytes a frame, frames a row[, 1: a line's bytes stored right to
# left])
SHEETS = {
    # the 56 ball sprites $D000: 3 bytes x 16 lines, frame = shift x 7 + ball (the cue ball, balls 1-6): one row a shift
    'graphics/BallSprites.bin': (3, 48, 7),
    # the font $DEF4: 8 x 8, the glyphs a-z then 0-9
    'fonts/Font.bin': (1, 8, 12),
    # the copyright glyph $9F2E (character $7F): 8 x 8
    'fonts/CopyrightGlyph.bin': (1, 8, 1),
    # a flag's solid line $AAD8: 56 x 1
    'graphics/SolidLine.bin': (7, 7, 1),
    # the flag's tail $AB41: 16 x 29, each line right byte first
    'graphics/FlagTail.bin': (2, 58, 1, 1),
    # the pen's shaft $BFFE: 32 x 16
    'graphics/PenShaftImage.bin': (4, 64, 1),
}


def sheet_to_png(data, wbytes, fsize, cols, rev=0):
    from PIL import Image, PngImagePlugin
    if len(data) % fsize:
        raise ValueError('%d bytes are not whole frames of %d' % (len(data), fsize))
    n = len(data) // fsize
    cols = max(1, min(cols, n))
    rows = (n + cols - 1) // cols
    fw, fh = wbytes * 8, fsize // wbytes
    img = Image.new('P', (cols * (fw + 1) + 1, rows * (fh + 1) + 1), 2)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            b = data[f * fsize + k]
            col = wbytes - 1 - k % wbytes if rev else k % wbytes
            for bit in range(8):
                px[ox + col * 8 + bit, oy + k // wbytes] = (b >> (7 - bit)) & 1
    info = PngImagePlugin.PngInfo()
    info.add_text('vp-sheet', '%d %d %d %d' % (wbytes, fsize, cols, n) + (' 1' if rev else ''))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_sheet(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    layout = [int(x) for x in img.text['vp-sheet'].split()]
    wbytes, fsize, cols, n = layout[:4]
    rev = layout[4] if len(layout) > 4 else 0
    px = img.load()
    fw, fh = wbytes * 8, fsize // wbytes
    out = bytearray(n * fsize)
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            b = 0
            col = wbytes - 1 - k % wbytes if rev else k % wbytes
            for bit in range(8):
                b = b << 1 | (1 if px[ox + col * 8 + bit, oy + k // wbytes] == 1 else 0)
            out[f * fsize + k] = b
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# CSV tables: the .bin name -> (bytes -> CSV, CSV -> bytes); the header comments say what each column means
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, columns, rows):
    lines = ['# ' + c for c in comments] + [','.join(columns)]
    lines += [','.join(str(v) for v in r) for r in rows]
    return ('\n'.join(lines) + '\n').encode()


def csv_in(raw):
    rows, header = [], None
    for line in raw.decode().split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if header is None:
            header = line.split(',')
            continue
        rows.append([c.strip() for c in line.split(',')])
    return header, rows


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


def grid_out(comments, cols, data, cell=str):
    rows = [[r] + [cell(data[r * cols + c]) for c in range(cols)] for r in range(len(data) // cols)]
    return csv_out(comments, ['row'] + ['c%d' % c for c in range(cols)], rows)


def grid_in(raw, cell=num):
    _h, rows = csv_in(raw)
    return bytes(cell(v) for r in rows for v in r[1:])


def contact_out(d, side):
    return grid_out(['row = |dy|, column cN = |dx| in whole pixels (centre to centre);',
                     '128 ($80) the balls overlap, 1-31 the contact ring cell (CollisionRecords record N), 0 apart'],
                    side, d)


def friction_cell(b):
    return '%d:%d' % (b >> 4, b & 15)


def friction_in(raw):
    return grid_in(raw, lambda v: int(v.split(':')[0]) << 4 | int(v.split(':')[1]))


def collision_out(d):
    rows = []
    for n in range(len(d) // 6):
        w = [d[n * 6 + k] | d[n * 6 + k + 1] << 8 for k in (0, 2, 4)]
        rows.append([n + 1] + w)
    return csv_out(['one record per contact ring cell N of ContactTable (dx, dy): three 8.8 words, $0100 = 1.0;',
                    'nxx = 256 dx*dx / 225, nyy = 256 dy*dy / 225, nxy = 256 |dx dy| / 225 (the distance taken as 15)'],
                   ['record', 'nxx', 'nyy', 'nxy'], rows)


def collision_in(raw):
    _h, rows = csv_in(raw)
    out = bytearray()
    for r in rows:
        for v in r[1:]:
            out += num(v).to_bytes(2, 'little')
    return bytes(out)


TABLES = {
    # $DBFA, 16 x 16: BallContacts $87EF reads 16 |dy| + |dx|
    'tables/ContactTable.bin': (lambda d: contact_out(d, 16), grid_in),
    # $DCFA, 8 x 8: PointJaw $8CF8 reads 8 |dy| + |dx| (a ball against a middle pocket's jaw point)
    'tables/Table8x8.bin': (lambda d: contact_out(d, 8), grid_in),
    # $DD3A, 16 x 16: FrictionSteps $90F5 reads 16 ny + nx; y:x the two nibbles
    'tables/FrictionTable.bin': (lambda d: grid_out(
        ['row = the |vy| nibble ny, column cN = the |vx| nibble nx;',
         'each cell y:x = the friction steps (high nibble the y step, low nibble the x step), 1/256 pixel a tick'],
        16, d, friction_cell), friction_in),
    # $DE3A, 31 records of 3 words: the ball-ball collision (BallCollide)
    'tables/CollisionRecords.bin': (collision_out, collision_in),
}

# ---------------------------------------------------------------------------------------------------------------
# Text: the print records and the pen script, as UTF-8 text
# ---------------------------------------------------------------------------------------------------------------
PRINT_HEAD = ['# The print records of PrintText $9E65, one a line: row column attribute "characters".',
              '# Attribute bit 7: double width. Characters: a-z and 0-9 the game font, \u00a9 is $7F (the copyright',
              '# glyph), other ASCII the ROM font; \\xNN any other byte, \\" and \\\\ escaped. The length byte is the',
              '# count of the characters.']


def print_out(d):
    lines, p = list(PRINT_HEAD), 0
    while p < len(d):
        row, col, attr, n = d[p], d[p + 1], d[p + 2], d[p + 3]
        if p + 4 + n > len(d):
            raise ValueError('a print record runs past the entry')
        t = ''
        for b in d[p + 4:p + 4 + n]:
            if b == 0x7F:
                t += '©'
            elif b in (0x22, 0x5C):
                t += '\\' + chr(b)
            elif 0x20 <= b < 0x7F:
                t += chr(b)
            else:
                t += '\\x%02x' % b
        lines.append('%d %d $%02X "%s"' % (row, col, attr, t))
        p += 4 + n
    return ('\n'.join(lines) + '\n').encode('utf-8')


def print_in(raw):
    out = bytearray()
    for line in raw.decode('utf-8').split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        head, t = line.split('"', 1)
        t = t[:t.rindex('"')]
        row, col, attr = (num(v) for v in head.split())
        chars, i = bytearray(), 0
        while i < len(t):
            c = t[i]
            if c == '\\':
                if t[i + 1] == 'x':
                    chars.append(int(t[i + 2:i + 4], 16))
                    i += 4
                    continue
                chars.append(ord(t[i + 1]))
                i += 2
                continue
            chars.append(0x7F if c == '©' else ord(c))
            i += 1
        out += bytes([row, col, attr, len(chars)]) + chars
    return bytes(out)


PEN_HEAD = ['# The pen script of SignatureCommand $BD23 ("written by" and the signature), one command a line:',
            '#   up / down        the pen up ($01) / down ($02)',
            '#   dot DX DY        one pixel at the pen + (DX, DY), signed bytes ($03 DX DY)',
            '#   move DX DY N     N steps (1-15) of DX, DY each in -2..1, one a frame, a pixel at (x, y - 1) per step',
            '#                    while the pen is down (one byte: DY bits 7-6, DX bits 5-4, N bits 3-0)',
            '#   end              the end ($00)',
            '# The pen starts at x 16, y 128 (set by the code, $BD18).']


def pen_out(d):
    lines, p = list(PEN_HEAD), 0
    s2 = lambda v: (v ^ 2) - 2
    sb = lambda v: v - 256 if v > 127 else v
    while p < len(d):
        b = d[p]
        if b == 0:
            lines.append('end')
            p += 1
        elif b == 1:
            lines.append('up')
            p += 1
        elif b == 2:
            lines.append('down')
            p += 1
        elif b == 3:
            lines.append('dot %d %d' % (sb(d[p + 1]), sb(d[p + 2])))
            p += 3
        elif b & 0xF0:
            lines.append('move %d %d %d' % (s2((b >> 4) & 3), s2(b >> 6), b & 15))
            p += 1
        else:
            raise ValueError('pen script byte $%02X at +%d' % (b, p))
    return ('\n'.join(lines) + '\n').encode()


def pen_in(raw):
    out = bytearray()
    for line in raw.decode().split('\n'):
        w = line.split()
        if not w or w[0].startswith('#'):
            continue
        k, v = w[0], [int(x) for x in w[1:]]
        if k in ('end', 'up', 'down'):
            out.append({'end': 0, 'up': 1, 'down': 2}[k])
        elif k == 'dot':
            out += bytes([3, v[0] & 255, v[1] & 255])
        elif k == 'move':
            out.append((v[1] & 3) << 6 | (v[0] & 3) << 4 | v[2])
        else:
            raise ValueError('pen script: %s' % line)
    return bytes(out)


PRINT_TEXTS = ['HudTexts', 'HudLastShot', 'GameOverTexts', 'FrameBanner', 'PlayerBannerTexts', 'FoulTexts',
               'ScoreBlank', 'HofTitle', 'PromptLeft', 'MenuTitle', 'KeysLine', 'VariationsTitle', 'PresentsTexts',
               'EditorTexts']
TEXT = {'text/%s.bin' % n: (print_out, print_in) for n in PRINT_TEXTS}
TEXT['text/SignatureScript.bin'] = (pen_out, pen_in)


# ---------------------------------------------------------------------------------------------------------------
# The OCP banner $BA86: run lengths <-> a PNG of 240-pixel rows
# ---------------------------------------------------------------------------------------------------------------
BANNER_WIDTH = 240


def banner_to_png(d):
    """One PNG line a data row (runs summing to 240 pixels: bit 7 ink, bits 0-6 half the length); palette 0 paper,
    1 ink. The PNG text chunk vp-rle holds the row width"""
    from PIL import Image, PngImagePlugin
    rows, row, tot = [], [], 0
    for b in d:
        if not b & 0x7F:
            raise ValueError('banner: a run of length 0')
        row.append(b)
        tot += 2 * (b & 0x7F)
        if tot == BANNER_WIDTH:
            rows.append(row)
            row, tot = [], 0
        elif tot > BANNER_WIDTH:
            raise ValueError('banner: a row of %d pixels' % tot)
    if row:
        raise ValueError('banner: the data ends inside a row')
    img = Image.new('P', (BANNER_WIDTH, len(rows)), 0)
    img.putpalette([0, 0, 0, 255, 0, 255] + [0] * 762)
    px = img.load()
    for y, r in enumerate(rows):
        x = 0
        for b in r:
            for _ in range(2 * (b & 0x7F)):
                px[x, y] = b >> 7
                x += 1
    info = PngImagePlugin.PngInfo()
    info.add_text('vp-rle', '%d' % BANNER_WIDTH)
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_banner(png):
    """Each line as its runs, one byte a run (the longest runs: the original's own encoding); runs are 2 pixels a
    unit, so a run of odd length is refused"""
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    out = bytearray()
    for y in range(img.size[1]):
        x = 0
        while x < img.size[0]:
            ink = 1 if px[x, y] == 1 else 0
            n = 0
            while x + n < img.size[0] and (1 if px[x + n, y] == 1 else 0) == ink:
                n += 1
            if n % 2 or n > 254:
                raise ValueError('banner: line %d, a run of %d pixels at x %d' % (y, n, x))
            out.append(ink << 7 | n // 2)
            x += n
    return bytes(out)


IMAGES = {'graphics/BannerData.bin': (banner_to_png, png_to_banner)}

# ---------------------------------------------------------------------------------------------------------------
# More CSV tables: game rules, positions, the key matrix, the letters' widths
# ---------------------------------------------------------------------------------------------------------------
def shots_out(d):
    return csv_out(['the shots of a frame, by the frame 1-9 (ShotsForFrame $9BE6 reads frame - 1; frame 10 on: 2, LD L,$02 at $9BED)'],
                   ['frame', 'shots'], [[k + 1, b] for k, b in enumerate(d)])


def column_in(raw, first=1):
    _h, rows = csv_in(raw)
    return bytes(num(v) for r in rows for v in r[first:])


def positions_out(d):
    names = ['cue'] + ['ball%d' % k for k in range(1, 7)]
    return csv_out(['the rack: the pixel position (x, y) of the ball centre, the cue ball then balls 1-6',
                    '(ResetBallPositions; the rack scripts of src/res/racks end on the same points)'],
                   ['ball', 'x', 'y'], [[names[k], d[2 * k], d[2 * k + 1]] for k in range(len(d) // 2)])


KEY_NAMES = {0x27: 'caps', 0x0D: 'enter', 0x20: 'space', 0x18: 'symbol'}
KEY_CODES = {v: k for k, v in KEY_NAMES.items()}
KEY_PORTS = ['$FEFE', '$FDFE', '$FBFE', '$F7FE', '$EFFE', '$DFFE', '$BFFE', '$7FFE']


def keys_out(d):
    rows = []
    for r in range(len(d) // 5):
        rows.append([KEY_PORTS[r]] + [KEY_NAMES.get(b, chr(b)) for b in d[5 * r:5 * r + 5]])
    return csv_out(['one half row of the keyboard a line, its port, then its five keys from the outer key in (bit 0',
                    'first); each cell the character KeyDown $822E looks up: a letter or digit, or caps ($27),',
                    'enter ($0D), space ($20), symbol ($18)'],
                   ['port', 'bit0', 'bit1', 'bit2', 'bit3', 'bit4'], rows)


def keys_in(raw):
    _h, rows = csv_in(raw)
    return bytes(KEY_CODES[v] if v in KEY_CODES else ord(v) for r in rows for v in r[1:])


def widths_out(d):
    half = len(d) // 2
    return csv_out(['the projected half-width of a turning letter at step k (4.5 degrees a step): w16 = FlipWidths16',
                    '(16 cos 4.5k), w24 = FlipWidths24 (24 cos 4.5k), read by FlipEdge $BC11; the file holds w16 for',
                    'every step, then w24'],
                   ['step', 'w16', 'w24'], [[k, d[k], d[half + k]] for k in range(half)])


def widths_in(raw):
    _h, rows = csv_in(raw)
    return bytes(num(r[1]) for r in rows) + bytes(num(r[2]) for r in rows)


TABLES.update({
    'tables/ShotsPerFrame.bin': (shots_out, column_in),
    'tables/StartPositions.bin': (positions_out, column_in),
    'tables/KeyTable.bin': (keys_out, keys_in),
    'tables/FlipWidths.bin': (widths_out, widths_in),
})

# ---------------------------------------------------------------------------------------------------------------
# More text: plain strings, the name-entry grid, the hall of fame's table
# ---------------------------------------------------------------------------------------------------------------
def quote(bs):
    t = ''
    for b in bs:
        if b in (0x22, 0x5C):
            t += '\\' + chr(b)
        elif 0x20 <= b < 0x7F:
            t += chr(b)
        else:
            t += '\\x%02x' % b
    return '"%s"' % t


def unquote(t):
    t = t.strip()
    if not (t.startswith('"') and t.endswith('"')):
        raise ValueError('not a quoted string: %s' % t)
    t, out, i = t[1:-1], bytearray(), 0
    while i < len(t):
        if t[i] == '\\':
            if t[i + 1] == 'x':
                out.append(int(t[i + 2:i + 4], 16))
                i += 4
                continue
            out.append(ord(t[i + 1]))
            i += 2
            continue
        out.append(ord(t[i]))
        i += 1
    return bytes(out)


def lines_in(raw):
    return [l for l in raw.decode('utf-8').split('\n') if l.strip() and not l.startswith('#')]


STRING_HEAD = ['# The characters as one quoted string: a-z the game font; \\xNN any other byte, \\" and \\\\ escaped.']


def string_out(d):
    return ('\n'.join(STRING_HEAD + [quote(d)]) + '\n').encode()


def string_in(raw):
    return b''.join(unquote(l) for l in lines_in(raw))


GRID_HEAD = ['# The name-entry grid of DrawCharacterGrid / PickCell, one row of 14 cells a line: each cell the character',
             '# the cell enters; \\x0c is "rub" and \\x0d "end" (two cells each, drawn by RubLines / EndLines).']


def grid_text_out(d):
    return ('\n'.join(GRID_HEAD + [quote(d[k:k + 14]) for k in range(0, len(d), 14)]) + '\n').encode()


HOF_SLOT = 71
HOF_HEAD = ['# The hall of fame as the game starts: one slot a line (slot 1 the centre pole, 2 the left, 3 the right):',
            '#   slot SCORE "NAME" pole X Y attr $AT flag X Y moves M',
            '# SCORE the score / 10 (shown x 10), NAME 7 characters (padded with spaces), pole the pole\'s pixel position,',
            '# attr the flag\'s attribute, flag its position (0 0: set by DrawFlag), moves bit 0 the flag moves. The 56-byte',
            '# name bitmap (+$0F, rendered by RenderName at the first draw) is zero in the image; a non-zero one follows',
            '# its slot as "bitmap HEX".']


def hof_out(d):
    lines = list(HOF_HEAD)
    for k in range(0, len(d), HOF_SLOT):
        s = d[k:k + HOF_SLOT]
        lines.append('slot %d %s pole %d %d attr $%02X flag %d %d moves %d' % (
            s[0] | s[1] << 8, quote(s[2:9]), s[11], s[12], s[13], s[9], s[10], s[14]))
        if any(s[15:]):
            lines.append('bitmap ' + s[15:].hex())
    return ('\n'.join(lines) + '\n').encode()


def hof_in(raw):
    out = bytearray()
    for line in lines_in(raw):
        if line.startswith('bitmap '):
            out[-56:] = bytes.fromhex(line.split()[1])
            continue
        head, rest = line.split('"', 1)
        name, tail = rest.rsplit('"', 1)
        score = num(head.split()[1])
        w, f = tail.split(), {}
        while w:
            n = 2 if w[0] in ('pole', 'flag') else 1
            f[w[0]] = [num(v) for v in w[1:1 + n]]
            w = w[1 + n:]
        out += bytes([score & 255, score >> 8]) + unquote('"%s"' % name) + bytes(
            f['flag'] + f['pole'] + f['attr'] + f['moves']) + bytes(56)
    return bytes(out)


TEXT.update({
    'text/VideoText.bin': (string_out, string_in),
    'text/CharacterGrid.bin': (grid_text_out, string_in),
    'text/HofTable.bin': (hof_out, hof_in),
})

# ---------------------------------------------------------------------------------------------------------------
# Record lists: spans (dx, dy, length) and the letters' edges (dx, dy, kind), each list ended by $FF
# ---------------------------------------------------------------------------------------------------------------
SPAN_HEAD = ['# A list of horizontal spans, one a line, from the origin the code gives:',
             '#   span DX DY LENGTH   LENGTH pixels from (x + DX, y + DY), DX and DY unsigned bytes ($00 DX DY LENGTH)',
             '#   end                 the end of the list ($FF)']
EDGE_HEAD = ['# The edges of the attract sequence\'s turning letters O, C, P, L (FlipLetter $BB74), one a line:',
             '#   letter NAME         the next list (the name for the reader; the label is the source\'s)',
             '#   edge DX DY KIND     DX 0 the left edge, 1 the right; DY the stripe line (0, 8, ... 40); KIND bit 1',
             '#                       the right edge, bit 2 the 24-pixel width table, bit 3 both tables',
             '#   end                 the end of the letter ($FF)']
RECORDS = {
    # name: (keyword, header, list names or None)
    'graphics/RubLines.bin': ('span', SPAN_HEAD + ['# The word "rub" of the name-entry grid, from (x $B7, y $90): XorLine for each.'], None),
    'graphics/EndLines.bin': ('span', SPAN_HEAD + ['# The word "end" of the name-entry grid, from (x $D7, y $90): XorLine for each.'], None),
    'graphics/PenNib.bin': ('span', SPAN_HEAD + ['# The pen\'s nib, from the pen point down-right (PenSpans $BE79).'], None),
    'graphics/PenCap.bin': ('span', SPAN_HEAD + ['# The pen\'s end cap (PenSpans $BE79, after the shaft).'], None),
    'graphics/FlipLetters.bin': ('edge', EDGE_HEAD, ['O', 'C', 'P', 'L']),
}


def records_out(name, d):
    word, head, names = RECORDS[name]
    lines, p, k = list(head), 0, 0
    while p < len(d):
        if names:
            lines.append('letter %s' % names[k])
        while d[p] != 0xFF:
            if p + 3 > len(d):
                raise ValueError('%s: a record runs past the entry' % name)
            lines.append('  %s %d %d %s' % (word, d[p], d[p + 1], ('$%02X' if word == 'edge' else '%d') % d[p + 2]))
            p += 3
        lines.append('end')
        p += 1
        k += 1
    return ('\n'.join(lines) + '\n').encode()


def records_in(name, raw):
    word = RECORDS[name][0]
    out = bytearray()
    for line in lines_in(raw):
        w = line.split()
        if w[0] == word:
            out += bytes(num(v) for v in w[1:4])
        elif w[0] == 'end':
            out.append(0xFF)
        elif w[0] != 'letter':
            raise ValueError('%s: %s' % (name, line))
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The rack-in scripts $A0C4-$A701: the set table, the six sets and their 36 scripts as one text file
# ---------------------------------------------------------------------------------------------------------------
RACKS_ORG = 0xA0C4  # RackSets: the file's bytes start here (the set and script pointers are absolute)
RACK_HEAD = [
    '# The rack-in scripts: how the six object balls roll into the rack before a frame of the game (RackBalls $9F6F, one',
    '# step a video frame of RackStep $A05E for each ball). One item a line, in the order of the bytes from org on:',
    '#   org $A0C4            the address of the first byte (RackSets), for the pointers',
    '#   sets S0 ... S5       RackSets: six words, the set of frames 1-2, 3-4, ... 11-12 (set ((frame - 1) / 2) mod 6)',
    '#   NAME: B1 ... B6      a set: six words, the scripts of balls 1-6',
    '#   NAME:                a script starts; its commands follow, one a line:',
    '#     wait N             3 N: wait N video frames',
    '#     place X Y          1 X Y: put the ball at pixel (X, Y)',
    '#     move N DX DY       2 N DX DY: move by (DX, DY) on each of the next N video frames (DX, DY signed)',
    '#     end                0: the ball is in place (the racking ends when all six are)',
    '# Every script ends with a place on its ball\'s rack position (StartPositions $9D5D, tables/StartPositions.csv).']


def racks_out(d):
    org = RACKS_ORG
    word = lambda a: d[a - org] | d[a - org + 1] << 8
    sets = [word(org + 2 * k) for k in range(6)]
    names = {}
    for k, s in enumerate(sets):
        names.setdefault(s, 'set%d' % k)
    scripts = {}
    for s in sets:
        for b in range(6):
            scripts.setdefault(word(s + 2 * b), '%s.ball%d' % (names[s], b + 1))
    sb = lambda v: '%+d' % (v - 256 if v > 127 else v)
    lines = RACK_HEAD + ['', 'org $%04X' % org, 'sets ' + ' '.join(names[s] for s in sets)]
    p = org + 12
    end = org + len(d)
    while p < end:
        if p in names:
            lines += ['', '%s: %s' % (names[p], ' '.join(scripts[word(p + 2 * b)] for b in range(6)))]
            p += 12
        elif p in scripts:
            lines += ['', '%s:' % scripts[p]]
            while True:
                c = d[p - org]
                if c == 0:
                    lines.append('  end')
                    p += 1
                    break
                if c == 1:
                    lines.append('  place %d %d' % (d[p - org + 1], d[p - org + 2]))
                    p += 3
                elif c == 2:
                    lines.append('  move %d %s %s' % (d[p - org + 1], sb(d[p - org + 2]), sb(d[p - org + 3])))
                    p += 4
                elif c == 3:
                    lines.append('  wait %d' % d[p - org + 1])
                    p += 2
                else:
                    raise ValueError('racks: command %d at $%04X' % (c, p))
        else:
            raise ValueError('racks: $%04X is neither a set nor a script' % p)
    if p != end:
        raise ValueError('racks: a script runs past the entry')
    return ('\n'.join(lines) + '\n').encode()


def racks_in(raw):
    items, org = [], None  # (label or None, kind, args)
    for line in lines_in(raw):
        w = line.split()
        if w[0] == 'org':
            org = num(w[1])
        elif w[0] == 'sets':
            items.append((None, 'words', w[1:]))
        elif w[0].endswith(':'):
            items.append((w[0][:-1], 'words' if len(w) > 1 else 'label', w[1:]))
        else:
            items.append((None, w[0], w[1:]))
    size = {'words': lambda a: 2 * len(a), 'label': lambda a: 0, 'end': lambda a: 1, 'place': lambda a: 3,
            'move': lambda a: 4, 'wait': lambda a: 2}
    labels, p = {}, org
    for label, kind, args in items:
        if label:
            labels[label] = p
        p += size[kind](args)
    out = bytearray()
    for _label, kind, args in items:
        if kind == 'words':
            for a in args:
                out += labels[a].to_bytes(2, 'little')
        elif kind == 'end':
            out.append(0)
        elif kind == 'place':
            out += bytes([1, num(args[0]), num(args[1])])
        elif kind == 'move':
            out += bytes([2, num(args[0]), int(args[1]) & 255, int(args[2]) & 255])
        elif kind == 'wait':
            out += bytes([3, num(args[0])])
    return bytes(out)


SCRIPTS = {'racks/RackScripts.bin': (racks_out, racks_in)}


def editable(name):
    if name in SHEETS:
        w, f, c = SHEETS[name][:3]
        rev = SHEETS[name][3] if len(SHEETS[name]) > 3 else 0
        return '.png', lambda n, d: sheet_to_png(d, w, f, c, rev), lambda n, d: png_to_sheet(d)
    if name in IMAGES:
        to_ed, from_ed = IMAGES[name]
        return '.png', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    if name in TABLES:
        to_ed, from_ed = TABLES[name]
        return '.csv', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    if name in TEXT:
        to_ed, from_ed = TEXT[name]
        return '.txt', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    if name in RECORDS:
        return '.txt', records_out, records_in
    if name in SCRIPTS:
        to_ed, from_ed = SCRIPTS[name]
        return '.txt', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    return None


def install(files):
    for name, data in files.items():
        fmt = editable(name)
        if fmt:
            suffix, to_ed, from_ed = fmt
            out = to_ed(name, data)
            if from_ed(name, out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            path = os.path.join(RES, os.path.splitext(name)[0] + suffix)
        else:
            path, out = os.path.join(RES, name), data
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(out)


def sources():
    """(src path, the .bin name it builds, its format or None) for every file of src/res"""
    for top, _dirs, files in os.walk(RES):
        for f in sorted(files):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            stem, ext = os.path.splitext(rel)
            name = stem + '.bin'
            fmt = editable(name) if ext != '.bin' else None
            if fmt and fmt[0] == ext:
                yield src, name, fmt
            else:
                yield src, rel, None


def build(out):
    for src, name, fmt in sources():
        data = open(src, 'rb').read()
        if fmt:
            data = fmt[2](name, data)
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(data)


def check(against=None):
    bad = count = 0
    for src, name, fmt in sources():
        if not fmt:
            continue
        count += 1
        ed = open(src, 'rb').read()
        data = fmt[2](name, ed)
        if fmt[2](name, fmt[1](name, data)) != data or fmt[1](name, data) != ed:
            print('res: %s does not round-trip' % src)
            bad += 1
        if against:
            ref = os.path.join(against, name)
            if os.path.exists(ref) and open(ref, 'rb').read() != data:
                print('res: %s differs from %s' % (src, ref))
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

#!/usr/bin/env python3
"""The resources of Rick Dangerous 2 in editable formats (src/res) and back to the bytes the sources INCBIN.

    python3 tools/res_formats.py build --out build/res [--levels build/lres]   # src/res -> bytes
    python3 tools/res_formats.py check [--against DIR]                        # every editable file round-trips

kit/mkgame.py --install calls install(files) with the bytes of each @res entry of the game and the small parts, and
install_level1 ... install_level5 for the level parts (src/levels/levelN.json "res_install"): their .ann
(src/levels/levels.ann) names every level's resources "level/NAME.bin"; level N's are kept in src/res/levels/levelN/
and built into LEVELS/levelN/res/level/ (tools/build.sh assembles level N with -I LEVELS/levelN).

A resource is a single file (one .bin, one editable file: SINGLES, matched by pattern) or a group (several .bin
files, one editable file: GROUPS). Every format is in this file; src/res/README.md lists the files.
"""
import argparse
import fnmatch
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# ---------------------------------------------------------------------------------------------------- pictures
# An indexed PNG keeps the Spectrum colour of every pixel: index = flash * 32 + ink * 16 + bright * 8 + colour, so
# the attribute comes back from the picture; a cell of one colour only (all ink or all paper) hides the other
# colour, which is kept in the PNG's text chunk "rd2" with the picture's layout.


def spectrum_rgb(colour, bright):
    v = 255 if bright else 205
    return [((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v]


PAL = []
for _flash in range(2):
    for _ink in range(2):
        for _bright in range(2):
            for _c in range(8):
                PAL += spectrum_rgb(_c, _bright)
FRAME = 64  # the grey between the cells of a sheet
PAL += [96, 96, 96]
MONO = [255, 255, 255, 0, 0, 0, 96, 96, 96, 0, 160, 0]  # 0 paper, 1 ink, 2 frame, 3 masked out (sprites)


def png_new(w, h, fill, pal):
    from PIL import Image
    img = Image.new('P', (w, h), fill)
    img.putpalette(pal + [0] * (768 - len(pal)))
    return img, img.load()


def png_bytes(img, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text('rd2', json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_open(raw):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    return img.load(), json.loads(img.text['rd2'])


def put_cell(px, x0, y0, rows, attr):
    """8 rows of a cell with its attribute; True when one colour is hidden"""
    used = set()
    for r, b in enumerate(rows):
        for bit in range(8):
            ink = (b >> (7 - bit)) & 1
            used.add(ink)
            colour = attr & 7 if ink else (attr >> 3) & 7
            px[x0 + bit, y0 + r] = (attr >> 7) * 32 + ink * 16 + ((attr >> 6) & 1) * 8 + colour
    return len(used) < 2


def get_cell(px, x0, y0, attr=None):
    rows, ink_c, paper_c, flash, bright = [], 0, 0, 0, 0
    for r in range(8):
        b = 0
        for bit in range(8):
            i = px[x0 + bit, y0 + r]
            b = b << 1 | (i >> 4) & 1
            flash, bright = i >> 5, (i >> 3) & 1
            if (i >> 4) & 1:
                ink_c = i & 7
            else:
                paper_c = i & 7
        rows.append(b)
    return rows, (flash << 7 | bright << 6 | paper_c << 3 | ink_c) if attr is None else attr


def screen_png(data):
    """a screen of 6912 bytes as a 256 x 192 picture"""
    if len(data) != 6912:
        raise ValueError('screen: %d bytes' % len(data))
    img, px = png_new(256, 192, FRAME, PAL)
    hidden = []
    for c in range(768):
        cy, cx = divmod(c, 32)
        rows = [data[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] for r in range(8)]
        if put_cell(px, cx * 8, cy * 8, rows, data[6144 + c]):
            hidden.append([c, data[6144 + c]])
    return png_bytes(img, {'screen': 1, 'hidden': hidden})


def png_screen(raw):
    px, meta = png_open(raw)
    hidden = dict(map(tuple, meta['hidden']))
    out = bytearray(6912)
    for c in range(768):
        cy, cx = divmod(c, 32)
        rows, a = get_cell(px, cx * 8, cy * 8, hidden.get(c))
        for r in range(8):
            out[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] = rows[r]
        out[6144 + c] = a
    return bytes(out)



# ---------------------------------------------------------------------------------------------------- texts
# A text block is strings ended by $FF. In the font a character's code is its glyph number + $34 (the glyphs: digits
# 0-9, three HUD icons, A-Z), so a digit d is the byte d + $34 ('4' is shown as 0) and a letter is ASCII; space is
# $20. The editable file has one string a line, the digits as shown; any other byte (the ending texts' x and y bytes
# before each line, the icons) is written {XX}. After the last $FF the file ends with no newline (an empty last string
# is an empty file end: the block's own end mark).
DIGITS = {0x34 + d: str(d) for d in range(10)}


def text_utf8(data):
    out = []
    for b in data:
        if b == 0xFF:
            out.append('\n')
        elif b in DIGITS:
            out.append(DIGITS[b])
        elif b == 0x20 or 0x41 <= b <= 0x5A:
            out.append(chr(b))
        else:
            out.append('{%02X}' % b)
    return ''.join(out).encode('utf-8')


def utf8_text(raw):
    s, out, i = raw.decode('utf-8'), bytearray(), 0
    while i < len(s):
        c = s[i]
        if c == '{':
            out.append(int(s[i + 1:i + 3], 16))
            i += 4
            continue
        if c == '\n':
            out.append(0xFF)
        elif c.isdigit():
            out.append(0x34 + int(c))
        elif c == ' ' or 'A' <= c <= 'Z':
            out.append(ord(c))
        else:
            raise ValueError('text: character %r has no glyph' % c)
        i += 1
    return bytes(out)


# ---------------------------------------------------------------------------------------------------- glyphs
GLYPH_ROW = 10  # glyphs a row in the sheet


def glyphs_png(data):
    """8 x 8 one-colour glyphs, 8 bytes each, in a sheet of GLYPH_ROW a row with a 1-pixel frame"""
    n = len(data) // 8
    if n * 8 != len(data):
        raise ValueError('glyphs: %d bytes' % len(data))
    rows = (n + GLYPH_ROW - 1) // GLYPH_ROW
    img, px = png_new(GLYPH_ROW * 9 + 1, rows * 9 + 1, 2, MONO)
    for g in range(n):
        x0, y0 = 1 + (g % GLYPH_ROW) * 9, 1 + (g // GLYPH_ROW) * 9
        for r in range(8):
            for bit in range(8):
                px[x0 + bit, y0 + r] = (data[g * 8 + r] >> (7 - bit)) & 1
    return png_bytes(img, {'glyphs': n})


def png_glyphs(raw):
    px, meta = png_open(raw)
    out = bytearray()
    for g in range(meta['glyphs']):
        x0, y0 = 1 + (g % GLYPH_ROW) * 9, 1 + (g // GLYPH_ROW) * 9
        for r in range(8):
            out.append(sum((px[x0 + bit, y0 + r] & 1) << (7 - bit) for bit in range(8)))
    return bytes(out)


# ---------------------------------------------------------------------------------------------------- tables
def csv_lines(raw):
    return [l for l in raw.decode('utf-8').splitlines() if l and not l.startswith('#')]


def level_starts_csv(data):
    """LevelStarts: 6 bytes a level: section, view row, x, y (a word, little-endian), the mirror byte"""
    out = ['# level,section,view_row,x,y,mirror']
    for i in range(0, len(data), 6):
        r = data[i:i + 6]
        out.append('%d,%d,%d,%d,%d,%d' % (i // 6 + 1, r[0], r[1], r[2], r[3] | r[4] << 8, r[5]))
    return ('\n'.join(out) + '\n').encode()


def csv_level_starts(raw):
    out = bytearray()
    for l in csv_lines(raw):
        _lev, s, row, x, y, m = map(int, l.split(','))
        out += bytes([s, row, x, y & 255, y >> 8, m])
    return bytes(out)


def section_counts_csv(data):
    return ('# level,sections\n' + ''.join('%d,%d\n' % (i + 1, b) for i, b in enumerate(data))).encode()


def csv_section_counts(raw):
    return bytes(int(l.split(',')[1]) for l in csv_lines(raw))


def byte_lists_txt(data):
    """sequences ended by $FF, one a line, decimal bytes (the $FF written as the line end)"""
    parts = bytes(data).split(b'\xff')
    lines = [' '.join(str(b) for b in p) for p in parts[:-1]]
    tail = parts[-1]
    return ('# one sequence a line, decimal bytes; each line ends with the $FF end mark\n' + ''.join(l + '\n' for l in lines)
            + ('tail ' + ' '.join(str(b) for b in tail) + '\n' if tail else '')).encode()


def txt_byte_lists(raw):
    out = bytearray()
    for l in csv_lines(raw):
        if l.startswith('tail '):
            out += bytes(int(x) for x in l[5:].split())
        else:
            out += bytes(int(x) for x in l.split()) + b'\xff'
    return bytes(out)


SPRITES_BASE, SPRITE_SIZE = 0xC26D, 128


def sprite_words_csv(data):
    """a table of sprite addresses (words): each written as its sprite number in the level's Sprites ($C26D)"""
    out = ['# frame,sprite (the word = Sprites + 128 x sprite)']
    for i in range(0, len(data), 2):
        w = data[i] | data[i + 1] << 8
        n, rest = divmod(w - SPRITES_BASE, SPRITE_SIZE)
        if rest:
            raise ValueError('sprite word $%04X' % w)
        out.append('%d,%d' % (i // 2, n))
    return ('\n'.join(out) + '\n').encode()


def csv_sprite_words(raw):
    out = bytearray()
    for l in csv_lines(raw):
        w = SPRITES_BASE + SPRITE_SIZE * int(l.split(',')[1])
        out += bytes([w & 255, w >> 8])
    return bytes(out)


POINTS = ['50', '100', '500', '5000', '10000', '100000']


def points_csv(files):
    out = ['# name,digits (six digit bytes, 0-9 each, most significant first: the score adder adds them digit by digit)']
    for p in POINTS:
        out.append('points-%s,%s' % (p, ''.join(str(b) for b in files['tables/points-%s.bin' % p])))
    return ('\n'.join(out) + '\n').encode()


def csv_points(raw):
    out = {}
    for l in csv_lines(raw):
        name, digits = l.split(',')
        out['tables/%s.bin' % name] = bytes(int(c) for c in digits)
    return out



# ---------------------------------------------------------------------------------------------------- music (RAM 1)
# The tunes as text: a list of tokens a line, a line per $FF-ended list. [NAME] marks where a pointer of the table
# points (a pattern Pnn, a tune's channel order list TnnA/B/C); {XX} is a byte written as it is (a marker in the
# middle of an event, a command no tune uses). Formats: src/music/music.ann and src/res/tunes/README.md.
NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note_name(midi):
    return '%s%d' % (NOTE_NAMES[midi % 12], midi // 12 - 1)


def name_note(t):
    m = re.match(r'^([A-G]#?)(-?\d+)$', t)
    return NOTE_NAMES.index(m.group(1)) + 12 * (int(m.group(2)) + 1)


def sgn(b):
    return b - 256 if b > 127 else b


def tokens_text(data, markers, event):
    """data split into lines at $FF; markers {offset: [names]}; event(data, i) -> (length, text) or None"""
    lines, cur, i = [], [], 0
    while i < len(data):
        for m in markers.get(i, []):
            cur.append('[%s]' % m)
        if data[i] == 0xFF:
            lines.append(' '.join(cur))
            cur, i = [], i + 1
            continue
        ev = event(data, i)
        if ev and i + ev[0] <= len(data) and not any(i < k < i + ev[0] for k in markers):
            cur.append(ev[1])
            i += ev[0]
        else:
            cur.append('{%02X}' % data[i])
            i += 1
    for m in markers.get(len(data), []):
        cur.append('[%s]' % m)
    if cur:
        lines.append('tail ' + ' '.join(cur))
    return lines


def text_tokens(lines, token):
    """the bytes and the marker offsets back: token(t) -> bytes"""
    out, marks = bytearray(), {}
    for l in lines:
        tail = l.startswith('tail ')
        for t in (l[5:] if tail else l).split():
            if t.startswith('['):
                marks.setdefault(t[1:-1], len(out))
            elif t.startswith('{'):
                out.append(int(t[1:3], 16))
            else:
                out += token(t)
        if not tail:
            out.append(0xFF)
    return bytes(out), marks


def pattern_event(d, i):
    b = d[i]
    if b < 0x7E:
        return 2, '%s:%d' % (note_name(b + 34), d[i + 1]) if i + 1 < len(d) else None
    if b == 0x7E:
        return (4, 'per%d:%d' % (d[i + 1] | d[i + 2] << 8, d[i + 3])) if i + 3 < len(d) else None
    if b == 0x7F:
        return (2, 'r:%d' % d[i + 1]) if i + 1 < len(d) else None
    if b <= 0x87:
        return 1, 'i%d' % (b & 7)
    if 0x90 <= b <= 0x9F:
        return 1, 'o%d' % (b & 15)
    return None


def pattern_token(t):
    if t.startswith('per'):
        per, d = map(int, t[3:].split(':'))
        return bytes([0x7E, per & 255, per >> 8, d])
    if t.startswith('r:'):
        return bytes([0x7F, int(t[2:])])
    if re.match(r'^i\d$', t):
        return bytes([0x80 + int(t[1:])])
    if re.match(r'^o\d+$', t):
        return bytes([0x90 + int(t[1:])])
    n, d = t.split(':')
    return bytes([name_note(n) - 34, int(d)])


PATTERNS, ORDERS = 0xC000, 0xC302


def patterns_txt(files):
    data, lo, hi = files['tunes/patterns.bin'], files['tunes/pattern-low.bin'], files['tunes/pattern-high.bin']
    marks = {}
    for n, (a, b) in enumerate(zip(lo, hi)):
        marks.setdefault((a | b << 8) - PATTERNS, []).append('P%02d' % n)
    if any(not 0 <= k <= len(data) for k in marks):
        raise ValueError('a pattern outside the patterns')
    head = ['# The 54 patterns of the tunes (RAM 1 $C000, 704 bytes) and their address table (PatternAddrLow /',
            '# PatternAddrHigh). A line per pattern stream ($FF ends it); [Pnn] marks where pattern nn starts (several may',
            '# share bytes). NOTE:frames a note (C4 = MIDI 60; the byte is MIDI - 34, the period index byte + transpose + 12),',
            '# r:frames a rest, perP:frames a note by tone period, iK instrument K, oK ornament K, {XX} a byte as it is.',
            '# patterns %d' % len(lo)]
    return ('\n'.join(head + tokens_text(data, marks, pattern_event)) + '\n').encode()


def txt_patterns(raw):
    text = raw.decode('utf-8').splitlines()
    count = int([l for l in text if l.startswith('# patterns ')][0].split()[2])
    data, marks = text_tokens([l for l in text if not l.startswith('#')], pattern_token)
    addr = [PATTERNS + marks['P%02d' % n] for n in range(count)]
    return {'tunes/patterns.bin': data, 'tunes/pattern-low.bin': bytes(a & 255 for a in addr),
            'tunes/pattern-high.bin': bytes(a >> 8 for a in addr)}


def order_event(d, i):
    b = d[i]
    if b < 0x80:
        return 1, 'P%02d' % b
    if 0x80 <= b <= 0x9F:
        return 1, 'x%d' % (b & 0x1F)
    if b == 0xFE and i + 1 < len(d):
        return 2, 't%+d' % sgn(d[i + 1])
    return None


def order_token(t):
    if t.startswith('P'):
        return bytes([int(t[1:])])
    if t.startswith('x'):
        return bytes([0x80 + int(t[1:])])
    return bytes([0xFE, int(t[1:]) & 255])


def tunes_txt(files):
    table, data = files['tunes/tune-table.bin'], files['tunes/order-lists.bin']
    marks = {}
    for k in range(0, len(table), 2):
        marks.setdefault((table[k] | table[k + 1] << 8) - ORDERS, []).append('T%02d%s' % (k // 6, 'ABC'[k // 2 % 3]))
    if any(not 0 <= k <= len(data) for k in marks):
        raise ValueError('an order list outside the lists')
    head = ['# The 11 tunes (RAM 1: TuneTable $C2C0, the order lists from $C302): a line per order list ($FF ends it);',
            '# [TnnA] marks where tune nn\'s channel A list starts (B, C the other AY channels; several may share one).',
            '# Pnn plays pattern nn (tunes/patterns.txt), xN the next pattern N times (0 = 256), t+N transposes the',
            '# patterns after it by N semitones, {XX} a byte as it is.', '# tunes %d' % (len(table) // 6)]
    return ('\n'.join(head + tokens_text(data, marks, order_event)) + '\n').encode()


def txt_tunes(raw):
    text = raw.decode('utf-8').splitlines()
    count = int([l for l in text if l.startswith('# tunes ')][0].split()[2])
    data, marks = text_tokens([l for l in text if not l.startswith('#')], order_token)
    table = bytearray()
    for n in range(count):
        for ch in 'ABC':
            a = ORDERS + marks['T%02d%s' % (n, ch)]
            table += bytes([a & 255, a >> 8])
    return {'tunes/tune-table.bin': bytes(table), 'tunes/order-lists.bin': data}


INSTR = ['attack', 'decay', 'sustain', 'release', 'peak', 'sweep_delay', 'sweep_frames', 'sweep_step', 'flags']
SIGNED = {'decay', 'release'}


def records_csv(data, size, effects):
    cols = INSTR + (['period', 'sustain_frames'] if effects else [])
    out = ['# %s,%s (src/res/tunes/README.md)' % ('effect' if effects else 'instrument', ','.join(cols))]
    for n in range(len(data) // size):
        r = data[n * size:(n + 1) * size]
        v = [r[0], sgn(r[1]), r[2], sgn(r[3]), r[4], r[5], r[6], sgn(r[8]) * 256 + r[7], r[9]]
        if effects:
            v += [r[10] | r[11] << 8, r[12]]
        out.append(','.join(str(x) for x in [n] + v))
    return ('\n'.join(out) + '\n').encode()


def csv_records(raw, effects):
    out = bytearray()
    for l in csv_lines(raw):
        v = list(map(int, l.split(',')))[1:]
        out += bytes([v[0], v[1] & 255, v[2], v[3] & 255, v[4], v[5], v[6], v[7] & 255, (v[7] >> 8) & 255, v[8]])
        if effects:
            out += bytes([v[9] & 255, v[9] >> 8, v[10]])
    return bytes(out)


def ornaments_csv(data):
    out = ['# ornament,loop,base_frames,steps,then 7 steps semitones:frames (header bit 7 loop, bits 3-5 the base',
           '# step\'s frames, bits 0-2 the steps used; a step byte: semitones x 8 + frames). Ornament 0 is none.']
    for n in range(len(data) // 8):
        r = data[n * 8:n * 8 + 8]
        out.append(','.join([str(n + 1), str(r[0] >> 7), str((r[0] >> 3) & 7), str(r[0] & 7)] +
                            ['%d:%d' % (b >> 3, b & 7) for b in r[1:]]))
    return ('\n'.join(out) + '\n').encode()


def csv_ornaments(raw):
    out = bytearray()
    for l in csv_lines(raw):
        f = l.split(',')
        out.append(int(f[1]) << 7 | int(f[2]) << 3 | int(f[3]))
        for st in f[4:]:
            a, b = map(int, st.split(':'))
            out.append(a << 3 | b)
    return bytes(out)


def periods_csv(data):
    out = ['# index,period,note (the AY tone period of each semitone; index 0 = A#0 = MIDI 22, at the 128K AY clock',
           '# 1.7734 MHz; entries 20 and 24 are about half a semitone off in the original)']
    for i in range(len(data) // 2):
        out.append('%d,%d,%s' % (i, data[2 * i] | data[2 * i + 1] << 8, note_name(22 + i)))
    return ('\n'.join(out) + '\n').encode()


def csv_periods(raw):
    out = bytearray()
    for l in csv_lines(raw):
        v = int(l.split(',')[1])
        out += bytes([v & 255, v >> 8])
    return bytes(out)



# ---------------------------------------------------------------------------------------------------- level graphics
# Sprites: 128 bytes each: +0 a line offset, +1 the rows drawn, then 21 rows of 6 bytes, data 2, data 1, data 0,
# mask 0, mask 2, mask 1 (column 0 the left one; the composer `$7329` ANDs the mask, ORs the data). The sheet shows
# each sprite 24 x 21 in a grey frame, SPRITE_ROW a row: index 0 paper (mask 0, data 0), 1 ink, 3 green = the screen
# shows through (mask 1, data 0), 4 red = ink over a transparent pixel (mask 1, data 1). The two header bytes of every
# sprite are in the PNG text chunk "rd2".
SPRITE_ROW = 8
SPRITE_PAL = MONO + [255, 0, 0]
SPRITE_ORDER = [(2, 3), (1, 5), (0, 4)]  # (data byte, mask byte) of columns 0, 1, 2 in a row's 6 bytes


def sprites_png(data):
    n = len(data) // 128
    if n * 128 != len(data):
        raise ValueError('sprites: %d bytes' % len(data))
    rows = (n + SPRITE_ROW - 1) // SPRITE_ROW
    img, px = png_new(SPRITE_ROW * 25 + 1, rows * 22 + 1, 2, SPRITE_PAL)
    heads = []
    for k in range(n):
        s = data[k * 128:(k + 1) * 128]
        heads.append([s[0], s[1]])
        x0, y0 = 1 + (k % SPRITE_ROW) * 25, 1 + (k // SPRITE_ROW) * 22
        for r in range(21):
            row = s[2 + 6 * r:8 + 6 * r]
            for col, (di, mi) in enumerate(SPRITE_ORDER):
                for bit in range(8):
                    dbit, mbit = (row[di] >> (7 - bit)) & 1, (row[mi] >> (7 - bit)) & 1
                    px[x0 + col * 8 + bit, y0 + r] = [[0, 1], [3, 4]][mbit][dbit]
    return png_bytes(img, {'sprites': n, 'heads': heads})


def png_sprites(raw):
    px, meta = png_open(raw)
    out = bytearray()
    for k in range(meta['sprites']):
        x0, y0 = 1 + (k % SPRITE_ROW) * 25, 1 + (k // SPRITE_ROW) * 22
        out += bytes(meta['heads'][k])
        for r in range(21):
            row = [0] * 6
            for col, (di, mi) in enumerate(SPRITE_ORDER):
                for bit in range(8):
                    v = px[x0 + col * 8 + bit, y0 + r]
                    row[di] |= (1 if v in (1, 4) else 0) << (7 - bit)
                    row[mi] |= (1 if v in (3, 4) else 0) << (7 - bit)
            out += bytes(row)
    return bytes(out)


CELL_ROW = 16


def cells_png(files):
    """the level's 256 cells (CellGraphics, 8 bytes each, and CellAttrs) in a sheet of 16 x 16, a grey frame"""
    g, a = files['level/cell-graphics.bin'], files['level/cell-attrs.bin']
    img, px = png_new(CELL_ROW * 9 + 1, (256 // CELL_ROW) * 9 + 1, FRAME, PAL)
    hidden = []
    for c in range(256):
        if put_cell(px, 1 + (c % CELL_ROW) * 9, 1 + (c // CELL_ROW) * 9, g[c * 8:c * 8 + 8], a[c]):
            hidden.append([c, a[c]])
    return png_bytes(img, {'cells': 256, 'hidden': hidden})


def png_cells(raw):
    px, meta = png_open(raw)
    hidden = dict(map(tuple, meta['hidden']))
    g, a = bytearray(), bytearray()
    for c in range(meta['cells']):
        rows, at = get_cell(px, 1 + (c % CELL_ROW) * 9, 1 + (c // CELL_ROW) * 9, hidden.get(c))
        g += bytes(rows)
        a.append(at)
    return {'level/cell-graphics.bin': bytes(g), 'level/cell-attrs.bin': bytes(a)}


CELL_BITS = ['special', 'solid', 'floor', 'ladder', 'ladder_top', 'deadly', 'bit6', 'front']


def cell_flags_csv(data):
    out = ['# cell,' + ','.join(CELL_BITS) + ' (CellFlags: bit 0 the level\'s special surface, 1 solid, 2 a floor jumped through from',
           '# below, 3 a ladder, 4 a ladder top, 5 deadly, 6 unused here, 7 drawn in front of the sprites)']
    for c, b in enumerate(data):
        out.append(','.join([str(c)] + [str((b >> k) & 1) for k in range(8)]))
    return ('\n'.join(out) + '\n').encode()


def csv_cell_flags(raw):
    return bytes(sum(int(v) << k for k, v in enumerate(l.split(',')[1:])) for l in csv_lines(raw))


def blocks_txt(data):
    """Blocks: 256 blocks of 4 x 4 cell numbers, a block a line: four rows of four cells, rows split by /"""
    out = ['# block: four rows of four cell numbers (decimal; level/cells.png numbers the cells 16 a row)']
    for b in range(len(data) // 16):
        q = data[b * 16:b * 16 + 16]
        out.append('%d: %s' % (b, ' / '.join(' '.join(str(x) for x in q[r * 4:r * 4 + 4]) for r in range(4))))
    return ('\n'.join(out) + '\n').encode()


def txt_blocks(raw):
    out = bytearray()
    for l in csv_lines(raw):
        out += bytes(int(x) for x in l.split(':', 1)[1].replace('/', ' ').split())
    return bytes(out)


# ---------------------------------------------------------------------------------------------------- level data
# The level texts share one way back to bytes (text_fields): '#' starts a comment line, ';' a comment to the line's
# end; a token ending in ':' is a label (ignored); a word of letters is a keyword (ignored); NAME=VALUE is VALUE.
# VALUE: $hhhh a little-endian word, >$hhhh a big-endian word, $hh or a decimal 0-255 a byte. Scripts (anims, paths)
# have their own tokens (anim_token, path_token). A group's text holds each .bin after a "[name]" line.
def hexw(v):
    return '$%04X' % v


def field_bytes(t):
    if '=' in t:
        t = t.split('=', 1)[1]
    if re.fullmatch(r'>\$[0-9A-Fa-f]{4}', t):
        v = int(t[2:], 16)
        return bytes([v >> 8, v & 255])
    if re.fullmatch(r'\$[0-9A-Fa-f]{4}', t):
        v = int(t[1:], 16)
        return bytes([v & 255, v >> 8])
    if re.fullmatch(r'\$[0-9A-Fa-f]{2}', t):
        return bytes([int(t[1:], 16)])
    if re.fullmatch(r'[0-9]+', t):
        return bytes([int(t)])
    if re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*', t):
        return b''
    raise ValueError('level text: bad token %r' % t)


def text_lines(raw):
    for l in raw.decode('utf-8').splitlines():
        if l.startswith('#'):
            continue
        l = l.split(';', 1)[0]
        yield [t for t in l.split() if not t.endswith(':')]


def text_fields(raw, token=field_bytes):
    return b''.join(token(t) for toks in text_lines(raw) for t in toks)


def split_groups(raw):
    """{name: raw text} of a group text: each part after its "[name]" line"""
    out, cur = {}, None
    for l in raw.decode('utf-8').splitlines(keepends=True):
        m = re.fullmatch(r'\[(.+)\]\s*', l)
        if m:
            cur = m.group(1)
            out[cur] = ''
        elif cur is not None:
            out[cur] += l
    return {k: v.encode() for k, v in out.items()}


def raw_line(d, p, q, n=8):
    out = []
    while p < q:
        out.append('bytes ' + ' '.join('$%02X' % b for b in d[p:min(q, p + n)]))
        p += n
    return out


# Maps: one byte a block, 8 blocks a row (one screen wide); a section's map starts at the row its "map" offset
# names (sections.txt) and is shown from its row 2 down to row limit / 4 + 7. Rows of neighbouring sections overlap.
def maps_txt(data):
    out = ['# Maps: rows of 8 block numbers (decimal, level/blocks.txt), top row first. Section n\'s map starts at row',
           '# map / 8 of its line in sections.txt; the screen shows its rows 2 to limit / 4 + 7. The maps overlap: the',
           '# next section\'s hidden rows 0-1 are usually the last two shown rows of the one before.']
    for r in range(0, len(data), 8):
        out.append('row %d: %s' % (r // 8, ' '.join(str(b) for b in data[r:r + 8])))
    return ('\n'.join(out) + '\n').encode()


def txt_maps(raw):
    return text_fields(raw)


SIDES = {0: 'none', 1: 'left', 2: 'right', 3: 'both'}


def exit_note(e):
    f = e[0]
    s = [SIDES[f & 3]]
    if f & 0x80:
        s.append('level end' + (' (a passage with CheatExits)' if not f & 0x10 else ''))
    if f & 0x40:
        s.append('LevelHookOn (the Fat Guy)')
    if f & 0x20:
        s.append('arrives riding')
    if not f & 0x80:
        s.append('to section %d' % e[2])
    return ', '.join(s)


def object_note(o):
    k, row, col, par = o
    x = (col & 31) * 8 + (4 if col & 0x20 else 0)
    when = 'on view' if col & 0x80 else 'on a trigger'
    if k == 0x78:
        what = 'bonus countdown start'
    elif k == 0x7C:
        what = 'bonus countdown stop'
    elif k >= 0x74:
        what = 'enemy, behaviour %d, patrol %d px' % (k & 3, ((par >> 2 & 15) + 1) * 8)
    else:
        what = {0x20: 'treasure', 0x28: 'ammunition', 0x2C: 'detonators'}.get(par & 0x3C, 'trap behaviour $%02X' % (par & 0x3C))
        what = 'kind %d, %s' % (k, what)
    return '%s; x %d%s; %s%s' % (what, x, ', y + 3' if col & 0x40 else '', when, ', one-shot' if par & 0x40 else '')


def sections_txt(data):
    """the section table (8 bytes a section) and the exit and map entry lists it points to, in their byte order"""
    ents = []
    while True:
        e = data[8 * len(ents):8 * len(ents) + 8]
        ents.append(e)
        if 8 * len(ents) >= min(min(x[4] << 8 | x[5], x[6] << 8 | x[7]) for x in ents):
            break
    out = ['# Sections: 8 bytes a section (offsets big-endian): map = offset from the maps\' base (maps.txt row map / 8),',
           '# pad (read by no code), limit = the last view top row the scroll reaches (cells), exits and objects =',
           '# offsets from this table to the section\'s exit list and map entry list. SectionCounts $8374 says how many',
           '# sections the game uses; the entries after them are fillers. Then the lists in their byte order:',
           '#   exit flags row to arrive (4 bytes; flags bits 0-1 side 1 left 2 right, 4 keep a level end under CheatExits,',
           '#     5 arrive riding, 6 LevelHookOn, 7 level end; row = Rick\'s feet row; to = section; arrive = feet row there),',
           '#     a byte with (b AND $0B) = 0 ends the list;',
           '#   object kind row col param (4 bytes; col bits 0-4 column, 5 x + 4, 6 y + 3, 7 spawn on view; param bits 0-1',
           '#     boxes, 2-5 behaviour or patrol, 6 one-shot), then its boxes: box x row size who (size: rows - 1 high',
           '#     nibble, columns - 1 low; who: bit 0 Rick, 1 bullet, 2 blast, 3 punch, 4 enemy, 5 trap, 6 every pass);',
           '#     kind 0 ends the list.']
    starts = {}
    for s, e in enumerate(ents):
        lim = e[3]
        note = 'filler' if (e[0] << 8 | e[1]) == 0 and lim == 0 and s else 'map rows %d-%d shown' % (
            (e[0] << 8 | e[1]) // 8 + 2, (e[0] << 8 | e[1]) // 8 + lim // 4 + 7)
        out.append('section %d: map=>%s pad=%d limit=%d exits=>%s objects=>%s ; %s' % (
            s, hexw(e[0] << 8 | e[1]), e[2], lim, hexw(e[4] << 8 | e[5]), hexw(e[6] << 8 | e[7]), note))
        starts.setdefault(e[4] << 8 | e[5], []).append(('exits', s))
        starts.setdefault(e[6] << 8 | e[7], []).append(('objects', s))
    p, n = 8 * len(ents), len(data)
    while p < n:
        here = starts.get(p)
        if here:
            out.append('# +%s: %s' % (hexw(p), ', '.join('%s of section %d' % h for h in here)))
            kind, p0 = here[0][0], p
            if kind == 'exits':
                while p + 4 <= n and data[p] & 0x0B:
                    e = data[p:p + 4]
                    out.append('exit flags=$%02X row=%d to=%d arrive=%d ; %s' % (e[0], e[1], e[2], e[3], exit_note(e)))
                    p += 4
                if p < n and not data[p] & 0x0B:
                    out.append('end $%02X' % data[p])
                    p += 1
            else:
                while p + 4 <= n and data[p] and p + 4 + 4 * (data[p + 3] & 3) <= n:
                    o = data[p:p + 4]
                    out.append('object kind=$%02X row=%d col=$%02X param=$%02X ; %s' % (o[0], o[1], o[2], o[3], object_note(o)))
                    p += 4
                    for _ in range(o[3] & 3):
                        b = data[p:p + 4]
                        out.append('  box x=%d row=%d size=$%02X who=$%02X ; %d x %d cells' % (
                            b[0], b[1], b[2], b[3], (b[2] & 15) + 1, (b[2] >> 4) + 1))
                        p += 4
                if p < n and not data[p]:
                    out.append('end 0')
                    p += 1
            if p > p0:
                continue
            q = min([s for s in starts if s > p] + [n])
            out += raw_line(data, p, q)
            p = q
            continue
        q = min([s for s in starts if s > p] + [n])
        out.append('# +%s: bytes no section points to' % hexw(p))
        out += raw_line(data, p, q)
        p = q
    return ('\n'.join(out) + '\n').encode()


def txt_sections(raw):
    return text_fields(raw)


# Scripts. Animation (AnimateTrap $A608): N a frame for one pass, N+K frame N for K more passes ($80 + K, N), fx=N
# an effect ($FD N), jump=$hhhh ($FF and the address). Path (UpdateTrap $A2F7): C*(dx,dy) C passes of the step (dx
# the high nibble, dy the low, signed, 7 = 8 pixels), fx=N an effect ($FF N), jump=$hhhh (0 and the address).
def nib(v):
    return v - 16 if v & 8 else v


def anim_items(d, p):
    b = d[p]
    if b < 0x80:
        return str(b), 1, False
    if b == 0xFD and p + 1 < len(d):
        return 'fx=%d' % d[p + 1], 2, False
    if b == 0xFF and p + 2 < len(d):
        return 'jump=%s' % hexw(d[p + 1] | d[p + 2] << 8), 3, True
    if b not in (0xFD, 0xFF) and p + 1 < len(d):
        return '%d+%d' % (d[p + 1], b - 0x80), 2, False
    return '$%02X' % b, 1, False


def path_items(d, p):
    b = d[p]
    if b == 0 and p + 2 < len(d):
        return 'jump=%s' % hexw(d[p + 1] | d[p + 2] << 8), 3, True
    if b == 0xFF and p + 1 < len(d):
        return 'fx=%d' % d[p + 1], 2, False
    if b not in (0, 0xFF) and p + 1 < len(d):
        s = d[p + 1]
        return '%d*(%d,%d)' % (b, nib(s >> 4), nib(s & 15)), 2, False
    return '$%02X' % b, 1, False


def anim_token(t):
    if '+' in t and re.fullmatch(r'[0-9]+\+[0-9]+', t):
        f, k = t.split('+')
        return bytes([0x80 + int(k), int(f)])
    if t.startswith('fx='):
        return bytes([0xFD, int(t[3:])])
    if t.startswith('jump='):
        return b'\xFF' + field_bytes(t[5:])
    return field_bytes(t)


def path_token(t):
    m = re.fullmatch(r'([0-9]+)\*\((-?[0-9]+),(-?[0-9]+)\)', t)
    if m:
        return bytes([int(m.group(1)), (int(m.group(2)) & 15) << 4 | (int(m.group(3)) & 15)])
    if t.startswith('fx='):
        return bytes([0xFF, int(t[3:])])
    if t.startswith('jump='):
        return b'\x00' + field_bytes(t[5:])
    return field_bytes(t)


def script_txt(d, base, starts, items, names):
    """script lines: a new line at every start address (labelled with its name) and after every jump"""
    out, line, p = [], [], 0
    while p < len(d):
        a = base + p
        if a in starts and line:
            out.append(' '.join(line))
            line = []
        if not line:
            line = ['%s:' % hexw(a)]
            if a in starts:
                out.append('# %s' % ', '.join(sorted(starts[a])))
        tok, size, end = items(d, p)
        line.append(tok)
        p += size
        if end:
            out.append(' '.join(line))
            line = []
    if line:
        out.append(' '.join(line))
    return out


def kinds_txt(files):
    """the kind table, the trap animations, the trap paths and the kind records (one group: the records' pointers
    and the scripts' jumps are absolute, the four blocks follow each other in that order)"""
    kt, an, pa, kr = (files['level/%s.bin' % n] for n in ('kinds', 'anims', 'paths', 'kinds-2'))
    ptr = [kt[i] | kt[i + 1] << 8 for i in range(0, len(kt), 2)]
    rbase = min(p for p in ptr if p >= 0xA800)
    pbase = rbase - len(pa)
    abase = pbase - len(an)
    cuts = sorted({p - rbase for p in ptr if rbase <= p < rbase + len(kr)} | {0})
    by = {}
    for k, p in enumerate(ptr):
        by.setdefault(p, []).append(k)
    out = ['# Kinds: a trap or pickup kind (a map entry\'s kind below $74) points to an 11-byte record: width, height,',
           '# flags (bit 6 deadly, 7 the detonator test; bits 0-5 the behaviour after the switch), path, anim, path2,',
           '# anim2 (absolute words). A record whose kind never switches has 7 bytes (the next record follows). The',
           '# animation and path tokens: anim N (a frame), N+K (frame N for K more passes), fx=N, jump=$hhhh; path',
           '# C*(dx,dy) (C passes of the step, dx and dy signed nibbles), fx=N, jump=$hhhh.',
           '[kinds.bin]']
    for k, p in enumerate(ptr):
        out.append('kind %d: %s' % (k, hexw(p)))
    astarts, pstarts, recs = {}, {}, ['[kinds-2.bin]']
    for i, c in enumerate(cuts):
        e = cuts[i + 1] if i + 1 < len(cuts) else len(kr)
        r, a = kr[c:e], rbase + c
        lab = 'record %s: ' % hexw(a)
        kinds = by.get(a, [])
        note = ' ; kind %s' % ', '.join(map(str, kinds)) if kinds else ''
        if len(r) >= 7:
            w = [r[3] | r[4] << 8, r[5] | r[6] << 8]
            f = 'width=%d height=%d flags=$%02X path=%s anim=%s' % (r[0], r[1], r[2], hexw(w[0]), hexw(w[1]))
            pstarts.setdefault(w[0], set()).add('path of %s' % hexw(a))
            astarts.setdefault(w[1], set()).add('anim of %s' % hexw(a))
            rest = r[7:]
            if len(r) >= 11:
                w2 = [r[7] | r[8] << 8, r[9] | r[10] << 8]
                f += ' path2=%s anim2=%s' % (hexw(w2[0]), hexw(w2[1]))
                pstarts.setdefault(w2[0], set()).add('path2 of %s' % hexw(a))
                astarts.setdefault(w2[1], set()).add('anim2 of %s' % hexw(a))
                rest = r[11:]
            recs.append(lab + f + (' ' + ' '.join('$%02X' % b for b in rest) if rest else '') + note)
        else:
            recs.append(lab + ' '.join('$%02X' % b for b in r) + note)
    out.append('[anims.bin]')
    out += script_txt(an, abase, astarts, anim_items, None)
    out.append('[paths.bin]')
    out += script_txt(pa, pbase, pstarts, path_items, None)
    out += recs
    return ('\n'.join(out) + '\n').encode()


def txt_kinds(raw):
    g = split_groups(raw)
    return {'level/kinds.bin': text_fields(g['kinds.bin']), 'level/anims.bin': text_fields(g['anims.bin'], anim_token),
            'level/paths.bin': text_fields(g['paths.bin'], path_token), 'level/kinds-2.bin': text_fields(g['kinds-2.bin'])}


def frame_map_csv(data):
    out = ['# frame,sprite,mirrored (SpriteFrameMap $C20E: frame n of an animation shows sprite n\'s entry; 127 no sprite)']
    for i, b in enumerate(data):
        out.append('%d,%d,%d' % (i + 1, b & 127, b >> 7))
    return ('\n'.join(out) + '\n').encode()


def csv_frame_map(raw):
    return bytes(int(l.split(',')[1]) | int(l.split(',')[2]) << 7 for l in csv_lines(raw))


# Level 5's Fat Guy: FatGuyParts $F83C (5 x 8 bytes), FatGuyPiecePaths $F864 (path tokens), FatGuyPieceAnims $F8C5
# (anim tokens); FatGuyPath $FAF4 (path tokens).
FATGUY = 0xF83C


def fat_guy_txt(data):
    out = ['# The Fat Guy (level 5, FatGuyStart $F7E6): five parts of 8 bytes (width or x offset, height or y offset,',
           '# sprite, the path and the animation after the kill), then those paths and the animation (kinds.txt tokens).',
           '[parts]']
    for k in range(5):
        r = data[8 * k:8 * k + 8]
        out.append('part %d: w=%d h=%d sprite=%s path=%s anim=%s ; sprite %d' % (
            k, r[0], r[1], hexw(r[2] | r[3] << 8), hexw(r[4] | r[5] << 8), hexw(r[6] | r[7] << 8),
            ((r[2] | r[3] << 8) - 0xC26D) // 128))
    paths = {data[8 * k + 4] | data[8 * k + 5] << 8: {'part %d' % k} for k in range(5)}
    anims = min(data[8 * k + 6] | data[8 * k + 7] << 8 for k in range(5))
    pend = anims - FATGUY
    out.append('[paths]')
    out += script_txt(data[40:pend], FATGUY + 40, paths, path_items, None)
    out.append('[anims]')
    out += script_txt(data[pend:], FATGUY + pend, {anims: {'the pieces'}}, anim_items, None)
    return ('\n'.join(out) + '\n').encode()


def txt_fat_guy(raw):
    g = split_groups(raw)
    return text_fields(g['parts']) + text_fields(g['paths'], path_token) + text_fields(g['anims'], anim_token)


def fat_guy_path_txt(data):
    out = ['# FatGuyPath $FAF4: the Fat Guy\'s path while he lives (path tokens, kinds.txt)']
    out += script_txt(data, 0xFAF4, {0xFAF4: {'FatGuyPath'}}, path_items, None)
    return ('\n'.join(out) + '\n').encode()


def txt_fat_guy_path(raw):
    return text_fields(raw, path_token)


# ---------------------------------------------------------------------------------------------------- registry
# SINGLES: pattern of the .bin name -> (suffix of the editable file, to_editable(bytes), from_editable(bytes))
SINGLES = [
    ('screens/*.bin', '.png', screen_png, png_screen),
    ('texts/*.bin', '.txt', text_utf8, utf8_text),
    ('graphics/glyphs.bin', '.png', glyphs_png, png_glyphs),
    ('tables/level-starts.bin', '.csv', level_starts_csv, csv_level_starts),
    ('tables/section-counts.bin', '.csv', section_counts_csv, csv_section_counts),
    ('tables/beeper-effects.bin', '.txt', byte_lists_txt, txt_byte_lists),
    ('tables/*-frames.bin', '.csv', sprite_words_csv, csv_sprite_words),
    ('tunes/instruments.bin', '.csv', lambda d: records_csv(d, 10, False), lambda r: csv_records(r, False)),
    ('tunes/effects.bin', '.csv', lambda d: records_csv(d, 13, True), lambda r: csv_records(r, True)),
    ('tunes/ornaments.bin', '.csv', ornaments_csv, csv_ornaments),
    ('tables/periods.bin', '.csv', periods_csv, csv_periods),
    ('level/sprites.bin', '.png', sprites_png, png_sprites),
    ('level/cell-flags.bin', '.csv', cell_flags_csv, csv_cell_flags),
    ('level/blocks.bin', '.txt', blocks_txt, txt_blocks),
    ('level/maps.bin', '.txt', maps_txt, txt_maps),
    ('level/sections.bin', '.txt', sections_txt, txt_sections),
    ('level/frame-map.bin', '.csv', frame_map_csv, csv_frame_map),
    ('level/fat-guy.bin', '.txt', fat_guy_txt, txt_fat_guy),
    ('level/fat-guy-path.bin', '.txt', fat_guy_path_txt, txt_fat_guy_path),
]
# GROUPS: editable file -> ([its .bin names], to_editable({name: bytes}), from_editable(bytes) -> {name: bytes})
GROUPS = {
    'tunes/patterns.txt': (['tunes/patterns.bin', 'tunes/pattern-low.bin', 'tunes/pattern-high.bin'], patterns_txt,
                           txt_patterns),
    'tunes/tunes.txt': (['tunes/tune-table.bin', 'tunes/order-lists.bin'], tunes_txt, txt_tunes),
    'level/cells.png': (['level/cell-graphics.bin', 'level/cell-attrs.bin'], cells_png, png_cells),
    'level/kinds.txt': (['level/kinds.bin', 'level/anims.bin', 'level/paths.bin', 'level/kinds-2.bin'], kinds_txt,
                        txt_kinds),
    'tables/points.csv': (['tables/points-%s.bin' % p for p in POINTS], points_csv, csv_points),
}


def single_of(name):
    for pattern, suffix, to_ed, from_ed in SINGLES:
        if fnmatch.fnmatch(name, pattern):
            return suffix, to_ed, from_ed
    return None


def group_of(name):
    for ed, (bins, _to, _from) in GROUPS.items():
        if name in bins:
            return ed
    return None


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def install_into(files, res):
    """the bytes of each resource as its editable file under res; every conversion checked both ways"""
    done = set()
    for ed, (bins, to_ed, from_ed) in GROUPS.items():
        if not all(b in files for b in bins):
            continue
        part = {b: files[b] for b in bins}
        out = to_ed(part)
        if from_ed(out) != part:
            raise SystemExit('res: %s does not convert back to its bytes' % ed)
        write(os.path.join(res, ed), out)
        done |= set(bins)
    for name, data in files.items():
        if name in done:
            continue
        if group_of(name):
            raise SystemExit('res: %s is part of %s, whose other resources were not given' % (name, group_of(name)))
        fmt = single_of(name)
        if fmt:
            suffix, to_ed, from_ed = fmt
            out = to_ed(data)
            if from_ed(out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            write(os.path.join(res, os.path.splitext(name)[0] + suffix), out)
        else:
            write(os.path.join(res, name), data)


def install(files):
    install_into(files, RES)


def install_level(n, files):
    """a level part's resources, named level/NAME.bin in src/levels/levels.ann, into src/res/levels/levelN/"""
    install_into(files, os.path.join(RES, 'levels', 'level%d' % n))


def install_level1(files):
    install_level(1, files)


def install_level2(files):
    install_level(2, files)


def install_level3(files):
    install_level(3, files)


def install_level4(files):
    install_level(4, files)


def install_level5(files):
    install_level(5, files)


def sources():
    """(src path, its folder under src/res, rel name, kind) of every file of src/res: kind 'group', 'single' or
    None (bytes). A level's files are named as its .ann names them (level/NAME), their folder levels/levelN"""
    for top, _dirs, names in sorted(os.walk(RES)):
        for f in sorted(names):
            if f.endswith('.md') or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            folder = ''
            parts = rel.split(os.sep)
            if parts[0] == 'levels' and len(parts) > 2:
                folder, rel = os.path.join(parts[0], parts[1]), os.path.join(*parts[2:])
            if rel in GROUPS:
                yield src, folder, rel, 'group'
            elif not rel.endswith('.bin') and single_of(os.path.splitext(rel)[0] + '.bin'):
                yield src, folder, rel, 'single'
            else:
                yield src, folder, rel, None


def to_bytes(rel, kind, raw):
    if kind == 'group':
        return GROUPS[rel][2](raw)
    if kind == 'single':
        name = os.path.splitext(rel)[0] + '.bin'
        return {name: single_of(name)[2](raw)}
    return {rel: raw}


def build(out, levels):
    for src, folder, rel, kind in sources():
        for name, data in to_bytes(rel, kind, open(src, 'rb').read()).items():
            if folder:
                write(os.path.join(levels, os.path.basename(folder), 'res', name), data)
            else:
                write(os.path.join(out, name), data)


def check(against=None):
    bad = count = 0
    for src, folder, rel, kind in sources():
        raw = open(src, 'rb').read()
        if not kind:
            continue
        count += 1
        try:
            data = to_bytes(rel, kind, raw)
            if kind == 'group':
                again = GROUPS[rel][1](data)
            else:
                (name, d), = data.items()
                again = single_of(name)[1](d)
            ok = again == raw and to_bytes(rel, kind, again) == data
        except (ValueError, KeyError, IndexError) as e:
            print('res: %s: %s' % (src, e))
            ok = False
        if not ok:
            print('res: %s does not round-trip' % os.path.relpath(src, ROOT))
            bad += 1
            continue
        for name, d in data.items():
            ref = os.path.join(against, folder, name) if against else None
            if ref and os.path.exists(ref) and open(ref, 'rb').read() != d:
                print('res: %s differs from %s' % (os.path.relpath(src, ROOT), ref))
                bad += 1
    print('res: %d editable files, %d bad' % (count, bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--levels', default=os.path.join(ROOT, 'build', 'lres'))
    p.add_argument('--against')
    args = p.parse_args()
    if args.command == 'build':
        build(args.out, args.levels)
        return 0
    return check(args.against)


if __name__ == '__main__':
    sys.exit(main())

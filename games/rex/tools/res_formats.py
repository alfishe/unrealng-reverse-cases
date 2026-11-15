#!/usr/bin/env python3
"""Rex's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of a part (REX 1, REX 2, DEMO, the loading screens).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against DIR       # ... and gives the bytes of DIR/<name>.bin

Each part's names start with its own: rex1, rex2, demo. The formats (each folder's README.md lists its files,
addresses and readers):
- screens/*.png: a screen as colour cells: a PNG whose palette has 64 Spectrum entries, index = flash x 32 + ink x 16
  + bright x 8 + colour; a cell that is all ink or all paper keeps its attribute in the PNG text chunk `tx-cells`
  (with `length` when the tape holds less than 6912 bytes: the title screens end at $FFF9).
- chars/*.png: the 256 room characters (8 bytes each) with their attributes (CharAttrs), 16 a row, colour cells.
- fonts/*.png: the font, 64 characters of 8 x 8, 0 paper, 1 ink, 2 grid; `tx-sheet` gives the layout.
- sprites/*.png: the sprite banks, each label of the .ann a set drawn as one strip of its bytes, W bytes a line
  (W chosen by the look of the bytes, written in `tx-sprites`; any W gives the bytes back); 0 paper, 1 ink, 2 grid.
- rooms/*.txt: a part's rooms as text grids: the 7 x 10 block codes, the exits, the object lists (rooms/README.md).
- blocks/*.csv: the 256 blocks, 9 character codes each (3 x 3, rows top to bottom).
- texts/*.txt: text records, one a line: `$AT COL $LINE "TEXT"` ([attribute][column][line] text, 0); `bytes ...`
  for anything else. Printable codes 32-95 as themselves, `\\"` and `\\\\` escaped.
- tables/*.csv: a header line naming the columns, `#` lines comments, numbers decimal or `$hex`; tables/*.txt:
  byte lists, one a line.
- sound/*.txt: the effect descriptors, one an effect: the header, then its steps.
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


def hexes(bs):
    return ' '.join('$%02X' % b for b in bs)


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
MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]


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


def chars_to_png(data, cols=16):
    """the room characters: 8 x n pixel bytes, then n attributes"""
    n = len(data) // 9
    if len(data) != 9 * n:
        raise ValueError('chars: %d bytes is not 9 x n' % len(data))
    rows = (n + cols - 1) // cols
    img, px = new_png(1 + cols * 9, 1 + rows * 9, GREY, PALETTE)
    hidden = []
    for t in range(n):
        if paint_cell(px, 1 + (t % cols) * 9, 1 + (t // cols) * 9, data[8 * t:8 * t + 8], data[8 * n + t]):
            hidden.append([t, data[8 * n + t]])
    return save(img, 'tx-cells', {'tiles': n, 'cols': cols, 'hidden': hidden})


def png_to_chars(raw):
    _img, px, meta = open_png(raw, 'tx-cells')
    hidden = {t: a for t, a in meta['hidden']}
    pixels, attrs = bytearray(), bytearray()
    for t in range(meta['tiles']):
        rows, a = read_cell(px, 1 + (t % meta['cols']) * 9, 1 + (t // meta['cols']) * 9, hidden.get(t))
        pixels += bytes(rows)
        attrs.append(a)
    return bytes(pixels + attrs)


def screen_to_png(data):
    """a screen: 6144 pixel bytes, 768 attributes; a shorter one (the tape's end) is padded and cut back"""
    length = len(data)
    if not 6144 < length <= 6912:
        raise ValueError('screen: %d bytes' % length)
    data = data + bytes(6912 - length)
    img, px = new_png(256, 192, GREY, PALETTE)
    hidden = []
    for c in range(768):
        cy, cx = divmod(c, 32)
        rows = [data[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] for r in range(8)]
        if paint_cell(px, cx * 8, cy * 8, rows, data[6144 + c]):
            hidden.append([c, data[6144 + c]])
    meta = {'hidden': hidden}
    if length != 6912:
        meta['length'] = length
    return save(img, 'tx-cells', meta)


def png_to_screen(raw):
    _img, px, meta = open_png(raw, 'tx-cells')
    hidden = {c: a for c, a in meta['hidden']}
    out = bytearray(6912)
    for c in range(768):
        cy, cx = divmod(c, 32)
        rows, a = read_cell(px, cx * 8, cy * 8, hidden.get(c))
        for r in range(8):
            out[(cy // 8) * 2048 + r * 256 + (cy % 8) * 32 + cx] = rows[r]
        out[6144 + c] = a
    return bytes(out[:meta.get('length', 6912)])


# ---------------------------------------------------------------------------------------------------------------
# Mono pictures: the font (8 x 8 frames) and the sprite sets (strips of W bytes a line)
# ---------------------------------------------------------------------------------------------------------------
def font_to_png(data, cols=16):
    n = len(data) // 8
    if len(data) != 8 * n:
        raise ValueError('font: %d bytes' % len(data))
    rows = (n + cols - 1) // cols
    img, px = new_png(1 + cols * 9, 1 + rows * 9, 2, MONO)
    for f in range(n):
        x0, y0 = 1 + (f % cols) * 9, 1 + (f // cols) * 9
        for y in range(8):
            for x in range(8):
                px[x0 + x, y0 + y] = (data[8 * f + y] >> (7 - x)) & 1
    return save(img, 'tx-sheet', {'w': 8, 'h': 8, 'cols': cols, 'frames': n})


def png_to_font(raw):
    _img, px, m = open_png(raw, 'tx-sheet')
    out = bytearray(8 * m['frames'])
    for f in range(m['frames']):
        x0, y0 = 1 + (f % m['cols']) * 9, 1 + (f // m['cols']) * 9
        for y in range(8):
            for x in range(8):
                if px[x0 + x, y0 + y] == 1:
                    out[8 * f + y] |= 0x80 >> x
    return bytes(out)


# the sprite sets: the offsets of the .ann's labels inside each part's Sprites entry (SpriteStomper, SpriteRex, ...)
SPRITE_SETS = {
    'rex1': [0x0, 0xC0, 0x180, 0x1F8, 0x240, 0x480, 0x540, 0x600, 0x6C0, 0x720, 0x780, 0x840, 0x900, 0x980, 0xAD0,
             0xAE8, 0xBE8, 0xC98, 0xD38, 0xD78, 0xD8D, 0xD98, 0xE18, 0xED8, 0xEF8, 0xF18, 0xF38, 0xFD8, 0xFF0, 0x10B0,
             0x1130, 0x11C0, 0x1240, 0x1260, 0x1380],
    'rex2': [0x0, 0xC0, 0x120, 0x180, 0x1A0, 0x1C0, 0x280, 0x2F8, 0x340, 0x580, 0x640, 0x700, 0x780, 0x928, 0x9C8,
             0xA08, 0xA28, 0xA48, 0xB67, 0xB88, 0xC88, 0xD68, 0xE28, 0xEA8, 0xF68, 0xFE8],
    'demo': [0x0, 0x1F8, 0x240, 0x540, 0x600, 0x6C0, 0x8C0, 0x8D8, 0xA88, 0xB28, 0xB68, 0xB88, 0xCC8, 0xCE8, 0xD08,
             0xD28, 0xDC8, 0xEA0, 0xF20],
}


def shift_width(d):
    """(score, width) of the pre-shifted copies: the line width W (and height) under which the next frame is this
    one shifted right by 1, 2 or 4 pixels on most lines; None for a set with no such copies"""
    best = None
    for w in (2, 3, 4, 1):
        for h in range(4, 65):
            size = w * h
            if 2 * size > len(d):
                break
            good = tot = 0
            for f in range(min(len(d) // size - 1, 3)):
                for r in range(h):
                    a = int.from_bytes(d[f * size + r * w:f * size + r * w + w], 'big')
                    b = int.from_bytes(d[(f + 1) * size + r * w:(f + 1) * size + r * w + w], 'big')
                    if a or b:
                        tot += 1
                        good += any(a >> k == b for k in (1, 2, 4))
            if tot >= max(h // 2, 1) and (best is None or good / tot > best[0] + 0.001):
                best = (good / tot, w)
    return best


def guess_width(d):
    """the line width (1-4 bytes) of a sprite set: the pre-shifted copies' when they show (score 0.7 or more), else
    3 (a 16-pixel picture with room for its shift, the game's usual size) unless the bytes one line apart look
    clearly more alike under another"""
    shifted = shift_width(d)
    if shifted and shifted[0] >= 0.7:
        return shifted[1]
    score = {}
    for w in (1, 2, 3, 4):
        if len(d) % w == 0 and len(d) >= 2 * w:
            score[w] = sum(bin(d[i] ^ d[i + w]).count('1') for i in range(len(d) - w)) / (len(d) - w)
    if not score:
        return 1
    best = min(score, key=score.get)
    if 3 in score and score[best] > 0.7 * score[3]:
        return 3
    return best


def sprites_to_png(data, starts, width=256):
    ends = starts[1:] + [len(data)]
    sets, x, y, shelf = [], 1, 1, 0
    for s, e in zip(starts, ends):
        d = data[s:e]
        w = guess_width(d)
        h = len(d) // w
        if x + 8 * w + 1 > width:
            x, y, shelf = 1, y + shelf + 1, 0
        sets.append([s, e - s, w, x, y])
        x += 8 * w + 1
        shelf = max(shelf, h)
    img, px = new_png(width, y + shelf + 1, 2, MONO)
    for s, n, w, x0, y0 in sets:
        for i in range(n):
            r, c = divmod(i, w)
            for bit in range(8):
                px[x0 + 8 * c + bit, y0 + r] = (data[s + i] >> (7 - bit)) & 1
    return save(img, 'tx-sprites', {'sets': sets})


def png_to_sprites(raw):
    _img, px, m = open_png(raw, 'tx-sprites')
    out = bytearray(sum(n for _s, n, _w, _x, _y in m['sets']))
    for s, n, w, x0, y0 in m['sets']:
        for i in range(n):
            r, c = divmod(i, w)
            for bit in range(8):
                if px[x0 + 8 * c + bit, y0 + r] == 1:
                    out[s + i] |= 0x80 >> bit
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Texts: [attribute][column][line] text, 0
# ---------------------------------------------------------------------------------------------------------------
def quote(bs):
    return '"' + ''.join('\\"' if b == 34 else '\\\\' if b == 92 else chr(b) for b in bs) + '"'


def unquote(s):
    s = s.strip()
    if len(s) < 2 or s[0] != '"' or s[-1] != '"':
        raise ValueError('text: not a quoted string: %r' % s)
    s, out, i = s[1:-1], bytearray(), 0
    while i < len(s):
        if s[i] == '\\':
            i += 1
        out.append(ord(s[i]))
        i += 1
    return bytes(out)


def records_out(d, comments):
    lines, raw, i = head(comments), [], 0

    def flush():
        if raw:
            lines.append('bytes ' + hexes(raw))
            del raw[:]
    while i < len(d):
        j = d.find(0, i + 3) if i + 3 <= len(d) else -1
        if j > i + 3 and all(32 <= b < 96 for b in d[i + 3:j]) and d[i] != 0xFF:
            flush()
            lines.append('$%02X %d $%02X %s' % (d[i], d[i + 1], d[i + 2], quote(d[i + 3:j])))
            i = j + 1
        else:
            raw.append(d[i])
            i += 1
    flush()
    return text_file(lines)


def records_in(raw):
    out = bytearray()
    for ln in lines_of(raw):
        if ln.startswith('bytes '):
            out += bytes(num(x) for x in ln.split()[1:])
            continue
        a, c, y, rest = ln.split(None, 3)
        out += bytes([num(a), num(c), num(y)]) + unquote(rest) + b'\x00'
    return bytes(out)


def texts(comments):
    return '.txt', lambda d: records_out(d, comments), records_in


# ---------------------------------------------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------------------------------------------
def table(columns, comments, index, kinds=None):
    """records of one byte a column as CSV: index numbers the records (written, not read back)"""
    kinds = kinds or {}

    def out(d):
        n = len(columns)
        if len(d) % n:
            raise ValueError('table: %d bytes is no whole number of %d-byte records' % (len(d), n))
        lines = head(comments) + [','.join([index] + columns)]
        for r in range(len(d) // n):
            cells = [('%d' if kinds.get(c) == 'dec' else '$%02X') % d[r * n + i] for i, c in enumerate(columns)]
            lines.append(','.join([str(r)] + cells))
        return text_file(lines)

    def back(raw):
        return bytes(num(v) & 255 for ln in lines_of(raw)[1:] for v in ln.split(',')[1:])

    return '.csv', out, back


def lists(comments, end=0xFF):
    """byte lists ending in `end`, one a line"""
    def out(d):
        parts, cur = [], []
        for b in d:
            cur.append(b)
            if b == end:
                parts.append(cur)
                cur = []
        return text_file(head(comments) + [hexes(p) for p in parts + ([cur] if cur else [])])
    return '.txt', out, lambda raw: bytes(num(x) for ln in lines_of(raw) for x in ln.split())


# ---------------------------------------------------------------------------------------------------------------
# Sound: [channel 1-3][noise flag][steps][volume x 16][period word], then steps of [count][period change][volume change]
# ---------------------------------------------------------------------------------------------------------------
# the descriptors' offsets from SfxGun (the .ann's labels; the same layout in the three parts, DEMO's SfxShieldHit
# starts inside the lift step's descriptor)
SFX_STARTS = [0, 9, 18, 27, 36, 45, 57, 75, 87, 99, 120, 141, 162, 195]
SFX_EXTRA = {'demo': [66]}


def effects_out(d, comments, starts):
    lines = head(comments + ['', 'channel noise steps volume period | the steps: count period-change volume-change; '
                             'a descriptor is the bytes up to the next line\'s'])
    for s, e in zip(starts, starts[1:] + [len(d)]):
        x = d[s:e]
        if len(x) < 6:
            lines.append('bytes ' + hexes(x))
            continue
        groups = [hexes(x[k:k + 3]) for k in range(6, len(x), 3)]
        lines.append(' | '.join(['%d $%02X %d $%02X $%04X' % (x[0], x[1], x[2], x[3], x[4] | x[5] << 8)] + groups))
    return text_file(lines)


def effects_in(raw):
    out = bytearray()
    for ln in lines_of(raw):
        if ln.startswith('bytes '):
            out += bytes(num(x) for x in ln.split()[1:])
            continue
        parts = ln.split('|')
        ch, noise, n, vol, period = parts[0].split()
        period = num(period)
        out += bytes([num(ch), num(noise), num(n), num(vol), period & 255, period >> 8])
        for q in parts[1:]:
            out += bytes(num(x) for x in q.split())
    return bytes(out)


def effects(comments, part):
    starts = sorted(SFX_STARTS + SFX_EXTRA.get(part, []))
    return '.txt', lambda d: effects_out(d, comments, starts), effects_in


# ---------------------------------------------------------------------------------------------------------------
# Rooms: the maps (70 block codes a room), the exits (6 bytes a room) and the object lists (the exits' words)
# ---------------------------------------------------------------------------------------------------------------
OBJECT_LISTS = {'rex1': 0xAECD, 'rex2': 0xAFC2, 'demo': 0xAFEE}  # RoomObjectLists of each part
LIST_HEADER = {'rex1': 3, 'rex2': 3, 'demo': 2}  # [sides][period][kind]; DEMO has no spawn kind


def object_list(d, header):
    """a list's bytes split for the eye: the header | each [kind][X][Y] | $FF and anything after"""
    parts, i = [d[:header]], header
    while i + 3 <= len(d) and d[i] != 0xFF:
        parts.append(d[i:i + 3])
        i += 3
    if i < len(d):
        parts.append(d[i:])
    return ' | '.join(hexes(p) for p in parts if p)


def rooms_out(part):
    def out(files):
        maps, exits, objs = (files['rooms/%s-%s.bin' % (part, k)] for k in ('maps', 'exits', 'objects'))
        base = OBJECT_LISTS[part]
        if len(maps) % 70 or len(exits) % 6:
            raise ValueError('rooms: %d map bytes, %d exit bytes' % (len(maps), len(exits)))
        n_maps, n_exits = len(maps) // 70, len(exits) // 6
        words = [exits[6 * r + 4] | exits[6 * r + 5] << 8 for r in range(n_exits)]
        cuts = sorted({0} | {w - base for w in words if 0 < w - base < len(objs)})
        lines = head(['%s: the rooms. Each "room N" holds the exits (up, right, down, left: the room numbers, 0 none, '
                      '99 the end of the part)' % part.upper(),
                      'and the address of its object list, then the map: 7 rows of 10 block codes (blocks/%s.csv; '
                      'a block is 3 x 3 characters).' % part,
                      'The object lists follow, each at its address with the rooms that use it: the header | each '
                      '[kind][X][Y] | $FF;',
                      '(rooms/README.md). A room past the exits table has a map and no exits line.'])
        for r in range(max(n_maps, n_exits)):
            lines.append('room %d' % r)
            if r < n_exits:
                e = exits[6 * r:6 * r + 4]
                lines.append('exits %d %d %d %d $%04X' % (e[0], e[1], e[2], e[3], words[r]))
            if r < n_maps:
                for y in range(7):
                    lines.append('  ' + ' '.join('%02X' % b for b in maps[70 * r + 10 * y:70 * r + 10 * y + 10]))
        for s, e in zip(cuts, cuts[1:] + [len(objs)]):
            users = [str(r) for r in range(n_exits) if words[r] == base + s]
            lines.append('list $%04X %s: %s' % (base + s, ','.join(users) or '-', object_list(objs[s:e], LIST_HEADER[part])))
        return text_file(lines)
    return out


def rooms_in(part):
    def back(raw):
        maps, exits, objs = bytearray(), bytearray(), bytearray()
        base = OBJECT_LISTS[part]
        for ln in lines_of(raw):
            w = ln.split()
            if w[0] == 'room':
                continue
            if w[0] == 'exits':
                word = num(w[5])
                exits += bytes([int(w[1]), int(w[2]), int(w[3]), int(w[4]), word & 255, word >> 8])
            elif w[0] == 'list':
                if num(w[1]) != base + len(objs):
                    raise ValueError('rooms: list %s is not at $%04X' % (w[1], base + len(objs)))
                objs += bytes(num(x) for x in ln.split(':', 1)[1].split() if x != '|')
            else:
                if len(w) != 10:
                    raise ValueError('rooms: a map row of %d codes' % len(w))
                maps += bytes(int(x, 16) for x in w)
        return {'rooms/%s-maps.bin' % part: bytes(maps), 'rooms/%s-exits.bin' % part: bytes(exits),
                'rooms/%s-objects.bin' % part: bytes(objs)}
    return back


GROUPS = {'rooms/%s.txt' % p: (['rooms/%s-%s.bin' % (p, k) for k in ('maps', 'exits', 'objects')],
                               rooms_out(p), rooms_in(p)) for p in OBJECT_LISTS}

PART_NAMES = {'rex1': 'REX 1', 'rex2': 'REX 2', 'demo': 'DEMO'}
SINGLES = {}
for _p, _n in PART_NAMES.items():
    _blocks = table(['c%d' % i for i in range(9)], ['%s: BlockDefs, the 256 blocks: 3 x 3 character codes each (c0-c2 '
                                                    'the top row; the characters in chars/%s.png)' % (_n, _p)],
                    'block')
    SINGLES.update({
        'fonts/%s.bin' % _p: ('.png', font_to_png, png_to_font),
        'chars/%s.bin' % _p: ('.png', chars_to_png, png_to_chars),
        'sprites/%s.bin' % _p: ('.png', lambda d, p=_p: sprites_to_png(d, SPRITE_SETS[p]), png_to_sprites),
        'blocks/%s.bin' % _p: _blocks,
        'tables/%s-char-flags.bin' % _p: table(['type'], ['%s: CharFlags, the cell type of each room character '
                                                          '(rooms/README.md lists the types)' % _n], 'char',
                                               {'type': 'dec'}),
        'tables/%s-kill-scores.bin' % _p: table(['score'], ['%s: KillScores, the score of each object kind in '
                                                            'hundreds' % _n], 'kind', {'score': 'dec'}),
        'sound/%s-effects.bin' % _p: effects(['%s: the AY effect descriptors from SfxGun (sound/README.md)' % _n], _p),
    })
for _s in ('rex1', 'rex2', 'demo', 'rex1-title', 'rex2-title'):
    SINGLES['screens/%s.bin' % _s] = ('.png', screen_to_png, png_to_screen)
_TEXTS = {
    'rex1-game': 'REX 1: GameTexts, the play texts, the bonus panels and the weapon panels',
    'rex1-menu': 'REX 1: MenuTexts, the menu and the DEFINE texts',
    'rex1-roll-call': 'REX 1: RollCallTexts, the enemies\' names and scores, $FF ends; DefineTaken\'s 6 bytes after',
    'rex1-hud': 'REX 1: HudTexts, the HUD\'s three rows ("]\\ ^\\ ..." are the HUD\'s icon characters)',
    'rex1-code': 'REX 1: CodeText, the CODE panel ("CODE:" and the 16 places the digits are written into)',
    'rex2-game': 'REX 2: GameTexts, the play texts and the panels',
    'rex2-menu': 'REX 2: MenuTexts, the menu and the DEFINE texts',
    'rex2-hud': 'REX 2: HudTexts, the HUD\'s three rows',
    'rex2-code': 'REX 2: CodeTexts, the code panel\'s texts',
    'demo-hud': 'DEMO: HudTexts, the HUD\'s three rows',
    'demo-bonus': 'DEMO: BonusTexts, the bonus roulette\'s five panels',
    'demo-tutor': 'DEMO: TutorTexts, the tutor\'s panels and the credits (TutorCredits)',
}
for _k, _c in _TEXTS.items():
    SINGLES['texts/%s.bin' % _k] = texts([_c, '$attribute column $line "text"; "bytes": anything else'])
SINGLES['tables/demo-tutor-rooms.bin'] = lists(['DEMO: TutorRooms, the rooms the demo plays in turn, $FF: again'])
SINGLES['tables/rex1-attract-rooms.bin'] = lists(['REX 1: AttractRooms, the attract mode\'s rooms, $FF: again'])


def group_of(name):
    for ed, (bins, _to, _from) in GROUPS.items():
        if name in bins:
            return ed
    return None


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def install(files):
    done, made = set(), {}
    for ed, (bins, to_ed, from_ed) in GROUPS.items():
        if not all(b in files for b in bins):
            continue
        part = {b: files[b] for b in bins}
        out = to_ed(part)
        if from_ed(out) != part:
            raise SystemExit('res: %s does not convert back to its bytes' % ed)
        write(os.path.join(RES, ed), out)
        done |= set(bins)
        made.update({b: ed for b in bins})
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
    return made


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
                ok, data = False, {}
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

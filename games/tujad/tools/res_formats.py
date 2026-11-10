#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the game's and the screen part's).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- screen/LoadingScreen.png: the 6912-byte screen as a 256 x 192 picture in the Spectrum's colours. The palette has 64
  entries, index = flash x 32 + ink x 16 + bright x 8 + colour: the picture shows the screen (without the flash),
  and each pixel's index says whether it is ink or paper, so the bytes come back exactly. A cell whose 64 pixels
  are all paper (or all ink) cannot show its other colour; the PNG text chunk `tujad-hidden` keeps those cells'
  attributes (row, column, attribute in hex).
- PNG sheets (sprites/, graphics/, tiles/TileData.png): an indexed PNG, palette 0 paper (black), 1 ink (white),
  2 grid (grey); each frame drawn top row first (every draw routine of the game goes down the screen from the
  first byte). The text chunk `tujad-sheet` holds, in the order of the bytes, each frame's place and size and the
  bytes before its rows (the enemy and object frames' shift byte, a tile block's width and height), and any bytes
  no frame covers (`raw`), so a sheet builds back on its own. SHEETS below gives each sheet's rows of frames.
- tiles/TileTables.txt, rooms/Rooms.txt: text, the formats in each file's header.
- rooms/StartPositions.csv: CSV with a header line naming the columns; `#` lines are comments; numbers decimal or
  `$hex`.
- text/: UTF-8, one quoted string a line, `#` lines comments; printable ASCII as itself, \u00a9 the ROM font's $7F,
  `\\xNN` any other byte, `\\"` and `\\\\` escaped. Messages.txt groups them by message with its priority.
- leftover/Source*.txt: the authors' tokenised assembler source, one stored line a line (label TAB mnemonic TAB
  operands), `cut "..."` for the bytes of a line cut off at either end.
Any other file stays its bytes.
"""
import argparse
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


# ---------------------------------------------------------------------------------------------------------------
# A Spectrum screen as a colour PNG that keeps ink and paper apart
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


SCREEN_PALETTE = []
for _i in range(64):
    SCREEN_PALETTE += zx_rgb(_i & 7, (_i >> 3) & 1)


def pixel_addr(x, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)


def screen_to_png(d, rows=24):
    from PIL import Image, PngImagePlugin
    img = Image.new('P', (256, rows * 8), 0)
    img.putpalette(SCREEN_PALETTE)
    px = img.load()
    attrs = d[6144:6144 + 768]
    hidden = []
    for y in range(rows * 8):
        for x in range(256):
            a = attrs[(y >> 3) * 32 + (x >> 3)]
            ink = (d[pixel_addr(x, y)] >> (7 - (x & 7))) & 1
            colour = a & 7 if ink else (a >> 3) & 7
            px[x, y] = (a >> 7) * 32 + ink * 16 + ((a >> 6) & 1) * 8 + colour
    for r in range(rows):
        for c in range(32):
            cell = [d[pixel_addr(c * 8, y)] for y in range(r * 8, r * 8 + 8)]
            if all(b == 0 for b in cell) or all(b == 255 for b in cell):
                hidden.append('%d,%d,%02X' % (r, c, attrs[r * 32 + c]))
    info = PngImagePlugin.PngInfo()
    info.add_text('tujad-hidden', ' '.join(hidden))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_screen(png, rows=24):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    hidden = {}
    for t in img.text.get('tujad-hidden', '').split():
        r, c, a = t.split(',')
        hidden[int(r), int(c)] = int(a, 16)
    d = bytearray(6144 + 768)
    for r in range(rows):
        for c in range(32):
            ink = paper = None
            for y in range(r * 8, r * 8 + 8):
                b = 0
                for x in range(c * 8, c * 8 + 8):
                    i = px[x, y]
                    b = b << 1 | ((i >> 4) & 1)
                    if (i >> 4) & 1:
                        ink = i
                    else:
                        paper = i
                d[pixel_addr(c * 8, y)] = b
            if (r, c) in hidden:
                a = hidden[r, c]
            else:
                a = (ink >> 5) << 7 | ((ink >> 3) & 1) << 6 | (paper & 7) << 3 | (ink & 7)
                if (ink & 0x28) != (paper & 0x28):
                    raise ValueError('cell %d,%d: ink and paper differ in flash or bright' % (r, c))
            d[6144 + r * 32 + c] = a
    return bytes(d)




# ---------------------------------------------------------------------------------------------------------------
# PNG sheets: frames of 1-bit graphics, any width and height, placed on a grid
# ---------------------------------------------------------------------------------------------------------------
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128]


def frames(n, wbytes, rows, head=0):
    return [(wbytes, rows, head)] * n


# the .bin name -> (a row of the sheet a list of frames (bytes across, pixel rows, bytes before the rows))
SHEETS = {
    # $9C40: walk 0-7, turn 8-9, the front (beam) 10, the side move while falling 11-13 (DroidFrames $6888)
    'sprites/Droid.bin': [frames(8, 3, 40), frames(3, 2, 40), frames(3, 3, 40)],
    # $A74E: the nine enemy kinds (4, 3, then 4 frames: EnemyGraphics $68C1), then the explosion ($AE01)
    'sprites/Enemies.bin': [frames(4, 3, 16, 1), frames(3, 3, 16, 1)] + [frames(4, 3, 16, 1)] * 7
                           + [frames(4, 3, 16, 1)],
    # $AEC5: an enemy materialising (MaterialiseFrames $68DB)
    'sprites/Materialise.bin': [frames(4, 3, 16)],
    # $AF85: weapon 3's probe
    'sprites/Probe.bin': [frames(4, 3, 16, 1)],
    # $B049: the object kinds of bits 4, 5, 6, 7 and none (ObjectKind $7C28), their death ($B6BA), the probe's
    # explosion ($B83E)
    'sprites/Objects.bin': [frames(3, 4, 24, 1), frames(4, 4, 24, 1), frames(3, 4, 24, 1), frames(4, 4, 24, 1),
                            frames(3, 4, 24, 1), frames(4, 4, 24, 1), frames(4, 3, 16, 1)],
    # $B902: a patroller going right, then left
    'sprites/Patrollers.bin': [frames(4, 4, 24), frames(4, 4, 24)],
    # $8814: the bolts of weapons 1 and 2, two frames each
    'sprites/ShotGraphics.bin': [frames(4, 2, 8)],
    # $8C55: weapons 0-3, GEN 19, the HUD's energy, the energy source
    'sprites/HudIcons.bin': [frames(7, 2, 16)],
    # $8BFD: the HUD frame's characters
    'graphics/HudGraphics.bin': [frames(11, 1, 8)],
    # $8DB2: the menu logo's block
    'graphics/MenuLogoGraphic.bin': [frames(1, 2, 16)],
    # $BC02: the menu frame: top, bottom, left, right edges, the corners top left, top right, bottom left,
    # bottom right
    'graphics/MenuFrame.bin': [frames(4, 2, 16), frames(4, 2, 16)],
    # $E002: the font, codes $20-$5B, 16 a row
    'graphics/Font.bin': [frames(16, 1, 8), frames(16, 1, 8), frames(16, 1, 8), frames(12, 1, 8)],
    # $E1E2: the picture the 50 ED pieces make, 10 x 5 (piece n is the tile at column (n - 1) / 5, row
    # (n - 1) % 5: DrawItem $6E0D, ProgressScreen $8F53)
    'graphics/EdPieces.bin': [frames(10, 2, 16)] * 5,
}


def sheet_layout(rows):
    """The items of a sheet laid out row by row: (x, y, bytes across, pixel rows, head bytes)"""
    items, y = [], 1
    cw = max(f[0] for r in rows for f in r) * 8
    for r in rows:
        x, h = 1, max(f[1] for f in r)
        for wb, rr, head in r:
            items.append([x, y, wb, rr, head])
            x += cw + 1
        y += h + 1
    return items


def sheet_to_png(data, items, raws=()):
    """items: [x, y, bytes across, pixel rows, head] in the order of the bytes; raws: (offset, bytes) kept as
    they are (bytes no graphic covers). The text chunk `tujad-sheet` holds the layout and the head bytes."""
    import json
    from PIL import Image, PngImagePlugin
    width = max(x + wb * 8 for x, y, wb, rr, hd in items) + 1
    height = max(y + rr for x, y, wb, rr, hd in items) + 1
    img = Image.new('P', (width, height), 2)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    layout, p, raws = [], 0, dict(raws)
    for x, y, wb, rr, hd in items:
        while p in raws:
            layout.append({'raw': raws[p].hex()})
            p += len(raws.pop(p))
        layout.append({'x': x, 'y': y, 'w': wb, 'h': rr, 'head': data[p:p + hd].hex()})
        p += hd
        for k in range(wb * rr):
            b = data[p + k]
            for bit in range(8):
                px[x + (k % wb) * 8 + bit, y + k // wb] = (b >> (7 - bit)) & 1
        p += wb * rr
    while p in raws:
        layout.append({'raw': raws[p].hex()})
        p += len(raws.pop(p))
    if p != len(data) or raws:
        raise ValueError('the sheet covers %d of %d bytes' % (p, len(data)))
    info = PngImagePlugin.PngInfo()
    info.add_text('tujad-sheet', json.dumps(layout, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_sheet(png):
    import json
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    out = bytearray()
    for it in json.loads(img.text['tujad-sheet']):
        if 'raw' in it:
            out += bytes.fromhex(it['raw'])
            continue
        out += bytes.fromhex(it['head'])
        x, y, wb, rr = it['x'], it['y'], it['w'], it['h']
        for k in range(wb * rr):
            b = 0
            for bit in range(8):
                b = b << 1 | (1 if px[x + (k % wb) * 8 + bit, y + k // wb] == 1 else 0)
            out.append(b)
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The tile graphics TileData $E822-$FDFF: one block a tile, laid out by tile number, 10 a row
# ---------------------------------------------------------------------------------------------------------------
TILE_DATA, TILE_TABLES = 0xE822, 0x6EA8
TILE_SLOT_W, TILE_SLOT_H = 8 * 8, 48


def tile_pointers(tables):
    return [tables[2 * i] | tables[2 * i + 1] << 8 for i in range(71)]


INSTALLING = {}


def current_tables():
    """The bytes of tiles/TileTables.bin: the ones being installed, else from src/res"""
    if 'tiles/TileTables.bin' in INSTALLING:
        return INSTALLING['tiles/TileTables.bin']
    txt = os.path.join(RES, 'tiles', 'TileTables.txt')
    if os.path.exists(txt):
        return tiletables_in(open(txt, 'rb').read())
    return open(os.path.join(RES, 'tiles', 'TileTables.bin'), 'rb').read()


def tiledata_to_png(data):
    """The blocks the 71 TileGraphics words point at, tile n in slot n - 1; the bytes between them kept raw"""
    tables = current_tables()
    ptrs = tile_pointers(tables)
    blocks = sorted((p, n + 1) for n, p in enumerate(ptrs) if p)
    items, raws, at = [], [], 0
    for p, tile in blocks:
        o = p - TILE_DATA
        if o > at:
            raws.append((at, data[at:o]))
        wb, rr = data[o], data[o + 1]
        slot = tile - 1
        items.append([1 + (slot % 10) * (TILE_SLOT_W + 1), 1 + (slot // 10) * (TILE_SLOT_H + 1), wb, rr, 2])
        at = o + 2 + wb * rr
    if at < len(data):
        raws.append((at, data[at:]))
    return sheet_to_png(data, items, raws)


# ---------------------------------------------------------------------------------------------------------------
# Text: one quoted string a line, `#` lines comments; printable ASCII as itself, (c) for the ROM font's $7F,
# \xNN any other byte, \" and \\ escaped
# ---------------------------------------------------------------------------------------------------------------
CHARMAP = {0x7F: '©'}
CHARCODES = {v: k for k, v in CHARMAP.items()}


def quote(bs):
    t = ''
    for b in bs:
        if b in CHARMAP:
            t += CHARMAP[b]
        elif b in (0x22, 0x5C):
            t += '\\' + chr(b)
        elif 0x20 <= b < 0x7F:
            t += chr(b)
        else:
            t += '\\x%02X' % b
    return '"' + t + '"'


def unquote(s):
    s = s.strip()
    if not (len(s) >= 2 and s.startswith('"') and s.endswith('"')):
        raise ValueError('not a quoted string: %s' % s)
    s, out, i = s[1:-1], bytearray(), 0
    while i < len(s):
        if s[i] == '\\':
            if s[i + 1] == 'x':
                out.append(int(s[i + 2:i + 4], 16))
                i += 4
            else:
                out.append(ord(s[i + 1]))
                i += 2
        elif s[i] in CHARCODES:
            out.append(CHARCODES[s[i]])
            i += 1
        else:
            if ord(s[i]) > 0x7E:
                raise ValueError('no game code for %r in %s' % (s[i], s))
            out.append(ord(s[i]))
            i += 1
    return bytes(out)


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.startswith('#')]


TEXT_HEAD = {
    'text/MenuTexts.bin': ['MenuTexts $8D38: the menu\'s texts, each ending in "." (Menu $8854 prints them: TUJAD, the',
                           'three controls, START GAME); the last line ($8D85, the copyright line) is never printed.'],
    'text/ProgressText.bin': ['ProgressText $9072: the progress screen\'s line (ProgressPercent $9046 writes the two',
                              'digits at +19 and +20); the last byte ($9092) is ProgressPercentBcd, the percentage in',
                              'BCD (2 a piece).'],
}
QUOTE_HEAD = ['UTF-8, one quoted string a line: printable ASCII as itself, © the ROM font\'s $7F, \\xNN any',
              'other byte, \\" and \\\\ escaped. The build joins the strings.']


def split_text_out(name, d):
    parts, s = [], 0
    for i, b in enumerate(d):
        if b == 0x2E:
            parts.append(d[s:i + 1])
            s = i + 1
    if s < len(d):
        parts.append(d[s:])
    lines = ['# ' + c for c in TEXT_HEAD[name] + QUOTE_HEAD] + [quote(p) for p in parts]
    return ('\n'.join(lines) + '\n').encode('utf-8')


def split_text_in(_name, raw):
    return b''.join(unquote(ln) for ln in lines_of(raw))


MESSAGE_ROW = 19
MESSAGES_HEAD = ['Messages $63D2: the ten messages of the scroller. A message is "message PRIORITY" and its text,',
                 'one quoted line a row of 19 characters as the scroller shows them (Interrupt $95D0: the window at',
                 '$402C is 19 characters wide); the last row ends with "." (the end mark, not shown). QueueMessage',
                 '$6ACD takes a message only when its priority is above the one shown.'] + QUOTE_HEAD


def messages_out(_name, d):
    lines, p = ['# ' + c for c in MESSAGES_HEAD], 0
    while p < len(d):
        e = d.index(0x2E, p + 1)
        text = d[p + 1:e]
        lines.append('message %d' % d[p])
        rows = [text[i:i + MESSAGE_ROW] for i in range(0, len(text), MESSAGE_ROW)] or [b'']
        rows[-1] += b'.'
        lines += ['  ' + quote(r) for r in rows]
        p = e + 1
    return ('\n'.join(lines) + '\n').encode('utf-8')


def messages_in(_name, raw):
    out = bytearray()
    for ln in lines_of(raw):
        t = ln.split()
        if t[0] == 'message':
            out.append(int(t[1]))
        else:
            out += unquote(ln)
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The authors' leftover assembler source (leftover/Source*.bin): the editor's tokenised lines
# ---------------------------------------------------------------------------------------------------------------
SOURCE_HEAD = ['The authors\' assembler source as their editor stored it, left in the image where the game later',
               'keeps variables (no code reads these bytes before writing them). A stored line is [length][label]',
               '[length][mnemonic][length][operands] and 3 bytes (always 0 here). One line here a stored line:',
               'label TAB mnemonic TAB operands; a line of ";" alone is an empty source line. "cut" lines are the',
               'bytes of a line cut off by the variables before or after (quoted, \\xNN for any byte).']


def parse_source_line(d, p):
    """(label, mnemonic, operands, trailer, next) of the stored line at p, or None"""
    fields = []
    for _ in range(3):
        if p >= len(d):
            return None
        n = d[p]
        if n > 40 or p + 1 + n > len(d):
            return None
        f = d[p + 1:p + 1 + n]
        if any(not 0x20 < b < 0x7F for b in f):
            return None
        fields.append(f)
        p += 1 + n
    if p + 3 > len(d):
        return None
    return fields[0], fields[1], fields[2], d[p:p + 3], p + 3


def source_out(_name, d):
    best = None
    for k in range(min(len(d), 48)):
        p, lines = k, []
        while True:
            r = parse_source_line(d, p)
            if r is None or r[3] != b'\x00\x00\x00':
                break
            lines.append(r)
            p = r[4]
        if lines and (best is None or p - k > best[2] - best[0]):
            best = (k, lines, p)
            if k == 0 and p == len(d):
                break
    k, recs, end = best
    out = ['# ' + c for c in SOURCE_HEAD]
    if k:
        out.append('cut ' + quote(d[:k]))
    for lab, mn, op, _tr, _n in recs:
        out.append(';' if not (lab or mn or op) else '\t'.join(x.decode() for x in (lab, mn, op)))
    if end < len(d):
        out.append('cut ' + quote(d[end:]))
    return ('\n'.join(out) + '\n').encode('utf-8')


def source_in(_name, raw):
    out = bytearray()
    for ln in raw.decode('utf-8').split('\n'):
        if not ln or ln.startswith('#'):
            continue
        if ln.startswith('cut '):
            out += unquote(ln[4:])
            continue
        fields = ['', '', ''] if ln == ';' else ln.split('\t')
        if len(fields) != 3:
            raise ValueError('a source line needs label TAB mnemonic TAB operands: %r' % ln)
        for f in fields:
            out.append(len(f))
            out += f.encode('ascii')
        out += b'\x00\x00\x00'
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The rooms (rooms/Rooms.bin, $BD06-$DFFF): RoomLayouts and AlienMap, one section a room
# ---------------------------------------------------------------------------------------------------------------
ROOMS_AT, LAYOUTS, LAYOUT_RECORDS, EMPTY_LAYOUT = 0xBD06, 0xBD06, 0xBE06, 0xDB52
ALIEN_MAP, ALIEN_RECORDS, EMPTY_ALIEN, ROOMS_END = 0xDB53, 0xDC53, 0xDFFA, 0xE000
OBJECT_FIELDS = ['kind', 'state', 'x', 'y', 'graphic', 'frame', 'frames', 'mark', 'attr']
ROOMS_HEAD = [
    'The 128 rooms of RoomLayouts $BD06 and AlienMap $DB53, room n at column n % 8, row n / 8 of the world (8 across,',
    '16 down: +1 east, +8 south). "room N empty": one of the 26 rooms that share the empty layout $DB52 and the empty',
    'alien record $DFFA. A room\'s lines:',
    '  tile T at C,R      a tile of TileGraphics $6EA8 (1-70) with its top-left character at column C (0-31), row R',
    '                     of the play area (screen row R + 5; rows above screen row 6 are not drawn), in order',
    '  item1 / item2 KIND at C,R   or "none": the room\'s items (KIND gen19 $80, energy $81, ed1-ed50 $82-$B3,',
    '                     weapon1-weapon3 $C1-$C3, or $XX); C,R the top-left cell (C even, R 0-15: ItemCell $6E88)',
    '  teleport to ROOM at C,R   or "teleport none"',
    '  enemies B,B,...    the enemies that may spawn here (bits of the mask, 0-3), or "enemies none"',
    '  object1 / object2 kind=$XX state=$XX x=N y=N graphic=$XXXX frame=N frames=N mark=$XX attr=$XX, or "none":',
    '                     the 10-byte object record as Objects $6327 holds it (DrawRoom copies it, SaveRoomObjects',
    '                     writes it back)',
    'The build lays the records out in room order and rebuilds both offset tables.']


def item_name(k):
    if k == 0x80:
        return 'gen19'
    if k == 0x81:
        return 'energy'
    if 0x82 <= k <= 0xB3:
        return 'ed%d' % (k - 0x81)
    if 0xC1 <= k <= 0xC3:
        return 'weapon%d' % (k - 0xC0)
    return '$%02X' % k


def item_code(t):
    if t == 'gen19':
        return 0x80
    if t == 'energy':
        return 0x81
    if t.startswith('ed'):
        return 0x81 + int(t[2:])
    if t.startswith('weapon'):
        return 0xC0 + int(t[6:])
    return num(t)


def pos_text(p):
    return '%d,%d' % ((p >> 4) * 2, p & 15)


def pos_code(t):
    c, r = (int(x) for x in t.split(','))
    if c % 2 or not 0 <= r < 16 or not 0 <= c < 32:
        raise ValueError('a position needs an even column 0-30 and a row 0-15: %s' % t)
    return (c // 2) << 4 | r


def rooms_out(_name, d):
    m = lambda a: d[a - ROOMS_AT]
    w = lambda a: m(a) | m(a + 1) << 8
    out = ['# ' + c for c in ROOMS_HEAD]
    for n in range(128):
        lay, al = LAYOUTS + w(LAYOUTS + 2 * n), ALIEN_MAP + w(ALIEN_MAP + 2 * n)
        out.append('')
        if lay == EMPTY_LAYOUT and al == EMPTY_ALIEN:
            out.append('room %d empty' % n)
            continue
        out.append('room %d' % n)
        p = lay
        while not m(p) & 0x80:
            out.append('  tile %d at %d,%d' % (m(p + 2), m(p), m(p + 1)))
            p += 3
        if m(p) != 0x80:
            raise ValueError('room %d: the layout ends with $%02X' % (n, m(p)))
        p = al
        for what in ('item1', 'item2', 'teleport'):
            if not m(p):
                out.append('  %s none' % what)
                p += 1
            elif what == 'teleport':
                out.append('  teleport to %d at %s' % (m(p + 1), pos_text(m(p))))
                p += 2
            else:
                out.append('  %s %s at %s' % (what, item_name(m(p + 1)), pos_text(m(p))))
                p += 2
        mask = m(p)
        bits = [str(b) for b in range(8) if mask >> b & 1]
        out.append('  enemies ' + (','.join(bits) if bits else 'none'))
        p += 1
        for what in ('object1', 'object2'):
            if not m(p):
                out.append('  %s none' % what)
                p += 1
                continue
            r = [m(p + i) for i in range(10)]
            vals = [r[0], r[1], r[2], r[3], r[4] | r[5] << 8, r[6], r[7], r[8], r[9]]
            fmt = ['$%02X', '$%02X', '%d', '%d', '$%04X', '%d', '%d', '$%02X', '$%02X']
            out.append('  %s ' % what + ' '.join('%s=%s' % (k, f % v) for k, f, v in zip(OBJECT_FIELDS, fmt, vals)))
            p += 10
    return ('\n'.join(out) + '\n').encode('utf-8')


def rooms_in(_name, raw):
    rooms, cur = {}, None
    for ln in raw.decode('utf-8').split('\n'):
        t = ln.split()
        if not t or ln.startswith('#'):
            continue
        if t[0] == 'room':
            cur = int(t[1])
            rooms[cur] = None if t[2:] == ['empty'] else {'tiles': bytearray(), 'alien': bytearray()}
            continue
        r = rooms[cur]
        if t[0] == 'tile':
            c, row = (int(x) for x in t[3].split(','))
            r['tiles'] += bytes([c, row, int(t[1])])
        elif t[0] in ('item1', 'item2'):
            r['alien'] += b'\x00' if t[1] == 'none' else bytes([pos_code(t[3]), item_code(t[1])])
        elif t[0] == 'teleport':
            r['alien'] += b'\x00' if t[1] == 'none' else bytes([pos_code(t[4]), int(t[2])])
        elif t[0] == 'enemies':
            mask = 0 if t[1] == 'none' else sum(1 << int(b) for b in t[1].split(','))
            r['alien'].append(mask)
        elif t[0] in ('object1', 'object2'):
            if t[1] == 'none':
                r['alien'].append(0)
                continue
            v = dict(kv.split('=') for kv in t[1:])
            g = num(v['graphic'])
            r['alien'] += bytes([num(v['kind']), num(v['state']), num(v['x']), num(v['y']), g & 255, g >> 8,
                                 num(v['frame']), num(v['frames']), num(v['mark']), num(v['attr'])])
        else:
            raise ValueError('rooms: unknown line %r' % ln)
    if sorted(rooms) != list(range(128)):
        raise ValueError('rooms: need rooms 0-127')
    lay_tab, lay_rec = bytearray(), bytearray()
    al_tab, al_rec = bytearray(), bytearray()
    lay_data = LAYOUT_RECORDS
    for n in range(128):
        r = rooms[n]
        if r is None:
            continue
        lay_rec += r['tiles'] + b'\x80'
        al_rec += r['alien']
    empty_layout = LAYOUT_RECORDS + len(lay_rec)
    alien_map = empty_layout + 1
    alien_records = alien_map + 256
    empty_alien = alien_records + len(al_rec)
    lp, ap = lay_data, alien_records
    for n in range(128):
        r = rooms[n]
        if r is None:
            lo, ao = empty_layout - LAYOUTS, empty_alien - alien_map
        else:
            lo, ao = lp - LAYOUTS, ap - alien_map
            lp += len(r['tiles']) + 1
            ap += len(r['alien'])
        lay_tab += bytes([lo & 255, lo >> 8])
        al_tab += bytes([ao & 255, ao >> 8])
    out = lay_tab + lay_rec + b'\x80' + al_tab + al_rec + b'\x00' * 6
    if alien_map != ALIEN_MAP or len(out) != ROOMS_END - ROOMS_AT:
        raise ValueError('rooms: the records moved (the alien map at $%04X, %d bytes): the code reads RoomLayouts'
                         ' at $BD06 and AlienMap at $DB53, keep the sizes or move the labels' % (alien_map, len(out)))
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# CSV tables: a header line naming the columns; `#` lines comments; numbers decimal or $hex
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, columns, rows):
    lines = ['# ' + c for c in comments] + [','.join(columns)]
    lines += [','.join(str(v) for v in r) for r in rows]
    return ('\n'.join(lines) + '\n').encode('utf-8')


def csv_rows(raw):
    rows, header = [], None
    for line in raw.decode('utf-8').split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if header is None:
            header = line.split(',')
            continue
        rows.append([c.strip() for c in line.split(',')])
    return rows


def starts_out(_name, d):
    return csv_out(['StartPositions $9484: where the droid starts in each room after a life lost or at a new game',
                    '(PlaceDroid $7A6D: x the column 0-$1D, y the pixel row $30-$98). Of the 26 empty rooms\'',
                    'rows L1 reads only room 32\'s, once.'],
                   ['room', 'x', 'y'], [[n, d[2 * n], d[2 * n + 1]] for n in range(128)])


def starts_in(_name, raw):
    rows = csv_rows(raw)
    if [int(r[0]) for r in rows] != list(range(128)):
        raise ValueError('StartPositions: need rooms 0-127 in order')
    return bytes(b for r in rows for b in (num(r[1]), num(r[2])))


# ---------------------------------------------------------------------------------------------------------------
# The tile tables (tiles/TileTables.bin, $6EA8-$7160): TileGraphics, TileAttrs and the colour blocks
# ---------------------------------------------------------------------------------------------------------------
TILE_ATTRS, TILE_ATTR_DATA, TILE_TABLES_END = 0x6F36, 0x6FC2, 0x7161
TILES_HEAD = [
    'The tile tables: TileGraphics $6EA8 (71 words: tiles 1-70 and a 71st no code reads) and TileAttrs $6F36 (70',
    'words), then the colour blocks $6FC2-$7160 the TileAttrs words point at (tiles share blocks).',
    '  tile N graphic $XXXX colours $YYYY   the tile\'s block in TileData (src/res/tiles/TileData.png) and colours',
    '  colours $YYYY B B B ...              a colour block from its address: a first byte with bit 7 is one',
    '                                       colour (bits 0-6) for every cell of the tile, else one attribute a',
    '                                       cell, row by row (width x height / 8 cells). The blocks follow each',
    '                                       other from $6FC2; the build checks the addresses.']


def tiletables_out(_name, d):
    w = lambda o: d[o] | d[o + 1] << 8
    out = ['# ' + c for c in TILES_HEAD]
    g = [w(2 * i) for i in range(71)]
    a = [w(142 + 2 * i) for i in range(70)]
    for i in range(71):
        out.append('tile %d graphic $%04X' % (i + 1, g[i]) + (' colours $%04X' % a[i] if i < 70 else ''))
    starts = sorted({x for x in a if TILE_ATTR_DATA <= x < TILE_TABLES_END} | {TILE_ATTR_DATA})
    for k, s in enumerate(starts):
        e = starts[k + 1] if k + 1 < len(starts) else TILE_TABLES_END
        blk = d[s - TILE_TABLES:e - TILE_TABLES]
        out.append('colours $%04X %s' % (s, ' '.join('%02X' % b for b in blk)))
    return ('\n'.join(out) + '\n').encode('utf-8')


def tiletables_in(raw, _name=None):
    g, a, data, at = {}, {}, bytearray(), TILE_ATTR_DATA
    for ln in lines_of(raw):
        t = ln.split()
        if t[0] == 'tile':
            g[int(t[1])] = num(t[3])
            if len(t) > 4:
                a[int(t[1])] = num(t[5])
        elif t[0] == 'colours':
            if num(t[1]) != at:
                raise ValueError('colours $%04X: the next block is at $%04X' % (num(t[1]), at))
            blk = bytes(int(x, 16) for x in t[2:])
            data += blk
            at += len(blk)
    out = bytearray()
    for i in range(1, 72):
        out += bytes([g[i] & 255, g[i] >> 8])
    for i in range(1, 71):
        out += bytes([a[i] & 255, a[i] >> 8])
    return bytes(out + data)


def editable(name):
    if name == 'screen/LoadingScreen.bin':
        return '.png', lambda n, d: screen_to_png(d), lambda n, d: png_to_screen(d)
    if name in SHEETS:
        return '.png', lambda n, d: sheet_to_png(d, sheet_layout(SHEETS[n])), lambda n, d: png_to_sheet(d)
    if name == 'tiles/TileData.bin':
        return '.png', lambda n, d: tiledata_to_png(d), lambda n, d: png_to_sheet(d)
    if name == 'tiles/TileTables.bin':
        return '.txt', tiletables_out, lambda n, d: tiletables_in(d)
    if name == 'rooms/Rooms.bin':
        return '.txt', rooms_out, rooms_in
    if name == 'rooms/StartPositions.bin':
        return '.csv', starts_out, starts_in
    if name == 'text/Messages.bin':
        return '.txt', messages_out, messages_in
    if name in TEXT_HEAD:
        return '.txt', split_text_out, split_text_in
    if name.startswith('leftover/Source'):
        return '.txt', source_out, source_in
    return None


def install(files):
    INSTALLING.update(files)
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

#!/usr/bin/env python3
"""Editable sources for the resources of src/res (src/res/README.md). Graphics are PNG, the level, the menu tune and
the order names are text. They become the original `.bin` files at build time (tools/build.sh), and the build's
byte-exact check against orig/NETHER.TAP keeps them honest. kit/mkgame.py --install calls install(files) with the
bytes of each @res entry.

| Source | Files built | Format |
| --- | --- | --- |
| `gfx/font.png` | `gfx/font.bin` | 8 x 8 glyphs, 16 a row, from code `$20`, top line first; index 0 paper, 1 ink |
| `gfx/view-edges.png` | `gfx/view-edges.bin` | the two 16 x 8 edge patterns side by side (ViewEdgeA, ViewEdgeB) |
| `gfx/sprites/NAME.png` | `gfx/sprites/NAME.bin` | one sprite block, upright; the PNG's size is its header |
| `map/level.txt` | `map/*.bin`, `map/shapes/*.bin` | the scenery and base lists, the shape table and the 11 shapes |
| `music/menu.txt` | `music/menu/*.bin` | the menu tune: 3 drum tracks, the bass and lead tracks and patterns |
| `text/order-names.txt` | `text/order-names.bin` | the 9 order names, three 8-character lines each |

Sprite pixels: 0 see-through (mask 1, graphic 0), 1 paper (mask 0, graphic 0), 2 ink (mask 0, graphic 1), 3 ink
over the background (mask 1, graphic 1: 3 bytes of the image have it, all in the cannon sprites). A PNG may be
saved indexed or as RGB in exactly the palette's colours.

    python3 tools/res_formats.py build [--out build/res]      # every file of src/res, the sources converted
    python3 tools/res_formats.py export [--from DIR]          # .bin files (src/res or DIR) to sources in src/res
    python3 tools/res_formats.py check                        # every source: built, written back, built again
    (--res DIR before the command works on another src/res, a scratch copy)

Other tools read a resource with `res_formats.load('gfx/sprites/ship.bin')`, built from its source on the fly.
"""
import argparse
import io
import os
import re
import shutil
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

GLYPH_PALETTE = [(24, 24, 32), (230, 230, 230)]                      # paper, ink
EDGE_PALETTE = [(230, 230, 230), (24, 24, 32)]                       # paper, ink (black in the view)
SPRITE_PALETTE = [(70, 110, 120), (230, 230, 230), (24, 24, 32), (240, 190, 60)]
COLUMNS = 16

FONT, EDGES, LEVEL, MENU, ORDERS = 'gfx/font.png', 'gfx/view-edges.png', 'map/level.txt', 'music/menu.txt', \
    'text/order-names.txt'
SPRITE = re.compile(r'gfx/sprites/[a-z0-9-]+\.bin')

# The level: the sections of map/level.txt, laid one after the other from $BDA9 (BuildMap $BC6F reads them)
LEVEL_ORG = 0xBDA9
LEVEL_PARTS = [('SceneryWest', 'scenery', 'map/scenery-west.bin'), ('SceneryEast', 'scenery', 'map/scenery-east.bin'),
               ('BaseListWest', 'bases', 'map/bases-west.bin'), ('BaseListEast', 'bases', 'map/bases-east.bin'),
               ('ShapeTable', 'table', 'map/shape-table.bin')] + \
    [(label, 'shape', 'map/shapes/%s.bin' % name) for label, name in [
        ('ShapeWarbase', 'warbase'), ('ShapeFactory', 'factory'), ('ShapeLowTiles', 'low-tiles'),
        ('ShapeMidTiles', 'mid-tiles'), ('ShapeTallWallV', 'tall-wall-v'), ('ShapeTallWallH', 'tall-wall-h'),
        ('ShapeEdgeFence', 'edge-fence'), ('ShapeFlatLineV', 'flat-line-v'), ('ShapeFlatLineH', 'flat-line-h'),
        ('ShapeLowWallH', 'low-wall-h'), ('ShapeMixedWallH', 'mixed-wall-h')]]
HALF = {'SceneryWest': 0, 'SceneryEast': 1, 'BaseListWest': 0, 'BaseListEast': 1}  # the x high byte (D)
RESOURCE_NAMES = {1: 'electronics', 2: 'nuclear', 3: 'phasers', 4: 'missiles', 5: 'cannon', 6: 'chassis'}

# The menu tune: the sections of music/menu.txt, laid one after the other from $C665 (MenuMusic $C4A7)
MENU_ORG = 0xC665
MENU_PARTS = [(label, kind, 'music/menu/%s.bin' % name) for label, kind, name in [
    ('DrumTrackSteady', 'drums', 'drum-steady'), ('DrumTrackUnused', 'drums', 'drum-unused'),
    ('DrumTrackBeat', 'drums', 'drum-beat'), ('BassTrack', 'voice', 'bass-track'), ('BassRiff', 'voice', 'bass-riff'),
    ('BassWalk', 'voice', 'bass-walk'), ('BassRun', 'voice', 'bass-run'), ('LeadTrack', 'voice', 'lead-track'),
    ('LeadRiff', 'voice', 'lead-riff'), ('LeadPhrase', 'voice', 'lead-phrase'),
    ('LeadArpeggioA', 'voice', 'lead-arpeggio-a'), ('LeadArpeggioB', 'voice', 'lead-arpeggio-b'),
    ('LeadScale', 'voice', 'lead-scale')]]
VOICE = {1: ('goto', 2), 2: ('call', 2), 3: ('drums', 2), 4: ('on', 0), 5: ('off', 0), 6: ('return', 0)}

ORDER_RECORD, ORDER_LINE = 27, 8  # three lines of 8 joined by code 3, ended by 0 (OrderNames $A848)

# ---------------------------------------------------------------------------------------------------------- PNG


def indexed(image, palette, name):
    """the pixels of a PNG as palette indices: px[x, y], (width, height)"""
    if image.mode == 'P' and image.getpalette()[:3 * len(palette)] == [c for rgb in palette for c in rgb]:
        px = image.load()
        for y in range(image.height):
            for x in range(image.width):
                if px[x, y] >= len(palette):
                    sys.exit(f'{name}: index {px[x, y]} at ({x}, {y}) is past the palette')
        return px, image.size
    rgb = image.convert('RGB')
    src = rgb.load()
    lookup = {c: i for i, c in enumerate(palette)}
    out = {}
    for y in range(rgb.height):
        for x in range(rgb.width):
            if src[x, y] not in lookup:
                sys.exit(f'{name}: colour {src[x, y]} at ({x}, {y}) is not in the palette {palette}')
            out[x, y] = lookup[src[x, y]]
    return out, rgb.size


def new_indexed(size, palette, fill=0):
    image = Image.new('P', size, fill)
    image.putpalette([c for rgb in palette for c in rgb])
    return image


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG')
    return buffer.getvalue()


def font_to_png(data):
    count = len(data) // 8
    image = new_indexed((COLUMNS * 8, (count + COLUMNS - 1) // COLUMNS * 8), GLYPH_PALETTE)
    px = image.load()
    for g in range(count):
        for line in range(8):
            for bit in range(8):
                px[(g % COLUMNS) * 8 + bit, (g // COLUMNS) * 8 + line] = 1 if data[g * 8 + line] & (0x80 >> bit) else 0
    return image


def png_to_font(image, name):
    px, (w, h) = indexed(image, GLYPH_PALETTE, name)
    if w != COLUMNS * 8 or h % 8:
        sys.exit(f'{name}: {w} x {h}, not {COLUMNS * 8} wide and whole glyph rows')
    out = bytearray()
    for g in range(COLUMNS * h // 8):
        for line in range(8):
            out.append(sum(0x80 >> bit for bit in range(8) if px[(g % COLUMNS) * 8 + bit, (g // COLUMNS) * 8 + line]))
    return bytes(out)


def edges_to_png(data):
    """32 bytes: two patterns of 8 lines x 2 bytes, top line first, the left byte first (DrawEdgeStrips $D057)"""
    image = new_indexed((32, 8), EDGE_PALETTE)
    px = image.load()
    for p in range(2):
        for line in range(8):
            for byte in range(2):
                for bit in range(8):
                    px[p * 16 + byte * 8 + bit, line] = 1 if data[p * 16 + line * 2 + byte] & (0x80 >> bit) else 0
    return image


def png_to_edges(image, name):
    px, size = indexed(image, EDGE_PALETTE, name)
    if size != (32, 8):
        sys.exit(f'{name}: {size}, not 32 x 8')
    out = bytearray()
    for p in range(2):
        for line in range(8):
            for byte in range(2):
                out.append(sum(0x80 >> bit for bit in range(8) if px[p * 16 + byte * 8 + bit, line]))
    return bytes(out)


def sprite_to_png(data, name='sprite'):
    """a block: height, width in bytes, then the rows from the bottom line up, each width (mask, graphic) pairs"""
    lines, width = data[0], data[1]
    if len(data) != 2 + 2 * lines * width or not lines or not width:
        sys.exit(f'{name}: {len(data)} bytes, the header says {lines} lines x {width} bytes')
    image = new_indexed((width * 8, lines), SPRITE_PALETTE)
    px = image.load()
    at = 2
    for line in range(lines):
        for byte in range(width):
            mask, graphic = data[at], data[at + 1]
            at += 2
            for bit in range(8):
                m, g = mask & (0x80 >> bit), graphic & (0x80 >> bit)
                px[byte * 8 + bit, lines - 1 - line] = (3 if g else 0) if m else (2 if g else 1)
    return image


def png_to_sprite(image, name):
    px, (w, lines) = indexed(image, SPRITE_PALETTE, name)
    if w % 8 or not 0 < lines < 256 or not 0 < w <= 255 * 8:
        sys.exit(f'{name}: {w} x {lines}: the width must be whole bytes, 1-255 of them, and 1-255 lines')
    out = bytearray((lines, w // 8))
    for line in range(lines):
        for byte in range(w // 8):
            mask = graphic = 0
            for bit in range(8):
                c = px[byte * 8 + bit, lines - 1 - line]
                mask |= (0x80 >> bit) if c in (0, 3) else 0
                graphic |= (0x80 >> bit) if c in (2, 3) else 0
            out += bytes((mask, graphic))
    return bytes(out)


# ------------------------------------------------------------------------------------- laid-out text (level, tune)


def number(word, where):
    try:
        if word.startswith('$'):
            return int(word[1:], 16)
        if word.startswith('-$'):
            return -int(word[2:], 16)
        return int(word)
    except ValueError:
        sys.exit(f'{where}: {word!r} is no number')


def byte(word, where, signed=False):
    v = number(word, where)
    if not (-128 <= v < 128 if signed else 0 <= v < 256):
        sys.exit(f'{where}: {word} does not fit a {"signed " if signed else ""}byte')
    return v & 0xFF


def signed(b):
    return b - 256 if b >= 128 else b


def word_bytes(a):
    return bytes((a & 0xFF, a >> 8))


def db_line(data):
    return '  db ' + ','.join('$%02X' % b for b in data)


class Layout:
    """the sections of a text file, laid one after the other from org; addresses as labels, two passes"""

    def __init__(self, parts, org):
        self.parts, self.org = parts, org

    def ref_function(self, datas):
        starts, at = [], self.org
        for data in datas:
            starts.append(at)
            at += len(data)

        def ref(address):
            best = max((i for i, s in enumerate(starts) if s <= address), default=None)
            if best is None or address >= at:
                return '$%04X' % address
            off = address - starts[best]
            return self.parts[best][0] + ('+%d' % off if off else '')
        return ref

    def parse(self, text, name):
        sections, current = [], None
        for line_no, raw in enumerate(text.splitlines(), 1):
            line = raw.split(';')[0].strip()
            if not line:
                continue
            words = line.split()
            if not raw[0].isspace():
                if len(words) != 2:
                    sys.exit(f'{name}:{line_no}: a section starts in column 1: KIND Label')
                current = (words[0], words[1], [])
                sections.append(current)
            elif current is None:
                sys.exit(f'{name}:{line_no}: a command before the first section')
            else:
                current[2].append((f'{name}:{line_no}', words))
        order = [(k, label) for label, k, _ in self.parts]
        if [(k, label) for k, label, _ in sections] != order:
            sys.exit(f'{name}: the sections must be, in this order: ' + ', '.join(f'{k} {lb}' for k, lb in order))
        return sections

    def assemble(self, sections, encode_line):
        labels = {}

        def run(final):
            at, out = self.org, []
            for kind, label, commands in sections:
                labels[label] = at
                data = bytearray()

                def address(word, where):
                    m = re.fullmatch(r'([A-Za-z_]\w*)(?:\+(\d+))?', word)
                    if not m:
                        return number(word, where) & 0xFFFF
                    if m.group(1) not in labels:
                        if final:
                            sys.exit(f'{where}: unknown label {m.group(1)}')
                        return 0
                    return labels[m.group(1)] + int(m.group(2) or 0)

                for where, words in commands:
                    if words[0] == 'db':
                        data += bytes(byte(w, where) for w in ' '.join(words[1:]).replace(',', ' ').split())
                    elif words[0] == 'dw':
                        for w in ' '.join(words[1:]).replace(',', ' ').split():
                            data += word_bytes(address(w, where))
                    else:
                        data += encode_line(kind, label, words, where, address)
                out.append(bytes(data))
                at += len(data)
            return out

        run(False)  # the labels first
        return run(True)


# ----------------------------------------------------------------------------------------------------- the level

LEVEL_LAYOUT = Layout(LEVEL_PARTS, LEVEL_ORG)


def level_to_text(datas):
    ref = LEVEL_LAYOUT.ref_function(datas)
    table = datas[[p[0] for p in LEVEL_PARTS].index('ShapeTable')]
    shape_names = {i: ref(table[2 * i] | table[2 * i + 1] << 8) for i in range(len(table) // 2)}
    out = ['; The level (r3.md: BuildMap $BC6F, PlaceScenery, PlaceBases, DrawShape $BD61), assembled by',
           '; tools/res_formats.py into the files of src/res/map. The sections follow each other from $%04X; an'
           % LEVEL_ORG,
           '; address is Label, Label+offset or $xxxx.',
           '; A column x is the map column 0-511 (the West lists hold 0-255, the East lists 256-511), a row y 0-15.',
           '; scenery: block TILE x y (a 2 x 2 block of the tile, its bottom left cell at (x, y)) | shape N x y',
           ';          (ShapeTable entry N drawn from (x, y)) | end (the 0 that ends the list)',
           '; bases:   warbase x y | factory TYPE x y (TYPE 1-6: the resource it makes) | base TYPE x y | end ($FF)',
           '; table:   dw Label, the shape of each index from 0',
           '; shape:   the steps from the start cell, each a block (or none) and then a move: block TILE move DX DY |',
           ';          move DX DY (no block) | block TILE end | end (the last step: its move is (0, 0)); DX columns,',
           ';          DY rows, signed',
           '; db $xx,... and dw Label,... write bytes as they are', '']
    for (label, kind, _), data in zip(LEVEL_PARTS, datas):
        out.append(f'{kind} {label}')
        p = 0
        if kind == 'table':
            for i in range(0, len(data) - 1, 2):
                out.append('  dw %-16s ; shape %d' % (ref(data[i] | data[i + 1] << 8), i // 2))
            p = len(data) - len(data) % 2
        while p < len(data):
            if kind == 'scenery':
                if data[p] == 0:
                    out.append('  end')
                    p += 1
                    continue
                if p + 3 > len(data):
                    break
                t, x, y = data[p], data[p + 1] | HALF[label] << 8, data[p + 2]
                if t & 0x80:
                    out.append('  shape %-3d %3d %2d     ; %s' % (t & 0x7F, x, y, shape_names.get(t & 0x7F, '?')))
                else:
                    out.append('  block $%02X %3d %2d' % (t, x, y))
                p += 3
            elif kind == 'bases':
                if data[p] & 0x80:
                    if data[p] != 0xFF:
                        break
                    out.append('  end')
                    p += 1
                    continue
                if p + 3 > len(data):
                    break
                t, x, y = data[p], data[p + 1] | HALF[label] << 8, data[p + 2]
                if t == 0:
                    out.append('  warbase   %3d %2d' % (x, y))
                elif t in RESOURCE_NAMES:
                    out.append('  factory %d %3d %2d     ; %s' % (t, x, y, RESOURCE_NAMES[t]))
                else:
                    out.append('  base %d %3d %2d' % (t, x, y))
                p += 3
            else:  # a shape
                if p + 3 > len(data):
                    break
                t, dx, dy = data[p], signed(data[p + 1]), signed(data[p + 2])
                move = 'end' if dx == 0 and dy == 0 else 'move %d %d' % (dx, dy)
                out.append('  ' + ('block $%02X %s' % (t, move) if t else move))
                p += 3
        if p < len(data):
            out.append(db_line(data[p:]))
        out.append('')
    return '\n'.join(out)


def level_line(kind, label, words, where, address):
    op, rest = words[0], words[1:]

    def column(word):
        x, half = number(word, where), HALF[label]
        if not half * 256 <= x < half * 256 + 256:
            sys.exit(f'{where}: column {x} is not in {label} ({half * 256}-{half * 256 + 255})')
        return x & 0xFF

    def want(n):
        if len(rest) != n:
            sys.exit(f'{where}: {op} takes {n} value(s)')

    if kind == 'scenery':
        if op == 'end':
            want(0)
            return b'\x00'
        if op == 'block':
            want(3)
            t = byte(rest[0], where)
            if t == 0 or t & 0x80:
                sys.exit(f'{where}: a block tile is $01-$7F')
            return bytes((t, column(rest[1]), byte(rest[2], where)))
        if op == 'shape':
            want(3)
            n = byte(rest[0], where)
            if n > 0x7F:
                sys.exit(f'{where}: a shape number is 0-127')
            return bytes((0x80 | n, column(rest[1]), byte(rest[2], where)))
    elif kind == 'bases':
        if op == 'end':
            want(0)
            return b'\xff'
        if op == 'warbase':
            want(2)
            return bytes((0, column(rest[0]), byte(rest[1], where)))
        if op in ('factory', 'base'):
            want(3)
            t = byte(rest[0], where)
            if t & 0x80 or (op == 'factory' and t not in RESOURCE_NAMES):
                sys.exit(f'{where}: {op} type {t}')
            return bytes((t, column(rest[1]), byte(rest[2], where)))
    elif kind == 'shape':
        tile = 0
        if op == 'block':
            if len(rest) < 2:
                sys.exit(f'{where}: block TILE move DX DY | block TILE end')
            tile, op, rest = byte(rest[0], where), rest[1], rest[2:]
        if op == 'end' and not rest:
            return bytes((tile, 0, 0))
        if op == 'move' and len(rest) == 2:
            dx, dy = byte(rest[0], where, True), byte(rest[1], where, True)
            if dx == 0 and dy == 0:
                sys.exit(f'{where}: a move of (0, 0) ends the shape: write end')
            return bytes((tile, dx, dy))
    sys.exit(f'{where}: cannot read {" ".join(words)!r} in a {kind} section')


# ------------------------------------------------------------------------------------------------- the menu tune

MENU_LAYOUT = Layout(MENU_PARTS, MENU_ORG)


def menu_to_text(datas):
    ref = MENU_LAYOUT.ref_function(datas)
    out = ['; The menu tune (r4.md: MenuMusic $C4A7, MenuInterrupt $C4FD, DrumStep $C5DB), assembled by',
           '; tools/res_formats.py into the files of src/res/music/menu. The sections follow each other from $%04X;'
           % MENU_ORG,
           '; an address is Label, Label+offset or $xxxx. A frame is 1/50 s (one interrupt).',
           '; Periods: the tone loop counts a period down, about 3.5 MHz / (125.5 * period) Hz ($7C ~225 Hz,',
           '; $3E ~450 Hz).',
           '; drums: hiss N (kind 0) | rasp N [KIND] (kind 1, or any other kind but 0 and 2) | sweep N P (kind 2: a',
           ';        falling tone from P) | goto Label. N frames to the next record (0 = 256, 1 cannot be written).',
           '; voice: note P N (period P >= 9, N frames; 0 = 256) | on | off (the pulses silent, the notes keep their',
           ';        time) | call Label (a pattern, one level deep) | return | goto Label | drums Label (the drum',
           ';        goes on at Label: the bass track only)',
           '; db $xx,... and dw Label,... write bytes as they are', '']
    for (label, kind, _), data in zip(MENU_PARTS, datas):
        out.append(f'{kind} {label}')
        p = 0
        while p < len(data):
            b = data[p]
            if kind == 'drums':
                if b == 1:
                    if p + 3 > len(data):
                        break
                    out.append('  goto ' + ref(data[p + 1] | data[p + 2] << 8))
                    p += 3
                    continue
                if p + 2 > len(data):
                    break
                k = data[p + 1]
                if k == 2:
                    if p + 3 > len(data):
                        break
                    out.append('  sweep %d $%02X' % (b, data[p + 2]))
                    p += 3
                    continue
                out.append('  hiss %d' % b if k == 0 else '  rasp %d' % b if k == 1 else '  rasp %d %d' % (b, k))
                p += 2
            else:
                if b >= 9:
                    if p + 2 > len(data):
                        break
                    out.append('  note $%02X %d' % (b, data[p + 1]))
                    p += 2
                    continue
                if b not in VOICE:
                    break
                name, n = VOICE[b]
                if p + 1 + n > len(data):
                    break
                out.append('  ' + name + (' ' + ref(data[p + 1] | data[p + 2] << 8) if n else ''))
                p += 1 + n
        if p < len(data):
            out.append(db_line(data[p:]))
        out.append('')
    return '\n'.join(out)


def menu_line(kind, label, words, where, address):
    op, rest = words[0], words[1:]
    if kind == 'drums':
        if op == 'goto' and len(rest) == 1:
            return b'\x01' + word_bytes(address(rest[0], where))
        if op in ('hiss', 'rasp', 'sweep') and rest:
            n = byte(rest[0], where)
            if n == 1:
                sys.exit(f'{where}: 1 frame cannot be written (the byte 1 is the goto)')
            if op == 'hiss' and len(rest) == 1:
                return bytes((n, 0))
            if op == 'sweep' and len(rest) == 2:
                return bytes((n, 2, byte(rest[1], where)))
            if op == 'rasp' and len(rest) in (1, 2):
                k = byte(rest[1], where) if len(rest) == 2 else 1
                if k in (0, 2):
                    sys.exit(f'{where}: kind {k} is no rasp')
                return bytes((n, k))
    else:
        if op == 'note' and len(rest) == 2:
            period = byte(rest[0], where)
            if period < 9:
                sys.exit(f'{where}: a period below 9 is a command')
            return bytes((period, byte(rest[1], where)))
        code = next((c for c, (n, _) in VOICE.items() if n == op), None)
        if code is not None and len(rest) == VOICE[code][1] // 2:
            return bytes((code,)) + (word_bytes(address(rest[0], where)) if rest else b'')
    sys.exit(f'{where}: cannot read {" ".join(words)!r} in a {kind} section')


# --------------------------------------------------------------------------------------------- the order names


def order_line_ok(s):
    return len(s) == ORDER_LINE and all(0x20 <= c < 0x60 and c != 0x22 for c in s)


def orders_to_text(data):
    out = ['; The order names (OrderNames $A848), one line an order 0-8 (robot +$0B): three quoted lines of 8',
           '; characters (font codes $20-$5F, no quote). ShowOrder copies the 27-byte record (the lines joined by',
           '; code 3, ended by 0) into OrderLine. A record that is not so is written N db $xx,...', '']
    for i in range(len(data) // ORDER_RECORD):
        r = data[i * ORDER_RECORD:(i + 1) * ORDER_RECORD]
        parts = r[:-1].split(b'\x03')
        if r[-1] == 0 and len(parts) == 3 and all(order_line_ok(s) for s in parts):
            out.append('%d ' % i + ' '.join('"%s"' % s.decode('ascii') for s in parts))
        else:
            out.append('%d db ' % i + ','.join('$%02X' % b for b in r))
    tail = data[len(data) - len(data) % ORDER_RECORD:]
    if tail:
        out.append('tail db ' + ','.join('$%02X' % b for b in tail))
    return '\n'.join(out) + '\n'


def text_to_orders(text, name):
    out = bytearray()
    for line_no, raw in enumerate(text.splitlines(), 1):
        where = f'{name}:{line_no}'
        line = raw.strip()
        if not line or line.startswith(';'):
            continue
        head, _, rest = line.partition(' ')
        rest = rest.strip()
        if head != 'tail' and number(head, where) != len(out) // ORDER_RECORD:
            sys.exit(f'{where}: order {head} out of turn')
        if rest.startswith('db '):
            record = bytes(byte(w, where) for w in rest[3:].replace(',', ' ').split())
        else:
            lines = re.findall(r'"([^"]*)"', rest)
            if len(lines) != 3 or not all(order_line_ok(s.encode('ascii', 'replace')) for s in lines):
                sys.exit(f'{where}: an order is three quoted lines of {ORDER_LINE} characters, codes $20-$5F')
            record = b'\x03'.join(s.encode('ascii') for s in lines) + b'\x00'
        if head != 'tail' and len(record) != ORDER_RECORD:
            sys.exit(f'{where}: a record is {ORDER_RECORD} bytes')
        out += record
    return bytes(out)


# -------------------------------------------------------------------------------------------------- the sources

GROUPS = {LEVEL: (LEVEL_LAYOUT, LEVEL_PARTS, level_to_text, level_line),
          MENU: (MENU_LAYOUT, MENU_PARTS, menu_to_text, menu_line)}


def editable(name):
    """the source of a .bin file of src/res, or None"""
    for source, (_, parts, _, _) in GROUPS.items():
        if name in [f for _, _, f in parts]:
            return source
    if name in ('gfx/font.bin', 'gfx/view-edges.bin'):
        return name[:-4] + '.png'
    if name == 'text/order-names.bin':
        return ORDERS
    if SPRITE.fullmatch(name):
        return name[:-4] + '.png'
    return None


def decode_data(source, data):
    """{file: bytes} built from the contents of one source"""
    if source in GROUPS:
        layout, parts, _, line = GROUPS[source]
        datas = layout.assemble(layout.parse(data.decode(), source), line)
        return {f: d for (_, _, f), d in zip(parts, datas)}
    name = source[:-4] + '.bin'
    if source == ORDERS:
        return {name: text_to_orders(data.decode(), source)}
    image = Image.open(io.BytesIO(data))
    if source == FONT:
        return {name: png_to_font(image, source)}
    if source == EDGES:
        return {name: png_to_edges(image, source)}
    return {name: png_to_sprite(image, source)}


def decode(source, res=RES):
    return decode_data(source, open(os.path.join(res, source), 'rb').read())


def encode(files):
    """{source: bytes of the file to write} for the editable files among {name: bytes}"""
    out = {}
    for source, (_, parts, to_text, _) in GROUPS.items():
        datas = [files.get(f) for _, _, f in parts]
        if any(d is not None for d in datas):
            if None in datas:
                sys.exit(f'{source} needs all of ' + ', '.join(f for _, _, f in parts))
            out[source] = to_text(datas).encode()
    for name, data in files.items():
        source = editable(name)
        if source is None or source in GROUPS:
            continue
        if source == ORDERS:
            out[source] = orders_to_text(data).encode()
        elif source == FONT:
            out[source] = png_bytes(font_to_png(data))
        elif source == EDGES:
            out[source] = png_bytes(edges_to_png(data))
        else:
            out[source] = png_bytes(sprite_to_png(data, name))
    return out


def walk(res):
    for folder, _, names in os.walk(res):
        for n in names:
            yield os.path.relpath(os.path.join(folder, n), res).replace(os.sep, '/')


def sources(res=RES):
    return sorted(rel for rel in walk(res) if rel in GROUPS or rel == ORDERS or
                  (rel.endswith('.png') and editable(rel[:-4] + '.bin') == rel))


_cache = {}


def load(name, res=RES):
    """the bytes of a resource file of src/res, built from its source when it has one"""
    path = os.path.join(res, name)
    if os.path.exists(path):
        return open(path, 'rb').read()
    source = editable(name)
    if source is None or not os.path.exists(os.path.join(res, source)):
        raise FileNotFoundError(path)
    if (res, source) not in _cache:
        _cache[res, source] = decode(source, res)
    return _cache[res, source][name]


def build_files(res=RES):
    """{name: bytes} of every file the source INCBINs: the raw files as they are, the sources converted"""
    files, srcs = {}, sources(res)
    for rel in walk(res):
        if rel not in srcs and not rel.endswith('README.md'):
            files[rel] = open(os.path.join(res, rel), 'rb').read()
    for source in srcs:
        for name, data in decode(source, res).items():
            if name in files:
                sys.exit(f'{name} and its source {source} both exist in {res}: delete one')
            files[name] = data
    return files


def build(out, res=RES):
    """every file of res into out, the sources converted; the sources themselves are not copied"""
    files = build_files(res)
    if os.path.exists(out):
        shutil.rmtree(out)
    for name, data in files.items():
        os.makedirs(os.path.dirname(os.path.join(out, name)), exist_ok=True)
        open(os.path.join(out, name), 'wb').write(data)
    return files


def install(files, res=RES):
    """write {name: bytes} into src/res: editable files as their sources (the .bin removed), the others as they are"""
    for source, data in encode(files).items():
        os.makedirs(os.path.dirname(os.path.join(res, source)), exist_ok=True)
        open(os.path.join(res, source), 'wb').write(data)
    for name, data in files.items():
        path = os.path.join(res, name)
        if editable(name):
            if os.path.exists(path):
                os.remove(path)
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)


def check(res=RES):
    """each source: its bytes, written back out as a source and built again, are the same bytes; a text source
    written back is also the same text"""
    bad = 0
    for source in sources(res):
        built = decode(source, res)
        written = encode(built)[source]
        same = decode_data(source, written) == built
        if same and not source.endswith('.png'):
            same = written == open(os.path.join(res, source), 'rb').read() or 'edited'
        bad += same is False
        state = {True: 'round trip exact', 'edited': 'round trip exact (the text differs from the exported one)',
                 False: 'ROUND TRIP DIFFERS'}[same]
        print(f'{source}: {len(built)} file(s), {sum(map(len, built.values()))} bytes, {state}')
    return bad


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--res', default=RES, help='the src/res folder to work on (default: the case\'s)')
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    e = sub.add_parser('export')
    e.add_argument('--from', dest='src')
    sub.add_parser('check')
    args = p.parse_args()
    if args.cmd == 'build':
        files = build(args.out, args.res)
        print(f'res: {len(files)} files from {len(sources(args.res))} sources into {args.out}')
    elif args.cmd == 'export':
        src = args.src or args.res
        files = {rel: open(os.path.join(src, rel), 'rb').read() for rel in walk(src) if editable(rel)}
        install(files, args.res)
        print(f'res: {len(files)} files exported as {len(encode(files))} sources in {args.res}')
    else:
        bad = check(args.res)
        print('res: every source round-trips' if not bad else f'res: {bad} source(s) differ')
        return 1 if bad else 0
    return 0


if __name__ == '__main__':
    sys.exit(main())

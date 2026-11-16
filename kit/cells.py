#!/usr/bin/env python3
"""Sprite cells with a variable pitch as an image and a layout file: a res format a case's tools/res_formats.py
calls (export at install, build at build time, both for check).

A cell is an attribute and 8 pixel bytes (9 bytes; the attribute first, or last with attr='last'), or one marker
byte for an empty cell the drawer skips (R-Type's DrawSprite `$8CFD`: `$36`). So a sprite of W x H cells has no fixed
length and the bytes cannot be cut into a picture by a pitch. An object table (width, height, the first cell's
address) gives the pieces; export draws each piece at a place of its own in one PNG and writes the layout as CSV:

    NAME.png   indexed: 0 paper, 1 ink, 2 no pixel (an empty cell, the gaps between pieces); each piece's cells row
               by row at its place, a cell's pixel byte a line of 8 pixels, bit 7 left
    NAME.csv   one line a piece, in byte order:  piece,x,y,width,height,objects,attributes
               x, y: its top left cell in the PNG (in cells of 8 x 8 pixels); width, height: in cells; objects: the
               object numbers that point at it (information, the build does not read it); attributes: one a cell,
               row by row, `$47`, or `-` for an empty cell (the marker byte)
               bytes,,,,,,HEX   bytes no piece holds (before a piece, between, after the last), in hex
               a first line `# cells: empty $36, attribute first` keeps the codec's settings

The build reads only the two files: for each line, its cells (the marker for `-`, else the attribute and the 8 bytes
from the PNG) or its bytes, in order. A piece at an address another piece already holds (an object of 0 x 0 cells,
two objects of one picture) adds its number to the first's `objects`; one that starts inside another's cells is left
to it (its bytes are the other's). Without an object table each run of 16 cells is a piece.

    import cells
    files = cells.export(data, cells.pieces(objects, base))      # {'.png': bytes, '.csv': bytes}
    data = cells.build(files)                                     # the bytes again
    cells.pieces(objects, base)    # [(offset, width, height, object number)] from a table of 4-byte records
                                   # (width, height, address little-endian), the addresses less base

R-Type: the level sprites (`src/res/levels/levelN/sprites.png`, `sprites.csv`, from the level's object table) and the
game's (`src/res/graphics/sprites.png`, from GameObjects); the build is identical.
"""
import io

from PIL import Image

PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
NONE = 2


def pieces(objects, base, record=4):
    """[(offset, width, height, number)] of an object table of @p record-byte records (width, height, address)"""
    out = []
    for n, i in enumerate(range(0, len(objects) - record + 1, record)):
        w, h, address = objects[i], objects[i + 1], objects[i + 2] | objects[i + 3] << 8
        out.append((address - base, w, h, n))
    return out


def _cells(data, offset, count, empty):
    """the cells of a piece: [(start, length)] or None when it runs past the data"""
    out, o = [], offset
    for _ in range(count):
        if o >= len(data):
            return None
        n = 1 if data[o] == empty else 9
        if o + n > len(data):
            return None
        out.append((o, n))
        o += n
    return out


def _layout(data, given, empty):
    """[('piece', offset, width, height, [numbers], cells) or ('bytes', offset, length)] in byte order"""
    if given is None:  # no object table: the cells one after another, 16 a piece
        starts, o = [], 0
        while o < len(data) and _cells(data, o, 1, empty):
            starts.append(o)
            o += _cells(data, o, 1, empty)[0][1]
        given = [(starts[i], min(16, len(starts) - i), 1, None) for i in range(0, len(starts), 16)]
    by_offset = {}
    for offset, w, h, number in given:
        by_offset.setdefault(offset, []).append((w * h, w, h, number))
    rows, pos = [], 0
    for offset in sorted(by_offset):
        found = sorted(by_offset[offset], key=lambda x: -x[0])
        numbers = [x[3] for x in by_offset[offset] if x[3] is not None]
        count, w, h, _ = found[0]
        if offset < pos or offset < 0 or offset >= len(data) or not count:
            for row in reversed(rows):  # a piece inside another or of no cells: its number goes to the one before
                if row[0] == 'piece':
                    row[4].extend(numbers)
                    break
            continue
        run = _cells(data, offset, count, empty)
        if run is None:
            continue
        if offset > pos:
            rows.append(['bytes', pos, offset - pos])
        rows.append(['piece', offset, w, h, numbers, run])
        pos = run[-1][0] + run[-1][1]
    if pos < len(data):
        rows.append(['bytes', pos, len(data) - pos])
    return rows


def export(data, given=None, empty=0x36, attr='first', columns=32):
    """{'.png': ..., '.csv': ...} of @p data; @p given: pieces() of the object table, or None"""
    rows = _layout(data, given, empty)
    shapes = [r for r in rows if r[0] == 'piece']
    width = max([columns] + [r[2] + 2 for r in shapes])
    places, x, y, tall = [], 1, 1, 0
    for r in shapes:
        if x + r[2] + 1 > width:
            x, y, tall = 1, y + tall + 1, 0
        places.append((x, y))
        x += r[2] + 1
        tall = max(tall, r[3])
    height = y + tall + 1
    image = Image.new('P', (width * 8, height * 8), NONE)
    image.putpalette([c for rgb in PALETTE for c in rgb])
    px = image.load()
    lines = [f'# cells: empty ${empty:02X}, attribute {attr}', 'piece,x,y,width,height,objects,attributes']
    k = 0
    for r in rows:
        if r[0] == 'bytes':
            lines.append('bytes,,,,,,' + data[r[1]:r[1] + r[2]].hex().upper())
            continue
        _, offset, w, h, numbers, run = r
        x0, y0 = places[k]
        attrs = []
        for c, (start, n) in enumerate(run):
            if n == 1:
                attrs.append('-')
                continue
            cell = data[start:start + 9]
            a, lines8 = (cell[0], cell[1:]) if attr == 'first' else (cell[8], cell[:8])
            attrs.append(f'${a:02X}')
            cx, cy = (x0 + c % w) * 8, (y0 + c // w) * 8
            for yy in range(8):
                for xx in range(8):
                    px[cx + xx, cy + yy] = 1 if lines8[yy] & (0x80 >> xx) else 0
        lines.append(f'{k},{x0},{y0},{w},{h},{" ".join(map(str, numbers))},{" ".join(attrs)}')
        k += 1
    b = io.BytesIO()
    image.save(b, 'PNG')
    return {'.png': b.getvalue(), '.csv': ('\n'.join(lines) + '\n').encode()}


def _pixels(data, name):
    image = Image.open(io.BytesIO(data))
    if image.mode != 'P':
        rgb = image.convert('RGB')
        lookup = {c: i for i, c in enumerate(PALETTE)}
        src = rgb.load()
        out = Image.new('P', rgb.size, NONE)
        dst = out.load()
        for y in range(rgb.height):
            for x in range(rgb.width):
                if src[x, y] not in lookup:
                    raise SystemExit(f'{name}: colour {src[x, y]} at ({x}, {y}) is not in the palette {PALETTE}')
                dst[x, y] = lookup[src[x, y]]
        image = out
    return image.load()


def build(files, name='cells'):
    """the bytes of {'.png': ..., '.csv': ...}"""
    empty, attr = 0x36, 'first'
    px = _pixels(files['.png'], name + '.png')
    out = bytearray()
    for line in files['.csv'].decode().split('\n'):
        if line.startswith('# cells:'):
            words = line.replace(',', ' ').split()
            empty = int(words[words.index('empty') + 1].lstrip('$'), 16)
            attr = words[words.index('attribute') + 1]
            continue
        if not line or line.startswith('#') or line.startswith('piece,'):
            continue
        f = line.split(',')
        if f[0] == 'bytes':
            out += bytes.fromhex(f[6])
            continue
        x0, y0, w = int(f[1]), int(f[2]), int(f[3])
        for c, a in enumerate(f[6].split()):
            if a == '-':
                out.append(empty)
                continue
            cx, cy = (x0 + c % w) * 8, (y0 + c // w) * 8
            pixels = []
            for yy in range(8):
                row = [px[cx + xx, cy + yy] for xx in range(8)]
                if NONE in row:
                    raise SystemExit(f'{name}.png: piece {f[0]} cell {c}: a pixel of index {NONE} (no pixel) at '
                                     f'({cx + row.index(NONE)}, {cy + yy}) in a cell that has an attribute')
                pixels.append(sum(0x80 >> xx for xx in range(8) if row[xx] == 1))
            value = int(a.lstrip('$'), 16)
            if value == empty:
                raise SystemExit(f'{name}.csv: piece {f[0]} cell {c}: attribute ${value:02X} is the empty marker')
            out += bytes([value] + pixels) if attr == 'first' else bytes(pixels + [value])
    return bytes(out)

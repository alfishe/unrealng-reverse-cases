#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build [--out build/res]   # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file -> bytes -> the same file again
    python3 tools/res_formats.py export [--from DIR]       # .bin files (DIR, default build/res) -> src/res

| @res name | Editable file(s) | Format |
| --- | --- | --- |
| `texts/NAME.bin` | `texts/NAME.txt` | UTF-8, one string a line; the game ends each string with bit 7 set on its last character |
| `tables/NAME.bin`, `levels/levelN/objects.bin` | `.csv` | a header line of field names, one record a line (TABLES); a `tail` line holds bytes after the last whole record in hex |
| `graphics/font.bin` | `graphics/font.png` | 8 x 8 glyphs, 16 a row; palette index 0 paper, 1 ink, 2 no glyph |
| `levels/levelN/metatiles.bin` | `metatiles.png`, `metatiles-attrs.csv` | metatile n at x = 32 n (4 x 4 cells upright, index 0 paper, 1 ink); the CSV the 16 cell attributes of each metatile, row by row |
| `levels/levelN/map.bin` | `levels/levelN/map.txt` | 5 lines (the metatile rows top to bottom), one token a block column: the metatile number and its drawer, `.` as stored, `m` mirrored, `f` upside down, `b` both |
| anything else | the `.bin` itself | bytes (screens stay SCREEN$ files) |

Other tools read a resource with load('levels/level1/map.bin'): the bytes built from its editable file.
"""
import argparse
import io
import os
import struct
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
COLUMNS = 16
DRAWERS = '.mfb'
# tables: struct format of one record and the field names
TABLES = {
    'score-awards': ('<BB', ['place', 'digit']),
    'clear-list': ('<HH', ['address', 'length']),
    'defined-keys': ('<BB', ['port', 'mask']),
    'task-table': ('<HBBB', ['address', 'switch', 'counter', 'reload']),
    'game-objects': ('<BBH', ['width', 'height', 'address']),
    'objects': ('<BBH', ['width', 'height', 'address']),
}
HEXFIELDS = {'address': 4, 'port': 2, 'mask': 2, 'switch': 2}
SUFFIXES = {'text': ['.txt'], 'table': ['.csv'], 'glyphs': ['.png'], 'metatiles': ['.png', '-attrs.csv'],
            'map': ['.txt']}


def kind(name):
    base = os.path.splitext(os.path.basename(name))[0]
    if not name.endswith('.bin'):
        return None
    if name.startswith('texts/'):
        return 'text'
    if base in TABLES and (name.startswith('tables/') or name.startswith('levels/')):
        return 'table'
    if name == 'graphics/font.bin':
        return 'glyphs'
    if name.startswith('levels/') and base == 'metatiles':
        return 'metatiles'
    if name.startswith('levels/') and base == 'map':
        return 'map'
    return None


def text_export(data):
    lines, cur = [], ''
    for b in data:
        c = b & 0x7F
        if c < 0x20 or c == 0x7F:
            return None
        cur += chr(c)
        if b & 0x80:
            lines.append(cur)
            cur = ''
    if cur:
        return None
    return {'.txt': ('\n'.join(lines) + '\n').encode('utf-8')}


def text_build(files):
    out = bytearray()
    for line in files['.txt'].decode('utf-8').split('\n')[:-1]:
        b = line.encode('ascii')
        out += b[:-1] + bytes([b[-1] | 0x80])
    return bytes(out)


def table_export(data, base):
    fmt, fields = TABLES[base]
    size = struct.calcsize(fmt)
    lines = [','.join(fields)]
    n = len(data) // size
    for i in range(n):
        vals = struct.unpack_from(fmt, data, i * size)
        lines.append(','.join(('$%0*X' % (HEXFIELDS[f], v)) if f in HEXFIELDS else str(v)
                              for f, v in zip(fields, vals)))
    if len(data) > n * size:
        lines.append('tail,' + data[n * size:].hex().upper())
    return {'.csv': ('\n'.join(lines) + '\n').encode()}


def table_build(files, base):
    fmt, _fields = TABLES[base]
    out = bytearray()
    for row in files['.csv'].decode().strip('\n').split('\n')[1:]:
        cells = row.split(',')
        if cells[0] == 'tail':
            out += bytes.fromhex(cells[1])
            continue
        out += struct.pack(fmt, *[int(c[1:], 16) if c.startswith('$') else int(c) for c in cells])
    return bytes(out)


def new_indexed(size, fill):
    image = Image.new('P', size, fill)
    image.putpalette([c for rgb in PALETTE for c in rgb])
    return image


def png_bytes(image):
    b = io.BytesIO()
    image.save(b, 'PNG')
    return b.getvalue()


def png_pixels(data, name):
    image = Image.open(io.BytesIO(data))
    if image.mode != 'P':
        rgb = image.convert('RGB')
        lookup = {c: i for i, c in enumerate(PALETTE)}
        out = new_indexed(rgb.size, 0)
        src, dst = rgb.load(), out.load()
        for y in range(rgb.height):
            for x in range(rgb.width):
                if src[x, y] not in lookup:
                    sys.exit(f'{name}: colour {src[x, y]} at ({x}, {y}) is not in the palette {PALETTE}')
                dst[x, y] = lookup[src[x, y]]
        image = out
    return image.load(), image.size


def glyphs_export(data):
    count = len(data) // 8
    if count * 8 != len(data):
        return None
    rows = (count + COLUMNS - 1) // COLUMNS
    image = new_indexed((COLUMNS * 8, rows * 8), 2)
    px = image.load()
    for g in range(count):
        x0, y0 = (g % COLUMNS) * 8, (g // COLUMNS) * 8
        for y in range(8):
            for x in range(8):
                px[x0 + x, y0 + y] = 1 if data[g * 8 + y] & (0x80 >> x) else 0
    return {'.png': png_bytes(image)}


def glyphs_build(files, name):
    px, (w, h) = png_pixels(files['.png'], name)
    out = bytearray()
    for g in range((w // 8) * (h // 8)):
        x0, y0 = (g % COLUMNS) * 8, (g // COLUMNS) * 8
        if px[x0, y0] == 2:
            break
        for y in range(8):
            out.append(sum(0x80 >> x for x in range(8) if px[x0 + x, y0 + y] == 1))
    return bytes(out)


def metatiles_export(data):
    k = len(data) // 144
    if k * 144 != len(data):
        return None
    image = new_indexed((32 * k, 32), 0)
    px = image.load()
    lines = ['metatile,' + ','.join('c%d%d' % (r, c) for r in range(4) for c in range(4))]
    for t in range(k):
        attrs = []
        for r in range(4):
            for c in range(4):
                cell = data[t * 144 + r * 36 + c * 9:t * 144 + r * 36 + c * 9 + 9]
                attrs.append('$%02X' % cell[0])
                for y in range(8):
                    for x in range(8):
                        px[t * 32 + c * 8 + x, r * 8 + y] = 1 if cell[1 + y] & (0x80 >> x) else 0
        lines.append('%d,%s' % (t, ','.join(attrs)))
    return {'.png': png_bytes(image), '-attrs.csv': ('\n'.join(lines) + '\n').encode()}


def metatiles_build(files, name):
    px, _size = png_pixels(files['.png'], name)
    out = bytearray()
    for t, row in enumerate(files['-attrs.csv'].decode().strip('\n').split('\n')[1:]):
        attrs = [int(a[1:], 16) for a in row.split(',')[1:]]
        for r in range(4):
            for c in range(4):
                out.append(attrs[r * 4 + c])
                for y in range(8):
                    out.append(sum(0x80 >> x for x in range(8) if px[t * 32 + c * 8 + x, r * 8 + y] == 1))
    return bytes(out)


def map_export(data):
    cols = len(data) // 5
    if cols * 5 != len(data):
        return None
    lines = ['# %d block columns of 32 pixels; one token a column: metatile number + drawer (. stored, m mirrored, '
             'f upside down, b both)' % cols]
    for r in range(5):
        lines.append(' '.join('%2d%s' % (data[c * 5 + r] & 0x3F, DRAWERS[data[c * 5 + r] >> 6]) for c in range(cols)))
    return {'.txt': ('\n'.join(lines) + '\n').encode()}


def map_build(files):
    rows = [x.split() for x in files['.txt'].decode().split('\n') if x and not x.startswith('#')]
    out = bytearray()
    for c in range(len(rows[0])):
        for r in range(5):
            t = rows[r][c]
            out.append(int(t[:-1]) | DRAWERS.index(t[-1]) << 6)
    return bytes(out)


def export(name, data):
    """the editable files of a resource {path under src/res: bytes}, or {name: data} when it stays bytes"""
    k = kind(name)
    base = os.path.splitext(os.path.basename(name))[0]
    forms = {'text': lambda: text_export(data), 'table': lambda: table_export(data, base),
             'glyphs': lambda: glyphs_export(data), 'metatiles': lambda: metatiles_export(data),
             'map': lambda: map_export(data)}.get(k, lambda: None)()
    if not forms:
        return {name: data}
    return {name[:-4] + suf: b for suf, b in forms.items()}


def build_one(name):
    """the bytes of resource NAME (its .bin under src/res, or built from its editable files)"""
    path = os.path.join(RES, name)
    if os.path.exists(path):
        return open(path, 'rb').read()
    k = kind(name)
    files = {suf: open(path[:-4] + suf, 'rb').read() for suf in SUFFIXES[k]}
    base = os.path.splitext(os.path.basename(name))[0]
    if k == 'text':
        return text_build(files)
    if k == 'table':
        return table_build(files, base)
    if k == 'glyphs':
        return glyphs_build(files, name)
    if k == 'metatiles':
        return metatiles_build(files, name)
    return map_build(files)


load = build_one


def resources():
    """every resource under src/res, editable sources by their .bin name"""
    names = set()
    for top, _dirs, files in os.walk(RES):
        for n in files:
            if n.endswith('.md'):
                continue
            rel = os.path.relpath(os.path.join(top, n), RES)
            if rel.endswith('.bin') or rel.endswith('.scr'):
                names.add(rel)
                continue
            for k, sufs in SUFFIXES.items():
                for suf in sufs:
                    if rel.endswith(suf) and kind(rel[:-len(suf)] + '.bin') == k:
                        names.add(rel[:-len(suf)] + '.bin')
    return sorted(names)


def install(files):
    for name, data in files.items():
        forms = export(name, data)
        for rel, b in forms.items():
            path = os.path.join(RES, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(b)
        if name not in forms and os.path.exists(os.path.join(RES, name)):
            os.remove(os.path.join(RES, name))


def build(out):
    for name in resources():
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(build_one(name))


def check():
    bad = 0
    names = resources()
    for name in names:
        for rel, b in export(name, build_one(name)).items():
            src = os.path.join(RES, rel)
            same = os.path.exists(src) and open(src, 'rb').read() == b
            if not same and rel.endswith('.png') and os.path.exists(src):  # a PNG compares by its pixels
                same = Image.open(src).convert('RGB').tobytes() == Image.open(io.BytesIO(b)).convert('RGB').tobytes()
            if not same:
                print('bad: %s does not come back unchanged' % rel)
                bad += 1
    print('res: %d resources, %d bad' % (len(names), bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check', 'export'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--from', dest='src', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    if args.command == 'export':
        files = {}
        for top, _dirs, names in os.walk(args.src):
            for n in names:
                rel = os.path.relpath(os.path.join(top, n), args.src)
                files[rel] = open(os.path.join(top, n), 'rb').read()
        install(files)
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

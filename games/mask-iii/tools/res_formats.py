#!/usr/bin/env python3
"""MASK III's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (every @res names a .bin; its source is the editable file).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every source round-trips (decode, encode, decode)
    python3 tools/res_formats.py export                    # the .bin files under src/res as their sources

The formats (src/res/*/README.md):
  charsets/*.bin, screens/menu-*.bin, screens/panel.bin   PNG, 1-bit, characters row by row (8 bytes a character)
  sprites/*.bin                                           PNG, 1-bit, frames side by side, each frame's characters
                                                          stored column by column (SPRITES gives w x h)
  font/font5.bin                                          PNG, 1-bit, 5-row glyphs, 13 a row
  screens/loading.bin                                     loading.png (the 6144 pixel bytes, 1-bit) + loading-attr.csv
  charsets/*-attr.bin, screens/panel-attr.bin             CSV of hex attributes, 16 (panel 32) a row
  tables/*.bin                                            CSV with a header, hex bytes (TABLES gives the columns)
  rooms/room-NN.bin                                       text: 5 rows of 48 block numbers (hex)
  blocks/blocks.bin                                       text: a block a line, 4 rows of 4 character codes (hex)
  texts/*.bin                                             UTF-8 text (bytes_to_text)
  music/tunes.bin                                         text: the AY tunes (tools/tunes.py)
"""
import argparse
import csv
import io
import os
import re
import shutil
import sys
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

SPRITES = {  # name -> (width, height) in characters of a frame
    'control-icons': (2, 2), 'matt-run': (4, 4), 'matt-jump': (4, 4), 'matt-crouch': (4, 4), 'faller': (2, 2),
    'flyer': (3, 2), 'digits': (1, 2), 'explosion': (2, 2), 'explosion-big': (3, 2), 'mask-icons': (2, 2),
    'shots': (2, 2), 'turret': (3, 2), 'turret-shot': (1, 1), 'wave': (2, 2), 'walker': (2, 2), 'chaser': (8, 3),
    'kind16': (2, 3), 'big': (4, 3), 'guard': (4, 4), 'part1': (3, 3), 'part2': (3, 3), 'small': (2, 2),
    'boss': (4, 4), 'boss-shot': (2, 2),
}
ROW_MAJOR = {'control-icons'}  # pictures DrawGraphic $99B8 draws: characters row by row in a frame
GRIDS = {  # name -> characters a row (row by row)
    'charsets/zone0.bin': 16, 'charsets/zone1-low.bin': 16, 'charsets/zone1-high.bin': 16,
    'charsets/zone2.bin': 16, 'charsets/zone3.bin': 16,
    'screens/menu-logo.bin': 10, 'screens/menu-badge.bin': 2, 'screens/menu-banner.bin': 12, 'screens/panel.bin': 32,
}
COUNTS = {'font/font5.bin': 39}  # glyphs when the last PNG row is not full
ATTRS = {'charsets/zone0-attr.bin': 16, 'charsets/zone1-attr.bin': 16, 'charsets/zone2-attr.bin': 16,
         'charsets/zone3-attr.bin': 16, 'screens/panel-attr.bin': 32}
TABLES = {  # name -> column names (the record size)
    'tables/rooms.bin': ['left', 'right', 'pod', 'exit3', 'zone', 'arrival',
                         'enemy0', 'enemy1', 'enemy2', 'enemy3', 'enemy4', 'enemy5'],
    'tables/pickups.bin': ['room_taken', 'kind', 'x', 'y'],
    'tables/effects.bin': ['b%d' % i for i in range(10)] + ['slot', 'b11', 'b12', 'b13'],
    'tables/enemies.bin': ['score_lo', 'score_hi', 'pic_lo', 'pic_hi', 'damage', 'anim', 'mask', 'width', 'height',
                           'mode', 'hits', 'colour'],
}
# key code row*16+bit -> KEYCHARS[row*5+bit] (the game's KeyChars $A0F1; CAPS SHIFT, ENTER, SYMBOL SHIFT as ^ ~ %)
KEYCHARS = '^ZXCVASDFGQWERT1234509876POIUY~LKJH %MNB'


# ---------------------------------------------------------------------------------------------- the codecs

def bits_png(w, h, get):
    im = Image.new('1', (w, h))
    px = im.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = 1 if get(x, y) else 0
    return im


def png_bit(im):
    im = im.convert('L')
    px = im.load()
    return lambda x, y: px[x, y] >= 128


def grid_to_png(data, per_row, rows_of=8):
    n = len(data) // rows_of
    rows = (n + per_row - 1) // per_row

    def get(x, y):
        i = (y // rows_of) * per_row + x // 8
        return i < n and data[i * rows_of + y % rows_of] >> (7 - x % 8) & 1
    return bits_png(per_row * 8, rows * rows_of, get)


def png_to_grid(im, per_row, count, rows_of=8):
    bit = png_bit(im)
    out = bytearray()
    for i in range(count):
        cx, cy = (i % per_row) * 8, (i // per_row) * rows_of
        for r in range(rows_of):
            out.append(sum(bit(cx + b, cy + r) << (7 - b) for b in range(8)))
    return bytes(out)


def char_at(w, h, c, r, row_major):
    return 8 * (r * w + c if row_major else c * h + r)


def sprite_to_png(data, w, h, row_major=False):
    size = w * h * 8
    frames = len(data) // size

    def get(x, y):
        f, c, r = x // (w * 8), (x % (w * 8)) // 8, y // 8
        return data[f * size + char_at(w, h, c, r, row_major) + y % 8] >> (7 - x % 8) & 1
    return bits_png(frames * w * 8, h * 8, get)


def png_to_sprite(im, w, h, row_major=False):
    bit = png_bit(im)
    frames = im.size[0] // (w * 8)
    out = bytearray(frames * w * h * 8)
    for f in range(frames):
        for c in range(w):
            for r in range(h):
                for line in range(8):
                    x0, y = f * w * 8 + c * 8, r * 8 + line
                    out[f * w * h * 8 + char_at(w, h, c, r, row_major) + line] = sum(bit(x0 + b, y) << (7 - b) for b in range(8))
    return bytes(out)


def table_to_csv(data, cols):
    buf = io.StringIO()
    wr = csv.writer(buf, lineterminator='\n')
    wr.writerow(['index'] + cols)
    n = len(cols)
    full = len(data) // n
    for i in range(full):
        wr.writerow([i] + ['%02X' % b for b in data[i * n:(i + 1) * n]])
    if len(data) % n:
        wr.writerow(['end'] + ['%02X' % b for b in data[full * n:]])
    return buf.getvalue().encode()


def csv_to_table(text):
    rows = list(csv.reader(io.StringIO(text)))
    return bytes(int(v, 16) for row in rows[1:] for v in row[1:] if v)


def attrs_to_csv(data, per_row):
    return ''.join(','.join('%02X' % b for b in data[i:i + per_row]) + '\n'
                   for i in range(0, len(data), per_row)).encode()


def csv_to_attrs(text):
    return bytes(int(v, 16) for line in text.split('\n') if line.strip() for v in line.split(','))


def room_to_text(data):
    head = '# a room: 5 rows of 48 blocks (hex), six screens of 8 blocks side by side\n'
    return (head + ''.join(' '.join('%02X' % b for b in data[i:i + 48]) + '\n' for i in range(0, len(data), 48))).encode()


def text_to_room(text):
    return bytes(int(v, 16) for line in text.split('\n') if not line.startswith('#') for v in line.split())


def blocks_to_text(data):
    out = ['# a block a line: its 16 character codes (hex), 4 rows of 4 separated by |']
    for i in range(len(data) // 16):
        b = data[i * 16:(i + 1) * 16]
        out.append('%02X: ' % i + ' | '.join(' '.join('%02X' % v for v in b[r * 4:r * 4 + 4]) for r in range(4)))
    return ('\n'.join(out) + '\n').encode()


def text_to_blocks(text):
    return bytes(int(v, 16) for line in text.split('\n') if line and not line.startswith('#')
                 for v in line.split(':', 1)[1].replace('|', ' ').split())


def bytes_to_text(data, fixed=None):
    """a line per string: a line ends where a byte has bit 7 (the character written plain); a last line without
    one ends in '\\'; bytes that are not printable ASCII are {XX}; with fixed, a line per FIXED bytes ending in |"""
    def ch(b):
        c = chr(b & 0x7F)
        return c if 0x20 <= b & 0x7F < 0x7F and c not in '{}\\|' else '{%02X}' % (b & 0x7F)
    if fixed:
        return ''.join(''.join(ch(b) for b in data[i:i + fixed]) + '|\n' for i in range(0, len(data), fixed)).encode()
    out, line = [], ''
    for b in data:
        line += ch(b)
        if b & 0x80:
            out.append(line + '\n')
            line = ''
    if line:
        out.append(line + '\\\n')
    return ''.join(out).encode()


def text_to_bytes(text, fixed=None):
    out = bytearray()
    for line in text.split('\n')[:-1]:
        if fixed:
            line = line[:-1]
        cont = line.endswith('\\')
        if cont:
            line = line[:-1]
        bs = [int(t[1:-1], 16) if t.startswith('{') else ord(t) for t in re.findall(r'\{[0-9A-F]{2}\}|.', line)]
        if not fixed and not cont and bs:
            bs[-1] |= 0x80
        out += bytes(bs)
    return bytes(out)


def keys_to_text(data):
    out, cur = [], ''
    for b in data:
        if b == 0:
            out.append(cur + '\n')
            cur = ''
        else:
            cur += KEYCHARS[(b >> 4) * 5 + (b & 15)]
    return ('# the passwords as typed (key code = row * 16 + bit), a line each\n' + ''.join(out)).encode()


def text_to_keys(text):
    out = bytearray()
    for line in text.split('\n')[1:-1]:
        for c in line:
            i = KEYCHARS.index(c)
            out.append((i // 5) * 16 + i % 5)
        out.append(0)
    return bytes(out)


SCREEN_PNG, SCREEN_ATTR = 'screens/loading.png', 'screens/loading-attr.csv'


def screen_addr(xb, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | xb


def screen_pixels(data):
    return bits_png(256, 192, lambda x, y: data[screen_addr(x >> 3, y)] >> (7 - x % 8) & 1)


def pixels_screen(im):
    bit = png_bit(im)
    out = bytearray(6144)
    for y in range(192):
        for xb in range(32):
            out[screen_addr(xb, y)] = sum(bit(xb * 8 + b, y) << (7 - b) for b in range(8))
    return bytes(out)


# ---------------------------------------------------------------------------------------------- the sources

def kind(name):
    base = os.path.basename(name)[:-4]
    if name == 'screens/loading.bin':
        return 'screen'
    if name in GRIDS:
        return 'grid'
    if name in ATTRS:
        return 'attrs'
    if name in TABLES:
        return 'table'
    if name.startswith('sprites/') and base in SPRITES:
        return 'sprite'
    if name == 'font/font5.bin':
        return 'font'
    if re.fullmatch(r'rooms/room-\d\d\.bin', name):
        return 'room'
    if name == 'blocks/blocks.bin':
        return 'blocks'
    if name == 'texts/passwords.bin':
        return 'keys'
    if name.startswith('texts/') and name.endswith('.bin'):
        return 'text'
    if name == 'music/tunes.bin':
        return 'tunes'
    return None


SUFFIX = {'grid': '.png', 'sprite': '.png', 'font': '.png', 'attrs': '.csv', 'table': '.csv', 'room': '.txt',
          'blocks': '.txt', 'text': '.txt', 'keys': '.txt', 'screen': '.png', 'tunes': '.txt'}


def editable(name):
    k = kind(name)
    return None if k is None else name[:-4] + SUFFIX[k]


def png_bytes(im):
    buf = io.BytesIO()
    im.save(buf, 'PNG')
    return buf.getvalue()


def encode_one(name, data):
    """{source: bytes} for one .bin"""
    k = kind(name)
    src = editable(name)
    base = os.path.basename(name)[:-4]
    if k == 'grid':
        return {src: png_bytes(grid_to_png(data, GRIDS[name]))}
    if k == 'sprite':
        return {src: png_bytes(sprite_to_png(data, *SPRITES[base], base in ROW_MAJOR))}
    if k == 'font':
        return {src: png_bytes(grid_to_png(data, 13, 5))}
    if k == 'screen':
        return {SCREEN_PNG: png_bytes(screen_pixels(data)), SCREEN_ATTR: attrs_to_csv(data[6144:], 32)}
    if k == 'attrs':
        return {src: attrs_to_csv(data, ATTRS[name])}
    if k == 'table':
        return {src: table_to_csv(data, TABLES[name])}
    if k == 'room':
        return {src: room_to_text(data)}
    if k == 'blocks':
        return {src: blocks_to_text(data)}
    if k == 'keys':
        return {src: keys_to_text(data)}
    if k == 'text':
        return {src: bytes_to_text(data, 11 if base == 'masks' else None)}
    if k == 'tunes':
        import tunes
        return {src: tunes.to_text(data).encode()}
    raise KeyError(name)


def decode(source, res=RES):
    """(the .bin name, its bytes) built from one source"""
    path = os.path.join(res, source)
    name = source[:-4] + '.bin'
    if source == SCREEN_PNG:
        attrs = csv_to_attrs(open(os.path.join(res, SCREEN_ATTR)).read())
        return 'screens/loading.bin', pixels_screen(Image.open(path)) + attrs
    k = kind(name)
    base = os.path.basename(name)[:-4]
    if k in ('grid', 'sprite', 'font'):
        im = Image.open(path)
        if k == 'sprite':
            return name, png_to_sprite(im, *SPRITES[base], base in ROW_MAJOR)
        per, rows_of = (13, 5) if k == 'font' else (GRIDS[name], 8)
        return name, png_to_grid(im, per, COUNTS.get(name) or (im.size[0] // 8) * (im.size[1] // rows_of), rows_of)
    text = open(path, encoding='utf-8').read()
    if k == 'attrs':
        return name, csv_to_attrs(text)
    if k == 'table':
        return name, csv_to_table(text)
    if k == 'room':
        return name, text_to_room(text)
    if k == 'blocks':
        return name, text_to_blocks(text)
    if k == 'keys':
        return name, text_to_keys(text)
    if k == 'text':
        return name, text_to_bytes(text, 11 if base == 'masks' else None)
    if k == 'tunes':
        import tunes
        return name, tunes.from_text(text)
    raise KeyError(source)


def sources(res=RES):
    found = []
    for folder, _, names in os.walk(res):
        for n in names:
            rel = os.path.relpath(os.path.join(folder, n), res).replace(os.sep, '/')
            if rel == SCREEN_PNG or (rel != SCREEN_ATTR and editable(rel[:-4] + '.bin') == rel):
                found.append(rel)
    return sorted(found)


def build(out, res=RES):
    if os.path.exists(out):
        shutil.rmtree(out)
    srcs = set(sources(res)) | {SCREEN_ATTR}
    for folder, _, names in os.walk(res):
        for n in names:
            rel = os.path.relpath(os.path.join(folder, n), res).replace(os.sep, '/')
            if rel in srcs or n.endswith('.md') or n.endswith('-preview.png'):
                continue
            os.makedirs(os.path.dirname(os.path.join(out, rel)), exist_ok=True)
            shutil.copyfile(os.path.join(res, rel), os.path.join(out, rel))
    for source in sources(res):
        name, data = decode(source, res)
        if os.path.exists(os.path.join(res, name)):
            sys.exit(f'src/res/{name} and its source {source} both exist: delete one')
        os.makedirs(os.path.dirname(os.path.join(out, name)), exist_ok=True)
        open(os.path.join(out, name), 'wb').write(data)
    return len(sources(res))


def install(files, res=RES):
    for name, data in files.items():
        path = os.path.join(res, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if kind(name):
            for src, b in encode_one(name, data).items():
                open(os.path.join(res, src), 'wb').write(b)
            if os.path.exists(path):
                os.remove(path)
        else:
            open(path, 'wb').write(data)


def decode_mem(source, files):
    """decode a source held in memory ({source: bytes}), for check"""
    os.makedirs(os.path.join(ROOT, 'work'), exist_ok=True)
    with tempfile.TemporaryDirectory(dir=os.path.join(ROOT, 'work')) as tmp:
        for src, b in files.items():
            os.makedirs(os.path.dirname(os.path.join(tmp, src)), exist_ok=True)
            open(os.path.join(tmp, src), 'wb').write(b)
        return decode(source, tmp)[1]


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    sub.add_parser('check')
    sub.add_parser('export')
    args = p.parse_args()
    if args.cmd == 'build':
        print(f'res: {build(args.out)} sources converted into {args.out}')
    elif args.cmd == 'export':
        files = {}
        for folder, _, names in os.walk(RES):
            for n in names:
                rel = os.path.relpath(os.path.join(folder, n), RES).replace(os.sep, '/')
                if kind(rel) and rel.endswith('.bin'):
                    files[rel] = open(os.path.join(RES, rel), 'rb').read()
        install(files)
        print(f'res: {len(files)} files exported')
    else:
        bad = 0
        for source in sources():
            name, data = decode(source)
            again = encode_one(name, data)
            same = decode_mem(source, again) == data
            bad += not same
            print(f'{source}: {"round trip exact" if same else "ROUND TRIP DIFFERS"} ({len(data)} bytes)')
        print(f'res: {len(sources())} sources, {bad} bad')
        sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()

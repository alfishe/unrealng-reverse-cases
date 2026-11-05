#!/usr/bin/env python3
"""The case's editable resources and their build: the intro's three pictures as PNG, the game's graphics, levels,
texts, effects and title tune in the formats of the plugins tools/res_*.py.

    python3 tools/res_formats.py build [--out build]     src/res/screens/NAME.png -> build/screens/NAME.scr, and each
                                                         game resource src/res/X.<format> -> build/res/X.bin
    python3 tools/res_formats.py install DIR             DIR/res/X.bin (kit/mkgame.py's resources) -> src/res/X.<format>
    python3 tools/res_formats.py export SCR PNG          a 6912-byte screen to its PNG
    python3 tools/res_formats.py check                   each source built, written back, built again: the same bytes

The game's resources (the @res entries of src/game/game.ann) go through the plugins: each tools/res_*.py has KINDS, a
list of (pattern, suffix, to_editable, from_editable), the pattern an fnmatch of the resource's name ending .bin.
The plugins are the 48K case's (../zynaps/tools), copied: the bytes are the same. kit/mkgame.py calls install(files).

| Source | Built | What |
| --- | --- | --- |
| `src/res/screens/title.png` | `build/screens/title.scr` | the title (block 1 `$8710`) |
| `src/res/screens/options.png` | `build/screens/options.scr` | the options screen (block 1 `$A210`) |
| `src/res/screens/hewson.png` | `build/screens/hewson.scr` | the Hewson picture (block 1 `$BD10`) |

A picture is a 256 x 192 indexed PNG of 32 colours: index = bright x 16 + (pixel set) x 8 + the colour, so the
image is the screen as it shows and the bytes come back exactly, even in a cell whose ink equals its paper (two cells
of the title have it, with no pixel set). What a cell does not show (the ink of a cell with no set pixel, the paper of
one with every pixel set, flash) is in the PNG's text chunk zx-hidden, two characters a cell ('-' when shown; none of
the three pictures has flash). The converter is copied from ../nether-earth-gs/tools/res_media.py (the cases stay
apart).
"""
import argparse
import fnmatch
import glob
import importlib
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res', 'screens')
GAME_RES = os.path.join(ROOT, 'src', 'res')
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
SCREENS = ('title', 'options', 'hewson')


# --- the screen PNG (from advanced-nether-earth/tools/intro_screen.py) ---

PALETTE = [(0, 0, 0), (0, 0, 0xC0), (0xC0, 0, 0), (0xC0, 0, 0xC0), (0, 0xC0, 0), (0, 0xC0, 0xC0), (0xC0, 0xC0, 0),
           (0xC0, 0xC0, 0xC0)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
          (0xFF, 0xFF, 0xFF)]


def pixel_address(x, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | x


def png_write(path, width, height, rows, palette, text):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)
    raw = b''.join(b'\0' + bytes(r) for r in rows)
    out = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 3, 0, 0, 0))
    out += chunk(b'PLTE', b''.join(bytes(c) for c in palette))
    for key, value in text.items():
        out += chunk(b'tEXt', key.encode() + b'\0' + value.encode())
    out += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(out)


def png_read(path):
    data = open(path, 'rb').read()
    pos, idat, text, head = 8, b'', {}, None
    while pos < len(data):
        n, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if kind == b'IHDR':
            head = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
        elif kind == b'tEXt':
            key, _, value = body.partition(b'\0')
            text[key.decode()] = value.decode()
        pos += 12 + n
    width, height, depth, kind, _, _, interlace = head
    if depth != 8 or kind != 3 or interlace:
        from PIL import Image
        image = Image.open(path)
        if image.mode != 'P':
            sys.exit(f'{path}: not an indexed PNG')
        pixels = list(image.getdata())
        return width, height, [pixels[y * width:(y + 1) * width] for y in range(height)], text
    raw = zlib.decompress(idat)
    rows, prev, stride = [], bytes(width), width + 1
    for y in range(height):
        f, line = raw[y * stride], bytearray(raw[y * stride + 1:(y + 1) * stride])
        for i in range(width):
            a = line[i - 1] if i else 0
            b, c = prev[i], prev[i - 1] if i else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(list(line))
        prev = bytes(line)
    return width, height, rows, text


def screen_to_png(scr, path):
    """index = bright x 16 + (pixel set) x 8 + colour; what a cell does not show (the ink of a cell with no set
    pixel, the paper of one with no clear pixel, flash) goes in the text chunk zx-hidden, two characters a cell"""
    rows = [[0] * 256 for _ in range(192)]
    hidden = []
    for cell in range(768):
        cx, cy = cell % 32, cell // 32
        attr = scr[6144 + cell]
        ink, paper, bright = attr & 7, (attr >> 3) & 7, (attr >> 6) & 1
        ones = zeros = 0
        for line in range(8):
            y = cy * 8 + line
            byte = scr[pixel_address(cx, y)]
            for bit in range(8):
                on = byte >> (7 - bit) & 1
                ones += on
                zeros += 1 - on
                rows[y][cx * 8 + bit] = bright * 16 + on * 8 + (ink if on else paper)
        h = '-'
        if not ones:
            h = str(ink)
        elif not zeros:
            h = str(paper)
        hidden.append(h + ('F' if attr & 0x80 else '-'))
    palette = [c for bright in (PALETTE, BRIGHT) for c in bright + bright]
    png_write(path, 256, 192, rows, palette, {'zx-hidden': ''.join(hidden)})


def png_to_screen(path):
    width, height, rows, text = png_read(path)
    if (width, height) != (256, 192):
        sys.exit(f'{path}: {width} x {height}, not 256 x 192')
    hidden = text.get('zx-hidden', '--' * 768)
    scr = bytearray(6912)
    for cell in range(768):
        cx, cy = cell % 32, cell // 32
        ink = paper = bright = None
        for line in range(8):
            y = cy * 8 + line
            byte = 0
            for bit in range(8):
                v = rows[y][cx * 8 + bit]
                on = v >> 3 & 1
                byte = byte << 1 | on
                if on:
                    ink = v & 7
                else:
                    paper = v & 7
                bright = v >> 4 & 1
            scr[pixel_address(cx, y)] = byte
        h, f = hidden[cell * 2], hidden[cell * 2 + 1]
        if ink is None:
            ink = int(h)
        if paper is None:
            paper = int(h)
        scr[6144 + cell] = (0x80 if f == 'F' else 0) | bright << 6 | paper << 3 | ink
    return bytes(scr)



# --- the game's resources through the plugins ---

def kinds():
    out = []
    for path in sorted(glob.glob(os.path.join(HERE, 'res_*.py'))):
        name = os.path.splitext(os.path.basename(path))[0]
        if name != 'res_formats':
            out += importlib.import_module(name).KINDS
    return out


def install(files):
    """The @res entries' bytes as their editable files under src/res; each proved both ways"""
    ks = kinds()
    for name, data in files.items():
        k = next((k for k in ks if fnmatch.fnmatch(name, k[0])), None)
        path = os.path.join(GAME_RES, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if k is None:
            open(path, 'wb').write(data)
            continue
        edit = k[2](data, name)
        if k[3](edit, name) != data:
            sys.exit(f'res: {name}: the editable form does not give the bytes back')
        if os.path.exists(path):
            os.remove(path)
        open(path[:-4] + k[1], 'wb').write(edit)


def game_sources():
    """(path under src/res, the resource name it builds, its kind) of every game resource's editable file"""
    ks = kinds()
    for top, _dirs, names in os.walk(GAME_RES):
        for n in sorted(names):
            rel = os.path.relpath(os.path.join(top, n), GAME_RES)
            for k in ks:
                if rel.endswith(k[1]) and fnmatch.fnmatch(rel[:-len(k[1])] + '.bin', k[0]):
                    yield rel, rel[:-len(k[1])] + '.bin', k
                    break


def build(out):
    os.makedirs(os.path.join(out, 'screens'), exist_ok=True)
    for name in SCREENS:
        data = png_to_screen(os.path.join(RES, name + '.png'))
        open(os.path.join(out, 'screens', name + '.scr'), 'wb').write(data)
    print(f'res_formats: {len(SCREENS)} screens built in {os.path.relpath(out, ROOT)}/screens')
    n = 0
    for rel, name, k in game_sources():
        dst = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(k[3](open(os.path.join(GAME_RES, rel), 'rb').read(), name))
        n += 1
    print(f'res_formats: {n} game resources built in {os.path.relpath(out, ROOT)}/res')


def check():
    import tempfile
    bad = 0
    for name in SCREENS:
        first = png_to_screen(os.path.join(RES, name + '.png'))
        with tempfile.TemporaryDirectory() as tmp:
            again = os.path.join(tmp, name + '.png')
            screen_to_png(first, again)
            second = png_to_screen(again)
        ok = first == second
        bad += not ok
        print(f'{name}: {"round trip identical" if ok else "DIFFERS after a round trip"}')
    for rel, name, k in game_sources():
        edit = open(os.path.join(GAME_RES, rel), 'rb').read()
        ok = k[2](k[3](edit, name), name) == edit
        bad += not ok
        print(f'{rel}: {"both ways identical" if ok else "DIFFERS: bytes -> editable is not the file"}')
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='mode', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build'))
    e = sub.add_parser('export')
    e.add_argument('scr')
    e.add_argument('png')
    sub.add_parser('check')
    i = sub.add_parser('install')
    i.add_argument('dir', help='a kit/mkgame.py --out folder: its res/ files')
    a = p.parse_args()
    if a.mode == 'build':
        build(a.out)
    elif a.mode == 'export':
        data = open(a.scr, 'rb').read()
        if len(data) != 6912:
            sys.exit(f'{a.scr}: {len(data)} bytes, not 6912')
        screen_to_png(data, a.png)
    elif a.mode == 'install':
        top = os.path.join(a.dir, 'res')
        files = {}
        for d, _dirs, names in os.walk(top):
            for n in names:
                path = os.path.join(d, n)
                files[os.path.relpath(path, top)] = open(path, 'rb').read()
        install(files)
        print(f'res_formats: {len(files)} game resources installed in src/res')
    else:
        return check()
    return 0


if __name__ == '__main__':
    sys.exit(main())

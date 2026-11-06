#!/usr/bin/env python3
"""The endings' resources (src/res/endings) as editable files and back to the bytes the sources INCBIN.

    python3 tools/endings_res.py build --out DIR     every resource -> DIR/res/<name> (the INCBIN names), the tune too

kit/mkgame.py --part src/endings/*.json --install writes the editable files through install(). The kinds, told by the INCBIN name:

| INCBIN name | Editable file(s) | Format |
| --- | --- | --- |
| `pictures/NAME.lz` | `pictures/NAME.png`, `pictures/NAME.lzhints` | a ZX screen (indexed PNG, below); the build packs it with the screen LZ of LzScreen (tools/endings_lz.py), the hints file holding the original packer's decisions the rule does not make (23 and 25) |
| `pictures/NAME.hrust` | `pictures/NAME.png` | a ZX screen; the build packs it with Hrust 1 (tools/endings_hrust.py, the original stream byte for byte) |
| `pictures/NAME.scr` | `pictures/NAME.png` | a ZX screen, stored plain (6912 bytes) |
| `fonts/NAME.bin` | `fonts/NAME.png` | Final Cut's scroll font: 59 glyphs, codes $20-$5A, 16 x 16 pixels (2 bytes a row, 32 a glyph), 16 a row in the PNG, index 0 paper, 1 ink |
| `text/NAME.bin` | `text/NAME.txt` | Final Cut's scroll text, UTF-8 (ASCII): one line of the file = one 8-character row of the scroll (padded with spaces to 8; spaces at the end of a line may be dropped); the build adds the 0 that ends the text. `#` lines are comments |
| `music/nether-earth-end.bin` | `src/res/music/nether-earth-end.pt2` (aneS's) | Dead End's tune, compiled for $CA45 (tools/endings_ptmodule.py, a copy of aneS's tools/music_ptmodule.py) |

The screen PNG: 256 x 192, 32 colours (index = bright x 16 + (pixel set) x 8 + colour); what a cell does not show
(the ink of a cell without set pixels, the paper of one without clear pixels, flash) is kept in the text chunk
zx-hidden, so the PNG gives the screen back without loss.
"""
import argparse
import os
import struct
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
RES = os.path.join(CASE, 'src', 'res', 'endings')
sys.path.insert(0, HERE)
import endings_hrust  # noqa: E402
import endings_lz  # noqa: E402
import endings_ptmodule  # noqa: E402

PALETTE = [(0, 0, 0), (0, 0, 0xC0), (0xC0, 0, 0), (0xC0, 0, 0xC0), (0, 0xC0, 0), (0, 0xC0, 0xC0), (0xC0, 0xC0, 0),
           (0xC0, 0xC0, 0xC0)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
          (0xFF, 0xFF, 0xFF)]

# The tunes the endings compile: INCBIN name -> (the tune file, the address it is compiled for)
TUNES = {'music/nether-earth-end.bin': ('src/res/music/nether-earth-end.pt2', 0xCA45)}

# --- screens as indexed PNG (a copy of tools/bootmenu_res.py's, itself tools/intro_screen.py's) ---

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
    """(width, height, rows of indexes, text) of an 8-bit indexed PNG (Pillow when the file is another kind)"""
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
    """256 x 192, 32 colours: index = bright x 16 + (pixel set) x 8 + colour; what a cell does not show (the ink of
    a cell with no set pixel, the paper of one with no clear pixel, flash) in the text chunk zx-hidden"""
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
                if v > 31:
                    sys.exit(f'{path}: pixel ({cx * 8 + bit}, {y}) has index {v}, not 0-31')
                on, colour, b = v >> 3 & 1, v & 7, v >> 4
                byte |= on << (7 - bit)
                if bright is None:
                    bright = b
                elif b != bright:
                    sys.exit(f'{path}: cell ({cx}, {cy}) mixes bright and not bright')
                if on:
                    if ink not in (None, colour):
                        sys.exit(f'{path}: cell ({cx}, {cy}) has two inks')
                    ink = colour
                else:
                    if paper not in (None, colour):
                        sys.exit(f'{path}: cell ({cx}, {cy}) has two papers')
                    paper = colour
            scr[pixel_address(cx, y)] = byte
        h = hidden[cell * 2:cell * 2 + 2]
        if ink is None:
            ink = int(h[0]) if h[0] != '-' else 0
        if paper is None:
            paper = int(h[0]) if h[0] != '-' else 0
        scr[6144 + cell] = (0x80 if h[1] == 'F' else 0) | bright << 6 | paper << 3 | ink
    return bytes(scr)


# --- the scroll font ---

GLYPHS = 59  # codes $20-$5A


def font_to_png(data, path):
    if len(data) != GLYPHS * 32:
        sys.exit(f'{path}: {len(data)} bytes, not {GLYPHS} glyphs of 32')
    rows = [[0] * 256 for _ in range(64)]
    for c in range(GLYPHS):
        for y in range(16):
            for half in range(2):
                b = data[c * 32 + y * 2 + half]
                for x in range(8):
                    rows[(c // 16) * 16 + y][(c % 16) * 16 + half * 8 + x] = b >> (7 - x) & 1
    png_write(path, 256, 64, rows, [(0, 0, 0), (0xFF, 0xFF, 0xFF)], {})


def png_to_font(path):
    width, height, rows, _ = png_read(path)
    if (width, height) != (256, 64):
        sys.exit(f'{path}: {width} x {height}, not 256 x 64')
    out = bytearray()
    for c in range(GLYPHS):
        for y in range(16):
            for half in range(2):
                v = 0
                for x in range(8):
                    p = rows[(c // 16) * 16 + y][(c % 16) * 16 + half * 8 + x]
                    if p > 1:
                        sys.exit(f'{path}: index {p}, not 0 or 1')
                    v |= p << (7 - x)
                out.append(v)
    return bytes(out)


# --- the scroll text ---

ROW = 8


def text_to_txt(data, path):
    if not data or data[-1] != 0 or (len(data) - 1) % ROW:
        sys.exit(f'{path}: not rows of {ROW} characters ending in 0')
    out = ['# Final Cut\'s scroll text: one line = one row of 8 characters (16 x 16 glyphs, $20-$5A: space, ! " \' ( ) * + , - . /,',
           '# digits, : ; < = > ?, @ and A-Z), scrolled up 16 pixel lines a row; the build pads each line to 8 and adds the 0',
           '# that ends the text.']
    for i in range(0, len(data) - 1, ROW):
        row = data[i:i + ROW]
        if any(not 0x20 <= c <= 0x5A for c in row):
            sys.exit(f'{path}: row {i // ROW}: a code outside $20-$5A')
        out.append(row.decode('ascii').rstrip())
    return '\n'.join(out) + '\n'


def txt_to_text(text, path):
    out = bytearray()
    for number, line in enumerate(text.split('\n')[:-1] if text.endswith('\n') else text.split('\n'), 1):
        if line.startswith('#'):
            continue
        if len(line) > ROW:
            sys.exit(f'{path}:{number}: {len(line)} characters, a row holds {ROW}')
        if any(not 0x20 <= ord(c) <= 0x5A for c in line):
            sys.exit(f'{path}:{number}: a character outside $20-$5A (capitals, digits, signs)')
        out += line.ljust(ROW).encode('ascii')
    return bytes(out) + b'\0'


# --- the kinds ---

def editable(name):
    stem, ext = os.path.splitext(name)
    if name.startswith(('pictures/', 'fonts/')):
        return stem + '.png'
    if name.startswith('text/'):
        return stem + '.txt'
    return name


def unpack_screen(name, data):
    ext = os.path.splitext(name)[1]
    if ext == '.lz':
        scr, end, tokens = endings_lz.unpack(data)
    elif ext == '.hrust':
        scr, end = endings_hrust.unpack(data)
    elif ext == '.scr':
        scr, end, tokens = data, len(data), None
    else:
        sys.exit(f'{name}: no picture kind')
    if end != len(data) or len(scr) != 6912:
        sys.exit(f'{name}: not one stream of a screen')
    return scr, (tokens if ext == '.lz' else None)


def decode(name, data, res=RES):
    """the INCBIN name's bytes written as their editable file(s)"""
    path = os.path.join(res, editable(name))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if name.startswith('pictures/'):
        scr, tokens = unpack_screen(name, data)
        screen_to_png(scr, path)
        if tokens is not None:
            hints = endings_lz.find_hints(scr, tokens)
            with open(os.path.splitext(path)[0] + '.lzhints', 'w') as f:
                f.write('# The original packer\'s decisions the rule of tools/endings_lz.py does not make, for %s:\n'
                        '# index (in the depacker\'s byte order) kind (m match, r run, l literals) length [distance]\n'
                        % os.path.basename(path))
                for index, kind, n, dist in hints:
                    f.write(' '.join(str(v) for v in (index, kind, n) + ((dist,) if dist is not None else ())) + '\n')
    elif name.startswith('fonts/'):
        font_to_png(data, path)
    elif name.startswith('text/'):
        open(path, 'w', encoding='utf-8').write(text_to_txt(data, path))
    else:
        sys.exit(f'{name}: no resource kind')
    if encode(name, res) != data:
        sys.exit(f'{name}: {editable(name)} does not give the bytes back')


def encode(name, res=RES):
    """the INCBIN name's bytes from its editable file(s)"""
    path = os.path.join(res, editable(name))
    ext = os.path.splitext(name)[1]
    if name.startswith('pictures/'):
        scr = png_to_screen(path)
        if ext == '.lz':
            hints = os.path.splitext(path)[0] + '.lzhints'
            return endings_lz.pack(scr, endings_lz.read_hints(hints) if os.path.exists(hints) else None)
        if ext == '.hrust':
            return endings_hrust.pack(scr)
        return scr
    if name.startswith('fonts/'):
        return png_to_font(path)
    if name.startswith('text/'):
        return txt_to_text(open(path, encoding='utf-8').read(), path)
    sys.exit(f'{name}: no resource kind')


# The INCBIN names, and the picture kind of each PNG (the PNG alone does not say how it is packed)
NAMES = ['pictures/dead-end.lz', 'pictures/game-over.hrust', 'pictures/game-menu.lz',
         'pictures/alien-magenta.scr', 'pictures/alien-green.scr', 'pictures/caption.scr', 'pictures/victory.scr',
         'fonts/scroll.bin', 'text/scroll.bin']


def install(files, res=RES):
    for name, data in sorted(files.items()):
        if name not in NAMES:
            sys.exit(f'{name}: not in endings_res.NAMES')
        decode(name, data, res)


def build_tunes(out):
    for name, (tune, addr) in TUNES.items():
        path = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        data = open(os.path.join(CASE, tune), 'rb').read()
        open(path, 'wb').write(endings_ptmodule.build(data, addr, endings_ptmodule.fmt_of(tune)))


def build(out, res=RES):
    for name in NAMES:
        path = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(encode(name, res))
    build_tunes(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('mode', choices=['build'])
    p.add_argument('--out', required=True)
    args = p.parse_args()
    build(args.out)
    print(f'endings_res: {len(NAMES)} resources and {len(TUNES)} tune into {args.out}/res')
    return 0


if __name__ == '__main__':
    sys.exit(main())

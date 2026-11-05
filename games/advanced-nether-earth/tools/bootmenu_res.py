#!/usr/bin/env python3
"""The boot program's resources (src/res/bootmenu) as editable files and back to the bytes the source INCBINs.

    python3 tools/bootmenu_res.py build --out DIR     every editable file -> DIR/res/<name> (the INCBIN names)
    python3 tools/bootmenu_res.py check               every editable file encoded into a temporary folder
                                                      (tools/build_bootmenu.sh compares the assembled image)

Four kinds, told by the INCBIN name (tools/bootmenu_mkasm.py --install writes them through install()):

| INCBIN name | Editable file | Format |
| --- | --- | --- |
| `pictures/NAME.hrust` | `pictures/NAME.png` | a ZX screen as an indexed PNG without loss (screen_to_png below); the build packs it with Hrust 1 (tools/bootmenu_hrust.py, the original streams byte for byte) |
| `fonts/NAME.bin` | `fonts/NAME.png` | 96 glyphs ($20-$7F), 16 a row, each 4 x 8 pixels (white on black); a glyph byte holds its 4 pixels in both nibbles (the printer masks the half it draws) |
| `text/NAME.bin` | `text/NAME.txt` | the 0-terminated strings, UTF-8 (below) |
| `sprites/NAME.bin` | `sprites/NAME.png` | a masked 8-pixel sprite, a line a row (mask byte, image byte): index = mask bit * 2 + image bit; 0 ink off (black), 1 ink on (white), 2 the screen shows through (grey), 3 the screen's pixel set (cyan: AND 1, OR 1) |

The text files: `#` lines are comments; `@wrap N` (first) is the width the printer wraps at (33 cells for the help
pages: columns 30-62 of 64; 0 for the menu lines, which never wrap); `== Name` opens a string (the name only
labels it). A string is its lines joined; every line but the last is padded with spaces to the wrap width; the last
ends with `¶`, the 0 that ends the string (spaces before it are kept). `‹lat›` and `‹rus›` are the codes 1 and 2
that switch the printer to the Latin and the Cyrillic font; the characters are the glyphs of the font in force:

- Latin font: ASCII, but `$5E` is `↑`, `$60` `£`, `$7F` `©` (the Spectrum's set).
- Cyrillic font (the authors' KOI-7-like layout: Latin letters for the Cyrillic ones that sound alike): `a-z` ->
  `абцдефгхийклмнопярстужвьыз`, `A-Z` -> the capitals, `@` ю, `[` ш, `\\` Ъ, `]` щ, `^` ч, `_` ъ, `` ` `` Ю,
  `{` Ш, `|` Э, `}` Щ, `~` Ч, `<` э, `$7F` `¤`; digits and other signs as they are.

The screen PNG code is a copy of tools/intro_screen.py's (aneI's), kept here so the parts build apart.
"""
import argparse
import os
import struct
import sys
import tempfile
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
RES = os.path.join(CASE, 'src', 'res', 'bootmenu')
sys.path.insert(0, HERE)
import bootmenu_hrust  # noqa: E402

PALETTE = [(0, 0, 0), (0, 0, 0xC0), (0xC0, 0, 0), (0xC0, 0, 0xC0), (0, 0xC0, 0), (0, 0xC0, 0xC0), (0xC0, 0xC0, 0),
           (0xC0, 0xC0, 0xC0)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
          (0xFF, 0xFF, 0xFF)]

# --- the text ---

LATIN = {c: chr(c) for c in range(0x20, 0x7F)}
LATIN.update({0x5E: '↑', 0x60: '£', 0x7F: '©'})
CYRILLIC = {c: chr(c) for c in range(0x20, 0x40)}
CYRILLIC[0x3C] = 'э'
CYRILLIC.update(zip(range(0x41, 0x5B), 'АБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗ'))
CYRILLIC.update(zip(range(0x61, 0x7B), 'абцдефгхийклмнопярстужвьыз'))
CYRILLIC.update({0x40: 'ю', 0x5B: 'ш', 0x5C: 'Ъ', 0x5D: 'щ', 0x5E: 'ч', 0x5F: 'ъ', 0x60: 'Ю', 0x7B: 'Ш', 0x7C: 'Э',
                 0x7D: 'Щ', 0x7E: 'Ч', 0x7F: '¤'})
FONTS = {1: LATIN, 2: CYRILLIC}
MARK = {1: '‹lat›', 2: '‹rus›'}
END = '¶'
assert len(set(LATIN.values())) == 96 and len(set(CYRILLIC.values())) == 96


def text_to_txt(data, title, wrap):
    """the strings' bytes as the text file"""
    out = ['# ' + title, '# tools/bootmenu_res.py: the format; the build turns it back into the bytes', '@wrap %d' % wrap]
    strings = data.split(b'\0')
    if strings[-1] != b'':
        sys.exit(f'{title}: the bytes do not end with a string\'s 0')
    font = 1
    for k, s in enumerate(strings[:-1]):
        out.append('== %d' % (k + 1))
        lines, line, cells = [], '', 0
        for b in s:
            if b in MARK:
                font = b
                line += MARK[b]
                continue
            if wrap and cells == wrap:
                lines.append(line)
                line, cells = '', 0
            if b not in FONTS[font]:
                sys.exit(f'{title}: byte ${b:02X} in string {k + 1}')
            line += FONTS[font][b]
            cells += 1
        lines.append(line)
        out += [l.rstrip(' ') for l in lines[:-1]] + [lines[-1] + END]
    return '\n'.join(out) + '\n'


def txt_to_text(text, name):
    """the text file back to the bytes"""
    reverse = {f: {v: k for k, v in t.items()} for f, t in FONTS.items()}
    wrap, strings, current = None, [], None
    for number, line in enumerate(text.split('\n'), 1):
        if line.startswith('#') or (current is None and not line):
            continue
        if line.startswith('@wrap'):
            wrap = int(line.split()[1])
            continue
        if line.startswith('== '):
            current = []
            strings.append(current)
            continue
        if current is None:
            sys.exit(f'{name}:{number}: text before any "== " line')
        current.append((number, line))
    if wrap is None:
        sys.exit(f'{name}: no @wrap line')
    out = bytearray()
    font = 1
    for lines in strings:
        while lines and not lines[-1][1]:
            lines.pop()
        if not lines or not lines[-1][1].endswith(END):
            sys.exit(f'{name}: a string that does not end with {END}')
        for k, (number, line) in enumerate(lines):
            last = k == len(lines) - 1
            if last:
                line = line[:-1]
            cells = 0
            i = 0
            while i < len(line):
                hit = next((b for b, m in MARK.items() if line.startswith(m, i)), None)
                if hit:
                    font = hit
                    out.append(hit)
                    i += len(MARK[hit])
                    continue
                ch = line[i]
                if ch not in reverse[font]:
                    sys.exit(f'{name}:{number}: {ch!r} is no glyph of the {"Latin" if font == 1 else "Cyrillic"} font')
                out.append(reverse[font][ch])
                cells += 1
                i += 1
            if wrap and cells > wrap:
                sys.exit(f'{name}:{number}: {cells} cells, the line holds {wrap}')
            if not last and wrap:
                out += b' ' * (wrap - cells)
        out.append(0)
    return bytes(out)


# --- the fonts ---

def font_to_png(data, path):
    if len(data) != 96 * 8:
        sys.exit(f'{path}: {len(data)} bytes, not 96 glyphs')
    rows = [[0] * 64 for _ in range(48)]
    for c in range(96):
        for r in range(8):
            b = data[c * 8 + r]
            if b >> 4 != b & 15:
                sys.exit(f'{path}: glyph ${c + 0x20:02X} row {r}: the two nibbles differ')
            for x in range(4):
                rows[(c // 16) * 8 + r][(c % 16) * 4 + x] = b >> (7 - x) & 1
    png_write(path, 64, 48, rows, [(0, 0, 0), (0xFF, 0xFF, 0xFF)], {})


def png_to_font(path):
    width, height, rows, _ = png_read(path)
    if (width, height) != (64, 48):
        sys.exit(f'{path}: {width} x {height}, not 64 x 48')
    out = bytearray()
    for c in range(96):
        for r in range(8):
            v = 0
            for x in range(4):
                p = rows[(c // 16) * 8 + r][(c % 16) * 4 + x]
                if p > 1:
                    sys.exit(f'{path}: index {p}, not 0 or 1')
                v |= p << (3 - x)
            out.append(v << 4 | v)
    return bytes(out)


# --- the masked sprites ---

SPRITE_PALETTE = [(0, 0, 0), (0xFF, 0xFF, 0xFF), (0x80, 0x80, 0x80), (0x00, 0xC0, 0xC0)]


def sprite_to_png(data, path):
    if len(data) % 2:
        sys.exit(f'{path}: {len(data)} bytes, not mask and image pairs')
    rows = [[(data[k] >> (7 - x) & 1) * 2 + (data[k + 1] >> (7 - x) & 1) for x in range(8)]
            for k in range(0, len(data), 2)]
    png_write(path, 8, len(rows), rows, SPRITE_PALETTE, {})


def png_to_sprite(path):
    width, height, rows, _ = png_read(path)
    if width != 8:
        sys.exit(f'{path}: {width} pixels wide, not 8')
    out = bytearray()
    for row in rows:
        mask = image = 0
        for x, p in enumerate(row):
            if p > 3:
                sys.exit(f'{path}: index {p}, not 0-3')
            mask |= (p >> 1) << (7 - x)
            image |= (p & 1) << (7 - x)
        out += bytes((mask, image))
    return bytes(out)


# --- screens as indexed PNG (a copy of tools/intro_screen.py's) ---

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


# --- the kinds ---

TEXT_WRAP = {'text/menu.bin': 0}
TITLES = {
    'text/menu.bin': 'the help menu: its seven items and the copyright line (HelpMenu)',
    'text/credits.bin': 'help item 6, "CREDITZ": 3 pages',
    'text/description.bin': 'help item 1, "Описание игры": 5 pages',
    'text/production.bin': 'help item 2, "Производство роботов": 4 pages',
    'text/components.bin': 'help item 3, "Характеристика компонентов": 8 pages',
    'text/programming.bin': 'help item 4, "Программирование роботов": 3 pages',
    'text/features.bin': 'help item 5, "Особенности игры": 5 pages',
}


def editable(name):
    """the file under src/res/bootmenu that holds the INCBIN name's bytes"""
    stem, ext = os.path.splitext(name)
    if name.startswith('pictures/') and ext == '.hrust':
        return stem + '.png'
    if name.startswith('fonts/') or name.startswith('sprites/'):
        return stem + '.png'
    if name.startswith('text/'):
        return stem + '.txt'
    return name


def decode(name, data, res=RES):
    """the INCBIN name's bytes written as their editable file"""
    path = os.path.join(res, editable(name))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if name.startswith('pictures/'):
        scr, end = bootmenu_hrust.unpack(data)
        if end != len(data) or len(scr) != 6912:
            sys.exit(f'{name}: not one Hrust stream of a screen')
        if bootmenu_hrust.pack(scr) != data:
            sys.exit(f'{name}: the packer does not give the stream back')
        screen_to_png(scr, path)
    elif name.startswith('fonts/'):
        font_to_png(data, path)
    elif name.startswith('sprites/'):
        sprite_to_png(data, path)
    elif name.startswith('text/'):
        open(path, 'w').write(text_to_txt(data, TITLES.get(name, name), TEXT_WRAP.get(name, 33)))
    else:
        open(path, 'wb').write(data)
    if encode(name, res) != data:
        sys.exit(f'{name}: {editable(name)} does not give the bytes back')


def encode(name, res=RES):
    """the INCBIN name's bytes from its editable file"""
    path = os.path.join(res, editable(name))
    if name.startswith('pictures/'):
        return bootmenu_hrust.pack(png_to_screen(path))
    if name.startswith('fonts/'):
        return png_to_font(path)
    if name.startswith('sprites/'):
        return png_to_sprite(path)
    if name.startswith('text/'):
        return txt_to_text(open(path, encoding='utf-8').read(), path)
    return open(path, 'rb').read()


def names(res=RES):
    """the INCBIN names of every editable file in res"""
    out = []
    for folder, _, files in os.walk(res):
        for f in sorted(files):
            rel = os.path.relpath(os.path.join(folder, f), res)
            stem, ext = os.path.splitext(rel)
            if rel.startswith('pictures/') and ext == '.png':
                out.append(stem + '.hrust')
            elif (rel.startswith('fonts/') or rel.startswith('sprites/')) and ext == '.png':
                out.append(stem + '.bin')
            elif rel.startswith('text/') and ext == '.txt':
                out.append(stem + '.bin')
    return sorted(out)


def install(files, res=RES):
    for name, data in sorted(files.items()):
        decode(name, data, res)


def build(out, res=RES):
    for name in names(res):
        path = os.path.join(out, 'res', name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(encode(name, res))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('mode', choices=['build', 'check'])
    p.add_argument('--out')
    args = p.parse_args()
    if args.mode == 'build':
        build(args.out)
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        build(tmp)
        print('%d resources built' % len(names()))
    return 0


if __name__ == '__main__':
    sys.exit(main())

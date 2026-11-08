#!/usr/bin/env python3
"""Editable sources for the resources of src/res (src/res/README.md). kit/mkgame.py --install calls install(files)
with the bytes of each @res entry; tools/build.sh turns the sources back into the bytes the source INCBINs, and its
byte-exact check against orig/Elite.tzx.zip keeps them honest.

| Source | Bytes | Format |
| --- | --- | --- |
| `fonts/font.png` | `fonts/font.bin` | the 91 glyphs of the codes `$20-$7A`, 16 a row; index 0 paper, 1 ink, 2 no glyph |
| `dashboard/compass.png` | `dashboard/compass.bin` | the front dot, the behind dot (4 lines of 16 pixels) and the dial (24 x 24), one under the other |
| `text/tokens.txt` | `text/tokens.bin` | one line a string: `std N:` or `other N:`, the bytes as text with `{xx}` for the codes (docs/08-hud-and-text.md) |
| `ships/ships.txt` | `ships/ships.bin` | each blueprint part by name: the header bytes, then one line a vertex, an edge or a face, its fields decoded (docs/07-objects.md) |

`screens/loading.scr` and `tape/master-memory.bin` stay bytes (a SCREEN$ and 1096 bytes of a machine's memory).

    python3 tools/res_formats.py build [--out build/res]      # every file of src/res, the sources converted
    python3 tools/res_formats.py export [--from DIR]          # .bin files (src/res or DIR) to sources in src/res
    python3 tools/res_formats.py check                        # export + build in memory give the same bytes
"""
import argparse
import io
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
ANN = os.path.join(ROOT, 'src', 'game', 'game.ann')
PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
STD_BYTES = 0xF4F5 - 0xF11E  # tokens.bin: the standard strings, then the other strings


# ---------------------------------------------------------------------------------------------------------- PNG


def png_bytes(image):
    out = io.BytesIO()
    image.save(out, 'PNG')
    return out.getvalue()


def indexed(data):
    rgb = Image.open(io.BytesIO(data)).convert('RGB')
    px = rgb.load()
    w, h = rgb.size
    look = {c: i for i, c in enumerate(PALETTE)}
    out = []
    for y in range(h):
        row = []
        for x in range(w):
            if px[x, y] not in look:
                sys.exit('res: pixel (%d, %d) is no palette colour' % (x, y))
            row.append(look[px[x, y]])
        out.append(row)
    return out, w, h


def new_image(w, h):
    image = Image.new('P', (w, h), 2)
    image.putpalette([c for rgb in PALETTE for c in rgb])
    return image


def bits_to(image, x0, y0, rows):
    """rows of bytes, a byte 8 pixels left to right"""
    px = image.load()
    for y, row in enumerate(rows):
        for i, b in enumerate(row):
            for k in range(8):
                px[x0 + 8 * i + k, y0 + y] = (b >> (7 - k)) & 1


def bits_from(pix, x0, y0, width, height):
    out = bytearray()
    for y in range(height):
        for i in range(width):
            b = 0
            for k in range(8):
                b = b << 1 | (pix[y0 + y][x0 + 8 * i + k] & 1)
            out.append(b)
    return bytes(out)


def font_export(data):
    n = len(data) // 8
    image = new_image(16 * 8, (n + 15) // 16 * 8)
    for g in range(n):
        bits_to(image, g % 16 * 8, g // 16 * 8, [data[8 * g + y:8 * g + y + 1] for y in range(8)])
    return png_bytes(image)


def font_build(png):
    pix, _w, _h = indexed(png)
    return b''.join(bits_from(pix, g % 16 * 8, g // 16 * 8, 1, 8) for g in range(91))


COMPASS = [(0, 2, 4), (8, 2, 4), (16, 3, 24)]  # (offset, bytes a line, lines): front dot, behind dot, dial


def compass_export(data):
    image = new_image(24, 4 + 1 + 4 + 1 + 24)
    y = 0
    for off, width, lines in COMPASS:
        bits_to(image, 0, y, [data[off + width * k:off + width * (k + 1)] for k in range(lines)])
        y += lines + 1
    return png_bytes(image)


def compass_build(png):
    pix, _w, _h = indexed(png)
    out, y = [], 0
    for _off, width, lines in COMPASS:
        out.append(bits_from(pix, 0, y, width, lines))
        y += lines + 1
    return b''.join(out)


# --------------------------------------------------------------------------------------------------------- text


def text_line(raw):
    return ''.join(chr(b) if 0x20 <= b <= 0x7E and chr(b) not in '{}' else '{%02X}' % b for b in raw)


def text_bytes(line):
    return bytes(int(m.group(1), 16) if m.group(1) else ord(m.group(2))
                 for m in re.finditer(r'\{([0-9A-F]{2})\}|(.)', line))


def tokens_export(data):
    lines = ['# The two token tables of $F11E-$FBFF (TokenTable, OtherTable). One string a line, its ending zero left',
             '# out; {xx} is a byte that is no plain character (a control, a token or a pair code). Decoded text:',
             '# python3 tools/tokens.py (docs/08-hud-and-text.md). The standard strings are numbered from 0, the other',
             '# strings from 1 (PrintOther skips n - 1). "tail" is what follows the last string.']
    for name, part, first in (('std', data[:STD_BYTES], 0), ('other', data[STD_BYTES:], 1)):
        strings = part.split(b'\x00')
        tail = strings.pop()
        for i, s in enumerate(strings):
            lines.append('%s %d: %s' % (name, first + i, text_line(s)))
        lines.append('%s tail: %s' % (name, text_line(tail)))
    return ('\n'.join(lines) + '\n').encode()


def tokens_build(txt):
    parts = {'std': [], 'other': []}
    tails = {}
    for line in txt.decode().split('\n'):
        m = re.match(r'^(std|other) (\d+|tail): (.*)$', line)
        if not m:
            continue
        if m.group(2) == 'tail':
            tails[m.group(1)] = text_bytes(m.group(3))
        else:
            parts[m.group(1)].append(text_bytes(m.group(3)))
    return b''.join(b''.join(s + b'\x00' for s in parts[k]) + tails[k] for k in ('std', 'other'))


def ship_entries():
    """(address, name, kind) of the ships.bin entries in game.ann, in order"""
    out = []
    for line in open(ANN):
        m = re.match(r'^\$([0-9A-F]{4}) [bs] (Ship\w+)', line)
        if m and 0x61CC <= int(m.group(1), 16) < 0x6FA3:
            n = m.group(2)
            kind = next((k for k in ('Vertices', 'Edges', 'Faces') if n.endswith(k)), 'Header')
            out.append((int(m.group(1), 16), n, kind))
    return out


def ships_export(data):
    entries = ship_entries()
    base = entries[0][0]
    lines = ['# The ship blueprints of $61CC-$6FA2 (docs/07-objects.md), in memory order. A part starts with "[Name',
             '# kind]". header: the 23 bytes in hex. vertices: x y z (magnitudes), the signs of x y z (+ or -), the',
             '# visibility distance (0-31), the four faces. edges: the visibility distance (byte), the two vertices',
             '# (their numbers), the two faces. faces: the signs of the normal, the visibility (0-31), x y z.']
    for k, (a, name, kind) in enumerate(entries):
        end = entries[k + 1][0] if k + 1 < len(entries) else base + len(data)
        part = data[a - base:end - base]
        lines.append('[%s %s]' % (name, kind.lower()))
        if kind == 'Header':
            lines.append(' '.join('%02X' % b for b in part))
            continue
        size = 6 if kind == 'Vertices' else 4
        for i in range(0, len(part), size):
            r = part[i:i + size]
            if len(r) < size:
                lines.append('bytes ' + ' '.join('%02X' % b for b in r))
            elif kind == 'Vertices':
                signs = ''.join('-' if r[3] >> (7 - j) & 1 else '+' for j in range(3))
                lines.append('%3d %3d %3d %s %2d  %2d %2d %2d %2d' % (r[0], r[1], r[2], signs, r[3] & 31,
                                                                    r[4] & 15, r[4] >> 4, r[5] & 15, r[5] >> 4))
            elif kind == 'Edges':
                lines.append('%3d  %2d %2d  %2d %2d' % (r[0], r[1], r[2], r[3] & 15, r[3] >> 4))
            else:  # x, y, z magnitudes, then the signs (bits 7-5) and the visibility
                signs = ''.join('-' if r[3] >> (7 - j) & 1 else '+' for j in range(3))
                lines.append('%s %2d  %3d %3d %3d' % (signs, r[3] & 31, r[0], r[1], r[2]))
    return ('\n'.join(lines) + '\n').encode()


def ships_build(txt):
    out = bytearray()
    kind = None
    for line in txt.decode().split('\n'):
        if not line or line.startswith('#'):
            continue
        m = re.match(r'^\[\w+ (\w+)\]$', line)
        if m:
            kind = m.group(1)
            continue
        f = line.split()
        if kind == 'header' or f[0] == 'bytes':
            out += bytes(int(x, 16) for x in f[(1 if f[0] == 'bytes' else 0):])
        elif kind == 'vertices':
            s = sum(128 >> j for j in range(3) if f[3][j] == '-')
            out += bytes([int(f[0]), int(f[1]), int(f[2]), s | int(f[4]), int(f[5]) | int(f[6]) << 4,
                          int(f[7]) | int(f[8]) << 4])
        elif kind == 'edges':
            out += bytes([int(f[0]), int(f[1]), int(f[2]), int(f[3]) | int(f[4]) << 4])
        else:
            s = sum(128 >> j for j in range(3) if f[0][j] == '-')
            out += bytes([int(f[2]), int(f[3]), int(f[4]), s | int(f[1])])
    return bytes(out)


# bin name -> (source, to_editable(bytes) -> data, from_editable(data) -> bytes)
FORMATS = {
    'fonts/font.bin': ('fonts/font.png', font_export, font_build),
    'dashboard/compass.bin': ('dashboard/compass.png', compass_export, compass_build),
    'text/tokens.bin': ('text/tokens.txt', tokens_export, tokens_build),
    'ships/ships.bin': ('ships/ships.txt', ships_export, ships_build),
}


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def install(files):
    for name, data in files.items():
        if name in FORMATS:
            source, export, build_ = FORMATS[name]
            text = export(data)
            if build_(text) != data:
                sys.exit('res: %s does not round-trip through %s' % (name, source))
            write(os.path.join(RES, source), text)
            stale = os.path.join(RES, name)
            if os.path.exists(stale):
                os.remove(stale)
        else:
            write(os.path.join(RES, name), data)


def sources():
    """{bin name: bytes} of every resource, the sources converted"""
    out = {}
    by_source = {s: (n, b) for n, (s, _e, b) in FORMATS.items()}
    for top, _dirs, names in os.walk(RES):
        for n in names:
            if n == 'README.md':
                continue
            rel = os.path.relpath(os.path.join(top, n), RES)
            data = open(os.path.join(top, n), 'rb').read()
            if rel in by_source:
                name, build_ = by_source[rel]
                out[name] = build_(data)
            else:
                out[rel] = data
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'export', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--from', dest='src', default=RES)
    args = p.parse_args()
    if args.command == 'build':
        for name, data in sources().items():
            write(os.path.join(args.out, name), data)
    elif args.command == 'export':
        files = {}
        for name in FORMATS:
            path = os.path.join(args.src, name)
            if os.path.exists(path):
                files[name] = open(path, 'rb').read()
        install(files)
    else:
        built = sources()
        for name, data in built.items():
            if name in FORMATS and FORMATS[name][2](FORMATS[name][1](data)) != data:
                print('res: %s does not round-trip' % name)
                return 1
        print('res: %d files, %d from editable sources, every one round-trips' %
              (len(built), sum(1 for n in built if n in FORMATS)))
    return 0


if __name__ == '__main__':
    sys.exit(main())

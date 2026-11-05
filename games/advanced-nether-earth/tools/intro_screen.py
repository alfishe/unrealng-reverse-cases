#!/usr/bin/env python3
"""ZX screens (6912 bytes) as editable PNG, both ways, without loss; the screen LZ of the intro's logo and the title
picture (the packer and the depacker of src/intro: LogoDepack $66C1, TitleDepack $9C40).

    python3 tools/intro_screen.py to-png SCREEN.bin OUT.png
    python3 tools/intro_screen.py to-scr IN.png OUT.bin
    python3 tools/intro_screen.py unpack STREAM.bin OFFSET OUT.bin [PARSE.txt]   the stream at OFFSET to a screen
    python3 tools/intro_screen.py pack SCREEN.bin OUT.bin [PARSE.txt]

The PNG: 256 x 192, indexed, 32 colours: index = bright x 16 + (pixel set) x 8 + colour, the palette the
Spectrum's (an ink and a paper index of one colour look the same). Each pixel's index gives its bit and the cell's
ink (set pixels) or paper (clear pixels) with its bright. What a cell does not show (the ink of a cell with no set
pixel, the paper of one with no clear pixel, the flash bit) is in the PNG's text chunk `zx-hidden`: 768 pairs of
characters, one a cell in screen order, the hidden colour (0-7, `-` when both are seen) and `F` for flash (`-` not).
An editor that keeps the indexes (any palette-aware one) keeps the screen; a new pixel must take the cell's ink or
paper index.

The screen LZ (the depacker's order: per third, column by column, each column the 8 character rows of 8 lines, top
line first, then the 768 attributes in order): a token byte b, bit 7 clear: a copy of ((b >> 3) & 15) + 3 bytes
from (b & 7) x 256 + the next byte back; bit 7 set: b & $7F = 0 the end, bit 6 clear: b & $3F literal bytes follow,
bit 6 set: the next byte (b & $3F) + 3 times. The authors' packer copies never overlap their source, take the
farthest of the longest, and choose between a copy and a run by a rule this script has not found (it agrees with a
greedy rule on all but about 6 % of the tokens): PARSE.txt keeps the authors' choices, one token a line (`lit N`,
`run N`, `copy N OFFSET`), and `pack` follows it while the screen allows it (the same bytes give the same
stream), the greedy rule after the first token the screen no longer allows.
"""
import struct
import sys
import zlib

PALETTE = [(0, 0, 0), (0, 0, 0xC0), (0xC0, 0, 0), (0xC0, 0, 0xC0), (0, 0xC0, 0), (0, 0xC0, 0xC0), (0xC0, 0xC0, 0),
           (0xC0, 0xC0, 0xC0)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
          (0xFF, 0xFF, 0xFF)]


def pixel_address(x, y):
    """the offset of pixel line y, byte column x in the 6144 pixel bytes"""
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | x


# --- PNG (indexed, 8 bits) without a library ---

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


# --- the screen LZ ---

def lz_order():
    """the screen offsets in the depacker's order (PutByte's walk)"""
    out = []
    for third in range(3):
        for column in range(32):
            for row in range(8):
                for line in range(8):
                    out.append(pixel_address(column, third * 64 + row * 8 + line))
    return out + list(range(6144, 6912))


def tokens(stream, pos=0):
    out = []
    while True:
        b = stream[pos]
        if not b & 0x80:
            out.append(('copy', ((b >> 3) & 15) + 3, (b & 7) * 256 + stream[pos + 1]))
            pos += 2
        elif b == 0x80:
            return out, pos + 1
        elif not b & 0x40:
            out.append(('lit', b & 0x3F))
            pos += 1 + (b & 0x3F)
        else:
            out.append(('run', (b & 0x3F) + 3))
            pos += 2


def unpack(stream, pos=0):
    """(the screen, the end of the stream, the parse)"""
    lin, start = [], pos
    parse, end = tokens(stream, pos)
    pos = start
    for t in parse:
        if t[0] == 'copy':
            src = len(lin) - t[2]
            lin += lin[src:src + t[1]] if t[1] <= t[2] else [lin[src + k] for k in range(t[1])]
            pos += 2
        elif t[0] == 'lit':
            lin += stream[pos + 1:pos + 1 + t[1]]
            pos += 1 + t[1]
        else:
            lin += [stream[pos + 1]] * t[1]
            pos += 2
    scr = bytearray(6912)
    for k, a in enumerate(lz_order()):
        scr[a] = lin[k]
    return bytes(scr), end, parse


def match_length(lin, q, off):
    k = 0
    while k < 18 and k < off and q + k < len(lin) and lin[q - off + k] == lin[q + k]:
        k += 1
    return k


def pack(scr, parse=()):
    lin = [scr[a] for a in lz_order()]
    out, lit, q, n = bytearray(), bytearray(), 0, len(lin)

    def flush():
        nonlocal lit
        while lit:
            part = lit[:63]
            out.append(0x80 | len(part))
            out.extend(part)
            lit = lit[len(part):]

    parse = list(parse)
    following = True
    while q < n:
        if following and parse:
            t = parse.pop(0)
            if t[0] == 'lit' and q + t[1] <= n:
                lit += bytes(lin[q:q + t[1]])
                flush()
                q += t[1]
                continue
            if t[0] == 'run' and 3 <= t[1] <= 66 and q + t[1] <= n and lin[q:q + t[1]] == [lin[q]] * t[1]:
                out += bytes([0xC0 | (t[1] - 3), lin[q]])
                q += t[1]
                continue
            if t[0] == 'copy' and 3 <= t[1] <= 18 and 0 < t[2] <= min(q, 2047) and match_length(lin, q, t[2]) >= t[1]:
                out += bytes([((t[1] - 3) << 3) | (t[2] >> 8), t[2] & 0xFF])
                q += t[1]
                continue
            following = False
        best, offset = 0, 0
        for off in range(min(q, 2046), 0, -1):
            k = match_length(lin, q, off)
            if k > best:
                best, offset = k, off
        run = 1
        while q + run < n and run < 66 and lin[q + run] == lin[q]:
            run += 1
        if run >= 3 and run > best:
            flush()
            out += bytes([0xC0 | (run - 3), lin[q]])
            q += run
        elif best >= 3:
            flush()
            out += bytes([((best - 3) << 3) | (offset >> 8), offset & 0xFF])
            q += best
        else:
            lit.append(lin[q])
            q += 1
            if len(lit) == 63:
                flush()
    flush()
    out.append(0x80)
    return bytes(out)


def read_parse(path):
    out = []
    for line in open(path):
        words = line.split('#')[0].split()
        if words:
            out.append((words[0],) + tuple(int(w) for w in words[1:]))
    return out


def write_parse(parse, path, title):
    with open(path, 'w') as f:
        f.write('# %s: the authors\' packer\'s tokens in order (tools/intro_screen.py)\n' % title)
        for t in parse:
            f.write(' '.join(str(x) for x in t) + '\n')


def main():
    cmd = sys.argv[1]
    if cmd == 'to-png':
        screen_to_png(open(sys.argv[2], 'rb').read()[:6912], sys.argv[3])
    elif cmd == 'to-scr':
        open(sys.argv[3], 'wb').write(png_to_screen(sys.argv[2]))
    elif cmd == 'unpack':
        data = open(sys.argv[2], 'rb').read()
        scr, end, parse = unpack(data, int(sys.argv[3], 0))
        open(sys.argv[4], 'wb').write(scr)
        if len(sys.argv) > 5:
            write_parse(parse, sys.argv[5], sys.argv[5])
        print('stream %d bytes, %d tokens' % (end - int(sys.argv[3], 0), len(parse)))
    elif cmd == 'pack':
        parse = read_parse(sys.argv[4]) if len(sys.argv) > 4 else ()
        open(sys.argv[3], 'wb').write(pack(open(sys.argv[2], 'rb').read(), parse))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()

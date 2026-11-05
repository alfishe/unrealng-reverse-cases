#!/usr/bin/env python3
"""The front99 part's resources (the '99 stage 2, the pictures block, the music block) in their editable forms, both
ways, and their checks.

    python3 tools/front99_res.py extract          src/res/{stage2,pictures99,music99}/ from work/media/99 (first cut)
    python3 tools/front99_res.py build OUT        OUT/res/<part>/<file>.bin: the bytes the sources INCBIN
    python3 tools/front99_res.py check            the round trips, the built bytes against work/media/99, and the
                                                  picture decoded as DecodeScreen does against the recording's
                                                  buffer (work/stage2/front99/dumps, when there)
    python3 tools/front99_res.py rle-unpack STREAM OUT.scr / rle-pack SCR OUT
    python3 tools/front99_res.py to-png SCR PNG / to-scr PNG SCR

Formats:

- Screens (6912 bytes) as PNG: 256 x 192, indexed, 32 colours: index = bright x 16 + (pixel set) x 8 + colour; what a
  cell does not show (the ink of a cell with no set pixel, the paper of one with no clear pixel, flash) is in the
  text chunk `zx-hidden` (768 pairs: the hidden colour or `-`, `F` or `-`). The PNG code is copied from
  R/games/advanced-nether-earth/tools/intro_screen.py (shared tools are copied, never imported across cases).
- The pictures block's RLE (DecodeScreen, $7D87): the screen's bytes in the decoder's order (column by column, each
  column's 192 pixel lines from the top, then the 768 attributes in order) as a stream: a byte other than $9A is
  itself; $9A V N is V N times (N = 0 would be 256). The encoder: a run of 3 or more equal bytes, or any $9A, is
  written as $9A V N (N at most 255), everything else as the byte. On this picture it gives the original stream
  byte for byte (runs of 2 as literals, $9A as $9A $9A $01); the cap of 255 is not witnessed (the longest run is 153).
- The 64-column font (2048 bytes, row r of character c at + 256 x r + c) as a 1-bit PNG of 16 x 16 cells of
  8 x 8 pixels, character c at cell (c mod 16, c / 16); white = a set bit.
- The scroller text (CP866) as UTF-8: one file line a scroller line, each written back with CR LF; TAB as TAB;
  `{AT c,r}` the bytes $16 c r; `{$hh}` any other single byte (none in this text).
"""
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, 'work', 'media', '99')
RES = os.path.join(ROOT, 'src', 'res')
DUMPS = os.path.join(ROOT, 'work', 'stage2', 'front99', 'dumps')


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



# --- the pictures block's RLE (DecodeScreen) ---

def decoder_order(scr):
    """the screen's 6912 bytes in DecodeScreen's order"""
    out = bytearray(scr[pixel_address(x, y)] for x in range(32) for y in range(192))
    return bytes(out + scr[6144:6912])


def rle_unpack(stream):
    """(screen, bytes used): DecodeScreen's loop, the run counter shared by the pixels and the attributes"""
    pos, run, value, out = 0, 0, 0, bytearray()
    while len(out) < 6912:
        if run == 0:
            byte = stream[pos]
            pos += 1
            if byte != 0x9A:
                out.append(byte)
                continue
            value, run = stream[pos], stream[pos + 1]
            pos += 2
        run = (run - 1) & 255
        out.append(value)
    scr = bytearray(6912)
    for i, (x, y) in enumerate((x, y) for x in range(32) for y in range(192)):
        scr[pixel_address(x, y)] = out[i]
    scr[6144:] = out[6144:]
    return bytes(scr), pos


def rle_pack(scr):
    data, out, i = decoder_order(scr), bytearray(), 0
    while i < len(data):
        v, n = data[i], 1
        while i + n < len(data) and data[i + n] == v and n < 255:
            n += 1
        if n >= 3 or v == 0x9A:
            out += bytes((0x9A, v, n))
            i += n
        else:
            out.append(v)
            i += 1
    return bytes(out)


# --- the 64-column font ---

def font_to_png(font, path):
    rows = [[0] * 128 for _ in range(128)]
    for c in range(256):
        for r in range(8):
            byte = font[r * 256 + c]
            for bit in range(8):
                rows[(c // 16) * 8 + r][(c % 16) * 8 + bit] = byte >> (7 - bit) & 1
    png_write(path, 128, 128, rows, [(0, 0, 0), (255, 255, 255)], {})


def png_to_font(path):
    width, height, rows, _ = png_read(path)
    if (width, height) != (128, 128):
        sys.exit(f'{path}: {width} x {height}, not 128 x 128')
    font = bytearray(2048)
    for c in range(256):
        for r in range(8):
            byte = 0
            for bit in range(8):
                v = rows[(c // 16) * 8 + r][(c % 16) * 8 + bit]
                if v > 1:
                    sys.exit(f'{path}: index {v}, not 0 or 1')
                byte |= v << (7 - bit)
            font[r * 256 + c] = byte
    return bytes(font)


# --- the scroller text ---

def text_to_utf8(data):
    out, i = [], 0
    while i < len(data):
        b = data[i]
        if b == 0x16 and i + 2 < len(data):
            out.append('{AT %d,%d}' % (data[i + 1], data[i + 2]))
            i += 3
        elif b == 0x0D and data[i + 1:i + 2] == b'\n':
            out.append('\n')
            i += 2
        elif b == 0x09 or 0x20 <= b and b not in (0x7B, 0x7D, 0x7F):
            out.append(bytes([b]).decode('cp866'))
            i += 1
        else:
            out.append('{$%02X}' % b)
            i += 1
    return ''.join(out)


def utf8_to_text(text):
    out, i = bytearray(), 0
    while i < len(text):
        ch = text[i]
        if ch == '{':
            end = text.index('}', i)
            token = text[i + 1:end]
            if token.startswith('AT '):
                col, row = (int(v) for v in token[3:].split(','))
                out += bytes((0x16, col, row))
            elif token.startswith('$'):
                out.append(int(token[1:], 16))
            else:
                sys.exit(f'scroller text: unknown {{{token}}}')
            i = end + 1
            continue
        out += b'\r\n' if ch == '\n' else ch.encode('cp866')
        i += 1
    return bytes(out)


# --- the parts ---

def media(name):
    return open(os.path.join(MEDIA, name), 'rb').read()


def slices():
    """{resource: (media file, offset, length)}: where each resource's bytes are in the media"""
    s2, pic, mus = 0x61A8, 0x7D87, 0xC000
    return {
        'stage2/scroller.bin': ('stage2-out.bin', 0x654C - s2, 0x7587 - 0x654C),
        'stage2/font64.bin': ('stage2-out.bin', 0x7587 - s2, 0x800),
        'pictures99/intro-screen.rle': ('pictures.bin', 0x7DFA - pic, 0x8A36 - 0x7DFA),
        'pictures99/leftover-8a36.bin': ('pictures.bin', 0x8A36 - pic, 0x8A87 - 0x8A36),
        'music99/ne_mus.stc': ('music.bin', 0xC4A8 - mus, 0x7E7),
        'music99/leftover-cc8f.bin': ('music.bin', 0xCC8F - mus, 0xCD00 - 0xCC8F),
    }


def original(name):
    f, off, n = slices()[name]
    return media(f)[off:off + n]


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mode = 'w' if isinstance(data, str) else 'wb'
    with open(path, mode, **({'encoding': 'utf-8', 'newline': '\n'} if mode == 'w' else {})) as f:
        f.write(data)


def extract():
    """the editable sources from the media (the first cut; after it the sources are the truth)"""
    write(os.path.join(RES, 'stage2', 'scroller.txt'), text_to_utf8(original('stage2/scroller.bin')))
    font_to_png(original('stage2/font64.bin'), os.path.join(RES, 'stage2', 'font64.png'))
    scr, used = rle_unpack(original('pictures99/intro-screen.rle'))
    os.makedirs(os.path.join(RES, 'pictures99'), exist_ok=True)
    screen_to_png(scr, os.path.join(RES, 'pictures99', 'intro-screen.png'))
    for name in ('pictures99/leftover-8a36.bin', 'music99/ne_mus.stc', 'music99/leftover-cc8f.bin'):
        write(os.path.join(RES, name), original(name))


def build(out):
    """{resource: bytes} from the sources, written under out/res"""
    text = open(os.path.join(RES, 'stage2', 'scroller.txt'), encoding='utf-8', newline='').read()
    files = {
        'stage2/scroller.bin': utf8_to_text(text),
        'stage2/font64.bin': png_to_font(os.path.join(RES, 'stage2', 'font64.png')),
        'pictures99/intro-screen.rle': rle_pack(png_to_screen(os.path.join(RES, 'pictures99', 'intro-screen.png'))),
    }
    for name in ('pictures99/leftover-8a36.bin', 'music99/ne_mus.stc', 'music99/leftover-cc8f.bin'):
        files[name] = open(os.path.join(RES, name), 'rb').read()
    if out:
        for name, data in files.items():
            write(os.path.join(out, 'res', name), data)
    return files


def check():
    bad = 0
    for name, data in build(None).items():
        same = data == original(name)
        bad += not same
        print(f'{name}: {len(data)} bytes, {"= the media" if same else "DIFFERS from the media"}')
    rle = original('pictures99/intro-screen.rle')
    scr, used = rle_unpack(rle)
    print(f'RLE: the stream decodes to 6912 bytes using {used} of {len(rle)}; re-packed '
          f'{"identical" if rle_pack(scr) == rle else "DIFFERENT"}')
    bad += rle_pack(scr) != rle or used != len(rle)
    # The 64 K dumps of r99 (tools/ttd_dump.py --cpu) after DecodeScreen ran: the buffer $8A87 = the decoded screen
    for frame in (473, 747, 1300, 2178):
        path = os.path.join(DUMPS, f'f{frame}-cpu.bin')
        if os.path.exists(path):
            mem = open(path, 'rb').read()
            diff = sum(a != b for a, b in zip(mem[0x8A87:0x8A87 + 6912], scr))
            bad += diff != 0
            print(f'r99 frame {frame}: PictureBuffer $8A87-$A586 vs the decoded picture: {diff} bytes differ')
    text = original('stage2/scroller.bin')
    bad += utf8_to_text(text_to_utf8(text)) != text
    font = original('stage2/font64.bin')
    halves = sum(1 for c in range(32, 256) for r in range(8) if font[r * 256 + c] >> 4 != font[r * 256 + c] & 15)
    print(f'font: characters $20-$FF with different nibbles: {halves} rows')
    print('front99_res: ' + ('all checks pass' if not bad else f'{bad} checks FAIL'))
    return 1 if bad else 0


def main():
    args = sys.argv[1:]
    if args == ['extract']:
        extract()
    elif args[:1] == ['build'] and len(args) == 2:
        build(args[1])
    elif args == ['check']:
        return check()
    elif args[:1] == ['rle-unpack'] and len(args) == 3:
        open(args[2], 'wb').write(rle_unpack(open(args[1], 'rb').read())[0])
    elif args[:1] == ['rle-pack'] and len(args) == 3:
        open(args[2], 'wb').write(rle_pack(open(args[1], 'rb').read()))
    elif args[:1] == ['to-png'] and len(args) == 3:
        screen_to_png(open(args[1], 'rb').read(), args[2])
    elif args[:1] == ['to-scr'] and len(args) == 3:
        open(args[2], 'wb').write(png_to_screen(args[1]))
    else:
        sys.exit(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main())

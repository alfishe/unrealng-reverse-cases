#!/usr/bin/env python3
"""The '99 menu's resources (src/res/menu99) in their editable forms, both ways, and their check.

    python3 tools/menu99_res.py build OUT     OUT/res/menu99/*.bin: the bytes src/menu99/*.asm INCBIN
    python3 tools/menu99_res.py check         the editable files give the bytes of work/media/99/menu-out.bin
    install(files)                            (from tools/menu99_mkgame.py menu --install) the bytes kit/mkgame.py
                                              wrote, as the editable files

Formats (src/res/menu99/README.md):

- menu-strings.txt: the six strings the menu prints through the game's PrintInline, one section each ([menu],
  [bottom], [description], [about], [advices], [greets]). Inside a section the line breaks of the file are not bytes;
  `{AT y,x}` = 1 y x, `{ATTR n}` = 2 n, `{NL}` = 3, `{SIZE $hh}` = 4 hh, `{$hh}` any other byte below 32 or above
  126, every other character itself (ASCII); the closing 0 is not written (each section ends with it).
- pointer.png: the 8 x 8 pointer, 4 colours: 0 the screen shows through (mask 1, pixel 0), 1 black (mask 0, pixel 0),
  2 white (mask 0, pixel 1), 3 the screen with the pixel set (mask 1, pixel 1); bytes: mask, pixels a row.
- viewer-font.png: the 64-column font (2048 bytes, row r of character c at + 256 x r + c) as a 1-bit PNG of 16 x 16
  cells of 8 x 8, character c at cell (c mod 16, c / 16), white = a set bit; both nibbles of a byte are drawn (the
  same layout as src/res/stage2/font64.png, whose bytes it equals).
"""
import io
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res', 'menu99')
MEDIA = os.path.join(ROOT, 'work', 'media', '99', 'menu-out.bin')
ORG = 0xD800

STRINGS = [('menu', 'menu-text.bin', 0xD826, 0xD912), ('bottom', 'menu-bottom.bin', 0xD920, 0xD967),
           ('description', 'title-description.bin', 0xDB2B, 0xDB4D), ('about', 'title-about.bin', 0xDB5B, 0xDB7F),
           ('advices', 'title-advices.bin', 0xDB97, 0xDBB5), ('greets', 'title-greets.bin', 0xDBC3, 0xDBE0)]
POINTER = ('pointer.bin', 0xDE11, 0xDE21)
FONT = ('viewer-font.bin', 0xDEF1, 0xE6F1)
POINTER_PALETTE = [(255, 0, 255), (0, 0, 0), (255, 255, 255), (128, 128, 128)]


def string_to_text(data):
    if not data or data[-1] != 0:
        sys.exit('menu99_res: a PrintInline string without its 0')
    out, i = [], 0
    while i < len(data) - 1:
        c = data[i]
        if c == 1:
            out.append('\n{AT %d,%d}' % (data[i + 1], data[i + 2]))
            i += 3
        elif c == 2:
            out.append('{ATTR %d}' % data[i + 1])
            i += 2
        elif c == 3:
            out.append('{NL}')
            i += 1
        elif c == 4:
            out.append('{SIZE $%02X}' % data[i + 1])
            i += 2
        elif 32 <= c < 127 and c not in (ord('{'), ord('}')):
            out.append(chr(c))
            i += 1
        else:
            out.append('{$%02X}' % c)
            i += 1
    return ''.join(out).lstrip('\n')


def text_to_string(text, name):
    out = bytearray()
    for tok in re.findall(r'\{[^}]*\}|.', text.replace('\n', '')):
        m = re.match(r'^\{AT (\d+),(\d+)\}$', tok)
        if m:
            out += bytes([1, int(m.group(1)), int(m.group(2))])
        elif re.match(r'^\{ATTR (\d+)\}$', tok):
            out += bytes([2, int(tok[6:-1])])
        elif tok == '{NL}':
            out.append(3)
        elif re.match(r'^\{SIZE \$[0-9A-Fa-f]{2}\}$', tok):
            out += bytes([4, int(tok[7:9], 16)])
        elif re.match(r'^\{\$[0-9A-Fa-f]{2}\}$', tok):
            out.append(int(tok[2:4], 16))
        elif len(tok) == 1 and 32 <= ord(tok) < 127:
            out.append(ord(tok))
        else:
            sys.exit(f'menu-strings.txt [{name}]: cannot read {tok!r}')
    return bytes(out) + b'\0'


def strings_to_file(parts):
    return ''.join('[%s]\n%s\n\n' % (name, string_to_text(parts[name])) for name, *_ in STRINGS)


def file_to_strings(text):
    parts, name = {}, None
    for line in text.split('\n'):
        m = re.match(r'^\[(\w+)\]$', line)
        if m:
            name = m.group(1)
            parts[name] = []
        elif name:
            parts[name].append(line)
    names = [n for n, *_ in STRINGS]
    if sorted(parts) != sorted(names):
        sys.exit('menu-strings.txt: the sections must be ' + ', '.join(names))
    return {n: text_to_string('\n'.join(parts[n]).strip('\n'), n) for n in names}


def png_bytes(image):
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=True)
    return out.getvalue()


def pointer_to_png(data):
    im = Image.new('P', (8, 8))
    im.putpalette([v for c in POINTER_PALETTE for v in c])
    for y in range(8):
        mask, pix = data[2 * y], data[2 * y + 1]
        for x in range(8):
            m, p = mask >> (7 - x) & 1, pix >> (7 - x) & 1
            im.putpixel((x, y), (0 if not p else 3) if m else (2 if p else 1))
    return png_bytes(im)


def png_to_pointer(raw):
    im = Image.open(io.BytesIO(raw))
    if im.mode != 'P' or im.size != (8, 8):
        sys.exit('pointer.png: an 8 x 8 indexed PNG')
    out = bytearray()
    for y in range(8):
        mask = pix = 0
        for x in range(8):
            v = im.getpixel((x, y))
            if v > 3:
                sys.exit(f'pointer.png: index {v} at ({x},{y}), not 0-3')
            mask |= (v in (0, 3)) << (7 - x)
            pix |= (v in (2, 3)) << (7 - x)
        out += bytes([mask, pix])
    return bytes(out)


def font_to_png(font):
    im = Image.new('1', (128, 128))
    for c in range(256):
        for r in range(8):
            byte = font[r * 256 + c]
            for bit in range(8):
                im.putpixel(((c % 16) * 8 + bit, (c // 16) * 8 + r), byte >> (7 - bit) & 1)
    return png_bytes(im)


def png_to_font(raw):
    im = Image.open(io.BytesIO(raw)).convert('1')
    if im.size != (128, 128):
        sys.exit('viewer-font.png: 128 x 128')
    font = bytearray(2048)
    for c in range(256):
        for r in range(8):
            byte = 0
            for bit in range(8):
                byte |= (1 if im.getpixel(((c % 16) * 8 + bit, (c // 16) * 8 + r)) else 0) << (7 - bit)
            font[r * 256 + c] = byte
    return bytes(font)


def install(files, res=RES):
    """kit's resource bytes ({'menu99/<file>.bin': bytes}) as the editable files in src/res/menu99"""
    os.makedirs(res, exist_ok=True)
    get = {os.path.basename(k): v for k, v in files.items()}
    open(os.path.join(res, 'menu-strings.txt'), 'w').write(
        strings_to_file({name: get[f] for name, f, *_ in STRINGS}))
    open(os.path.join(res, 'pointer.png'), 'wb').write(pointer_to_png(get[POINTER[0]]))
    open(os.path.join(res, 'viewer-font.png'), 'wb').write(font_to_png(get[FONT[0]]))
    if decode_sources(res) != get:
        sys.exit('menu99_res: the editable files do not give the bytes back')


def decode_sources(res=RES):
    out = {}
    strings = file_to_strings(open(os.path.join(res, 'menu-strings.txt')).read())
    for name, f, *_ in STRINGS:
        out[f] = strings[name]
    out[POINTER[0]] = png_to_pointer(open(os.path.join(res, 'pointer.png'), 'rb').read())
    out[FONT[0]] = png_to_font(open(os.path.join(res, 'viewer-font.png'), 'rb').read())
    return out


def build(out, res=RES):
    dest = os.path.join(out, 'res', 'menu99')
    os.makedirs(dest, exist_ok=True)
    for f, data in decode_sources(res).items():
        open(os.path.join(dest, f), 'wb').write(data)


def check(res=RES):
    media = open(MEDIA, 'rb').read()
    built = decode_sources(res)
    bad = 0
    for f, lo, hi in [(f, lo, hi) for _, f, lo, hi in STRINGS] + [POINTER, FONT]:
        if built[f] != media[lo - ORG:hi - ORG]:
            print(f'menu99_res: {f} differs from menu-out.bin ${lo:04X}-${hi - 1:04X}')
            bad += 1
    print('menu99_res: %d files, %s' % (len(built), 'identical' if not bad else f'{bad} differ'))
    return 1 if bad else 0


def main():
    if len(sys.argv) == 3 and sys.argv[1] == 'build':
        build(sys.argv[2])
        return 0
    if len(sys.argv) == 2 and sys.argv[1] == 'check':
        return check()
    sys.exit(__doc__)


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The credits scroller's resources (src/res/intro/scroller) to the bytes src/intro/scroller INCBINs, and back.

    python3 tools/intro_scroller.py build [--src DIR] --out DIR    the sources -> text.bin font.bin dither.bin
                                                                    screen.bin star-path.bin in DIR
    python3 tools/intro_scroller.py export IMAGE [--src DIR]       the scroller's image (d03-6600.bin, $6600-$FFFF)
                                                                    -> the sources
    python3 tools/intro_scroller.py check [--src DIR]              build, export the built bytes again, build: same

| Source | Bytes | Format |
| --- | --- | --- |
| `text.txt` | ScrollerText `$6D73-$76D2`, 2400 bytes | 100 lines of exactly 24 characters between `|` and `|`, one a column of the scroller (TypeChar prints it top down, the next line one column left); codes `$20-$5F` as ASCII (`'` `!` `-` `.` `>` `*` digits, capitals). Lines starting `#` are comments. The 0 after it (ScrollerTextEnd) is in the source. |
| `font.png` | ScrollerFont `$7900-$7AFF`, codes `$20-$5F` | 128 x 32, 16 glyphs a row in code order; index 0 paper, 1 ink; 8 bytes a glyph, top line first, bit 7 left. The glyphs are stored turned a quarter clockwise, as the screen shows them (the text runs down the columns). |
| `dither.png` | DitherLevels `$8000-$803F` | 128 x 4: the 16 heat levels left to right, each 8 x 4 (a byte a line, bit 7 left); index 0 paper, 1 ink. ScrollerInit takes the left nibble of one level and the right nibble of another for each pair of cells. |
| `screen.png` | ScrollerScreen `$8500-$9FFF`, 6912 bytes | the screen copied to `$4000` at the start (the logo and "Presents" at the top): tools/intro_screen.py's lossless screen PNG |
| `star-path.txt` | StarPath `$C09A-$C14D` | 90 lines `x y`: the points of the circle the star's five tips run on (cells of StarBuffer), in order; tip k at step s is point s + 18 k |
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import intro_screen  # noqa: E402

CASE = os.path.dirname(HERE)
SRC = os.path.join(CASE, 'src', 'res', 'intro', 'scroller')
ORG = 0x6600
PARTS = {'text.bin': (0x6D73, 2400), 'font.bin': (0x7900, 512), 'dither.bin': (0x8000, 64),
         'screen.bin': (0x8500, 6912), 'star-path.bin': (0xC09A, 180)}
MONO = [(0, 0, 0), (255, 255, 255)]


def bits_png(path, width, height, pixel):
    rows = [[pixel(x, y) for x in range(width)] for y in range(height)]
    intro_screen.png_write(path, width, height, rows, MONO, {})


def read_mono(path, size):
    w, h, rows, _ = intro_screen.png_read(path)
    if (w, h) != size:
        sys.exit(f'{path}: {w} x {h}, not {size[0]} x {size[1]}')
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v > 1:
                sys.exit(f'{path}: pixel ({x}, {y}) has index {v}, not 0 or 1')
    return rows


def export(data, src):
    """the bytes of each part -> the sources"""
    os.makedirs(src, exist_ok=True)
    text = data['text.bin']
    with open(os.path.join(src, 'text.txt'), 'w') as f:
        f.write('# The credits scroller\'s text (ScrollerText): one line a column of 24 characters, | marks its ends\n')
        for i in range(0, len(text), 24):
            f.write('|' + text[i:i + 24].decode('ascii') + '|\n')
    font = data['font.bin']
    bits_png(os.path.join(src, 'font.png'), 128, 32,
             lambda x, y: font[((y // 8) * 16 + x // 8) * 8 + y % 8] >> (7 - x % 8) & 1)
    dither = data['dither.bin']
    bits_png(os.path.join(src, 'dither.png'), 128, 4, lambda x, y: dither[(x // 8) * 4 + y] >> (7 - x % 8) & 1)
    intro_screen.screen_to_png(data['screen.bin'], os.path.join(src, 'screen.png'))
    path = data['star-path.bin']
    with open(os.path.join(src, 'star-path.txt'), 'w') as f:
        f.write('# StarPath: x y of the 90 points of the star tips\' circle (StarBuffer cells)\n')
        for i in range(0, len(path), 2):
            f.write('%d %d\n' % (path[i], path[i + 1]))


def build(src):
    """the sources -> {file: bytes}"""
    out = {}
    text = bytearray()
    for n, line in enumerate(open(os.path.join(src, 'text.txt'), encoding='utf-8'), 1):
        line = line.rstrip('\n')
        if line.startswith('#') or not line:
            continue
        if len(line) != 26 or line[0] != '|' or line[-1] != '|':
            sys.exit(f'text.txt:{n}: not 24 characters between | and |')
        for ch in line[1:-1]:
            if not 0x20 <= ord(ch) <= 0x5F:
                sys.exit(f'text.txt:{n}: {ch!r} is not in the font (codes $20-$5F)')
        text += line[1:-1].encode('ascii')
    out['text.bin'] = bytes(text)
    rows = read_mono(os.path.join(src, 'font.png'), (128, 32))
    font = bytearray(512)
    for y in range(32):
        for x in range(128):
            font[((y // 8) * 16 + x // 8) * 8 + y % 8] |= rows[y][x] << (7 - x % 8)
    out['font.bin'] = bytes(font)
    rows = read_mono(os.path.join(src, 'dither.png'), (128, 4))
    dither = bytearray(64)
    for y in range(4):
        for x in range(128):
            dither[(x // 8) * 4 + y] |= rows[y][x] << (7 - x % 8)
    out['dither.bin'] = bytes(dither)
    out['screen.bin'] = intro_screen.png_to_screen(os.path.join(src, 'screen.png'))
    path = bytearray()
    for line in open(os.path.join(src, 'star-path.txt')):
        words = line.split('#')[0].split()
        if words:
            path += bytes(int(w) for w in words)
    out['star-path.bin'] = bytes(path)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('cmd', choices=['build', 'export', 'check'])
    p.add_argument('image', nargs='?')
    p.add_argument('--src', default=SRC)
    p.add_argument('--out')
    args = p.parse_args()
    if args.cmd == 'export':
        image = open(args.image, 'rb').read()
        export({name: image[a - ORG:a - ORG + n] for name, (a, n) in PARTS.items()}, args.src)
    elif args.cmd == 'build':
        os.makedirs(args.out, exist_ok=True)
        for name, data in build(args.src).items():
            if len(data) != PARTS[name][1]:
                sys.exit(f'{name}: {len(data)} bytes, the source keeps {PARTS[name][1]}')
            open(os.path.join(args.out, name), 'wb').write(data)
    else:
        import tempfile
        first = build(args.src)
        with tempfile.TemporaryDirectory() as tmp:
            export(first, tmp)
            again = build(tmp)
        print('check: same' if first == again else 'check: DIFFERENT')
        return 0 if first == again else 1


if __name__ == '__main__':
    sys.exit(main())

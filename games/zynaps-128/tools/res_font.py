#!/usr/bin/env python3
"""8 x 8 glyphs as an indexed PNG: src/res/fonts/*.font.png (Pillow).

A resource under fonts/ is a run of 8-byte glyphs, each byte one line, bit 7 at the left. The PNG holds them in
cells of 8 x 8 pixels, COLUMNS cells a row, left to right and top to bottom; palette index 0 is a clear pixel, 1 a set
one, 2 marks the lines past the resource's end (a resource need not be whole glyphs: romleftover.bin stops one line
short of its last glyph). Reading back, the bytes end at the first line drawn in index 2.

    python3 tools/res_font.py check FILE.bin                the bytes -> PNG -> bytes, the same
    python3 tools/res_font.py preview FILE.bin OUT.png      a x4 view with a grid, for the README
Copied from the 48K case (../zynaps/tools): the formats of the same bytes.
"""
import io
import sys

from PIL import Image

COLUMNS = {'fonts/glyphs.bin': 9}  # the 54 game glyphs as 9 x 6; the others 8 a row
PALETTE = [255, 255, 255, 0, 0, 0, 192, 64, 192]  # clear, set, past the end


def columns(name, glyphs):
    return min(COLUMNS.get(name, 8), max(glyphs, 1))


def to_png(data, name=''):
    glyphs = (len(data) + 7) // 8
    cols = columns(name, glyphs)
    rows = (glyphs + cols - 1) // cols
    image = Image.new('P', (8 * cols, 8 * rows), 2)
    image.putpalette(PALETTE)
    pixels = image.load()
    for i, byte in enumerate(data):
        g, line = divmod(i, 8)
        x0, y = 8 * (g % cols), 8 * (g // cols) + line
        for bit in range(8):
            pixels[x0 + bit, y] = (byte >> (7 - bit)) & 1
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=False)
    return out.getvalue()


def from_png(png, name=''):
    image = Image.open(io.BytesIO(png))
    if image.mode != 'P':
        raise ValueError(f'{name}: the PNG must be indexed (palette): 0 clear, 1 set, 2 past the end')
    width, height = image.size
    if width % 8 or height % 8:
        raise ValueError(f'{name}: {width} x {height}: not whole 8 x 8 cells')
    pixels = image.load()
    out = bytearray()
    for g in range((width // 8) * (height // 8)):
        x0, y0 = 8 * (g % (width // 8)), 8 * (g // (width // 8))
        for line in range(8):
            values = [pixels[x0 + bit, y0 + line] for bit in range(8)]
            if all(v == 2 for v in values):
                return bytes(out)
            if any(v not in (0, 1) for v in values):
                raise ValueError(f'{name}: glyph {g} line {line}: a pixel neither 0 nor 1 (or a line half past the end)')
            out.append(sum(v << (7 - bit) for bit, v in enumerate(values)))
    return bytes(out)


def preview(data, name, path, scale=4):
    image = Image.open(io.BytesIO(to_png(data, name))).convert('RGB')
    image = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
    pixels = image.load()
    for x in range(0, image.width, 8 * scale):
        for y in range(image.height):
            pixels[x, y] = (128, 128, 255)
    for y in range(0, image.height, 8 * scale):
        for x in range(image.width):
            pixels[x, y] = (128, 128, 255)
    image.save(path)


KINDS = [('fonts/*.bin', '.font.png', to_png, from_png)]


def main():
    if len(sys.argv) >= 3 and sys.argv[1] in ('check', 'preview'):
        path = sys.argv[2]
        name = 'fonts/' + path.replace('\\', '/').rsplit('/', 1)[-1]
        data = open(path, 'rb').read()
        if sys.argv[1] == 'preview' and len(sys.argv) == 4:
            preview(data, name, sys.argv[3])
            return 0
        png = to_png(data, name)
        back = from_png(png, name)
        ok = back == data and to_png(back, name) == png
        print(f'{path}: {len(data)} bytes, ' + ('both ways the same' if ok else 'FAIL'))
        return 0 if ok else 1
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The pictures of Rick Dangerous as indexed PNG, both ways (a format module of tools/res_formats.py; READMEs in
src/res/graphics, src/res/sprites and src/res/screens).

| Resource(s) | Bytes | PNG |
| --- | --- | --- |
| graphics/charset0.bin + charattr0.bin (`$7100`, `$7900`) | 2048 + 256 | graphics/charset0.png: 16 x 16 cells of 8 x 8 in their colours, a grid |
| graphics/charset1.bin + charattr1.bin (`$7A00`, `$8200`) | 2048 + 256 | graphics/charset1.png |
| graphics/font.bin (`$9E95`) | 344 | graphics/font.png: 43 glyphs in a row of cells, ink black on white |
| sprites/frames.bin (`$8401`) | 6804 | sprites/frames.png: 54 frames of 24 x 21, 9 a row, a grid |
| sprites/copied.bin (`$6BA4`, `$6C22`) | 2 x 126 | sprites/copied.png: the two frames Start copies to `$6A80` and `$7080` |
| screens/loading.scr (`$4000`) | 6912 | screens/loading.png: 256 x 192 in its colours |

**Colours** (char sets, the loading screen). The palette's first 16 entries are the Spectrum's colours, 0-7 plain and
8-15 BRIGHT; a pixel is the index of its cell's INK (a set bit) or PAPER. The attributes themselves (with FLASH, and
which colour is INK) are in the PNG's text chunk `attributes`, one line of hex a row of cells: change a colour there
and paint with the cell's two indices. A cell whose INK and PAPER are the same index cannot show its bits; they go to
the text chunk `bits` (`cell:hex`). Index 16 is the grid, never data.

**Sprite frames.** A row of a frame is 6 bytes as the drawer DrawSprite `$A419` POPs them: OR3, OR2, OR1, AND1, AND3,
AND2 (column 1 is the left byte). A pixel is index 0 when the mask keeps the background and no pixel is set
(transparent), 1 set pixel inside the mask (ink), 2 cleared pixel inside the mask (paper), 3 a set pixel over a kept
background (mask 1, pixel 1). Index 4 is the grid.
"""
import io

from PIL import Image, PngImagePlugin

ZX = [(0, 0, 0), (0, 0, 0xCD), (0xCD, 0, 0), (0xCD, 0, 0xCD), (0, 0xCD, 0), (0, 0xCD, 0xCD), (0xCD, 0xCD, 0),
      (0xCD, 0xCD, 0xCD), (0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF),
      (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]
GRID = 16
SPRITE_PALETTE = [(0x4A, 0x6A, 0x7A), (0x10, 0x10, 0x10), (0xF0, 0xF0, 0xE0), (0xE0, 0x30, 0xC0), (0x80, 0x80, 0x80)]
FRAMES, ROWS, PER_ROW = 54, 21, 9
FONT_GLYPHS = 43


def png(width, height, palette, pixels, text=None, fill=0):
    image = Image.new('P', (width, height), fill)
    flat = []
    for c in palette:
        flat += list(c)
    image.putpalette(flat)
    px = image.load()
    for (x, y), v in pixels.items():
        px[x, y] = v
    info = PngImagePlugin.PngInfo()
    for k, v in (text or {}).items():
        info.add_text(k, v)
    out = io.BytesIO()
    image.save(out, 'PNG', optimize=False, pnginfo=info)
    return out.getvalue()


def open_png(data, name, size):
    image = Image.open(io.BytesIO(data))
    if image.mode != 'P':
        raise ValueError('%s: not an indexed PNG' % name)
    if image.size != size:
        raise ValueError('%s: %d x %d, not %d x %d' % ((name,) + image.size + size))
    return image, image.load(), image.text if hasattr(image, 'text') else image.info


# ------------------------------------------------------------------------------------------------- attribute cells

def attr_inks(a):
    bright = 8 if a & 0x40 else 0
    return (a & 7) + bright, ((a >> 3) & 7) + bright


def cells_to_png(bitmap, attrs, cols, rows, cell_at, grid):
    """bitmap(cell, line) -> byte; cells in rows of `cols`; grid: a 1-pixel line round each cell"""
    step = 9 if grid else 8
    pixels, same = {}, []
    for c in range(cols * rows):
        ink, paper = attr_inks(attrs[c])
        x0, y0 = (c % cols) * step + grid, (c // cols) * step + grid
        lines = [bitmap(c, y) for y in range(8)]
        if ink == paper and any(lines):
            same.append('%d:%s' % (c, bytes(lines).hex()))
        for y, b in enumerate(lines):
            for k in range(8):
                pixels[(x0 + k, y0 + y)] = ink if b >> (7 - k) & 1 else paper
    text = {'attributes': '\n'.join(bytes(attrs[r * cols:(r + 1) * cols]).hex() for r in range(rows))}
    if same:
        text['bits'] = '\n'.join(same)
    w, h = cols * step + grid, rows * step + grid
    return png(w, h, ZX + [(0x60, 0x60, 0x60)], pixels, text, GRID if grid else 0)


def cells_from_png(data, name, cols, rows, grid):
    step = 9 if grid else 8
    image, px, text = open_png(data, name, (cols * step + grid, rows * step + grid))
    if 'attributes' not in text:
        raise ValueError('%s: no attributes text chunk' % name)
    attrs = bytes.fromhex(''.join(text['attributes'].split()))
    if len(attrs) != cols * rows:
        raise ValueError('%s: %d attributes, not %d' % (name, len(attrs), cols * rows))
    same = {}
    for line in text.get('bits', '').split():
        c, _, h = line.partition(':')
        same[int(c)] = bytes.fromhex(h)
    out = []
    for c in range(cols * rows):
        ink, paper = attr_inks(attrs[c])
        x0, y0 = (c % cols) * step + grid, (c // cols) * step + grid
        lines = []
        for y in range(8):
            b = 0
            for k in range(8):
                v = px[x0 + k, y0 + y]
                if v not in (ink, paper):
                    raise ValueError('%s: cell %d pixel (%d, %d) is index %d, not its INK %d or PAPER %d'
                                     % (name, c, x0 + k, y0 + y, v, ink, paper))
                b = b << 1 | (v == ink and ink != paper)
            lines.append(b)
        if ink == paper:
            lines = list(same.get(c, bytes(8)))
        out.append(bytes(lines))
    return out, attrs


def charset_group(n):
    bins = ['graphics/charset%d.bin' % n, 'graphics/charattr%d.bin' % n]

    def to_ed(files):
        bitmap, attrs = files[bins[0]], files[bins[1]]
        return cells_to_png(lambda c, y: bitmap[8 * c + y], attrs, 16, 16, None, 1)

    def from_ed(data):
        cells, attrs = cells_from_png(data, 'charset%d.png' % n, 16, 16, 1)
        return {bins[0]: b''.join(cells), bins[1]: attrs}
    return 'graphics/charset%d.png' % n, (bins, to_ed, from_ed)


# ------------------------------------------------------------------------------------------------- the font

def font_to(data):
    attrs = bytes([0x38]) * FONT_GLYPHS
    return cells_to_png(lambda c, y: data[8 * c + y], attrs, FONT_GLYPHS, 1, None, 1)


def font_from(data):
    cells, attrs = cells_from_png(data, 'font.png', FONT_GLYPHS, 1, 1)
    if attrs != bytes([0x38]) * FONT_GLYPHS:
        raise ValueError('font.png: the attributes are not black on white')
    return b''.join(cells)


# ------------------------------------------------------------------------------------------------- sprite frames

COLS = [(3, 2), (5, 1), (4, 0)]      # (AND byte, OR byte) of columns 1-3 in a 6-byte row


def frames_to(data, count=None):
    count = count or FRAMES
    pixels = {}
    for f in range(count):
        x0, y0 = (f % PER_ROW) * 25 + 1, (f // PER_ROW) * 22 + 1
        for r in range(ROWS):
            row = data[126 * f + 6 * r:126 * f + 6 * r + 6]
            for c, (am, op) in enumerate(COLS):
                for k in range(8):
                    m, p = row[am] >> (7 - k) & 1, row[op] >> (7 - k) & 1
                    pixels[(x0 + 8 * c + k, y0 + r)] = {(1, 0): 0, (0, 1): 1, (0, 0): 2, (1, 1): 3}[(m, p)]
    rows = (count + PER_ROW - 1) // PER_ROW
    return png(PER_ROW * 25 + 1, rows * 22 + 1, SPRITE_PALETTE, pixels, None, 4)


def frames_from(data, count=None):
    count = count or FRAMES
    rows = (count + PER_ROW - 1) // PER_ROW
    image, px, _text = open_png(data, 'frames.png', (PER_ROW * 25 + 1, rows * 22 + 1))
    out = bytearray()
    for f in range(count):
        x0, y0 = (f % PER_ROW) * 25 + 1, (f // PER_ROW) * 22 + 1
        for r in range(ROWS):
            row = [0] * 6
            for c, (am, op) in enumerate(COLS):
                for k in range(8):
                    v = px[x0 + 8 * c + k, y0 + r]
                    if v > 3:
                        raise ValueError('frames.png: frame %d pixel (%d, %d) is index %d' % (f, x0 + 8 * c + k, y0 + r, v))
                    m, p = {0: (1, 0), 1: (0, 1), 2: (0, 0), 3: (1, 1)}[v]
                    row[am] |= m << (7 - k)
                    row[op] |= p << (7 - k)
            out += bytes(row)
    return bytes(out)


# ------------------------------------------------------------------------------------------------- a screen

def screen_bitmap(scr, c, y):
    x, row = c % 32, c // 32
    line = row * 8 + y
    return scr[((line & 0xC0) << 5) | ((line & 7) << 8) | ((line & 0x38) << 2) | x]


def screen_to(data):
    if len(data) != 6912:
        raise ValueError('a screen is 6912 bytes, not %d' % len(data))
    return cells_to_png(lambda c, y: screen_bitmap(data, c, y), data[6144:], 32, 24, None, 0)


def screen_from(data):
    cells, attrs = cells_from_png(data, 'loading.png', 32, 24, 0)
    out = bytearray(6144)
    for c, lines in enumerate(cells):
        x, row = c % 32, c // 32
        for y, b in enumerate(lines):
            line = row * 8 + y
            out[((line & 0xC0) << 5) | ((line & 7) << 8) | ((line & 0x38) << 2) | x] = b
    return bytes(out) + attrs


SINGLES = {
    'graphics/font.bin': ('.png', font_to, font_from),
    'sprites/frames.bin': ('.png', frames_to, frames_from),
    # the two frames the entry copies from $6BA4 / $6C22 to $6A80 / $7080 (kinds 16 and 19), the same format
    'sprites/copied.bin': ('.png', lambda d: frames_to(d, 2), lambda d: frames_from(d, 2)),
    'screens/loading.scr': ('.png', screen_to, screen_from),
}
GROUPS = dict(charset_group(n) for n in (0, 1))

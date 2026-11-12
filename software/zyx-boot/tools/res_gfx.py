#!/usr/bin/env python3
"""The menu's mono graphics as PNG sheets (tools/res_formats.py calls it for src/res/graphics/*).

A sheet is an indexed PNG: 0 paper (black), 1 ink (white), 2 the grid (grey), the frames left to right in rows of
`cols`, one grey pixel between them. Every frame is stored as the Spectrum stores it: rows top to bottom, each row
`w / 8` bytes, bit 7 the leftmost pixel. The layout (w, h, cols, frames) rides in the PNG's text chunk `zyx-sheet`, so
an edited sheet converts back without this table; paint only with indices 0 and 1 inside the frames.
"""
import io
import json

MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]
KEY = 'zyx-sheet'

# resource -> (frame width, frame height, frames a row)
SHEETS = {
    'graphics/font.bin': (8, 8, 16),        # 96 characters, space to (c); CHARS = $A500
    'graphics/logo.bin': (40, 40, 4),       # the four logo sprites printed at $4006, $400B, $4010, $4015
    'graphics/rhombus.bin': (40, 40, 1),    # RombSource: the corner rhombus every rotation phase is built from
    'graphics/twinkle.bin': (16, 16, 4),    # the four twinkle sprites
}


def handles(name):
    return name in SHEETS


def to_editable(name, data):
    from PIL import Image, PngImagePlugin
    w, h, cols = SHEETS[name]
    size = w * h // 8
    if len(data) % size:
        raise ValueError(f'{name}: {len(data)} bytes is no whole number of {size}-byte frames')
    n = len(data) // size
    rows = (n + cols - 1) // cols
    img = Image.new('P', (1 + min(n, cols) * (w + 1), 1 + rows * (h + 1)), 2)
    img.putpalette(MONO + [0] * (768 - len(MONO)))
    px = img.load()
    for f in range(n):
        x0, y0 = 1 + (f % cols) * (w + 1), 1 + (f // cols) * (h + 1)
        for y in range(h):
            for x in range(w):
                px[x0 + x, y0 + y] = (data[f * size + y * (w // 8) + x // 8] >> (7 - x % 8)) & 1
    info = PngImagePlugin.PngInfo()
    info.add_text(KEY, json.dumps({'w': w, 'h': h, 'cols': cols, 'frames': n}, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return '.png', out.getvalue()


def from_editable(name, raw):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    m = json.loads(img.text[KEY])
    px = img.load()
    w, h, cols = m['w'], m['h'], m['cols']
    size = w * h // 8
    out = bytearray(size * m['frames'])
    for f in range(m['frames']):
        x0, y0 = 1 + (f % cols) * (w + 1), 1 + (f // cols) * (h + 1)
        for y in range(h):
            for x in range(w):
                if px[x0 + x, y0 + y] == 1:
                    out[f * size + y * (w // 8) + x // 8] |= 0x80 >> (x % 8)
    return bytes(out)

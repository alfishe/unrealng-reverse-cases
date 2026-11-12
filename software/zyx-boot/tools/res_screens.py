#!/usr/bin/env python3
"""The variants' packed loading pictures as PNG screens (tools/res_formats.py calls it for graphics/*):

- graphics/rle-picture-1.bin, graphics/rle-picture-2.bin: zyxisl's and zyxboot-09's two pictures
  (variants/NAME/parts/pictures.ann), run-length packed: a byte other than `$9D` is itself, `$9D`, a byte and a
  count is that byte count times (count 0: 256 times). No end mark: the unpacker stops after `$1B00` bytes;
- graphics/intro-picture.bin: zyxermbt's loading picture (variants/zyxermbt/parts/intro.ann), LZ packed in the
  format `tools/lzpack.py --format intro` reads and writes, up to and with its `$80` end mark.

The bin is the packed stream as the disk holds it; the editable form is the unpacked screen, a 256x192 indexed PNG in
the Spectrum's 16 colours (index = bright * 8 + colour). The packers make the same choices as the ones the variants
were made with, so an unedited PNG packs to the same bytes (tools/res_formats.py check).

Attributes: the PNG's text chunk `zyx-screen` keeps each cell's attribute (flash included, which no colour shows) and
the pixel bytes of cells whose ink and paper are the same colour. A cell painted only in its ink and paper colours
keeps its attribute; a new colour in a cell becomes its ink when the cell still shows its paper, else its paper (two
new colours: the lower index the paper). Paint each cell in at most two colours of one brightness.
"""
import io
import json

import lzpack

KEY = 'zyx-screen'
SCREENS = {'graphics/rle-picture-1.bin': 'rle', 'graphics/rle-picture-2.bin': 'rle',
           'graphics/intro-picture.bin': 'intro'}
SIZE = 6912
RLE_MARK = 0x9D
# the Spectrum's colours, normal then bright
PALETTE = [0, 0, 0, 0, 0, 0xD7, 0xD7, 0, 0, 0xD7, 0, 0xD7, 0, 0xD7, 0, 0, 0xD7, 0xD7, 0xD7, 0xD7, 0, 0xD7, 0xD7, 0xD7,
           0, 0, 0, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0, 0xFF, 0, 0xFF, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0, 0xFF, 0xFF, 0xFF]


def handles(name):
    return name in SCREENS


# ------------------------------------------------------------------------------------------------- packers

def rle_unpack(src):
    out, i = bytearray(), 0
    while len(out) < SIZE:
        if src[i] == RLE_MARK:
            out += bytes([src[i + 1]]) * (src[i + 2] or 256)
            i += 3
        else:
            out.append(src[i])
            i += 1
    return bytes(out[:SIZE])


def rle_pack(d):
    """the original packer's rules: a run of 3 or more is a $9D run (256 at most), and so is every $9D byte"""
    out, p = bytearray(), 0
    while p < len(d):
        run = 1
        while p + run < len(d) and run < 256 and d[p + run] == d[p]:
            run += 1
        if run >= 3 or d[p] == RLE_MARK:
            out += bytes([RLE_MARK, d[p], run & 255])
            p += run
        else:
            out.append(d[p])
            p += 1
    return bytes(out)


def intro_order():
    """the screen offset of each byte of the intro's stream, in the order its PutByte writes (the code's mapping)"""
    order = []
    for i in range(6144):
        a = 0x4000 + i
        h, l = a >> 8, a & 255
        c = (h & 0x58) | (l & 7)
        a = (a << 2) & 0xFFFF
        h, l = (a >> 8) & 0x1F, a & 255
        order.append((c << 8 | (l & 0xE0) | h) - 0x4000)
    return order + list(range(6144, SIZE))


def unpack(name, data):
    if SCREENS[name] == 'rle':
        return rle_unpack(data)
    logical, _end = lzpack.unpack(data, 0, 'intro')
    screen = bytearray(SIZE)
    for i, a in enumerate(intro_order()):
        screen[a] = logical[i]
    return bytes(screen)


def pack(name, screen):
    if SCREENS[name] == 'rle':
        return rle_pack(screen)
    return lzpack.pack(bytes(screen[a] for a in intro_order()), 'intro')


# ------------------------------------------------------------------------------------------------- PNG

def pixel_offset(x, y):
    return (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2 | x >> 3


def colours(attr):
    """(ink index, paper index) of an attribute"""
    bright = (attr >> 6 & 1) * 8
    return bright + (attr & 7), bright + (attr >> 3 & 7)


def to_editable(name, data):
    from PIL import Image, PngImagePlugin
    s = unpack(name, data)
    img = Image.new('P', (256, 192), 0)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    same = {}
    for y in range(192):
        for x in range(256):
            ink, paper = colours(s[6144 + (y >> 3) * 32 + (x >> 3)])
            px[x, y] = ink if s[pixel_offset(x, y)] >> (7 - (x & 7)) & 1 else paper
    for cell in range(768):
        ink, paper = colours(s[6144 + cell])
        if ink == paper:
            x, y = (cell & 31) * 8, (cell >> 5) * 8
            same[str(cell)] = bytes(s[pixel_offset(x, y + r)] for r in range(8)).hex()
    info = PngImagePlugin.PngInfo()
    info.add_text(KEY, json.dumps({'attrs': s[6144:].hex(), 'same': same}, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return '.png', out.getvalue()


def from_editable(name, raw):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    meta = json.loads(img.text[KEY])
    px = img.load()
    s = bytearray(SIZE)
    s[6144:] = bytes.fromhex(meta['attrs'])
    for cell in range(768):
        x0, y0 = (cell & 31) * 8, (cell >> 5) * 8
        attr = s[6144 + cell]
        ink, paper = colours(attr)
        used = {px[x0 + x, y0 + y] for y in range(8) for x in range(8)}
        if ink == paper and used == {ink} and str(cell) in meta['same']:
            for r, b in enumerate(bytes.fromhex(meta['same'][str(cell)])):
                s[pixel_offset(x0, y0 + r)] = b
            continue
        new = used - {ink, paper}
        if new:
            if len(used) > 2 or len({c >> 3 for c in used}) > 1:
                raise ValueError(f'{name}: cell {cell & 31},{cell >> 5}: more than two colours, or two brightnesses')
            if paper in used:               # the new colour is the ink
                ink = new.pop()
            elif ink in used:               # the new colour is the paper
                paper = new.pop()
            else:                           # all new: one is the paper, two are paper (the darker) and ink
                paper, ink = min(used), max(used)
            attr = (attr & 0x80) | (ink >> 3) << 6 | (paper & 7) << 3 | (ink & 7)
            s[6144 + cell] = attr
        for y in range(8):
            b = 0
            for x in range(8):
                b = b << 1 | (px[x0 + x, y0 + y] == ink and ink != paper)
            s[pixel_offset(x0, y0 + y)] = b
    return pack(name, s)

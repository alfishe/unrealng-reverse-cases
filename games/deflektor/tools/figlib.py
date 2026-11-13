#!/usr/bin/env python3
"""Shared helpers of the case's figure scripts (tools/fig_*.py): the entry image with the resources put back, the
levels and their settings, the game's own level drawing, the Spectrum palette, a TrueType font, labelled sheets.

Every figure is drawn from the image (work/mkgame/original.bin, tools/image.py) and the editable resources in src/res,
or from a recording's screens; nothing is drawn by hand.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))

import res_formats  # noqa: E402

IMAGE = os.path.join(CASE, 'work', 'mkgame', 'original.bin')
LEVELS = os.path.join(CASE, 'src', 'res', 'levels', 'levels.txt')

PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
BG = (24, 24, 30)
FG = (225, 225, 230)
DIM = (150, 150, 160)
ACCENT = (255, 220, 90)

FONT_FILES = ['/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/SFNSMono.ttf',
              '/System/Library/Fonts/Supplemental/Courier New.ttf']


def font(size=14):
    for f in FONT_FILES:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def image():
    """The 64 K entry image with levels.txt put at LevelData $B000 (an edited levels.txt is drawn as edited)."""
    img = bytearray(open(IMAGE, 'rb').read())
    data = res_formats.levels_in(open(LEVELS, 'rb').read())
    img[0xB000:0xB000 + len(data)] = data
    return img


def level_bytes(img, slot):
    a = 0xB000 + 0x87 * slot
    return list(img[a:a + 0x87])


def settings(img, slot):
    """LevelSettings $8385: (energy rate in frames a bar step, gremlin count)."""
    return img[0x8385 + 2 * slot], img[0x8386 + 2 * slot]


def counts(codes):
    """What a level holds, by kind (bit 7, the turning flag, aside; turning elements counted apart)."""
    k = {'cells': 0, 'mirrors': 0, 'turning': 0, 'cyan': 0, 'yellow': 0, 'absorbing': 0, 'reflecting': 0,
         'mines': 0, 'prisms': 0, 'fibres': 0}
    for c in codes:
        if c & 0x80 and c != 0x80:
            k['turning'] += 1
        v = c & 0x7F
        if v == 0x40:
            k['cells'] += 1
        elif 1 <= v <= 0x10:
            k['mirrors'] += 1
        elif 0x11 <= v <= 0x18:
            k['cyan'] += 1
        elif 0x19 <= v <= 0x20:
            k['yellow'] += 1
        elif 0x21 <= v <= 0x2F:
            k['absorbing'] += 1
        elif 0x30 <= v <= 0x3E:
            k['reflecting'] += 1
        elif v == 0x41:
            k['mines'] += 1
        elif v == 0x42:
            k['prisms'] += 1
        elif 0x50 <= v <= 0x57:
            k['fibres'] += 1
    return k


def attr_colours(a):
    br = 8 if a & 64 else 0
    return PAL[(a & 7) + br], PAL[((a >> 3) & 7) + br]


def char_image(img, code, scale=1):
    """One cell character as DrawMarkedChars $8A09 draws it: CellGraphics $D700 + 8 x code, CellColours $DF00 + code."""
    ink, paper = attr_colours(img[0xDF00 + code])
    im = Image.new('RGB', (8, 8))
    px = im.load()
    for k in range(8):
        b = img[0xD700 + 8 * code + k]
        for x in range(8):
            px[x, k] = ink if b & (0x80 >> x) else paper
    return im.resize((8 * scale, 8 * scale), Image.NEAREST) if scale > 1 else im


def cell_image(img, code, scale=1):
    """A cell code as RenderGrid $8960 draws it: the four characters of CellTable $8200 + 4 x code."""
    im = Image.new('RGB', (16, 16))
    t = 0x8200 + 4 * (code & 0x7F)
    for i in range(4):
        im.paste(char_image(img, img[t + i]), ((i & 1) * 8, (i >> 1) * 8))
    return im.resize((16 * scale, 16 * scale), Image.NEAREST) if scale > 1 else im


def play_area(img, slot):
    """The level drawn by the game's own BuildLevel $891A (SkoolKit's simulator, tools/level_maps.py): 256 x 160."""
    import level_maps
    m = level_maps.draw_level(img, slot)
    return level_maps.picture(m).crop((0, 0, 256, 160)), m


def screen_png(path):
    return Image.open(path).convert('RGB')


def text(d, xy, s, size=14, fill=FG, anchor=None):
    d.text(xy, s, font=font(size), fill=fill, anchor=anchor)


def sheet(items, cols, cell_w, cell_h, title=None, label_h=36, gap=10, width=1050, label_size=13, title_size=18,
          notes=None):
    """A labelled sheet: items are (PIL image, [label lines]); each image scaled to fit cell_w x cell_h."""
    rows = (len(items) + cols - 1) // cols
    top = 34 if title else 6
    nh = 0
    if notes:
        nh = 22 * len(notes) + 8
    h = top + rows * (cell_h + label_h + gap) + nh + 4
    out = Image.new('RGB', (width, h), BG)
    d = ImageDraw.Draw(out)
    if title:
        text(d, (10, 8), title, title_size, ACCENT)
    x0 = (width - cols * cell_w - (cols - 1) * gap) // 2
    for i, (im, labels) in enumerate(items):
        r, c = divmod(i, cols)
        x = x0 + c * (cell_w + gap)
        y = top + r * (cell_h + label_h + gap)
        s = min(cell_w / im.width, cell_h / im.height)
        im2 = im.resize((int(im.width * s), int(im.height * s)), Image.NEAREST)
        out.paste(im2, (x + (cell_w - im2.width) // 2, y))
        for j, ln in enumerate(labels):
            text(d, (x + 2, y + im2.height + 3 + j * (label_size + 3)), ln, label_size, FG if j == 0 else DIM)
    if notes:
        y = top + rows * (cell_h + label_h + gap)
        for j, n in enumerate(notes):
            text(d, (10, y + j * 22), n, 13, DIM)
    return out

"""Shared drawing helpers of the Myth case's doc figures (tools/fig_*.py).

Every figure is 1050 px wide, on the kit's dark background, with TrueType text of at least 13 px (10 pt and more at
900 px). The helpers: a canvas with a title and a subtitle, a sheet of screenshots with captions, a box with a label,
the listing of a build read by address, and the stage images.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

W = 1050
BG, PANEL, TEXT, DIM, HI = (20, 20, 26), (32, 32, 42), (235, 235, 235), (170, 170, 182), (255, 220, 90)
COLOURS = kitlib.ROUTINE_COLOURS
F = kitlib.font


def P(*parts):
    return os.path.join(CASE, *parts)


def canvas(height, title=None, sub=None, width=W):
    im = Image.new('RGB', (width, height), BG)
    d = ImageDraw.Draw(im)
    y = 12
    if title:
        d.text((16, y), title, font=F(19), fill=TEXT)
        y += 28
    if sub:
        for line in sub.split('\n'):
            d.text((16, y), line, font=F(13), fill=DIM)
            y += 18
    return im, d, y + 6


def save(im, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    im.save(out, optimize=True)
    print(out, im.size)


def text_width(d, text, size):
    return d.textlength(text, font=F(size))


def sheet(items, out, title, sub=None, cols=3, cap_lines=2):
    """items: (image path or PIL image, caption) pairs; each screen scaled to the column width."""
    gap = 10
    cw = (W - 2 * 16 - (cols - 1) * gap) // cols
    ch = cw * 3 // 4
    caph = 18 * cap_lines + 6
    rows = (len(items) + cols - 1) // cols
    head = 40 + (18 * len(sub.split('\n')) if sub else 0) + 10
    im, d, y0 = canvas(head + rows * (ch + caph + gap) + 10, title, sub)
    for i, (src, cap) in enumerate(items):
        x = 16 + (i % cols) * (cw + gap)
        y = y0 + (i // cols) * (ch + caph + gap)
        s = src if isinstance(src, Image.Image) else Image.open(src).convert('RGB')
        im.paste(s.resize((cw, ch), Image.NEAREST if s.width <= cw else Image.LANCZOS), (x, y))
        for k, line in enumerate(cap.split('\n')[:cap_lines]):
            d.text((x, y + ch + 4 + 18 * k), line, font=F(13), fill=TEXT if k == 0 else DIM)
    save(im, out)


def rec_screen(rec, frame):
    """A screen the recording tool saved (work/stage2/rec/REC/screens/FFFFFF[-what].png, 512 x 384)."""
    folder = P('work', 'stage2', 'rec', rec, 'screens')
    for name in sorted(os.listdir(folder)):
        if name.startswith('%06d' % frame):
            return os.path.join(folder, name)
    raise SystemExit(f'no screen {frame} in {folder}')


def listing(part):
    """{address: (bytes, text)} of build/PART.lst (sjasmplus listing), labels kept as their own rows."""
    rows = []
    rx = re.compile(r'^\s*\d+\+?\s+([0-9A-F]{4})\s((?:[0-9A-F]{2}\s)*)\s*(.*)$')
    with open(P('build', part + '.lst')) as f:
        for line in f:
            m = rx.match(line.rstrip('\n'))
            if m:
                rows.append((int(m.group(1), 16), m.group(2).split(), m.group(3)))
    return rows


def zx_colour(index, bright=False):
    return kitlib.ink_colour(index, bright)

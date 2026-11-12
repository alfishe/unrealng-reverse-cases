#!/usr/bin/env python3
"""Shared helpers of the case's documentation figures (fig_overview, fig_loop, fig_keys, fig_graphics, fig_text).

Memory comes from two places:

- the image `work/mkgame/original.bin` (the 64 K the loader leaves: code, graphics, music), for what never changes;
- a recording, read with TTD `memory_at` from the unreal-ng instance that holds it (`re_session.py open`), for
  what the menu builds at run time (the rhombus phases, ScreenCopy, the stars). A 64 K dump of a moment is kept in
  `work/docs/figcache/` so a figure can be drawn again without the instance.
"""
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(CASE, '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

WIDTH = 1050
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
ACCENT = (240, 200, 70)


def image():
    """The 64 K image the loader leaves"""
    with open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb') as f:
        return f.read()


def moment(work, frame):
    """64 K of a recording at FRAME[:T] (memory_at), cached in work/docs/figcache/"""
    cache = os.path.join(CASE, 'work', 'docs', 'figcache')
    name = os.path.basename(os.path.normpath(os.path.dirname(os.path.join(work, 'session.json'))))
    path = os.path.join(cache, f'{name}-{str(frame).replace(":", "_")}.bin')
    if os.path.isfile(path):
        with open(path, 'rb') as f:
            return f.read()
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)
    f, _, t = str(frame).partition(':')
    data = bytearray()
    for off in range(0, 0x10000, 0x4000):
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': int(f), 'offset': off, 'length': 0x4000}
        if t:
            body['tinframe'] = int(t)
        r = session.call('time_travel', body, ok=False)
        if r.is_error or not (r.structured or {}).get('exact', False):
            raise SystemExit(f'memory_at {frame}: {r.text}')
        data += bytes.fromhex(r.structured['hex'])
    os.makedirs(cache, exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)
    return bytes(data)


def font(size=13):
    return K.font(size)


def screen(mem, base=0x4000):
    return K.render_screen(mem, base)


def sprite(data, w, h, ink=(230, 230, 230), paper=(0, 0, 0), scale=1):
    """A mono sprite stored row by row, w / 8 bytes a row, bit 7 leftmost"""
    img = Image.new('RGB', (w, h), paper)
    px = img.load()
    bw = w // 8
    for y in range(h):
        for x in range(w):
            if data[y * bw + x // 8] & (0x80 >> (x % 8)):
                px[x, y] = ink
    return img.resize((w * scale, h * scale), Image.NEAREST) if scale != 1 else img


def canvas(height, width=WIDTH):
    img = Image.new('RGB', (width, height), BG)
    return img, ImageDraw.Draw(img)


def title(draw, text, sub=None, y=10):
    draw.text((12, y), text, fill=TEXT, font=font(16))
    if sub:
        draw.text((12, y + 24), sub, fill=DIM, font=font(12))


def grid(img, cell_px, colour=(60, 60, 75), x0=0, y0=0, w=None, h=None):
    d = ImageDraw.Draw(img)
    w = w or img.width
    h = h or img.height
    for x in range(x0, x0 + w + 1, cell_px):
        d.line([(x, y0), (x, y0 + h)], fill=colour)
    for y in range(y0, y0 + h + 1, cell_px):
        d.line([(x0, y), (x0 + w, y)], fill=colour)


def save(img, path):
    path = os.path.join(CASE, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(path, img.size)

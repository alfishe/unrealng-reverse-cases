#!/usr/bin/env python3
"""Doc 03's figures: the tape in time and in memory, and the decryption chain's 119 rewrite loops.

    python3 tools/fig_load.py tape docs/img/load/tape.png [build/orig/r-type.tzx]
    python3 tools/fig_load.py layers docs/img/load/layers.png work/docs/rtA/layers.txt

tape: top, the whole tape in time (tools/tzxblocks.py's timings at 3.5 MHz, the pauses included), one bar a block,
coloured by kind; bottom, each SpeedLock data block and the level pair as a row: its TZX number, its size, and where
its bytes land in the 64 K (DEST below, from c1's stages and the reader's block tables, docs/03-build-and-load.md 3.1).

layers: the output of `tools/speedlock7.py layers build/basic.bin` (one line a rewrite loop: index, the loop's
address, its kind, the bytes it rewrites); one row a loop, the bar from the byte after the loop to $FEE7.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import tzxblocks  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

W = 1050
KIND = {'rom': (110, 150, 230), 'tone': (90, 90, 110), 'sl7': (240, 150, 70), 'mark': (240, 230, 120),
        'turbo': (150, 210, 110), 'pause': (45, 45, 55)}
# TZX block: (where it lands, what) for the SpeedLock data blocks and the first level pair
DEST = {2: (0x5CCB, 0x700F, 'the BASIC + chain'), 7: (0xFEE8, 0xFFD0, 'Stage2Start'),
        13: (0x4000, 0x57FF, 'the screen'), 15: (0x8000, 0x82FF, 'the attributes'),
        17: (0x9710, 0xC4AD, 'game, XOR $92'), 19: (0xFD7F, 0xFD80, 'a store key'),
        21: (0xFDB3, 0xFDB6, 'the last store'), 23: (0xFF49, 0xFF7F, 'BlockTable2'),
        25: (0x7000, 0x970F, 'game, XOR $92'), 27: (0xC544, 0xE7CC, 'game top'),
        29: (0xFE40, 0xFEB2, 'Decipher'), 31: (0xFEFC, 0xFF2C, 'Stage2End'), 33: (0x61A8, 0x61C8, 'Tail'),
        35: (0x61C9, 0x61D7, 'the tail\'s rest'), 39: (0x6000, 0x6011, 'level 1 header'),
        40: (0xC4AE, 0xF859, 'level 1 body')}


def kind_of(b):
    k = b['kind']
    if k == 'standard':
        return 'rom'
    if k in ('pure tone', 'pulses'):
        return 'tone'
    if k == 'pure data':
        return 'mark' if len(b['data']) == 1 or (len(b['data']) == 3 and b['data'][0] == 7) else 'sl7'
    if k == 'turbo':
        return 'turbo'
    return None


def tape(out, path):
    blocks = list(tzxblocks.parse(open(path, 'rb').read()))
    f_big, f, fs = K.font(16), K.font(13), K.font(12)
    rows = [b for b in blocks if b['index'] in DEST]
    H = 252 + len(rows) * 24 + 50
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), "R-Type's tape: 11 minutes, three parts", fill=K.TEXT, font=f_big)
    d.text((14, 34), 'Top: the whole tape in time, pauses dark. Below: where each loaded block lands (to scale).',
           fill=K.DIM, font=f)
    # the time strip
    spans, t = [], 0.0
    for b in blocks:
        s = tzxblocks.seconds(b)
        k = kind_of(b)
        if k and s:
            spans.append((t, t + s, k, b['index']))
        t += s
        if b.get('pause'):
            spans.append((t, t + b['pause'] / 1000, 'pause', b['index']))
            t += b['pause'] / 1000
    total = t
    x0, x1, y = 60, W - 20, 80
    px = lambda s: x0 + s * (x1 - x0) / total  # noqa: E731
    for a, b_, k, _ in spans:
        d.rectangle((px(a), y, max(px(a) + 1, px(b_) - 1), y + 34), fill=KIND[k])
    for s in range(0, int(total) + 1, 60):
        d.line((px(s), y + 36, px(s), y + 42), fill=K.DIM)
        d.text((px(s) - 10, y + 44), f'{s // 60}m', fill=K.DIM, font=fs)
    d.text((10, y + 10), 'time', fill=K.DIM, font=fs)
    marks = [(0, 'BASIC'), (37, 'SpeedLock 7: 13 data blocks'), (300, 'eight levels, each a header + a body')]
    for s, label in marks:
        d.text((px(s) + 2, y - 18), label, fill=K.TEXT, font=fs)
    t_sl7 = sum(tzxblocks.seconds(b) + b.get('pause', 0) / 1000 for b in blocks if b['index'] <= 36)
    d.text((14, y + 64), f'The loader part ends at {t_sl7:.0f} s; the whole tape plays for {total:.0f} s '
           f'(pauses included).', fill=K.DIM, font=fs)
    d.text((14, y + 82), 'Colours: blue ROM speed, grey pilot tones, orange SpeedLock data, yellow its marks, '
           'green turbo (the levels).', fill=K.DIM, font=fs)
    # the destinations
    y0 = 222
    lx, mx0, mx1 = 14, 330, W - 20
    pm = lambda a: mx0 + a * (mx1 - mx0) / 0x10000  # noqa: E731
    for a in range(0, 0x10001, 0x4000):
        d.line((pm(a), y0 - 6, pm(a), H - 40), fill=(50, 50, 60))
        d.text((pm(a) - 20, y0 - 22), '$%04X' % min(a, 0xFFFF), fill=K.DIM, font=fs)
    for i, b in enumerate(rows):
        lo, hi, what = DEST[b['index']]
        yy = y0 + 4 + i * 24
        k = kind_of(b)
        d.text((lx, yy), f"TZX {b['index']:2d}  {len(b['data']):5d} B  {what}", fill=K.TEXT, font=f)
        d.rectangle((pm(lo), yy + 2, max(pm(lo) + 3, pm(hi + 1)), yy + 16), fill=KIND[k])
        lx_ = pm(hi + 1) + 6 if pm(hi + 1) + 50 < mx1 else pm(lo) - 46
        d.text((lx_, yy + 1), '$%04X' % lo, fill=K.DIM, font=fs)
    d.text((14, H - 30), 'Block 2 is the BASIC (ROM speed); blocks 39-40 stand for each level pair. The marks (3 bytes) '
           'and block 6 land nowhere: the reader checks them.', fill=K.DIM, font=fs)
    im.save(out)


def layers(out, path):
    rows = []
    for line in open(path):
        m = re.match(r'\s*(\d+) \$([0-9A-F]{4}) (\w+)\s+(\d+) bytes', line)
        if m:
            rows.append((int(m.group(1)), int(m.group(2), 16), m.group(3), int(m.group(4))))
    col = {'add': (90, 200, 120), 'sub': (110, 150, 230), 'xor': (240, 150, 70), 'pop': (200, 110, 230),
           'inc': (240, 230, 120), 'dec': (240, 90, 80)}
    f_big, f, fs = K.font(16), K.font(13), K.font(12)
    rh = 5
    y0 = 92
    H = y0 + len(rows) * rh + 90
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The chain: 119 rewrite loops, each over everything after it', fill=K.TEXT, font=f_big)
    d.text((14, 34), 'One row a loop, top to bottom in the order they run (c1 frames 2083-2398). The bar: the bytes '
           'it rewrites, up to $FEE7.', fill=K.DIM, font=f)
    x0, x1 = 80, W - 20
    px = lambda a: x0 + (a - 0xEC00) * (x1 - x0) / 0x12E8  # noqa: E731
    for a in range(0xEC00, 0xFF00, 0x0400):
        d.line((px(a), y0 - 6, px(a), H - 80), fill=(50, 50, 60))
        d.text((px(a) - 20, y0 - 22), '$%04X' % a, fill=K.DIM, font=fs)
    d.line((px(0xFB7E), y0 - 6, px(0xFB7E), H - 64), fill=K.TEXT)
    d.text((px(0xFB7E) - 110, H - 62), 'SL7Start $FB7E', fill=K.TEXT, font=fs)
    for i, (n, a, k, ln) in enumerate(rows):
        y = y0 + i * rh
        d.rectangle((px(0xFEE8 - ln), y, px(0xFEE8), y + rh - 2), fill=col[k])
        d.rectangle((px(a) - 1, y, px(a) + 1, y + rh - 2), fill=K.TEXT)
        if n % 10 == 0:
            d.text((14, y - 5), f'loop {n}', fill=K.DIM, font=fs)
    cx = 14
    counts = {k: sum(1 for r in rows if r[2] == k) for k in col}
    for k in col:
        name = f'{k} ({counts[k]})'
        d.rectangle((cx, H - 46, cx + 16, H - 34), fill=col[k])
        d.text((cx + 22, H - 49), name, fill=K.TEXT, font=f)
        cx += 40 + d.textlength(name, font=f)
    d.text((14, H - 26), 'White tick: the loop itself. Every loop rewrites all that follows it, so a byte near $FEE7 '
           'is rewritten up to 119 times.', fill=K.DIM, font=fs)
    im.save(out)


if __name__ == '__main__':
    a = sys.argv[1:]
    if not a or a[0] not in ('tape', 'layers'):
        print(__doc__)
    elif a[0] == 'tape':
        tape(a[1], a[2] if a[2:] else os.path.join(CASE, 'build', 'orig', 'r-type.tzx'))
    else:
        layers(a[1], a[2])

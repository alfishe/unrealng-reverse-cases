#!/usr/bin/env python3
"""Doc 02's figures: the memory map at three moments, and the game's modules from src/game/game.ann.

    python3 tools/fig_arch.py memory docs/img/arch/memory-map.png
    python3 tools/fig_arch.py modules docs/img/arch/modules.png

memory: the 64 K at the entry $85FD (c1 frame 11 700 T 1379, the loader's last step), in play on level 1 and in play
on level 5 (the shortest level but one); the bands are the ranges of docs/02-architecture.md 2.2, each level's
length from build/levelN.bin and its own code from src/levelN/levelN.ann.

modules: one row a game.ann module (the @module of the entries it holds), its range, its size and a bar to scale
over $7000-$FFFF.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

W = 1090
COL = {'rom': (90, 90, 100), 'screen': (70, 160, 220), 'buffer': (60, 110, 150), 'code': (90, 200, 120),
       'data': (220, 170, 70), 'level': (200, 110, 230), 'levelcode': (240, 90, 160), 'sound': (240, 90, 80),
       'stack': (240, 230, 120), 'free': (45, 45, 55), 'loader': (200, 70, 60), 'basic': (120, 120, 140)}


def level_len(n):
    return os.path.getsize(os.path.join(CASE, 'build', f'level{n}.bin'))


def memory(out):
    l1 = 0xC4AE + level_len(1)
    l5 = 0xC4AE + level_len(5)
    common = [(0x0000, 0x3FFF, 'rom', 'the ROM'),
              (0x4000, 0x5AFF, 'screen', 'the screen'),
              (0x5B00, 0x5FFF, 'buffer', 'EntryCopy, BitReverse, shots'),
              (0x6000, 0x77FF, 'buffer', 'pixel shadow, texts, title code'),
              (0x7800, 0x7FFF, 'data', 'attributes, vars, SolidMap'),
              (0x8000, 0x85FC, 'data', 'rows, intro code, IM 2, enemies'),
              (0x85FD, 0xA5F6, 'code', 'the game code $85FD'),
              (0xA5F7, 0xBE22, 'data', 'Sprites, GameObjects'),
              (0xBE23, 0xC4AD, 'code', 'interrupt, keys, util')]
    entry = common[:2] + [(0x5B00, 0x5CCA, 'buffer', 'system variables'),
                          (0x5CCB, 0x6FFF, 'basic', 'the spent BASIC and loader'),
                          (0x7000, 0xC4AD, 'code', 'the game, XORed back'),
                          (0xC4AE, 0xDD17, 'free', 'zeros, loader leftovers'),
                          (0xDD18, 0xF817, 'data', 'TitleScreen'),
                          (0xF818, 0xF87B, 'free', ''),
                          (0xF87C, 0xFDA4, 'sound', 'the sound $F87C'),
                          (0xFDA5, 0xFF93, 'code', 'tail: LoadLevel $FE03'),
                          (0xFF94, 0xFFFF, 'stack', 'the stack')]
    tail = [(0xF87C, 0xFDA4, 'sound', 'the sound $F87C'), (0xFDA5, 0xFF93, 'code', 'tail: LoadLevel $FE03'),
            (0xFF94, 0xFFFF, 'stack', 'stack, low $FFCE (hiscore $FFC8)')]
    play1 = common + [(0xC4AE, l1 - 1, 'level', 'level 1, 13 228 bytes'), (0xF3A5, l1 - 1, 'levelcode', ''),
                      (l1, 0xF87B, 'free', '')] + tail
    play5 = common + [(0xC4AE, l5 - 1, 'level', 'level 5, 8904 bytes'), (0xE1E8, l5 - 1, 'levelcode', ''),
                      (l5, 0xF87B, 'free', 'the previous level, stale')] + tail
    cols = [('at the entry (c1 11 700)', entry), ('in play, level 1', play1), ('in play, level 5', play5)]
    f_big, f, fs = K.font(16), K.font(13), K.font(12)
    H = 860
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'R-Type in the 48K: the game proper stays, a level replaces the level space $C4AE', fill=K.TEXT,
           font=f_big)
    d.text((14, 34), 'Bands to scale, $0000 at the top. Pink: a level\'s own code at its end. Ranges: doc 2, 2.2. Past level 5: level 4 stale.',
           fill=K.DIM, font=f)
    y0, y1 = 90, H - 60
    ax = 70
    colw, gap = 80, 255
    py = lambda a: y0 + a * (y1 - y0) / 0x10000  # noqa: E731
    for a in range(0, 0x10001, 0x2000):
        d.line((ax - 6, py(a), ax, py(a)), fill=K.DIM)
        d.text((10, py(a) - 7), '$%04X' % min(a, 0xFFFF), fill=K.DIM, font=fs)
    for i, (title, bands) in enumerate(cols):
        x = ax + i * (colw + gap)
        d.text((x, 66), title, fill=K.TEXT, font=f)
        for lo, hi, kind, label in bands:
            d.rectangle((x, py(lo), x + colw, max(py(lo), py(hi + 1) - 1)), fill=COL[kind])
        ly = -100
        for lo, hi, kind, label in bands:
            if not label:
                continue
            mid = (py(lo) + py(hi + 1)) / 2
            ty = max(mid - 7, ly + 15)
            d.line((x + colw, mid, x + colw + 8, ty + 7), fill=K.DIM)
            d.text((x + colw + 10, ty), label, fill=K.TEXT, font=fs)
            ly = ty
    keys = [('code', 'code'), ('data', 'data and variables'), ('buffer', 'buffers'), ('level', 'the level body'),
            ('levelcode', "the level's own code"), ('sound', 'sound'), ('stack', 'stack'), ('free', 'unused now')]
    cx = 14
    for k, name in keys:
        d.rectangle((cx, H - 34, cx + 16, H - 22), fill=COL[k])
        d.text((cx + 22, H - 37), name, fill=K.TEXT, font=f)
        cx += 40 + d.textlength(name, font=f)
    im.save(out)


def ann_modules():
    mods, cur = [], None
    for line in open(os.path.join(CASE, 'src', 'game', 'game.ann')):
        m = re.match(r'@module (\w+)', line)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) ', line)
        if m and cur:
            mods.append((int(m.group(1), 16), cur))
            cur = None
    mods.sort()
    return [(a, (mods[i + 1][0] if i + 1 < len(mods) else 0x10000) - 1, n) for i, (a, n) in enumerate(mods)]


def modules(out):
    mods = ann_modules()
    f_big, f, fs = K.font(16), K.font(13), K.font(12)
    lw, x1 = 400, W - 20
    rh = 26
    y0 = 92
    H = y0 + len(mods) * rh + 40
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The game image $7000-$FFFF by module (src/game/game.ann, 17 modules)', fill=K.TEXT, font=f_big)
    d.text((14, 34), 'One row a module, in address order; the bar is its place in $7000-$FFFF, to scale.',
           fill=K.DIM, font=f)
    px = lambda a: lw + (a - 0x7000) * (x1 - lw) / 0x9000  # noqa: E731
    for a in range(0x7000, 0x10001, 0x1000):
        d.line((px(a), y0 - 8, px(a), H - 34), fill=(50, 50, 60))
        d.text((px(a) - 18, y0 - 26), '$%04X' % min(a, 0xFFFF), fill=K.DIM, font=fs)
    code = {'titlestate', 'intro', 'main', 'scroll', 'sprites', 'tapeload', 'waves', 'ship', 'interrupt', 'util',
            'sound', 'tail'}
    for i, (a, b, n) in enumerate(mods):
        y = y0 + i * rh
        colour = COL['code'] if n in code else COL['level'] if n == 'levelspace' else COL['data']
        d.text((14, y + 4), n, fill=K.TEXT, font=f)
        d.text((150, y + 4), '$%04X-$%04X  %5d bytes' % (a, b, b - a + 1), fill=K.DIM, font=f)
        d.rectangle((px(a), y + 4, max(px(a) + 2, px(b + 1) - 1), y + rh - 4), fill=colour)
    cx = 14
    for k, name in (('code', 'code (and the tables it keeps inline)'), ('data', 'texts, variables, graphics'),
                    ('level', 'the level space: each level loads here')):
        d.rectangle((cx, H - 26, cx + 16, H - 14), fill=COL[k])
        d.text((cx + 22, H - 29), name, fill=K.TEXT, font=f)
        cx += 50 + d.textlength(name, font=f)
    im.save(out)


if __name__ == '__main__':
    a = sys.argv[1:]
    {'memory': memory, 'modules': modules}.get(a[0] if a else '', lambda o: print(__doc__))(a[1] if a[1:] else None)

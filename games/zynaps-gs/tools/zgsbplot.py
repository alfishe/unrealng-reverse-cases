"""The look of the zgsB figure scripts (docs 07-10): matplotlib on the kit's dark palette (kit/kitlib.py), the
screen helpers they share, and the frame log of tools/gs_podbot.py (class Rec).
(The plot part is copied from the 48K case's tools/zybplot.py, the boxes from its tools/fig_weapons.py.)

gs_podbot.py's PREFIX.npz holds, every --step frames: frames (the bot's frame count), vars (the player record
$7F9C-$7FAB, $80E0-$80EF, FireHeld $8184, $7F62-$7F81: 65 bytes), objs (the 16 object records $F36C-$F62B, 704
bytes) and screen ($4000-$5AFF, 6912 bytes).
"""
import os
import sys

import matplotlib
import numpy as np
from PIL import Image, ImageDraw

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.normpath(os.path.join(CASE, '..', '..', 'kit')))
import kitlib as K  # noqa: E402

IMG = os.path.join(CASE, 'docs', 'img')


def rgb(c):
    return tuple(v / 255 for v in c)


BG, PANEL, TEXT, DIM = rgb(K.BACKGROUND), rgb(K.PANEL), rgb(K.TEXT), rgb(K.DIM)
COLOURS = [rgb(c) for c in K.ROUTINE_COLOURS]


def style():
    plt.rcParams.update({
        'figure.facecolor': BG, 'axes.facecolor': PANEL, 'savefig.facecolor': BG,
        'axes.edgecolor': DIM, 'axes.labelcolor': TEXT, 'xtick.color': TEXT, 'ytick.color': TEXT,
        'text.color': TEXT, 'axes.titlecolor': TEXT, 'grid.color': (0.25, 0.25, 0.3), 'font.size': 10,
        'axes.titlesize': 11, 'text.parse_math': False, 'legend.facecolor': PANEL, 'legend.edgecolor': DIM,
        'font.family': 'DejaVu Sans',
    })


def out(topic, name):
    d = os.path.join(IMG, topic)
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, name)


def save(fig, path):
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print('wrote', os.path.relpath(path, CASE), f'{os.path.getsize(path) // 1024} KB')


def saveimg(img, path):
    img.save(path)
    print('wrote', os.path.relpath(path, CASE), img.size)


def screen(mem, base=0x4000):
    """the 256 x 192 screen of a 64 K image (or of 6912 bytes at base), the game's colours, flash phase 0"""
    if len(mem) < 0x10000:
        img = bytearray(0x10000)
        img[0x4000:0x4000 + len(mem)] = mem
        mem = img
    return K.render_screen(mem, base)


# the frame log
P1, OBJ = 0x7F9C, 0xF36C
VAR_PARTS = [(0x7F9C, 16), (0x80E0, 16), (0x8184, 1), (0x7F62, 32)]
KINDS = {0: 'ship', 1: 'laser', 2: 'enemy', 3: 'explosion', 4: 'pod', 5: 'enemy shot', 6: 'sight', 7: 'seeker',
         8: 'lockable', 9: 'plasma', 10: 'missile', 11: 'enemy (11)', 12: 'big enemy'}
KIND_COLOUR = {0: (210, 210, 210), 2: (110, 160, 255), 11: (80, 120, 230), 1: (255, 240, 80), 3: (190, 140, 100),
               4: (80, 230, 110), 5: (255, 90, 90), 6: (90, 200, 255), 7: (255, 120, 220), 9: (255, 150, 60),
               10: (255, 60, 60), 8: (200, 110, 230), 12: (170, 90, 240)}
SIZES = {12: (72, 56), 1: (16, 6), 9: (8, 8), 10: (16, 8), 7: (16, 8), 6: (16, 16), 5: (8, 8), 4: (16, 13)}


class Rec:
    def __init__(self, path, name=None):
        d = np.load(path)
        self.F, self.V, self.O = d['frames'], d['vars'], d['objs']
        self.S = d['screen'] if 'screen' in d else None
        self.name = name or os.path.basename(os.path.dirname(os.path.abspath(path)))

    def var(self, addr):
        off = 0
        for a, n in VAR_PARTS:
            if a <= addr < a + n:
                return self.V[:, off + addr - a].astype(int)
            off += n
        raise KeyError(f'${addr:04X} is not in the frame log')

    def index(self, frame):
        return int(np.searchsorted(self.F, frame))

    def slot(self, i, s):
        return self.O[i, 44 * s:44 * s + 44]

    def active(self, i):
        out = []
        for s in range(16):
            r = self.slot(i, s)
            if r[8] & 0x80:
                out.append((s, int(r[7]), int(r[3]) | int(r[4]) << 8, int(r[5]) | int(r[6]) << 8))
        return out

    def screen_img(self, i, scale=2):
        img = screen(bytes(self.S[i]))
        return img.resize((256 * scale, 192 * scale), Image.NEAREST)


def box_of(kind, x, y, scale):
    """a record's box on the screen: X in columns of 8 pixels from column 16 (the screen's left edge), Y in rows of
    8 pixels from row -1 (playfield row 0 is screen row 1, under the score line); SIZES in pixels (24 x 16 for the
    ship and the enemies), checked against the screens"""
    px = (x / 256 - 16) * 8 * scale
    py = (y / 256 + 1) * 8 * scale
    w, h = SIZES.get(kind, (24, 16))
    return px, py, px + w * scale, py + h * scale


def boxes(img, rec, i, scale, only=None, label=True, slots=False):
    d = ImageDraw.Draw(img)
    f = K.font(9 * scale // 2 + 2)
    for s, kind, x, y in rec.active(i):
        if only is not None and kind not in only:
            continue
        col = KIND_COLOUR.get(kind, (230, 230, 230))
        x0, y0, x1, y1 = box_of(kind, x, y, scale)
        d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], outline=col, width=max(1, scale // 2))
        if label:
            text = (f'{s}:' if slots else '') + KINDS.get(kind, str(kind))
            d.text((x0, y1 + 3), text, fill=col, font=f)

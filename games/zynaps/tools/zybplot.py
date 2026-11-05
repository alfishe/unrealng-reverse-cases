"""The look of the zyB figure scripts (docs 07-10): matplotlib on the kit's dark palette (kit/kitlib.py), and the
screen helpers they share."""
import os
import sys

import matplotlib

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
        'axes.titlesize': 11, 'text.parse_math': False, 'legend.facecolor': PANEL, 'legend.edgecolor': DIM, 'font.family': 'DejaVu Sans',
    })


def out(topic, name):
    d = os.path.join(IMG, topic)
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, name)


def save(fig, path):
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print('wrote', os.path.relpath(path, CASE), f'{os.path.getsize(path) // 1024} KB')


def screen(mem, base=0x4000):
    """the 256 x 192 screen of a 64 K image (or of 6912 bytes at base), the game's colours, flash phase 0"""
    if len(mem) < 0x10000:
        img = bytearray(0x10000)
        img[0x4000:0x4000 + len(mem)] = mem
        mem = img
    return K.render_screen(mem, base)

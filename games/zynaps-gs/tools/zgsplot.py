"""The look of the zgsA figure scripts (docs 01-06): matplotlib on the kit's dark palette (kit/kitlib.py).
(Copied from the 48K case's tools/zybplot.py.)"""
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402,F401

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

"""Shared helpers of the docs-B figure scripts (docs 07-10): the look (matplotlib on the kit's dark palette), the game
image, the recordings' saved RAM, TTD memory reads, screens, and a model of the string printer PrintString $AF2B.

Nothing here draws a figure by itself; the fig_*.py scripts import it.
"""
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from PIL import Image  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402

IMG = os.path.join(CASE, 'docs', 'img')
WORK = os.path.join(CASE, 'work')
DOCB = os.path.join(WORK, 'docs', 'docB')


def rgb(c):
    return tuple(v / 255 for v in c)


BG, PANEL, TEXT, DIM = rgb(K.BACKGROUND), rgb(K.PANEL), rgb(K.TEXT), rgb(K.DIM)
COLOURS = [rgb(c) for c in K.ROUTINE_COLOURS]


def style():
    plt.rcParams.update({
        'figure.facecolor': BG, 'axes.facecolor': PANEL, 'savefig.facecolor': BG,
        'axes.edgecolor': DIM, 'axes.labelcolor': TEXT, 'xtick.color': TEXT, 'ytick.color': TEXT,
        'text.color': TEXT, 'axes.titlecolor': TEXT, 'grid.color': (0.25, 0.25, 0.3), 'font.size': 11,
        'axes.titlesize': 12, 'axes.labelsize': 11, 'xtick.labelsize': 10.5, 'ytick.labelsize': 10.5,
        'legend.fontsize': 10.5, 'text.parse_math': False, 'legend.facecolor': PANEL, 'legend.edgecolor': DIM,
        'font.family': 'DejaVu Sans', 'lines.linewidth': 1.6,
    })


# The case shows figures 900 px wide. Figures are drawn at most WIDTH inches (x 100 dpi = 1050 px) with no text
# below 10 pt, so every label stays at about 11 px or more at 900 px.
WIDTH = 10.5


def wrap(text, width=95):
    """Wraps a title so that it fits WIDTH inches at 13 pt (or a panel title at 12 pt with a smaller width)."""
    import textwrap
    return '\n'.join(textwrap.wrap(text, width))


def suptitle(fig, text, width=95):
    fig.suptitle(wrap(text, width), fontsize=13)


def out(topic, name):
    d = os.path.join(IMG, topic)
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, name)


def save(fig, path):
    fig.savefig(path, dpi=100)
    plt.close(fig)
    with Image.open(path) as im:
        size = im.size
    print('wrote', os.path.relpath(path, CASE), f'{size[0]}x{size[1]}', f'{os.path.getsize(path) // 1024} KB')


# --- the game image -------------------------------------------------------------------------------------------------

_IMAGE = None


def image():
    """the 64 K image as the loader's move leaves it (work/mkgame/original.bin: $6D60-$FFFF filled)"""
    global _IMAGE
    if _IMAGE is None:
        _IMAGE = open(os.path.join(WORK, 'mkgame', 'original.bin'), 'rb').read()
    return _IMAGE


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


def s8(v):
    return v - 256 if v > 127 else v


# --- recordings -----------------------------------------------------------------------------------------------------

def snapshot_frames(rec):
    d = os.path.join(WORK, rec, 'snapshots')
    return sorted(int(n) for n in os.listdir(d) if n.isdigit()) if os.path.isdir(d) else []


def snapshot_ram(rec, frame):
    """the 64 K CPU view at a saved snapshot of a recording (48K / 128K with the game's pages: 5, 2, 0)"""
    d = os.path.join(WORK, rec, 'snapshots', f'{frame:06d}')
    mem = bytearray(0x10000)
    for base, page in ((0x4000, 5), (0x8000, 2), (0xC000, 0)):
        mem[base:base + 0x4000] = open(os.path.join(d, f'ram-{page}.bin'), 'rb').read()
    return bytes(mem)


def session(work):
    import exlib
    return exlib.session(work)


def ttd_load(s, path):
    r = s.call('time_travel', {'action': 'load', 'path': os.path.abspath(path)}, ok=False)
    first = (r.text or '').splitlines()[0] if r.text else ''
    if r.is_error:
        raise RuntimeError(first)
    return first


def read(s, frame, lo, n, tinframe=None):
    import exlib
    return exlib.read(s, frame, lo, n, tinframe)


# --- screens --------------------------------------------------------------------------------------------------------

def screen(mem, base=0x4000, flash=0):
    """the 256 x 192 screen of a 64 K memory (or of 6912 bytes) in the game's colours, flash phase 0"""
    if len(mem) < 0x10000:
        img = bytearray(0x10000)
        img[base:base + len(mem)] = mem
        mem = img
    return K.render_screen(mem, base)


def scr_file(path):
    data = open(path, 'rb').read()
    return screen(data[:6912])


def zoom(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def ink(index, bright):
    return K.ink_colour(index, bright)


# --- PrintString $AF2B as a model -----------------------------------------------------------------------------------

class Canvas:
    """the cells a string prints: (row, column) -> (glyph bytes, attribute, cell type, empty mark); the codes it ran"""

    def __init__(self, mem):
        self.mem = mem
        self.cells = {}
        self.log = []      # (address, code bytes, kind, text)

    def put(self, d, e, ch, font, c, ctype, mark):
        if e & 0x20:       # PrintChar's clip: columns 32-63 and the negative ones
            return
        a = (font + 8 * ch) & 0xFFFF
        self.cells[(s8(d & 0xFF), e & 0xFF)] = (bytes(self.mem[a:a + 8]), c, ctype, mark)


KINDS = ['glyph', 'move', 'new line', 'ink', 'at', 'attribute', 'repeat', 'repeat end', 'call', 'run across',
         'run down', 'glyph set', 'space', 'cell type', 'drawn', 'empty', 'mark cell', 'end']


def code_kind(a):
    if a < 0x61:
        return 'glyph'
    if a < 0x90:
        return 'move'
    if a < 0xCF:
        return 'new line'
    if a < 0xDF:
        return 'ink'
    return {0xDF: 'at', 0xE0: 'attribute', 0xE1: 'repeat', 0xE2: 'repeat end', 0xE3: 'call', 0xE4: 'run across',
            0xE5: 'run down', 0xE6: 'glyph set', 0xE7: 'space', 0xE8: 'cell type', 0xE9: 'drawn', 0xEA: 'empty',
            0xEB: 'mark cell'}.get(a, 'end')


def print_string(cv, hl, d, e, c, st, depth=0):
    """runs the string at hl as $AF2B does (plot mode 0); st: font, ctype, mark (the operands $ADEF, $AE1B, $AE21)"""
    M = cv.mem
    stack = []
    while True:
        at = hl
        a = M[hl]
        hl += 1
        k = code_kind(a)
        if k == 'glyph':
            cv.put(d, e, a, st['font'], c, st['ctype'], st['mark'])
            e += 1
            cv.log.append((at, 1, k, depth))
        elif k == 'move':
            d += a - 0x78
            e += s8(M[hl])
            hl += 1
            cv.log.append((at, 2, k, depth))
        elif k == 'new line':
            d += 1
            e += a - 0xAF
            cv.log.append((at, 1, k, depth))
        elif k == 'ink':
            n = a - 0xCF
            b = n if n < 8 else (n - 8) | 0x40
            c = (c & 0x38) | b
            cv.log.append((at, 1, k, depth))
        elif k == 'at':
            d, e = M[hl], M[hl + 1]
            hl += 2
            cv.log.append((at, 3, k, depth))
        elif k == 'attribute':
            c = M[hl]
            hl += 1
            cv.log.append((at, 2, k, depth))
        elif k == 'repeat':
            stack.append([hl + 1, M[hl], c])
            hl += 1
            cv.log.append((at, 2, k, depth))
        elif k == 'repeat end':
            top = stack[-1]
            top[1] = (top[1] - 1) & 0xFF
            c = top[2]
            cv.log.append((at, 1, k, depth))
            if top[1] == 0:
                stack.pop()
            else:
                hl = top[0]
        elif k == 'call':
            cv.log.append((at, 3, k, depth))
            print_string(cv, word(M, hl), d, e, c, st, depth + 1)
            hl += 2
        elif k == 'run across':
            for _ in range(M[hl] or 256):
                cv.put(d, e, M[hl + 1], st['font'], c, st['ctype'], st['mark'])
                e += 1
            hl += 2
            cv.log.append((at, 3, k, depth))
        elif k == 'run down':
            for _ in range(M[hl] or 256):
                cv.put(d, e, M[hl + 1], st['font'], c, st['ctype'], st['mark'])
                d += 1
            hl += 2
            cv.log.append((at, 3, k, depth))
        elif k == 'glyph set':
            st['font'] = word(M, hl)
            hl += 2
            cv.log.append((at, 3, k, depth))
        elif k == 'space':
            cv.put(d, e, 0x20, 0xD7E0, c, st['ctype'], st['mark'])
            e += 1
            cv.log.append((at, 1, k, depth))
        elif k == 'cell type':
            st['ctype'] = M[hl]
            hl += 1
            cv.log.append((at, 2, k, depth))
        elif k == 'drawn':
            st['mark'] = 0
            cv.log.append((at, 1, k, depth))
        elif k == 'empty':
            st['mark'] = 0xFF
            cv.log.append((at, 1, k, depth))
        elif k == 'mark cell':
            if st.get('marks') is not None:
                st['marks'].append((s8(d & 0xFF), e & 0xFF, M[hl]))
            hl += 1
            cv.log.append((at, 2, k, depth))
        else:
            cv.log.append((at, 1, k, depth))
            return hl


def render_cells(cells, rows=24, cols=32, r0=0, c0=0):
    """the cells as a 1x picture (8 pixels a cell)"""
    im = Image.new('RGB', (cols * 8, rows * 8), (0, 0, 0))
    px = im.load()
    for (r, cc), (g, at, _, _) in cells.items():
        r -= r0
        cc -= c0
        if not (0 <= r < rows and 0 <= cc < cols):
            continue
        bright = at & 0x40
        fg, bg = ink(at & 7, bright), ink(at >> 3 & 7, bright)
        for y in range(8):
            for x in range(8):
                px[cc * 8 + x, r * 8 + y] = fg if g[y] >> (7 - x) & 1 else bg
    return im


ELEMENTS = 0x852E
SCREENS = 0xC7F4


def element_address(n, mem=None):
    return word(mem or image(), ELEMENTS + 2 * n)


def screen_list(n, mem=None):
    mem = mem or image()
    hl = word(mem, SCREENS + 2 * n)
    out = []
    while mem[hl] != 0xFF:
        out.append((mem[hl], mem[hl + 1], mem[hl + 2]))
        hl += 3
    return out


def build_screen(n, mem=None):
    """screen n as BuildScreen prints it: the canvas and the $EB marks (row, column, kind)"""
    mem = mem or image()
    cv = Canvas(mem)
    st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
    for d, e, el in screen_list(n, mem):
        st['ctype'] = 1
        st['mark'] = 0
        print_string(cv, element_address(el, mem), d, e, 0, st)
    return cv, st['marks']


def font(size=12):
    return K.font(size)

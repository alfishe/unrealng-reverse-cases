#!/usr/bin/env python3
"""Doc 03's tape figure, from the original TAP (no emulator):

  python3 tools/fig_tape.py

docs/img/load/tape.png: the six blocks of orig/Bumpy.tap.zip's BUMPY.TAP on a time line at ROM speed (each block's
time from its length: the pilot of 8063 or 3223 pulses of 2168 T, the two sync pulses, 8 bits a byte of 855 T a half
for a 0 and 1710 T for a 1, at 3.5 MHz), and below it where each data block lands in the 64 K, with the loading
screen as it arrives in block 3.
"""
import io
import os
import zipfile

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from PIL import Image  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'load')
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'
CLOCK = 3500000


def blocks():
    raw = zipfile.ZipFile(os.path.join(CASE, 'orig/Bumpy.tap.zip')).read('BUMPY.TAP')
    out, i = [], 0
    while i < len(raw):
        n = raw[i] | raw[i + 1] << 8
        out.append(raw[i + 2:i + 2 + n])
        i += 2 + n
    return out


def seconds(block):
    pilot = 8063 if block[0] < 128 else 3223
    t = pilot * 2168 + 667 + 735
    for b in block:
        for k in range(8):
            t += 2 * (1710 if (b >> (7 - k)) & 1 else 855)
    return t / CLOCK


def main():
    bl = blocks()
    names = ['header "BUMPY" (Program, LINE 10)', 'the BASIC, 191 bytes', 'header "BUMPY.SCR" (Bytes)',
             'the loading screen, 6912 bytes', 'header "BUMPY.CDE" (Bytes, 25000)', 'the game, 38 700 bytes']
    cols = ['#787887', '#5ac878', '#787887', '#5a96fa', '#787887', '#f0c846']
    fig = plt.figure(figsize=(10.5, 6.6), dpi=100, facecolor=BG)
    a = fig.add_axes([0.04, 0.62, 0.92, 0.28])
    t0, total = 0.0, 0.0
    small = []
    for k, b in enumerate(bl):
        s = seconds(b)
        a.barh(0, s, left=t0, color=cols[k], edgecolor=BG, height=0.6)
        if s > 30:
            a.text(t0 + s / 2, 0, (f'{k}: {names[k]}' if s > 100 else f'{k}: the screen') + f'\n{s:.1f} s', ha='center', va='center', fontsize=10,
                   color='black')
        else:
            a.text(t0 + s / 2, 0.42, str(k), ha='center', va='bottom', fontsize=10, color=TEXT)
            small.append(f'{k}: {names[k]}, {s:.1f} s')
        t0 += s
    a.text(60, -0.62, '   '.join(small[:2]) + '\n' + '   '.join(small[2:]), fontsize=10, color=TEXT, va='center')
    total = t0
    a.set_xlim(0, total + 2)
    a.set_ylim(-1, 1)
    a.set_yticks([])
    a.set_xlabel('seconds at ROM speed (pauses between the blocks not counted)', color=TEXT, fontsize=10)
    a.tick_params(colors=TEXT, labelsize=10)
    a.set_facecolor(PANEL)
    for s in a.spines.values():
        s.set_color(DIM)
    a.set_title(f'BUMPY.TAP: six standard ROM blocks, {total:.1f} s, no custom loader', color=TEXT, fontsize=12)
    m = fig.add_axes([0.04, 0.1, 0.62, 0.36])
    m.set_facecolor(PANEL)
    regions = [(0x0000, 0x4000, 'ROM', '#3a3a48'), (0x4000, 0x5B00, 'screen', '#5a96fa'),
               (0x5CCB, 0x5D8A, 'block 1: BASIC', '#5ac878'), (0x6170, 0x6190, 'stack', '#e65a50'),
               (0x61A8, 0xF8D5, 'block 5: the game $61A8-$F8D4, entry $AB7C', '#f0c846')]
    for lo, hi, lab, c in regions:
        m.barh(0, hi - lo, left=lo, color=c, height=0.6)
    for lo, hi, lab, c in regions:
        if hi - lo > 6000 and lab != 'screen':
            m.text((lo + hi) / 2, 0, lab.replace('$', r'\$'), ha='center', va='center', fontsize=10, color='black')
    m.annotate('block 1: BASIC at \\$5CCB', (0x5D20, 0.3), (0x6400, 0.75), fontsize=10, color=TEXT,
               arrowprops=dict(arrowstyle='-', color=DIM))
    m.annotate('stack \\$6170-\\$618F', (0x6180, -0.3), (0x4800, -0.8), fontsize=10, color=TEXT,
               arrowprops=dict(arrowstyle='-', color=DIM))
    m.annotate('the screen \\$4000', (0x4D00, 0.3), (0x0800, 0.75), fontsize=10, color=TEXT,
               arrowprops=dict(arrowstyle='-', color=DIM))
    m.set_xlim(0, 0x10000)
    m.set_ylim(-1.1, 1.1)
    m.set_yticks([])
    m.set_xticks(range(0, 0x10001, 0x4000))
    m.set_xticklabels([f'\\${x:04X}' for x in range(0, 0x10001, 0x4000)], fontsize=10, color=TEXT)
    m.tick_params(colors=TEXT)
    for s in m.spines.values():
        s.set_color(DIM)
    m.set_title('where the data blocks land', color=TEXT, fontsize=11)
    sc = Image.open(os.path.join(CASE, 'src/res/screens/loading.png')).convert('RGB')
    s_ax = fig.add_axes([0.7, 0.04, 0.28, 0.5])
    s_ax.imshow(sc, interpolation='nearest')
    s_ax.set_xticks([])
    s_ax.set_yticks([])
    s_ax.set_title('block 3, the loading screen', color=TEXT, fontsize=10)
    os.makedirs(OUT, exist_ok=True)
    fig.savefig(os.path.join(OUT, 'tape.png'), facecolor=BG)
    print('tape.png', [len(b) for b in bl], round(total, 1))


if __name__ == '__main__':
    main()

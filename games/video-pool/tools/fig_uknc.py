#!/usr/bin/env python3
"""Figures of doc 14 (porting to the UKNC).

    python3 tools/uknc_convert.py                 # first: the converted resources in work/docs/vpD/uknc
    python3 tools/fig_uknc.py balls [--conv work/docs/vpD/uknc]
    python3 tools/fig_uknc.py budget

balls: the converted ball sheet as the UKNC would show it (decoded from balls16.bin, bit 0 = the leftmost pixel,
320-pixel mode, each pixel 1.2 times as wide as high on a 4:3 screen), next to the Spectrum sheet it came from.
budget: one tick of the game (aiming, one ball, six balls, the heaviest) in Z80 T-states against the frame, and the
same work estimated on the UKNC's two processors (doc 14, 14.3; the numbers are passed in BUDGET below).
"""
import argparse
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import uknc_convert as U  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'uknc')
WIDTH, DPI = 10.5, 100
plt.rcParams.update({'font.size': 11, 'font.family': 'DejaVu Sans'})
# grid, paper (UKNC colour 2: green), ink (UKNC colour 0: black), word boundary
CMAP = ListedColormap(['#9a9a9a', '#00a000', '#000000', '#d0d000'])


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=DPI)
    plt.close(fig)
    print(path)


def cmd_balls(a):
    b16 = open(os.path.join(a.conv, 'balls16.bin'), 'rb').read()
    sheet = U.spectrum_balls()
    # the UKNC sheet: 16 columns (shift), 7 rows (ball), 32 x 15 pixels each, 1 grid pixel between
    W, H = 16 * 33 + 1, 7 * 16 + 1
    img = [[0] * W for _ in range(H)]
    for shift in range(16):
        for ball in range(7):
            base = (shift * 7 + ball) * 60
            for y in range(15):
                w0 = b16[base + 4 * y] | b16[base + 4 * y + 1] << 8
                w1 = b16[base + 4 * y + 2] | b16[base + 4 * y + 3] << 8
                line = w0 | w1 << 16
                for x in range(32):
                    img[1 + ball * 16 + y][1 + shift * 33 + x] = 2 if line >> x & 1 else 1
            for y in range(15):
                img[1 + ball * 16 + y][1 + shift * 33 + 16] = 3 if img[1 + ball * 16 + y][1 + shift * 33 + 16] == 1 \
                    else img[1 + ball * 16 + y][1 + shift * 33 + 16]
    # the Spectrum sheet: 8 columns (shift), 7 rows, 24 x 16
    SW, SH = 8 * 25 + 1, 7 * 17 + 1
    simg = [[0] * SW for _ in range(SH)]
    for shift in range(8):
        for ball in range(7):
            f = sheet[(shift * 7 + ball) * 48:(shift * 7 + ball + 1) * 48]
            for y in range(16):
                for x in range(24):
                    simg[1 + ball * 17 + y][1 + shift * 25 + x] = 2 if f[3 * y + x // 8] >> (7 - x % 8) & 1 else 1
    fig = plt.figure(figsize=(WIDTH, 7.6))
    ax1 = fig.add_axes([0.05, 0.60, 0.40, 0.32])
    ax1.imshow(simg, cmap=CMAP, vmin=0, vmax=3, interpolation='nearest', aspect=1.0)
    ax1.set_title('A. Spectrum: BallSprites $D000\n8 shifts x 7 balls, 3 bytes x 16 lines, bit 7 left', fontsize=11)
    ax1.set_xticks([1 + s * 25 + 12 for s in range(8)], [str(s) for s in range(8)])
    ax1.set_yticks([1 + b * 17 + 8 for b in range(7)], ['cue'] + [str(b) for b in range(1, 7)])
    ax1.set_xlabel('shift = x AND 7')
    # zoom: ball 1 shift 5 on the UKNC, with the word and bit numbers
    ax3 = fig.add_axes([0.53, 0.60, 0.44, 0.31])
    base = (5 * 7 + 1) * 60
    z = []
    words = []
    for y in range(15):
        w0 = b16[base + 4 * y] | b16[base + 4 * y + 1] << 8
        w1 = b16[base + 4 * y + 2] | b16[base + 4 * y + 3] << 8
        words.append((w0, w1))
        line = w0 | w1 << 16
        z.append([2 if line >> x & 1 else 1 for x in range(32)])
    ax3.imshow(z, cmap=CMAP, vmin=0, vmax=3, interpolation='nearest', aspect=1 / 1.2,
               extent=(-0.5, 31.5, 14.5, -0.5))
    ax3.axvline(15.5, color='#d0d000', lw=2)
    ax3.set_xticks([0, 4, 8, 12, 16, 20, 24, 28, 31], ['0', '4', '8', '12', '0', '4', '8', '12', '15'])
    ax3.set_xlabel('bit of the word = pixel: word 0 (left), word 1 (right)')
    ax3.set_yticks(range(0, 15, 2))
    ax3.set_ylabel('line')
    ax3.set_title(f'C. UKNC: ball 1, shift 5, two words a line\nline 0: {words[0][0]:06o} {words[0][1]:06o}, '
                  f'line 7: {words[7][0]:06o} {words[7][1]:06o} (octal)', fontsize=11)
    ax2 = fig.add_axes([0.05, 0.07, 0.92, 0.42])
    ax2.imshow(img, cmap=CMAP, vmin=0, vmax=3, interpolation='nearest', aspect=1 / 1.2)
    ax2.set_title('B. UKNC: balls16, decoded from the converted words: 16 shifts x 7 balls, 2 words x 15 lines, '
                  'bit 0 left,\n320-pixel mode (pixels 1.2 times as wide as high); the yellow line is the word boundary',
                  fontsize=11)
    ax2.set_xticks([1 + s * 33 + 16 for s in range(16)], [str(s) for s in range(16)])
    ax2.set_yticks([1 + b * 16 + 7 for b in range(7)], ['cue'] + [str(b) for b in range(1, 7)])
    ax2.set_xlabel('shift = x AND 15')
    fig.text(0.01, 0.005, 'src/res/graphics/BallSprites.png -> python3 tools/uknc_convert.py -> '
             'work/docs/vpD/uknc/balls16.bin (6720 bytes); python3 tools/fig_uknc.py balls', fontsize=10, color='#555')
    save(fig, 'balls-uknc.png')


# one tick: name, Z80 T on the Spectrum, its parts (redraw, physics, other) -- doc 04, 4.6 (task_costs.py)
TICKS = [('aiming', 15237, 0, 0), ('one ball', 19932, 6649, 9969), ('six balls', 62248, 33442, 25492),
         ('heaviest', 73768, 33429, 37025)]


def cmd_budget(a):
    """Z80 tick vs the UKNC estimate: CPU takes physics + other, PPU takes the redraw (factors from 14.3)"""
    k_cpu, k_ppu = a.k_cpu, a.k_ppu
    fig, ax = plt.subplots(figsize=(WIDTH, 4.8))
    names = [t[0] for t in TICKS]
    y = range(len(TICKS))
    for i, (name, total, redraw, phys) in enumerate(TICKS):
        other = total - redraw - phys
        f = 100 / 69888
        ax.barh(i - 0.27, redraw * f, 0.25, color='#4c72b0', label='redraw' if i == 0 else None)
        ax.barh(i - 0.27, phys * f, 0.25, left=redraw * f, color='#dd8452', label='physics' if i == 0 else None)
        ax.barh(i - 0.27, other * f, 0.25, left=(redraw + phys) * f, color='#999999',
                label='scheduler, input, HUD' if i == 0 else None)
        ax.text(total * f + 1, i - 0.27, f'Z80 {total * f:.0f} %', va='center', fontsize=10)
        cpu = (phys + other) * k_cpu / 3.5e6 * 50 * 100
        ppu = redraw * k_ppu / 3.5e6 * 50 * 100
        ax.barh(i, cpu, 0.22, color='#c44e52', label='UKNC CPU (physics + rest)' if i == 0 else None)
        ax.text(cpu + 1, i, f'CPU {cpu:.0f} %', va='center', fontsize=10)
        ax.barh(i + 0.25, ppu, 0.22, color='#55a868', label='UKNC PPU (redraw)' if i == 0 else None)
        ax.text(ppu + 1, i + 0.25, f'PPU {ppu:.0f} %', va='center', fontsize=10)
    ax.axvline(100, color='red', ls='--', lw=1)
    ax.text(100.8, 3.45, 'one frame (20 ms)', color='red', fontsize=10)
    ax.set_yticks(list(y), names)
    ax.invert_yaxis()
    ax.set_xlim(0, 140)
    ax.set_xlabel('share of one 50 Hz frame, %')
    ax.set_title('One tick of the game: measured on the Spectrum, estimated on the UKNC\'s two processors')
    ax.legend(loc='upper right', fontsize=10)
    fig.text(0.01, 0.01, f'Z80 ticks: doc 04, 4.6 (w1 frames 1070, 1086, 4375, 4373); UKNC: Z80 seconds x '
             f'{k_cpu} (CPU) and x {k_ppu} (PPU), 14.3; python3 tools/fig_uknc.py budget', fontsize=10, color='#555')
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    save(fig, 'budget.png')


def cmd_anim(a):
    """A ball XORed across the UKNC screen in plane 0: each picture erases the ball at its old x and draws it at the
    new one with two words a line from balls16, the shift x AND 15 choosing the copy"""
    from PIL import Image
    import io
    b16 = open(os.path.join(a.conv, 'balls16.bin'), 'rb').read()
    ball, y0, W, H = 3, 4, 64, 23            # a strip of the screen: 64 pixels (4 words) x 23 lines
    screen = [[0] * W for _ in range(H)]

    def xor(x):
        shift, word = x & 15, x >> 4
        base = (shift * 7 + ball) * 60
        touched = []
        for yy in range(15):
            for k in range(2):
                w = b16[base + 4 * yy + 2 * k] | b16[base + 4 * yy + 2 * k + 1] << 8
                for bit in range(16):
                    if w >> bit & 1:
                        px = (word + k) * 16 + bit
                        if px < W:
                            screen[y0 + yy][px] ^= 1
            touched.append(word)
        return shift, word, base

    pictures = []
    xs = list(range(2, 34))
    prev = None
    for i, x in enumerate(xs):
        if prev is not None:
            xor(prev)
        shift, word, base = xor(x)
        prev = x
        fig = plt.figure(figsize=(WIDTH, 4.2))
        ax = fig.add_axes([0.04, 0.12, 0.56, 0.74])
        img = [[2 if v else 1 for v in row] for row in screen]
        for yy in range(15):
            for k in range(2):
                for bit in range(16):
                    px = (word + k) * 16 + bit
                    if px < W and img[y0 + yy][px] == 1:
                        img[y0 + yy][px] = 3
        ax.imshow(img, cmap=ListedColormap(['#9a9a9a', '#00a000', '#000000', '#7fd07f']), vmin=0, vmax=3,
                  interpolation='nearest', aspect=1 / 1.2)
        for wb in range(1, 4):
            ax.axvline(wb * 16 - 0.5, color='#d0d000', lw=1.5)
        ax.set_xticks([8, 24, 40, 56], ['word 0', 'word 1', 'word 2', 'word 3'])
        ax.set_yticks([])
        ax.set_title(f'plane 0, one strip of the table: ball {ball} at x = {x}', fontsize=11)
        t = fig.add_axes([0.62, 0.05, 0.37, 0.85])
        t.axis('off')
        lines = [f'x = {x}', f'shift = x AND 15 = {shift}', f'first word = x / 16 = {word}',
                 f'copy = (shift x 7 + ball) x 60', f'     = {base} bytes ({base:o} octal)',
                 '', 'per line, 15 lines:', '  MOV (R1)+,R0 ; XOR R0,(R2)+', '  MOV (R1)+,R0 ; XOR R0,(R2)+',
                 '  ADD R3,R2      ; next line', '', 'light green: the two words', 'this picture XORed']
        if prev is not None and i:
            lines.insert(5, f'erased first at x = {xs[i - 1]}')
        t.text(0, 1, '\n'.join(lines), va='top', fontsize=11, family='monospace')
        fig.text(0.01, 0.01, f'picture {i + 1} of {len(xs)}: work/docs/vpD/uknc/balls16.bin; '
                 'python3 tools/fig_uknc.py anim', fontsize=10, color='#555')
        buf = io.BytesIO()
        fig.savefig(buf, dpi=DPI, format='png')
        plt.close(fig)
        pictures.append(Image.open(io.BytesIO(buf.getvalue())).convert('P', palette=Image.ADAPTIVE, colors=64))
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'ball-xor.gif')
    pictures[0].save(path, save_all=True, append_images=pictures[1:], duration=400, loop=0)
    print(path, len(pictures), 'pictures')


# the memory maps of 14.1: (start, end, label, colour); Spectrum hex, UKNC octal in the labels
MAPS = [
    ('ZX Spectrum 48K\n(Z80 3.5 MHz)', [
        (0x0000, 0x4000, 'ROM 16 KB: BASIC,\nBEEPER, the calculator\n(AimShot)', '#bbbbbb'),
        (0x4000, 0x5B00, 'screen: pixels, attributes', '#7fb3e0'),
        (0x5B00, 0x8000, 'system, BASIC loader', '#dddddd'),
        (0x8000, 0xD000, 'game code', '#e8a87c'),
        (0xD000, 0xE014, 'balls, tables, font', '#f2d07c'),
        (0xE014, 0x10000, 'free, stack, IM 2 jump', '#eeeeee')]),
    ('UKNC CPU\n(K1801VM2 8 MHz)', [
        (0x0000, 0xE000, 'RAM 56 KB\n000000-157777:\nwords from planes\n1 + 2, low halves;\nRT-11 and the game', '#e8a87c'),
        (0xE000, 0x10000, 'I/O 160000-177777:\nchannels, plane\nwindow 176640', '#bbbbbb')]),
    ('UKNC PPU\n(K1801VM2 6.25 MHz)', [
        (0x0000, 0x8000, 'RAM 32 KB\n000000-077777:\nplane 0, low half;\nline table 000270,\nPPU program', '#9fd09f'),
        (0x8000, 0xFE00, 'ROM 100000-176777,\nor plane 0 high half\nas RAM (177054\nbits 4-7)', '#bbbbbb'),
        (0xFE00, 0x10000, '', '#888888')]),
    ('three planes\n(3 x 64 KB)', [
        (0x0000, 0x8000, 'low halves:\nplane 0 = PPU RAM,\nplanes 1 + 2 =\nCPU RAM', '#dddddd'),
        (0x8000, 0x10000, 'high halves\n100000-177777:\nvideo memory,\n3 bits a pixel,\nthrough ports', '#7fb3e0')]),
]


def cmd_machines(a):
    fig, ax = plt.subplots(figsize=(WIDTH, 6.0))
    for i, (title, regions) in enumerate(MAPS):
        x = i * 1.05
        for lo, hi, label, colour in regions:
            ax.add_patch(plt.Rectangle((x, lo), 0.95, hi - lo, facecolor=colour, edgecolor='black', lw=0.8))
            ax.text(x + 0.03, (lo + hi) / 2, label, va='center', fontsize=10)
        ax.text(x + 0.475, 0x10000 + 0x600, title, ha='center', va='top', fontsize=11, weight='bold')
    ax.set_xlim(-0.05, 4.2)
    ax.set_ylim(0x10000 + 0x2000, 0)
    ax.set_yticks([0, 0x4000, 0x8000, 0xC000, 0x10000], ['0', '16 K (hex 4000, octal 040000)', '32 K (8000, 100000)',
                                                         '48 K (C000, 140000)', '64 K'])
    ax.set_xticks([])
    ax.set_title('The two machines\' memory, one column per address space (byte addresses, top = 0)', fontsize=12)
    fig.text(0.01, 0.01, 'UKNC: UKNCBTL Memory.cpp, ukncbtl-doc uknc-memory.md; Spectrum: doc 02; '
             'python3 tools/fig_uknc.py machines', fontsize=10, color='#555')
    fig.tight_layout(rect=(0, 0.03, 1, 1))
    save(fig, 'machines.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['balls', 'budget', 'anim', 'machines'])
    p.add_argument('--conv', default=os.path.join(CASE, 'work', 'docs', 'vpD', 'uknc'))
    p.add_argument('--k-cpu', type=float, default=0.8, help='UKNC CPU time / Z80 time for the logic (14.3)')
    p.add_argument('--k-ppu', type=float, default=0.65, help='UKNC PPU time / Z80 time for the redraw (14.3)')
    a = p.parse_args()
    globals()['cmd_' + a.what](a)


if __name__ == '__main__':
    main()

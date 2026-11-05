#!/usr/bin/env python3
"""Doc 03: UltraXOR v1.2's 78 layers as a staircase (docs/img/load/ultraxor-layers.png).

    python3 tools/fig_ultraxor.py [--plain build/boot/a-nether-plain.bin] [--png docs/img/load/ultraxor-layers.png]

Across: the envelope's addresses after the entry's copy, $7705-$813A. Up: the layer, 0 (plain in the file) to 77.
Each layer is a dot where its loop stores (LD (HL),A) and a bar over the bytes it decrypts; the bar always starts
right after the dot: a loop decrypts the next loop from its own DJNZ displacement on. Below: the file's bytes there
(cipher, as on the disk) and the same bytes decrypted, one pixel column per byte, grey level = the byte. Data:
tools/ultraxor.py layers (the plain form from src/boot/a-nether.asm, built by tools/build.sh) and the disk file
build/boot/a-nether-b.bin.
"""
import argparse
import os
import re
import subprocess
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'
LO, HI = 0x7705, 0x813A
FILE_AT = 0x5DE0 - 0x5D3B  # the copy's source offset in the file


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('--plain', default=os.path.join(CASE, 'build/boot/a-nether-plain.bin'))
    a.add_argument('--cipher', default=os.path.join(CASE, 'build/boot/a-nether-b.bin'))
    a.add_argument('--png', default=os.path.join(CASE, 'docs/img/load/ultraxor-layers.png'))
    args = a.parse_args()
    out = subprocess.run([sys.executable, os.path.join(HERE, 'ultraxor.py'), 'layers', args.plain],
                         capture_output=True, text=True, check=True).stdout
    layers = []
    for line in out.splitlines():
        m = re.match(r'\s*(\d+)\s+LD \(HL\),A at \$([0-9A-F]+)\s+decrypts \$([0-9A-F]+)-\$([0-9A-F]+)\s+(\d+)', line)
        if m:
            layers.append((int(m.group(1)), int(m.group(2), 16), int(m.group(3), 16), int(m.group(4), 16)))
    plain = open(args.plain, 'rb').read()
    cipher = open(args.cipher, 'rb').read()
    n = HI - LO + 1
    p = np.frombuffer(plain[FILE_AT:FILE_AT + n], dtype=np.uint8)
    c = np.frombuffer(cipher[FILE_AT:FILE_AT + n], dtype=np.uint8)
    fig = plt.figure(figsize=(12, 7.6), facecolor=BG)
    fig.text(0.012, 0.975, 'UltraXOR: 78 loops in a chain; each decrypts the next one, the last one the disk reader',
             color=FG, fontsize=13.5, family='monospace', va='top')
    fig.text(0.012, 0.94, 'Each layer: a dot where its loop stores the decrypted byte, a bar over what it decrypts; '
             'the envelope $7705-$813A after the entry\'s copy'.replace('$', r'\$'), color=DIM, fontsize=9.5,
             family='monospace', va='top')
    ax = fig.add_axes([0.07, 0.30, 0.91, 0.60], facecolor=PANEL)
    for k, pc, lo, hi in layers:
        col = '#4caf50' if k == 0 else '#f0c05a' if k == 77 else '#5c8fd6'
        ax.plot([lo, hi + 1], [k, k], color=col, lw=2.2, solid_capstyle='butt')
        ax.plot(pc, k, 'o', color=FG, ms=2.5)
    ax.annotate('layer 0, $7721: plain in the file;\nDI, LD R,A with A = $2A: from here every\nkey is fixed by '
                'the code alone'.replace('$', r'\$'), xy=(0x7757, 0), xytext=(0x7A00, 6), color=FG, fontsize=8.5,
                family='monospace', arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('layers 1-76: 14-44 bytes each,\nkeys from R and the registers they change'.replace('$', r'\$'),
                xy=(0x7C00, 50), xytext=(0x7700, 55), color=FG, fontsize=8.5, family='monospace',
                arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('layer 77, $7FCA (BC = $0152): $7FE9-$813A,\nthe system state, then the reader copied\nto $5D3F '
                'that reads the whole disk'.replace('$', r'\$'), xy=(0x8060, 77), xytext=(0x7B80, 69),
                color=FG, fontsize=8.5, family='monospace', arrowprops=dict(arrowstyle='->', color=DIM))
    ax.annotate('"UltraXOR v1.2 (c) PARACELS"', xy=(0x7708, -1.5), xytext=(0x7708, -6), color=DIM, fontsize=8,
                family='monospace')
    ax.set_xlim(LO, HI + 1)
    ax.set_ylim(-8, 80)
    ax.set_ylabel('layer (run order)', color=DIM, fontsize=9)
    ticks = list(range(0x7800, 0x8200, 0x100))
    ax.set_xticks(ticks)
    ax.set_xticklabels(['\\$%04X' % t for t in ticks])
    ax.tick_params(colors=DIM, labelsize=8)
    for s in ax.spines.values():
        s.set_color('#444')
    diff = (p != c).astype(np.uint8)
    bx = fig.add_axes([0.07, 0.15, 0.91, 0.07], facecolor=PANEL)
    bx.imshow(np.tile(diff, (8, 1)), cmap=matplotlib.colors.ListedColormap(['#2b2d38', '#d9534f']), aspect='auto',
              extent=(LO, HI + 1, 0, 1), interpolation='nearest', vmin=0, vmax=1)
    bx.set_yticks([])
    bx.set_xticks(ticks)
    bx.set_xticklabels(['\\$%04X' % t for t in ticks])
    bx.tick_params(colors=DIM, labelsize=8)
    fig.text(0.07, 0.235, 'red: the byte on the disk differs from the decrypted one (%d of %d bytes); dark: stored '
             'plain (the sign, layer 0, chance)' % (int(diff.sum()), n), color=FG, fontsize=8.5, family='monospace')
    fig.text(0.07, 0.04, 'A byte stays plain by chance where its key is 0. The 338 bytes of layer 77 hold the reader; '
             'the one byte decrypted twice is its JR NZ displacement.', color=DIM, fontsize=8.5,
             family='monospace')
    os.makedirs(os.path.dirname(args.png), exist_ok=True)
    fig.savefig(args.png, dpi=100, facecolor=BG)
    print(len(layers), 'layers;', 'bytes decrypted twice:',
          sum(1 for x in range(LO, HI + 1) if sum(lo <= x <= hi for _k, _p, lo, hi in layers) > 1))


if __name__ == '__main__':
    main()

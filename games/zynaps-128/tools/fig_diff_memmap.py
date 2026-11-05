#!/usr/bin/env python3
"""The 2 in 1's game image against the 48K Zynaps's, byte by byte, with what block 2's set-up writes into it at load
(docs/img/diff/memmap-diff.png, docs 13.4). Adapted from games/nether-earth-gs/tools/fig_diff_memmap.py.

    python3 tools/fig_diff_memmap.py [--out PNG]

The classes come from tools/diff_48k.py (both builds; the set-up's writes from work/images/game-entry-cpu.bin, c1 at
JP $8000, options off). One cell is one byte of the Z80's view, $6100-$FFFF, 256 bytes a row.
"""

import argparse
import os
import sys
from collections import Counter

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
import numpy as np  # noqa: E402
from matplotlib.colors import ListedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_48k as D  # noqa: E402

LO = 0x6100
CLASSES = [('none', 'in neither image', '#0e0e14'),
           ('same', 'the same byte at the same address', '#3d6b47'),
           ('changed', 'changed by the 2018 edit (keys, delays)', '#e5534b'),
           ('zeroed', 'a 48K tape leftover, zero in the 2 in 1', '#f2e86d'),
           ('patched', 'the same in the image, written by the set-up at load (128K path)', '#ff9f43'),
           ('48k-only', '48K image only (zeros Start fills; not in block 2)', '#2b3550'),
           ('128-only', 'the 2 in 1 only ($FFFF)', '#26c6da')]
INDEX = {k: i for i, (k, _, _) in enumerate(CLASSES)}
BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'

LABELS = [  # (address, label)
    (0x61A8, '48K $61A8-$67FF: zeros (TileGraphics are copied there by Start)'),
    (0x6800, 'level data, effects, variables $6800-$817F: same'),
    (0x8188, '1 KeyTable: SPACE Q A O P'),
    (0x8484, 'set-up: credits DAVE ROGERS'),
    (0x86B7, '2 RowStar padding; set-up: row toggle OUT -> NOP'),
    (0x8C15, '3 ScrollStep padding'),
    (0x8FBD, 'set-up: strip toggle OUT -> NOP'),
    (0x949C, 'set-up: slot toggle OUT -> NOP'),
    (0x9BFF, 'set-up: 16 hook sites $9BFF-$ACA3'),
    (0xA538, '4-6 MenuRasterInterrupt: waits, line loop'),
    (0xA9E5, 'set-up: glue sites in the three handlers'),
    (0xAA68, '7-9 PlayInterrupt: three waits'),
    (0xB21B, 'set-up: JR $B200, RET at $B2F0'),
    (0xB30C, 'set-up: EffectPlay -> HookSound + 15 hooks'),
    (0xB446, 'set-up: TitleTune DI, OUT -> NOP'),
    (0xC000, 'glyph cache, sprites, records: same'),
    (0xFDE8, '10 IF1 RS-232 routine: zeroed'),
    (0xFFD9, "11 ROM font 'Q'-'U': zeroed; $FFFF = $73"),
]


def classify():
    a48, a128 = D.Case('48K'), D.Case('128')
    cls = D.classify(a48, a128)
    for a in range(LO, 0x61A8):
        cls[a] = 'none'
    img = open(D.ENTRY_IMAGE, 'rb').read()
    for a in range(0x6800, 0x10000):
        if img[a] != a128.mem[a]:
            cls[a] = 'patched'
    return cls


def draw(cls, out):
    rows = (0x10000 - LO) // 256
    grid = np.zeros((rows, 256), dtype=int)
    for a, c in cls.items():
        grid[(a - LO) // 256, a & 255] = INDEX[c]
    fig = plt.figure(figsize=(13, 10), facecolor=BG)
    ax = fig.add_axes((0.12, 0.1, 0.47, 0.82))
    ax.imshow(grid, cmap=ListedColormap([c for _, _, c in CLASSES]), vmin=0, vmax=len(CLASSES) - 1,
              aspect='auto', interpolation='nearest', extent=(0, 256, rows, 0))
    for a, c in cls.items():
        if c in ('changed', 'patched', '128-only'):
            ax.add_patch(plt.Rectangle(((a & 255) - 1.5, (a - LO) // 256 - 0.4), 4, 1.8, fill=False,
                                       ec=CLASSES[INDEX[c]][2], lw=0.7))
    ticks = list(range(0, rows, 8))
    ax.set_yticks([t + 0.5 for t in ticks])
    ax.set_yticklabels([f'${LO + 256 * t:04X}' for t in ticks], fontsize=7, color=DIM, family='monospace')
    ax.set_xticks([0, 64, 128, 192, 255])
    ax.set_xticklabels(['+$00', '+$40', '+$80', '+$C0', '+$FF'], fontsize=7, color=DIM, family='monospace')
    ax.tick_params(colors=DIM)
    for s in ax.spines.values():
        s.set_color(DIM)
    ax.axhline((0x6800 - LO) / 256, color='white', lw=0.6, ls=':')
    ax.text(-2, (0x6800 - LO) / 256, 'block 2 image $6800 ', color='white', fontsize=7, ha='right', va='center')
    used = []
    for addr, label in LABELS:
        y = (addr - LO) / 256 + 0.5
        ly = max([y] + [u + 3.4 for u in used])
        used.append(ly)
        ax.annotate(label, ((addr & 255) + 0.5, y), xytext=(262, ly), textcoords='data', fontsize=8, color=TEXT,
                    va='center', annotation_clip=False,
                    arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6, shrinkA=0, shrinkB=0))
    n = Counter(cls.values())
    common = n['same'] + n['changed'] + n['zeroed'] + n['patched']
    fig.legend(handles=[Patch(color=c, label=f'{lab}: {n[k]:,} bytes') for k, lab, c in CLASSES[1:]],
               loc='lower left', ncol=2, frameon=False, labelcolor=TEXT, fontsize=8, bbox_to_anchor=(0.04, 0.0))
    fig.suptitle(f'The 2 in 1 is the 48K game at its own addresses: {(n["same"] + n["patched"]) / common:.2%} of the '
                 f'{common:,} common bytes are the same; {n["changed"] + n["zeroed"]} differ in 11 places, '
                 f'{n["patched"]} more are written at load', color=TEXT, fontsize=10.5, x=0.01, ha='left')
    fig.text(0.01, 0.945, 'One cell one byte of the Z80\'s view, 256 a row; changed and patched bytes ringed; '
             'numbers 1-11 are the places of 13.4; classes from tools/diff_48k.py over both builds and c1\'s '
             'memory at JP $8000', color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, dpi=90, facecolor=BG)
    print('wrote', out, dict(n))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(D.C, 'docs/img/diff/memmap-diff.png'))
    a = ap.parse_args()
    draw(classify(), a.out)


if __name__ == '__main__':
    main()

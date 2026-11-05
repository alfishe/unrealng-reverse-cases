#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): Nether Earth's saved game on tape against ANE's file nether.N on
disk, field by field, and the bytes of the nether.N the authors left on the disk.

    python3 tools/fig_diff_shell_save.py --out docs/img/diff/shell-save.png

The fields are the code's:
  Nether Earth: SaveGameBlocks $C2C9 / SaveChecksum $C30F / LoadGameBlocks $C21E (../nether-earth/src/game/
      mainmenu.asm): the 2-byte sum block, then $D92B-$FDFB ($24D1 bytes), both flag $00, pilot $0900;
  ANE: SaveGameStage $C2CC (src/game/mainmenu.asm), GameSave $6905 (src/game/im2.asm), the disk module's save at
      $4033 (src/disk/): CODE $D92B, 9941 bytes = $D92B-$FFFF; LoadReturn $A590 (src/game/disk.asm);
  the variables of both src/game/game.ann (@equ): the same addresses $FD00-$FDFB, except NE's music state.
The bytes: src/res/disk/nether-n.bin (the disk's nether.N as the build places it).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

BASE = 0xD92B
FIELDS = [  # start, end (inclusive), name, colour, in NE's block, note
    (0xD92B, 0xD957, 'Shots, staged (45)', '#e5534b', True, 'NE: copied back on load;\nANE: never copied back'),
    (0xD958, 0xD9FF, 'Buildings, staged (168)', '#d9a441', True, 'NE: copied back to $FF01;\nANE: not read'),
    (0xDA00, 0xDB7F, 'Robots: ours (384)', '#5c8fd6', True, 'same'),
    (0xDB80, 0xDCFF, 'Robots: the enemy\'s (384)', '#3f6db3', True, 'same'),
    (0xDD00, 0xFCFF, 'Map: 16 x 512 cells (8192)', '#5a6380', True, 'same'),
    (0xFD00, 0xFDFB, 'variables, capture points (252)', '#4caf50', True, 'same addresses; NE\'s music bytes idle'),
    (0xFDFC, 0xFF00, 'NE: IM 2 jump + table;\nANE: zero, a HRUM\ndepacker copy at $FE4C', '#7a7d8c', False,
     'ANE only: leftovers'),
    (0xFF01, 0xFFA8, 'Buildings, live (168)', '#e8833a', False, 'ANE only: what a load uses'),
    (0xFFA9, 0xFFFF, 'stack', '#3d4256', False, 'ANE only: stack words'),
]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--bytes', default=os.path.join(C.ANE, 'src/res/disk/nether-n.bin'))
    p.add_argument('--out', default=C.out_path('shell-save.png'))
    args = p.parse_args()
    data = open(args.bytes, 'rb').read()
    assert len(data) == 9941, len(data)
    staged, live = data[0xD958 - BASE:0xDA00 - BASE], data[0xFF01 - BASE:0xFFA9 - BASE]
    ne_sum = sum(data[:0x24D1]) & 0xFFFF
    print(f'nether.N: {len(data)} bytes; staged buildings == $FF01 copy: {staged == live}; '
          f'the sum NE would save for its first $24D1 bytes: ${ne_sum:04X}')

    fig = plt.figure(figsize=(16, 9), dpi=100)
    gs = fig.add_gridspec(1, 2, width_ratios=[1.7, 1], wspace=0.05)
    ax, bx = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])
    C.style(fig, (ax, bx))
    ax.set_axis_off()

    # left: the two formats on one address scale (non-linear: each field gets room for its label)
    heights = {f[0]: 0.6 + 0.9 * np.log10((f[1] - f[0] + 1)) for f in FIELDS}
    y = 0.0
    xs_ne, xs_ane, w = 0.0, 2.1, 1.75
    ax.text(xs_ne + w / 2, -1.85, 'Nether Earth: two tape blocks', color=C.NE_COL, ha='center', fontsize=10.5)
    ax.text(xs_ane + w / 2, -1.85, 'ANE: one disk file, nether.N', color=C.ANE_COL, ha='center', fontsize=10.5)
    # NE's sum block on top
    ax.add_patch(Rectangle((xs_ne, -1.55), w, 1.4, facecolor='#26c6da', edgecolor=C.BG))
    ax.text(xs_ne + 0.05, -0.85, 'block 1: 2 bytes, flag $00:\nthe byte sum of block 2', color='#101010',
            fontsize=8.2, va='center')
    ax.add_patch(Rectangle((xs_ane, -1.55), w, 1.4, facecolor=C.PANEL, edgecolor='#555', ls='--'))
    ax.text(xs_ane + 0.05, -0.85, 'no checksum: nothing on the\ndisk path tests the bytes',
            color=C.DIM, fontsize=8.2, va='center')
    for a, b, name, col, in_ne, note in FIELDS:
        h = heights[a]
        for x, show in ((xs_ne, in_ne), (xs_ane, True)):
            if show:
                ax.add_patch(Rectangle((x, y), w, h - 0.08, facecolor=col, edgecolor=C.BG))
                ax.text(x + 0.05, y + (h - 0.08) / 2, f'${a:04X}-${b:04X}\n{name}', color='#f4f4f4', fontsize=8.2,
                        va='center')
        ax.text(xs_ane + w + 0.08, y + (h - 0.08) / 2, note, color=C.DIM, fontsize=8.2, va='center')
        y += h
    ne_end = sum(heights[f[0]] for f in FIELDS if f[4])
    ax.annotate('', xy=(xs_ne - 0.08, 0), xytext=(xs_ne - 0.08, ne_end - 0.08),
                arrowprops=dict(arrowstyle='<->', color=C.NE_COL, lw=1))
    ax.text(xs_ne - 0.13, ne_end / 2, 'block 2: $24D1 = 9 425 bytes, flag $00', color=C.NE_COL, rotation=90,
            ha='right', va='center', fontsize=9)
    ax.annotate('', xy=(xs_ane - 0.06, 0), xytext=(xs_ane - 0.06, y - 0.08),
                arrowprops=dict(arrowstyle='<->', color=C.ANE_COL, lw=1))
    ax.text(xs_ane - 0.1, y / 2 + 1.2, 'CODE 55595, 9 941 bytes', color=C.ANE_COL, rotation=90, ha='right',
            va='center', fontsize=9)
    ax.set_xlim(-0.5, 6.4)
    ax.set_ylim(y + 0.2, -2.2)
    ax.set_title('Same bytes for the game: ANE\'s file is NE\'s block 2 plus the top 516 bytes of memory,\n'
                 'with no checksum (field heights not to scale)', color=C.FG, fontsize=12, loc='left')

    # right: nether.N's bytes, 96 a row, coloured by field, dark where zero
    cols = 96
    rows = (len(data) + cols - 1) // cols
    img = np.zeros((rows, cols, 3))
    img[:] = matplotlib.colors.to_rgb(C.PANEL)
    for a, b, name, col, in_ne, note in FIELDS:
        rgb = np.array(matplotlib.colors.to_rgb(col))
        for addr in range(a, b + 1):
            i = addr - BASE
            v = data[i]
            img[i // cols, i % cols] = rgb * (0.18 if v == 0 else 0.55 + 0.45 * v / 255)
    bx.imshow(img, aspect='auto', interpolation='nearest')
    bx.set_xticks([0, 32, 64, 95])
    bx.set_yticks(range(0, rows, 10))
    bx.set_yticklabels([f'${BASE + r * cols:04X}' for r in range(0, rows, 10)], fontsize=8)
    bx.set_xlabel('byte in the row (96 a row); dim = zero, bright = a high value', color=C.DIM, fontsize=9)
    bx.set_title(f'The disk\'s own nether.N (day 29): {len(data)} bytes', color=C.FG, fontsize=11, loc='left')
    r_ne = 0x24D1 // cols
    bx.axhline(0x24D1 / cols - 0.5, color='#ffffff', lw=1, ls='--')
    bx.text(cols - 1, r_ne - 1.5, 'NE\'s block 2 ends here ($FDFB)', color='#ffffff', fontsize=8.5, ha='right')
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


if __name__ == '__main__':
    sys.exit(main())

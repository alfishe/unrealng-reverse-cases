#!/usr/bin/env python3
"""The dotted block sprite (sprite 18, block $A428) as Nether Earth has it and as the GS game has it: the GS bridge
GsMenuSound starts on the sprite's last byte, $A569, so its DI ($F3) is the graphic byte of the top line's rightmost
pair (docs/img/diff/sprite-diff.png).

    python3 tools/fig_diff_sprite.py [--out PNG]

The block: two header bytes, then 40 lines of 4 (mask, graphic) pairs, bottom line first. A pixel is drawn as
(screen AND mask) OR graphic, so the figure shows each version over a grey backdrop of diagonal stripes standing for
whatever lies behind.
"""

import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_ne as D  # noqa: E402

BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'
BLOCK, ROWS, WIDTH = 0xA428, 40, 4


def render(mem):
    """(value image, changed mask) of the block: 0 = backdrop paper, 1 = backdrop ink, 2 = sprite paper, 3 = ink"""
    img = np.zeros((ROWS, WIDTH * 8), dtype=int)
    for line in range(ROWS):
        y = ROWS - 1 - line                      # bottom line first
        for col in range(WIDTH):
            a = BLOCK + 2 + 2 * (line * WIDTH + col)
            mask, gfx = mem.get(a, 0), mem.get(a + 1, 0)
            for bit in range(8):
                x = col * 8 + bit
                behind = (x + y) % 4 == 0        # the stripes behind
                m = (mask >> (7 - bit)) & 1
                g = (gfx >> (7 - bit)) & 1
                if g:
                    img[y, x] = 3
                elif m:
                    img[y, x] = 1 if behind else 0
                else:
                    img[y, x] = 2
    return img


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default=os.path.join(D.GS, 'docs/img/diff/sprite-diff.png'))
    a = ap.parse_args()
    ne, gs = D.Case('NE'), D.Case('GS')
    last = BLOCK + 2 + 2 * ROWS * WIDTH - 1
    assert last == 0xA569, hex(last)
    pal = np.array([[0.30, 0.30, 0.34], [0.55, 0.55, 0.60], [1.0, 1.0, 1.0], [0.0, 0.0, 0.0]])
    fig, axes = plt.subplots(1, 3, figsize=(10, 6.2), facecolor=BG,
                             gridspec_kw=dict(width_ratios=[1, 1, 1], left=0.04, right=0.98, top=0.86, bottom=0.12))
    imgs = [render(ne.mem), render(gs.mem)]
    diff = (imgs[0] != imgs[1])
    for ax, img, title in ((axes[0], imgs[0], f'Nether Earth: ${last:04X} = ${ne.mem[last]:02X}'),
                           (axes[1], imgs[1], f'GS game: ${last:04X} = ${gs.mem[last]:02X} (DI of GsMenuSound)')):
        ax.imshow(pal[img], interpolation='nearest')
        ax.set_title(title, color=TEXT, fontsize=9.5)
        ax.axis('off')
    show = pal[imgs[1]] * 0.35
    show[diff] = [0.90, 0.33, 0.29]
    axes[2].imshow(show, interpolation='nearest')
    axes[2].set_title(f'{int(diff.sum())} pixels differ (red)', color=TEXT, fontsize=9.5)
    axes[2].axis('off')
    fig.suptitle('Sprite 18, the dotted block ($A428): the bridge\'s first byte is the sprite\'s last', color=TEXT,
                 fontsize=11, x=0.01, ha='left')
    fig.text(0.01, 0.03, f'Top line, rightmost pair: mask ${gs.mem[last - 1]:02X}, graphic $00 in NE, '
             f'${gs.mem[last]:02X} (11110011) in GS.\n'
             'Grey stripes = whatever lies behind (mask 1). No recording of either case drew this block.', color=DIM, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    print('wrote', a.out, 'pixels differ', int(diff.sum()))


if __name__ == '__main__':
    main()

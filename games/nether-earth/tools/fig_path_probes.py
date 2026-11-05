#!/usr/bin/env python3
"""Doc 13 figure: the cells FreeDirections tests for each direction (docs/img/path/probes.png).

    python3 tools/fig_path_probes.py --out docs/img/path/probes.png

Drawn from the probes of tools/path_model.py (CanMoveRight / Left / Down / Up of src/game/world.asm): the model is
asked which cells it reads, on an empty map with the robot's anchor at (x, y).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import path_model as P  # noqa: E402

BG, AX, FG = '#15161b', '#1c1d24', '#e8e8ee'
FOOT, ANCHOR, TERRAIN, OBJECT = '#3d6fb5', '#8fb8ff', '#e5534b', '#d9a441'


class Spy(P.World):
    """a World that records the cells the probes read and how"""

    def __init__(self):
        super().__init__(bytes(0x10000), log=False)
        self.reads = []

    def test_cell(self, hl, d, e):
        self.reads.append((hl, 'terrain'))
        return True

    def anchor_free(self, hl, e):
        self.reads.append((hl, 'object'))
        return True


def probe(direction, x=100, y=8):
    w = Spy()
    hl = P.cell_address(x, y)
    {P.RIGHT: w.can_move_right, P.LEFT: w.can_move_left, P.DOWN: w.can_move_down,
     P.UP: w.can_move_up}[direction](hl, 8, 0x40)
    return [(P.cell_xy(a)[0] - x, P.cell_xy(a)[1] - y, kind) for a, kind in w.reads]


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    fig, axes = plt.subplots(1, 4, figsize=(11, 3.6))
    fig.patch.set_facecolor(BG)
    titles = {P.RIGHT: '→ right (CanMoveRight)', P.LEFT: '← left (CanMoveLeft)', P.DOWN: '↓ down (CanMoveDown)',
              P.UP: '↑ up (CanMoveUp)'}
    shift = {P.RIGHT: (1, 0), P.LEFT: (-1, 0), P.DOWN: (0, 1), P.UP: (0, -1)}
    for ax, direction in zip(axes, (P.RIGHT, P.LEFT, P.DOWN, P.UP)):
        ax.set_facecolor(AX)
        ax.set_xlim(-2.6, 3.6)
        ax.set_ylim(3.6, -3.6)
        ax.set_aspect('equal')
        for gx in range(-3, 5):
            ax.axvline(gx - 0.5, color='#2c2e38', lw=0.6)
        for gy in range(-4, 5):
            ax.axhline(gy - 0.5, color='#2c2e38', lw=0.6)
        # the footprint now: (0,0) anchor, (1,0), (0,-1), (1,-1)
        for cx, cy in ((0, 0), (1, 0), (0, -1), (1, -1)):
            ax.add_patch(Rectangle((cx - 0.5, cy - 0.5), 1, 1, color=FOOT, alpha=0.55))
        ax.add_patch(Rectangle((-0.5, -0.5), 1, 1, fill=False, ec=ANCHOR, lw=2))
        ax.text(0, 0, 'A', color=FG, ha='center', va='center', fontsize=11, weight='bold')
        dx, dy = shift[direction]
        for cx, cy in ((0, 0), (1, 0), (0, -1), (1, -1)):
            ax.add_patch(Rectangle((cx + dx - 0.5, cy + dy - 0.5), 1, 1, fill=False, ec=FG, lw=1, ls='--'))
        for cx, cy, kind in probe(direction):
            colour = TERRAIN if kind == 'terrain' else OBJECT
            ax.add_patch(Rectangle((cx - 0.42, cy - 0.42), 0.84, 0.84, fill=False, ec=colour, lw=2.4))
            ax.text(cx, cy, 'T+O' if kind == 'terrain' else 'O', color=colour, ha='center', va='center',
                    fontsize=8, weight='bold')
        ax.set_title(titles[direction], color=FG, fontsize=10)
        ax.set_xticks(range(-2, 4))
        ax.set_xticklabels([f'x{c:+d}' if c else 'x' for c in range(-2, 4)], color=FG, fontsize=7)
        ax.set_yticks(range(-3, 4))
        ax.set_yticklabels([f'y{c:+d}' if c else 'y' for c in range(-3, 4)], color=FG, fontsize=7)
        for s in ax.spines.values():
            s.set_color('#2c2e38')
    handles = [Rectangle((0, 0), 1, 1, color=FOOT, alpha=0.55),
               Rectangle((0, 0), 1, 1, fill=False, ec=FG, ls='--'),
               Rectangle((0, 0), 1, 1, fill=False, ec=TERRAIN, lw=2.4),
               Rectangle((0, 0), 1, 1, fill=False, ec=OBJECT, lw=2.4)]
    labels = ['the robot now (A = its anchor, the only cell with bit 6)', 'the footprint after the step',
              'T+O: terrain type below the limit and no object / low ship bit (TestCell)',
              'O: no object anchor there (its 2 x 2 would overlap); the ship bit counts too']
    fig.legend(handles, labels, loc='lower center', ncol=2, frameon=False, labelcolor=FG, fontsize=8.5)
    fig.suptitle('A step is free when the 2 new cells pass the terrain test and no anchor sits where its block '
                 'would overlap', color=FG, fontsize=11.5)
    fig.subplots_adjust(left=0.04, right=0.99, top=0.83, bottom=0.2, wspace=0.25)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), dpi=100)
    print(args.out)


if __name__ == '__main__':
    main()

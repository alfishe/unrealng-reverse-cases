#!/usr/bin/env python3
"""Galaxy 1 as the game generates it (docs/10-gameplay-logic.md), and the recordings' jumps.

    python3 tools/fig_galaxy.py [OUT.png]

Left: the 256 systems of galaxy 1 (tools/galaxy.py, the seeds twisted as the game does), coloured by economy, the dot
size the tech level. Right: Lave's neighbourhood with the 7.0 light year range of a full tank (the range is an
ellipse in chart units, because SquaredDistance halves dy), f1's jump to Diso and w1's misjump, which stopped half
way at (15, 173) (JumpWitch).
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import galaxy as G  # noqa: E402
import rtplot as P  # noqa: E402


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'docs/img/logic/galaxy.png'
    g = G.systems(1)
    cmap = P.plt.get_cmap('coolwarm')
    col = [cmap(x['economy'] / 7) for x in g]
    size = [6 + 2.2 * x['tech'] for x in g]
    fig, (ax, bx) = P.figure(9, 13, nrows=2, gridspec_kw={'height_ratios': [1, 1.3]})
    ax.scatter([x['x'] for x in g], [x['y'] for x in g], s=size, c=col, lw=0)
    ax.set_xlim(-4, 260)
    ax.set_ylim(260, -4)
    ax.set_aspect(0.5)
    ax.add_patch(P.plt.Rectangle((-22, 133), 84, 80, fill=False, color=P.TEXT, lw=0.8, ls='--'))
    ax.set_title('Galaxy 1: 256 systems from three seed words (x = s1 high, y = s0 high)', fontsize=10.5,
                 loc='left')
    ax.set_xlabel('x (chart units; the galactic chart halves y)')
    ax.set_ylabel('y')
    near = [x for x in g if -8 <= x['x'] <= 52 and 136 <= x['y'] <= 212]
    left = {'Diso', 'Riedquat', 'Orrere', 'Uszaa'}
    bx.scatter([x['x'] for x in near], [x['y'] for x in near], s=[40 + 9 * x['tech'] for x in near], c=[cmap(x['economy'] / 7) for x in near], lw=0, zorder=3)
    labels = []
    for x in near:
        dist = 4 * int(np.sqrt((x['x'] - 20) ** 2 + (abs(x['y'] - 173) // 2) ** 2))
        labels.append((x['x'], x['y'], '%s  %.1f ly\n%s, %s, tech %d' % (
            x['name'], dist / 10, G.ECONOMIES[x['economy']], G.GOVERNMENTS[x['government']], x['tech'] + 1),
            'left' if x['name'] in left else 'right'))
    t = np.linspace(0, 2 * np.pi, 200)
    bx.plot(20 + 17.5 * np.cos(t), 173 + 35 * np.sin(t), color=P.WRITE, lw=1, ls='--')
    bx.text(21, 209.5, 'the 7.0 ly range: 4 sqrt(dx^2 + (dy/2)^2) = 70', color=P.WRITE, fontsize=8.5)
    bx.annotate('', xy=(11, 174), xytext=(20, 173), arrowprops=dict(arrowstyle='->', color=P.EXEC, lw=1.6))
    bx.text(15.5, 166, 'f1 1956: Lave to Diso, 3.6 ly', color=P.EXEC, fontsize=8.5, ha='center')
    bx.scatter([15], [173], marker='x', s=70, color=P.HOT, zorder=5)
    bx.text(15.5, 162.5, 'w1 2099: the misjump stops at (15, 173)', color=P.HOT, fontsize=8.5, ha='center')
    bx.set_xlim(-22, 62)
    bx.set_ylim(213, 133)
    bx.set_aspect('auto')
    bx.set_title("Lave's neighbourhood (the dashed box above)", fontsize=10.5, loc='left')
    bx.set_xlabel('x')
    handles = [P.plt.matplotlib.patches.Patch(color=cmap(e / 7), label=n) for e, n in enumerate(G.ECONOMIES)]
    fig.legend(handles=handles, loc='lower center', ncol=4, fontsize=8.5, frameon=False,
               title='economy (the dot size is the tech level)', title_fontsize=8.5)
    fig.suptitle('The galaxy is generated, never stored: every system, its data and its name come from twisting '
                 'three 16-bit seeds', fontsize=12)
    fig.tight_layout(rect=(0, 0.06, 1, 0.97))
    P.place_labels(fig, bx, labels)
    P.save(fig, out)


if __name__ == '__main__':
    main()

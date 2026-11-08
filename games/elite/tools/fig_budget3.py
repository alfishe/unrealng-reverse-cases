#!/usr/bin/env python3
"""Where the time goes over three recordings, by module, as one chart for a 900 px page (docs/02-architecture.md
2.7): a row a module, three bars a row (f1, d1, w1), the modules over 2 % in any recording, the rest summed.

    python3 tools/fig_budget3.py     # -> docs/img/arch/budget.png

The T-states are kit/fig_budget.py's (each instruction's summed T from the L1 build, given to its routine's module
by src/game/game.ann; HALT apart), so the numbers are those of the table under the figure.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import fig_budget as B  # noqa: E402
import rtplot as P  # noqa: E402

CASE = os.path.dirname(HERE)
RECS = [('f1', 'f1: launch, flight, jump'), ('d1', 'd1: title, docked screens'),
        ('w1', 'w1: witch space, fight, death')]
COLOURS = [(0.35, 0.65, 1.0), (1.0, 0.68, 0.25), (0.45, 0.85, 0.45)]


def main():
    parts = [B.Part(os.path.join(CASE, 'src', 'game', 'game.ann'), True)]
    shares = []
    for rec, _ in RECS:
        b = B.by_module(B.budget(os.path.join(CASE, 'work', rec, 'l1.json'), parts, None, {}))
        shares.append({m: 100 * t / b['total'] for m, t in b['per'].items()})
    mods = sorted({m for s in shares for m, v in s.items() if v >= 2.0}, key=lambda m: -shares[0].get(m, 0))
    rows = mods + ['other']
    vals = [[s.get(m, 0) for m in mods] + [sum(v for k, v in s.items() if k not in mods)] for s in shares]
    fig, ax = P.figure(9, 10.5)
    h = 0.27
    for i, ((rec, label), col) in enumerate(zip(RECS, COLOURS)):
        ys = [r + (i - 1) * h for r in range(len(rows))]
        ax.barh(ys, vals[i], height=h * 0.92, color=col, label=label)
        for y, v in zip(ys, vals[i]):
            if v >= 0.5:
                ax.text(v + 0.3, y, '%.1f' % v, va='center', fontsize=8.5, color=P.TEXT)
    names = [('HALT (waiting)' if m == B.HALT_NAME else P.module_label(m, small=False)) for m in mods] + \
        ['the other modules']
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels(names, fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel('% of all the T-states of the recording (self time)', fontsize=10)
    ax.tick_params(axis='x', labelsize=9)
    ax.set_xlim(0, max(max(v) for v in vals) * 1.12)
    ax.legend(fontsize=10, loc='lower right', frameon=False)
    ax.set_title('Flight is the copy, the stardust and the text; docked, the key spin; with ships, the 3D maths',
                 fontsize=11)
    P.save(fig, 'docs/img/arch/budget.png', dpi=100)


if __name__ == '__main__':
    main()

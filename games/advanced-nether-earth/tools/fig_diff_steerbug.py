#!/usr/bin/env python3
"""NE's SteerByOrder bug (NE doc 10.12, 13.3.6) in Nether Earth and in Advanced Nether Earth: the first step after a
new building target, from every start cell (docs/img/diff/steer-bug.png, work/diff/code.md).

    python3 tools/fig_diff_steerbug.py [--step 4] [--seeds 6] [--out docs/img/diff/steer-bug.png]

FindTargetBuilding leaves HL past the factory table ($FDFF), so SteerAtBuilding ($B2BB) aims at the bytes $FDFC-$FDFE.
NE keeps its IM 2 jump there: $FDFC = 0, $FDFD = $C3 (the JP), $FDFE = $66 (Handler's low byte, PlayInterrupt $D566):
the aim is column $C300, row $66. ANE moved the jump to $6969, and $FDFC-$FDFE are 0 in play (recording s2 frame
11500, work/images/scl-play-cpu.bin; the authors' saved game nether.N): the aim is column 0, row 0. The robot code is
the same bytes in both games (tools/diff_game.py: modules world, enemy, bases, ship, tables all `same`), so NE's
model of the world turn (games/nether-earth/tools/path_model.py, checked byte for byte against NE) runs both: one
robot on a flat map with one target factory, door (311, 7), the decision with +$0E = $FF (a new target).
"""

import argparse
import collections
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False  # hex addresses: $ is not math
from matplotlib.colors import ListedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
NE_TOOLS = os.path.normpath(os.path.join(HERE, '..', '..', 'nether-earth', 'tools'))
sys.path.insert(0, NE_TOOLS)
import path_lab as L  # noqa: E402
import path_model as P  # noqa: E402

DOOR = (311, 7)
EFFECTS = ['toward', 'across', 'away', 'stand', 'blast']
COLOURS = ['#4caf50', '#5c8fd6', '#e8913a', '#7a7d8a', '#e5534b']
LABELS = {'toward': 'first course toward the door', 'across': 'across (no nearer, no farther)',
          'away': 'first course away from the door', 'stand': 'stands ("on the target")',
          'blast': 'NuclearBlast where it stands'}
BG, PANEL, TEXT, DIM = '#0e0e14', '#181820', '#d2d2dc', '#787887'


_SEEDS = {}
_seed_rng = L.seed_rng


def cached_seed_rng(m, seed):
    """path_lab's seed_rng (thousands of generator draws), done once per seed"""
    if seed not in _SEEDS:
        t = bytearray(0x10000)
        _seed_rng(t, seed)
        _SEEDS[seed] = (bytes(t[P.RANDOM_SEED:P.RANDOM_SEED + 4]), t[P.RANDOM_INDEX])
    s, i = _SEEDS[seed]
    m[P.RANDOM_SEED:P.RANDOM_SEED + 4] = s
    m[P.RANDOM_INDEX] = i


L.seed_rng = cached_seed_rng


def effect(x, y, d):
    if d['rule'] == 'blast':
        return 'blast'
    if d['rule'] == 'arrived':
        return 'stand'
    c = d.get('course') or 0
    if not c:
        return 'stand'
    ty = DOOR[1] + 3 if x != DOOR[0] else DOOR[1]
    dx, dy = {P.RIGHT: (1, 0), P.LEFT: (-1, 0), P.DOWN: (0, 1), P.UP: (0, -1)}[c]
    before = abs(x - DOOR[0]) + abs(y - ty)
    after = abs(x + dx - DOOR[0]) + abs(y + dy - ty)
    return 'toward' if after < before else 'away' if after > before else 'across'


def run(order, owner, game, step, seeds):
    base = L.empty_world()
    L.flatten(base, 14, 502)
    L.only_target(base, 2, *DOOR, owner=owner, table=P.FACTORIES)
    if game == 'ANE':
        base[0xFDFC:0xFDFF] = bytes(3)      # ANE in play: nothing at $FDFC-$FDFE
    else:
        assert bytes(base[0xFDFC:0xFDFF]) == b'\x00\xc3\x66', 'NE: 0, JP, Handler low byte'
    xs = list(range(16, 501, step))
    grid, count = [], collections.Counter()
    for y in range(1, 16):
        row = []
        for x in xs:
            m = bytearray(base)
            L.add_robot(m, 0, x, y, parts=L.BIPOD | L.CANNON | (0x40 if order == 4 else 0), order=order,
                        facing=P.UP)
            effs = collections.Counter(effect(x, y, L.first_decision(m, 0, 0xFF, s)) for s in range(seeds))
            count.update(effs)
            row.append(EFFECTS.index(effs.most_common(1)[0][0]))
        grid.append(row)
    return xs, grid, count


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--seeds', type=int, default=6)
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'diff', 'steer-bug.png'))
    a = p.parse_args()
    cases = [(6, 0x00, 'order 6, capture a neutral factory'), (4, 0x20, 'order 4, destroy an enemy factory (nuclear)')]
    fig, axes = plt.subplots(2, 2, figsize=(13, 6.6), facecolor=BG)
    cmap = ListedColormap(COLOURS)
    for r, (order, owner, title) in enumerate(cases):
        for c, game in enumerate(('NE', 'ANE')):
            xs, grid, count = run(order, owner, game, a.step, a.seeds)
            n = sum(count.values())
            shares = ', '.join(f'{k} {count[k] / n:.0%}' for k in EFFECTS if count[k])
            print(f'{game} {title}: {shares}')
            ax = axes[r][c]
            ax.set_facecolor(PANEL)
            ax.imshow(grid, cmap=cmap, vmin=0, vmax=len(EFFECTS) - 1, aspect='auto', interpolation='nearest',
                      extent=(xs[0] - a.step / 2, xs[-1] + a.step / 2, 15.5, 0.5))
            ax.plot([DOOR[0]], [DOOR[1]], marker='s', color='white', ms=7, mec='black')
            ax.annotate('the door', DOOR, (DOOR[0] + 30, DOOR[1] - 4), color='white', fontsize=8,
                        arrowprops=dict(arrowstyle='->', color='white', lw=0.8))
            aim = 'aim: column $C300, row $66 (JP, Handler)' if game == 'NE' else 'aim: column 0, row 0 (zeros)'
            ax.set_title(f'{game}: {title}\n{aim}\n{shares}', color=TEXT, fontsize=8.5, loc='left')
            ax.axvline(255.5, color=DIM, lw=0.6, ls='--')
            ax.tick_params(colors=DIM, labelsize=7)
            for s in ax.spines.values():
                s.set_color(DIM)
            ax.set_xlabel('the robot\'s map column', color=DIM, fontsize=7)
            ax.set_ylabel('row', color=DIM, fontsize=7)
    fig.legend(handles=[Patch(color=COLOURS[i], label=LABELS[k]) for i, k in enumerate(EFFECTS)], loc='lower center',
               ncol=5, frameon=False, labelcolor=TEXT, fontsize=8)
    fig.suptitle('The first step after a new target reads $FDFC-$FDFE: NE stands or blows up on the left half, '
                 'ANE turns left, toward column 0', color=TEXT, fontsize=11, x=0.01, ha='left')
    fig.text(0.01, 0.925, f'One robot (bipod, cannon), flat map, one target factory, the most frequent first course '
             f'of {a.seeds} generator states per cell; NE\'s model of WorldTurn (same code in both games). '
             'Dashed: column 256.', color=DIM, fontsize=8)
    fig.tight_layout(rect=(0, 0.05, 1, 0.92))
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    fig.savefig(a.out, dpi=100, facecolor=BG)
    print('wrote', a.out)


if __name__ == '__main__':
    main()

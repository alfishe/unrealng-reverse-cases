#!/usr/bin/env python3
"""Doc 13 figure: one robot's walk around an obstacle, decision by decision (docs/img/path/walk-*.gif).

    python3 tools/fig_path_walk.py --shape wall-top-gap --order 6 --seed 11 --out docs/img/path/walk-wall.gif

A test world of tools/path_lab.py (the obstacle, one robot, one target door) run on tools/path_model.py, which
matches the game byte for byte (tools/path_check.py). One picture per robot step (`RobotStep` at delay 0): the free
set FreeDirections found, the course it took, and why.
"""
import argparse
import os
import sys
import textwrap

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle, FancyArrowPatch  # noqa: E402
from PIL import Image  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import path_lab as L  # noqa: E402
import path_model as P  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8d99'
BLOCK, FOOT, FREE, COURSE, TRAIL, DOOR_C, AIM = '#7a5c3a', '#3d6fb5', '#4caf50', '#f2c84b', '#5c8fd6', '#e5534b', \
    '#c77ddb'
VEC = {P.RIGHT: (1, 0), P.LEFT: (-1, 0), P.DOWN: (0, 1), P.UP: (0, -1)}
WHY = {
    'keep': 'keeps its course (+$06 left, the way is free)',
    'boxed': 'nothing free: stands',
    'fire': 'an opponent ahead: fires',
    'ahead': 'an opponent ahead: moves on',
    'turn-to-enemy': 'an opponent to a side: turns to it',
}
RULE = {
    'far-lean': '8+ columns away: leans to the door\'s side (RobotLeanTo), rows ignored',
    'near-wanted': 'under 8 columns: a free wanted direction',
    'near-wanted-keep': 'under 8 columns: a free wanted direction, +$06 = |dx| - 1',
    'near-any': 'under 8 columns, no wanted one free: any free one',
    'arrived': 'on the door: faces down and stands',
    'lean': 'leans right (RobotLeanTo)',
}
LEAN = {'first': 'the first coin', 'second': 'the second coin', 'pick': 'both coins lost: another free one',
        'blocked': 'the wanted side blocked: any free one, back included'}


def frame(world0, entries, k, window, door, title):
    e = entries[k]
    fig = plt.figure(figsize=(9, 4.9), dpi=100)
    fig.patch.set_facecolor(BG)
    ax = fig.add_axes([0.05, 0.3, 0.93, 0.62])
    ax.set_facecolor(AX)
    x0, x1 = window
    ax.set_xlim(x0 - 0.5, x1 + 0.5)
    ax.set_ylim(15.5, -0.5)
    ax.set_aspect('equal')
    for x in range(x0, x1 + 1):
        for y in range(16):
            v = world0[P.cell_address(x, y)]
            if (v & 0x1F) >= 0x08:
                ax.add_patch(Rectangle((x - 0.5, y - 0.5), 1, 1, color=BLOCK))
    ax.add_patch(Rectangle((door[0] - 0.5, door[1] - 0.5), 1, 1, fill=False, ec=DOOR_C, lw=2))
    ax.text(door[0], door[1] - 0.95, 'door', color=DOOR_C, ha='center', fontsize=8)
    ax.axhline(door[1] + 3, color=AIM, lw=1, ls=':')
    ax.text(x1 + 0.3, door[1] + 3 - 0.25, 'aimed row: door + 3', color=AIM, ha='right', fontsize=8)
    trail = [(p['x'], p['y']) for p in entries[:k + 1]]
    ax.plot([t[0] + 0.5 for t in trail], [t[1] - 0.5 for t in trail], color=TRAIL, lw=1.2, alpha=0.8)
    x, y = e['x'], e['y']
    ax.add_patch(Rectangle((x - 0.5, y - 1.5), 2, 2, color=FOOT, alpha=0.75))
    cx, cy = x + 0.5, y - 0.5
    for d, (dx, dy) in VEC.items():
        if e['free'] & d:
            ax.add_patch(FancyArrowPatch((cx + dx * 1.1, cy + dy * 1.1), (cx + dx * 2.3, cy + dy * 2.3),
                                         arrowstyle='-|>', mutation_scale=10, color=FREE, lw=1.4))
    if e['course']:
        dx, dy = VEC[e['course']]
        ax.add_patch(FancyArrowPatch((cx, cy), (cx + dx * 2.6, cy + dy * 2.6), arrowstyle='-|>', mutation_scale=16,
                                     color=COURSE, lw=2.6))
    ax.set_xticks(range(x0, x1 + 1, 5))
    ax.set_yticks(range(0, 16, 3))
    ax.tick_params(colors=DIM, labelsize=7)
    for s in ax.spines.values():
        s.set_color('#2c2e38')
    ax.set_xlabel('map column', color=DIM, fontsize=8)
    ax.set_ylabel('row', color=DIM, fontsize=8)
    fig.suptitle(title, color=FG, fontsize=11, y=0.97)
    why = WHY.get(e['branch'], '')
    if e['branch'] == 'steer':
        why = RULE.get(e.get('rule'), e.get('rule') or '')
        if e.get('lean'):
            why += f"; {LEAN[e['lean']]}"
        why += f"; new course of {e['course_len']} steps"
    if e['facing'] != e['course'] and e['course']:
        why += ' (a turn first: costs this step)'
    lines = [f"step {k + 1} of {len(entries)}, game turn {e['turn']}:  anchor ({x}, {y}), free {P.bits(e['free']) or '-'},"
             f" course {P.bits(e['course']) or 'stand'}, +$06 {e['steps_out']}",
             ] + textwrap.wrap(why, 105)
    for i, line in enumerate(lines):
        fig.text(0.04, 0.2 - 0.05 * i, line, color=FG if i == 0 else COURSE, fontsize=9.5)
    legend = [(FOOT, 'the robot (2 x 2)'), (FREE, 'free directions'), (COURSE, 'the course taken'),
              (TRAIL, 'its path so far'), (BLOCK, 'cells it cannot enter')]
    for i, (c, t) in enumerate(legend):
        fig.text(0.04 + 0.19 * i, 0.03, '■ ' + t, color=c, fontsize=8.5)
    fig.canvas.draw()
    img = Image.frombuffer('RGBA', fig.canvas.get_width_height(), fig.canvas.buffer_rgba()).convert('RGB')
    plt.close(fig)
    return img


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--shape', default='wall-top-gap')
    p.add_argument('--order', type=int, default=6)
    p.add_argument('--loco', default='bipod')
    p.add_argument('--seed', type=int, default=0)
    p.add_argument('--cap', type=int, default=3000)
    p.add_argument('--window', default='280,325')
    p.add_argument('--title')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    m = L.scenario(args.shape, args.order, parts=L.PARTS[args.loco])
    t, steps, track, w = L.trial(m, args.seed, args.order, args.cap, keep_log=True)
    entries = [e for e in w.log if e['slot'] == 0]
    print(f'{args.shape} order {args.order} seed {args.seed}: {t} turns, {len(entries)} decisions')
    window = tuple(int(v) for v in args.window.split(','))
    title = args.title or f'{args.shape}, order {args.order}: {len(entries)} steps, {t} game turns to the door'
    pics = [frame(m, entries, k, window, L.DOOR, title) for k in range(len(entries))]
    K.save_gif(args.out, pics, [350] * (len(pics) - 1) + [3000])
    print(args.out)


if __name__ == '__main__':
    main()

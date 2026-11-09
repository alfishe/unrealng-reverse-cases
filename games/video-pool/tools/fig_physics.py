#!/usr/bin/env python3
"""Figures of docs/10-gameplay-logic.md: the friction table, the table geometry, the contact table, the break of w1
against the physics model, and the course of w1.

    python3 tools/fig_physics.py friction   --image work/mkgame/original.bin --samples work/docs/vpC/w1-break.jsonl \
        --out docs/img/physics/friction.png
    python3 tools/fig_physics.py geometry   --table work/docs/vpC/shots/t707.png --out docs/img/physics/geometry.png
    python3 tools/fig_physics.py contact    --image work/mkgame/original.bin --out docs/img/physics/contact.png
    python3 tools/fig_physics.py trajectory --image work/mkgame/original.bin --samples work/docs/vpC/w1-break.jsonl \
        --table work/docs/vpC/shots/t707.png --shot 1085,252,130,76 --out docs/img/physics/trajectory.png
    python3 tools/fig_physics.py course     --samples work/docs/vpC/w1-course.jsonl --out docs/img/physics/course.png

The tables are read from the 64 K image (FrictionTable $DD3A, ContactTable $DBFA, CollisionRecords $DE3A). The
samples are JSON lines {"frame", "hex"} read with TTD memory_at by work/docs/vpC/sample.py: the ball block
$8A88-$8B4D for the break, the player variables $9F43-$9F50 for the course. The trajectory runs tools/physics_model.py.
"""
import argparse
import json
import math
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Circle, Rectangle  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import physics_model as P  # noqa: E402

plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'figure.dpi': 100, 'savefig.dpi': 100,
                     'font.family': 'DejaVu Sans'})
BALL = ['#ffffff', '#e00000', '#0030e6', '#c800c8', '#fa8c00', '#000000', '#00969f']
EDGE = ['#000000', '#600000', '#001060', '#500050', '#603000', '#ffffff', '#003040']
W = 10.5


def samples(path):
    return [(d['frame'], bytes.fromhex(d['hex'])) for d in map(json.loads, open(path))]


def table_axes(ax, png):
    img = plt.imread(png)
    ax.imshow(img, extent=(0, 256, 192, 0), interpolation='nearest')
    ax.set_xlim(0, 256)
    ax.set_ylim(192, 40)
    ax.set_xlabel('x (screen pixels)')
    ax.set_ylabel('y (screen pixels)')


def save(fig, out):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    fig.savefig(out)
    print(out)


# ---------------------------------------------------------------------------------------------------------------------

def fig_friction(args):
    m = open(args.image, 'rb').read()
    fig, (a, b) = plt.subplots(1, 2, figsize=(W, 5.2), gridspec_kw={'width_ratios': [1, 1.25]})
    for ny in range(16):
        for nx in range(16):
            v = m[P.FRICTION + 16 * ny + nx]
            sx, sy = v & 15, v >> 4
            if sx or sy:
                a.arrow(nx, ny, sx * 0.17, sy * 0.17, head_width=0.18, length_includes_head=True, color='#1060c0')
            else:
                a.plot(nx, ny, '.', color='#999999', ms=3)
    a.set_xlim(-0.6, 16.4)
    a.set_ylim(16.4, -0.6)
    a.set_aspect('equal')
    a.set_xticks(range(0, 16, 3))
    a.set_yticks(range(0, 16, 3))
    a.set_xlabel('nx: |vx| shifted until bit 3 of a high byte is set')
    a.set_ylabel('ny: the same shift of |vy|')
    a.set_title('FrictionTable $DD3A: the step (x, y), magnitude 5')

    rows = samples(args.samples)
    fr, sp, fx = [], [], []
    for f, raw in rows:
        c = P.Ball(raw[:14])
        if not c.flags & 0x40 and f > 1086:
            break
        fr.append(f)
        sp.append(math.hypot(P.s16(c.vx), P.s16(c.vy)) / 256)
        fx.append(math.hypot(P.s8(c.fx), P.s8(c.fy)))
    b.plot(fr, sp, '-', color='#1060c0', lw=2, label='cue ball speed (pixels a tick), w1')
    b.axvline(1117, color='#c00000', ls='--', lw=1)
    b.text(1119, max(sp) * 0.62, 'frame 1117:\nhits ball 1', color='#c00000', va='top')
    k = next(i for i, v in enumerate(sp) if v > 0)
    t0, v0 = fr[k], sp[k]
    line = [v0 - 5 / 256 * (f - t0) - 0.25 for f in fr[k:k + 31]]
    b.plot(fr[k:k + 31], line, ':', color='#000000', lw=1.5, label='slope 5/256 a tick (shifted down 0.25)')
    b.set_xlabel('w1 frame (one tick a frame)')
    b.set_ylabel('pixels a tick')
    b.set_title('The break: the cue ball slows by friction')
    b.legend(loc='lower left', fontsize=10)
    b.grid(alpha=0.3)
    fig.suptitle('Rolling friction: a table of steps instead of a division (w1 frames %d-%d)' % (fr[0], fr[-1]))
    fig.tight_layout()
    save(fig, args.out)


# ---------------------------------------------------------------------------------------------------------------------

def fig_geometry(args):
    fig, ax = plt.subplots(figsize=(W, 8.6))
    table_axes(ax, args.table)
    ax.set_ylim(196, 36)
    ax.set_xlim(-2, 258)
    kw = dict(lw=1.8)
    # cushion lines (the ball centre's limits)
    ax.plot([23, 115], [65, 65], color='#ffd000', **kw, label='cushion lines x 17 / 238, y 65 / 166 (centre limits)')
    for xs, y in (([140, 232], 65), ([23, 115], 166), ([140, 232], 166)):
        ax.plot(xs, [y, y], color='#ffd000', **kw)
    for x in (17, 238):
        ax.plot([x, x], [71, 160], color='#ffd000', **kw)
    # corner diagonals
    ax.plot([8, 23], [56, 71], color='#ff3030', **kw, label='corner channels y-x=48, x+y=183, x+y=303, x-y=72')
    ax.plot([8, 23], [175, 160], color='#ff3030', **kw)
    ax.plot([247, 232], [56, 71], color='#ff3030', **kw)
    ax.plot([247, 232], [175, 160], color='#ff3030', **kw)
    # middle channels and jaw points
    for y0, y1 in ((56, 65), (166, 175)):
        ax.plot([122, 122], [y0, y1], color='#00e0ff', **kw)
        ax.plot([134, 134], [y0, y1], color='#00e0ff', **kw)
    ax.plot([], [], color='#00e0ff', **kw, label='middle channel walls x 122.0 / 133.996')
    for x in (115, 140):
        for y in (58, 173):
            ax.add_patch(Circle((x, y), 7.3, fill=False, ec='#ff60ff', lw=1.8))
    ax.plot([], [], 'o', mfc='none', mec='#ff60ff', ms=10, label='jaw points (115 / 140, 58 / 173), radius about 7')
    # potting boundary and the clamps
    ax.add_patch(Rectangle((8, 56), 239, 119, fill=False, ec='#ffffff', lw=1.5, ls='--'))
    ax.plot([], [], color='#ffffff', ls='--', label='potted when the centre leaves x 8..247, y 56..175')
    # pocket boxes (large)
    for x0, x1 in ((8, 15), (122, 133), (240, 247)):
        for y0, y1 in ((56, 63), (168, 175)):
            ax.add_patch(Rectangle((x0, y0), x1 - x0, y1 - y0, fill=True, fc='#ffffff', alpha=0.35, ec='none'))
    ax.plot([], [], 's', color='#ffffff', alpha=0.5, ms=10, label='pocket boxes: a potted ball is snapped inside')
    # cursor perimeter and the break line
    ax.add_patch(Rectangle((3, 51), 249, 129, fill=False, ec='#ff9000', lw=1.5, ls=':'))
    ax.plot([], [], color='#ff9000', ls=':', label='aim cursor track x 3..252, y 51..180 (756 places)')
    ax.annotate('', xy=(252, 130), xytext=(40.5, 115.5),
                arrowprops=dict(arrowstyle='->', color='#ffffff', lw=1.5, ls='-'))
    ax.text(150, 120, 'w1 break: cue (40, 115) to cursor (252, 130)', color='#ffffff', fontsize=10, ha='center')
    for n, (x, y) in enumerate(((10, 47), (127, 47), (244, 47), (244, 189), (127, 189), (10, 189))):
        ax.text(x, y, 'pocket %d' % (n + 1), color='#000000', fontsize=10, ha='center', va='center',
                bbox=dict(fc='#ffffff', ec='none', alpha=0.8, pad=1))
    fig.legend(*ax.get_legend_handles_labels(), loc='lower center', ncol=2, fontsize=10, frameon=True,
               facecolor='#303030', labelcolor='#ffffff')
    ax.set_title('The table as the code sees it: large pockets (CushionsLarge $8FBB), ball centres, whole pixels')
    fig.subplots_adjust(left=0.07, right=0.98, top=0.95, bottom=0.25)
    save(fig, args.out)


# ---------------------------------------------------------------------------------------------------------------------

def coef(m, a):
    h = m[a + 1]
    return 1.0 if h else m[a] / 256


def fig_contact(args):
    m = open(args.image, 'rb').read()
    fig, (a, b) = plt.subplots(1, 2, figsize=(W, 5.4), gridspec_kw={'width_ratios': [1.1, 1]})
    for dy in range(16):
        for dx in range(16):
            v = m[P.CONTACT + 16 * dy + dx]
            if v == 0x80:
                a.add_patch(Rectangle((dx - .5, dy - .5), 1, 1, fc='#d04040', ec='#ffffff', lw=.5))
            elif v:
                a.add_patch(Rectangle((dx - .5, dy - .5), 1, 1, fc='#40a040', ec='#ffffff', lw=.5))
                a.text(dx, dy, str(v), ha='center', va='center', fontsize=7.5, color='#ffffff')
            else:
                a.add_patch(Rectangle((dx - .5, dy - .5), 1, 1, fc='#e8e8e8', ec='#ffffff', lw=.5))
    a.add_patch(Rectangle((10 - .5, 11 - .5), 1, 1, fill=False, ec='#000000', lw=2.5))
    a.annotate('w1 tick 32:\n|dx| 10, |dy| 11', xy=(10.4, 11.4), xytext=(11.5, 14.6), fontsize=10,
               arrowprops=dict(arrowstyle='->'))
    a.set_xlim(-.5, 15.5)
    a.set_ylim(15.5, -.5)
    a.set_aspect('equal')
    a.set_xlabel('|dx| (whole pixels)')
    a.set_ylabel('|dy|')
    a.set_title('ContactTable $DBFA[16|dy| + |dx|]\nred $80 overlap, green ring 1-31, grey apart')

    ns = list(range(1, 32))
    w0 = [coef(m, P.RECORDS + 6 * (n - 1)) for n in ns]
    w1 = [coef(m, P.RECORDS + 6 * (n - 1) + 2) for n in ns]
    w2 = [coef(m, P.RECORDS + 6 * (n - 1) + 4) for n in ns]
    b.plot(ns, w0, 'o-', ms=3, label='w0 = nx²', color='#1060c0')
    b.plot(ns, w1, 's-', ms=3, label='w1 = ny²', color='#c06000')
    b.plot(ns, w2, '^-', ms=3, label='w2 = |nx ny|', color='#808080')
    b.plot(ns, [x + y for x, y in zip(w0, w1)], 'k-', lw=2, label='w0 + w1 (1.0 is exact)')
    b.axhline(1.0, color='#000000', lw=.8, ls=':')
    b.axvline(17, color='#c00000', ls='--', lw=1)
    b.text(17.4, 0.52, 'ring 17\n(tick 32)', color='#c00000', fontsize=10)
    b.set_xlabel('ring entry n (record $DE3A + 6(n-1))')
    b.set_ylabel('coefficient (0.8 fixed point)')
    b.set_title('CollisionRecords: the three coefficients per ring')
    b.legend(fontsize=10, loc='center left')
    b.grid(alpha=0.3)
    fig.suptitle('Ball against ball without trigonometry: the offset picks a precomputed line of centres')
    fig.tight_layout()
    save(fig, args.out)


# ---------------------------------------------------------------------------------------------------------------------

def fig_trajectory(args):
    frame0, cx, cy, power = (int(v) for v in args.shot.split(','))
    model = P.Model(open(args.image, 'rb').read())
    rows = [(f, raw[:98]) for f, raw in samples(args.samples) if f >= frame0]
    balls = P.Balls(rows[0][1])
    model.shot(balls, (cx, cy), power)
    model.friction_steps(balls.b[0])
    track = [[(b.x / 256, b.y / 256)] for b in balls.b]
    events = []
    tick = 0
    for frame, want in rows[1:]:
        lost = 0
        while balls.raw() != want and lost < 3 and tick < 800:
            model.tick(balls)
            tick += 1
            lost += 1
            for i, b in enumerate(balls.b):
                if b.flags & 0x80 and not b.flags & 0x20 and (b.x, b.y) != (int(track[i][-1][0] * 256),
                                                                            int(track[i][-1][1] * 256)):
                    track[i].append((b.x / 256, b.y / 256))
            for e in balls.events:
                b = balls.b[e[1]]
                events.append((e[0], e[1], b.x / 256, b.y / 256, frame))
        if balls.raw() != want:
            break
    fig, ax = plt.subplots(figsize=(W, 7.1))
    table_axes(ax, args.table)
    ax.set_ylim(186, 44)
    ax.set_anchor('N')
    for i in range(7):
        xs = [p[0] for p in track[i]]
        ys = [p[1] for p in track[i]]
        if len(xs) > 1:
            ax.plot(xs, ys, '-', color=BALL[i], lw=1.6, path_effects=None)
            if i == 0:
                ax.plot(xs, ys, '-', color=EDGE[i], lw=0.6)
    for f, raw in rows[::3]:
        for i in range(7):
            b = P.Ball(raw[14 * i:14 * i + 14])
            if b.flags & 0x40:
                ax.plot(b.x / 256, b.y / 256, 'o', ms=3.2, mfc=BALL[i], mec=EDGE[i], mew=0.6)
    mark = {'contact': ('*', '#ffff00', 13), 'cushion': ('D', '#00ffff', 7), 'pot': ('X', '#ff00ff', 12)}
    shown = set()
    for name, i, x, y, f in events:
        if name == 'stop':
            continue
        key = 'contact' if 'contact' in name or 'exchange' in name else 'pot' if 'pot' in name else 'cushion'
        sym, col, size = mark[key]
        ax.plot(x, y, sym, color=col, ms=size, mec='#000000', mew=0.8,
                label=None if key in shown else {'contact': 'ball-ball exchange (model)', 'cushion':
                                                 'cushion or jaw bounce (model)', 'pot': 'pot: ball 5 into pocket 3 (model)'}[key])
        shown.add(key)
    ax.plot([], [], 'o', ms=4, mfc='#cccccc', mec='#000000', label='recorded position, every 3rd frame (w1)')
    ax.plot([], [], '-', color='#cccccc', lw=2, label='model path, one point a tick')
    for i, name in enumerate(('cue ball', 'ball 1', 'ball 2', 'ball 3', 'ball 4', 'ball 5', 'ball 6')):
        ax.plot([], [], 's', ms=9, mfc=BALL[i], mec='#000000', label=name)
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.1), ncol=4, fontsize=10, frameon=False,
              handletextpad=0.4, columnspacing=1.2)
    ax.set_title('The break of w1 (frames %d-%d): recorded positions on the model of tools/physics_model.py'
                 % (frame0, frame))
    fig.subplots_adjust(left=0.07, right=0.98, top=0.95, bottom=0.2)
    save(fig, args.out)
    for e in events:
        print(' ', e)


# ---------------------------------------------------------------------------------------------------------------------

def fig_course(args):
    rows = samples(args.samples)
    fr = [f for f, _ in rows]
    score = [(r[2] | r[3] << 8) * 10 for _, r in rows]
    frame = [r[8] for _, r in rows]
    shots = [r[10] for _, r in rows]
    lives = [r[11] if r[11] < 128 else -1 for _, r in rows]
    fig, ax = plt.subplots(4, 1, figsize=(W, 7.6), sharex=True, gridspec_kw={'height_ratios': [2, 1, 1, 1]})
    ax[0].step(fr, score, where='post', color='#1060c0', lw=2)
    ax[0].set_ylabel('score')
    ax[1].step(fr, frame, where='post', color='#008000', lw=2)
    ax[1].set_ylabel('frame')
    ax[2].step(fr, shots, where='post', color='#c06000', lw=2)
    ax[2].set_ylabel('shots left')
    ax[3].step(fr, lives, where='post', color='#c00000', lw=2)
    ax[3].set_ylabel('lives')
    ax[3].text(11800, -0.6, '-1: GAME OVER', color='#c00000', fontsize=10, va='center', ha='right')
    ax[3].set_xlabel('w1 frame (50 a second)')
    for a in ax:
        a.grid(alpha=0.3)
    ax[0].set_title('The course of w1: score, frame number, shots left and lives (\\$9F43-\\$9F50, every 5th frame)')
    fig.tight_layout()
    save(fig, args.out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['friction', 'geometry', 'contact', 'trajectory', 'course'])
    p.add_argument('--image')
    p.add_argument('--samples')
    p.add_argument('--table')
    p.add_argument('--shot')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    globals()['fig_' + args.what](args)


if __name__ == '__main__':
    main()

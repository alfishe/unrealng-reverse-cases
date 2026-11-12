#!/usr/bin/env python3
"""Doc 10's figures: the jump scripts against Hiro's measured jumps, the fall damage, Hiro's sequence slots over play48,
the points.

    python3 tools/fig_gameplay.py [--only NAME[,NAME]] [--out docs/img/gameplay]

The scripts are read from work/stage2/rec/play48/end.szx (StandScript $7B00, WalkScript $7A51, RunScript $7A7A:
[count][speed][X offset left][X offset right][size class], then count steps of [frame][Y step][X step]). Hiro's
positions come from work/docs/zsC/play48-hiro.jsonl (TTD memory_at, the state at the start of each frame; frames
519-3768 of play48: $5D00 66 bytes, $6642 24 bytes, $6BDD).

The throw figure reads work/docs/fixC/throw-shots.jsonl: the `throw` recording sampled the same way (frames 1885-2240
and 2590-2750: $5D00 66 bytes, the shot's page $6600 66 bytes, $6642 24 bytes), made with
`python3 work/docs/fixC/sample.py --work W --from F --to G --range 5D00:66 --range 6600:66 --range 6642:24 --out OUT`
on an instance holding work/stage2/rec/throw/session.ttd.

Names: jumps, fall, slots, points, throw.
"""
import argparse
import json
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
SAMPLES = os.path.join(CASE, 'work', 'docs', 'zsC')
plt.rcParams.update({'font.size': 11, 'text.parse_math': False})  # '$' is a hex sign here, never math

SCRIPTS = [(0x7B00, 'StandScript $7B00 (11 steps)', 'tab:blue', 1098),
           (0x7A51, 'WalkScript $7A51 (12 steps)', 'tab:green', 1551),
           (0x7A7A, 'RunScript $7A7A (16 steps)', 'tab:red', 680)]


def sgn(b):
    return b - 256 if b > 127 else b


def memory():
    import fig_rooms as FR
    return FR.snapshot_ram(os.path.join(CASE, 'work', 'stage2', 'rec', 'play48', 'end.szx'))


def script_path(m, a):
    n = m[a]
    x = y = 0
    pts = [(0, 0)]
    for i in range(n):
        _frame, dy, dx = m[a + 5 + 3 * i], sgn(m[a + 6 + 3 * i]), sgn(m[a + 7 + 3 * i])
        x, y = x + dx, y + dy
        pts.append((x, y))
    return pts


def hiro():
    rows = {}
    for line in open(os.path.join(SAMPLES, 'play48-hiro.jsonl')):
        d = json.loads(line)
        rows[d['frame']] = bytes.fromhex(d['5D00'])
    return rows


def fig_jumps(out):
    m = memory()
    rows = hiro()
    fig, ax = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    for a, name, col, start in SCRIPTS:
        pts = script_path(m, a)
        ax[0].plot([p[0] for p in pts], [p[1] for p in pts], '-o', color=col, ms=4, label=name)
        x0, y0 = rows[start - 1][1], rows[start - 1][0]
        meas = [(sgn((rows[f][1] - x0) & 255), rows[f][0] - y0) for f in range(start, start + 34)]
        ax[0].plot([p[0] for p in meas], [p[1] for p in meas], ':', color=col, lw=2)
        ax[1].plot(range(0, 34), [rows[start + k][0] for k in range(34)], '-', color=col,
                   label='play48 from frame %d' % start)
    ax[0].invert_yaxis()
    ax[0].set_xlabel('X step sum (game units: 2 a step, a cell is 8)')
    ax[0].set_ylabel('Y (pixels, up is negative)')
    ax[0].set_title('the scripts (solid) and play48 (dotted)', fontsize=11)
    ax[0].legend(fontsize=9, loc='lower right')
    ax[1].invert_yaxis()
    ax[1].set_xlabel('frames after the jump key was taken')
    ax[1].set_ylabel('Hiro\'s Y $5D00 (pixels, decimal)')
    ax[1].set_title('Y per frame: a step every 2 frames, then the fall', fontsize=11)
    ax[1].legend(fontsize=9)
    for a in ax:
        a.grid(alpha=0.3)
    fig.suptitle('The three jumps: fixed scripts, the hover cut short by the head test, the fall 4 pixels a frame',
                 fontsize=13, fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


def fig_fall(out):
    steps = list(range(0, 41))
    loss = [2 * min(s - 17, 14) if s >= 20 else 0 for s in steps]
    fig, ax = plt.subplots(figsize=(10.5, 3.9), dpi=100)
    ax.step(steps, loss, where='mid', color='tab:red', label='energy the landing takes (HiroLanded $90C3)')
    ax.axhline(32, color='tab:blue', ls='--', lw=1, label='full energy $20 (32)')
    ax.axvline(19.5, color='k', ls=':', lw=1)
    ax.annotate('play48: 32 steps from room 8 into room 9; 14 damage steps;\na touch took 4 at frame 3016, the 6th step the life (frame 3045)',
                xy=(32, 28), xytext=(0.5, 22), arrowprops={'arrowstyle': '->'}, fontsize=10)
    ax.text(4, 12, '1-19 steps: a 1-frame crouch (LandScript $7AB6), no loss', fontsize=10)
    ax.set_xlabel('fall steps +$26 (4 pixels each, counted by FallStep across room changes)')
    ax.set_ylabel('energy lost')
    ax.legend(fontsize=10, loc='lower right')
    ax.grid(alpha=0.3)
    fig.suptitle('Fall damage: nothing below 20 steps, then 6 to 28 energy, 2 a step every 5 frames', fontsize=13, fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


SLOTS = ['+30 jump', '+31 fall/hurt', '+32 pose', '+33 turn', '+34 action', '+35 hard landing', '+36 hang',
         '+37 death', '+38 rise']


def fig_slots(out):
    rows = hiro()
    fr = sorted(rows)
    lanes = SLOTS + ['+02 bit 1 airborne', '+02 bit 3 ladder', '+10 bit 4 hurt']
    tests = [lambda h, k=k: h[0x30 + k] != 0 for k in range(9)] + [
        lambda h: h[2] & 2, lambda h: h[2] & 8, lambda h: h[0x10] & 0x10]
    colours = ['tab:blue', 'tab:orange', 'tab:green', 'tab:purple', 'tab:red', 'tab:brown', 'tab:pink', 'k', 'tab:olive',
               'tab:cyan', 'tab:gray', 'tab:red']
    fig, ax = plt.subplots(figsize=(10.5, 4.8), dpi=100)
    for i, (t, col) in enumerate(zip(tests, colours)):
        spans, start = [], None
        for f in fr:
            on = bool(t(rows[f]))
            if on and start is None:
                start = f
            if not on and start is not None:
                spans.append((start, f - start))
                start = None
        if start is not None:
            spans.append((start, fr[-1] - start))
        ax.broken_barh(spans, (i - 0.35, 0.7), color=col)
        ax.text(fr[-1] + 20, i, '%d' % len(spans), va='center', fontsize=10)
    ax.set_yticks(range(len(lanes)))
    ax.set_yticklabels(lanes, fontsize=10)
    ax.invert_yaxis()
    ax.set_xlim(fr[0], fr[-1] + 80)
    ax.set_xlabel('play48 frame (memory_at, the state at the frame start); the number at the right: how many times')
    ax.grid(axis='x', alpha=0.3)
    fig.suptitle('Hiro\'s sequence slots over play48: jumps, strikes, hurts, falls; no hang, death or rise',
                 fontsize=13, fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


POINTS = [('gem 1-5', [50, 100, 200, 400, 700]), ('flask $06', [7000]), ('orbs $20-$22', [1000, 2000, 5000]),
          ('reset shields $1C/$1D', [400]), ('a block broken', [10]), ('fragment $18', [10000]),
          ('the 16th fragment', [50000]), ('patrol $2B', [50]), ('traps $2E-$31, $34, chaser $39', [100]),
          ('chaser $37', [200]), ('chasers $38, $3D', [250]), ('chasers $3A-$3C', [300]), ('chaser $2C', [350]),
          ('giants $26-$29', [5000]), ('Havok $25', [50000]), ('a life left at the end', [20000])]


def fig_points(out):
    fig, ax = plt.subplots(figsize=(10.5, 5.2), dpi=100)
    for i, (name, vals) in enumerate(POINTS):
        col = 'tab:green' if i < 7 else ('tab:blue' if i < 13 else 'tab:purple')
        for v in vals:
            ax.plot([v], [i], 'o', color=col, ms=8)
        ax.hlines(i, min(vals), max(vals), color=col, lw=2)
        ax.text(max(vals) * 1.25, i, ', '.join('%d' % v for v in vals), va='center', fontsize=10)
    ax.set_xscale('log')
    ax.set_xlim(5, 400000)
    from matplotlib.ticker import FuncFormatter
    ax.xaxis.set_major_formatter(FuncFormatter(lambda v, _: '%d' % v))  # no mathtext (parse_math is off)
    ax.set_yticks(range(len(POINTS)))
    ax.set_yticklabels([p[0] for p in POINTS], fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel('points (log scale); green pickups, blue enemies, purple bosses and the end')
    ax.grid(axis='x', alpha=0.3)
    fig.suptitle('Where the points come from: AddScore $99E7 records, the fragments and the end dwarf the rest',
                 fontsize=13, fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


def fig_throw(out):
    rows = {}
    for line in open(os.path.join(CASE, 'work', 'docs', 'fixC', 'throw-shots.jsonl')):
        d = json.loads(line)
        rows[d['frame']] = (bytes.fromhex(d['5D00']), bytes.fromhex(d['6600']), bytes.fromhex(d['6642']))
    throws = [(2061, 2186, 'the spinblade (kind $43), Charge 20 at 2061, facing right', 'tab:red'),
              (2607, 2656, 'the blade (kind $40), Charge 12 at 2607, facing left', 'tab:blue')]
    fig, axes = plt.subplots(2, 2, figsize=(10.5, 6.4), dpi=100, sharex='col')
    for col, (f0, f1, title, c) in enumerate(throws):
        fr = [f for f in range(f0, f1 + 1) if f in rows]
        live = [f for f in fr if rows[f][1][2] & 1]
        ax = axes[0][col]
        ax.plot([f - f0 for f in live], [sgn(rows[f][1][1]) if rows[f][1][1] > 0xC0 else rows[f][1][1] for f in live],
                '.-', color=c, ms=4, lw=1)  # X below 0 (past the left edge) as negative
        ax.plot([f - f0 for f in fr], [rows[f][0][1] for f in fr], '-', color='grey', lw=1)
        ax.set_ylabel('X (half units, 1.5 px; 160 a room)')
        ax.set_title(title, fontsize=10)
        ax.grid(alpha=0.3)
        ax.text(0.02, 0.92 if col == 0 else 0.08, 'dots: the shot (page $66), grey: Hiro', transform=ax.transAxes, fontsize=9)
        ax = axes[1][col]
        ax.step([f - f0 for f in live], [(rows[f][1][0x3F] - 256) if rows[f][1][0x3F] > 127 else rows[f][1][0x3F]
                                         for f in live], where='post', color=c)
        ax.set_ylabel('+$3F, the life left (signed)')
        ax.set_xlabel('frames after the release (frame %d)' % f0)
        ax.grid(alpha=0.3)
    fig.suptitle('Two throws of the throw recording: the shot\'s X and its life, a frame', fontsize=13,
                 fontweight='bold')
    fig.tight_layout()
    fig.savefig(out, dpi=100)


FIGS = {'jumps': fig_jumps, 'fall': fig_fall, 'slots': fig_slots, 'points': fig_points, 'throw': fig_throw}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'gameplay'))
    p.add_argument('--only')
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for name in (a.only.split(',') if a.only else FIGS):
        path = os.path.join(a.out, name + '.png')
        FIGS[name](path)
        print(os.path.relpath(path, CASE))


if __name__ == '__main__':
    main()

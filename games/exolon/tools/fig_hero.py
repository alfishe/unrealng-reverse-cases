"""Figures of the hero in docs/10-gameplay-logic.md (writer fillO).

  python3 tools/fig_hero.py sheet     docs/img/hero/frames.png   PlayerFrames $EF80: the 25 frames by role
  python3 tools/fig_hero.py moves     docs/img/hero/moves.png    x2 frames 380-1000 and c1 16180-16450: X, Y, the
                                                                 frame drawn, JumpStep, per frame (TTD reads)
  python3 tools/fig_hero.py shots     docs/img/hero/shots.png    x2 frames 436-492, 586-630: the shot slots' X

The reads come from work/docs/fillO/reads.py (my instance, x2) and work/docs/fillO/c1read.py (the live c1, memory_at
only) into work/docs/fillO/d/*.json; the commands are in work/docs/fillO-NOTES.md.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

D = os.path.join(B.WORK, 'docs', 'fillO', 'd')

ROLE = {0: 'walk 0', 1: 'walk 1', 2: 'walk 2', 3: 'walk 3\nin the air', 4: 'walk 4', 5: 'walk 5\nstanding',
        6: 'walk 6', 7: 'walk 7', 8: 'walk 8', 9: 'walk 9\nfalling', 10: 'crouching', 11: 'death'}


def frame_px(n):
    """PlayerFrames $EF80: frame n of 96 bytes, 3 bytes across, 32 lines"""
    M = B.image()
    a = 0xEF80 + 96 * n
    px = np.zeros((32, 24))
    for y in range(32):
        for x in range(24):
            px[y, x] = M[a + 3 * y + x // 8] >> (7 - x % 8) & 1
    return px


def sheet():
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 5.6))
    gs = fig.add_gridspec(2, 13, hspace=0.95, wspace=0.12)
    white, green = (1, 1, 1), (0.3, 1, 0.3)
    for n in range(25):
        if n < 12:
            ax = fig.add_subplot(gs[0, n])
        elif n < 24:
            ax = fig.add_subplot(gs[1, n - 12])
        else:
            ax = fig.add_subplot(gs[1, 12])
        px = frame_px(n)
        col = green if n == 24 else white
        ax.imshow(np.dstack([px * col[0], px * col[1], px * col[2]]), interpolation='nearest')
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title(f'{n} ${n:02X}', fontsize=10.5)
        role = 'the trap' if n == 24 else ROLE[n % 12]
        ax.set_xlabel(role, fontsize=10)
    fig.text(0.01, 0.80, 'frames 0-11: ExoSuit $9ED8 = 0 (no suit)', fontsize=11)
    fig.text(0.01, 0.405, 'frames 12-23: ExoSuit = $0C, the same roles in the suit; 24: the trap (Traps $9C15)',
             fontsize=11)
    B.suptitle(fig, 'PlayerFrames $EF80: 25 frames of 24 x 32 (96 bytes each, frame n at $EF80 + 96 n); PlayerFrame '
               '$8224 draws frame A + ExoSuit')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.74, bottom=0.07)
    B.save(fig, B.out('hero', 'frames.png'))


def load(name):
    d = json.load(open(os.path.join(D, name)))
    return d, sorted((int(f), v) for f, v in d['frames'].items())


def moves():
    """x2 frames 380-1000 (the walk, three jumps, the first screen change) and c1 16180-16450 (crouch, turn, step)"""
    _, fr = load('x2-hero.json')
    fr = [(f, v) for f, v in fr if 380 <= f < 1000]
    F = np.array([f for f, _ in fr])
    blk = [bytes.fromhex(v[1]) for _, v in fr]          # $8269-$82FB
    shown = np.array([b[0] for b in blk])
    X = np.array([b[0x82F5 - 0x8269] for b in blk])
    Y = np.array([b[0x82F6 - 0x8269] for b in blk])
    J = np.array([b[0x82F7 - 0x8269] for b in blk])
    scr = np.array([int(v[3], 16) for _, v in fr])
    B.style()
    fig, axs = plt.subplots(4, 1, figsize=(B.WIDTH, 11.0), sharex=True,
                            gridspec_kw={'height_ratios': [1.1, 1, 1, 0.8]})
    ax = axs[0]
    ax.step(F, X, where='post', color=B.COLOURS[0], label='PlayerX $82F5 (2 px a unit)')
    for f in F[1:][np.diff(scr) != 0]:
        ax.axvline(f, color=B.DIM, ls=':', lw=1)
        ax.text(f + 3, 100, f'screen {scr[F == f][0]}\nframe {f}', fontsize=10.5)
    ax.set_ylabel('X')
    ax.legend(loc='upper left')
    ax.set_title('the walk: X + 1 a pass (about 2 frames); X = $80 is the next screen, X back to 0', fontsize=11)
    ax = axs[1]
    ax.step(F, Y, where='post', color=B.COLOURS[1], label='PlayerY $82F6 (pixels, the top line)')
    ax.invert_yaxis()
    ax.set_ylabel('Y (down)')
    ax.legend(loc='lower left')
    ax.set_title('the jumps: 18 px up in 9 passes, 4 level, 9 down (JumpSteps $826A read from 22 down)', fontsize=11)
    ax = axs[2]
    ax.step(F, J, where='post', color=B.COLOURS[2], label='JumpStep $82F7 (22 down to 1, 0 on the ground)')
    ax.set_ylabel('JumpStep')
    ax.legend(loc='upper right')
    ax = axs[3]
    ax.step(F, np.where(shown == 0xFF, np.nan, shown), where='post', color=B.COLOURS[3],
            label='PlayerFrameShown $8269')
    ax.set_yticks([0, 3, 5, 9])
    ax.set_ylabel('frame')
    ax.legend(loc='upper right', ncol=1)
    ax.set_title('the frame drawn: the walk cycle 0-9; 3 in the air; 5 standing', fontsize=11)
    ax.set_xlabel('frame of recording x2 (TTD memory_at at the end of each frame)')
    B.suptitle(fig, 'MovePlayer in x2: walking right 1 unit a pass, four jumps; the third leaves screen 0 at X $80 in the '
               'air and lands on screen 1 (x2 frames 380-1000, read every frame)')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('hero', 'moves.png'))
    # c1: crouch, both keys, the turn, three steps left, the death leap
    d, fr = load('c1-turn.json')
    F = np.array([f for f, _ in fr])
    rows = [bytes.fromhex(v[0]) for _, v in fr]
    X = np.array([r[2] for r in rows])
    Y = np.array([r[3] for r in rows])
    fac = np.array([B.s8(r[7]) for r in rows])
    cr = np.array([r[8] for r in rows])
    shown = np.array([int(v[1], 16) for _, v in fr])
    ctl = [bytes.fromhex(v[4]) for _, v in fr]
    left = np.array([c[0] for c in ctl])
    right = np.array([c[1] for c in ctl])
    duck = np.array([c[3] for c in ctl])
    jump = np.array([c[2] for c in ctl])
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 9.0), sharex=True, gridspec_kw={'height_ratios': [1, 1, 1]})
    ax = axs[0]
    names = ('left $7B92', 'right $7B93', 'up $7B94', 'down $7B95')
    for i, s in enumerate((left, right, jump, duck)):
        ax.fill_between(F, i, i + 0.8 * (s > 0), step='post', color=B.COLOURS[i], lw=0)
    ax.set_yticks([i + 0.4 for i in range(4)])
    ax.set_yticklabels(names, fontsize=10.5)
    ax.set_title('the controls read this pass (ReadControls $7B72)', fontsize=11)
    ax = axs[1]
    ax.step(F, shown, where='post', color=B.COLOURS[3], label='PlayerFrameShown $8269')
    ax.step(F, np.where(cr == 0xFA, 10.6, np.nan), where='post', color=B.COLOURS[4], lw=4,
            label='CrouchOffset $82FB = $FA')
    ax.step(F, 6 + fac * 0.5, where='post', color=B.COLOURS[5], label='Facing $82FA: up 1, down $FF')
    ax.set_yticks([0, 2, 5, 10, 11])
    ax.set_ylabel('frame')
    ax.legend(loc='lower center', fontsize=10)
    ax = axs[2]
    ax.step(F, X, where='post', color=B.COLOURS[0], label='PlayerX $82F5 (left axis)')
    ax.set_ylabel('X')
    ax.set_ylim(8, 18)
    ay = ax.twinx()
    ay.step(F, Y, where='post', color=B.COLOURS[1], label='PlayerY $82F6 (right axis, down)')
    ay.set_ylim(0x72, 0x5A)
    ay.set_ylabel('Y')
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ay.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc='lower left', fontsize=10)
    ax.set_xlabel('frame of recording c1 (read-only memory_at on the live instance)')
    for f, t, y in ((16189, 'down: crouch', 4.3), (16231, 'left + right: stand', 4.3), (16337, 'left: the turn', 5.3),
                    (16341, 'first step', 4.3), (16417, 'killed: frame $0B, the leap', -1.3)):
        for a in axs:
            a.axvline(f, color=B.DIM, ls=':', lw=1)
        if y < 0:
            axs[0].text(f - 2, -y, t, fontsize=10.5, ha='right')
        else:
            axs[0].text(f + 2, y, t, fontsize=10.5)
    axs[0].set_ylim(0, 6.2)
    B.suptitle(fig, 'c1 frames 16180-16450: down held gives frame $0A and no walk; left and right together stand; '
               'left turns the frames in one pass (frame 5), the next passes walk left')
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    axs[0].set_xlim(16180, 16450)
    B.save(fig, B.out('hero', 'turn.png'))


def shots():
    """x2: two shots against the spire's wall (frames 436-492) and one to the screen's edge (586-630)"""
    _, fr = load('x2-hero.json')
    B.style()
    fig, axs = plt.subplots(1, 2, figsize=(B.WIDTH, 6.2), gridspec_kw={'width_ratios': [1.25, 1]})
    for ax, (f0, f1), wall, tag in ((axs[0], (436, 492), (108, 'the spire: ProbeRight at X 108 sees column 28'),
                                     'two shots end at the spire'),
                                    (axs[1], (586, 630), (0x7C, 'X $7C: the right edge'), 'a shot ends at the edge')):
        sel = [(f, v) for f, v in fr if f0 <= f <= f1]
        F = np.array([f for f, _ in sel])
        X = np.array([bytes.fromhex(v[1])[0x82F5 - 0x8269] for _, v in sel])
        S = [bytes.fromhex(v[2]) for _, v in sel]
        pc = np.array([int(v[4], 16) for _, v in sel])
        ax.step(F, X, where='post', color=B.TEXT, label='PlayerX $82F5')
        ax.step(F, X + 0x0C, where='post', color=B.DIM, ls=':', label='PlayerX + $0C: the start')
        ax.step(F, X + 0x40, where='post', color=B.DIM, ls='--', label='PlayerX + $40: the range end')
        for k in range(8):
            sx = np.array([s_[3 * k] if s_[3 * k + 2] else np.nan for s_ in S], float)
            if np.isfinite(sx).any():
                ax.plot(F, sx, 'o-', ms=3.5, lw=1, color=B.COLOURS[k], label=f'ShotList slot {k}: X')
        ax.axhline(wall[0], color=B.COLOURS[3], lw=1.2)
        ax.text(f0 + 1, wall[0] + 1.5, wall[1], fontsize=10, color=B.COLOURS[3])
        for f in F[1:][np.diff(pc) != 0]:
            ax.axvline(f, color=B.DIM, lw=0.5, alpha=0.5)
        ax.set_ylim(40, 135)
        ax.set_xlim(f0, f1)
        ax.set_title(tag, fontsize=10.5)
        ax.set_xlabel(f'frame of x2 ({f0}-{f1})')
    axs[0].set_ylabel('X (2 px a unit)')
    h, lab = axs[0].get_legend_handles_labels()
    fig.legend(h, lab, loc='lower center', ncol=3, fontsize=10)
    B.suptitle(fig, "The player's shots in x2 (screen 0): ShotList $845F read every frame (thin lines: a new pass). A "
               "shot starts at PlayerX + $0C and gains 5 units (10 px) a pass; it ends at a wall, at X $7C or at "
               "PlayerX + $40")
    fig.tight_layout(rect=(0, 0.13, 1, 0.88))
    B.save(fig, B.out('hero', 'shots.png'))


if __name__ == '__main__':
    {'sheet': sheet, 'moves': moves, 'shots': shots}[sys.argv[1]]()

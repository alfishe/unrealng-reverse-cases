"""Figures of the object kinds in docs/07-objects.md (writer fillO).

  python3 tools/fig_kinds.py turret    docs/img/kinds/turret.png    x2 screen 2: the recoil glyphs; x1: states and shells
  python3 tools/fig_kinds.py guns      docs/img/kinds/guns.png      w/009 frames 1000-1500: the gun shots' X
  python3 tools/fig_kinds.py missile   docs/img/kinds/missile.png   w/006 frames 1400-2134: the homing missile's track
  python3 tools/fig_kinds.py balls     docs/img/kinds/balls.png     x2 frames 3000-3400: the 8 balls of screen 5
  python3 tools/fig_kinds.py blast     docs/img/kinds/blast.png     x2 frames 405-426, 565-575: grenade blasts on screen 0
  python3 tools/fig_kinds.py teleport  docs/img/kinds/teleport.png  x2 frames 1609-1620: a teleport on screen 2
  python3 tools/fig_kinds.py booth     docs/img/kinds/booth.png     w/108 frames 1612-1614: the exoskeleton booth
  python3 tools/fig_kinds.py scenes    docs/img/kinds/scenes.png    w/035, w/024, w030: force field, flicker pad, mine
  python3 tools/fig_kinds.py effects   docs/img/kinds/effects.png   model: puff, blast, debris and sparkle frames by pass
  python3 tools/fig_kinds.py all

The reads come from work/docs/fillO/reads.py and readsat.py (TTD memory_at on my instance) into
work/docs/fillO/d/*.json; the screens of the warp runs at multiples of 250 frames come from their saved snapshots.
The commands are in work/docs/fillO-NOTES.md.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.patches as mpatches  # noqa: E402
import numpy as np  # noqa: E402

D = os.path.join(B.WORK, 'docs', 'fillO', 'd')


def load(name):
    d = json.load(open(os.path.join(D, name)))
    return d, sorted((int(f), v) for f, v in d['frames'].items())


def grabs(name):
    """frame -> 64 K memory with the screen ($4000, 6912 bytes) of a readsat.py grab"""
    d, fr = load(name)
    out = {}
    for f, v in fr:
        mem = bytearray(0x10000)
        mem[0x4000:0x4000 + 6912] = bytes.fromhex(v[0])
        out[f] = (bytes(mem), v)
    return out


def crop(mem, c0, r0, c1, r1):
    """screen cells c0..c1-1, r0..r1-1 as an array"""
    im = np.asarray(B.screen(mem))
    return im[8 * r0:8 * r1, 8 * c0:8 * c1]


def show(ax, img, title, extent=None):
    ax.imshow(img, interpolation='nearest', extent=extent)
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_title(title, fontsize=10.5)


# --- turrets ----------------------------------------------------------------------------------------------------------

def turret():
    g = grabs('x2-screens.json')
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 8.4))
    gs = fig.add_gridspec(2, 7, height_ratios=[0.62, 1.6], hspace=0.25, wspace=0.1)
    for i, f in enumerate((1584, 1586, 1590, 1595, 1600, 1605, 1608)):
        mem, v = g[f]
        st = bytes.fromhex(v[6])[2]
        ax = fig.add_subplot(gs[0, i])
        show(ax, crop(mem, 13, 13, 17, 16), f'frame {f}\nstate {st}')
    ax = fig.add_subplot(gs[1, :])
    _, fr = load('x1-turret.json')
    F = np.array([f for f, _ in fr])
    st = np.array([bytes.fromhex(v[0])[2] for _, v in fr])
    sh = [bytes.fromhex(v[1]) for _, v in fr]
    px = np.array([bytes.fromhex(v[2])[0] for _, v in fr])
    dt = np.array([int(v[4], 16) for _, v in fr])
    ax.step(F, st * 8, where='post', color=B.COLOURS[3], label='TurretList state x 8 (9 at a fire, 1 idle)')
    for k in range(10):
        x = np.array([s[3 * k] if s[3 * k + 2] else np.nan for s in sh], float)
        if np.isfinite(x).any():
            ax.plot(F, x, '.', ms=3, color=B.COLOURS[0], label='ShellList: a shell\'s X' if k == 0 else None)
    ax.step(F, px, where='post', color=B.TEXT, label='PlayerX')
    ax.fill_between(F, 0, 130, where=dt > 0, step='post', color=B.COLOURS[1], alpha=0.18, lw=0,
                    label='DeathTimer running')
    ax.set_ylim(0, 130)
    ax.set_xlim(F[0], F[-1])
    ax.set_xlabel('frame of x1 (no POKE, screen 0; the turret at column 20, row 14)')
    ax.set_ylabel('X (2 px a unit)')
    h, lab = ax.get_legend_handles_labels()
    fig.legend(h, lab, loc='lower center', ncol=4, fontsize=10)
    ax.annotate('frame 1750: the shell at X $4A meets\nthe player at X $3F, Y $60: a kill', xy=(1750, 0x4A),
                xytext=(1590, 108), fontsize=10.5, arrowprops={'arrowstyle': '->', 'color': B.TEXT}, color=B.TEXT)
    B.suptitle(fig, 'Top: the turret of x2 screen 2 (column 14, row 14) through one recoil, frames 1584-1608: the '
               'barrel glyph steps $1E, $1C ... $12, $10, one a pass. Bottom: x1 frames 1200-1800, the state byte, '
               'each shell from X $50 two units a pass to the left until it meets the player')
    fig.subplots_adjust(left=0.07, right=0.98, top=0.86, bottom=0.12)
    B.save(fig, B.out('kinds', 'turret.png'))


# --- guns ---------------------------------------------------------------------------------------------------------

def guns():
    _, fr = load('w009-guns.json')
    F = np.array([f for f, _ in fr])
    G = [bytes.fromhex(v[0]) for _, v in fr]
    px = np.array([bytes.fromhex(v[2])[0] for _, v in fr])
    live = np.array([sum(1 for k in range(10) if g[3 * k + 2]) for g in G])
    B.style()
    fig, axs = plt.subplots(2, 1, figsize=(B.WIDTH, 7.6), sharex=True, gridspec_kw={'height_ratios': [2.2, 1]})
    ax = axs[0]
    for k in range(10):
        for row, col in ((120, B.COLOURS[0]), (128, B.COLOURS[2])):
            x = np.array([g[3 * k] if g[3 * k + 2] and g[3 * k + 1] == row else np.nan for g in G], float)
            if np.isfinite(x).any():
                ax.plot(F, x, '.', ms=2.5, color=col)
    ax.plot([], [], '.', color=B.COLOURS[0], label='a shot of the gun at row 15 (Y 120)')
    ax.plot([], [], '.', color=B.COLOURS[2], label='a shot of the gun at row 16 (Y 128)')
    ax.step(F, px, where='post', color=B.TEXT, label='PlayerX')
    ax.axhline(4 * 23 - 2, color=B.DIM, ls='--', lw=1)
    ax.text(F[0] + 3, 4 * 23, 'X = 4 x 23 - 2 = 90: where a shot starts', fontsize=10, color=B.DIM)
    ax.axhline(4 * 23 - 2 - 0x1E, color=B.COLOURS[3], ls=':', lw=1.2)
    ax.text(F[0] + 3, 4 * 23 - 2 - 0x1E + 1.5, 'X 60: the gun fires only while PlayerX is below this', fontsize=10,
            color=B.COLOURS[3])
    ax.set_ylim(0, 100)
    ax.set_ylabel('X (2 px a unit)')
    ax.legend(loc='upper right', fontsize=10)
    ax = axs[1]
    ax.step(F, live, where='post', color=B.COLOURS[1], label='GunShots $9E18: live records (of 10)')
    ax.set_ylim(0, 10.5)
    ax.set_ylabel('records')
    ax.legend(loc='upper left', fontsize=10)
    ax.set_xlabel('frame of w/009 (a warp clone on screen 9; screen 10 here, two guns at column 23)')
    B.suptitle(fig, 'Gun shots in w/009 frames 1000-1500: GunShots read every frame. Each shot starts at X 90 and '
                    'loses 2 units a pass to X 0; at most 5 of the 10 records were in use')
    fig.tight_layout(rect=(0, 0, 1, 0.92))
    B.save(fig, B.out('kinds', 'guns.png'))


# --- the homing missile -----------------------------------------------------------------------------------------------

def missile():
    _, fr = load('w006-missile.json')
    fr = [(f, v) for f, v in fr if f < 2046]
    F = np.array([f for f, _ in fr])
    m = [bytes.fromhex(v[0]) for _, v in fr]
    MX = np.array([b[2] for b in m])
    MY = np.array([b[3] for b in m])
    PX = np.array([bytes.fromhex(v[1])[0] for _, v in fr])
    PY = np.array([bytes.fromhex(v[1])[1] for _, v in fr])
    B.style()
    fig, axs = plt.subplots(1, 2, figsize=(B.WIDTH, 6.2), gridspec_kw={'width_ratios': [1.35, 1]})
    ax = axs[0]
    ax.step(F, MX, where='post', color=B.COLOURS[0], label='missile X $A268')
    ax.step(F, PX, where='post', color=B.TEXT, label='PlayerX')
    ax.step(F, MY, where='post', color=B.COLOURS[2], label='missile Y $A269')
    ax.step(F, PY, where='post', color=B.DIM, label='PlayerY')
    ax.axhline(0x46, color=B.COLOURS[3], ls=':', lw=1)
    ax.text(F[0] + 3, 0x46 + 2, 'X $46: two units a pass below it', fontsize=10, color=B.COLOURS[3])
    for f, t in ((1562, 'relaunch\nX $78, Y $45'), (1823, 'relaunch\nX $78, Y $23')):
        ax.axvline(f, color=B.DIM, lw=0.8, ls='--')
        ax.text(f + 4, 128, t, fontsize=10, va='top')
    ax.set_ylim(0, 135)
    ax.set_xlabel('frame of w/006 (screen 8, the launcher at column 20, row 11)')
    ax.set_ylabel('X (2 px a unit) / Y (pixels)')
    h, lab = ax.get_legend_handles_labels()
    fig.legend(h, lab, loc='lower left', fontsize=10, ncol=2, bbox_to_anchor=(0.04, 0.0))
    ax = axs[1]
    seg = np.split(np.arange(len(F)), np.where(np.diff(MX.astype(int)) > 50)[0] + 1)
    for i, s in enumerate(seg):
        ax.plot(MX[s] * 2, MY[s], '-', color=B.COLOURS[i % 6], lw=1.5, label=f'flight {i + 1}')
        ax.plot(MX[s][0] * 2, MY[s][0], 'o', color=B.COLOURS[i % 6])
    ax.plot(PX * 2 + 12, PY + 16, '.', ms=1.5, color=B.DIM, label='the player\'s centre')
    ax.set_xlim(0, 256)
    ax.set_ylim(176, 0)
    ax.set_aspect('equal')
    ax.set_xlabel('screen x (pixels)')
    ax.set_ylabel('screen y (pixels)')
    h, lab = ax.get_legend_handles_labels()
    fig.legend(h, lab, loc='lower right', fontsize=10, ncol=2, bbox_to_anchor=(0.99, 0.0))
    ax.set_title('the tracks on the screen (a dot: the launch)', fontsize=10.5)
    B.suptitle(fig, 'The homing missile in w/006 frames 1400-2045: each flight starts at the right edge (X $78) at a '
                    'random height and turns one pixel a pass toward the player\'s Y; X 0 ends it and the next starts '
                    'in the same pass')
    fig.tight_layout(rect=(0, 0.12, 1, 0.9))
    B.save(fig, B.out('kinds', 'missile.png'))


# --- balls ------------------------------------------------------------------------------------------------------------

def balls():
    _, fr = load('x2-balls.json')
    F = np.array([f for f, _ in fr])
    R = [bytes.fromhex(v[0]) for _, v in fr]
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 5.4))
    gs = fig.add_gridspec(1, 3, width_ratios=[1.0, 1.0, 1.1], wspace=0.3)
    mem = B.snapshot_ram('x2', 3250)
    ax = fig.add_subplot(gs[0, 0])
    show(ax, crop(mem, 20, 12, 30, 20), 'x2 frame 3250 (snapshot):\ncolumns 20-29, rows 12-19',
         extent=(80, 120, 160, 96))
    ax.set_xticks([80, 90, 100, 110, 120])
    ax.set_yticks([96, 112, 128, 144, 160])
    ax.set_xlabel('X (2 px a unit)')
    ax.set_ylabel('Y (pixels)')
    ax = fig.add_subplot(gs[0, 1])
    for k in range(8):
        x = np.array([r[4 * k] for r in R], float)
        y = np.array([r[4 * k + 1] for r in R], float)
        ax.plot(x + 0.08 * k, y, '-', lw=0.6, color=B.COLOURS[k % 6], alpha=0.8)
    ax.set_xlim(90, 106)
    ax.set_ylim(134, 114)
    ax.set_xlabel('X (2 px a unit)')
    ax.set_ylabel('Y (pixels)')
    ax.set_title('the 8 tracks, frames 3000-3400', fontsize=10.5)
    ax = fig.add_subplot(gs[0, 2])
    for k in range(3):
        x = np.array([r[4 * k] for r in R], float)
        ax.step(F, x + 6 * k, where='post', lw=1, color=B.COLOURS[k])
        ax.text(F[-1] + 3, x[-1] + 6 * k, f'ball {k}', fontsize=10, va='center')
    ax.set_xlabel('frame of x2')
    ax.set_ylabel('X (+ 6 a ball, to separate them)')
    ax.set_title('X of three balls: a step a pass,\nturning at the walls', fontsize=10.5)
    B.suptitle(fig, 'The balls of x2 screen 5 (BallSpawners $9B4B: one spawner at column 24, row 15). BallList '
                    '$9A99 read every frame: the 8 balls wander inside a pocket of the scenery, X 96-100, Y 120-128')
    fig.subplots_adjust(left=0.07, right=0.95, top=0.8, bottom=0.12)
    B.save(fig, B.out('kinds', 'balls.png'))


# --- grenade blasts -------------------------------------------------------------------------------------------------

def blast():
    g = grabs('x2-screens.json')
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 6.6))
    gs = fig.add_gridspec(2, 4, hspace=0.35, wspace=0.08)
    for i, (f, t) in enumerate(((405, 'grenade in flight'), (410, 'the blast prints the\nturret again (XOR)'),
                                (413, 'the turret erased'), (426, 'the debris flies'))):
        mem, v = g[f]
        show(fig.add_subplot(gs[0, i]), crop(mem, 15, 9, 29, 18), f'frame {f}: {t}')
    for i, (f, t) in enumerate(((565, 'before'), (570, 'the spire printed again'), (575, 'debris leaves'))):
        mem, v = g[f]
        show(fig.add_subplot(gs[1, i]), crop(mem, 20, 5, 32, 19), f'frame {f}: {t}')
    ax = fig.add_subplot(gs[1, 3])
    ax.axis('off')
    ax.text(0, 1.0, 'DestructibleList $9437\n(screen 0, two records)', fontsize=10.5, va='top', weight='bold')
    ax.text(0, 0.78, 'frame 405:\n1a 1f 08 12 1d 0a 0d\n13 1b 0c 11 14 0e 05\n\nframe 412:\n1a 1f 08 12 1d 0a 0d\n'
            '80 1b 0c 11 14 0e 05\n\nframe 570:\n80 1f 08 12 1d 0a 0d\n80 1b 0c 11 14 0e 05', fontsize=10, va='top',
            family='monospace')
    B.suptitle(fig, 'Two grenades of x2 on screen 0. Top: frames 405-426, columns 15-28, rows 9-17: the grenade ends '
                    'at X $4C, Y $77, inside the turret\'s box. Bottom: frames 565-575, columns 20-31, rows 5-18: '
                    'the next ends at X $6C, Y $71, inside the spire\'s box')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.83, bottom=0.02)
    B.save(fig, B.out('kinds', 'blast.png'))


# --- teleport and booth -----------------------------------------------------------------------------------------------

def teleport():
    g = grabs('x2-screens.json')
    B.style()
    fig, axs = plt.subplots(1, 3, figsize=(B.WIDTH, 3.6))
    for ax, (f, t) in zip(axs, ((1609, 'up pressed at X $1A, Y $70'), (1610, 'X $59, Y $38: the other pad'),
                                (1620, 'the sparkles\' puffs at both pads'))):
        mem, v = g[f]
        show(ax, crop(mem, 0, 0, 32, 22), f'frame {f}: {t}')
    B.suptitle(fig, 'A teleport in x2 (screen 2): pad 1 at column 5, row 13, pad 2 at column 23, row 6. Frames 1609, '
                    '1610 and 1620, rows 0-21')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.78, bottom=0.02, wspace=0.05)
    B.save(fig, B.out('kinds', 'teleport.png'))


def booth():
    g = grabs('w108-screens.json')
    B.style()
    fig, axs = plt.subplots(1, 3, figsize=(B.WIDTH, 4.4))
    for ax, f in zip(axs, (1612, 1613, 1614)):
        mem, v = g[f]
        suit = int(v[2], 16)
        p = bytes.fromhex(v[1])
        show(ax, crop(mem, 10, 0, 22, 8), f'frame {f}: ExoSuit ${suit:02X}\nX ${p[0]:02X}, Y ${p[1]:02X}')
    B.suptitle(fig, 'The exoskeleton booth of screen 109 in w/108 (ExoBoothList: column 14, row 2), columns 10-21, '
                    'rows 0-7: up pressed at frame 1613 flips ExoSuit $9ED8 to $0C and the player is redrawn as frame '
                    '$11 (5 + 12)')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.74, bottom=0.02, wspace=0.05)
    B.save(fig, B.out('kinds', 'booth.png'))


# --- force field, flicker pad, mine -------------------------------------------------------------------------------------

def scenes():
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 7.4))
    gs = fig.add_gridspec(2, 3, hspace=0.3, wspace=0.08)
    m = B.snapshot_ram('w/035', 500)
    show(fig.add_subplot(gs[0, 0:2]), crop(m, 0, 0, 32, 22),
         'w/035 frame 500, screen 35: the force field, column 20, rows 3-18 (ink = PassCount AND 7)')
    m = B.snapshot_ram('w/024', 500)
    show(fig.add_subplot(gs[0, 2]), crop(m, 9, 0, 23, 10),
         'w/024 frame 500, screen 24:\nthe flicker pad at column 14, row 4')
    for i, (f, t) in enumerate(((1500, 'armed (state 1)'), (1750, 'spent (state 0): the flames'))):
        m = B.snapshot_ram('w030', f)
        show(fig.add_subplot(gs[1, i]), crop(m, 0, 12, 12, 22), f'w030 frame {f}, screen 32: the mine at\n'
                                                                 f'column 5, row 19, {t}')
    ax = fig.add_subplot(gs[1, 2])
    ax.axis('off')
    ax.text(0, 0.95, 'MineList $91B0 (w030)', fontsize=10.5, weight='bold', va='top')
    ax.text(0, 0.8, 'frame 1500: 05 13 01  1d 13 01  ff\nframe 1570: 05 13 00  1d 13 01  ff\n\nthe player at frame 1570:\n'
            'X $0D, Y $78\n\nY + $1F = $97 = 8 x 19 - 1\nX + 6 - 4 x 5 - 9 = -10 = $F6',
            fontsize=10, va='top', family='monospace')
    B.suptitle(fig, 'Three kinds on warp-run screens, from the runs\' saved snapshots: the force field (top left), the '
                    'flicker pad (top right), a mine before and after it fired (bottom)')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.86, bottom=0.02)
    B.save(fig, B.out('kinds', 'scenes.png'))


# --- puff, blast, debris, sparkle frames ------------------------------------------------------------------------------

def small_sprite(n, copy=0):
    M = B.image()
    a = 0xED40 + 64 * n + 16 * copy
    return np.array([[M[a + 2 * y + x // 8] >> (7 - x % 8) & 1 for x in range(16)] for y in range(8)])


def sprite16(n):
    M = B.image()
    a = 0xF8E0 + 32 * n
    return np.array([[M[a + 2 * y + x // 8] >> (7 - x % 8) & 1 for x in range(16)] for y in range(16)])


def effects():
    M = B.image()
    puff = list(M[0x9865:0x9870])                         # PuffFrames $9865
    bl = list(M[0xA001:0xA00C])                           # BlastFrames $A001
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 6.0))
    gs = fig.add_gridspec(3, 11, hspace=0.9, wspace=0.15, height_ratios=[0.6, 1, 0.6])
    col = np.array([1.0, 0.85, 0.3])
    for i, t in enumerate(range(10, 0, -1)):              # AnimatePuffs: timer t draws PuffFrames[t - 1]
        ax = fig.add_subplot(gs[0, i])
        fr = puff[t - 1]
        show(ax, small_sprite(fr)[..., None] * col, f'pass {i + 1}\nsprite {fr}')
    fig.text(0.01, 0.885, 'Puff (AnimatePuffs $9835): timer 10 down to 1, small sprite PuffFrames[t - 1]; 6 is blank',
             fontsize=11)
    for i, t in enumerate(range(11, 0, -1)):              # RunBlasts: passes left t, frame BlastFrames[t - 1]
        ax = fig.add_subplot(gs[1, i])
        fr = bl[t - 1]
        img = sprite16(fr)[..., None] * np.array([1.0, 0.4, 0.4])
        show(ax, img, f'pass {i + 1}\nframe {fr}')
    fig.text(0.01, 0.64, 'Blast (RunBlasts $9FBD): 11 passes, Sprites16 frame BlastFrames[t - 1]; frame 0 erases',
             fontsize=11)
    ax = fig.add_subplot(gs[2, 0])
    show(ax, small_sprite(2)[..., None] * np.array([0.5, 1, 1]), 'debris\nsprite 2')
    ax = fig.add_subplot(gs[2, 2])
    show(ax, small_sprite(7)[..., None] * np.array([1, 0.4, 0.4]), 'ball\nsprite 7')
    ax = fig.add_subplot(gs[2, 3:])
    ax.axis('off')
    sp = [B.s8(x) for x in M[0x9555:0x955D]]
    ax.text(0, 0.9, f'DebrisSpeeds $9555: {sp}\ndx = DebrisSpeeds[Random AND 7], dy = 2 x DebrisSpeeds[Random AND 7]',
            fontsize=10.5, va='top')
    fig.text(0.01, 0.27, 'Debris and balls are single small sprites (XOR, copy X AND 3 of SmallSprites '
             '$ED40)', fontsize=11)
    B.suptitle(fig, 'The short-lived effects, from the image, in the order they are drawn')
    fig.subplots_adjust(left=0.01, right=0.99, top=0.8, bottom=0.02)
    B.save(fig, B.out('kinds', 'effects.png'))


ALL = {'turret': turret, 'guns': guns, 'missile': missile, 'balls': balls, 'blast': blast, 'teleport': teleport,
       'booth': booth, 'scenes': scenes, 'effects': effects}

if __name__ == '__main__':
    if sys.argv[1] == 'all':
        for f in ALL.values():
            f()
    else:
        ALL[sys.argv[1]]()

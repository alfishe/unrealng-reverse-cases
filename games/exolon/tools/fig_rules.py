"""Figures of docs/10-gameplay-logic.md (docs agent B).

  python3 tools/fig_rules.py zones    docs/img/rules/zones.png    the object kinds of all 125 screens (model)
  python3 tools/fig_rules.py arcs     docs/img/rules/arcs.png     jump, grenade and death leap: tables vs recordings
  python3 tools/fig_rules.py deaths   docs/img/rules/deaths.png   x1's nine deaths: lives, DeathTimer, immunity
  python3 tools/fig_rules.py course   docs/img/rules/course.png   x2: screens, score, the idle missiles
  python3 tools/fig_rules.py hof      docs/img/rules/hof.png      h1: the Hall of Fame table before and after

The recordings' values come from TTD reads made with work/docs/docB/read_series.py (memory_at at the end of each
frame), kept as JSON:

  x1/deaths.json  Lives $8E7A, DeathTimer $9CE2, PassCount/ImmunityCount $768C, PlayerX/Y $82F5, every 2nd frame
  x2/arcs.json    PlayerX/Y/JumpStep $82F5, GrenadeTimer/X/Y $925A, DeathTimer $9CE2, frames 0-1500
  x2/play.json    the score $AD8A, ScreenNumber $8523, the idle missile $AC78-$AC7C, BonusTicks $9ED6, every 10th
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import fig_objects as O  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

JUMP_STEPS, GRENADE_ARC, DEATH_LEAP = 0x826A, 0x92DB, 0x9D4A
ZONE_ENDS = (24, 49, 74, 99, 124)


def series(rec, name):
    d = json.load(open(os.path.join(B.DOCB, rec, name)))
    fr = sorted(d['frames'], key=int)
    return [(int(f), [bytes.fromhex(h) for h in d['frames'][f]]) for f in fr]


def screen_kinds(n):
    cv, marks = B.build_screen(n)
    out = {}
    for v in cv.cells.values():
        if v[2] > 1:
            out[v[2]] = out.get(v[2], 0) + 1
    for _, _, k in marks:
        out[k] = out.get(k, 0) + 1
    return out


def zones():
    O.kind_table_check()
    kinds = sorted(O.KINDS)
    data = np.zeros((len(kinds), 125))
    for n in range(125):
        for k, c in screen_kinds(n).items():
            data[kinds.index(k), n] = c
    B.style()
    fig, ax = plt.subplots(figsize=(B.WIDTH, 8.2))
    for i, k in enumerate(kinds):
        xs = np.flatnonzero(data[i])
        ax.scatter(xs, np.full(len(xs), i), s=6 + 5 * data[i][xs], color=B.COLOURS[k % len(B.COLOURS)],
                   edgecolors='none')
    for z in range(5):
        ax.axvspan(25 * z - 0.5, 25 * z + 24.5, color=(1, 1, 1, 0.04 if z % 2 else 0.0))
        ax.text(25 * z + 12, len(kinds) + 0.15, f'zone {z + 1}\n{25 * z}-{25 * z + 24}', ha='center',
                fontsize=11)
    for e in ZONE_ENDS:
        ax.axvline(e, color=B.TEXT, lw=0.6, ls=':')
    ax.set_yticks(range(len(kinds)))
    ax.set_yticklabels([f'{k} {O.KINDS[k][3]} ({int((data[i] > 0).sum())})' for i, k in enumerate(kinds)])
    ax.set_xticks(range(0, 125, 10))
    ax.set_xlim(-1, 125)
    ax.set_ylim(-0.7, len(kinds) + 1.1)
    ax.set_xlabel('screen (ScreenNumber $8523); dotted: the zone-end screens 24, 49, 74, 99, 124')
    ax.grid(True, axis='y', alpha=0.2)
    B.suptitle(fig, '125 screens in five zones of 25: the object kinds of each screen (dot size = cells, '
               '(n) = screens with the kind); only the last screen of a zone has the zone end (model of the build)')
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    B.save(fig, B.out('rules', 'zones.png'))
    return data, kinds


def table(addr, n):
    return [B.s8(v) for v in B.image()[addr:addr + n]]


def arcs():
    B.style()
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 13))
    # the jump: JumpStep 22 first, the table read backwards (index JumpStep - 1)
    js = table(JUMP_STEPS, 22)
    model = np.cumsum([0] + [js[s - 1] for s in range(22, 0, -1)])
    rows = series('x2', 'arcs.json')
    ax = axs[0]
    jumps, cur = [], None
    for f, (p, g, dt) in rows:
        x, y, step = p
        if step and cur is None:
            cur = [(f, x, y, step)]
        elif step and cur:
            cur.append((f, x, y, step))
        elif not step and cur:
            jumps.append(cur)
            cur = None
    base = None
    for j in jumps[:6]:
        y0 = j[0][2] - js[j[0][3]]          # the Y before the first step
        pts = {}
        for f, x, y, step in j:
            pts[22 - step] = y - y0
        ks = sorted(pts)
        ax.plot(ks, [-pts[k] for k in ks], 'o', ms=4, color=B.COLOURS[1], alpha=0.6)
    ax.plot(range(23), -model, color=B.TEXT, lw=1.5, label='JumpSteps $826A (model)')
    ax.plot([], [], 'o', color=B.COLOURS[1], label=f'x2: {min(6, len(jumps))} jumps, Y at each pass')
    ax.set_xlabel('passes from the jump key')
    ax.set_ylabel('pixels above the start')
    ax.set_title(f'the jump: {-min(model)} px up and down in 22 passes')
    ax.legend(loc='lower center')
    # the grenade: X and Y in pixels from the throw
    ga = table(GRENADE_ARC, 32)
    ax = axs[1]
    flights, cur = [], None
    for f, (p, g, dt) in rows:
        t, gx, gy = g
        if t and cur is None:
            cur = [(f, t, gx, gy)]
        elif t and cur:
            cur.append((f, t, gx, gy))
        elif not t and cur:
            flights.append(cur)
            cur = None
    mx, my, y = [0], [0], 0
    for t in range(32, 1, -1):          # the step of timer t is byte t - 1; the timer stops at 1
        y += ga[t - 1]
        mx.append(mx[-1] + 2)
        my.append(-y)
    for k in range(30):
        y += ga[0]
        mx.append(mx[-1] + 2)
        my.append(-y)
    for fl in flights[:6]:
        _, t1, gx1, gy1 = fl[0]
        k1 = 32 - t1                     # steps made before the first sample
        d = 1 if fl[-1][2] >= gx1 else -1
        ax.plot([mx[k1] + 2 * d * (gx - gx1) for _, _, gx, _ in fl],
                [my[k1] - (gy - gy1) for _, _, _, gy in fl], 'o', ms=3, color=B.COLOURS[2], alpha=0.6)
    ax.plot(mx, my, color=B.TEXT, lw=1.5, label='GrenadeArc $92DB (model, no floor)')
    ax.plot([], [], 'o', color=B.COLOURS[2], label=f'x2: {min(6, len(flights))} throws, each step (end of frame)')
    ax.set_xlabel('pixels from the throw (2 a step)')
    ax.set_ylabel('pixels above the throw')
    ax.set_ylim(-30, 24)
    ax.set_title(f'the grenade: up {int(max(my))} px in 9 steps, level, then down 1 a step until it lands')
    ax.legend(loc='lower left')
    # the death leap: DeathTimer 46 -> 1, index t
    dl = table(DEATH_LEAP - 1, 47)
    ax = axs[2]
    drows = series('x1', 'deaths.json')
    shown = 0
    for i, (f, v) in enumerate(drows):
        if v[1][0] == 0x2E and (i == 0 or drows[i - 1][1][1][0] == 0):
            y0 = v[3][1]
            pts = [(46 - w[1][0], w[3][1] - y0) for _, w in drows[i:i + 60] if w[1][0]]
            ax.plot([p[0] for p in pts], [-p[1] for p in pts], 'o', ms=3, color=B.COLOURS[3], alpha=0.6)
            shown += 1
    my = np.cumsum([0] + [dl[t] for t in range(46, 1, -1)])
    ax.plot(range(46), -my, color=B.TEXT, lw=1.5, label='DeathLeap $9D4A (model, no floor)')
    ax.plot([], [], 'o', color=B.COLOURS[3], label=f'x1: the {shown} deaths, every 2nd frame')
    ax.set_xlabel('passes from the death (DeathTimer 46 down)')
    ax.set_ylabel('pixels above the place of death')
    ax.set_ylim(-60, 25)
    ax.set_title(f'the death leap: up {int(max(-my))} px in 9 passes, then a fall to the floor')
    ax.legend(loc='lower left')
    B.suptitle(fig, 'Three arcs, three tables of Y steps: the recordings follow each table until a floor or a '
               'ceiling stops the move')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('rules', 'arcs.png'))
    return model, mx, my


def deaths():
    rows = series('x1', 'deaths.json')
    f = np.array([r[0] for r in rows])
    lives = np.array([r[1][0][0] for r in rows])
    dt = np.array([r[1][1][0] for r in rows])
    imm = np.array([r[1][2][1] for r in rows])
    B.style()
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 9), sharex=True)
    axs[0].step(f, lives, where='post', color=B.COLOURS[0])
    axs[0].set_ylabel('Lives $8E7A')
    starts = [f[i] for i in range(1, len(f)) if dt[i] == 46 and dt[i - 1] == 0]
    ends = [f[i] for i in range(1, len(f)) if lives[i] < lives[i - 1] or (lives[i] > lives[i - 1])]
    for s in starts:
        for ax in axs:
            ax.axvline(s, color=B.DIM, lw=0.6)
    axs[0].set_title(B.wrap(f'{len(starts)} deaths; each costs a life when DeathTimer reaches 0; at 0 lives GAME '
                            'OVER, and the entry $6D60 (Start) sets 9 again at frame 3362', 100), fontsize=11)
    axs[1].plot(f, dt, color=B.COLOURS[1])
    axs[1].set_ylabel('DeathTimer $9CE2')
    axs[1].set_title('KillPlayer $9CAF sets 46 passes; PlayerDeath $9CE3 counts one a pass (the leap)', fontsize=11)
    axs[2].plot(f, imm, color=B.COLOURS[2])
    axs[2].set_ylabel('ImmunityCount $768D')
    axs[2].set_title(B.wrap('ImmunityCount = 46 + 20 = 66 at the death, down one a pass: 20 passes of safety after '
                            'the restart (after the last death it stays at 20: no more passes)', 100), fontsize=11)
    axs[2].set_xlabel('x1 frame')
    lengths = []
    for s in starts:
        i = list(f).index(s)
        j = i
        while j < len(f) and dt[j]:
            j += 1
        lengths.append(f[j] - s if j < len(f) else None)
    B.suptitle(fig, f'x1: nine deaths without a POKE: each one {min(lengths)}-{max(lengths)} frames of leap '
               '(46 passes), then the restart point')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('rules', 'deaths.png'))
    return starts, lengths


def course():
    rows = series('x2', 'play.json')
    f = np.array([r[0] for r in rows])
    score = np.array([int(r[1][0].decode()) for r in rows])
    scr = np.array([r[1][1][0] for r in rows])
    live = np.array([r[1][2][0] for r in rows])
    mx = np.array([r[1][2][1] for r in rows])
    idle = np.array([r[1][2][3] | r[1][2][4] << 8 for r in rows])
    B.style()
    fig, axs = plt.subplots(4, 1, figsize=(B.WIDTH, 11.5), sharex=True, gridspec_kw={'height_ratios': [2, 1, 1.4, 1.4]})
    axs[0].step(f, score, where='post', color=B.COLOURS[0])
    steps = np.diff(score)
    sizes = sorted(set(int(s) for s in steps if s))
    axs[0].set_ylabel('score $AD8A')
    axs[0].set_title(B.wrap(f'the score: {int((steps > 0).sum())} rises in the samples, every one '
                            f'{", ".join(map(str, sizes))} points (KillAlien $A62D: 150 an alien)', 100), fontsize=11)
    axs[1].step(f, scr, where='post', color=B.COLOURS[1])
    axs[1].set_ylabel('screen $8523')
    first5 = f[np.argmax(scr == 5)]
    axs[1].set_title(f'screens 0-5 walked by frame {first5}; then the script stands on screen 5', fontsize=11)
    axs[2].plot(f, idle, color=B.COLOURS[2])
    axs[2].axhline(700, color=B.DIM, lw=0.8, ls='--')
    axs[2].set_ylabel('IdleTime $AC7B')
    t700 = f[np.argmax(idle >= 700)]
    axs[2].set_title(B.wrap(f'IdleTime: +1 a pass, 0 at each new screen; it reaches 700 ($2BC, dashed) at frame '
                            f'{t700} and is never reset by the missiles', 100), fontsize=11)
    axs[3].plot(f, np.where(live > 0, mx, np.nan), '.', ms=2, color=B.COLOURS[3])
    axs[3].set_ylabel('missile X $AC79')
    n = int(((live[1:] > 0) & (live[:-1] == 0)).sum())
    axs[3].set_title(B.wrap(f'the idle missile (IdleMissileLive $AC78): at least {n} launches from X $78 (120); '
                            'most end on the player standing at X 92-118 (the touch), some fly on to X 0', 100),
                     fontsize=11)
    axs[3].set_xlabel('x2 frame (every 10th sampled)')
    B.suptitle(fig, 'x2, a clone with immunity (exploration only): the course of a run that stops on screen 5 and '
               'shoots aliens; standing still brings the idle missiles')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('rules', 'course.png'))
    return score, t700, n


def text(data):
    return ''.join(chr(v) if 32 <= v < 127 else '.' for v in data)


def hof():
    frames = (250, 2500, 6750)
    titles = ('frame 250: as loaded', 'frame 2500: score in', 'frame 6750: name typed')
    notes = ('HUMPTY (place 50) is the\nentry that will fall out',
             '009000 at place 1, still under\nthe old name; all move down 16;\nHUMPTY past $7511, its H = $FF',
             'ENTER wrote EXOLON over\nthe name of place 1')
    shown = [0, 1, 2, None, 46, 47, 48, 49, 50]          # entry indexes; None = the gap; 50 = the end mark
    B.style()
    fig, axs = plt.subplots(1, 3, figsize=(B.WIDTH, 6.4))
    for ax, fr, ti, note in zip(axs, frames, titles, notes):
        m = B.snapshot_ram('h1', fr)
        ax.axis('off')
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        y = 0.95
        for k in shown:
            if k is None:
                ax.text(0.02, y, '   ...  places 4-46', family='DejaVu Sans Mono', fontsize=12, color=B.DIM,
                        va='top')
                y -= 0.075
                continue
            a = 0x71F1 + 16 * k
            e = m[a:a + 16]
            col, box = B.TEXT, None
            if k == 50:
                t = f'${a:04X} {e[0]:02X} {text(e[1:10])} {text(e[10:])}'
                col = B.COLOURS[3]
                box = B.COLOURS[3] if fr != 250 else None
            else:
                t = f'${a:04X} {k + 1:2} {text(e[:10])} {text(e[10:])}'
                if fr != 250 and k == 0:
                    col, box = B.COLOURS[1], B.COLOURS[1]
                if fr == 250 and k == 49:
                    col, box = B.COLOURS[0], B.COLOURS[0]
            ax.text(0.02, y, t, family='DejaVu Sans Mono', fontsize=12, color=col, va='top',
                    bbox=dict(facecolor='none', edgecolor=box, lw=1.5, pad=2) if box else None)
            y -= 0.075
        ax.text(0.02, y - 0.03, note, fontsize=11, color=B.TEXT, va='top')
        ax.set_title(ti, fontsize=12)
    B.suptitle(fig, 'HallOfFameInsert $A073 (h1, a clone with the score 009000): the score goes in above the first '
               'lower entry; the rest move down 16 bytes and the last one falls past the end mark $7511')
    fig.text(0.5, 0.012, 'Each row: the address, the place, the 10 name bytes, the 6 score digits; '
             'the last row is the 16 bytes from the end mark.', ha='center', fontsize=10.5)
    fig.tight_layout(rect=(0, 0.04, 1, 0.9))
    B.save(fig, B.out('rules', 'hof.png'))


if __name__ == '__main__':
    {'zones': zones, 'arcs': arcs, 'deaths': deaths, 'course': course, 'hof': hof}[sys.argv[1]]()

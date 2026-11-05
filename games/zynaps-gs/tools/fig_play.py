#!/usr/bin/env python3
"""The figures of docs/10-gameplay-logic.md, drawn from the zgsB pod-bot recordings (tools/gs_podbot.py) and the
memory images taken at the game's start (the 48K case's tools/fig_weapons.py, moved onto this case's frame logs).

    python3 tools/fig_play.py course  --npz work/zgsB/e1/bot.npz --tag e1 --out docs/img/play/weapons-course.png
    python3 tools/fig_play.py sheet   --npz work/zgsB/e1/bot.npz --tag e1 --out docs/img/play/weapons-sheet.png
    python3 tools/fig_play.py gif     --npz work/zgsB/e2/bot.npz --tag e2 --from 4770 --to 5030 \
                                      --only 6,8,10,12 --title '...' --out docs/img/play/homing-missile.gif
    python3 tools/fig_play.py homing  --npz work/zgsB/e2/bot.npz --tag e2 --out docs/img/play/homing-sheet.png
    python3 tools/fig_play.py options --out docs/img/play/hidden-options.png
    python3 tools/fig_play.py order   --out docs/img/play/level-order.png

A frame log (gs_podbot.py's PREFIX.npz) holds, every --step frames after the step: frames; vars = the player record
`$7F9C-$7FAB` (16 bytes), `$80E0-$80EF` (16: the lock, the hit masks, Fuel `$80E6`), FireHeld `$8184` (1) and
`$7F62-$7F81` (32: PassCount, the HUD counters); objs = the 16 object records `$F36C-$F62B` (44 bytes each, RAM
page 0); screen = the 6912 bytes at `$4000`.
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.normpath(os.path.join(CASE, '..', '..', 'kit')))
import kitlib as K  # noqa: E402


def rgb(c):
    return tuple(v / 255 for v in c)


BG, PANEL, TEXT, DIM = rgb(K.BACKGROUND), rgb(K.PANEL), rgb(K.TEXT), rgb(K.DIM)
COLOURS = [rgb(c) for c in K.ROUTINE_COLOURS]
P1 = 0x7F9C
KINDS = {0: 'ship', 1: 'laser', 2: 'enemy', 3: 'explosion', 4: 'pod', 5: 'enemy shot', 6: 'sight', 7: 'seeker',
         8: 'lockable', 9: 'plasma', 10: 'missile', 11: 'enemy', 12: 'big enemy'}
KIND_COLOUR = {2: (230, 230, 230), 11: (230, 230, 230), 1: (255, 240, 80), 4: (80, 230, 110), 6: (90, 200, 255),
               7: (255, 120, 220), 9: (255, 150, 60), 10: (255, 80, 80), 8: (200, 110, 230), 12: (200, 110, 230),
               3: (255, 200, 120), 5: (255, 90, 90)}
SIZES = {12: (72, 56), 1: (16, 6), 9: (8, 8), 10: (16, 8), 7: (16, 8), 6: (16, 16), 5: (8, 8)}
ACTIONS = ['speed', 'laser', 'plasma', 'homing', 'seeker']


def style():
    plt.rcParams.update({
        'figure.facecolor': BG, 'axes.facecolor': PANEL, 'savefig.facecolor': BG,
        'axes.edgecolor': DIM, 'axes.labelcolor': TEXT, 'xtick.color': TEXT, 'ytick.color': TEXT,
        'text.color': TEXT, 'axes.titlecolor': TEXT, 'grid.color': (0.25, 0.25, 0.3), 'font.size': 10,
        'axes.titlesize': 11, 'text.parse_math': False, 'legend.facecolor': PANEL, 'legend.edgecolor': DIM,
        'font.family': 'DejaVu Sans'})


def save(fig, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print('wrote', os.path.relpath(path, CASE), f'{os.path.getsize(path) // 1024} KB')


class Rec:
    """a gs_podbot.py frame log, read by address"""
    LAYOUT = [(0x7F9C, 16), (0x80E0, 16), (0x8184, 1), (0x7F62, 32)]

    def __init__(self, path, tag):
        d = np.load(path)
        self.F, self.V, self.O = d['frames'], d['vars'], d['objs']
        self.S = d['screen'] if 'screen' in d.files else None
        self.tag = tag

    def var(self, addr):
        col = 0
        for base, n in self.LAYOUT:
            if base <= addr < base + n:
                return self.V[:, col + addr - base].astype(int)
            col += n
        raise KeyError(hex(addr))

    def active(self, i):
        out = []
        for s in range(16):
            r = self.O[i, 44 * s:44 * s + 44]
            x, y = int(r[3]) | int(r[4]) << 8, int(r[5]) | int(r[6]) << 8
            if r[8] & 0x80 and (x or y):  # X = Y = 0: switched on this pass, not placed yet
                out.append((s, int(r[7]), x, y))
        return out

    def score(self, i):
        return int(bytes(self.V[i, 0:4]).hex())


def events(rec):
    """the pod pick-ups: (frame, 'step' / 'action' / 'wrap', the selector before, the name)"""
    sel, weap, dbl, las, spd = (rec.var(P1 + k) for k in (7, 8, 9, 10, 11))
    out = []
    for i in range(1, len(rec.F)):
        gain = rec.score(i) - rec.score(i - 1)
        changed = (weap[i], dbl[i], las[i], spd[i]) != (weap[i - 1], dbl[i - 1], las[i - 1], spd[i - 1])
        if sel[i] != sel[i - 1] or (gain >= 100 and changed):
            if sel[i] == 0 and sel[i - 1] == 4 and gain >= 1100:
                out.append((int(rec.F[i]), 'wrap', int(sel[i - 1]), 'wrap'))
            elif sel[i] == sel[i - 1] + 1:
                out.append((int(rec.F[i]), 'step', int(sel[i - 1]), ACTIONS[sel[i]]))
            elif sel[i] == 0:
                name = ACTIONS[sel[i - 1]]
                if sel[i - 1] == 2 and dbl[i]:
                    name = 'double plasma'
                out.append((int(rec.F[i]), 'action', int(sel[i - 1]), name))
    return out


def course(a):
    rec = Rec(a.npz, a.tag)
    F = rec.F
    sel, weap, dbl, las, spd, lvl = (rec.var(P1 + k) for k in (7, 8, 9, 10, 11, 6))
    fuel, held = rec.var(0x80E6), rec.var(0x8184)
    ev = events(rec)
    style()
    fig, axes = plt.subplots(3, 1, figsize=(14, 9.8), sharex=True, gridspec_kw={'height_ratios': [1.3, 1.2, 1.1]})
    level_at = [F[i] for i in range(1, len(F)) if lvl[i] != lvl[i - 1]]
    ends = [F[i] for i in range(1, len(F)) if weap[i] == 0 and weap[i - 1] and sel[i] == sel[i - 1]]
    ax = axes[0]
    ax.step(F, sel, where='post', color=COLOURS[2], lw=1.6)
    nact = 0
    for f, kind, before, name in ev:
        if kind == 'action':
            i = int(np.searchsorted(F, f)) - 1
            ax.plot(f, before, marker='*', ms=15, color=COLOURS[3], zorder=5)
            nact += 1
            ax.annotate(f'{name}\n(fire {held[max(i, 0)]} passes)', (f, before),
                        xytext=[(6, 6), (-75, 16), (6, 6), (8, -30), (-110, 8), (12, -14)][(nact - 1) % 6],
                        textcoords='offset points', color=COLOURS[3], fontsize=9, fontweight='bold')
        elif kind == 'wrap':
            ax.plot(f, before, marker='D', ms=8, color=COLOURS[0], zorder=5)
        else:
            ax.plot(f, before + 1, marker='o', ms=6, color=COLOURS[1], zorder=5)
    ax.set_yticks(range(5))
    ax.set_yticklabels([f'{k} {n}' for k, n in enumerate(ACTIONS)])
    ax.set_ylim(-0.6, 5.2)
    ax.grid(alpha=0.3)
    steps = sum(1 for e in ev if e[1] == 'step')
    acts = sum(1 for e in ev if e[1] == 'action')
    ax.set_title(f'{a.tag}: {len(ev)} pods scooped. Without fire a pod moves the selector (record +7) on (o, {steps}); '
                 f'with fire held 8+ passes it runs the selected action (*, {acts})', loc='left')
    ax.plot([], [], '-', color=COLOURS[2], label='pod selector, player record +7')
    ax.plot([], [], 'o', color=COLOURS[1], label='pod without fire: selector + 1')
    ax.plot([], [], '*', ms=12, color=COLOURS[3], label='pod with fire held: the action, selector to 0')
    ax.plot([], [], 'D', ms=7, color=COLOURS[0], label='past seeker: wrap to 0, 1100 points, fuel $B4')
    ax.legend(loc='center', fontsize=8.5)
    ax = axes[1]
    ax.step(F, weap, where='post', color=COLOURS[4], lw=1.8, label='side weapon +8 (0 none, 2 plasma, 3 homing, 4 seeker)')
    ax.step(F, dbl + 0.05, where='post', color=COLOURS[0], lw=1.4, label='double plasma +9')
    ax.step(F, las - 0.05, where='post', color=COLOURS[3], lw=1.8, label='laser level +$0A (0-3)')
    ax.step(F, (spd - 0x40) / 32, where='post', color=COLOURS[5], lw=1.4, ls='--', label='speed +$0B = $40 + $20 n: n')
    for f in level_at:
        for x in axes:
            x.axvline(f, color=TEXT, lw=0.9, ls=':')
        axes[0].text(f, 5.0, ' level done: the next level starts', color=TEXT, fontsize=8.5, va='top')
    for f in ends:
        ax.annotate('level end (CmdLevelEnd $AE40):\nside weapon and double gone', (f, 0), xytext=(20, 40),
                    textcoords='offset points', color=TEXT, fontsize=8.5,
                    arrowprops=dict(arrowstyle='->', color=DIM))
    ax.set_ylim(-0.4, 4.8)
    ax.grid(alpha=0.3)
    ax.legend(loc='upper left', fontsize=8.5, ncol=2)
    fo = [F[i] for i in range(1, len(F)) if fuel[i] == 0x5A and fuel[i - 1] < 4]
    ax.set_title(f'What the actions changed; {len(fo)} FuelOuts (fuel empty) each took a laser level and a speed '
                 'step back', loc='left')
    ax = axes[2]
    ax.plot(F, fuel, color=COLOURS[1], lw=1.4)
    for i in range(1, len(F)):
        if fuel[i] > fuel[i - 1] + 2 or (fuel[i] < fuel[i - 1] - 2):
            if fuel[i] == 0x5A and fuel[i - 1] < 4:
                txt = 'FuelOut $9C03:\n$5A, laser -1, speed -$20'
            elif fuel[i] == 0xBB:
                txt = 'pod: $BB'
            elif fuel[i] == 0xB4:
                txt = 'wrap: $B4'
            elif abs(fuel[i] - fuel[i - 1] // 2) <= 1:
                txt = 'pod missed: halved'
            elif fuel[i] == 0x5A:
                txt = 'round start: $5A'
            else:
                txt = f'{fuel[i - 1]}->{fuel[i]}'
            off = (30, -22) if txt.startswith('pod:') else (6, 12 if fuel[i] > 60 else 30)
            ax.annotate(txt, (F[i], fuel[i]), xytext=off, textcoords='offset points',
                        color=TEXT, fontsize=8, arrowprops=dict(arrowstyle='->', color=DIM))
    ax.axhline(0x40, color=DIM, ls=':', lw=0.8)
    ax.axhline(0x20, color=DIM, ls=':', lw=0.8)
    ax.text(F[-1], 0x40 + 3, 'panel lamps go dark below $40, $20', ha='right', color=DIM, fontsize=8)
    dec = [F[i] for i in range(1, len(F)) if fuel[i] == fuel[i - 1] - 1]
    per = np.median(np.diff(dec)) if len(dec) > 2 else 0
    ax.set_title(f'Fuel $80E6: -1 every {per:.0f} frames, refilled by a pod taken, halved by a pod missed, $5A after '
                 'FuelOut', loc='left')
    ax.set_ylim(-5, 215)
    ax.set_xlabel(f'{a.tag} bot frame ({a.label})')
    ax.grid(alpha=0.3)
    fig.suptitle(a.title, color=TEXT, fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, a.out)
    for e in ev:
        print(e)
    print('levels', level_at, 'weapon lost', ends, 'fuelouts', fo)


def boxes(img, rec, i, scale, only=None):
    """the active slots' boxes: X in columns of 8 pixels from X 16, Y in rows of 8 pixels from Y -1 (the 48K case's
    rule, checked against these screens)"""
    d = ImageDraw.Draw(img)
    f = K.font(9 * scale // 2 + 2)
    for s, kind, x, y in rec.active(i):
        if only is not None and kind not in only:
            continue
        col = KIND_COLOUR.get(kind)
        if not col:
            continue
        px = (x / 256 - 16) * 8 * scale
        py = (y / 256 + 1) * 8 * scale
        w, h = SIZES.get(kind, (24, 16))
        d.rectangle([px - 2, py - 2, px + w * scale + 2, py + h * scale + 2], outline=col, width=max(1, scale // 2))
        d.text((px, py + h * scale + 3), KINDS.get(kind, str(kind)), fill=col, font=f)


def screen_img(rec, i, scale=2):
    mem = bytearray(0x10000)
    mem[0x4000:0x4000 + 6912] = bytes(rec.S[i])
    return K.render_screen(mem, 0x4000).resize((256 * scale, 192 * scale), Image.NEAREST)


def panel_sheet(rec, picks, title, out):
    scale = 2
    W, H = 256 * scale, 192 * scale
    pad, top = 10, 36
    cols = 3
    rows = (len(picks) + cols - 1) // cols
    img = Image.new('RGB', (cols * W + (cols + 1) * pad, rows * (H + top + pad) + 40), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((pad, 10), title, fill=K.TEXT, font=K.font(16))
    base = rec
    for k, pick in enumerate(picks):
        cap, i, only = pick[:3]
        rec = pick[3] if len(pick) > 3 else base
        x0 = pad + (k % cols) * (W + pad)
        y0 = 40 + (k // cols) * (H + top + pad)
        if i is None:
            d.text((x0, y0 + 2), cap + ': not reached', fill=K.DIM, font=K.font(14))
            continue
        s = screen_img(rec, i, scale)
        boxes(s, rec, i, scale, only=only)
        img.paste(s, (x0, y0 + top))
        d.text((x0, y0 + 2), cap, fill=K.TEXT, font=K.font(14))
        v = {n: rec.var(P1 + o)[i] for n, o in (('laser', 10), ('weapon', 8), ('double', 9))}
        d.text((x0, y0 + 19), f'{rec.tag} frame {rec.F[i]}: laser {v["laser"]}, weapon {v["weapon"]}, '
                              f'double {v["double"]}', fill=K.DIM, font=K.font(12))
        print(cap, rec.F[i])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print('wrote', os.path.relpath(out, CASE))


def first(rec, pred, after=0):
    for i in range(len(rec.F)):
        if rec.F[i] >= after and pred(i):
            return i
    return None


def sheet(a):
    rec = Rec(a.npz, a.tag)
    weap, dbl, las = (rec.var(P1 + k) for k in (8, 9, 10))

    def kinds(i):
        return [k for _, k, _, _ in rec.active(i)]

    def lasers(i):
        return sum(1 for s, k, _, _ in rec.active(i) if 9 <= s <= 12)

    picks = [
        ('laser level 1: one shot in the air', first(rec, lambda i: las[i] == 1 and lasers(i) == 1, 60), (1,)),
        ('laser level 2: up to three shots', first(rec, lambda i: las[i] == 2 and lasers(i) >= 3), (1,)),
        ('plasma: one ball falls and bounces', first(rec, lambda i: weap[i] == 2 and 9 in kinds(i)), (9,)),
        ('double plasma: two balls', first(rec, lambda i: dbl[i] and kinds(i).count(9) >= 2), (9,)),
        ('homing: the sight 10 columns ahead', first(rec, lambda i: weap[i] == 3 and 6 in kinds(i)), (6, 8, 12, 4)),
    ]
    seek = Rec(a.npz2, a.tag2) if a.npz2 else rec

    def skinds(i):
        return [k for _, k, _, _ in seek.active(i)]

    sw = seek.var(P1 + 8)
    picks.append(('seeker: launched, after an enemy', first(seek, lambda i: sw[i] == 4 and 7 in skinds(i) and
                                                          (2 in skinds(i) or 11 in skinds(i))) or
                  first(seek, lambda i: sw[i] == 4 and 7 in skinds(i)), (7, 2, 11, 4), seek))
    panel_sheet(rec, picks, a.title, a.out)


def homing(a):
    rec = Rec(a.npz, a.tag)
    weap = rec.var(P1 + 8)
    lock = rec.var(0x80E2)

    def slot(i, s):
        return rec.O[i, 44 * s:44 * s + 44]

    def missile(i):
        r = slot(i, 14)
        return bool(r[8] & 0x80) and r[7] == 10

    launch = [i for i in range(1, len(rec.F)) if missile(i) and not missile(i - 1)]
    big = [i for i in range(len(rec.F)) if any(k == 12 for _, k, _, _ in rec.active(i))]
    gone = [i for i in range(1, len(rec.F)) if (i - 1) in big and i not in big]
    picks = [
        ('homing armed: the sight, no lock', first(rec, lambda i: weap[i] == 3 and lock[i] == 0 and
                                                   any(k == 6 for _, k, _, _ in rec.active(i))), (6, 8, 12)),
        ('a lock ($80E2 set): here the big enemy', first(rec, lambda i: weap[i] == 3 and lock[i] != 0), (6, 8, 12)),
        ('a missile launched ($9CFA)', launch[0] + 1 if launch else None, (6, 10, 8, 12)),
        ('the missile on its way, 6 frames later', launch[0] + 4 if launch else None, (6, 10, 8, 12)),
        ('the big enemy (kind 12) in play', big[len(big) // 2] if big else None, (12, 6, 10)),
        ('the big enemy destroyed', gone[-1] if gone else None, None),
    ]
    print('launches at', [int(rec.F[i]) for i in launch], 'big enemy gone at', [int(rec.F[i]) for i in gone])
    panel_sheet(rec, picks, a.title, a.out)


def gif(a):
    rec = Rec(a.npz, a.tag)
    only = tuple(int(v) for v in a.only.split(',')) if a.only else None
    pics, durs = [], []
    for i in range(len(rec.F)):
        f = rec.F[i]
        if a.frm <= f <= a.to and (f - a.frm) % a.every == 0:
            img = screen_img(rec, i, 2)
            boxes(img, rec, i, 2, only=only)
            canvas = Image.new('RGB', (512, 384 + 22), K.BACKGROUND)
            canvas.paste(img, (0, 22))
            ImageDraw.Draw(canvas).text((4, 3), f'{a.title}  {rec.tag} frame {f}', fill=K.TEXT, font=K.font(13))
            pics.append(canvas)
            durs.append(60)
    durs[0] = durs[-1] = 1200
    K.save_gif(a.out, pics, durs)
    print('wrote', os.path.relpath(a.out, CASE), len(pics), 'pictures', os.path.getsize(a.out) // 1024, 'KB')


OPTION_SITES = [
    ('INFINITE LIFE (key 8)', 0x9B4C, 8, (0x9B50,),
     ['LD A,($FFD7)', 'AND A', 'RET NZ', 'JP $9B5F'], ['LD A,($FFD7)', 'AND A', 'RET', 'JP $FF44'],
     'PlayerHit $9B4C: RET NZ becomes RET, the death path never runs'),
    ('INFINITE ROUNDS (key 3, YES at the start)', 0xB215, 7, (0xB218,),
     ['CALL $B0FF', 'JR NC,$B20F', 'JR $B203'], ['CALL $B0FF', 'JR $B20F', 'JR $B203'],
     'MainLoopEnd $B215: JR NC becomes JR, "game over" is ignored'),
    ('SELECT LEVEL (keys Q-P, A, S)', 0xB072, 6, (0xB073, 0xB074),
     ['ADD HL,DE', 'LD B,(HL)', 'INC B', 'LD DE,$0008'], ['ADD HL,DE', 'LD B,$0B', 'CALL $FF87'],
     'SetLevelStart $B073: LD B,(HL) / INC B becomes LD B,n, every start is level n (here 11)'),
]


def options(a):
    before = open(os.path.join(CASE, a.before), 'rb').read()
    after = open(os.path.join(CASE, a.after), 'rb').read()
    style()
    fig, axes = plt.subplots(len(OPTION_SITES), 1, figsize=(12, 7.6))
    for ax, (name, start, n, site, dis0, dis1, what) in zip(axes, OPTION_SITES, ):
        ax.set_xlim(0, 12)
        ax.set_ylim(0, 3)
        ax.axis('off')
        ax.text(0, 2.75, f'{name}: {what}', color=TEXT, fontsize=10.5, fontweight='bold', va='top')
        for row, (mem, dis, lab) in enumerate(((before, dis0, 'menu'), (after, dis1, 'game start'))):
            y = 1.6 - row * 1.0
            ax.text(0, y + 0.3, lab, color=DIM, fontsize=9, va='center')
            for k in range(n):
                addr = start + k
                hit = mem[addr] != (after if row == 0 else before)[addr]
                col = (COLOURS[0] if addr in site else COLOURS[3]) if hit else PANEL
                ax.add_patch(plt.Rectangle((1.4 + k * 0.62, y), 0.56, 0.6, color=col, ec=DIM))
                ax.text(1.68 + k * 0.62, y + 0.3, f'{mem[addr]:02X}', ha='center', va='center',
                        color='black' if hit else TEXT,
                        fontsize=10, family='monospace')
                if row == 0:
                    ax.text(1.68 + k * 0.62, y + 0.78, f'{addr:04X}', ha='center', color=DIM, fontsize=7.5,
                            family='monospace')
            ax.text(1.4 + n * 0.62 + 0.3, y + 0.3, ';  '.join(dis), color=TEXT, fontsize=9.5, va='center',
                    family='monospace')
    fig.suptitle('The hidden options are code patches: one or two bytes each, written by the menu at the start',
                 color=TEXT, fontsize=13)
    fig.text(0.01, 0.01, 'red: the option\'s bytes; yellow: an installer hook, written at the start too\n'
                         f'menu: {a.before}; game start: {a.after} (INFINITE LIFE and SELECT LEVEL 11 chosen)',
             color=DIM, fontsize=8.5)
    fig.subplots_adjust(left=0.02, right=0.99, top=0.9, bottom=0.07, hspace=0.25)
    save(fig, a.out)


def order(a):
    runs = []
    for tag, path in (a.orders or []):
        if path.startswith('list:'):  # read by gs_podbot.py at the start (PREFIX-events.txt)
            runs.append((tag, [int(v) for v in path[5:].split(',')]))
            continue
        mem = open(os.path.join(CASE, path), 'rb').read()
        runs.append((tag, list(mem[0x8003:0x800F])))
    style()
    fig, ax = plt.subplots(figsize=(12, 1.2 + 0.55 * len(runs)))
    for r, (tag, o) in enumerate(runs):
        y = len(runs) - 1 - r
        for k, lv in enumerate(o):
            fixed = k < 3 or k > 8 or lv == 0
            ax.add_patch(plt.Rectangle((k, y), 0.94, 0.85, color=(DIM if fixed else COLOURS[2]), alpha=0.35 if fixed
                                       else 0.9))
            txt = '0' if 3 <= k <= 8 and lv == 0 else str(lv + 1)
            ax.text(k + 0.47, y + 0.42, txt if k == 3 or txt[0] != '0' else '0', ha='center', va='center',
                    color=TEXT, fontsize=11 if len(txt) < 3 else 7)
        ax.text(-0.15, y + 0.42, tag, ha='right', va='center', color=TEXT, fontsize=9)
    ax.set_xlim(-4.2, 12.1)
    ax.set_ylim(-0.2, len(runs) + 0.3)
    ax.set_xticks([k + 0.47 for k in range(12)])
    ax.set_xticklabels([f'+{k}' for k in range(12)])
    ax.set_xlabel('the level index, player record +6 (LevelOrder $8003 + index = the level played, shown 1-12)')
    ax.set_yticks([])
    for s in ax.spines.values():
        s.set_visible(False)
    ax.set_title('Levels 1-3 and 10-12 keep their places; PlayersSetup ($AFFE) draws 4-9 anew for every game (blue; 0 = not drawn yet)',
                 loc='left', color=TEXT)
    fig.tight_layout()
    save(fig, a.out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['course', 'sheet', 'homing', 'gif', 'options', 'order'])
    p.add_argument('--npz')
    p.add_argument('--tag', default='')
    p.add_argument('--npz2', help='sheet: a second frame log for the seeker panel')
    p.add_argument('--tag2', default='')
    p.add_argument('--label', default='')
    p.add_argument('--title', default='')
    p.add_argument('--out', required=True)
    p.add_argument('--from', dest='frm', type=int, default=0)
    p.add_argument('--to', type=int, default=10 ** 9)
    p.add_argument('--every', type=int, default=2)
    p.add_argument('--only')
    p.add_argument('--before', default='work/zgsB/menu-cpu.bin')
    p.add_argument('--after', default='work/zgsB/e2/cpu-start.bin')
    p.add_argument('--order', dest='orders', nargs=2, action='append', metavar=('TAG', 'CPU64K'))
    a = p.parse_args()
    {'course': course, 'sheet': sheet, 'homing': homing, 'gif': gif, 'options': options, 'order': order}[a.what](a)


if __name__ == '__main__':
    main()

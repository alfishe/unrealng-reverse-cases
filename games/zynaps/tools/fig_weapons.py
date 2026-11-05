#!/usr/bin/env python3
"""The weapons recording w1 as figures (docs/10-gameplay-logic.md 10.3-10.5).

    python3 tools/fig_weapons.py course   [--npz work/zyB/w1-frames.npz]
    python3 tools/fig_weapons.py sheet    [--npz work/zyB/w1-frames.npz]
    python3 tools/fig_weapons.py gif NAME FROM TO [--every 2] [--npz ...]

The input is tools/ttd_dump.py's per-frame memory of a recording (TTD memory_at at each frame's end): the player
record $7F9C (+7 the pod selector, +8 the side weapon, +9 the double plasma, +$0A the laser level, +$0B the speed),
Fuel $80E6, FireHeld $8184, the score, and the 16 object records $F36C-$F62B (slot 0 the ship, 1-5 enemies and pods,
6-8 enemy shots, 9-12 laser shots, 13 the second plasma ball, 14 the side weapon's shot, 15 the sight).

  course  docs/img/play/weapons-course.png: the selector, the weapons and the fuel over the whole recording, each
          pod scooped marked (a selector step, or an action with fire held), the fuel's refills, halving and FuelOut.
  sheet   docs/img/play/weapons-sheet.png: one screen per weapon state at a frame where it shows, the objects of
          the weapon boxed and named.
  gif     docs/img/play/NAME.gif: the screen from FROM to TO (2x, every --every frames), the slots' kinds boxed.
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw

import zybplot as P

B = 0x7F9C
KINDS = {0: 'ship', 1: 'laser', 2: 'enemy', 3: 'explosion', 4: 'pod', 5: 'enemy shot', 6: 'sight', 7: 'seeker',
         8: 'lockable', 9: 'plasma', 10: 'missile', 11: 'enemy', 12: 'big enemy'}
KIND_COLOUR = {2: (230, 230, 230), 11: (230, 230, 230), 1: (255, 240, 80), 4: (80, 230, 110), 6: (90, 200, 255), 7: (255, 120, 220), 9: (255, 150, 60),
               10: (255, 80, 80), 8: (200, 110, 230), 12: (200, 110, 230)}
SIZES = {12: (72, 56), 1: (16, 6), 9: (8, 8), 10: (16, 8), 7: (16, 8), 6: (16, 16), 5: (8, 8)}
ACTIONS = ['speed', 'laser', 'plasma', 'homing', 'seeker']


class Rec:
    def __init__(self, path):
        d = np.load(path)
        self.F, self.V, self.O = d['frames'], d['vars'], d['objs']
        self.S = d['screen'] if 'screen' in d else None
        self.name = os.path.basename(path).split('-')[0]

    def var(self, addr):
        return self.V[:, addr - B].astype(int)

    def slot(self, i, s):
        r = self.O[i, 44 * s:44 * s + 44]
        return r

    def active(self, i):
        out = []
        for s in range(16):
            r = self.slot(i, s)
            if r[8] & 0x80:
                out.append((s, int(r[7]), int(r[3]) | int(r[4]) << 8, int(r[5]) | int(r[6]) << 8))
        return out


def events(rec):
    """the pod pick-ups: (frame, 'step' or 'action', the selector before, the action's name)"""
    sel, weap, dbl, las, spd = (rec.var(B + k) for k in (7, 8, 9, 10, 11))
    score = [int(bytes(rec.V[i, 0:4]).hex()) for i in range(len(rec.F))]
    out = []
    for i in range(1, len(rec.F)):
        gain = score[i] - score[i - 1]
        if sel[i] != sel[i - 1] or (gain >= 100 and (weap[i], dbl[i], las[i], spd[i]) !=
                                     (weap[i - 1], dbl[i - 1], las[i - 1], spd[i - 1])):
            if sel[i] == 0 and sel[i - 1] == 4 and gain >= 1100:
                out.append((int(rec.F[i]), 'wrap', int(sel[i - 1]), 'wrap: 1000 + 100 points, fuel $B4'))
            elif sel[i] == sel[i - 1] + 1:
                out.append((int(rec.F[i]), 'step', int(sel[i - 1]), ACTIONS[sel[i]]))
            else:
                name = ACTIONS[sel[i - 1]]
                if sel[i - 1] == 2 and dbl[i]:
                    name = 'double plasma'
                out.append((int(rec.F[i]), 'action', int(sel[i - 1]), name))
    return out


def course(rec):
    F = rec.F
    sel, weap, dbl, las, spd = (rec.var(B + k) for k in (7, 8, 9, 10, 11))
    fuel = rec.var(0x80E6)
    ev = events(rec)
    P.style()
    fig, axes = P.plt.subplots(3, 1, figsize=(14, 9.4), sharex=True, gridspec_kw={'height_ratios': [1.3, 1.2, 1.1]})
    ax = axes[0]
    ax.step(F, sel, where='post', color=P.COLOURS[2], lw=1.6, label='pod selector (record +7)')
    for f, kind, before, name in ev:
        if kind == 'action':
            ax.plot(f, before, marker='*', ms=15, color=P.COLOURS[3], zorder=5)
            ax.annotate(name, (f, before), xytext=(4, 8), textcoords='offset points', color=P.COLOURS[3],
                        fontsize=9.5, fontweight='bold')
        elif kind == 'wrap':
            ax.plot(f, before, marker='D', ms=8, color=P.COLOURS[0], zorder=5)
            ax.annotate('wrap', (f, before), xytext=(4, 6), textcoords='offset points', color=P.COLOURS[0])
        else:
            ax.plot(f, before + 1, marker='o', ms=6, color=P.COLOURS[1], zorder=5)
    ax.set_yticks(range(5))
    ax.set_yticklabels([f'{k} {n}' for k, n in enumerate(ACTIONS)])
    ax.set_ylim(-0.6, 4.9)
    ax.grid(alpha=0.3)
    steps = sum(1 for e in ev if e[1] == 'step')
    acts = sum(1 for e in ev if e[1] == 'action')
    ax.set_title(f'w1: {len(ev)} pods scooped. Without fire a pod moves the selector on (o, {steps}); with fire held '
                 f'8 passes it runs the selected action and the selector falls to 0 (*, {acts})')
    ax.plot([], [], 'o', color=P.COLOURS[1], label='pod without fire: selector + 1')
    ax.plot([], [], '*', ms=12, color=P.COLOURS[3], label='pod with fire held: the action')
    ax.legend(loc='center right', fontsize=8.5, ncol=1)
    ax = axes[1]
    ax.step(F, weap, where='post', color=P.COLOURS[4], lw=1.8, label='side weapon +8 (0 none, 2 plasma, 3 homing, 4 seeker)')
    ax.step(F, dbl + 0.05, where='post', color=P.COLOURS[0], lw=1.4, label='double plasma +9')
    ax.step(F, las - 0.05, where='post', color=P.COLOURS[3], lw=1.8, label='laser level +$0A (0-3)')
    ax.step(F, (spd - 0x40) / 32, where='post', color=P.COLOURS[5], lw=1.4, ls='--',
            label='speed +$0B: ($40 + $20 n), n')
    ax.set_ylim(-0.4, 4.6)
    ax.grid(alpha=0.3)
    ax.legend(loc='upper left', fontsize=8.5, ncol=2)
    ax.set_title('What the actions changed: speed $40->$60, laser 1->2, plasma, double plasma, homing (the plasma '
                 'gone), seeker; two FuelOuts took laser and speed back')
    ax = axes[2]
    ax.plot(F, fuel, color=P.COLOURS[1], lw=1.4, label='Fuel $80E6')
    for i in range(1, len(F)):
        if fuel[i] != fuel[i - 1] and fuel[i] != fuel[i - 1] - 1:
            if fuel[i] == 0x5A:
                txt = 'FuelOut: $5A,\nlaser -1, speed -$20'
            elif fuel[i] == 0xBB:
                txt = 'speed pod: $BB'
            elif fuel[i] == 0xB4:
                txt = 'wrap: $B4'
            elif fuel[i] == fuel[i - 1] // 2:
                txt = 'pod missed: halved'
            else:
                txt = f'{fuel[i - 1]}->{fuel[i]}'
            ax.annotate(txt, (F[i], fuel[i]), xytext=(6, 10 if fuel[i] > 60 else 28), textcoords='offset points',
                        color=P.TEXT, fontsize=8.5, arrowprops=dict(arrowstyle='->', color=P.DIM))
    ax.axhline(0x40, color=P.DIM, ls=':', lw=0.8)
    ax.axhline(0x20, color=P.DIM, ls=':', lw=0.8)
    ax.text(F[-1], 0x40 + 3, 'gauge: lamps go dark below $40, $20', ha='right', color=P.DIM, fontsize=8)
    dec = [F[i] for i in range(1, len(F)) if fuel[i] == fuel[i - 1] - 1]
    per = np.median(np.diff(dec))
    ax.set_title(f'The fuel: -1 every {per:.0f} frames ({len(dec)} steps measured), refilled by pods, '
                 f'halved by a missed pod, $5A after FuelOut')
    ax.set_ylim(-5, 205)
    ax.set_xlabel('w1 frame (TTD, from work/run/play-imm.szx: level 1, $FFD7 = 1)')
    ax.grid(alpha=0.3)
    fig.tight_layout()
    P.save(fig, P.out('play', 'weapons-course.png'))
    for e in ev:
        print(e)


def boxes(img, rec, i, scale, only=None, label=True):
    """the active slots' boxes on a screen image: X in columns of 8 pixels from X 16 (the screen's left edge), Y in
    rows of 8 pixels from Y -1 (row 0 is pixel line 8, below the score line); the box sizes are
    the sprites' (SIZES, 24 x 16 for the ship and the enemies), checked against the screens"""
    d = ImageDraw.Draw(img)
    f = P.K.font(9 * scale // 2 + 2)
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
        if label:
            d.text((px, py + h * scale + 3), KINDS.get(kind, str(kind)), fill=col, font=f)


def screen_img(rec, i, scale=2):
    img = P.screen(bytes(rec.S[i]))
    return img.resize((256 * scale, 192 * scale), Image.NEAREST)


def sheet(rec):
    sel, weap, dbl, las = (rec.var(B + k) for k in (7, 8, 9, 10))
    F = rec.F

    def first(pred, after=0):
        for i in range(len(F)):
            if F[i] >= after and pred(i):
                return i
        return None

    def kinds(i):
        return [k for _, k, _, _ in rec.active(i)]

    def lasers(i):
        return sum(1 for s, k, _, _ in rec.active(i) if 9 <= s <= 12)

    picks = [
        ('laser level 1: one shot in the air', first(lambda i: las[i] == 1 and lasers(i) == 1, 60), (1,)),
        ('laser level 2: up to three shots', first(lambda i: las[i] == 2 and lasers(i) >= 3), (1,)),
        ('plasma: one ball falls and bounces', first(lambda i: weap[i] == 2 and 9 in kinds(i), 900), (9,)),
        ('double plasma: two balls', first(lambda i: dbl[i] and kinds(i).count(9) >= 2, 1900), (9,)),
        ('homing: the sight 10 columns ahead', first(lambda i: weap[i] == 3 and 6 in kinds(i), 2600), (6, 4)),
        ('seeker: launched, no enemy yet', first(lambda i: weap[i] == 4 and 7 in kinds(i) and (2 in kinds(i) or 11 in kinds(i)), 3560)
         or first(lambda i: weap[i] == 4 and 7 in kinds(i), 3560), (7, 2, 11, 4)),
    ]
    P.style()
    scale = 2
    W, H = 256 * scale, 192 * scale
    pad, top = 10, 34
    out = Image.new('RGB', (3 * W + 4 * pad, 2 * (H + top) + 3 * pad + 30), tuple(int(c * 255) for c in P.BG))
    d = ImageDraw.Draw(out)
    f = P.K.font(15)
    d.text((pad, 8), 'The weapons in w1, one screen each (frame end, the game\'s colours, flash phase 0); the '
                     'weapon\'s objects boxed from their records', fill=P.K.TEXT, font=P.K.font(16))
    for k, (title, i, only) in enumerate(picks):
        x0 = pad + (k % 3) * (W + pad)
        y0 = 30 + pad + (k // 3) * (H + top + pad)
        img = screen_img(rec, i, scale)
        boxes(img, rec, i, scale, only=only)
        out.paste(img, (x0, y0 + top))
        d.text((x0, y0 + 2), f'{title}', fill=P.K.TEXT, font=f)
        d.text((x0, y0 + 18), f'w1 frame {F[i]}: laser {las[i]}, weapon {weap[i]}, double {dbl[i]}',
               fill=P.K.DIM, font=P.K.font(12))
        print(title, F[i])
    path = P.out('play', 'weapons-sheet.png')
    out.save(path)
    print('wrote', os.path.relpath(path, P.CASE))


def gif(rec, name, lo, hi, every, only=None, title=''):
    pics, durs = [], []
    F = rec.F
    for i in range(len(F)):
        if lo <= F[i] <= hi and (F[i] - lo) % every == 0:
            img = screen_img(rec, i, 2)
            boxes(img, rec, i, 2, only=only)
            canvas = Image.new('RGB', (512, 384 + 22), tuple(int(c * 255) for c in P.BG))
            canvas.paste(img, (0, 22))
            ImageDraw.Draw(canvas).text((4, 3), f'{title}  {rec.name} frame {F[i]}', fill=P.K.TEXT, font=P.K.font(13))
            pics.append(canvas)
            durs.append(60)
    durs[0] = durs[-1] = 1200
    path = P.out('play', name + '.gif')
    P.K.save_gif(path, pics, durs)
    print('wrote', os.path.relpath(path, P.CASE), len(pics), 'pictures', os.path.getsize(path) // 1024, 'KB')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what')
    p.add_argument('rest', nargs='*')
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'zyB', 'w1-frames.npz'))
    p.add_argument('--every', type=int, default=2)
    p.add_argument('--only', help='kinds to box, comma-separated')
    p.add_argument('--title', default='')
    a = p.parse_args()
    rec = Rec(a.npz)
    if a.what == 'course':
        course(rec)
    elif a.what == 'sheet':
        sheet(rec)
    elif a.what == 'gif':
        only = tuple(int(v) for v in a.only.split(',')) if a.only else None
        gif(rec, a.rest[0], int(a.rest[1]), int(a.rest[2]), a.every, only, a.title)


if __name__ == '__main__':
    main()

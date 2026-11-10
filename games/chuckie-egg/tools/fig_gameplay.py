#!/usr/bin/env python3
"""The figures of doc 10 (gameplay logic), drawn from the code's rules and from memory samples of levels-1-9.

    python3 tools/fig_gameplay.py jump       --samples V.jsonl --out docs/img/gameplay/jump-arc.png
    python3 tools/fig_gameplay.py eggtest    --out docs/img/gameplay/egg-test.png
    python3 tools/fig_gameplay.py duck       --samples V.jsonl --from 23541 --to 25048 --out docs/img/gameplay/duck.png
    python3 tools/fig_gameplay.py difficulty --out docs/img/gameplay/difficulty.png
    python3 tools/fig_gameplay.py score      --game G.jsonl --out docs/img/gameplay/score-lives.png
    python3 tools/fig_gameplay.py bug        --bug DIR --control DIR --out docs/img/gameplay/heneatgrain-bug.png
    python3 tools/fig_gameplay.py lifthud    --out docs/img/gameplay/lift-top-hud.png

V.jsonl holds memory_at samples of $72D8-$7375 (the object block), G.jsonl of $6EC8-$6EF3 (score, eggs, level,
lives), one line {"frame": F, "hex": ...} a frame, written by work/docs/ceC/sample.py. A sample of frame F is the
memory at the start of frame F. Coordinates are the game's: x from the left, y from the bottom.
"""
import argparse
import json
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_objects as FO  # noqa: E402

BLOCK = 0x72D8
GAME = 0x6EC8
BG = tuple(c / 255 for c in FO.BG)
FG = tuple(c / 255 for c in FO.TEXT)
DIM = tuple(c / 255 for c in FO.DIM)
ORANGE, CYAN, YELLOW, GREEN, RED, VIOLET = '#f08c3c', '#50c8e6', '#e6e66e', '#6edc8c', '#e66464', '#be8cf0'


def style():
    plt.rcParams.update({
        'figure.facecolor': BG, 'axes.facecolor': BG, 'savefig.facecolor': BG,
        'text.color': FG, 'axes.labelcolor': FG, 'xtick.color': FG, 'ytick.color': FG,
        'axes.edgecolor': DIM, 'grid.color': (0.25, 0.25, 0.3), 'font.size': 11,
        'axes.titlesize': 12, 'legend.facecolor': BG, 'legend.edgecolor': DIM, 'legend.fontsize': 10,
    })


def save(fig, out):
    fig.savefig(out, dpi=100)
    plt.close(fig)
    print(out, Image.open(out).size)


def var(m, addr, base=BLOCK):
    return m[addr - base]


def signed(v):
    return v - 256 if v > 127 else v


# The jump and fall models, in passes of MainLoop (JumpFall $A2B5, JumpRise, JumpFallFaster)

def jump_steps():
    """(pass, dy) of every vertical step of a flat jump from its start (JumpStep sets JumpCount $8C, JumpDelay 0)"""
    steps, t, count, delay = [], 0, 0x8C, 256          # JumpDelay 0: DEC gives 255, so 256 passes to the first step
    for _ in range(11):                                # rising: count += 10 each step, delay = count
        t += delay
        steps.append((t, +1))
        count += 10
        delay = count
    t += delay                                         # count reached 250: the next step is the top
    steps.append((t, 0))                               # top: JumpDy 0, JumpCount 0, JumpDelay 0 -> 256
    delay = 256
    count = 0xFA
    for _ in range(30):                                # falling: count -= 10 down to 40, delay = count
        t += delay
        steps.append((t, -1))
        delay = count
        count = max(40, count - 10)
    return steps


def fall_steps(stale, n):
    """(pass, dy) of a fall off an edge: the first step after the stale JumpDelay, then 240, 230, ... 40"""
    steps, t, delay, count = [], 0, stale, 240
    for _ in range(n):
        t += delay
        steps.append((t, -1))
        delay = count
        count = max(40, count - 10)
    return steps


def cmd_jump(args):
    style()
    S = FO.load_samples(args.samples)
    fig = plt.figure(figsize=(10.5, 7.6))
    gs = fig.add_gridspec(2, 2, height_ratios=[1.15, 1], hspace=0.42, wspace=0.22,
                          left=0.07, right=0.98, top=0.9, bottom=0.11)
    fig.suptitle('Harry\'s jump and fall: the model in MainLoop passes against levels-1-9', fontsize=15)
    # (a) the jump: y against x
    ax = fig.add_subplot(gs[0, :])
    x0, y0 = 120, 151
    pts = [(0, x0, y0)]
    y = y0
    for t, dy in jump_steps():
        y += dy
        pts.append((t, x0 + t // 130, y))
        if dy < 0 and y == y0:
            break
    xs = [x0]
    ys = [y0]
    for (t, x, yv) in pts[1:]:
        xs += [x, x]
        ys += [ys[-1], yv]
    ax.plot(xs, ys, color=ORANGE, lw=2, label='model: a step every JumpDelay passes, x + 1 every 130 passes')
    fr = range(args.jump_from, args.jump_to + 1)
    sx = [var(S[f], 0x72D8) for f in fr]
    sy = [var(S[f], 0x72D9) for f in fr]
    ax.plot(sx, sy, 'o', color=CYAN, ms=6, label='recording: HarryX, HarryY at the start of frames %d-%d'
            % (args.jump_from, args.jump_to))
    for f, xv, yv in zip(fr, sx, sy):
        off = {1888: (-60, 8), 1906: (-70, 6), 1908: (8, 6), 1927: (8, 8)}
        if f in off:
            ax.annotate('frame %d' % f, (xv, yv), textcoords='offset points', xytext=off[f], fontsize=10,
                        color=FG)
    ax.set_xlabel('HarryX (pixels)')
    ax.set_ylabel('HarryY (pixels up)')
    ax.set_title('(a) A flat jump on level 1: 11 rises, the top, 11 falls; 4762 passes, 36 pixels to the right')
    ax.grid(True)
    ax.legend(loc='lower center')
    ax.set_ylim(148, 166)
    # (b) the delay of every step
    ax = fig.add_subplot(gs[1, 0])
    st = jump_steps()
    d = [st[0][0]] + [st[k][0] - st[k - 1][0] for k in range(1, len(st))]
    d = d[:23]
    cols = [GREEN] * 11 + [YELLOW] + [RED] * 11
    ax.bar(range(1, 24), d, color=cols)
    ax.set_xlabel('vertical step of a flat jump')
    ax.set_ylabel('passes before the step')
    ax.set_title('(b) Rise (green), top (yellow), fall (red)')
    ax.grid(True, axis='y')
    # (c) a fall off an edge, against the recording
    ax = fig.add_subplot(gs[1, 1])
    fr = range(args.fall_from, args.fall_to + 1)
    ys = [var(S[f], 0x72D9) for f in fr]
    js = [var(S[f], 0x7325) for f in fr]
    ax.plot(list(fr), ys, '-o', color=CYAN, ms=3, label='HarryY')
    for f, j in zip(fr, js):
        if j == 1:
            ax.axvspan(f - 0.5, f + 0.5, color=YELLOW, alpha=0.25, lw=0)
        elif j == 2:
            ax.axvspan(f - 0.5, f + 0.5, color=RED, alpha=0.12, lw=0)
    ax.set_xlabel('frame (levels-1-9)')
    ax.set_ylabel('HarryY')
    ax.set_title('(c) Off an edge: drift (yellow), fall (red)')
    ax.grid(True)
    fig.text(0.07, 0.01, 'tools/fig_gameplay.py jump; samples work/docs/ceC/l19-vars.jsonl (TTD memory_at, '
             'the state at the start of each frame)', color=DIM, fontsize=10)
    save(fig, args.out)


# The egg test (TakeEggOrGrain $99DF reads the cell at (x + 8, y - 8))

def cmd_eggtest(args):
    spr, _hen = FO.sprites()
    scale, cw, ch = 4, 72, 56
    panels = [
        (1, 47, 23, 4, ['Level 1, frame 568: walking left,', 'Harry reaches (47, 23)'],
         ['The point (55, 15) is in cell (6, 1):', 'the egg is taken.']),
        (4, 211, 119, 0, ['Level 4: walking on row 12', 'at (211, 119)'],
         ['The point (219, 111) is in row 13:', 'the egg in the floor is missed.']),
        (4, 211, 111, 0, ['Level 4, frame 8517: falling', 'through the hole at (211, 111)'],
         ['The point (219, 103) is in row 12:', 'the egg is taken.']),
    ]
    pw = cw * scale
    W = 1050
    gap = (W - 3 * pw) // 4
    head = 52
    ph = ch * scale
    top = 50
    H = top + head + ph + 140
    img = Image.new('RGB', (W, H), FO.BG)
    d = ImageDraw.Draw(img)
    d.text((gap, 12), 'The egg test: TakeEggOrGrain $99DF reads the map cell under the point (x + 8, y - 8)',
           fill=FO.TEXT, font=FO.font(18))
    for k, (lv, hx, hy, frame, t1, t2) in enumerate(panels):
        m = FO.map_image(lv, 1)
        mp = m.load()
        # Harry's pixels only where the map is black, so the egg under him stays visible
        sp = spr[frame * 32:frame * 32 + 32]
        for row in range(16):
            for bit in range(16):
                if sp[row * 2 + bit // 8] >> (7 - bit % 8) & 1:
                    cx, cy = hx + bit, 167 - hy + row
                    if 0 <= cx < 256 and 0 <= cy < 168 and mp[cx, cy] == (0, 0, 0):
                        mp[cx, cy] = FO.INK[6]
        cx0 = max(0, min(256 - cw, hx - 28))
        cy0 = max(0, min(168 - ch, 167 - hy - 24))
        crop = m.crop((cx0, cy0, cx0 + cw, cy0 + ch)).resize((cw * scale, ch * scale), Image.NEAREST)
        cd = ImageDraw.Draw(crop)
        for gx in range(cw):                            # the cell grid
            if (cx0 + gx) % 8 == 0:
                cd.line([gx * scale, 0, gx * scale, ch * scale], fill=(45, 45, 60))
        for gy in range(ch):
            if (167 - (cy0 + gy) + 1) % 8 == 0:
                cd.line([0, gy * scale, cw * scale, gy * scale], fill=(45, 45, 60))
        px, py = hx + 8, hy - 8
        col, row = px // 8, py // 8
        bx, by = (col * 8 - cx0) * scale, (167 - (row * 8 + 7) - cy0) * scale
        hit = FO.level_cells(lv)[col + 32 * row] == 3
        cd.rectangle([bx, by, bx + 8 * scale - 1, by + 8 * scale - 1],
                     outline=(80, 255, 120) if hit else (255, 80, 80), width=3)
        hx0, hy0 = (hx - cx0) * scale, (167 - hy - cy0) * scale
        cd.rectangle([hx0, hy0, hx0 + 16 * scale - 1, hy0 + 16 * scale - 1], outline=(235, 200, 60))
        sx, sy = (px - cx0) * scale + 2, (167 - py - cy0) * scale + 2
        cd.ellipse([sx - 5, sy - 5, sx + 5, sy + 5], fill=(255, 255, 255), outline=(255, 80, 80))
        ox = gap + k * (pw + gap)
        for j, t in enumerate(t1):
            d.text((ox, top + j * 22), t, fill=FO.TEXT, font=FO.font(14))
        img.paste(crop, (ox, top + head))
        for j, t in enumerate(t2):
            d.text((ox, top + head + ph + 8 + j * 22), t, fill=FO.TEXT, font=FO.font(14))
    d.text((gap, H - 64), 'Yellow box: Harry\'s 16 x 16 sprite, its top at HarryY. White dot: the test point.',
           fill=FO.DIM, font=FO.font(14))
    d.text((gap, H - 42), 'Green box: the cell read holds an egg; red: it does not. Grid: the 8 x 8 map cells.',
           fill=FO.DIM, font=FO.font(14))
    d.text((gap, H - 20), 'tools/fig_gameplay.py eggtest; maps from src/res/maps, positions from levels-1-9 '
           '(samples of frames 569 and 8518).', fill=FO.DIM, font=FO.font(13))
    img.save(args.out)
    print(args.out, img.size)


# The duck on level 9

def cmd_duck(args):
    style()
    S = FO.load_samples(args.samples)
    fr = [f for f in range(args.frm, args.to + 1) if f in S]
    fig = plt.figure(figsize=(10.5, 8.4))
    gs = fig.add_gridspec(2, 1, height_ratios=[1.35, 1], hspace=0.3, left=0.07, right=0.92, top=0.92,
                          bottom=0.13)
    fig.suptitle('The duck homes on Harry: levels-1-9, level 9, frames %d-%d' % (args.frm, args.to), fontsize=15)
    ax = fig.add_subplot(gs[0])
    m = FO.map_image(1, 1)
    ax.imshow(m, extent=(0, 256, 0, 168), alpha=0.55)
    hx = [var(S[f], 0x72D8) + 8 for f in fr]
    hy = [var(S[f], 0x72D9) - 8 for f in fr]
    dx = [var(S[f], 0x7348) + 8 for f in fr]
    dy = [var(S[f], 0x7349) - 8 for f in fr]
    ax.plot(hx, hy, color=YELLOW, lw=1.5, label='Harry (the centre of his sprite)')
    ax.plot(dx, dy, color=CYAN, lw=1.5, label='the duck (the centre of its sprite)')
    ax.plot(dx[0], dy[0], 's', color=CYAN, ms=8)
    ax.annotate('the duck leaves the cage', (dx[0], dy[0]), textcoords='offset points', xytext=(10, -14),
                color=FG, fontsize=10)
    ax.set_xlim(0, 256)
    ax.set_ylim(0, 176)
    ax.set_xlabel('x (pixels)')
    ax.set_ylabel('y (pixels up)')
    ax.legend(loc='upper right')
    ax = fig.add_subplot(gs[1])
    ax.plot(fr, [signed(var(S[f], 0x734A)) for f in fr], color=ORANGE, label='DuckDx')
    ax.plot(fr, [signed(var(S[f], 0x734B)) for f in fr], color=VIOLET, label='DuckDy')
    ax2 = ax.twinx()
    ax2.plot(fr, [var(S[f], 0x7348) - var(S[f], 0x72D8) for f in fr], color=CYAN, lw=0.8, alpha=0.7,
             label='DuckX - HarryX')
    ax2.plot(fr, [var(S[f], 0x7349) - var(S[f], 0x72D9) for f in fr], color=GREEN, lw=0.8, alpha=0.7,
             label='DuckY - HarryY')
    ax2.set_ylabel('distance (pixels)')
    ax.set_ylabel('speed (pixels a duck step)')
    ax.set_ylim(-6, 6)
    ax.grid(True)
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc='upper center', ncol=4, bbox_to_anchor=(0.5, -0.1))
    fig.text(0.07, 0.01, 'tools/fig_gameplay.py duck; samples work/docs/ceC/l19-vars.jsonl (the state at the '
             'start of each frame); map src/res/maps/Level1.txt', color=DIM, fontsize=10)
    save(fig, args.out)


# The difficulty by level, from SetupLevel $AE9C, MainLoop $9935, MoveDuck $A16E, TakeEggOrGrain $99F3

def level_rules(L):
    lv = L - 1
    hens = 0 if 8 <= lv < 16 else (5 if lv >= 24 else FO.hen_table()[(lv & 7) + 1][0] // 4)
    return {
        'time': 100 * (9 - min(lv // 16, 5)),
        'bonus': 1000 * min(lv + 1, 9),
        'egg': 100 * (1 + min(lv // 4, 9)),
        'hens': hens,
        'henperiod': 2 if lv >= 0x20 else 3,
        'duck': 1 if lv >= 8 else 0,
    }


def cmd_difficulty(args):
    style()
    Ls = list(range(1, args.levels + 1))
    R = [level_rules(L) for L in Ls]
    fig, axs = plt.subplots(4, 1, figsize=(10.5, 8.6), sharex=True,
                            gridspec_kw={'hspace': 0.28, 'left': 0.08, 'right': 0.98, 'top': 0.92,
                                         'bottom': 0.08})
    fig.suptitle('Difficulty by level: what SetupLevel, MainLoop, MoveDuck and TakeEggOrGrain derive from Level',
                 fontsize=14)
    ax = axs[0]
    ax.step(Ls, [r['time'] for r in R], where='mid', color=CYAN, label='time at the start')
    ax.step(Ls, [r['bonus'] / 10 for r in R], where='mid', color=YELLOW, label='bonus at the start / 10')
    ax.set_ylabel('points')
    ax.legend(loc='lower center')
    ax.set_title('Time 900 on levels 1-16, 100 less every 16 levels, 400 from level 81; bonus 1000-9000')
    ax = axs[1]
    ax.step(Ls, [r['egg'] for r in R], where='mid', color=ORANGE)
    ax.set_ylabel('egg points')
    ax.set_title('An egg: 100 on levels 1-4, 100 more every 4 levels, 1000 from level 37')
    ax = axs[2]
    ax.bar(Ls, [r['hens'] for r in R], color=GREEN, width=0.8)
    ax.set_ylabel('hens')
    ax.set_title('Hens: the map\'s 2-4 on levels 1-8 and 17-24, none on 9-16, five from level 25')
    ax = axs[3]
    ax.step(Ls, [r['henperiod'] for r in R], where='mid', color=VIOLET, label='slow ticks between hen turns')
    ax.step(Ls, [r['duck'] for r in R], where='mid', color=RED, label='duck free (1) or caged (0)')
    ax.set_ylabel('')
    ax.set_ylim(-0.3, 4.6)
    ax.legend(loc='upper right', ncol=2)
    ax.set_title('Hens every 3 slow ticks, every 2 from level 33; the duck free from level 9')
    ax.set_xlabel('level (the map is ((level - 1) AND 7) + 1)')
    for a in axs:
        a.grid(True)
        for b in (9, 17, 25, 33, 37, 81):
            a.axvline(b - 0.5, color=DIM, lw=0.6, ls=':')
    fig.text(0.08, 0.01, 'tools/fig_gameplay.py difficulty; the rules read from the code (game.ann), '
             'the hen counts from src/res/tables/HenTable.csv', color=DIM, fontsize=10)
    save(fig, args.out)


# The score and lives over levels-1-9

def cmd_score(args):
    style()
    G = FO.load_samples(args.game)
    fr = sorted(f for f in G if f >= args.frm)
    score = [int(''.join(str(v) for v in G[f][0:6])) if max(G[f][0:6]) <= 9 else None for f in fr]
    lives = [G[f][0x6EF0 - GAME] for f in fr]
    level = [G[f][0x6EEB - GAME] + 1 for f in fr]
    eggs = [G[f][0x6EE6 - GAME] for f in fr]
    fig, axs = plt.subplots(2, 1, figsize=(10.5, 6.4), sharex=True,
                            gridspec_kw={'hspace': 0.15, 'height_ratios': [1.6, 1], 'left': 0.09,
                                         'right': 0.91, 'top': 0.9, 'bottom': 0.1})
    fig.suptitle('levels-1-9: score, lives and eggs left, frame by frame', fontsize=15)
    ax = axs[0]
    ax.plot(fr, score, color=YELLOW, label='score')
    for k in range(1, len(fr)):
        if level[k] != level[k - 1]:
            for a in axs:
                a.axvline(fr[k], color=DIM, lw=0.8, ls=':')
            ax.text(fr[k] + 80, 2000, 'L%d' % level[k], color=FG, fontsize=10)
        if lives[k] > lives[k - 1]:
            ax.plot(fr[k], score[k], 'o', color=GREEN, ms=7)
        if lives[k] < lives[k - 1]:
            ax.plot(fr[k], score[k], 'X', color=RED, ms=9)
    ax.plot([], [], 'o', color=GREEN, label='a life gained (the 10 000s digit changed)')
    ax.plot([], [], 'X', color=RED, label='a life lost (a hen, level 8)')
    ax.set_ylabel('score')
    ax.legend(loc='upper left')
    ax.grid(True)
    ax2 = ax.twinx()
    ax2.step(fr, lives, where='post', color=GREEN, lw=1)
    ax2.set_ylabel('lives', color=GREEN)
    ax2.set_ylim(0, 12)
    ax = axs[1]
    ax.step(fr, eggs, where='post', color=FG, lw=0.8)
    ax.set_ylabel('eggs left')
    ax.set_xlabel('frame')
    ax.grid(True)
    fig.text(0.09, 0.01, 'tools/fig_gameplay.py score; samples work/docs/ceC/l19-game.jsonl (\\$6EC8-\\$6EF3, '
             'the state at the start of each frame)', color=DIM, fontsize=10)
    save(fig, args.out)


# The HenEatGrain experiment (work/docs/ceC/heg.py on a clone of work/stage1/bot/l8b-row4.szx)

def cmd_bug(args):
    rows = [(args.bug, 'Harry at x 152 (hen x - 8): the left peck kills through HenEatGrain, RET to ROM $0100/$0101',
             [(2, 'frame 2: the peck'), (31, 'frame 31: RAM filled'), (61, 'frame 61: cleared'),
              (121, 'frame 121: reset')]),
            (args.control, 'Harry at x 153 (hen x - 7): the hen\'s erase test kills him the normal way',
             [(2, 'frame 2: the kill'), (11, 'frame 11: death tune'), (61, 'frame 61: death tune'),
              (240, 'frame 240: still the tune')])]
    sw, sh = 252, 189
    gap = (1050 - 4 * sw) // 5
    H = 50 + 2 * (34 + sh + 30) + 40
    img = Image.new('RGB', (1050, H), FO.BG)
    d = ImageDraw.Draw(img)
    d.text((gap, 12), 'HenEatGrain on a clone: a hen walking left at (160, 8) pecks the grain in cell (19, 1)',
           fill=FO.TEXT, font=FO.font(18))
    y = 50
    for folder, title, shots in rows:
        d.text((gap, y), title, fill=FO.TEXT, font=FO.font(14))
        for k, (f, t) in enumerate(shots):
            im = Image.open(os.path.join(folder, 'f%03d.png' % f)).convert('RGB').resize((sw, sh), Image.LANCZOS)
            x = gap + k * (sw + gap)
            img.paste(im, (x, y + 28))
            d.text((x, y + 28 + sh + 4), t, fill=FO.DIM, font=FO.font(13))
        y += 34 + sh + 30
    d.text((gap, H - 26), 'tools/fig_gameplay.py bug; screens from work/docs/ceC/heg.py 152 and 153 (frames '
           'counted from the pokes)', fill=FO.DIM, font=FO.font(13))
    img.save(args.out)
    print(args.out, img.size)


# The HUD damage at the top of the lift shaft (lift-top.gif: its first and last pictures, levels-1-9 5905 and 5995)

LIVEMAP = 0x61A8


def cmd_lifthud(args):
    gif = Image.open(args.gif)
    gif.seek(0)
    first = gif.convert('RGB')
    gif.seek(gif.n_frames - 1)
    last = gif.convert('RGB')
    cell = first.width // 32                                  # the GIF is the screen at scale 2: 16 px a cell
    rows = 4                                                  # character rows 0-3 from the top
    scale = 1.75
    sw, sh = int(first.width * scale), int(rows * cell * scale)
    gap = 44
    W = sw + 2 * gap
    H = 60 + 2 * (30 + sh + 16) + 170
    img = Image.new('RGB', (W, H), FO.BG)
    d = ImageDraw.Draw(img)
    d.text((gap, 14), 'Lift-top trick, level 3: map row 21 painted from y 168, row 22 from y 176',
           fill=FO.TEXT, font=FO.font(18))
    changed = []
    for cr in range(rows):
        for c in range(14):                                   # the HUD's left half; the right half is the counters
            box = (c * cell, cr * cell, (c + 1) * cell, (cr + 1) * cell)
            if list(first.crop(box).getdata()) != list(last.crop(box).getdata()):
                changed.append((cr, c))
    y = 56
    for picture, title in ((first, 'frame %d: the HUD intact (PLAYER 1, LEVEL 03, four life icons)' % args.first),
                           (last, 'frame %d: LEVEL 03 and one life icon overwritten by bricks and a ladder top'
                            % args.last)):
        d.text((gap, y), title, fill=FO.TEXT, font=FO.font(15))
        crop = picture.crop((0, 0, picture.width, rows * cell)).resize((sw, sh), Image.NEAREST)
        img.paste(crop, (gap, y + 26))
        if picture is last:
            for cr, c in changed:
                x0, y0 = gap + c * cell * scale, y + 26 + cr * cell * scale
                d.rectangle((x0, y0, x0 + cell * scale - 1, y0 + cell * scale - 1), outline=(80, 200, 230), width=2)
        for cr in range(rows):
            d.text((6, y + 26 + cr * cell * scale + 8), 'r%d' % (23 - cr), fill=FO.DIM, font=FO.font(13))
        y += 30 + sh + 16
    by_row = {}
    for cr, c in changed:
        by_row.setdefault(23 - cr, []).append(c)
    lines = ['Cyan: the cells that changed (columns 0-13). r: the map row. The map has rows 0-20; 21-22 lie past '
             'slot 0:']
    for r in sorted(by_row):
        cs = by_row[r]
        lines.append('  map row %d, columns %s: LiveMap + 32 x %d + column = $%04X-$%04X, slot 1 row %d'
                     % (r, ', '.join(str(c) for c in cs), r, LIVEMAP + 32 * r + cs[0], LIVEMAP + 32 * r + cs[-1],
                        r - 21))
    lines.append('Slot 1 (player 1\'s map, $6448) holds level 1 as StartGame wrote it:')
    lines.append('  row 0 all bricks; row 1 empty at column 8, a ladder at columns 10-11.')
    lines.append('DrawSprite redraws the pixels from those cells, PaintCells their attributes.')
    for k, t in enumerate(lines):
        d.text((gap, y + 4 + 22 * k), t, fill=FO.TEXT, font=FO.font(13))
    d.text((gap, H - 24), 'tools/fig_gameplay.py lifthud; pictures from docs/img/play/lift-top.gif (levels-1-9)',
           fill=FO.DIM, font=FO.font(12))
    img.save(args.out)
    print(args.out, img.size, sorted(by_row.items()))


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('jump')
    s.add_argument('--samples', required=True)
    s.add_argument('--jump-from', type=int, default=1886)
    s.add_argument('--jump-to', type=int, default=1929)
    s.add_argument('--fall-from', type=int, default=912)
    s.add_argument('--fall-to', type=int, default=962)
    s.add_argument('--out', required=True)
    s = sub.add_parser('eggtest')
    s.add_argument('--out', required=True)
    s = sub.add_parser('duck')
    s.add_argument('--samples', required=True)
    s.add_argument('--from', dest='frm', type=int, default=23541)
    s.add_argument('--to', type=int, default=25048)
    s.add_argument('--out', required=True)
    s = sub.add_parser('difficulty')
    s.add_argument('--levels', type=int, default=100)
    s.add_argument('--out', required=True)
    s = sub.add_parser('score')
    s.add_argument('--game', required=True)
    s.add_argument('--from', dest='frm', type=int, default=280)
    s.add_argument('--out', required=True)
    s = sub.add_parser('bug')
    s.add_argument('--bug', required=True)
    s.add_argument('--control', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('lifthud')
    s.add_argument('--gif', default='docs/img/play/lift-top.gif')
    s.add_argument('--first', type=int, default=5905)
    s.add_argument('--last', type=int, default=5995)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    globals()['cmd_' + args.cmd](args)


if __name__ == '__main__':
    main()

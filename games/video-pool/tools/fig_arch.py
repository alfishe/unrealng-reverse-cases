#!/usr/bin/env python3
"""Doc 02's time figures from the L1 builds: the module heatmap (every module's share of the CPU's time in every
recording) and the frame budget (one average frame of each recording, split into waiting, the sound loop, the
game's modules and the ROM).

    python3 tools/fig_arch.py modules|budget|all [--out-dir docs/img/arch]

The builds: work/game/l1.json (c1 from the game's entry) and work/runs/{w1,f1,p2,v1,m1,j1,e1}/l1.json. Each L1
instruction carries its address, page, code, count and T-states summed over the recording; a recording's time is
its frames x 69 888 T. A module is cut as kit/mkgame.py cuts the source: from the first entry after its @module line
to the next module's first entry. HALT instructions are their own row (the CPU waiting for the interrupt), the ROM
another; SoundLoop $8069-$80AF, the foreground of play, is taken out of main.
"""
import argparse
import json
import math
import os
import re
import sys
from bisect import bisect_right

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

WIDTH = 1050
FRAME_T = 69888
BUILDS = [('game', 'work/game/l1.json', 'c1 from the entry: presents, menu, a game of fouls'),
          ('w1', 'work/runs/w1/l1.json', 'a won game to the hall of fame'),
          ('f1', 'work/runs/f1/l1.json', 'the fouls'),
          ('p2', 'work/runs/p2/l1.json', 'two players'),
          ('v1', 'work/runs/v1/l1.json', 'the variations'),
          ('m1', 'work/runs/m1/l1.json', 'attract, every menu option'),
          ('j1', 'work/runs/j1/l1.json', 'the joysticks'),
          ('e1', 'work/runs/e1/l1.json', 'the editor')]
SOUND = (0x8069, 0x80AF)


def modules():
    """Every entry's address and the module it is written under, by address; and the module names by first entry"""
    starts, names, cur = [], [], None
    for line in open(os.path.join(CASE, 'src', 'game', 'game.ann')):
        m = re.match(r'@module (\w+)', line)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r'\$([0-9A-F]{4}) [cbwts] ', line)
        if m and cur:
            starts.append(int(m.group(1), 16))
            names.append(cur)
    order = sorted(range(len(starts)), key=lambda i: starts[i])
    return [starts[i] for i in order], [names[i] for i in order]


def shares(path, starts, names):
    doc = json.load(open(os.path.join(CASE, path)))
    frames = doc['replay']['frames']
    total = frames * FRAME_T
    out = {}
    for z80, page, code, _cls, _count, tstates, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        if code == '76':
            key = 'HALT (waiting)'
        elif page == 261 or a < 0x4000:
            key = 'ROM'
        elif SOUND[0] <= a <= SOUND[1]:
            key = 'SoundLoop (foreground)'
        elif a >= 0xFC00:
            key = 'Im2Jump (FCFC)'
        elif a < starts[0]:
            key = 'below 8000'
        else:
            key = names[bisect_right(starts, a) - 1]
        out[key] = out.get(key, 0) + tstates
    return frames, total, out


def text(d, xy, s, size=13, fill=K.TEXT, anchor='la'):
    d.text(xy, s, font=K.font(size), fill=fill, anchor=anchor)


def heat(v):
    """A share 0..1 on a log scale from 0.001 % to 100 %: dark blue to yellow"""
    if v <= 0:
        return (32, 32, 38)
    x = max(0.0, min(1.0, (math.log10(v * 100) + 3) / 5))
    stops = [(0.0, (40, 40, 90)), (0.35, (70, 60, 170)), (0.6, (200, 70, 110)), (0.8, (240, 150, 60)),
             (1.0, (255, 240, 120))]
    for (x0, c0), (x1, c1) in zip(stops, stops[1:]):
        if x <= x1:
            f = (x - x0) / (x1 - x0)
            return tuple(int(c0[i] + (c1[i] - c0[i]) * f) for i in range(3))
    return stops[-1][1]


def cmd_modules(out_dir, data, starts, names):
    ran = sorted({k for _f, _t, sh in data.values() for k in sh if sh[k]})
    mods = [n for n in dict.fromkeys(names) if n in ran]
    rows = ['HALT (waiting)', 'SoundLoop (foreground)', 'ROM', 'Im2Jump (FCFC)'] + mods
    left, top, cw, rh = 180, 96, (WIDTH - 180 - 20) // len(BUILDS), 21
    img = Image.new('RGB', (WIDTH, top + rh * len(rows) + 70), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    text(d, (20, 10), 'The module heatmap: each module\'s share of the CPU\'s time, per recording (L1 builds)', 16)
    text(d, (20, 34), 'A cell is the T-states of the module\'s code over the recording\'s frames x 69 888 T, as a per '
         'cent; colour on a log scale.', 13, K.DIM)
    text(d, (20, 52), 'Dark grey: not executed. The modules that ran, in address order; the data-only modules are left out.',
         13, K.DIM)
    for c, (name, _p, _desc) in enumerate(BUILDS):
        frames = data[name][0]
        text(d, (left + c * cw + cw / 2, top - 24), name, 14, K.TEXT, 'mm')
        text(d, (left + c * cw + cw / 2, top - 8), f'{frames} fr', 11, K.DIM, 'mm')
    for r, row in enumerate(rows):
        y = top + r * rh
        text(d, (left - 8, y + rh / 2), row, 12, K.TEXT if r >= 4 else K.DIM, 'rm')
        for c, (name, _p, _desc) in enumerate(BUILDS):
            frames, total, sh = data[name]
            v = sh.get(row, 0) / total
            x = left + c * cw
            d.rectangle([x + 1, y + 1, x + cw - 2, y + rh - 2], fill=heat(v))
            if v > 0:
                s = f'{v * 100:.2f}' if v >= 0.0001 else '<0.01'
                bright = sum(heat(v)) > 450
                text(d, (x + cw / 2, y + rh / 2), s, 12, (20, 20, 20) if bright else K.TEXT, 'mm')
        if r == 3:
            d.line([20, y + rh + 1, WIDTH - 20, y + rh + 1], fill=K.DIM)
    y = top + rh * len(rows) + 12
    for i in range(6):
        v = 10 ** (i - 5)
        d.rectangle([left + i * 90, y, left + i * 90 + 30, y + 14], fill=heat(v))
        text(d, (left + i * 90 + 36, y), f'{v * 100:g} %', 12, K.DIM)
    text(d, (20, y + 26), 'python3 tools/fig_arch.py modules', 12, K.DIM)
    path = os.path.join(out_dir, 'modules.png')
    img.save(path)
    print(f'{path}: {img.width} x {img.height}')


GROUPS = [('HALT (waiting)', (70, 70, 80), lambda k: k == 'HALT (waiting)'),
          ('SoundLoop (foreground)', (90, 140, 220), lambda k: k == 'SoundLoop (foreground)'),
          ('drawing: balldraw, tabledraw, printing, hud', (90, 200, 210),
           lambda k: k in ('balldraw', 'tabledraw', 'printing', 'hud')),
          ('physics: physics, cushions, friction, shotsetup', (220, 90, 90),
           lambda k: k in ('physics', 'cushions', 'friction', 'shotsetup', 'balls', 'physicstables')),
          ('the interrupt: main, scheduler, Im2Jump', (230, 170, 70),
           lambda k: k in ('main', 'scheduler', 'Im2Jump (FCFC)')),
          ('play: shot, aim, input, tally, turns, racking, gameover', (120, 190, 120),
           lambda k: k in ('shot', 'aim', 'input', 'tally', 'turns', 'racking', 'gameover')),
          ('pages: presents, attract, signature, menu, halloffame, nameentry, editor', (200, 160, 230),
           lambda k: k in ('presents', 'attract', 'signature', 'menu', 'halloffame', 'nameentry', 'editor')),
          ('ROM', (240, 230, 120), lambda k: k == 'ROM')]


def cmd_budget(out_dir, data):
    left, top, bh = 70, 80, 34
    img = Image.new('RGB', (WIDTH, top + (bh + 14) * len(BUILDS) + 40 + 22 * len(GROUPS) + 30), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    text(d, (20, 10), 'The frame budget: one average frame of each recording, 69 888 T, split by what ran', 16)
    text(d, (20, 34), 'The whole recording\'s T-states by group, divided by its frames; the numbers are thousands of T '
         'a frame.', 13, K.DIM)
    width = WIDTH - left - 20
    for r, (name, _p, desc) in enumerate(BUILDS):
        frames, total, sh = data[name]
        y = top + r * (bh + 14)
        text(d, (left - 8, y + bh / 2), name, 14, K.TEXT, 'rm')
        x = left
        rest = dict(sh)
        for label, col, test in GROUPS:
            v = sum(t for k, t in sh.items() if test(k))
            for k in [k for k in rest if test(k)]:
                del rest[k]
            w = width * v / total
            if w <= 0:
                continue
            d.rectangle([x, y, x + w, y + bh], fill=col)
            per = v / frames / 1000
            if w > 34:
                text(d, (x + w / 2, y + bh / 2), f'{per:.1f}k', 12, (20, 20, 20), 'mm')
            x += w
        text(d, (left + 4, y + bh + 1), desc, 11, K.DIM)
        if rest and sum(rest.values()) / total > 0.001:
            print(name, 'unassigned', rest)
    y = top + len(BUILDS) * (bh + 14) + 16
    for label, col, _t in GROUPS:
        d.rectangle([left, y + 2, left + 14, y + 16], fill=col)
        text(d, (left + 22, y + 2), label, 12)
        y += 22
    text(d, (20, y + 6), 'python3 tools/fig_arch.py budget', 12, K.DIM)
    path = os.path.join(out_dir, 'budget.png')
    img.save(path)
    print(f'{path}: {img.width} x {img.height}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=('modules', 'budget', 'all'))
    ap.add_argument('--out-dir', default=os.path.join(CASE, 'docs', 'img', 'arch'))
    a = ap.parse_args()
    starts, names = modules()
    data = {name: shares(path, starts, names) for name, path, _d in BUILDS}
    if a.what in ('modules', 'all'):
        cmd_modules(a.out_dir, data, starts, names)
    if a.what in ('budget', 'all'):
        cmd_budget(a.out_dir, data)


if __name__ == '__main__':
    main()

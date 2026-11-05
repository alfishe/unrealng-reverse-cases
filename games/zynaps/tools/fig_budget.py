#!/usr/bin/env python3
"""Doc 02 figure: where the CPU's time goes over a whole recording, per routine, from an L1 build.

    python3 tools/fig_budget.py work/r1/l1.json docs/img/arch/budget.png [--top 24]

Each instruction of l1.json carries its count and its T-states summed over the recording (fields 5 and 6). The
T-states are summed per routine (the routine entry, "$ADDR c Name", at or before the address in src/game/game.ann;
labels inside a routine count for it) and shown as a share of all the recording's T-states (frames x 69888). A
bar's colour is the module the routine lives in (@module of game.ann). ROM time, if any, is one bar.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

import re
from bisect import bisect_right

ENTRY = re.compile(r'^\$([0-9A-F]{4}) c (\w+)')


def routines(ann):
    entries, module = [], '?'
    for line in open(ann, encoding='utf-8'):
        if line.startswith('@module '):
            module = line.split()[1]
        m = ENTRY.match(line)
        if m:
            entries.append((int(m.group(1), 16), m.group(2), module))
    entries.sort()
    return entries


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('l1')
    p.add_argument('out')
    p.add_argument('--top', type=int, default=24)
    p.add_argument('--ann', default=os.path.join(HERE, '..', 'src', 'game', 'game.ann'))
    p.add_argument('--title', default='r1, 75003 frames: where the CPU time goes, per routine')
    args = p.parse_args()
    doc = json.load(open(args.l1))
    entries = routines(args.ann)
    starts = [a for a, _, _ in entries]
    module_of = {n: m for _, n, m in entries}
    frames = doc['replay'].get('frames', 0)
    total = frames * 69888
    per = {}
    for z80, page, code, cls, count, tstates, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        i = bisect_right(starts, a) - 1
        name = 'ROM' if a < 0x4000 or i < 0 else entries[i][1]
        per[name] = per.get(name, 0) + tstates
    busy = sum(per.values())
    rows = sorted(per.items(), key=lambda kv: -kv[1])[:args.top]
    modules = []
    for name, _ in rows:
        m = module_of.get(name, 'ROM')
        if m not in modules:
            modules.append(m)
    palette = K.ROUTINE_COLOURS + [(255, 255, 255), (150, 110, 70), (90, 110, 200), (200, 200, 200)]
    colour_of = {m: palette[i % len(palette)] for i, m in enumerate(modules)}
    W, left, bar_h = 900, 200, 20
    top = 70
    H = top + len(rows) * (bar_h + 4) + 116
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb = K.font(12), K.font(15)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), f'share of all {total:,} T-states ({frames} frames x 69888); the top {len(rows)} routines '
                     f'cover {100 * sum(t for _, t in rows) / total:.1f}%', fill=K.DIM, font=f)
    peak = rows[0][1]
    scale = (W - left - 90) / peak
    for i, (name, t) in enumerate(rows):
        y = top + i * (bar_h + 4)
        colour = colour_of[module_of.get(name, 'ROM')]
        d.text((10, y + 3), name, fill=K.TEXT, font=f)
        d.rectangle((left, y, left + t * scale, y + bar_h), fill=colour)
        d.text((left + t * scale + 6, y + 3), f'{100 * t / total:.1f}%', fill=K.TEXT, font=f)
    y = top + len(rows) * (bar_h + 4) + 10
    x = 10
    d.text((x, y), 'module:', fill=K.DIM, font=f)
    x += 60
    for label in modules:
        c = colour_of[label]
        w = 26 + int(d.textlength(label, font=f)) + 12
        if x + w > W:
            x, y = 70, y + 18
        d.rectangle((x, y + 2, x + 14, y + 12), fill=c)
        d.text((x + 20, y), label, fill=K.TEXT, font=f)
        x += w
    d.text((10, y + 22), f'all instructions together: {busy:,} T = {100 * busy / total:.1f}% of the frames', fill=K.DIM, font=f)
    d.text((10, y + 38), "(no HALT in play: the main loop's time is EffectPlay's tone loop and PlayLoop)", fill=K.DIM,
           font=f)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)
    for name, t in rows:
        print(f'{name:24s} {module_of.get(name, "ROM"):12s} {100 * t / total:5.1f}%')


if __name__ == '__main__':
    main()

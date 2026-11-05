#!/usr/bin/env python3
"""Doc 02 figure: where the CPU's time goes over a whole recording, per routine, from an L1 build (copied from
../zynaps/tools/fig_budget.py; the 128K's parts added).

    python3 tools/fig_budget.py work/r1/l1.json docs/img/arch/budget.png [--top 24]

Each instruction of l1.json carries its page, its count and its T-states summed over the recording (fields 2, 5 and
6). The T-states are summed per routine (the routine entry, "$ADDR c Name", at or before the address in the .ann of
the part the instruction lies in: src/sound/engine.ann for page 4, src/game/glue.ann for $5B00-$5BFF, stubs.ann for
$B30D-$B3A8, mouse.ann for $FE00-$FEDC in page 0, else src/game/game.ann; labels inside a routine count for it) and
shown as a share of all the recording's T-states (frames x 71680, the Pentagon 128 frame). A bar's colour is the
module the routine lives in (@module of its .ann). ROM time, if any, is one bar.
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
    p.add_argument('--title', default='r1: where the CPU time goes, per routine')
    args = p.parse_args()
    doc = json.load(open(args.l1))
    src = os.path.join(HERE, '..', 'src')
    parts = {k: routines(os.path.join(src, *v)) for k, v in
             (('game', ('game', 'game.ann')), ('engine', ('sound', 'engine.ann')), ('glue', ('game', 'glue.ann')),
              ('stubs', ('game', 'stubs.ann')), ('mouse', ('game', 'mouse.ann')))}
    module_of = {}
    for k, entries in parts.items():
        for _, n, m in entries:
            module_of[n] = m if k == 'game' else f'{k} ({m})'
    starts = {k: [a for a, _, _ in e] for k, e in parts.items()}
    frames = doc['replay'].get('frames', 0)
    total = frames * 71680
    per, part_t = {}, {}
    for z80, page, code, cls, count, tstates, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        if a < 0x4000:
            per['ROM'] = per.get('ROM', 0) + tstates
            continue
        k = ('engine' if page == 4 else 'glue' if 0x5B00 <= a < 0x5C00 else 'stubs' if 0xB30D <= a <= 0xB3A8
             else 'mouse' if 0xFE00 <= a <= 0xFEDC and page == 0 else 'game')
        i = bisect_right(starts[k], a) - 1
        name = parts[k][i][1] if i >= 0 else f'${a:04X}'
        per[name] = per.get(name, 0) + tstates
        part_t[k] = part_t.get(k, 0) + tstates
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
    H = top + len(rows) * (bar_h + 4) + 134
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb = K.font(12), K.font(15)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), f'share of all {total:,} T-states ({frames} frames x 71680); the top {len(rows)} routines '
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
    d.text((10, y + 38), "(no HALT in play: the main loop's time is EventDispatch called over and over by PlayLoop)",
           fill=K.DIM, font=f)
    d.text((10, y + 56), 'by part: ' + ', '.join(f'{k} {100 * v / total:.2f}%' for k, v in
                                                 sorted(part_t.items(), key=lambda kv: -kv[1])) +
           ' (engine = page 4, glue = $5B00, stubs = $B30D-$B3A8)', fill=K.DIM, font=f)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)
    for name, t in rows:
        print(f'{name:24s} {module_of.get(name, "ROM"):12s} {100 * t / total:5.1f}%')


if __name__ == '__main__':
    main()

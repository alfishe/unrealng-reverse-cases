#!/usr/bin/env python3
"""The module map of the game image `$6D42-$FFFF`, drawn from src/game/game.ann (doc 2): every byte coloured by the
module that holds it, code full, data hatched; and the table of modules (stretches, code and data bytes, entries).

A module runs as kit/mkgame.py cuts the source: an entry belongs to the @module last named before it in the .ann, and
it runs to the next entry's address (the last one to `$FFFF`). Code is an entry of kind c, data every other kind
(b, w, t, s).

    python3 tools/fig_modules.py --out docs/img/arch/modules.png [--table work/docs/esA/modules.md]
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

COLOURS = {
    'renderer': (235, 90, 80), 'cells': (90, 200, 120), 'music': (90, 140, 250), 'effects': (200, 110, 230),
    'menu': (70, 210, 220), 'keys': (250, 150, 60), 'main': (170, 220, 80), 'hud': (235, 120, 180),
    'player': (150, 150, 255), 'mapscreen': (210, 180, 120), 'unpack': (120, 240, 200), 'password': (245, 245, 245),
    'hiscore': (160, 110, 70), 'cavedata': (250, 220, 60),
}


def entries(ann):
    module, out = None, []
    for line in open(ann):
        m = re.match(r'^@module (\w+)', line)
        if m:
            module = m.group(1)
            continue
        m = re.match(r'^\$([0-9A-F]{4}) ([a-z]) (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2), m.group(3), module))
    out.sort()
    spans = []
    for i, (a, kind, name, mod) in enumerate(out):
        end = out[i + 1][0] if i + 1 < len(out) else 0x10000
        spans.append((a, end, kind, name, mod))
    return spans


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--table')
    ap.add_argument('--width', type=int, default=1050)
    a = ap.parse_args()
    spans = entries(os.path.join(CASE, 'src/game/game.ann'))
    owner = {}
    for lo, hi, kind, name, mod in spans:
        for x in range(lo, hi):
            owner[x] = (mod, kind)
    per_row = 512
    first_row = 0x6C00
    rows = (0x10000 - first_row) // per_row
    left, top, px, rh = 64, 56, 1.75, 9
    W = a.width
    legend_h = 4 * 22 + 70
    H = top + rows * (rh + 1) + legend_h
    img = Image.new('RGB', (W, H), (22, 22, 28))
    d = ImageDraw.Draw(img)
    fb, f, fs = K.font(15), K.font(12), K.font(11)
    d.text((left, 12), 'The module map: 14 modules over the image $6D42-$FFFF, each in several stretches',
           fill=(235, 235, 235), font=fb)
    d.text((left, 32), 'one row = 512 bytes; full colour = code (c entries), hatched = data (b, w, t, s entries); '
           'dark = not in the image', fill=(180, 180, 180), font=fs)
    for r in range(rows):
        base = first_row + r * per_row
        y = top + r * (rh + 1)
        if base % 0x800 == 0:
            d.text((6, y - 2), '$%04X' % base, fill=(190, 190, 190), font=fs)
        for i in range(per_row):
            x = left + i * px
            o = owner.get(base + i)
            if not o:
                d.rectangle([x, y, x + px, y + rh - 1], fill=(40, 40, 46))
                continue
            mod, kind = o
            c = COLOURS.get(mod, (128, 128, 128))
            if kind == 'c':
                d.rectangle([x, y, x + px, y + rh - 1], fill=c)
            else:
                dark = tuple(v // 3 for v in c)
                d.rectangle([x, y, x + px, y + rh - 1], fill=dark)
                if i % 3 == 0:
                    d.line([x, y, x, y + rh - 1], fill=c)
    # module totals
    tot = {}
    stretches = {}
    prev = None
    for lo, hi, kind, name, mod in spans:
        t = tot.setdefault(mod, [0, 0, 0])
        t[0 if kind == 'c' else 1] += hi - lo
        t[2] += 1
        if prev and prev[1] == mod and prev[0] == lo:
            stretches[mod][-1][1] = hi
        else:
            stretches.setdefault(mod, []).append([lo, hi])
        prev = (hi, mod)
    y = top + rows * (rh + 1) + 12
    colw = (W - left - 10) // 4
    order = sorted(tot, key=lambda m: -(tot[m][0] + tot[m][1]))
    for j, mod in enumerate(order):
        x, yy = left + (j % 4) * colw, y + (j // 4) * 22
        d.rectangle([x, yy + 2, x + 14, yy + 14], fill=COLOURS.get(mod, (128, 128, 128)))
        d.text((x + 20, yy), '%s %d + %d bytes' % (mod, tot[mod][0], tot[mod][1]), fill=(220, 220, 220), font=fs)
    d.text((left, y + 4 * 22 + 4), 'legend: module, code bytes + data bytes. Command: python3 tools/fig_modules.py '
           '--out docs/img/arch/modules.png (from src/game/game.ann)', fill=(160, 160, 160), font=fs)
    img.save(a.out)
    lines = ['| Module | Stretches | Code bytes | Data bytes | Entries |', '| --- | --- | --- | --- | --- |']
    for mod in order:
        s = ', '.join('`$%04X-$%04X`' % (lo, hi - 1) for lo, hi in stretches[mod])
        lines.append('| %s | %s | %d | %d | %d |' % (mod, s, tot[mod][0], tot[mod][1], tot[mod][2]))
    text = '\n'.join(lines) + '\n'
    if a.table:
        open(a.table, 'w').write(text)
    print(text)


if __name__ == '__main__':
    main()

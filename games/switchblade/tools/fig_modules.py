#!/usr/bin/env python3
"""The module map: every byte of the game's image `$5C00-$FFFF` coloured by the `@module` of the `.ann` entry that
holds it (an entry runs to the next entry), 256 bytes a row; the run-time regions that are not in the image
(the actor pages, the cell planes, the stack, the IM 2 table) are named on the right. Prints the table of modules:
their ranges, bytes and entries.

    python3 tools/fig_modules.py src/game/game.ann docs/img/arch/modules.png
"""
import re
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

ENTRY = re.compile(r'^\$([0-9A-F]{4}) ([cbwstu]) (\S+)')
RUNTIME = [  # (lo, hi, text): what the game keeps there at run time
    (0x5B00, 0x5BFF, 'stack $5BBA-$5BFF, ColumnValues $5B50, RoomObjectList $5B01'),
    (0x5D00, 0x65FF, 'run time: nine actor pages, Hiro $5D00 (tails +$82-$FF: tables)'),
    (0x6600, 0x66FF, 'run time: weapon page $6600, globals $6642-$667F, code $6682'),
    (0x6700, 0x6CFF, 'run time: the six cell planes $67-$6C'),
    (0x6D00, 0x6EFF, 'run time: kept room states $6D00, $6E00'),
    (0x6F00, 0x704F, 'run time: OutlineMask $6F00, RowBase, NameBoxPlaces'),
    (0xFDFD, 0xFF00, 'JP $8456 at $FDFD, IM 2 table $FE00-$FF00'),
]


def main():
    ann, out = sys.argv[1], sys.argv[2]
    mod = None
    entries = []
    for line in open(ann, encoding='utf-8'):
        if line.startswith('@module'):
            mod = line.split()[1]
        m = ENTRY.match(line)
        if m:
            entries.append((int(m.group(1), 16), m.group(2), m.group(3), mod))
    entries.sort()
    owner = {}
    stats = {}
    for k, (a, kind, name, m) in enumerate(entries):
        z = entries[k + 1][0] if k + 1 < len(entries) else 0x10000
        for b in range(a, z):
            owner[b] = m
        s = stats.setdefault(m, {'bytes': 0, 'c': 0, 'data': 0, 'ranges': []})
        s['bytes'] += z - a
        s['c' if kind == 'c' else 'data'] += 1
        if s['ranges'] and s['ranges'][-1][1] == a:
            s['ranges'][-1][1] = z
        else:
            s['ranges'].append([a, z])
    names = sorted(stats, key=lambda m: min(r[0] for r in stats[m]['ranges']))
    colours = {m: K.ROUTINE_COLOURS[i % len(K.ROUTINE_COLOURS)] for i, m in enumerate(names)}
    lo, hi = 0x5B00, 0x10000
    cell, rh = 3, 4
    rows = (hi - lo) // 256
    W = 1050
    gx, gy = 60, 40
    H = gy + rows * rh + 40 + 15 * len(RUNTIME) + 18 * ((len(names) + 3) // 4) + 10
    img = Image.new('RGB', (W, H), (16, 16, 20))
    d = ImageDraw.Draw(img)
    f, fs = K.font(12), K.font(11)
    d.text((10, 8), 'The module map: each byte of the game $5C00-$FFFF by its source module; R1-R7 what the regions hold at run time',
           fill='white', font=K.font(14))
    for r in range(rows):
        for c in range(256):
            a = lo + r * 256 + c
            col = colours[owner[a]] if a in owner else (40, 40, 48)
            x, y = gx + c * cell, gy + r * rh
            d.rectangle([x, y, x + cell - 1, y + rh - 1], fill=col)
        if (lo + r * 256) % 0x1000 == 0:
            d.text((6, gy + r * rh - 5), f'${lo + r * 256:04X}', fill=(180, 180, 180), font=fs)
            d.line([gx - 4, gy + r * rh, gx - 1, gy + r * rh], fill=(180, 180, 180))
    rx = gx + 256 * cell + 8
    for k, (a, z, t) in enumerate(RUNTIME):
        y0, y1 = gy + (a - lo) // 256 * rh, gy + (z - lo) // 256 * rh + rh - 1
        d.line([rx, y0, rx, y1], fill=(230, 230, 230), width=2)
        d.text((rx + 6 + 16 * (k % 2), (y0 + y1) // 2 - 7), f'R{k + 1}', fill=(230, 230, 230), font=f)
    ly = gy + rows * rh + 14
    for k, (a, z, s) in enumerate(RUNTIME):
        d.text((10, ly), f'R{k + 1} ${a:04X}-${z:04X}: {s}', fill=(220, 220, 220), font=fs)
        ly += 15
    ly += 8
    for i, m in enumerate(names):
        x, y = 10 + (i % 4) * 260, ly + 18 * (i // 4)
        d.rectangle([x, y + 2, x + 12, y + 12], fill=colours[m])
        d.text((x + 18, y), f'{m}: {stats[m]["bytes"]} bytes', fill='white', font=f)
    img.save(out)
    print(out, img.size)
    print('| Module | Bytes | Code entries | Data entries | Ranges |')
    print('| --- | ---: | ---: | ---: | --- |')
    for m in names:
        s = stats[m]
        rs = ', '.join(f'`${a:04X}-${z - 1:04X}`' for a, z in s['ranges'])
        print(f'| {m} | {s["bytes"]} | {s["c"]} | {s["data"]} | {rs} |')


if __name__ == '__main__':
    main()

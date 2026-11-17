#!/usr/bin/env python3
"""The graphics a draw routine was given, from its L1 `patterns`: the bases each pattern of the routine went through
(HL's, IX's: the addresses its loads walked from), and a first sprite sheet drawn from an image at those bases.

    python3 kit/pattern_sheet.py --routine ADDR [--routine ADDR ...] L1 [L1 ...] [--image IMAGE] [--out OUT.png]
                                 [--reg HL] [--reads | --writes]
                                 [--width-at 0 --height-at 1 --data-at 2 | --size WxH [--data-at 0]]
                                 [--max-width 8] [--max-height 96] [--scale 2] [--sheet 1050] [--json OUT]

Bases: every L1's patterns whose routine has one of the --routine entries (hex), all their `bases` (--reg keeps the
patterns of that base register; --reads / --writes those that read / write through it), merged and sorted; printed
one a line with the routines, registers and L1s that gave them. With --image (an SZX or a 64 K / 48 K dump,
kitlib.memory_image) and --out, each base is read as a graphic: a header holds its width in bytes at +width-at and
its height in lines at +height-at, the pixels start at +data-at, width x height bytes a line at a time, bit 7 left;
or --size WxH gives every graphic that size (no header, the pixels at +data-at). A base whose header gives a width
outside 1..max-width or a height outside 1..max-height is no graphic and is left out (said in the summary). Each
graphic is drawn at --scale with its address above it, in rows --sheet pixels wide. The header bytes before the
pixels are printed beside each base (`flags`, the shift: whatever the case's format keeps there).

ATV Simulator: `--routine 865F --width-at 0 --height-at 1 --data-at 4` (the sprite entry, HL's bases), the image as
the loader leaves it: docs/img/sprites/sprites-stage1.png (tools/sprite_sheet.py).
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib  # noqa: E402

BACK, LABEL, FRAME, INK = (24, 24, 32), (230, 220, 120), (70, 70, 90), (255, 255, 255)


def pattern_bases(docs, routines, reg=None, reads=None, writes=None):
    """{base: {'routines', 'regs', 'l1s'}} of the patterns of @p routines (entry addresses) in @p docs [(name, L1)]"""
    out = {}
    for name, d in docs:
        index = {kitlib.hex_address(r['entry']): i for i, r in enumerate(d['routines'])}
        wanted = {index[a]: a for a in routines if a in index}
        for p in d.get('patterns', ()):
            if p['routine'] not in wanted:
                continue
            if reg and p.get('base', '').upper() != reg.upper():
                continue
            if reads and not p.get('reads') or writes and not p.get('writes'):
                continue
            for b in p.get('bases', ()):
                got = out.setdefault(kitlib.hex_address(b), {'routines': set(), 'regs': set(), 'l1s': set()})
                got['routines'].add(wanted[p['routine']])
                got['regs'].add(p.get('base', '?'))
                got['l1s'].add(name)
    return out


def graphics(img, bases, a):
    """[(base, width, height, data offset)] that read as graphics, and the bases left out"""
    keep, out = [], []
    for base in sorted(bases):
        if a.size:
            w, h = a.size
        else:
            w, h = img[(base + a.width_at) & 0xFFFF], img[(base + a.height_at) & 0xFFFF]
        if 1 <= w <= a.max_width and 1 <= h <= a.max_height and base + a.data_at + w * h <= 0x10000:
            keep.append((base, w, h))
        else:
            out.append(base)
    return keep, out


def draw(img, items, a):
    S, PAD, W = a.scale, 10, a.sheet
    font = kitlib.font(13)
    x = y = PAD
    row_h = 0
    places = []
    for base, w, h in items:
        cw, ch = max(w * 8 * S, 52), h * S + 18
        if x + cw > W - PAD:
            x, y = PAD, y + row_h + PAD
            row_h = 0
        places.append((base, w, h, x, y))
        x += cw + PAD
        row_h = max(row_h, ch)
    im = Image.new('RGB', (W, y + row_h + PAD), BACK)
    dr = ImageDraw.Draw(im)
    for base, w, h, x, y in places:
        dr.text((x, y), f'${base:04X}', fill=LABEL, font=font)
        dr.rectangle([x - 1, y + 17, x + w * 8 * S, y + 18 + h * S], outline=FRAME)
        for r in range(h):
            for k in range(w):
                v = img[base + a.data_at + r * w + k]
                for b in range(8):
                    if v & (0x80 >> b):
                        px, py = x + (k * 8 + b) * S, y + 18 + r * S
                        dr.rectangle([px, py, px + S - 1, py + S - 1], fill=INK)
    return im


def size_arg(text):
    w, _, h = text.lower().partition('x')
    return int(w), int(h)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('l1', nargs='+')
    ap.add_argument('--routine', action='append', required=True, type=kitlib.hex_address,
                    help='the draw routine\'s entry (hex), repeatable')
    ap.add_argument('--reg', help='only the patterns of this base register (HL, IX, ...)')
    ap.add_argument('--reads', action='store_true')
    ap.add_argument('--writes', action='store_true')
    ap.add_argument('--image', help='the memory to draw from (SZX, 64 K or 48 K dump)')
    ap.add_argument('--out', help='the sheet (PNG); needs --image')
    ap.add_argument('--width-at', type=int, default=0)
    ap.add_argument('--height-at', type=int, default=1)
    ap.add_argument('--data-at', type=int)
    ap.add_argument('--size', type=size_arg, help='WxH: every graphic W bytes by H lines, no header')
    ap.add_argument('--max-width', type=int, default=8)
    ap.add_argument('--max-height', type=int, default=96)
    ap.add_argument('--scale', type=int, default=2)
    ap.add_argument('--sheet', type=int, default=1050, help='the sheet\'s width in pixels')
    ap.add_argument('--json')
    a = ap.parse_args(argv)
    if a.data_at is None:
        a.data_at = 0 if a.size else 2
    docs = []
    for path in a.l1:
        with open(path) as f:
            docs.append((os.path.basename(os.path.dirname(os.path.abspath(path))) or path, json.load(f)))
    bases = pattern_bases(docs, a.routine, a.reg, a.reads, a.writes)
    if not bases:
        sys.exit('pattern_sheet.py: no pattern of ' + ', '.join(f'${r:04X}' for r in a.routine) + ' in these L1s')
    img = kitlib.memory_image(a.image) if a.image else None
    keep, left = graphics(img, bases, a) if img is not None else ([], [])
    shapes = {b: (w, h) for b, w, h in keep}
    rows = []
    for base in sorted(bases):
        g = bases[base]
        row = {'base': base, 'routines': sorted(g['routines']), 'regs': sorted(g['regs']), 'l1s': sorted(g['l1s'])}
        text = f'${base:04X}  ' + ', '.join(f'${r:04X}' for r in row['routines']) + ' ' + '/'.join(row['regs']) + \
            '  ' + ', '.join(row['l1s'])
        if img is not None:
            if base in shapes:
                w, h = shapes[base]
                head = img[base:base + a.data_at] if a.data_at else b''
                row.update(width=w, height=h, header=head.hex().upper())
                text += f'  {w}x{h}' + (f' header {head.hex(" ").upper()}' if head else '')
            else:
                row['graphic'] = False
                text += '  no graphic'
        rows.append(row)
        print(text)
    if a.out:
        if img is None:
            sys.exit('pattern_sheet.py: --out needs --image')
        im = draw(img, keep, a)
        im.save(a.out)
        print(f'{a.out}: {len(keep)} graphics of {len(bases)} bases ({len(left)} no graphic); {im.size}')
    else:
        print(f'{len(bases)} bases' + (f', {len(keep)} graphics' if img is not None else ''))
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(rows, f, indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())

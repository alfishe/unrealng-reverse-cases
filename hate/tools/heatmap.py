#!/usr/bin/env python3
"""Memory heatmaps from an unreal-ng L1 build (l1.json): what the program executed, read and wrote, per byte.

The 64 K address space is a 256 x 256 grid, one row per 256 bytes ($0000 at the top left, $FFFF at the bottom
right), each byte a CELL x CELL square. Intensity is log2 of the count. Panels: executions (the instructions'
counts over their bytes), data reads, data writes, and a composite (red write, green read, blue execute).

    python3 heatmap.py l1.json out.png [--cell 3] [--from 4000] [--to FFFF] [--regions regions.txt] [--title T]
    python3 heatmap.py l1.json out.png --frames           # when each byte was last touched instead of how often

regions.txt: lines "START END NAME" (hex), drawn as labelled brackets to the right of the composite.
"""
import argparse
import json
import math

from PIL import Image, ImageDraw, ImageFont

# Physical page -> Z80 base on a 48K machine (the pages L1 names RAM 5, RAM 2, RAM 0 and ROM 0)
BASES_48K = {5: 0x4000, 2: 0x8000, 0: 0xC000, 261: 0x0000}


def load(path, bases):
    doc = json.load(open(path))
    executes = [0] * 0x10000
    for z80, page, code, _cls, count, *_ in doc['instructions']:
        address = int(z80[1:], 16)
        for i in range(len(code) // 2):
            executes[(address + i) & 0xFFFF] += count
    reads, writes, last = [0] * 0x10000, [0] * 0x10000, [0] * 0x10000
    for page in doc.get('byte_counts', []):
        base = bases.get(page['page'])
        if base is None:
            continue
        for i in range(0x4000):
            reads[base + i] = page['reads'][i]
            writes[base + i] = page['writes'][i]
            last[base + i] = page['last_frame'][i]
    if not doc.get('byte_counts'):
        raise SystemExit('l1.json has no byte_counts: build it with an unreal-ng that exports them')
    return executes, reads, writes, last, doc['replay']


def scale(values, lo, hi):
    top = max((values[a] for a in range(lo, hi + 1)), default=0)
    norm = math.log2(top + 1) if top else 1.0
    return lambda a: math.log2(values[a] + 1) / norm if values[a] else 0.0, top


GRADIENT = [(0, 0, 0), (48, 18, 96), (150, 30, 110), (230, 90, 50), (250, 200, 60), (255, 255, 230)]


def heat(x):
    if x <= 0:
        return (12, 12, 16)
    x = min(1.0, x) * (len(GRADIENT) - 1)
    i = min(int(x), len(GRADIENT) - 2)
    f = x - i
    a, b = GRADIENT[i], GRADIENT[i + 1]
    return tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3))


def panel(lo, hi, cell, colour):
    rows = (hi - lo) // 256 + 1
    image = Image.new('RGB', (256 * cell, rows * cell), (12, 12, 16))
    pixels = image.load()
    for a in range(lo, hi + 1):
        c = colour(a)
        x, y = (a & 0xFF) * cell, ((a - lo) >> 8) * cell
        for dy in range(cell):
            for dx in range(cell):
                pixels[x + dx, y + dy] = c
    return image


def main():
    p = argparse.ArgumentParser()
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--cell', type=int, default=3)
    p.add_argument('--from', dest='lo', default='4000')
    p.add_argument('--to', dest='hi', default='FFFF')
    p.add_argument('--regions')
    p.add_argument('--title', default='')
    p.add_argument('--frames', action='store_true')
    args = p.parse_args()
    lo, hi = int(args.lo, 16) & 0xFF00, int(args.hi, 16) | 0xFF
    executes, reads, writes, last, replay = load(args.l1, BASES_48K)
    font = ImageFont.load_default()
    if args.frames:
        frames = max(1, replay['frames'])
        panels = [('last touched (frame of the window)', panel(lo, hi, args.cell,
                   lambda a: heat(last[a] / frames) if (reads[a] or writes[a] or executes[a]) else (12, 12, 16)),
                   f"0 .. {frames} frames")]
    else:
        fx, tx = scale(executes, lo, hi)
        fr, tr = scale(reads, lo, hi)
        fw, tw = scale(writes, lo, hi)
        composite = panel(lo, hi, args.cell, lambda a: (int(255 * fw(a)), int(255 * fr(a)), int(255 * fx(a))))
        panels = [('executed', panel(lo, hi, args.cell, lambda a: heat(fx(a))), f'max {tx}'),
                  ('read', panel(lo, hi, args.cell, lambda a: heat(fr(a))), f'max {tr}'),
                  ('written', panel(lo, hi, args.cell, lambda a: heat(fw(a))), f'max {tw}'),
                  ('red write, green read, blue execute', composite, 'log2 scale')]
    margin, gap, label_w = 52, 18, 190 if args.regions else 0
    w = margin + sum(im.width for _, im, _ in panels) + gap * (len(panels) - 1) + label_w + 12
    h = 46 + panels[0][1].height + 26
    out = Image.new('RGB', (w, h), (24, 24, 30))
    d = ImageDraw.Draw(out)
    d.text((margin, 6), args.title or f'Memory ${lo:04X}-${hi:04X}, {replay["frames"]} frames, '
           f'{replay["instructions"]} instructions', fill=(235, 235, 235), font=font)
    x = margin
    for name, im, note in panels:
        out.paste(im, (x, 30))
        d.text((x, 18), name, fill=(200, 200, 210), font=font)
        d.text((x, 32 + im.height + 4), note, fill=(150, 150, 160), font=font)
        x += im.width + gap
    for a in range(lo, hi + 1, 0x1000):
        y = 30 + ((a - lo) >> 8) * args.cell
        d.text((6, y - 4), f'${a:04X}', fill=(170, 170, 180), font=font)
        d.line([(margin - 6, y), (margin - 2, y)], fill=(120, 120, 130))
    if args.regions:
        rx = x - gap + 6
        for line in open(args.regions):
            parts = line.split(None, 2)
            if len(parts) < 3 or line.startswith('#'):
                continue
            a, b = int(parts[0], 16), int(parts[1], 16)
            if b < lo or a > hi:
                continue
            y0 = 30 + ((max(a, lo) - lo) >> 8) * args.cell
            y1 = 30 + ((min(b, hi) - lo) >> 8) * args.cell + args.cell - 1
            d.line([(rx, y0), (rx + 4, y0), (rx + 4, y1), (rx, y1)], fill=(200, 200, 120))
            d.text((rx + 8, (y0 + y1) // 2 - 5), parts[2].strip(), fill=(220, 220, 160), font=font)
    out.save(args.png)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Memory heatmaps from an unreal-ng L1 build (l1.json): what the program executed, read and wrote, per byte.

The 64 K address space is a 256 x 256 grid, one row per 256 bytes ($0000 at the top left, $FFFF at the bottom
right), each byte a CELL x CELL square. Intensity is log2 of the count. Panels: executions (the instructions'
counts over their bytes), data reads, data writes, and a composite (red write, green read, blue execute).

    python3 heatmap.py l1.json out.png [--cell 3] [--from 4000] [--to FFFF] [--regions regions.txt] [--title T]
                       [--panels executed,read,written,composite] [--columns 2]
    python3 heatmap.py l1.json out.png --frames           # when each byte was last touched instead of how often

regions.txt: lines "START END NAME" (hex), drawn as labelled brackets to the right of the last panel of each row
(labels that would overlap are pushed apart and joined to their bracket by a leader).

--panels picks the panels and their order (default all four), --columns how many go in a row (default 2: the four
panels as two rows of two). The text is TrueType, 13 px in a picture up to 1050 px wide and larger in proportion in a
wider one, so that it reads at about 11 px or more when the figure is shown 900 px wide (GUIDE.md 4.3): at --cell 2
the four panels are one figure of about 1300 px.

When the range holds the screen page ($4000-$5AFF), each panel gets an inset below it: the same counts in the
screen's geometry, the bitmap bytes where they show and the attributes as their cells.
"""
import argparse
import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402
from routine_anim import wrap  # noqa: E402

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


def screen_view(colour, scale, font=None):
    """The screen page in the screen's own geometry: each bitmap byte of $4000-$57FF as 8 x 1 pixels where it shows,
    and beside it each attribute of $5800-$5AFF as its 8 x 8 cell (at half size), coloured by colour(address)"""
    bitmap = Image.new('RGB', (256 * scale, 192 * scale), (12, 12, 16))
    d = ImageDraw.Draw(bitmap)
    for a in range(0x4000, 0x5800):
        y = ((a >> 8) & 7) | ((a >> 2) & 0x38) | ((a >> 5) & 0xC0)
        x = (a & 31) * 8
        d.rectangle((x * scale, y * scale, (x + 8) * scale - 1, (y + 1) * scale - 1), fill=colour(a))
    cell = 4 * scale
    attrs = Image.new('RGB', (32 * cell, 24 * cell), (12, 12, 16))
    d = ImageDraw.Draw(attrs)
    for a in range(0x5800, 0x5B00):
        x, y = (a - 0x5800) & 31, (a - 0x5800) >> 5
        d.rectangle((x * cell, y * cell, (x + 1) * cell - 2, (y + 1) * cell - 2), fill=colour(a))
    font = font or K.font(15)
    out = Image.new('RGB', (bitmap.width + 10 + attrs.width + 4, bitmap.height + 4), (24, 24, 30))
    d = ImageDraw.Draw(out)
    d.rectangle((0, 0, bitmap.width + 3, bitmap.height + 3), outline=(110, 110, 140))
    d.rectangle((bitmap.width + 8, 0, bitmap.width + 11 + attrs.width, attrs.height + 3), outline=(110, 110, 140))
    out.paste(bitmap, (2, 2))
    out.paste(attrs, (bitmap.width + 10, 2))
    d.text((bitmap.width + 10, attrs.height + 8), 'attributes', fill=(150, 150, 170), font=font)
    return out


PANELS = ('executed', 'read', 'written', 'composite')


def spread(wanted, step, top):
    """label tops in order, each at least step below the one before and none above top, every run of touching labels
    centred on its labels' wanted places as far as its neighbours allow"""
    groups = []  # [first index, last index, y of the first]
    for i, y in enumerate(wanted):
        groups.append([i, i, max(y, top)])
        while len(groups) > 1:
            a, b = groups[-2], groups[-1]
            if a[2] + step * (a[1] - a[0] + 1) <= b[2]:
                break
            first, last = a[0], b[1]
            centred = sum(wanted[first:last + 1]) / (last - first + 1) - step * (last - first) / 2
            groups[-2:] = [[first, last, max(top, round(centred))]]
    out = []
    for first, last, y in groups:
        out += [y + step * k for k in range(last - first + 1)]
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--cell', type=int, default=3)
    p.add_argument('--from', dest='lo', default='4000')
    p.add_argument('--to', dest='hi', default='FFFF')
    p.add_argument('--regions')
    p.add_argument('--title', default='')
    p.add_argument('--frames', action='store_true')
    p.add_argument('--panels', default=','.join(PANELS), help='which panels, in order: ' + ', '.join(PANELS))
    p.add_argument('--columns', type=int, default=2, help='panels in a row (2)')
    args = p.parse_args()
    lo, hi = int(args.lo, 16) & 0xFF00, int(args.hi, 16) | 0xFF
    executes, reads, writes, last, replay = load(args.l1, BASES_48K)
    if args.frames:
        frames = max(1, replay['frames'])
        colour = lambda a: heat(last[a] / frames) if (reads[a] or writes[a] or executes[a]) else (12, 12, 16)  # noqa
        panels = [('last touched (frame of the window)', colour, f"0 .. {frames} frames")]
    else:
        fx, tx = scale(executes, lo, hi)
        fr, tr = scale(reads, lo, hi)
        fw, tw = scale(writes, lo, hi)
        every = {'executed': ('executed', lambda a: heat(fx(a)), f'max {tx}'),
                 'read': ('read', lambda a: heat(fr(a)), f'max {tr}'),
                 'written': ('written', lambda a: heat(fw(a)), f'max {tw}'),
                 'composite': ('red write, green read, blue execute',
                               lambda a: (int(255 * fw(a)), int(255 * fr(a)), int(255 * fx(a))), 'log2 scale')}
        names = [n.strip() for n in args.panels.split(',') if n.strip()]
        unknown = [n for n in names if n not in every]
        if unknown or not names:
            sys.exit(f'--panels: {", ".join(unknown) or "none"}; choose from {", ".join(PANELS)}')
        panels = [every[n] for n in names]
    grids = [panel(lo, hi, args.cell, c) for _, c, _ in panels]
    screen = lo <= 0x4000 and hi >= 0x5AFF
    columns = max(1, min(args.columns, len(panels)))
    rows = [list(range(i, min(i + columns, len(panels)))) for i in range(0, len(panels), columns)]
    inset_w = 384 * max(1, args.cell // 2) + 14 if screen else 0  # screen_view's width
    slot_w = max(max(g.width for g in grids), inset_w)
    regions = []
    if args.regions:
        for line in open(args.regions):
            parts = line.split(None, 2)
            if len(parts) < 3 or line.startswith('#'):
                continue
            a, b = int(parts[0], 16), int(parts[1], 16)
            if b >= lo and a <= hi:
                regions.append((a, b, parts[2].strip()))

    def layout(size):
        """the picture's width and the fonts for a text size"""
        font, big = K.font(size), K.font(size + 3)
        label_w = (max(int(font.getlength(n)) for _, _, n in regions) + 24) if regions else 0
        margin = int(font.getlength('$FFFF')) + 14
        width = margin + columns * slot_w + 18 * (columns - 1) + label_w + 12
        return width, font, big, margin

    size = 13
    width = layout(size)[0]
    if width > 1050:
        size = math.ceil(13 * width / 1050)
        width = layout(size)[0]
        size = math.ceil(13 * width / 1050)
    width, font, big, margin = layout(size)
    lh = size + 6
    gap = 18
    # The screen page in view: each panel gets an inset below it with the same colours in the screen's geometry
    insets = [screen_view(c, max(1, args.cell // 2), font) for _, c, _ in panels] if screen else []
    inset_text = wrap('$4000-$57FF as the screen, $5800-$5AFF as its cells', font, slot_w) if screen else []
    inset_h = insets[0].height + lh * (len(inset_text) + 1) + 8 if insets else 0
    title = args.title or f'Memory ${lo:04X}-${hi:04X}, {replay["frames"]} frames, {replay["instructions"]} instructions'
    title_lines = wrap(title, big, width - margin - 12)
    top = 8 + (size + 9) * len(title_lines) + 6
    row_h = lh + grids[0].height + lh + 8 + inset_h + gap
    height = top + row_h * len(rows)
    out = Image.new('RGB', (width, height), (24, 24, 30))
    d = ImageDraw.Draw(out)
    for i, line in enumerate(title_lines):
        d.text((margin, 8 + (size + 9) * i), line, fill=(235, 235, 235), font=big)
    for r, members in enumerate(rows):
        y0 = top + r * row_h
        gy = y0 + lh
        x = margin
        for i in members:
            name, _, note = panels[i]
            im = grids[i]
            out.paste(im, (x, gy))
            d.text((x, y0), name, fill=(200, 200, 210), font=font)
            d.text((x, gy + im.height + 4), note, fill=(150, 150, 160), font=font)
            if insets:
                iy = gy + im.height + lh + 8
                # a leader from the screen rows of the grid down to the inset
                sy = gy + ((0x4000 - lo) >> 8) * args.cell
                ty = iy + lh * len(inset_text) + 2
                d.line([(x - 4, sy), (x - 8, sy), (x - 8, ty), (x - 2, ty)], fill=(140, 140, 170))
                for k, text in enumerate(inset_text):
                    d.text((x, iy + lh * k), text, fill=(170, 170, 200), font=font)
                out.paste(insets[i], (x, ty))
            x += slot_w + gap
        for a in range(lo, hi + 1, 0x1000):
            y = gy + ((a - lo) >> 8) * args.cell
            d.text((4, y - size // 2 - 1), f'${a:04X}', fill=(170, 170, 180), font=font)
            d.line([(margin - 8, y), (margin - 3, y)], fill=(120, 120, 130))
        if regions:
            rx = margin + (len(members) - 1) * (slot_w + gap) + grids[members[-1]].width + 6
            spans = []
            for a, b, name in regions:
                ya = gy + ((max(a, lo) - lo) >> 8) * args.cell
                yb = gy + ((min(b, hi) - lo) >> 8) * args.cell + args.cell - 1
                spans.append((ya, yb, name))
            spans.sort()
            tops = spread([(ya + yb) // 2 - lh // 2 for ya, yb, _ in spans], lh, gy - lh // 2)
            for (ya, yb, name), ty in zip(spans, tops):
                d.line([(rx, ya), (rx + 4, ya), (rx + 4, yb), (rx, yb)], fill=(200, 200, 120))
                mid = (ya + yb) // 2
                d.line([(rx + 5, mid), (rx + 12, ty + lh // 2)], fill=(200, 200, 120))
                d.text((rx + 16, ty), name, fill=(220, 220, 160), font=font)
    out.save(args.png)
    print(f'{args.png}: {out.width} x {out.height}, text {size} px')


if __name__ == '__main__':
    main()

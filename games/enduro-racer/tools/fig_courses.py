#!/usr/bin/env python3
"""The five courses side by side, drawn from the track resource (doc 01, 1.5).

    python3 tools/fig_courses.py [--out docs/img/maps/courses.png] [--scale 3]

Reads src/res/track (through tools/res_formats.py and tools/course.py's track walk, as TrackStep runs it) and the
sprites from build/game.bin for the legend. Each column is one stage from its start (top) to its end (bottom), one
pixel row every SCALE distance units. The background is the segment's hill (0 flat to 3), the grey band the road
bent sideways by each segment's curve (0-3) and CurveDir (a sketch: the game keeps no map, it bends the road on the
screen, and which way CurveDir 1 bends is drawn to the right by convention here), the coloured marks the objects at
their lateral place (the variable object resolved to the type the stage's `var` command sets), white bars the ramps,
red bars the stage 3 gap marks. Numbers at the left: distance from the race's start, every 1024 units.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import res_formats as rf  # noqa: E402
import course  # noqa: E402

NAMES = {0: 'ramp', 1: 'boulder', 2: 'conifer', 3: 'palm', 4: 'bush', 5: 'cactus', 6: 'rock spires',
         7: 'round tree'}
COLOURS = {0: (255, 255, 255), 1: (150, 150, 150), 2: (20, 120, 20), 3: (230, 160, 40), 4: (120, 220, 80),
           5: (200, 60, 200), 6: (200, 90, 40), 7: (60, 200, 255)}
LARGEST = {4: (29, 8, 0xB4C0), 5: (96, 3, 0xB306), 1: (24, 3, 0xC1BF), 6: (65, 6, 0xBDA8), 2: (107, 5, 0xC27B),
           0: (26, 25, 0xC84F), 3: (101, 6, 0xB702), 7: (91, 8, 0x6D34)}
HILLS = [(225, 235, 215), (200, 220, 185), (170, 200, 150), (140, 180, 120)]
GROUND = ['grass, trees', 'sand, rock spires', 'dunes, a gap', 'sand, cacti', 'beach, palms']


def sprite(image, rows, width, addr, scale=1):
    im = Image.new('RGBA', (width * 8, rows), (0, 0, 0, 0))
    for y in range(rows):
        for bx in range(width):
            v = image[addr - 0x5B00 + y * width + bx]
            for k in range(8):
                if v & (0x80 >> k):
                    im.putpixel((bx * 8 + k, y), (0, 0, 0, 255))
    return im.resize((width * 8 * scale, rows * scale), Image.NEAREST) if scale != 1 else im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'maps', 'courses.png'))
    ap.add_argument('--scale', type=int, default=3)
    a = ap.parse_args()
    data = rf.load('track/tables.bin')
    stages, _ = rf.track_stages(data)
    events, var_at = [], []
    for o, w, dist in rf.track_walk(data):
        if w[0] == 'call':
            n = None if w[2] == 'forever' else int(w[2])
            course.run(data, course.commands(data, int(w[1].lstrip('$'), 16)), n, dist, events)
        elif w[0] == 'obj':
            events.append((dist, 'obj', int(w[1]), int(w[3])))
        elif w[0] == 'mark':
            events.append((dist, 'mark', 0, 0))
        elif w[0] == 'var':
            var_at.append((dist, int(w[1])))
    image = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    f, fb, fs = kitlib.font(13), kitlib.font(18), kitlib.font(12)
    colw, gap, left, top = 150, 12, 44, 92
    legend_x = left + 5 * (colw + gap) + 4
    width = 1050
    longest = max(len(s) for s in stages) * 128 // a.scale
    im = Image.new('RGB', (width, top + longest + 40), (255, 255, 255))
    d = ImageDraw.Draw(im)
    d.text((8, 6), 'The five courses as the track data lays them out: road bends, hills, objects, ramps', font=fb,
           fill=(0, 0, 0))
    d.text((8, 30), 'one row = %d distance units (ScrollStep = SPEED x 14 a pass, 8.8); a segment = 128 units'
           % a.scale, font=f, fill=(60, 60, 60))
    start = 0
    for n, segs in enumerate(stages):
        x0 = left + n * (colw + gap)
        length = 128 * len(segs)
        h = length // a.scale
        var = [t for dd, t in var_at if dd < start + length][-1]
        d.text((x0, 52), 'stage %d: %d seg.' % (n + 1, len(segs)), font=f, fill=(0, 0, 0))
        d.text((x0, 68), GROUND[n], font=fs, fill=(60, 60, 60))
        centre, shift, marks = colw / 2, [], []
        for s, b in enumerate(segs):
            hill, curve, direction = b & 3, (b >> 2) & 3, (b >> 4) & 1
            y0, y1 = top + s * 128 // a.scale, top + (s + 1) * 128 // a.scale
            d.rectangle([x0, y0, x0 + colw - 1, y1], fill=HILLS[hill])
            for _y in range(y0, y1):
                shift.append(centre)
                centre += (curve * (1 if direction else -1)) * 0.3
                centre = max(40, min(colw - 40, centre))
            d.line([x0, y0, x0 + 5, y0], fill=(80, 80, 80))
        for y, c in enumerate(shift):
            d.line([x0 + c - 18, top + y, x0 + c + 18, top + y], fill=(110, 110, 110))
        for dist, kind, typ, x in events:
            if not start <= dist < start + length:
                continue
            y = top + (dist - start) // a.scale
            c = x0 + shift[min((dist - start) // a.scale, len(shift) - 1)]
            if kind == 'mark':
                marks.append((c, y))
                continue
            if typ == 10:
                typ = var
            if typ == 0:
                d.rectangle([c - 18, y - 1, c + 18, y + 1], fill=(255, 255, 255), outline=(0, 0, 0))
                continue
            px = c + x * 18 / 64
            px = max(x0 + 2, min(x0 + colw - 3, px))
            d.rectangle([px - 2, y - 2, px + 2, y + 2], fill=COLOURS[typ], outline=(0, 0, 0))
        for c, y in marks:
            d.rectangle([c - 30, y - 2, c + 30, y + 2], fill=(230, 0, 0))
        start += length
    # distance ticks on the left of stage 1's column (each column starts at its own stage start)
    acc = 0
    for n, segs in enumerate(stages):
        acc_next = acc + 128 * len(segs)
        x0 = left + n * (colw + gap)
        d.text((x0 + 2, top + 128 * len(segs) // a.scale + 4), 'ends at %d' % acc_next, font=fs, fill=(0, 0, 0))
        acc = acc_next
    for u in range(0, 4097, 512):
        y = top + u // a.scale
        d.line([left - 6, y, left - 1, y], fill=(0, 0, 0))
        d.text((2, y - 7), str(u), font=fs, fill=(0, 0, 0))
    d.text((2, top - 18), 'units', font=fs, fill=(0, 0, 0))
    # legend
    y = top
    d.text((legend_x, 52), 'objects', font=f, fill=(0, 0, 0))
    for t in [0, 1, 2, 7, 6, 4, 5, 3]:
        rows, w, addr = LARGEST[t]
        sp = sprite(image, rows, w, addr)
        if sp.width > 120:
            sp = sp.resize((sp.width // 2, sp.height // 2), Image.NEAREST)
        d.rectangle([legend_x, y + 2, legend_x + 8, y + 10], fill=COLOURS[t], outline=(0, 0, 0))
        d.text((legend_x + 14, y), 'type %d %s' % (t, NAMES[t]), font=fs, fill=(0, 0, 0))
        im.paste(sp, (legend_x + 14, y + 18), sp)
        y += 18 + sp.height + 10
    d.rectangle([legend_x, y + 2, legend_x + 30, y + 4], fill=(230, 0, 0))
    d.text((legend_x + 36, y - 4), 'gap mark', font=fs, fill=(0, 0, 0))
    y += 18
    for h in range(4):
        d.rectangle([legend_x, y, legend_x + 12, y + 10], fill=HILLS[h], outline=(0, 0, 0))
        d.text((legend_x + 18, y - 2), 'hill %d' % h, font=fs, fill=(0, 0, 0))
        y += 16
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Draw each stage's course from the track resource (src/res/track/*.txt, through tools/res_formats.py):

    python3 tools/course.py [--out src/res/track] [--scale 4]

Writes course1.png ... course5.png (views only: the build does not read them) and prints each stage's counts.
The picture is the stage from its start (top) to its end (bottom), one pixel row every SCALE distance units:
the background shade is the segment's hill (0 flat to 3), the grey band the road, bent sideways by the segment's
curve and direction (a sketch: the game bends the road on screen, it keeps no map), the dots the objects at their
lateral place (colour by type, legend at the top left), red lines the stage 3 gap marks, the thin lines the
segment borders. The objects come from the track as TrackStep runs it: a `call` runs its pattern, looping at its
`jump`, for its length (a `forever` call until the pattern's `ret`).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as rf  # noqa: E402

COLOURS = {0: (255, 255, 255), 1: (40, 200, 40), 2: (200, 120, 40), 3: (120, 80, 40), 4: (60, 160, 255),
           5: (230, 230, 60), 6: (220, 60, 220), 7: (255, 140, 140), 10: (160, 160, 160)}
NAMES = {0: 'ramp', 10: 'variable'}
END = 128 * 140 + 512  # past the race's end (the last stage's forever pattern loops): stop there
HILLS = [(30, 70, 30), (45, 90, 40), (60, 110, 50), (75, 130, 60)]


def commands(data, addr):
    """the commands from a copy address on, with their copy addresses"""
    return [(rf.COPY_ORG + o, w) for o, w in rf.track_parse(data, addr - rf.COPY_ORG, rf.TRACK_END - rf.TRACK_ORG)]


def run(data, start_cmds, limit, dist, out, depth=0):
    """run commands (a list from one address on) for limit units (None: until ret); append (distance, kind, value,
    x); return the distance reached"""
    index = {a: i for i, (a, _) in enumerate(start_cmds)}
    i, used, steps = 0, 0, 0
    while i < len(start_cmds) and (limit is None or used < limit) and dist + used < END and steps < 20000:
        steps += 1
        _a, w = start_cmds[i]
        if w[0] == 'obj':
            out.append((dist + used, 'obj', int(w[1]), int(w[3])))
            used += 2 * int(w[2])
        elif w[0] == 'mark':
            out.append((dist + used, 'mark', 0, 0))
        elif w[0] == 'ret':
            if limit is None:
                return dist + used
        elif w[0] == 'jump':
            target = int(w[1].lstrip('$'), 16)
            if target in index:
                i = index[target]
                continue
            sub = commands(data, target)
            start_cmds, index, i = sub, {a: k for k, (a, _) in enumerate(sub)}, 0
            continue
        elif w[0] == 'call' and depth < 3:
            n = None if w[2] == 'forever' else int(w[2])
            reached = run(data, commands(data, int(w[1].lstrip('$'), 16)), n, dist + used, out, depth + 1)
            used = reached - dist
        i += 1
    return dist + used


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(rf.RES, 'track'))
    p.add_argument('--scale', type=int, default=4)
    args = p.parse_args()
    data = rf.load('track/tables.bin')
    stages, _ = rf.track_stages(data)
    top = rf.track_walk(data)
    events = []
    for k, (o, w, dist) in enumerate(top):
        if w[0] == 'call':
            n = None if w[2] == 'forever' else int(w[2])
            run(data, commands(data, int(w[1].lstrip('$'), 16)), n, dist, events)
        elif w[0] == 'obj':
            events.append((dist, 'obj', int(w[1]), int(w[3])))
        elif w[0] == 'mark':
            events.append((dist, 'mark', 0, 0))
    start = 0
    for n, segs in enumerate(stages):
        length = 128 * len(segs)
        h = length // args.scale
        img = Image.new('RGB', (240, h + 40), (0, 0, 0))
        d = ImageDraw.Draw(img)
        centre, shift = 120.0, []
        for s, b in enumerate(segs):
            hill, curve, direction = b & 3, (b >> 2) & 3, (b >> 4) & 1
            y0, y1 = 40 + s * 128 // args.scale, 40 + (s + 1) * 128 // args.scale
            d.rectangle([0, y0, 239, y1], fill=HILLS[hill])
            for y in range(y0, y1):
                shift.append(centre)
                centre += (curve * (1 if direction else -1)) * 0.25
                centre = max(60, min(180, centre))
            d.line([0, y0, 6, y0], fill=(200, 200, 200))
        for y, c in enumerate(shift):
            d.line([c - 30, 40 + y, c + 30, 40 + y], fill=(90, 90, 90))
        counts = {}
        for dist, kind, typ, x in events:
            if not start <= dist < start + length:
                continue
            y = (dist - start) // args.scale
            c = shift[min(y, len(shift) - 1)]
            if kind == 'mark':
                d.line([c - 40, 40 + y, c + 40, 40 + y], fill=(255, 0, 0))
                counts['marks'] = counts.get('marks', 0) + 1
                continue
            px = c + x * 30 / 64
            d.ellipse([px - 2, 40 + y - 2, px + 2, 40 + y + 2], fill=COLOURS.get(typ, (255, 0, 0)))
            counts[typ] = counts.get(typ, 0) + 1
        for i, t in enumerate(sorted(COLOURS)):
            d.rectangle([4 + 26 * (i % 9), 4, 10 + 26 * (i % 9), 10], fill=COLOURS[t])
            d.text((12 + 26 * (i % 9), 2), str(t), fill=(255, 255, 255))
        d.text((4, 20), 'stage %d: %d units' % (n + 1, length), fill=(255, 255, 255))
        path = os.path.join(args.out, 'course%d.png' % (n + 1))
        img.save(path)
        print('%s: %d segments, objects by type %s' % (os.path.relpath(path, rf.ROOT), len(segs),
              ', '.join('%s %d' % (NAMES.get(t, t), c) for t, c in sorted(counts.items(), key=lambda x: str(x[0])))))
        start += length
    return 0


if __name__ == '__main__':
    sys.exit(main())

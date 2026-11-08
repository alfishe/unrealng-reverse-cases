#!/usr/bin/env python3
"""The ship slots over a recorded fight, animated (docs/07-objects.md 7.7): the recorded screen, the ships seen from
above, and the eight slots with their blueprint, energy and state, frame by frame.

    python3 tools/fig_slots_anim.py REC FIRST LAST STEP OUT.gif [--event F:TEXT ...] [--title TEXT]

The slots come from work/<rec>/slots/FFFFFF.bin (tools/grab_slots.py), the screens from work/<rec>/frames
(tools/grab.py; the nearest grabbed frame at or before each step). The top view puts the player at the centre facing
up: x across, z ahead, 4000 units to each edge; each ship leaves a trail of its last 60 frames. A slot's state is
its flags byte +$20: bits 4-5 not 0 mark a ship exploding (ExplosionPoint sets them, then the states run down);
a slot with energy (+$22) 0 is free, whatever header it still holds.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_design as F  # noqa: E402
import fig_objects as O  # noqa: E402

COLOURS = {'Thargoid': (110, 220, 110), 'Thargon': (170, 255, 120), 'Missile': (255, 90, 90),
           'Plate': (200, 200, 120), 'Splinter': (190, 160, 120), 'Cargo': (230, 180, 80)}
RANGE = 4000


def slots(rec, f):
    m = open(os.path.join(F.CASE, 'work', rec, 'slots', '%06d.bin' % f), 'rb').read()
    out = []
    for s in range(8):
        a = s * 39
        if m[a + 0x22] == 0:
            out.append(None)
            continue
        out.append({'x': O.coordinate(m, a), 'y': O.coordinate(m, a + 3), 'z': O.coordinate(m, a + 6),
                    'energy': m[a + 0x22], 'flags': m[a + 0x20],
                    'name': O.BLUEPRINTS.get(m[a + 0x23] | m[a + 0x24] << 8, '?')})
    return out


def colour(name):
    for k, v in COLOURS.items():
        if name.startswith(k):
            return v
    return (160, 160, 200)


def screen(rec, f):
    for g in range(f, f - 16, -1):
        try:
            return F.shot(rec, g, 2).resize((384, 288), Image.LANCZOS)
        except (FileNotFoundError, OSError):
            continue
    return Image.new('RGB', (384, 288), F.BG)


def picture(rec, f, history, text, title):
    scr = screen(rec, f)
    side = 316
    body = 326
    im = Image.new('RGB', (scr.width + side + 300, body + 64), F.BG)
    d = ImageDraw.Draw(im)
    d.text((8, 6), title, fill=F.TEXT, font=K.font(16))
    d.text((8, body + 38), '%s %d: %s' % (rec, f, text), fill=F.LABEL, font=K.font(15))
    im.paste(scr, (0, 32))
    # the top view
    ox, oy = scr.width + 8, 32
    d.rectangle((ox, oy, ox + side - 16, oy + side - 17), outline=(70, 70, 90))
    cx, cy, half = ox + (side - 16) // 2, oy + (side - 16) // 2, (side - 16) / 2

    def xy(p):
        return (cx + max(-1, min(1, p['x'] / RANGE)) * half, cy - max(-1, min(1, p['z'] / RANGE)) * half)

    d.text((ox + 4, oy + side - 14), 'from above: x across, z ahead', fill=F.DIM, font=K.font(14))   # under the box
    d.polygon([(cx, cy - 7), (cx - 5, cy + 5), (cx + 5, cy + 5)], fill=(255, 255, 255))
    for s in range(8):
        trail = [h[s] for h in history if h[s] is not None]
        if len(trail) > 1:
            d.line([xy(p) for p in trail], fill=tuple(c // 2 for c in colour(trail[-1]['name'])), width=1)
    now = history[-1]
    for s, p in enumerate(now):
        if p is None:
            continue
        x, y = xy(p)
        c = colour(p['name'])
        if p['flags'] & 0x30:
            d.ellipse((x - 8, y - 8, x + 8, y + 8), outline=(255, 120, 60), width=2)
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=c)
        d.text((x + 6, y - 8), str(s), fill=c, font=K.font(14))
    # the slot table
    tx = ox + side
    d.text((tx, oy + 2), 'slot, blueprint, energy (of 255)', fill=F.DIM, font=K.font(13))
    for s, p in enumerate(now):
        y = oy + 22 + s * 37
        d.text((tx, y), str(s), fill=F.TEXT, font=K.font(15))
        if p is None:
            d.text((tx + 24, y), 'free', fill=(90, 90, 100), font=K.font(14))
            continue
        c = colour(p['name'])
        d.text((tx + 24, y), p['name'], fill=c, font=K.font(14))
        d.rectangle((tx + 24, y + 19, tx + 24 + 220, y + 28), outline=(70, 70, 90))
        d.rectangle((tx + 24, y + 19, tx + 24 + p['energy'] * 220 // 255, y + 28), fill=c)
        d.text((tx + 250, y + 15), str(p['energy']), fill=F.TEXT, font=K.font(13))
        if p['flags'] & 0x30:
            d.text((tx + 170, y), 'exploding', fill=(255, 120, 60), font=K.font(13))
    return im


def main():
    p = argparse.ArgumentParser()
    p.add_argument('rec')
    p.add_argument('first', type=int)
    p.add_argument('last', type=int)
    p.add_argument('step', type=int)
    p.add_argument('out')
    p.add_argument('--event', action='append', default=[])
    p.add_argument('--title', default='')
    p.add_argument('--delay', type=int, default=80)
    a = p.parse_args()
    events = sorted((int(e.split(':', 1)[0]), e.split(':', 1)[1]) for e in a.event)
    frames = list(range(a.first, a.last + 1, a.step))
    history, pics = [], []
    for f in frames:
        history.append(slots(a.rec, f))
        history = history[-max(1, 60 // a.step):]
        text = ''
        for g, t in events:
            if g <= f:
                text = t
        pics.append(picture(a.rec, f, history, text, a.title))
    K.save_gif(a.out, pics, [a.delay] * (len(pics) - 1) + [2000])
    print('wrote', a.out, len(pics), 'pictures')


if __name__ == '__main__':
    main()

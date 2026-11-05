#!/usr/bin/env python3
"""Doc 05 figures: the weapon pod experiment of tools/exp_pods.py (no recording reached it).

    python3 tools/fig_pods.py sheet --runs work/zyA/exp/pods --out docs/img/controls/pods.png
    python3 tools/fig_pods.py gif --runs work/zyA/exp/pods --run take-2 --from 120 --to 200
           --out docs/img/controls/pod-take.gif

sheet: on top FireHeld $8184 over the first 40 frames of a run with fire held from frame 1 (one step every 2
frames, the threshold 8 PodStep tests), then the six runs side by side at the frame after the touch: the screen and
what changed in the player record ($7F9C +7 selector, +8 side weapon, +$0A laser, +$0B speed), Fuel $80E6 and the
score. gif: one run's screens (kept every 2 frames by exp_pods.py) with the record's values under each picture.
"""
import argparse
import csv
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zynlib as Z  # noqa: E402

K = Z.K
RUNS = [('select', 'no fire: the selector steps on', 'selector 0'),
        ('take-0', 'fire held, selector 0', 'speed-up'), ('take-1', 'fire held, selector 1', 'laser'),
        ('take-2', 'fire held, selector 2', 'plasma'), ('take-3', 'fire held, selector 3', 'homing missiles'),
        ('take-4', 'fire held, selector 4', 'seeker')]
SIDE = {0: 'none', 2: 'plasma', 3: 'homing', 4: 'seeker'}


def load(runs, name):
    rows = list(csv.DictReader(open(os.path.join(runs, name + '.tsv')), delimiter='\t'))
    rows = [{k: int(v) for k, v in r.items()} for r in rows]
    screens = np.load(os.path.join(runs, name + '.npz'))['screens']
    return rows, screens


def screen_image(raw):
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = bytes(raw)
    return K.render_screen(mem)


def touch_of(rows):
    for a, b in zip(rows, rows[1:]):
        if any(a[k] != b[k] for k in ('selector', 'side', 'double', 'laser', 'speed')):
            return b['frame'], a, b
    return None, rows[0], rows[-1]


def describe(a, b):
    out = []
    for key, label in (('selector', 'selector +7'), ('side', 'side +8'), ('laser', 'laser +$0A'),
                       ('speed', 'speed +$0B')):
        if a[key] != b[key]:
            va, vb = a[key], b[key]
            if key == 'speed':
                va, vb = f'${va:02X}', f'${vb:02X}'
            if key == 'side':
                va, vb = f'{va} {SIDE.get(va, "")}', f'{vb} {SIDE.get(vb, "")}'
            out.append(f'{label}: {va} -> {vb}')
    if b['fuel'] - a['fuel'] > 5:
        out.append(f'Fuel: ${a["fuel"]:02X} -> ${b["fuel"]:02X}')
    out.append(f'score: {a["score"]} -> {b["score"]}')
    return out


def sheet(args):
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    W = 900
    im = Image.new('RGB', (W, 1100), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'A pod: touch it with fire held 8 passes to take the selected weapon, else the selector steps on',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'tools/exp_pods.py: r1 frame 200 state, ship on the pod\'s row, selector poked, Kempston fire '
                     'held (take) or not (select)', fill=K.DIM, font=f)
    # the FireHeld chart
    rows, _ = load(args.runs, 'take-1')
    x0, y0, cw, ch = 60, 70, 800, 120
    d.rectangle((x0, y0, x0 + cw, y0 + ch), outline=K.DIM)
    n = 40
    top = 20
    for v in range(0, top + 1, 4):
        y = y0 + ch - v * ch / top
        d.text((x0 - 26, y - 7), f'{v}', fill=K.DIM, font=fs)
    yth = y0 + ch - 8 * ch / top
    d.line([(x0, yth), (x0 + cw, yth)], fill=(255, 90, 90))
    d.text((x0 + 6, yth - 16), 'PodStep: FireHeld >= 8 takes the weapon', fill=(255, 90, 90), font=fs)
    pts = []
    for r in rows[:n]:
        x = x0 + (r['frame'] - 1) * cw / (n - 1)
        y = y0 + ch - min(r['fire_held'], top) * ch / top
        pts.append((x, y))
        d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(90, 200, 120))
    d.line(pts, fill=(90, 200, 120), width=2)
    first8 = next(r['frame'] for r in rows if r['fire_held'] >= 8)
    xf = x0 + (first8 - 1) * cw / (n - 1)
    d.line([(xf, y0), (xf, y0 + ch)], fill=(240, 200, 70))
    d.text((xf + 4, y0 + 4), f'frame {first8}: FireHeld = 8 (fire held 8 passes, 16 frames)', fill=(240, 200, 70),
           font=fs)
    for fr in range(0, n + 1, 10):
        x = x0 + max(fr - 1, 0) * cw / (n - 1)
        d.text((x - 6, y0 + ch + 4), f'{fr}', fill=K.DIM, font=fs)
    d.text((x0, y0 + ch + 18), 'FireHeld $8184 per frame, fire held from frame 1 (run take-1): +1 every second frame, '
                               'once a pass (ReadControls)', fill=K.DIM, font=f)
    # the six runs
    gy = y0 + ch + 48
    sw, sh = 280, 210
    for i, (name, how, what) in enumerate(RUNS):
        rows, screens = load(args.runs, name)
        frame, a, b = touch_of(rows)
        pick = min(len(screens) - 1, (frame + 30) // 2) if frame else len(screens) - 1
        x, y = 10 + (i % 3) * (sw + 15), gy + (i // 3) * (sh + 110)
        d.text((x, y), f'{name}: {how}', fill=K.TEXT, font=f)
        im.paste(screen_image(screens[pick]).resize((sw, sh), Image.NEAREST), (x, y + 18))
        lines = [f'touched at frame {frame}; picture at frame {pick * 2 + 2}'] + describe(a, b)
        for j, line in enumerate(lines[:5]):
            d.text((x, y + 18 + sh + 4 + 15 * j), line, fill=(240, 200, 70) if j == 1 else K.DIM, font=fs)
    im = im.crop((0, 0, W, gy + 2 * (sh + 110)))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


def gif(args):
    rows, screens = load(args.runs, args.run)
    f, fb = K.font(12), K.font(15)
    pictures = []
    for i in range(len(screens)):
        fr = i * 2 + 2
        if not (args.start <= fr <= args.end):
            continue
        r = rows[fr - 1]
        im = Image.new('RGB', (532, 34 + 384 + 44), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        d.text((10, 8), args.title or f'Run {args.run}: the pod taken with fire held', fill=K.TEXT, font=fb)
        im.paste(screen_image(screens[i]).resize((512, 384), Image.NEAREST), (10, 34))
        d.text((10, 424), f'frame {fr}  FireHeld {r["fire_held"]}  selector {r["selector"]}  side {r["side"]} '
                          f'({SIDE.get(r["side"], "")})  laser {r["laser"]}  speed ${r["speed"]:02X}', fill=K.TEXT,
               font=f)
        d.text((10, 440), f'Fuel ${r["fuel"]:02X}  score {r["score"]}', fill=K.DIM, font=f)
        pictures.append(im)
    durations = [100] * len(pictures)
    durations[-1] = 2000
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['sheet', 'gif'])
    p.add_argument('--runs', required=True)
    p.add_argument('--run', default='take-2')
    p.add_argument('--from', dest='start', type=int, default=120)
    p.add_argument('--to', dest='end', type=int, default=200)
    p.add_argument('--title')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    {'sheet': sheet, 'gif': gif}[args.what](args)


if __name__ == '__main__':
    main()

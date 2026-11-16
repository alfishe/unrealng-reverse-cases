#!/usr/bin/env python3
"""How long a pass of the race loop takes, and how the timer follows the passes (doc 04, 4.5).

    python3 tools/fig_passes.py SAMPLES.json [--out docs/img/loop/passes.png] [--from 14075] [--to 19265]

SAMPLES.json is a per-frame sample of the c1 recording made through the MCP `time_travel memory_at` call
(work/docs/erA/sample.py: the bytes $7C2E-$7C3F and $5E00-$5E7F at the start of every frame from 11600 to 21265).
A pass ends where PassCount ($7C2E) changes: the value read at frame N is the state at the start of frame N, so the
step seen at N happened during frame N-1. Left: the histogram of pass lengths in frames. Right: the passes in
order over the race (length against frame), with the timer ($5E1F, BCD) drawn under them.
"""
import argparse
import json
import os
import sys
from collections import Counter

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('samples')
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'loop', 'passes.png'))
    ap.add_argument('--from', dest='start', type=int, default=14075)
    ap.add_argument('--to', dest='end', type=int, default=19265)
    a = ap.parse_args()
    d = json.load(open(a.samples))
    frames = sorted(int(k) for k in d['frames'] if a.start <= int(k) <= a.end)

    def byte(f, rg, addr):
        return bytes.fromhex(d['frames'][str(f)][rg])[addr - int(rg.split('-')[0], 16)]
    steps, prev = [], None
    for f in frames:
        v = byte(f, '7C2E-7C3F', 0x7C2E)
        if prev is not None and v != prev:
            steps.append(f)
        prev = v
    passes = [(s1, s1 - s0) for s0, s1 in zip(steps, steps[1:])]
    hist = Counter(n for _, n in passes)
    mean = sum(n for _, n in passes) / len(passes)
    timer = [(f, byte(f, '5E00-5E7F', 0x5E1F)) for f in frames]
    speed = [(f, byte(f, '7C2E-7C3F', 0x7C34)) for f in frames]

    W, H = 1050, 520
    im = Image.new('RGB', (W, H), (255, 255, 255))
    dr = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(13), kitlib.font(18), kitlib.font(12)
    dr.text((8, 6), 'A pass takes 8.0 frames on average: the main loop runs free, the timer counts passes',
            font=fb, fill=(0, 0, 0))
    dr.text((8, 30), 'c1 frames %d-%d (stage 1, the timer from 60 to 0): %d passes, mean %.2f frames'
            % (a.start, a.end, len(passes), mean), font=f, fill=(60, 60, 60))
    # histogram
    hx, hy, hw, hh = 50, 80, 300, 360
    top = max(hist.values())
    keys = list(range(5, 13))
    bw = hw // (len(keys) + 2)
    dr.line([hx, hy + hh, hx + hw, hy + hh], fill=(0, 0, 0))
    for i, k in enumerate(keys + ['17+']):
        n = hist.get(k, 0) if k != '17+' else sum(v for kk, v in hist.items() if kk >= 13)
        h = int(n * (hh - 20) / top)
        x = hx + 6 + i * bw
        dr.rectangle([x, hy + hh - h, x + bw - 6, hy + hh], fill=(230, 90, 80) if k == 8 else (120, 170, 230),
                     outline=(0, 0, 0))
        dr.text((x, hy + hh - h - 16), str(n), font=fs, fill=(0, 0, 0))
        dr.text((x + 4, hy + hh + 4), str(k), font=fs, fill=(0, 0, 0))
    dr.text((hx, hy + hh + 22), 'frames a pass (17+: the countdown pass,', font=fs, fill=(0, 0, 0))
    dr.text((hx, hy + hh + 38), '70: the pass held by the pause)', font=fs, fill=(0, 0, 0))
    dr.text((hx, hy - 22), 'passes by length', font=f, fill=(0, 0, 0))
    # over time
    px, py, pw, ph = 420, 80, 600, 200
    dr.text((px, py - 22), 'each pass: its length (dots) and the speed (grey, km/h / 20)', font=f, fill=(0, 0, 0))
    span = a.end - a.start

    def X(fr):
        return px + int((fr - a.start) * pw / span)

    def Y(v):
        return py + ph - int(min(v, 14) * ph / 14)
    dr.rectangle([px, py, px + pw, py + ph], outline=(120, 120, 120))
    for v in (4, 8, 12):
        dr.line([px, Y(v), px + pw, Y(v)], fill=(220, 220, 220))
        dr.text((px - 22, Y(v) - 7), str(v), font=fs, fill=(0, 0, 0))
    last = None
    for fr, s in speed:
        pt = (X(fr), Y(s / 20))
        if last:
            dr.line([last, pt], fill=(170, 170, 170))
        last = pt
    for fr, n in passes:
        c = (230, 90, 80) if n >= 11 else (40, 40, 40)
        x, y = X(fr), Y(n)
        dr.rectangle([x - 1, y - 1, x + 1, y + 1], fill=c)
    # timer
    ty, th = py + ph + 50, 120
    dr.text((px, ty - 22), 'the timer ($5E1F, BCD shown as decimal): one step = 10 passes', font=f, fill=(0, 0, 0))
    dr.rectangle([px, ty, px + pw, ty + th], outline=(120, 120, 120))
    last = None
    for fr, t in timer:
        v = (t >> 4) * 10 + (t & 15)
        pt = (X(fr), ty + th - int(v * th / 60))
        if last:
            dr.line([last, (pt[0], last[1]), pt], fill=(60, 120, 200), width=2)
        last = pt
    for v in (0, 30, 60):
        dr.text((px - 22, ty + th - int(v * th / 60) - 7), str(v), font=fs, fill=(0, 0, 0))
    for fr in range(a.start - a.start % 1000 + 1000, a.end, 1000):
        dr.line([X(fr), ty + th, X(fr), ty + th + 5], fill=(0, 0, 0))
        dr.text((X(fr) - 18, ty + th + 7), str(fr), font=fs, fill=(0, 0, 0))
    dr.text((px, ty + th + 26), 'frame (50 a second): 60 timer seconds took %d frames, %.0f s of real time'
            % (a.end - a.start, (a.end - a.start) / 50), font=fs, fill=(60, 60, 60))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size, 'passes', len(passes), 'mean %.2f' % mean, sorted(hist.items()))


if __name__ == '__main__':
    main()

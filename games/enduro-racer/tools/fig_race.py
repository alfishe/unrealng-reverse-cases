#!/usr/bin/env python3
"""One race in numbers: SPEED, the timer and the score of c1's stage 1, frame by frame (doc 01, 1.6).

    python3 tools/fig_race.py SAMPLES.json [--from 14000] [--to 19500] [--out docs/img/design/race-c1.png]

SAMPLES.json is work/docs/erA/sample.py's output for c1 (one sample a frame, memory_at: the state at the start of
the frame): the block $5E00-$5E7F (Score $5E18, 7 ASCII digits; Timer $5E1F, BCD) and $7C2E-$7C3F (GetUp $7C31,
Speed $7C33-$7C34, the high byte is SPEED in km/h), and $9136-$9177 (FallTime $916E). Three bands share the frame
axis: SPEED (with the falls shaded), the timer in seconds, the score. The time bonus is not in this race: c1 never
finished stage 1.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('samples')
    ap.add_argument('--from', dest='f0', type=int, default=14075)
    ap.add_argument('--to', dest='f1', type=int, default=19500)
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'design', 'race-c1.png'))
    a = ap.parse_args()
    d = json.load(open(a.samples))['frames']
    rows = []
    for f in range(a.f0, a.f1 + 1):
        s = d.get(str(f))
        if not s:
            continue
        b5e = bytes.fromhex(s['5E00-5E7F'])
        b7c = bytes.fromhex(s['7C2E-7C3F'])
        b91 = bytes.fromhex(s['9136-9177'])
        score = int(b5e[0x18:0x1F].decode('latin-1').replace(' ', '') or 0)
        t = b5e[0x1F]
        timer = (t >> 4) * 10 + (t & 15)
        rows.append((f, b7c[0x34 - 0x2E], timer, score, b91[0x6E - 0x36], b7c[0x31 - 0x2E]))
    # the score is sampled at a frame's start, sometimes in the middle of AddScore's carry: take the median of three
    sc = [r[3] for r in rows]
    rows = [r[:3] + (sorted(sc[max(i - 1, 0):i + 2])[len(sc[max(i - 1, 0):i + 2]) // 2],) + r[4:]
            for i, r in enumerate(rows)]
    W, left, right = 1050, 70, 20
    bands = [('SPEED (km/h)', 1, 200), ('timer (seconds)', 2, 60), ('score', 3, 60000)]
    bh, gap, top = 150, 40, 50
    H = top + len(bands) * (bh + gap) + 60
    im = Image.new('RGB', (W, H), (255, 255, 255))
    dr = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(14), kitlib.font(18), kitlib.font(13)
    dr.text((10, 8), 'c1, stage 1: SPEED, the timer and the score, one sample a frame (frames %d-%d)'
            % (a.f0, a.f1), font=fb, fill=(0, 0, 0))

    def X(fr):
        return left + (fr - a.f0) * (W - left - right) / (a.f1 - a.f0)
    for i, (name, k, vmax) in enumerate(bands):
        y0 = top + i * (bh + gap)
        dr.rectangle([left, y0, W - right, y0 + bh], outline=(0, 0, 0))
        dr.text((left, y0 - 18), name, font=f, fill=(0, 0, 0))
        # falls and getting up shaded
        for fr, sp, tm, sc, fall, getup in rows:
            if fall or getup:
                dr.line([X(fr), y0 + 1, X(fr), y0 + bh - 1], fill=(255, 215, 200))
        for v in (0, vmax // 2, vmax):
            yy = y0 + bh - v * bh / vmax
            dr.line([left - 5, yy, left, yy], fill=(0, 0, 0))
            dr.text((5, yy - 7), str(v), font=fs, fill=(0, 0, 0))
        pts = [(X(r[0]), y0 + bh - min(r[k], vmax) * bh / vmax) for r in rows]
        dr.line(pts, fill=[(200, 40, 40), (40, 90, 200), (0, 120, 0)][i], width=2)
    yb = top + len(bands) * (bh + gap) - gap + 6
    for fr in range(((a.f0 + 499) // 500) * 500, a.f1 + 1, 500):
        dr.line([X(fr), yb - 6, X(fr), yb], fill=(0, 0, 0))
        dr.text((X(fr) - 18, yb + 2), str(fr), font=fs, fill=(0, 0, 0))
    dr.text((left, yb + 22), 'frame (50 a second). Shaded: a fall or getting up (FallTime $916E or GetUp $7C31 '
            'nonzero).', font=fs, fill=(60, 60, 60))
    dr.text((left, yb + 40), 'Timer $5E1F and Score $5E18 as the game holds them; SPEED is $7C34.', font=fs,
            fill=(60, 60, 60))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)
    for r in rows[::500]:
        print(r)
    print(rows[-1])


if __name__ == '__main__':
    main()

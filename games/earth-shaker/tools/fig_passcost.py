#!/usr/bin/env python3
"""The mean pass of every cave in real play, split by step, from the L1 builds of the 32 rzx-earthNN recordings
(other players' RZX runs replayed, WALKTHROUGH 6.0): doc 4's chart of why the speed varies.

A routine's tstates_inclusive (L1) summed over the recording, divided by the passes (KeysStep `$8759` runs once a
pass), in frames of 69 888 T. The steps: DrawWindowAtOrigin `$8D75` (the 16 x 11 window, from MapKey), ScanCells
`$8075` and AntiGravScan `$A655` (the cell update, downward or, under anti-gravity, upward), AnimateCellCodes `$937E` own (the animation codes' walk), ClearVacated `$81AC`, KeysStep
(the player, with its own sounds), FizzSound `$A773` (the pass sound PassSound and the fizz beeps), TimerStep `$86DE`;
"other" is the rest of PlayCave's inclusive T-states a pass (the pass's glue, the interrupts it took).

    python3 tools/fig_passcost.py --out docs/img/loop/pass-cost.png [--tsv work/docs/esA/pass-cost.tsv]
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

FRAME_T = 69888
PARTS = [  # (name, entry, inclusive?, colour)
    ('DrawWindow (window)', '$8D75', True, (235, 90, 80)),
    ('ScanCells / AntiGravScan', '$8075+$A655', True, (90, 140, 250)),
    ('AnimateCellCodes', '$937E', False, (240, 150, 60)),
    ('ClearVacated', '$81AC', True, (180, 110, 230)),
    ('KeysStep (player)', '$8759', True, (230, 120, 200)),
    ('FizzSound + PassSound', '$A773', True, (250, 210, 60)),
    ('TimerStep', '$86DE', True, (90, 210, 120)),
]


def l1_path(n):
    if n == 4:  # stage 2's replay of cave 4 to its end (stage 1's rzx04 parted from the RZX at frame 2344)
        return os.path.join(CASE, 'work/stage2/rzx04/cap/l1.json')
    return os.path.join(CASE, 'work/stage1/rzx%02d/l1.json' % n)


def cave_costs(n):
    d = json.load(open(l1_path(n)))
    e = {rt['entry']: rt['profile'] for rt in d['routines'] if rt['page'] == 2 or rt['entry'] in ('$E740',)}
    passes = e['$8759']['entries']
    total = e['$8885']['tstates_inclusive'] / passes
    parts = []
    for name, entry, incl, col in PARTS:
        v = 0
        for one in entry.split('+'):
            p = e.get(one)
            if p:
                v += (p['tstates_inclusive'] if incl else p['tstates']) / passes
        parts.append(v)
    parts.append(total - sum(parts))
    return passes, total, parts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--tsv')
    ap.add_argument('--width', type=int, default=1050)
    a = ap.parse_args()
    rows = [(n,) + cave_costs(n) for n in range(1, 33)]
    names = [p[0] for p in PARTS] + ['other (glue, interrupts)']
    cols = [p[3] for p in PARTS] + [(120, 120, 120)]
    if a.tsv:
        with open(a.tsv, 'w') as f:
            f.write('cave\tpasses\tframes_a_pass\t' + '\t'.join(names) + '\n')
            for n, passes, total, parts in rows:
                f.write('%d\t%d\t%.2f\t' % (n, passes, total / FRAME_T) + '\t'.join('%d' % v for v in parts) + '\n')
    W = a.width
    left, top, right, bottom = 60, 74, 20, 150
    ph = 420
    H = top + ph + bottom
    img = Image.new('RGB', (W, H), (22, 22, 28))
    d = ImageDraw.Draw(img)
    fb, f, fs = K.font(15), K.font(12), K.font(11)
    d.text((left, 12), 'The mean pass per cave in real play: the window costs the same, the cell update and the sounds vary', fill=(235, 235, 235), font=fb)
    d.text((left, 32), 'rzx-earth01..32 (other players\' RZX runs replayed; cave 4 from stage 2\'s full replay), L1 '
           'T-states a pass = routine T / KeysStep runs', fill=(180, 180, 180), font=fs)
    fmax = 10
    pw = W - left - right
    bw = pw / 32
    y0 = top + ph
    for fr in range(0, fmax + 1):
        y = y0 - fr * ph / fmax
        d.line([left, y, W - right, y], fill=(55, 55, 62))
        d.text((left - 26, y - 7), '%d' % fr, fill=(190, 190, 190), font=f)
    d.text((6, top - 20), 'frames a pass', fill=(190, 190, 190), font=fs)
    for i, (n, passes, total, parts) in enumerate(rows):
        x0 = left + i * bw + 3
        x1 = left + (i + 1) * bw - 3
        y = y0
        for v, c in zip(parts, cols):
            hpx = v / FRAME_T * ph / fmax
            d.rectangle([x0, y - hpx, x1, y], fill=c)
            y -= hpx
        d.text((x0 + 1, y - 16), '%.1f' % (total / FRAME_T), fill=(230, 230, 230), font=fs)
        d.text((x0 + (x1 - x0) / 2 - 6, y0 + 4), '%d' % n, fill=(200, 200, 200), font=f)
    d.text((left + pw / 2 - 20, y0 + 22), 'cave', fill=(200, 200, 200), font=f)
    ly = y0 + 46
    colw = pw // 4
    for j, (nm, c) in enumerate(zip(names, cols)):
        x, yy = left + (j % 4) * colw, ly + (j // 4) * 22
        d.rectangle([x, yy + 2, x + 14, yy + 14], fill=c)
        d.text((x + 20, yy), nm, fill=(220, 220, 220), font=fs)
    d.text((left, ly + 52), 'How to read: one bar a cave, its height the mean pass in frames (the number on top); '
           'the colours stack the steps of the pass, bottom up.', fill=(190, 190, 190), font=fs)
    d.text((left, ly + 70), 'Command: python3 tools/fig_passcost.py --out docs/img/loop/pass-cost.png',
           fill=(150, 150, 150), font=fs)
    img.save(a.out)
    for n, passes, total, parts in rows:
        print(n, passes, '%.2f' % (total / FRAME_T), ' '.join('%d' % v for v in parts))


if __name__ == '__main__':
    main()

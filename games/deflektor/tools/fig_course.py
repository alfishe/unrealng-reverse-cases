#!/usr/bin/env python3
"""The course of a recorded level as a chart (doc 10), from a tools/ttd_watch.py log.

    python3 tools/ttd_watch.py --work W --addr 8380,9B3F,9B40,9B41,9B42,A507,A50A,A104,A8A6 --from F --to T \
        --step 1 > LOG
    python3 tools/fig_course.py LOG OUT --title "..."

Rows against the frame: the score (ScoreDigits `$9B3F-$9B42`, spaces as 0), CellsLeft `$8380`, the energy bar's byte
(EnergyBarPointer `$A507`, `$F1-$F8`), the overload bar's byte (OverloadBarPointer `$A50A`, `$B1-$B9`), the COMPUTER
line's MessageNumber `$A104` and the SoundFlags `$A8A6` bits.
"""
import re
import sys

from PIL import Image, ImageDraw

import figlib

MSG = {0: '', 1: 'CHARGING', 4: 'GREMLINS', 0x0A: 'ENERGY LOW', 0x0C: 'CRITICAL', 0x12: 'OVERLOAD', 0x13: 'MINE ALERT',
       0x14: 'ABORTED', 0x16: 'BOOM', 0x17: 'DRAINED', 0x18: 'CONTACT!'}
MCOL = {1: (120, 200, 255), 4: (255, 120, 255), 0x0A: (255, 200, 90), 0x0C: (255, 140, 60), 0x12: (255, 90, 90),
        0x13: (255, 60, 160), 0x16: (255, 40, 40), 0x17: (200, 60, 60), 0x18: (120, 255, 120)}


def parse(path):
    rows = []
    for line in open(path):
        m = re.match(r'(\d+) (.*)', line.strip())
        if not m:
            continue
        vals = dict((a.upper(), int(v, 16)) for a, v in re.findall(r'\$([0-9A-Fa-f]{4})=([0-9A-Fa-f]{2})', m.group(2)))
        if vals:
            rows.append((int(m.group(1)), vals))
    return rows


def main():
    rows = parse(sys.argv[1])
    out = sys.argv[2]
    title = sys.argv[sys.argv.index('--title') + 1] if '--title' in sys.argv else 'The course of a level'
    f0, f1 = rows[0][0], rows[-1][0]
    W, H = 1050, 620
    x0, x1 = 150, W - 20
    o = Image.new('RGB', (W, H), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), title, 17, figlib.ACCENT)
    figlib.text(d, (10, 32), 'Each row a variable against the frame (%d-%d), read from the recording by '
                'tools/ttd_watch.py' % (f0, f1), 12, figlib.DIM)

    def fx(f):
        return x0 + (f - f0) / max(1, f1 - f0) * (x1 - x0)

    def score(v):
        s = ''.join(chr(v.get(a, 0x30)) for a in ('9B3F', '9B40', '9B41', '9B42'))
        return int(s.replace(' ', '0') or 0) * 10

    series = {'score': [], 'cells': [], 'energy': [], 'overload': [], 'msg': [], 'sound': []}
    for f, v in rows:
        series['score'].append((f, score(v)))
        series['cells'].append((f, v['8380']))
        series['energy'].append((f, v['A507']))
        series['overload'].append((f, v['A50A']))
        series['msg'].append((f, v['A104']))
        series['sound'].append((f, v['A8A6']))

    def band(y, h, label, sub):
        d.rectangle([x0, y, x1, y + h], outline=(60, 60, 72))
        figlib.text(d, (10, y + 2), label, 13, figlib.FG)
        figlib.text(d, (10, y + 20), sub, 10, figlib.DIM)

    def steps(pts, y, h, lo, hi, col, end=f1):
        prev = None
        for (f, v), nxt in zip(pts, pts[1:] + [(end, None)]):
            yy = y + h - (min(max(v, lo), hi) - lo) / max(1, hi - lo) * h
            if prev is not None:
                d.line([fx(f), prev, fx(f), yy], fill=col, width=2)
            d.line([fx(f), yy, fx(nxt[0]), yy], fill=col, width=2)
            prev = yy

    y = 60
    sc = series['score']
    band(y, 80, 'score', '0 to %d' % max(v for _, v in sc))
    steps(sc, y, 80, 0, max(v for _, v in sc), (255, 220, 90))
    y += 95
    band(y, 70, 'CellsLeft $8380', '19 to 0; FE the door')
    cl = [(f, v if v < 0x80 else -1) for f, v in series['cells']]
    steps(cl, y, 70, -1, 19, (255, 120, 255))
    y += 85
    band(y, 60, 'energy byte $A507', 'F1 (empty) to F8 (full)')
    steps([(f, v) for f, v in series['energy']], y, 60, 0xF1, 0xF8, (120, 255, 120))
    y += 75
    band(y, 50, 'overload byte $A50A', 'B1 (cool) to B9 (full)')
    steps([(f, v) for f, v in series['overload']], y, 50, 0xB1, 0xB9, (255, 90, 90))
    y += 65
    band(y, 40, 'MessageNumber $A104', 'the COMPUTER line')
    ms = series['msg']
    for (f, v), nxt in zip(ms, ms[1:] + [(f1, None)]):
        if v:
            d.rectangle([fx(f), y + 4, max(fx(f) + 1, fx(nxt[0])), y + 36], fill=MCOL.get(v, (200, 200, 200)))
    y += 55
    band(y, 75, 'SoundFlags $A8A6', 'bits 1 mine, 2 laser, 3 burn, 4 charge')
    sf = series['sound']
    for b in range(1, 5):
        yy = y + 75 - b * 15
        for (f, v), nxt in zip(sf, sf[1:] + [(f1, None)]):
            if v & (1 << b):
                d.rectangle([fx(f), yy - 5, max(fx(f) + 1, fx(nxt[0])), yy + 5], fill=list(MCOL.values())[b])
        figlib.text(d, (x0 - 22, yy - 7), str(b), 10, figlib.DIM)
    y += 90
    for f in range(0, f1 + 1, 100):
        if f >= f0:
            d.line([fx(f), y - 8, fx(f), y - 3], fill=figlib.DIM)
            if f % 200 == 0:
                figlib.text(d, (fx(f) - 12, y), str(f), 10, figlib.DIM)
    xx = 10
    for k in (1, 0x12, 0x13, 0x18):
        d.rectangle([xx, y + 22, xx + 12, y + 34], fill=MCOL[k])
        figlib.text(d, (xx + 18, y + 20), MSG[k], 12, figlib.FG)
        xx += 18 + 10 * len(MSG[k]) + 20
    o = o.crop((0, 0, W, y + 44))
    o.save(out)


if __name__ == '__main__':
    main()

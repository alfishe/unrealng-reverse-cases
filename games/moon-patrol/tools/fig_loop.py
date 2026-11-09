#!/usr/bin/env python3
"""The data figures of doc 04 (the game loop), 1050 pixels wide, into docs/img/loop/, from the per-frame tables
work/docs/mpA-passes.py wrote (frame, PassCount $B23B, FRAMES $5C78 low word, read at the end of each frame):

    python3 tools/fig_loop.py passes   # work/docs/mpA-i1-passes.tsv: frames per pass, histogram and over time
    python3 tools/fig_loop.py bonus    # work/docs/mpA-i1-bonusE.tsv: the frames that lost their interrupt
    python3 tools/fig_loop.py all
"""
import os
import sys
from collections import Counter

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig_design import BG, F13, F14B, F16B, GREY, INK, WIDTH  # noqa: E402

CASE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(CASE, 'docs', 'img', 'loop')
COL = {6: (70, 150, 90), 7: (70, 120, 220), 8: (220, 120, 40)}


def table(name):
    rows = []
    for line in open(os.path.join(CASE, 'work', 'docs', name)):
        f, pc, fr = line.split()
        rows.append((int(f), int(pc), int(fr)))
    return rows


def pass_ends(rows):
    """the frames at which PassCount changed (the pass ended in the frame before)"""
    return [rows[i][0] for i in range(1, len(rows)) if rows[i][1] != rows[i - 1][1]]


def passes():
    rows = table('mpA-i1-passes.tsv')
    ends = pass_ends(rows)
    lens = [(ends[i], ends[i] - ends[i - 1]) for i in range(1, len(ends))]
    hist = Counter(n for _, n in lens)
    img = Image.new('RGB', (WIDTH, 470), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 6), 'Frames per main-loop pass, i1 frames %d-%d (%d passes, mean %.2f)' % (
        rows[0][0], rows[-1][0], len(lens), sum(n for _, n in lens) / len(lens)), font=F16B, fill=INK)
    # the histogram, left
    x0, y0, bw, hmax = 60, 60, 70, 300
    top = max(hist.values())
    for i, n in enumerate(sorted(hist)):
        h = hist[n] * hmax // top
        x = x0 + i * (bw + 20)
        d.rectangle((x, y0 + hmax - h, x + bw, y0 + hmax), fill=COL.get(n, GREY))
        d.text((x + 18, y0 + hmax - h - 18), str(hist[n]), font=F14B, fill=INK)
        d.text((x + 10, y0 + hmax + 6), '%d frames' % n, font=F13, fill=INK)
    d.text((x0, y0 + hmax + 26), 'passes of each length', font=F13, fill=GREY)
    # the passes over time, right: one dot a pass at (its end frame, its length)
    gx0, gx1, gy0, gy1 = 380, WIDTH - 20, 60, 360
    lo, hi = rows[0][0], rows[-1][0]
    d.rectangle((gx0, gy0, gx1, gy1), outline=GREY)
    for n in (6, 7, 8):
        y = gy1 - (n - 5) * (gy1 - gy0) // 4
        d.line((gx0, y, gx1, y), fill=(225, 225, 220))
        d.text((gx0 - 22, y - 8), str(n), font=F13, fill=INK)
    for f, n in lens:
        x = gx0 + (f - lo) * (gx1 - gx0) // (hi - lo)
        y = gy1 - (n - 5) * (gy1 - gy0) // 4
        d.rectangle((x - 1, y - 6, x + 1, y + 6), fill=COL.get(n, GREY))
    for f in range(1000, hi + 1, 1000):
        x = gx0 + (f - lo) * (gx1 - gx0) // (hi - lo)
        d.text((x - 16, gy1 + 6), str(f), font=F13, fill=INK)
    d.text((gx0, gy1 + 26), 'each pass at the frame it ended: its length in frames (i1 frame)', font=F13, fill=GREY)
    d.text((16, 420), 'FRAMES moved in every frame of the window: no interrupt lost in play. Read with TTD memory_at'
           ' at the end of each frame.', font=F13, fill=INK)
    d.text((16, 440), 'python3 work/docs/mpA-passes.py --work work/docs/mpA-i1 --from 300 --to 4700', font=F13,
           fill=GREY)
    out = os.path.join(OUT, 'passes.png')
    img.save(out)
    print(out, img.size)


# the bonus screen of sector E in i1: (first frame, last frame, label), from doc 04 4.4
PHASES = [(5177, 5188, 'page'), (5189, 5374, 'BonusTune: 22 BEEPER notes'),
          (5375, 5424, '50 HALTs'), (5425, 5449, 'BonusBeep x2'), (5450, 5499, '50 HALTs'),
          (5500, 5697, 'time bonus: 22 blips (5 frames DI, 4 HALTs)'),
          (5698, 5797, 'Wait100Frames'), (5798, 6024, 'BonusFlash: 25 x MenuDelay')]


def bonus():
    rows = table('mpA-i1-bonusE.tsv')
    lost = [rows[i][0] for i in range(1, len(rows)) if rows[i][2] == rows[i - 1][2]]
    lostset = set(lost)
    ends = pass_ends(rows)
    lo, hi = rows[1][0], rows[-1][0]
    per_row = 400
    nrows = (hi - lo + per_row) // per_row
    px = (WIDTH - 90) / per_row
    rh = 150
    img = Image.new('RGB', (WIDTH, 60 + nrows * rh + 50), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 6), 'The bonus screen of sector E, i1 frames %d-%d: %d frames lost their interrupt (red)' % (
        lo, hi, len(lost)), font=F16B, fill=INK)
    for r in range(nrows):
        f0 = lo + r * per_row
        y = 74 + r * rh
        for f in range(f0, min(f0 + per_row, hi + 1)):
            x = 70 + (f - f0) * px
            d.rectangle((x, y + 20, x + px - 0.2, y + 50), fill=(210, 50, 50) if f in lostset else (90, 170, 100))
            if f in ends:
                d.line((x, y + 14, x, y + 56), fill=INK, width=2)
            if f % 100 == 0:
                d.line((x, y + 52, x, y + 58), fill=INK)
                d.text((x - 16, y + 60), str(f), font=F13, fill=INK)
        d.text((8, y + 28), 'frame', font=F13, fill=GREY)
        for k, (a, b, label) in enumerate(PHASES):
            if b < f0 or a >= f0 + per_row:
                continue
            lift = 18 if k % 2 else 0
            xa = 70 + (max(a, f0) - f0) * px
            xb = 70 + (min(b, f0 + per_row - 1) - f0 + 1) * px
            d.line((xa, y + 8 - lift, xa, y + 14), fill=GREY)
            d.line((xa, y + 8 - lift, xb - 2, y + 8 - lift), fill=GREY, width=2)
            text = label
            while text and d.textlength(text, font=F13) > WIDTH - 4 - xa:
                text = text[:-1]
            d.text((xa + 2, y - 8 - lift), text, font=F13, fill=INK)
    ly = img.height - 52
    d.rectangle((16, ly + 2, 30, ly + 14), fill=(90, 170, 100))
    d.text((36, ly), 'interrupt taken (FRAMES moved)', font=F13, fill=INK)
    d.rectangle((300, ly + 2, 314, ly + 14), fill=(210, 50, 50))
    d.text((320, ly), 'interrupt lost (FRAMES unchanged)', font=F13, fill=INK)
    d.line((600, ly, 600, ly + 16), fill=INK, width=2)
    d.text((608, ly), 'a main-loop pass ended', font=F13, fill=INK)
    d.text((16, ly + 22), 'python3 work/docs/mpA-passes.py --work work/docs/mpA-i1 --from 5150 --to 6300', font=F13,
           fill=GREY)
    out = os.path.join(OUT, 'bonus-irq.png')
    img.save(out)
    print(out, img.size)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    for name, fn in [('passes', passes), ('bonus', bonus)]:
        if what in (name, 'all'):
            fn()

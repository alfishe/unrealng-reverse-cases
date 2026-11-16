#!/usr/bin/env python3
"""Doc 04's pass figure: the work of each pass against the 7-frame budget, one player and two.

    python3 tools/fig_passes.py docs/img/loop/passes.png [PASSES_JSON] [KB_CLOCK]

Top: the 600 passes of tools/pass_time.py (work/stage2/pass/passes.json: c1's play replayed from play.szx with the
keys set at each pass's start), the T-states from Pass `$D851` to the first WaitFrames `$D86B`, as a share of
7 x 69 888 T; the heaviest marked. Bottom: recording kb (two players), the frames between two changes of the clock
`$D6C9-$D6CB` (one change a pass, ClockTick), sampled at T 0 of every frame 240-7400 (work/docs/atA-kb-clock.txt,
written by work/docs/atA/sample.py); the clock is written at a different point of each pass, so a 7 can read as
6 + 8.
"""
import collections
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def font(n):
    try:
        return ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', n)
    except OSError:
        return ImageFont.load_default()


def main():
    out = sys.argv[1]
    passes = json.load(open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(CASE, 'work/stage2/pass/passes.json')))
    clock = sys.argv[3] if len(sys.argv) > 3 else os.path.join(CASE, 'work/docs/atA-kb-clock.txt')
    big, small = font(15), font(12)
    W, H = 1050, 700
    im = Image.new('RGB', (W, H), (22, 22, 30))
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'A pass is 7 frames while its work fits: one player always fits, two players often do not',
           fill=(240, 240, 240), font=big)
    # top panel
    x0, y0, pw, ph = 70, 60, 950, 250
    d.text((x0, y0 - 22), 'c1 replayed (tools/pass_time.py): the work of each of 600 passes, % of 7 x 69 888 T',
           fill=(220, 220, 220), font=small)
    for p in (0, 25, 50, 75, 100):
        y = y0 + ph - ph * p // 100
        d.line([x0, y, x0 + pw, y], fill=(60, 60, 75))
        d.text((x0 - 44, y - 7), '%d %%' % p, fill=(180, 180, 180), font=small)
    n = len(passes)
    top = max(passes, key=lambda q: q['T'])
    for i, q in enumerate(passes):
        x = x0 + i * pw // n
        y = y0 + ph - int(ph * q['percent'] / 100)
        col = (250, 120, 60) if q is top else ((120, 170, 250) if q['mounted'] else (120, 200, 120))
        d.line([x, y0 + ph, x, y], fill=col, width=1)
    tx = x0 + passes.index(top) * pw // n
    d.text((tx + 6, y0 + 2), "the replay's heaviest: c1 frame %d, %d T, %.1f %%" % (top['c1_frame'], top['T'], top['percent']),
           fill=(250, 140, 80), font=small)
    for i in range(0, n, 100):
        d.text((x0 + i * pw // n - 16, y0 + ph + 4), str(passes[i]['c1_frame']), fill=(170, 170, 170), font=small)
    d.text((x0, y0 + ph + 22), 'c1 frame of the pass (blue: mounted, green: on foot); least %.1f %%, mean %.1f %%' % (
        min(q['percent'] for q in passes), sum(q['T'] for q in passes) / n / 4892.16), fill=(200, 200, 200), font=small)
    # bottom panel: kb histogram
    rows = [l.split() for l in open(clock)]
    ch, prev = [], None
    for f, v in rows:
        if v != prev:
            ch.append(int(f))
            prev = v
    gaps = [b - a for a, b in zip(ch, ch[1:]) if b - a <= 20]
    c = collections.Counter(gaps)
    bx0, by0, bw, bh = 70, 400, 950, 230
    d.text((bx0, by0 - 22), 'kb (two players), frames 240-7400: frames between two clock ticks (one tick a pass), %d passes'
           % len(gaps), fill=(220, 220, 220), font=small)
    keys = list(range(5, 17))
    mx = max(c.values())
    colw = bw // len(keys)
    for k, v in enumerate(keys):
        cnt = c.get(v, 0)
        h = int((bh - 20) * cnt / mx)
        x = bx0 + k * colw
        d.rectangle([x + 8, by0 + bh - h, x + colw - 8, by0 + bh], fill=(120, 170, 250) if v <= 7 else (250, 120, 60))
        d.text((x + colw // 2 - 12, by0 + bh - h - 16), str(cnt), fill=(230, 230, 230), font=small)
        d.text((x + colw // 2 - 6, by0 + bh + 4), str(v), fill=(200, 200, 200), font=small)
    d.text((bx0, by0 + bh + 22), 'frames a pass (orange: the work ran past the 7th frame and the wait loop exits at once;',
           fill=(200, 200, 200), font=small)
    d.text((bx0, by0 + bh + 40), 'four of the 8s pair with the 6s, a sampling jitter)',
           fill=(200, 200, 200), font=small)
    im.save(out)
    print(out, im.size, sorted(c.items()))


if __name__ == '__main__':
    main()

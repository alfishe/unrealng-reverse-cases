#!/usr/bin/env python3
"""Doc 04: the main loop's passes over c1's play, from the execution hits of $E410 (after the pass's HALT) and $E3C9
(MainLoop's first instruction).

    python3 tools/fig_loop.py work/docs/rdA/c1-halts.txt docs/img/loop/passes.png

The input has one line per address: ADDR COUNT F:T F:T ... (find_last execute on c1, oldest first; made by
work/docs/rdA/hits.py). The top panel is the frames from one HALT return to the next; the bottom panel is where in
its frame each pass came back from the HALT (the interrupt handler's end) and where the next pass began.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, TEXT, DIM, FRAME = (24, 24, 30), (235, 235, 235), (170, 170, 180), (110, 110, 140)
FRAME_T = 70908
INT_T = 1846  # where the 128K's INT falls in kit's frame (beam_timeline: "the INT at frame T 1846")


def hits(path):
    out = {}
    for line in open(path):
        parts = line.split()
        out[parts[0]] = [tuple(int(v) for v in p.split(':')) for p in parts[2:]]
    return out


def main():
    src, png = sys.argv[1], sys.argv[2]
    h = hits(src)
    halts, loops = h['E410'], h['E3C9']
    W, left, right = 1050, 90, 20
    f0, f1 = halts[0][0], halts[-1][0]
    x = (lambda f: left + (f - f0) / (f1 - f0) * (W - left - right))
    f_t, f_l, f_s = K.font(24), K.font(17), K.font(15)
    top1, h1 = 110, 230
    top2, h2 = top1 + h1 + 90, 260
    H = top2 + h2 + 120
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'A pass takes 2 frames (25 Hz); longer only for scrolls, zone changes, deaths',
           fill=TEXT, font=K.font(21))
    d.text((12, 44), f'c1 frames {f0}-{f1}: {len(halts)} passes, from the hits of $E410 (after HALT) and $E3C9 '
           '(MainLoop).', fill=DIM, font=f_s)
    # panel 1: frames per pass, log-ish scale
    import math
    levels = [2, 3, 4, 8, 16, 32, 64, 161]
    ylev = (lambda v: top1 + h1 - (math.log2(v) - 1) / (math.log2(161) - 1) * h1)
    d.text((12, top1 - 30), 'frames from one pass to the next (log scale); green 2, yellow 3, red more', fill=TEXT, font=f_l)
    for L in levels:
        y = ylev(L)
        d.line([(left, y), (W - right, y)], fill=(45, 45, 55))
        d.text((left - 40, y - 9), f'{L}', fill=DIM, font=f_s)
    counts = {}
    for (fa, _), (fb, _) in zip(halts, halts[1:]):
        n = fb - fa
        counts[n] = counts.get(n, 0) + 1
        col = (120, 230, 120) if n == 2 else (240, 220, 80) if n == 3 else (250, 90, 70)
        y = ylev(n)
        d.ellipse((x(fa) - 3, y - 3, x(fa) + 3, y + 3), fill=col)
    notes = [(30721, 'scroll down'), (31172, 'zone 1 to 2'), (31296, 'lost INT'), (32512, 'zone'),
             (32717, 'death'), (32849, 'pause, 161')]
    for k, (f, lab) in enumerate(notes):
        d.text((x(f) - 20, top1 + h1 + 6 + 18 * (k % 2)), lab, fill=TEXT, font=f_s)
        d.line([(x(f), top1), (x(f), top1 + h1 + 4)], fill=(80, 80, 100))
    # panel 2: T within the frame
    d.text((12, top2 - 30), 'where in its frame: HALT returns (green) and the next pass starts (blue)', fill=TEXT,
           font=f_l)
    yt = (lambda t: top2 + h2 - t / FRAME_T * h2)
    for t in range(0, FRAME_T + 1, 10000):
        d.line([(left, yt(t)), (W - right, yt(t))], fill=(45, 45, 55))
        d.text((12, yt(t) - 9), f'{t:,} T'.replace(',', ' '), fill=DIM, font=f_s)
    d.line([(left, yt(INT_T)), (W - right, yt(INT_T))], fill=(250, 90, 70))
    d.text((left + 4, yt(INT_T) + 2), 'INT (T 1846)', fill=(250, 90, 70), font=f_s)
    for f, t in loops:
        if f0 <= f <= f1:
            d.point((x(f), yt(t)), fill=(110, 130, 240))
            d.point((x(f) + 1, yt(t)), fill=(110, 130, 240))
    for f, t in halts:
        d.point((x(f), yt(t)), fill=(120, 230, 120))
        d.point((x(f) + 1, yt(t)), fill=(120, 230, 120))
    for fr in range(31000, f1 + 1, 500):
        d.text((x(fr) - 22, top2 + h2 + 8), str(fr), fill=DIM, font=f_s)
    d.text((left, top2 + h2 + 30), 'c1 frame', fill=DIM, font=f_s)
    summary = ', '.join(f'{n} frames: {c}' for n, c in sorted(counts.items()))
    lines, line = [], ''
    for part in ('passes by length: ' + summary).split(' '):
        if d.textlength(line + ' ' + part, font=f_s) > W - 30:
            lines.append(line)
            line = part
        else:
            line = (line + ' ' + part).strip()
    lines.append(line)
    for i, ln in enumerate(lines):
        d.text((12, top2 + h2 + 56 + 20 * i), ln, fill=TEXT, font=f_s)
    img.save(png)
    print(png, img.size, summary)


if __name__ == '__main__':
    main()

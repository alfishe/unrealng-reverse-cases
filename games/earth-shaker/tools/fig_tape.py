#!/usr/bin/env python3
"""The covertape side as a picture (doc 3): every block of Side 1 on a time axis, Earth Shaker's blocks 9-13 picked
out, then those blocks to scale: pilot, data and pause, with their sizes, load addresses and times at ROM speed.

The times are counted from the blocks' own timings (tools/tzxblocks.py `seconds`: pilot pulses, syncs, two pulses a
bit at 3.5 MHz), the pauses from the TZX.

    python3 tools/fig_tape.py --out docs/img/load/tape.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import lab  # noqa: E402  (side_file: the side unpacked unchanged from orig/)
import tzxblocks as T  # noqa: E402

PROGRAMS = [(1, 7, 'Biggles, Timewarp, two headerless blocks', (110, 110, 140)),
            (9, 13, 'Earth Shaker', (250, 200, 60)),
            (15, 20, 'Switchblade (demo)', (110, 140, 110))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--width', type=int, default=1050)
    a = ap.parse_args()
    blocks = list(T.parse(open(lab.side_file(), 'rb').read()))
    W = a.width
    left, right = 20, 20
    H = 470
    img = Image.new('RGB', (W, H), (22, 22, 28))
    d = ImageDraw.Draw(img)
    fb, f, fs = K.font(15), K.font(12), K.font(11)
    d.text((left, 10), 'Your Sinclair 63, Side 1: Earth Shaker is TZX blocks 9-13, four ROM-speed blocks after a text '
           'block', fill=(235, 235, 235), font=fb)
    # the whole side
    t, spans = 0.0, []
    for b in blocks:
        s = T.seconds(b)
        p = b.get('pause', 0) / 1000.0
        spans.append((b['index'], t, t + s, t + s + p, b))
        t += s + p
    total = t
    sx = (W - left - right) / total
    y = 50
    d.text((left, y - 2), 'the whole side, %.1f s of signal and pauses' % total, fill=(200, 200, 200), font=f)
    y += 18
    for i0, i1, name, col in PROGRAMS:
        t0 = min(s[1] for s in spans if i0 <= s[0] <= i1)
        t1 = max(s[3] for s in spans if i0 <= s[0] <= i1)
        d.rectangle([left + t0 * sx, y, left + t1 * sx, y + 26], outline=col)
        d.text((left + t0 * sx + 3, y + 30), '%s (blocks %d-%d)' % (name, i0, i1), fill=col, font=fs)
    for idx, t0, t1, t2, b in spans:
        if t1 > t0:
            col = (250, 200, 60) if 10 <= idx <= 13 else (150, 150, 170)
            d.rectangle([left + t0 * sx, y + 4, max(left + t0 * sx + 1, left + t1 * sx), y + 22], fill=col)
    for s in range(0, int(total) + 1, 60):
        x = left + s * sx
        d.line([x, y + 50, x, y + 56], fill=(160, 160, 160))
        d.text((x - 8, y + 58), '%d s' % s, fill=(160, 160, 160), font=fs)
    # Earth Shaker to scale
    y = 170
    es = [s for s in spans if 10 <= s[0] <= 13]
    e0, e1 = es[0][1], es[-1][3]
    zx = (W - left - right) / (e1 - e0)
    d.text((left, y - 4), 'blocks 10-13 to scale: %.1f s of signal, %.1f s with the pauses' % (
        sum(s[2] - s[1] for s in es), e1 - e0), fill=(200, 200, 200), font=f)
    y += 20
    for idx, t0, t1, t2, b in es:
        tm = b['timing']
        pilot = (tm['pilot'] * tm['pilot_pulses'] + tm['sync1'] + tm['sync2']) / 3.5e6
        x0, xp, x1, x2 = (left + (v - e0) * zx for v in (t0, t0 + pilot, t1, t2))
        d.rectangle([x0, y, max(x0 + 2, xp), y + 30], fill=(120, 170, 250))
        d.rectangle([xp, y, max(xp + 2, x1), y + 30], fill=(250, 200, 60))
        d.rectangle([x1, y + 12, x2, y + 18], fill=(70, 70, 80))
    labels = [
        (10, 'header "EARTH": Program, 107 bytes, LINE 1', '19 bytes, 5.09 s, pause 1036 ms'),
        (11, 'the BASIC loader, one line', '109 bytes to $5CCB, 2.55 s, pause 4644 ms'),
        (12, 'header "EARTH": Bytes, 37566 at $6D42', '19 bytes, 5.09 s, pause 1033 ms'),
        (13, 'the whole game, $6D42-$FFFF', '37568 bytes, 204.09 s, pause 10570 ms'),
    ]
    ly = y + 48
    for k, (idx, l1, l2) in enumerate(labels):
        s = [x for x in es if x[0] == idx][0]
        x = left + (s[1] - e0) * zx
        lx = left + k * 250
        d.line([x + 1, y + 31, x + 1, ly + 6 + k * 0], fill=(200, 200, 200))
        d.line([x + 1, ly + 6, lx, ly + 6], fill=(200, 200, 200))
        d.text((lx, ly + 10), 'block %d: %s' % (idx, l1), fill=(235, 235, 235), font=fs)
        d.text((lx, ly + 26), l2, fill=(190, 190, 190), font=fs)
        ly += 44
    yk = ly + 16
    for i, (name, col) in enumerate([('pilot and syncs', (120, 170, 250)), ('data bits', (250, 200, 60)),
                                     ('pause (silence)', (70, 70, 80))]):
        x = left + i * 200
        d.rectangle([x, yk + 2, x + 14, yk + 14], fill=col)
        d.text((x + 20, yk), name, fill=(220, 220, 220), font=fs)
    d.text((left, yk + 24), 'Times from the blocks\' own timings (pilot 2168 T, bits 855 / 1710 T, 3.5 MHz) and the TZX '
           'pauses.', fill=(150, 150, 150), font=fs)
    d.text((left, yk + 40), 'Command: python3 tools/fig_tape.py --out docs/img/load/tape.png', fill=(150, 150, 150),
           font=fs)
    img = img.crop((0, 0, W, yk + 62))
    img.save(a.out)
    for idx, t0, t1, t2, b in spans:
        print(idx, b['kind'], '%.2f-%.2f-%.2f' % (t0, t1, t2))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 03 figure: when each 128K bank is filled during the load of side 1 in c1 (signal speed, play at frame 208).

    python3 tools/fig_load_timeline.py work/stage1/loadscan.json docs/img/load/load-timeline.png

loadscan.json: [frame, bank, bytes changed, first offset, last offset] per 250-frame sample (work/stage1/loadscan.py,
time_travel memory_at of every bank of c1). The tape blocks of side 1 are drawn above at their times from the TZX
timings (tools/tzxblocks.py), so a bank's bar sits under the block that fills it.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

PLAY = 208
W, H, X0, X1 = 900, 330, 70, 880
F0, F1 = 0, 24500


def x(f):
    return X0 + (f - F0) * (X1 - X0) / (F1 - F0)


def main():
    scan = json.load(open(sys.argv[1]))
    tzx = open(os.path.join(HERE, '..', 'work', 'stage1', 'media', 'side1.tzx'), 'rb').read()
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    d.text((X0, 4), 'Side 1 in c1: tape blocks (top) and the bytes each bank gains per 250 frames (bars)', fill='black')
    t = 0.0
    for b in tzxblocks.parse(tzx):
        s = tzxblocks.seconds(b) or 0
        data = b.get('data')
        if data is not None and len(data) > 100:
            f0, f1 = PLAY + t * 50, PLAY + (t + s) * 50
            d.rectangle([x(f0), 24, x(f1), 44], outline='black', fill='#cde')
            label = str(len(data))
            if x(f1) - x(f0) > 30:
                d.text((x(f0) + 3, 28), label, fill='black')
        t += s
    d.text((4, 28), 'blocks', fill='black')
    for n in range(8):
        y = 60 + n * 30
        d.text((4, y + 6), f'bank {n}', fill='black')
        d.line([X0, y + 24, X1, y + 24], fill='#ccc')
        for f, bank, count, _a, _b in scan:
            if bank != n or count < 50:
                continue
            h = min(22, 22 * count / 1100)
            d.rectangle([x(f - 250), y + 24 - h, x(f), y + 24], fill='#c33' if f >= 23974 else '#36a')
    for f in range(0, F1 + 1, 2000):
        d.line([x(f), 300, x(f), 304], fill='black')
        d.text((x(f) - 12, 306), str(f), fill='black')
    d.text((X0, 318), 'frame of c1; red: the bootstrap at $8000 (frame 23974) copies bank 1 to $8301-$BFFF and the loader rewrites $5C3C-$7FFF', fill='#c33')
    os.makedirs(os.path.dirname(sys.argv[2]), exist_ok=True)
    im.save(sys.argv[2])


if __name__ == '__main__':
    main()

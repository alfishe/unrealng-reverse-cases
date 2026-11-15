#!/usr/bin/env python3
"""Doc 9's figure of the sound's cost: the T-states of each frame split into NoiseBurst, TonePlayer and the chords,
the rest of the sound engine and everything else, from a traced window.

    python3 tools/fig_soundcost.py SPLIT.txt OUT.png [PASS_FRAME ...]

SPLIT.txt is the output of work/docs/rtC/tools/tsplit.py: a header line, then "frame noise tone engine other" a line
(the T from each instruction to the next, by the routine it belongs to). PASS_FRAME marks the frames where the main
loop's top `$8649` ran (a new pass).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1050, 520
FRAME = 69888
COLS = [('noise', (210, 50, 40), 'NoiseBurst $FA71-$FAAE'), ('tone', (60, 120, 200), 'TonePlayer and the chords'),
        ('engine', (240, 170, 40), 'the rest of the sound engine'), ('other', (200, 200, 200), 'everything else')]


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    src, out = sys.argv[1], sys.argv[2]
    passes = {int(x) for x in sys.argv[3:]}
    rows = []
    for line in open(src):
        p = line.split()
        if len(p) == 5 and p[0].isdigit():
            rows.append([int(x) for x in p])
    img = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(img)
    d.text((10, 10), f'l2 frames {rows[0][0]}-{rows[-1][0]}: where each frame\'s 69 888 T go', fill='black',
           font=font(17))
    d.text((10, 34), 'three small explosions (sound $08) hold all three channels: every interrupt spends about 31 000 T '
                     'in NoiseBurst', fill=(70, 70, 70), font=font(14))
    left, top, bottom = 80, 70, H - 110
    bw = (W - left - 20) / len(rows)
    for i, (f, *v) in enumerate(rows):
        x = left + i * bw
        y = bottom
        for (k, col, _), t in zip(COLS, v):
            h = (bottom - top) * t / FRAME
            d.rectangle([x + 3, y - h, x + bw - 3, y], fill=col)
            y -= h
        d.text((x + bw / 2 - 16, bottom + 4), str(f), fill='black', font=font(13))
        if v[0]:
            d.text((x + bw / 2 - 12, bottom - (bottom - top) * v[0] / FRAME / 2 - 8), f'{v[0] // 1000}k',
                   fill='white', font=font(13))
        if f in passes:
            d.polygon([(x + bw / 2, top - 2), (x + bw / 2 - 7, top - 14), (x + bw / 2 + 7, top - 14)], fill='black')
    for frac in (0, 0.25, 0.5, 0.75, 1):
        y = bottom - (bottom - top) * frac
        d.line([left - 6, y, left, y], fill='black')
        d.text((10, y - 8), f'{int(FRAME * frac)}', fill='black', font=font(13))
    d.text((left, bottom + 24), 'frame of l2 (a bar: the T-states of the frame, from its start)', fill='black',
           font=font(14))
    x = 10
    ly = bottom + 50
    for _, col, name in COLS:
        d.rectangle([x, ly, x + 14, ly + 14], fill=col)
        d.text((x + 18, ly - 1), name, fill='black', font=font(13))
        x += 40 + int(d.textlength(name, font=font(13)))
    d.polygon([(x + 7, ly + 14), (x, ly + 2), (x + 14, ly + 2)], fill='black')
    d.text((x + 18, ly - 1), 'a new pass (the main loop at $8649)', fill='black', font=font(13))
    img.save(out)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A first map of ATV Simulator's six trails from the data: the course record each trail's setup reads (`$EC9C`:
trails 1-4 at `$7C9C` + 6 n, trail 5 at `$EE84`, trail 6 at `$60AC`, the copy of `$F230`), and the two lists it
points at, drawn along the trail's distance.

    python3 tools/trail_map.py IMAGE.bin OUT.png       # IMAGE: a 64 K image in play (trail 6's record is copied)

The record: +0 list A (`$D6B6`), +2 list B (`$D6B8`), +4 the trail's length (the finish `$D6C0` is 72 less).
List A: 6-byte entries, distance, a word, a word, to `$FFFF` (the objects: the third word is a graphic or a type;
stage 3 names them). List B: 6-byte entries, distance and two words, to `$FFFF` (drawn as a step line of its first
word). The format is a first reading of the bytes; every field is to be confirmed by the code in stage 3.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

NAMES = ['SAND DUNING', 'GRASSTRAKIN', 'ICEBERGS', 'PYRAMIDS', 'TROPICANA', 'SWAMP']


def word(m, a):
    return m[a] | m[a + 1] << 8


def entries(m, a):
    out = []
    while word(m, a) != 0xFFFF and len(out) < 200:
        out.append((a, word(m, a), word(m, a + 2), word(m, a + 4)))
        a += 6
    return out


def main():
    m = open(sys.argv[1], 'rb').read()
    recs = [0x7C9C + 6 * n for n in range(4)] + [0xEE84, 0x60AC]
    W, LEFT, H = 1050, 150, 150
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 12)
        big = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 14)
    except OSError:
        font = big = ImageFont.load_default()
    im = Image.new('RGB', (W, 40 + H * 6), (24, 24, 32))
    dr = ImageDraw.Draw(im)
    dr.text((10, 10), 'ATV Simulator: the six trails from their course records (distance left to right, 0 to the length)',
            fill=(230, 230, 230), font=big)
    for t, r in enumerate(recs):
        la, lb, ln = word(m, r), word(m, r + 2), word(m, r + 4)
        y0 = 40 + t * H
        sc = (W - LEFT - 20) / max(ln, 1)
        dr.text((10, y0 + 10), f'{t + 1} {NAMES[t]}', fill=(230, 220, 120), font=big)
        dr.text((10, y0 + 30), f'record ${r:04X}', fill=(200, 200, 200), font=font)
        dr.text((10, y0 + 46), f'A ${la:04X}  B ${lb:04X}', fill=(200, 200, 200), font=font)
        dr.text((10, y0 + 62), f'length {ln} (${ln:04X})', fill=(200, 200, 200), font=font)
        base = y0 + H - 22
        dr.line([LEFT, base, LEFT + ln * sc, base], fill=(90, 90, 110))
        fx = LEFT + (ln - 72) * sc
        dr.line([fx, y0 + 8, fx, base], fill=(220, 80, 80))
        dr.text((fx + 3, y0 + 8), 'finish', fill=(220, 80, 80), font=font)
        b = entries(m, lb)
        pts = []
        for i, (_a, x, v, _w) in enumerate(b):
            nx = b[i + 1][1] if i + 1 < len(b) else ln
            yy = base - (v & 0xFF) * 1.2
            pts += [(LEFT + x * sc, yy), (LEFT + nx * sc, yy)]
        if pts:
            dr.line(pts, fill=(110, 200, 120), width=2)
        for i, (_a, x, v, k) in enumerate(entries(m, la)):
            px = LEFT + x * sc
            yy = base - 70 - (i % 3) * 14
            dr.line([px, yy + 12, px, base], fill=(120, 160, 230))
            dr.text((px + 2, yy), f'{k:X}', fill=(150, 190, 250), font=font)
    im.save(sys.argv[2])
    print(im.size)


if __name__ == '__main__':
    main()

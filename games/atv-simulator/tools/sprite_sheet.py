#!/usr/bin/env python3
"""A first sprite sheet of ATV Simulator from the data: every graphic the sprite entry `$865F` was given in the play
recordings (the L1 `patterns` record of `$865F`: HL's bases), drawn from the image as the loader leaves it.

    python3 tools/sprite_sheet.py IMAGE.bin OUT.png L1 [L1 ...]

A graphic is a header and its lines (`$865F`): +0 the width in bytes (`$80F2`), +1 the height in lines (`$80F3`), +2 a
byte kept in `$80F6`, +3 the pixel shift the data is in now (`$80F4` points at it: `$8759` / `$8777` shift the data
in place to the shift the drawing needs, so the image as loaded holds each graphic at its first shift), +4 the bytes,
width × height, a line at a time; `$8D53` ORs them into the play buffer (22 bytes a line). Each graphic is drawn at
2x with its address; headers outside 1-8 bytes wide or 1-96 lines high are left out (bases that are not headers).
"""
import json
import sys

from PIL import Image, ImageDraw, ImageFont


def main():
    img = open(sys.argv[1], 'rb').read()
    bases = set()
    for path in sys.argv[3:]:
        d = json.load(open(path))
        idx = {r['entry']: i for i, r in enumerate(d['routines'])}
        for p in d['patterns']:
            if p['routine'] == idx.get('$865F'):
                bases.update(int(b[1:], 16) for b in p['bases'])
    items = []
    for a in sorted(bases):
        w, h = img[a], img[a + 1]
        if 1 <= w <= 8 and 1 <= h <= 96:
            items.append((a, w, h))
    S, PAD, W = 2, 10, 1050
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 13)
    except OSError:
        font = ImageFont.load_default()
    x = y = PAD
    row_h = 0
    places = []
    for a, w, h in items:
        cw, ch = max(w * 8 * S, 52), h * S + 18
        if x + cw > W - PAD:
            x, y = PAD, y + row_h + PAD
            row_h = 0
        places.append((a, w, h, x, y))
        x += cw + PAD
        row_h = max(row_h, ch)
    im = Image.new('RGB', (W, y + row_h + PAD), (24, 24, 32))
    dr = ImageDraw.Draw(im)
    for a, w, h, x, y in places:
        dr.text((x, y), f'${a:04X}', fill=(230, 220, 120), font=font)
        dr.rectangle([x - 1, y + 17, x + w * 8 * S, y + 18 + h * S], outline=(70, 70, 90))
        for r in range(h):
            for k in range(w):
                v = img[a + 4 + r * w + k]
                for b in range(8):
                    if v & (0x80 >> b):
                        px, py = x + (k * 8 + b) * S, y + 18 + r * S
                        dr.rectangle([px, py, px + S - 1, py + S - 1], fill=(255, 255, 255))
    im.save(sys.argv[2])
    print(len(items), 'graphics of', len(bases), 'bases;', im.size)
    for a, w, h, _x, _y in places:
        print(f'${a:04X} {w}x{h} flags ${img[a + 2]:02X} shift {img[a + 3]}')


if __name__ == '__main__':
    main()

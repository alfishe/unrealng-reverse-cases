#!/usr/bin/env python3
"""The memory heatmap of a recording for a 900 px page (docs/02-architecture.md 2.3): one composite map of
16K-64K, red what was written, green read, blue executed (log2 of the counts, as kit/heatmap.py), 256 bytes a row
(2 x 3 pixels a byte), with the regions of tools/heatmap-regions.txt named beside it.

    python3 tools/fig_heatmap.py work/f1/l1.json docs/img/arch/heatmap.png [--title TEXT]

The counts come from the L1 build's byte counts (kit/heatmap.py's load). A region's label sits at its rows; labels
that would collide are pushed down and joined to their rows by a line.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import heatmap as H  # noqa: E402
import kitlib as K  # noqa: E402

LO, HI, CELL = 0x4000, 0xFFFF, 3     # a row of 256 bytes is 512 x 3 pixels


def regions(path):
    out = []
    for line in open(path):
        if line.strip() and not line.startswith('#'):
            a, b, name = line.split(None, 2)
            out.append((int(a, 16), int(b, 16), name.strip()))
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('l1')
    p.add_argument('out')
    p.add_argument('--regions', default=os.path.join(HERE, 'heatmap-regions.txt'))
    p.add_argument('--title', default='')
    a = p.parse_args()
    ex, rd, wr, _last, _replay = H.load(a.l1, H.BASES_48K)
    se, _ = H.scale(ex, LO, HI)
    sr, _ = H.scale(rd, LO, HI)
    sw, _ = H.scale(wr, LO, HI)

    def colour(adr):
        r, g, b = sw(adr), sr(adr), se(adr)
        if not (r or g or b):
            return (12, 12, 16)
        return (int(40 + 215 * r) if r else 0, int(40 + 215 * g) if g else 0, int(40 + 215 * b) if b else 0)

    pic = H.panel(LO, HI, 1, colour)
    pic = pic.resize((512, pic.height * CELL), Image.NEAREST)
    f12, f13, f17 = K.font(12), K.font(13), K.font(17)
    top, left = 40, 54
    W = 900
    im = Image.new('RGB', (W, top + pic.height + 34), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((8, 8), a.title, fill=K.TEXT, font=f17)
    im.paste(pic, (left, top))
    for adr in range(LO, HI + 1, 0x1000):
        y = top + ((adr - LO) >> 8) * CELL
        d.text((4, y - 6), '$%04X' % adr, fill=K.DIM, font=f12)
        d.line((left - 4, y, left - 1, y), fill=K.DIM)
    # the labels, pushed apart
    lx = left + pic.width + 40
    want = []
    for s, e, name in regions(a.regions):
        if e < LO:
            continue
        y0, y1 = top + ((max(s, LO) - LO) >> 8) * CELL, top + ((e - LO) >> 8) * CELL + CELL
        want.append([(y0 + y1) / 2, y0, y1, name])
    y = top
    for w in want:
        w.append(max(w[0] - 7, y))
        y = w[4] + 15
    over = y - (top + pic.height + 10)
    if over > 0:                                  # squeeze back up from the bottom
        y = top + pic.height + 10
        for w in reversed(want):
            w[4] = min(w[4], y - 15)
            y = w[4]
    for mid, y0, y1, name, ly in want:
        x0 = left + pic.width + 4
        d.line((x0, y0, x0, y1 - 1), fill=K.DIM)
        d.line((x0, mid, x0 + 14, mid, lx - 4, ly + 7), fill=(70, 70, 82))
        d.text((lx, ly), name[:40], fill=K.TEXT, font=f12)
    ly = im.height - 24
    lx = 8
    for c, t in (((255, 40, 40), 'written'), ((40, 255, 40), 'read'), ((60, 60, 255), 'executed'),
                 ((255, 255, 40), 'read and written'), ((255, 255, 255), 'all three')):
        d.rectangle((lx, ly + 2, lx + 12, ly + 14), fill=c)
        d.text((lx + 17, ly), t, fill=K.DIM, font=f13)
        lx += 34 + int(d.textlength(t, font=f13))
    d.text((lx + 10, ly), 'brightness: log2 of the count', fill=K.DIM, font=f13)
    im.save(a.out)
    print('wrote', a.out, im.size)


if __name__ == '__main__':
    main()

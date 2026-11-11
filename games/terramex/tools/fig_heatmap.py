#!/usr/bin/env python3
"""Doc 02 2.2: the memory heatmap of every stage 1 recording, as four panels in a 2 x 2 grid, readable at 900 px.

The counts and the colours are those of kit/heatmap.py (its load, scale, heat, panel and screen_view); only the layout
and the label sizes are this case's: executed and read on the first row, written and the composite on the second,
each with its own address axis and the screen page as an inset below it (the bitmap where it shows, the
attributes as their cells).

    python3 tools/fig_heatmap.py work/stage1/l1-all.json work/heatmap.png   (doc 02 uses tools/fig_arch.py heatmap)
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import heatmap as H  # noqa: E402
import kitlib as K  # noqa: E402

BG, TEXT, DIM, FRAME = (24, 24, 30), (235, 235, 235), (170, 170, 180), (110, 110, 140)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--cell', type=int, default=2)
    a = p.parse_args()
    lo, hi, cell = 0x4000, 0xFFFF, a.cell
    executes, reads, writes, _last, _replay = H.load(a.l1, H.BASES_48K)
    fx, tx = H.scale(executes, lo, hi)
    fr, tr = H.scale(reads, lo, hi)
    fw, tw = H.scale(writes, lo, hi)
    comp = (lambda q: (int(255 * fw(q)), int(255 * fr(q)), int(255 * fx(q))))
    panels = [('executed', lambda q: H.heat(fx(q)), f'max {tx:,} per byte'.replace(',', ' ')),
              ('read', lambda q: H.heat(fr(q)), f'max {tr:,} per byte'.replace(',', ' ')),
              ('written', lambda q: H.heat(fw(q)), f'max {tw:,} per byte'.replace(',', ' ')),
              ('red written, green read, blue executed', comp, 'each channel log2 of its count')]
    f_title, f_name, f_axis, f_note = K.font(26), K.font(22), K.font(17), K.font(16)
    axis_w, gap, top = 78, 34, 92
    grid_w, grid_h = 256 * cell, ((hi - lo) // 256 + 1) * cell
    inset_scale = 1
    inset_h = 192 * inset_scale + 4
    cell_w = axis_w + grid_w + 10
    cell_h = 34 + grid_h + 34 + 24 + inset_h + 26
    w = 2 * cell_w + gap + 20
    h = top + 2 * cell_h + gap + 40
    out = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(out)
    d.text((14, 12), 'Memory use over every stage 1 recording (L1 counts, $4000-$FFFF)', fill=TEXT, font=f_title)
    d.text((14, 50), 'One row a page of 256 bytes, $4000 at the top; colour = log2 of the count. Below each grid: '
           'the screen page as the screen.', fill=DIM, font=f_note)
    for i, (name, colour, note) in enumerate(panels):
        ox = 10 + (i % 2) * (cell_w + gap)
        oy = top + (i // 2) * (cell_h + gap)
        d.text((ox + axis_w, oy), name, fill=TEXT, font=f_name)
        gx, gy = ox + axis_w, oy + 34
        out.paste(H.panel(lo, hi, cell, colour), (gx, gy))
        d.rectangle((gx - 1, gy - 1, gx + grid_w, gy + grid_h), outline=FRAME)
        for q in range(lo, hi + 1, 0x1000):
            y = gy + ((q - lo) >> 8) * cell
            d.text((ox + 2, y - 9), f'${q:04X}', fill=DIM, font=f_axis)
            d.line([(gx - 8, y), (gx - 2, y)], fill=FRAME)
        d.text((gx, gy + grid_h + 6), note, fill=DIM, font=f_note)
        sy = gy + grid_h + 34
        d.text((gx, sy), '$4000-$57FF as the screen, $5800-$5AFF as the cells', fill=DIM, font=f_note)
        out.paste(H.screen_view(colour, inset_scale), (gx, sy + 24))
    out.save(a.png)
    print(a.png, out.size)


if __name__ == '__main__':
    main()

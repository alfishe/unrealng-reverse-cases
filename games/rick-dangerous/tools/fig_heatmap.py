#!/usr/bin/env python3
"""Doc 02: the memory heatmap of the merged L1 counts, four panels in two rows, readable at 900 px.

The counts and the colour scale are kit/heatmap.py's (load, scale, heat, panel). The layout is this case's: two grids a
row with the region names between them as their shared axis, then a strip of RAM 1 (the music on a 128K), drawn from
its read and write counts (the L1 file holds no per-byte executions for a paged bank, only their total).

    python3 tools/fig_heatmap.py work/docs/rdA/l1-all.json docs/img/heatmap.png
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import heatmap as H  # noqa: E402
import kitlib as K  # noqa: E402

BG, TEXT, DIM, FRAME = (24, 24, 30), (235, 235, 235), (170, 170, 180), (110, 110, 140)

REGIONS = [
    (0x4000, 0x57FF, 'screen bitmap'),
    (0x5800, 0x5AFF, 'attributes'),
    (0x5B00, 0x6DFF, 'mirror, sprite work'),
    (0x6E00, 0x70FF, 'cell flags'),
    (0x7100, 0x82FF, 'char sets'),
    (0x8300, 0x8400, 'IM 2 table'),
    (0x8401, 0x9E94, 'sprite frames'),
    (0x9E95, 0x9FEC, 'font'),
    (0x9FED, 0xAF63, 'code: sound..HUD'),
    (0xAF64, 0xE218, 'level data'),
    (0xE219, 0xE4AD, 'menu, main loop'),
    (0xE4AE, 0xEA8D, 'levels, texts'),
    (0xEA8E, 0xEBFF, 'object table'),
    (0xEC00, 0xFD7C, 'code: objects, Rick'),
    (0xFD7D, 0xFFFF, 'spawn, handler'),
]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('l1')
    p.add_argument('png')
    p.add_argument('--width', type=int, default=1050)
    a = p.parse_args()
    lo, hi, cell = 0x4000, 0xFFFF, 2
    executes, reads, writes, _last, _replay = H.load(a.l1, H.BASES_48K)
    doc = json.load(open(a.l1))
    frames = doc['replay'].get('frames', 0)
    fx, tx = H.scale(executes, lo, hi)
    fr, tr = H.scale(reads, lo, hi)
    fw, tw = H.scale(writes, lo, hi)
    comp = (lambda q: (int(255 * fw(q)), int(255 * fr(q)), int(255 * fx(q))))
    num = (lambda v: f'{v:,}'.replace(',', ' '))
    panels = [('executed', lambda q: H.heat(fx(q)), f'max {num(tx)} per byte'),
              ('read', lambda q: H.heat(fr(q)), f'max {num(tr)} per byte'),
              ('written', lambda q: H.heat(fw(q)), f'max {num(tw)} per byte'),
              ('red written, green read, blue run', comp, 'each channel log2 of its count')]
    f_title, f_name, f_lab, f_note = K.font(30), K.font(24), K.font(20), K.font(20)
    grid_w, grid_h = 256 * cell, ((hi - lo) // 256 + 1) * cell
    mid, top, row_gap = 290, 104, 70
    w = 10 + grid_w + mid + grid_w + 10
    ram1_rows = 14
    h = top + 2 * (40 + grid_h + 34) + row_gap + 60 + ram1_rows * 6 + 30
    out = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(out)
    d.text((12, 10), 'Where Rick Dangerous spends its memory: every byte, every recording', fill=TEXT, font=f_title)
    d.text((12, 54), f'48 L1 builds merged ({num(frames)} frames). One row = 256 bytes, $4000 at the top; '
           'colour = log2 of the count.', fill=DIM, font=f_note)
    for i, (name, colour, note) in enumerate(panels):
        gx = 10 if i % 2 == 0 else 10 + grid_w + mid
        oy = top + (i // 2) * (40 + grid_h + 34 + row_gap)
        d.text((gx, oy), name, fill=TEXT, font=f_name)
        gy = oy + 40
        out.paste(H.panel(lo, hi, cell, colour), (gx, gy))
        d.rectangle((gx - 1, gy - 1, gx + grid_w, gy + grid_h), outline=FRAME)
        d.text((gx, gy + grid_h + 6), note, fill=DIM, font=f_note)
        if i % 2 == 0:  # the shared axis: region names between the two grids
            mx = 10 + grid_w
            wanted = [gy + ((r0 + r1) // 2 - lo) // 256 * cell - 11 for r0, r1, _ in REGIONS]
            ys = H.spread(wanted, 24, gy - 4)
            for (r0, r1, label), y, want in zip(REGIONS, ys, wanted):
                y0, y1 = gy + ((r0 - lo) >> 8) * cell, gy + ((r1 - lo) >> 8) * cell + cell - 1
                d.line([(mx + 3, y0), (mx + 3, y1)], fill=FRAME, width=3)
                d.line([(mx + mid - 4, y0), (mx + mid - 4, y1)], fill=FRAME, width=3)
                d.text((mx + 12, y), f'${r0:04X} {label}', fill=TEXT, font=K.font(17))
    # RAM 1: the music image at $C000-$CDFF, read and written (paged executions are a total only)
    ram1 = [pg for pg in doc['byte_counts'] if pg['page'] == 1][0]
    r1r, r1w = ram1['reads'], ram1['writes']
    mr, mw = max(r1r) or 1, max(r1w) or 1
    import math
    oy = top + 2 * (40 + grid_h + 34) + row_gap
    paged = doc.get('paged_executions', {}).get('1', 0)
    d.text((10, oy), f'RAM 1 $C000-$CDFF (128K music): red written, green read. '
           f'{num(paged)} instructions ran there (a total only)', fill=TEXT, font=K.font(19))
    gy = oy + 34
    sc = 4
    strip = Image.new('RGB', (256 * sc, ram1_rows * 6), (12, 12, 16))
    px = strip.load()
    for i in range(ram1_rows * 256):
        rr = math.log2(r1r[i] + 1) / math.log2(mr + 1) if r1r[i] else 0
        ww = math.log2(r1w[i] + 1) / math.log2(mw + 1) if r1w[i] else 0
        c = (int(255 * ww), int(255 * rr), 0) if (rr or ww) else (12, 12, 16)
        for dx in range(sc):
            for dy in range(6):
                px[(i & 255) * sc + dx, (i >> 8) * 6 + dy] = c
    strip = strip.resize((w - 20 - 80, ram1_rows * 6), Image.NEAREST)
    out.paste(strip, (90, gy))
    d.rectangle((89, gy - 1, 90 + strip.width, gy + strip.height), outline=FRAME)
    d.text((10, gy - 4), '$C000', fill=DIM, font=K.font(18))
    d.text((10, gy + strip.height - 20), '$CD00', fill=DIM, font=K.font(18))
    if out.width != a.width:
        out = out.resize((a.width, round(out.height * a.width / out.width)), Image.LANCZOS)
    os.makedirs(os.path.dirname(a.png) or '.', exist_ok=True)
    out.save(a.png)
    print(a.png, out.size)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 02 figure: the eight 128K banks as heatmaps of the L1 builds of the recordings, summed.

    python3 tools/fig_heatmap128.py docs/img/arch/heatmap-banks.png work/stage1/rec/menu/l1.json ...

Each bank is 64 rows of 256 bytes (offset 0 top left), 1.6 px a byte. Colour: red = written, green = read,
blue = executed, each channel log2 of the summed count scaled to the largest (kit/heatmap.py's convention). The
counts are per physical page (L1 `byte_counts`, `instructions` page), so a bank is the same whichever slot it was
paged into. ROM writes and the loader's stages count too when c1 is given.
"""
import json
import math
import sys

from PIL import Image, ImageDraw

S = 1.6
TITLES = {0: 'bank 0 ($C000): code, mission block $DBC5-$FB3E', 1: 'bank 1: staging copy of $8301-$BFFF (load only)',
          2: 'bank 2 ($8000): main code, IM 2 table, stack, 3D buffer', 3: 'bank 3 ($C000)',
          4: 'bank 4 ($C000): catalogue $CB64-$E737', 5: 'bank 5 ($4000): screen, variables, code $5B00-$7FFF',
          6: 'bank 6 ($C000): stores, menus', 7: 'bank 7 ($C000)'}


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    r = {n: [0] * 16384 for n in range(8)}
    w = {n: [0] * 16384 for n in range(8)}
    x = {n: [0] * 16384 for n in range(8)}
    for p in paths:
        d = json.load(open(p))
        for page in d['byte_counts']:
            n = page['page']
            if n > 7:
                continue
            for i in range(16384):
                r[n][i] += page['reads'][i]
                w[n][i] += page['writes'][i]
        for z80, n, code, _c, count, *_ in d['instructions']:
            if n > 7:
                continue
            off = int(z80[1:], 16) & 0x3FFF
            for i in range(len(code) // 2):
                if off + i < 16384:
                    x[n][off + i] += count
    def scale(t):
        top = max(max(v) for v in t.values()) or 1
        lt = math.log2(top + 1)
        return lambda v: int(255 * math.log2(v + 1) / lt) if v else 0
    sr, sw, sx = scale(r), scale(w), scale(x)
    bw, bh = int(256 * S), int(64 * S)
    W, H = 2 * bw + 60, 4 * (bh + 34) + 40
    im = Image.new('RGB', (W, H), 'white')
    dr = ImageDraw.Draw(im)
    dr.text((10, 6), 'Battle Command: the 128K banks over the stage 1 recordings (red written, green read, blue executed)',
            fill='black')
    for n in range(8):
        col, row = n % 2, n // 2
        ox, oy = 20 + col * (bw + 20), 30 + row * (bh + 34)
        tile = Image.new('RGB', (256, 64))
        px = tile.load()
        for i in range(16384):
            px[i % 256, i // 256] = (sw(w[n][i]), sr(r[n][i]), sx(x[n][i]))
        im.paste(tile.resize((bw, bh), Image.NEAREST), (ox, oy + 14))
        dr.text((ox, oy), TITLES[n], fill='black')
        dr.rectangle([ox - 1, oy + 13, ox + bw, oy + 14 + bh], outline='#888')
    dr.text((10, H - 18), 'Rows are 256 bytes; offset +0000 at the top left of each bank, +3F00 the last row.',
            fill='black')
    im.save(out)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 02 figure: the play memory of the '99 as one composite heatmap (docs/img/arch/heatmap-play.png).

kit/heatmap.py's composite panel alone, at a size readable at ~900 px: $4000-$FFFF, one row per 256 bytes, each
byte a 2 x 2 square; red = written, green = read, blue = executed, each channel log2 of the count over the whole
recording (crit-play: r-critical replayed from the start-up menu at frame 2661 to 12102). The regions of
tools/zsa_regions99.txt are bracketed on the right. The pages are the Pentagon's at play: 5 at $4000, 2 at $8000,
0 at $C000 (kit/heatmap.py's load).

    python3 tools/fig_zs_heatmap.py --l1 work/stage2/game99/crit-play/l1.json --out docs/img/arch/heatmap-play.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import heatmap as H  # noqa: E402
from fig_common import font  # noqa: E402

BG, FG, DIM = (21, 22, 27), (230, 230, 230), (170, 174, 186)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--l1', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--cell', type=int, default=2)
    a = ap.parse_args()
    ex, rd, wr, _, replay = H.load(a.l1, H.BASES_48K)
    lo, hi, cell = 0x4000, 0xFFFF, a.cell
    se, _ = H.scale(ex, lo, hi)
    sr, _ = H.scale(rd, lo, hi)
    sw, _ = H.scale(wr, lo, hi)
    img = H.panel(lo, hi, cell, lambda x: (int(255 * sw(x)), int(255 * sr(x)), int(255 * se(x))))
    regions = [l.split(None, 2) for l in open(os.path.join(HERE, 'zsa_regions99.txt')) if l.strip()]
    left, top, label_w = 70, 70, 330
    out = Image.new('RGB', (left + img.width + label_w, top + img.height + 50), BG)
    d = ImageDraw.Draw(out)
    f, fs = font(15), font(12)
    d.text((10, 8), f"r-critical, {replay['frames']} frames: code (blue) only in $A600-$D6A7, writes (red) in the "
           "screen and the view buffer,", fill=FG, font=f)
    d.text((10, 28), "reads (green) of a few sprite rows, the radar layers and the map", fill=FG, font=f)
    out.paste(img, (left, top))
    for row in range(0, (hi - lo + 1) // 256, 16):
        y = top + row * cell
        d.text((8, y - 6), f'${lo + 256 * row:04X}', fill=DIM, font=fs)
        d.line([(left - 6, y), (left - 1, y)], fill=DIM)
    x = left + img.width + 8
    last_y = -100
    for i, (s, e, name) in enumerate(regions):
        s, e = int(s, 16), int(e, 16)
        y0, y1 = top + ((s - lo) >> 8) * cell, top + (((e - lo) >> 8) + 1) * cell - 1
        d.line([(x, y0), (x + 5, y0), (x + 5, y1), (x, y1)], fill=DIM)
        ty = max((y0 + y1) // 2 - 7, last_y + 15)
        last_y = ty
        d.text((x + 10, ty), f'${s:04X} {name.strip()}', fill=FG, font=fs)
    ly = top + img.height + 14
    for colour, name in (((255, 0, 0), 'written'), ((0, 255, 0), 'read'), ((0, 0, 255), 'executed'),
                         ((255, 255, 0), 'read + written'), ((0, 255, 255), 'read + executed')):
        d.rectangle([left, ly, left + 14, ly + 14], fill=colour)
        d.text((left + 20, ly), name, fill=FG, font=fs)
        left += 40 + int(d.textlength(name, font=fs))
    d.text((left + 10, ly), '(log2 of each count, over the whole recording)', fill=DIM, font=fs)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    out.save(a.out)
    print(a.out, out.size)


if __name__ == '__main__':
    main()

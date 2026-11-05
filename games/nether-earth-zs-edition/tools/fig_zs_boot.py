#!/usr/bin/env python3
"""Doc 03 figure: the '99 from the disk to the start-up menu, on r99's frames (docs/img/load/boot99.png).

The events are the code arrivals of r99 (`re_session.py stages --work work/stage1/r99`, from its l1.json: the first
frame an address range ran) and the script's one key (SPACE at 1310, inputs/r99-128.txt); the screens above the
axis are r99's own at the frames marked, read with TTD memory_at from the re_session instance of --work.

    python3 tools/fig_zs_boot.py --work work/docs/zsA/r99 --out docs/img/load/boot99.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402
import zxscreen  # noqa: E402
from fig_common import font  # noqa: E402

EVENTS = [(152, 'BASIC reader $5D5B'), (177, 'stage 2 read to $8000, depacker $5B00'),
          (227, 'stage 2 runs at $61A8'), (261, 'music $C000 + IM 2 $6525'), (464, 'RLE decoder $7D87'),
          (472, 'picture rolls in'), (746, 'scroller'), (1310, 'SPACE'), (2179, 'stage 3 unpacked over stage 2'),
          (2299, 'game block at $6780 unpacks'), (2545, 'patches $DC00'), (2561, 'menu block $E800, page 1'),
          (2659, 'stub $6700 copies the menu'), (2661, 'menu at $D800')]
SHOTS = [102, 600, 1002, 1600, 2300, 2652, 3002]
BG, FG, DIM = (21, 22, 27), (230, 230, 230), (184, 188, 200)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    s = Z.session(a.work)
    tw, th = 192, 144
    pad, head = 14, 60
    width = pad * 2 + len(SHOTS) * (tw + 8)
    axis_y = head + th + 60
    out = Image.new('RGB', (width, axis_y + 40 + 15 * 16), BG)
    d = ImageDraw.Draw(out)
    f, fs = font(17), font(12)
    d.text((pad, 8), "The '99 from the disk to the start-up menu: 1310 frames of intro wait for SPACE, then stage 3 "
           "loads,", fill=FG, font=f)
    d.text((pad, 30), "unpacks and pages in the rest in 1350 frames (r99, Pentagon 128, frames from the reset)",
           fill=FG, font=f)
    f0, f1 = 0, 3050
    x0, x1 = pad + 10, width - pad - 10
    xs = lambda fr: x0 + (fr - f0) * (x1 - x0) / (f1 - f0)
    for i, fr in enumerate(SHOTS):
        img = zxscreen.render(Z.memory_at(s, fr, 0, 0x4000, 0x1B00), 1).convert('RGB').resize((tw, th))
        x = pad + i * (tw + 8)
        out.paste(img, (x, head))
        d.text((x, head + th + 4), f'frame {fr}', fill=DIM, font=fs)
        d.line([x + tw // 2, head + th + 20, xs(fr), axis_y], fill=(110, 110, 130))
    d.line([x0, axis_y, x1, axis_y], fill=FG, width=2)
    for fr in range(0, f1 + 1, 500):
        d.line([xs(fr), axis_y - 4, xs(fr), axis_y + 4], fill=FG)
        d.text((xs(fr) - 12, axis_y + 6), str(fr), fill=DIM, font=fs)
    for k, (fr, label) in enumerate(EVENTS):
        y = axis_y + 26 + k * 16
        colour = (240, 120, 90) if label == 'SPACE' else (217, 164, 65)
        d.line([xs(fr), axis_y, xs(fr), y + 7], fill=colour)
        d.text((xs(fr) + 4, y), f'{fr} {label}', fill=FG, font=fs)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    out.save(a.out)
    print(a.out, out.size)


if __name__ == '__main__':
    main()

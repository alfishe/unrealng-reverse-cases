#!/usr/bin/env python3
"""A contact sheet of a recording's screen at chosen frames (memory_at at each frame's start), each labelled with
its frame: for finding moments, not a document figure.

    python3 tools/sheet.py --work work/runs/i1 --out work/stage1/i1-sheet.png 500 1500 2500 [--cols 6]
"""
import argparse

from PIL import Image, ImageDraw

import mplib as M


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--cols', type=int, default=6)
    p.add_argument('frames', nargs='+', type=int)
    args = p.parse_args()
    s = M.session(args.work)
    n = len(args.frames)
    rows = (n + args.cols - 1) // args.cols
    sheet = Image.new('RGB', (args.cols * 260, rows * 206), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(args.frames):
        img = M.K.render_screen(M.read(s, f, 0x4000, 0x1B00), 0)
        x, y = (i % args.cols) * 260, (i // args.cols) * 206
        sheet.paste(img, (x + 2, y + 12))
        d.text((x + 4, y), str(f), fill=(255, 255, 0))
    sheet.save(args.out)
    print(args.out)


if __name__ == '__main__':
    main()

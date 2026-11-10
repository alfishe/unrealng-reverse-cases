#!/usr/bin/env python3
"""A sheet of screenshots in two columns, 1050 px wide, each with a caption line under it (doc 01's key moments).

    python3 tools/fig_moments.py OUT.png --title TEXT SHOT.png="caption" [SHOT.png="caption" ...]

Each SHOT is a 512 x 384 screen as kit/screen_shot.py writes it (the recording and frame go in the caption).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

WIDTH, GAP, CAPTION = 1050, 10, 44


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--title', required=True)
    ap.add_argument('shots', nargs='+', help='PNG=caption')
    a = ap.parse_args()
    shots = [s.split('=', 1) for s in a.shots]
    cell_w = (WIDTH - 3 * GAP) // 2
    cell_h = cell_w * 3 // 4
    rows = (len(shots) + 1) // 2
    title_h = 34
    img = Image.new('RGB', (WIDTH, title_h + rows * (cell_h + CAPTION + GAP)), kitlib.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((GAP, 8), a.title, font=kitlib.font(17), fill=kitlib.TEXT)
    f = kitlib.font(14)
    for k, (path, caption) in enumerate(shots):
        x = GAP + (k % 2) * (cell_w + GAP)
        y = title_h + (k // 2) * (cell_h + CAPTION + GAP)
        img.paste(Image.open(path).convert('RGB').resize((cell_w, cell_h), Image.NEAREST), (x, y))
        line, lines = '', []
        for word in caption.split():
            if d.textlength(line + ' ' + word, font=f) > cell_w and line:
                lines.append(line)
                line = word
            else:
                line = (line + ' ' + word).strip()
        lines.append(line)
        for n, text in enumerate(lines[:2]):
            d.text((x, y + cell_h + 4 + 18 * n), text, font=f, fill=kitlib.TEXT)
    img.save(a.out)
    print(a.out, img.size)


if __name__ == '__main__':
    main()

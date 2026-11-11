#!/usr/bin/env python3
"""WALKTHROUGH 6.1 figures: sheets of the recordings' named screens, each labelled with its recording and frame.

    python3 tools/fig_shots.py OUT.png COLS rec:glob [rec:glob ...]

rec is a folder under work/stage1/rec/, glob a pattern over its screens/ (FRAME-NAME.png, written by
tools/record.py at that frame of the recording). Tiles are 896 / COLS px wide, the sheet 900 px.
"""
import glob
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.join(HERE, '..', 'work', 'stage1', 'rec')


def main():
    out, cols = sys.argv[1], int(sys.argv[2])
    files = []
    for spec in sys.argv[3:]:
        rec, pat = spec.split(':', 1)
        for f in sorted(glob.glob(os.path.join(REC, rec, 'screens', pat + '.png'))):
            files.append((rec, f))
    tw = 896 // cols
    th = tw * 3 // 4
    rows = (len(files) + cols - 1) // cols
    im = Image.new('RGB', (900, rows * (th + 14) + 2), 'white')
    d = ImageDraw.Draw(im)
    for i, (rec, f) in enumerate(files):
        x, y = 2 + (i % cols) * tw, (i // cols) * (th + 14)
        frame, _, name = os.path.basename(f)[:-4].partition('-')
        d.text((x + 2, y + 1), f'{rec} {int(frame)} {name}'[:tw // 6], fill='black')
        im.paste(Image.open(f).convert('RGB').resize((tw - 4, th - 3), Image.LANCZOS), (x, y + 14))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out)
    print(out, len(files))


if __name__ == '__main__':
    main()

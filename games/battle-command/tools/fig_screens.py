#!/usr/bin/env python3
"""Doc 01 figures: sheets of screens, 1050 px wide, each tile labelled with where it comes from.

    python3 tools/fig_screens.py OUT.png COLS ITEM [ITEM ...]

An ITEM is PATH or PATH=LABEL, PATH relative to the case folder: a recording's named screen
(work/stage1/rec/REC/screens/FRAME-NAME.png, written by tools/record.py at that frame; the default label is
"REC FRAME NAME"), a picture or a mission preview of src/res (the default label is the file name). Tiles keep the
picture's aspect ratio; the labels are 12 px.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
from kitlib import font  # noqa: E402

W, GAP, LABEL = 1050, 6, 18


def label_of(path):
    parts = path.split('/')
    name = os.path.basename(path)[:-4]
    if 'rec' in parts and 'screens' in parts:
        rec = parts[parts.index('rec') + 1]
        frame, _, what = name.partition('-')
        return f'{rec} {int(frame)} {what}'
    return name.replace('.preview', '')


def main():
    out, cols = sys.argv[1], int(sys.argv[2])
    items = []
    for spec in sys.argv[3:]:
        path, _, lab = spec.partition('=')
        items.append((Image.open(os.path.join(ROOT, path)).convert('RGB'), lab or label_of(path)))
    tw = (W - GAP * (cols + 1)) // cols
    rows = [items[i:i + cols] for i in range(0, len(items), cols)]
    heights = [max(int(tw * im.height / im.width) for im, _ in row) for row in rows]
    H = sum(h + LABEL + GAP for h in heights) + GAP
    sheet = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(sheet)
    f = font(12)
    y = GAP
    for row, h in zip(rows, heights):
        for c, (im, lab) in enumerate(row):
            x = GAP + c * (tw + GAP)
            th = int(tw * im.height / im.width)
            while d.textlength(lab, font=f) > tw and len(lab) > 4:
                lab = lab[:-2]
            d.text((x, y), lab, font=f, fill='black')
            sheet.paste(im.resize((tw, th), Image.LANCZOS), (x, y + LABEL))
        y += h + LABEL + GAP
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print(out, len(items), sheet.size)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A labelled sheet of screens (or crops of them): each argument FILE|LABEL or FILE@X,Y,W,H|LABEL (a crop in
Spectrum pixels, 256 x 192), drawn at --scale, --cols to a row, the label under each.

    python3 tools/fig_sheet.py OUT.png --cols 4 [--scale 1] 'work/stage1/c1/screens/016008-menu.png|c1 16008: the menu' ...
"""
import argparse

from PIL import Image, ImageDraw


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('items', nargs='+')
    ap.add_argument('--cols', type=int, default=4)
    ap.add_argument('--scale', type=float, default=1)
    a = ap.parse_args()
    tiles = []
    for it in a.items:
        path, label = it.split('|', 1)
        crop = None
        if '@' in path:
            path, box = path.split('@')
            crop = [int(v) for v in box.split(',')]
        im = Image.open(path).convert('RGB')
        k = im.size[0] / 256          # the screens may be saved at 2x, with or without a border
        if im.size[0] not in (256, 512):
            bw = (im.size[0] - 256 * round(im.size[0] / 320)) // 2
            k = round(im.size[0] / 320)
            im = im.crop((bw, (im.size[1] - 192 * k) // 2, bw + 256 * k, (im.size[1] + 192 * k) // 2))
        if crop:
            x, y, w, h = crop
            im = im.crop((int(x * k), int(y * k), int((x + w) * k), int((y + h) * k)))
        w, h = im.size
        im = im.resize((int(w / k * a.scale), int(h / k * a.scale)), Image.NEAREST)
        tiles.append((im, label))
    cw = max(t[0].size[0] for t in tiles) + 8
    ch = max(t[0].size[1] for t in tiles) + 22
    rows = (len(tiles) + a.cols - 1) // a.cols
    sheet = Image.new('RGB', (cw * a.cols, ch * rows), (32, 32, 32))
    d = ImageDraw.Draw(sheet)
    for i, (im, label) in enumerate(tiles):
        x, y = (i % a.cols) * cw + 4, (i // a.cols) * ch + 4
        sheet.paste(im, (x, y))
        d.text((x, y + im.size[1] + 3), label, fill=(230, 230, 230))
    sheet.save(a.out)
    print(a.out, sheet.size)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Screens of the stage 1 recordings as PNGs: the screen each capture saved every 250 frames
(work/stage1/<recording>/screens/NNNNNN.scr), at twice the size, named after what they show.

    python3 tools/fig_play.py --out docs/img/play REC:FRAME:NAME ...
    python3 tools/fig_play.py --out docs/img/play --sheet caves.png REC:FRAME:NAME ...   # also one labelled sheet

A shot given as @PNG|LABEL|NAME is a 512 x 384 screenshot already made (kit/screen_shot.py, a frame between the
capture's screens): it is copied as NAME.png and put on the sheet with LABEL.
"""
import argparse
import os

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def scr_image(data):
    img = Image.new('RGB', (256, 192))
    px = img.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for cx in range(32):
            b = data[row + cx]
            at = data[6144 + (y >> 3) * 32 + cx]
            pal = BRIGHT if at & 64 else PAL
            ink, paper = pal[at & 7], pal[at >> 3 & 7]
            for bit in range(8):
                px[cx * 8 + bit, y] = ink if b >> (7 - bit) & 1 else paper
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--sheet')
    ap.add_argument('--cols', type=int, default=4)
    ap.add_argument('shots', nargs='+')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    made = []
    for spec in a.shots:
        if spec.startswith('@'):
            path, label, name = spec[1:].split('|', 2)
            img = Image.open(path).convert('RGB').resize((256, 192), Image.NEAREST)
            img.resize((512, 384), Image.NEAREST).save(os.path.join(a.out, name + '.png'))
            made.append((label, img))
            continue
        rec, frame, name = spec.split(':', 2)
        data = open(os.path.join(CASE, 'work', 'stage1', rec, 'screens', f'{int(frame):06d}.scr'), 'rb').read()
        img = scr_image(data)
        img.resize((512, 384), Image.NEAREST).save(os.path.join(a.out, name + '.png'))
        made.append((f'{rec} frame {int(frame)}', img))
    if a.sheet:
        rows = (len(made) + a.cols - 1) // a.cols
        sheet = Image.new('RGB', (a.cols * 260, rows * 214), (24, 24, 30))
        d = ImageDraw.Draw(sheet)
        for i, (label, img) in enumerate(made):
            x, y = i % a.cols * 260 + 2, i // a.cols * 214 + 2
            d.text((x, y + 2), label, fill=(235, 235, 235))
            sheet.paste(img, (x, y + 18))
        sheet.save(os.path.join(a.out, a.sheet))
    print(len(made), 'screens written to', a.out)


if __name__ == '__main__':
    main()

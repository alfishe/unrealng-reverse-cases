#!/usr/bin/env python3
"""A sheet of 1-bit graphics from the 64 K image: a run of sprites, each WIDTH bytes by ROWS rows, drawn in a grid
with its address under it.

    python3 tools/sprites.py work/mkgame/original.bin out.png --at 8DF0 --count 16 --width 2 --rows 16
            [--flip] [--scale 4] [--per-line 8] [--title T] [--names a,b,c]

--flip draws the last row at the top (the game's map tiles are stored bottom row first and drawn upwards).
Several runs on one sheet: give --at, --count, --width, --rows, --names as ';'-separated lists.
"""
import argparse

from PIL import Image, ImageDraw, ImageFont

INK, PAPER, GRID, TEXT = (255, 255, 255), (0, 0, 0), (60, 60, 60), (200, 200, 200)


def font(size):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def sprite(mem, at, width, rows, flip):
    lines = [mem[at + r * width: at + (r + 1) * width] for r in range(rows)]
    return lines[::-1] if flip else lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('out')
    ap.add_argument('--at', required=True)
    ap.add_argument('--count', required=True)
    ap.add_argument('--width', default='2')
    ap.add_argument('--rows', default='16')
    ap.add_argument('--flip', default='')
    ap.add_argument('--names', default='')
    ap.add_argument('--scale', type=int, default=4)
    ap.add_argument('--per-line', type=int, default=8)
    ap.add_argument('--title', default='')
    a = ap.parse_args()
    mem = open(a.image, 'rb').read()
    runs = []
    ats, counts = a.at.split(';'), a.count.split(';')
    widths = (a.width.split(';') * len(ats))[:len(ats)]
    rowss = (a.rows.split(';') * len(ats))[:len(ats)]
    flips = (a.flip.split(';') * len(ats))[:len(ats)] if a.flip else [''] * len(ats)
    names = a.names.split(';') if a.names else [''] * len(ats)
    for at, count, width, rows, flip, nm in zip(ats, counts, widths, rowss, flips, names):
        at, count, width, rows = int(at, 16), int(count), int(width), int(rows)
        nms = nm.split(',') if nm else []
        runs.append([(at + i * width * rows, width, rows, flip == '1', nms[i] if i < len(nms) else '')
                     for i in range(count)])
    s = a.scale
    cw = max(w for run in runs for _, w, _, _, _ in run) * 8 * s + 2 * s + 8
    cw = max(cw, 90)
    label = 30
    f = font(12)
    ft = font(15)
    lines = []
    for run in runs:
        for i in range(0, len(run), a.per_line):
            lines.append(run[i:i + a.per_line])
    heights = [max(r for _, _, r, _, _ in ln) * s + 2 * s + label for ln in lines]
    top = 30 if a.title else 6
    img = Image.new('RGB', (cw * a.per_line + 12, top + sum(heights) + 6), (24, 24, 24))
    d = ImageDraw.Draw(img)
    if a.title:
        d.text((8, 6), a.title, fill=TEXT, font=ft)
    y = top
    for ln, h in zip(lines, heights):
        for k, (at, width, rows, flip, nm) in enumerate(ln):
            x0 = 6 + k * cw
            d.rectangle([x0, y, x0 + width * 8 * s + 2 * s - 1, y + rows * s + 2 * s - 1], fill=PAPER, outline=GRID)
            for r, row in enumerate(sprite(mem, at, width, rows, flip)):
                for b, byte in enumerate(row):
                    for bit in range(8):
                        if byte & (0x80 >> bit):
                            px, py = x0 + s + (b * 8 + bit) * s, y + s + r * s
                            d.rectangle([px, py, px + s - 1, py + s - 1], fill=INK)
            d.text((x0, y + rows * s + 2 * s + 2), f'${at:04X}', fill=TEXT, font=f)
            if nm:
                d.text((x0, y + rows * s + 2 * s + 15), nm, fill=TEXT, font=f)
        y += h
    img.save(a.out)
    print(a.out, img.size)


if __name__ == '__main__':
    main()

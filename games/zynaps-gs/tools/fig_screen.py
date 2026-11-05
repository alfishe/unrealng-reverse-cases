#!/usr/bin/env python3
"""Doc 01 figure: the play screen with its parts named, each with the address the code draws it at. (Adapted from
the 48K case's tools/fig_screen.py: the GS game draws the same screen at the same addresses.)

    python3 tools/fig_screen.py --work work/zgsA/r1 --frame 3100 --out docs/img/design/play-screen.png

The boxes are character cells (column, row, width, height). Their witnesses: PrintPlayerScore $5802 / column 22 of
row 0; RowRecords (row r of the playfield at screen row r + 1, the record's +2/+4); DrawSpinner (row 20, columns 1
and 29); PodIconJob ($5A86 / $5AA6: rows 20-21, columns 6-7); the fuel lamps ($5AC1, $5ADD); the ink-step cells
($5AC6); the speed bar ($5AEE); DrawLives ($5AD8: row 22 from column 24). The values printed beside come from the
same frame's memory.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zgslib as Z  # noqa: E402

K = Z.K


def cell_of(address):
    a = address - 0x5800
    return a & 31, a >> 5


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frame', type=int, default=2400)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    scr = Z.cached(args.work, args.frame)
    rec = Z.cached(args.work, args.frame, 0x7F9C, 16)
    fuel = Z.cached(args.work, args.frame, 0x80E6, 1)[0]
    score = int(rec[0:4].hex())
    parts = [
        # (column, row, width, height, label, colour)
        (0, 0, 32, 1, f'row 0: the scores, player 1 from $5802, player 2 from column 22 (now {score})',
         (240, 240, 240)),
        (0, 1, 32, 18, 'rows 1-18: the playfield, 18 rows of span chains (RowRecords $F12C)', (90, 200, 120)),
        (1, 20, 2, 2, 'spinner, row 20 column 1 (DrawSpinner)', (250, 150, 60)),
        (29, 20, 2, 2, 'spinner, row 20 column 29', (250, 150, 60)),
        (6, 20, 2, 2, f'pod selector icon, $5A86/$5AA6 (record +7 = {rec[7]})', (240, 200, 70)),
        (*cell_of(0x5AC1), 2, 1, f'fuel lamps $5AC1, Fuel $80E6 = ${fuel:02X}', (255, 90, 90)),
        (*cell_of(0x5ADD), 2, 1, 'fuel lamps $5ADD', (255, 90, 90)),
        (*cell_of(0x5AEE), 4, 1, f'speed bar $5AEE (record +$0B = ${rec[11]:02X})', (70, 210, 220)),
        (*cell_of(0x5AD8), 6, 1, f'lives $5AD8 on (record +4 = {rec[4]})', (200, 110, 230)),
    ]
    z = 2
    screen = Z.render(scr, z)
    W = 900
    H = 56 + 192 * z + 20
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb = K.font(12), K.font(15)
    d.text((10, 8), f'The play screen: score line, 18 playfield rows, the panel (r1 frame {args.frame}, level 1)',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'numbered boxes: the character cells each part is drawn in; the list on the right names them',
           fill=K.DIM, font=f)
    x0, y0 = 10, 56
    im.paste(screen, (x0, y0))
    lx = x0 + 256 * z + 16
    label_y = y0
    for i, (c, r, w, h, label, colour) in enumerate(parts):
        bx0, by0 = x0 + c * 8 * z, y0 + r * 8 * z
        bx1, by1 = x0 + (c + w) * 8 * z - 1, y0 + (r + h) * 8 * z - 1
        d.rectangle((bx0, by0, bx1, by1), outline=colour, width=2)
        d.text((bx0 + 2, by0 + 1), str(i + 1), fill=colour, font=f)
        ty = label_y + i * 44
        d.text((lx, ty), f'{i + 1}', fill=colour, font=fb)
        words, line, lines = label.split(' '), '', []
        for word in words:
            if len(line) + len(word) + 1 > 44:
                lines.append(line)
                line = word
            else:
                line = (line + ' ' + word).strip()
        lines.append(line)
        for j, text in enumerate(lines):
            d.text((lx + 22, ty + 2 + 15 * j), text, fill=K.TEXT, font=f)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

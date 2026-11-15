#!/usr/bin/env python3
"""Doc 3's figure of the loader's 128K test (LoaderMain `$5E18-$5E41`, build/loader.lst): its steps on a 128K and on
a 48K, with the byte at `$C000` in each RAM bank after each step and where each path leaves.

    python3 tools/fig_paging.py      # docs/img/load/paging-test.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'load', 'paging-test.png')
BG, FG, DIM, GRID = (24, 24, 30), (235, 235, 235), (160, 160, 172), (60, 60, 72)
RAM0, RAM4, ONE = (90, 160, 230), (180, 110, 220), (120, 190, 120)
GO, STOP, FLAG = (110, 200, 120), (230, 110, 90), (240, 200, 80)

# (code, 128K: RAM 0 byte, RAM 4 byte, outcome), (48K: the one byte, outcome); None = the path has left
STEPS = [
    ('OUT ($7FFD),$10; LD ($C000),$2A', ('2A', '??', ''), ('2A', '')),
    ('OUT ($7FFD),$14; LD A,($C000); CP $2A', ('2A', '??', 'A = RAM 4 byte, not $2A: go on'),
     ('2A', 'A = $2A: no paging, leave')),
    ('XOR A; LD (HL),A; DEC (HL); OR (HL); INC A', ('2A', 'FF', 'A = 0: RAM 4 is RAM, go on'), None),
    ('OUT ($7FFD),$10; LD A,($C000); CP $2A', ('2A', 'FF', 'A = $2A: two banks, go on'), None),
    ('XOR A; LD (MachineFlag),A', ('2A', 'FF', '$FFFE = 0: a 128K'), None),
]


def cell(d, x, y, w, h, text, col, font):
    d.rectangle((x, y, x + w, y + h), fill=col, outline=BG)
    tw = d.textlength(text, font=font)
    d.text((x + (w - tw) / 2, y + (h - font.size) / 2 - 1), text, fill=(15, 15, 20), font=font)


def main():
    big, mid, small = kitlib.font(18), kitlib.font(15), kitlib.font(13)
    W, H = 1180, 580
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), "The loader's 128K test: MachineFlag $FFFE starts at $FF; the byte at $C000 after each step",
           fill=FG, font=big)
    x_code, x128, x48 = 14, 470, 890
    y = 52
    d.text((x_code, y), 'step (LoaderMain, $5E18-$5E41)', fill=DIM, font=mid)
    d.text((x128, y), '128K (c1): RAM 0  RAM 4', fill=DIM, font=mid)
    d.text((x48, y), '48K (c48): one RAM', fill=DIM, font=mid)
    y += 30
    row_h = 74
    for i, (code, k128, k48) in enumerate(STEPS):
        top = y + i * row_h
        d.line((x_code, top - 6, W - 14, top - 6), fill=GRID)
        d.text((x_code, top + 6), f'{i + 1}. {code}', fill=FG, font=small)
        r0, r4, note = k128
        cell(d, x128, top, 60, 26, r0, RAM0, mid)
        cell(d, x128 + 70, top, 60, 26, r4, RAM4, mid)
        if note:
            col = FLAG if 'MachineFlag' in code else GO
            d.text((x128, top + 32), note, fill=col, font=small)
        if k48 is None:
            d.text((x48, top + 4), '(left at step 2)', fill=DIM, font=small)
        else:
            b, note48 = k48
            cell(d, x48, top, 60, 26, b, ONE, mid)
            if note48:
                d.text((x48, top + 32), note48, fill=STOP, font=small)
    top = y + len(STEPS) * row_h
    d.line((x_code, top - 6, W - 14, top - 6), fill=GRID)
    d.text((x_code, top + 4), 'then', fill=FG, font=mid)
    d.text((x128, top + 4), 'load the game, page RAM 4, load the music,', fill=FLAG, font=small)
    d.text((x128, top + 22), 'page RAM 0, JP $9100; $FFFE = 0', fill=FLAG, font=small)
    d.text((x48, top + 4), 'load the game, JP $9100;', fill=STOP, font=small)
    d.text((x48, top + 22), '$FFFE = $FF', fill=STOP, font=small)
    d.text((x_code, H - 46), '?? = whatever RAM 4 held at power-on (not $2A in c1).', fill=DIM, font=small)
    d.text((x_code, H - 26), 'A path also leaves at step 3 if the byte is not RAM, and at step 4 if RAM 0 lost its $2A '
           '(one bank seen twice); both leave $FFFE = $FF.', fill=DIM, font=small)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT)
    print(OUT)


if __name__ == '__main__':
    main()

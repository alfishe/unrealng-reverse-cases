#!/usr/bin/env python3
"""Doc 4's figure of the IM 2 vector trick: the bytes GameEntry $9100 writes at the top of memory (taken from the
memory at c1 frame 15 021, read from build/game.lst's GameEntry and the loader block), and the four steps an interrupt
takes from the bus to Interrupt $9226.

    python3 tools/fig_im2.py      # docs/img/loop/im2-trick.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'loop')
BG, FG, DIM, HOT, BOX = (24, 24, 30), (235, 235, 235), (170, 170, 180), (255, 200, 90), (60, 60, 75)
STEP = (110, 200, 255)

# (address label, bytes shown, what it is, highlighted)
CELLS = [
    ('$0000', 'F3', 'ROM: DI (both 128K ROMs and the 48K ROM)', True),
    ('$9226', 'F5 08 F5', 'Interrupt: PUSH AF, EX AF,AF\', PUSH AF ...', True),
    ('$FE00', 'FF FF FF ...', 'ImTable $FE00-$FF00: 257 bytes of $FF', False),
    ('$FEFF', 'FF FF', 'the vector read for any bus byte: I = $FE, bus $FF', True),
    ('$FFF0', '..', 'StackTop: SP at GameEntry and GameStart', False),
    ('$FFF4', 'C3 26 92', 'ImJump: JP $9226', True),
    ('$FFFE', '00', 'MachineFlag: 0 on a 128K, $FF on a 48K', False),
    ('$FFFF', '18', 'ImJr: JR, its offset the next byte, $0000 = $F3 (-13)', True),
]

STEPS = [
    '1  the ULA interrupts; IM 2 reads a word at I x 256 + bus = $FEFF: $FFFF (19 T)',
    '2  at $FFFF the CPU fetches $18 (JR); the offset wraps to $0000 and reads $F3 = -13',
    '3  PC after the JR = $0001; $0001 - 13 = $FFF4 (12 T)',
    '4  at $FFF4: JP $9226 (10 T), the handler; it ends EI, RET at $92C1-$92C2',
]


def main():
    os.makedirs(OUT, exist_ok=True)
    big, mid = kitlib.font(17), kitlib.font(15)
    row = 44
    im = Image.new('RGB', (1050, 60 + len(CELLS) * row + 30 + len(STEPS) * 30 + 20), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 10), 'The IM 2 vector trick: the bytes GameEntry $9100 leaves (c1 frame 15 021, after IM 2)',
           fill=FG, font=big)
    y0 = 50
    for i, (addr, val, what, hot) in enumerate(CELLS):
        y = y0 + i * row
        d.text((14, y + 10), addr, fill=HOT if hot else DIM, font=big)
        d.rectangle((100, y + 4, 260, y + row - 6), fill=BOX, outline=HOT if hot else DIM, width=2)
        d.text((112, y + 11), val, fill=FG, font=big)
        d.text((280, y + 11), what, fill=FG if hot else DIM, font=mid)
    # the path: $FEFF -> $FFFF -> ($0000 read) -> $FFF4 -> $9226
    cy = {a: y0 + i * row + row // 2 - 1 for i, (a, *_r) in enumerate(CELLS)}
    xs = [960, 990, 1020]
    d.line((900, cy['$FEFF'], xs[0], cy['$FEFF'], xs[0], cy['$FFFF'], 900, cy['$FFFF']), fill=STEP, width=3)
    d.text((xs[0] - 16, (cy['$FEFF'] + cy['$FFFF']) // 2 - 30), '1', fill=STEP, font=big)
    d.line((900, cy['$FFFF'] + 6, xs[1], cy['$FFFF'] + 6, xs[1], cy['$0000'], 900, cy['$0000']), fill=STEP,
           width=3)
    d.text((xs[1] - 16, (cy['$0000'] + cy['$FEFF']) // 2), '2', fill=STEP, font=big)
    d.line((900, cy['$FFFF'] + 12, xs[2], cy['$FFFF'] + 12, xs[2], cy['$FFF4'], 900, cy['$FFF4']), fill=STEP,
           width=3)
    d.text((xs[2] - 16, cy['$FFF4'] + 10), '3', fill=STEP, font=big)
    d.line((880, cy['$FFF4'] - 6, 880, cy['$9226'], 900, cy['$9226']), fill=STEP, width=3)
    d.text((862, (cy['$9226'] + cy['$FFF4']) // 2), '4', fill=STEP, font=big)
    y = y0 + len(CELLS) * row + 20
    for s in STEPS:
        d.text((14, y), s, fill=STEP, font=mid)
        y += 30
    im.save(os.path.join(OUT, 'im2-trick.png'))
    print(os.path.join(OUT, 'im2-trick.png'), im.size)


if __name__ == '__main__':
    main()

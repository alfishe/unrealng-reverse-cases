#!/usr/bin/env python3
"""The figures of doc 8 (HUD and text).

    python3 tools/fig_hud.py hud --work W --frame F --out docs/img/hud/fields.png
    python3 tools/fig_hud.py font --out docs/img/hud/font.png

hud: the HUD (pixel lines 0-39) of a recording's frame (memory at T 0), 4 screen pixels a pixel, every field boxed
with the routine that prints it, its column and pixel line, and its attribute. font: the 8x8 font at Font ($7608,
codes $20-$5E) and the ten big digits (BigDigits, 16 x 15) from build/game.bin, with their codes.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, os.path.join(CASE, 'tools'))
import kitlib as K  # noqa: E402
from fig_controls import Live, image, wrap, WIDTH  # noqa: E402

# (column, pixel line, width in characters, height in lines, label, colour)
FIELDS = [
    (1, 8, 3, 8, 'TOP  HudLayout  $7A', (230, 90, 80)),
    (5, 8, 7, 8, 'best score  HiScores row 1  PlayTurn', (240, 200, 70)),
    (13, 8, 4, 8, 'TIME  $60', (90, 200, 120)),
    (19, 8, 5, 8, 'SCORE  $7A', (230, 90, 80)),
    (25, 8, 7, 8, 'Score  DrawScore (AddScore)  $69', (90, 150, 250)),
    (1, 24, 5, 8, 'STAGE  $70', (240, 200, 70)),
    (7, 24, 2, 15, 'stage digit  BigDigit DE = $0718', (200, 110, 230)),
    (13, 24, 4, 15, 'Timer  PrintTimer  BigDigit x 2', (90, 200, 120)),
    (19, 24, 5, 8, 'SPEED  $70', (240, 200, 70)),
    (25, 24, 4, 8, 'SPEED  PrintSpeed  PrintNumber', (70, 210, 220)),
    (29, 24, 3, 8, 'K<> (km/h)  $68', (250, 150, 60)),
]


def cmd_hud(args):
    live = Live(args.work)
    scr = bytearray(0x10000)
    scr[0x4000:0x5B00] = live.mem(args.frame, 0x4000, 0x1B00)
    sc = 4
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    hud = K.render_screen(scr).crop((0, 0, 256, 40)).resize((256 * sc, 40 * sc), Image.NEAREST)
    pic = Image.new('RGB', (WIDTH, 40 * sc + 330), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), f'The HUD, pixel lines 0-39 of c1 {args.frame} (T 0): each field, its printer, its column and '
                    'line', fill=K.TEXT, font=ft)
    x0, y0 = 12, 40
    pic.paste(hud, (x0, y0))
    ly = y0 + 40 * sc + 14
    for i, (col, line, w, h, label, colour) in enumerate(FIELDS):
        box = [x0 + col * 8 * sc, y0 + line * sc, x0 + (col + w) * 8 * sc - 1, y0 + (line + h) * sc - 1]
        d.rectangle(box, outline=colour, width=2)
        d.text((box[0] + 2, box[1] - 15 if line == 8 else box[3] + 1), str(i + 1), fill=colour, font=f)
        lx = 12 + (i % 2) * 520
        yy = ly + (i // 2) * 22
        d.text((lx, yy), f'{i + 1:2d}  column {col:2d}, line {line:2d}:  {label}', fill=colour, font=f)
    wrap(d, 'PlayTurn clears lines 0-63 and sets the attributes of lines 0-47 to $69 (blue on cyan, bright); the labels '
            'come from HudLayout ($8DAC: count, then line, column, attribute, length) and HudTexts. Numbers: the '
            'small ones through PrintChar (8 x 8, Font), the stage and the timer through BigDigit (16 x 15, '
            'BigDigits, SP walking RowTable). DEMO or nUP flashes below, at column 28, line 176 (HudFlash).',
         12, ly + 6 * 22 + 8, WIDTH - 24, fs, K.DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def glyph(mem, address, w_bytes, rows):
    g = Image.new('RGB', (8 * w_bytes, rows), (30, 30, 40))
    px = g.load()
    for r in range(rows):
        for c in range(w_bytes):
            b = mem[address + r * w_bytes + c]
            for bit in range(8):
                if b & (0x80 >> bit):
                    px[c * 8 + bit, r] = (230, 230, 235)
    return g


def cmd_font(args):
    mem = image()
    f, fs, ft = K.font(13), K.font(12), K.font(16)
    pic = Image.new('RGB', (WIDTH, 520), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 8), 'Font ($7608, codes $20-$5E, 8 bytes a character) and BigDigits (the HUD\'s stage and TIME)',
           fill=K.TEXT, font=ft)
    sc = 3
    for i in range(63):
        code = 0x20 + i
        x = 12 + (i % 16) * 64
        y = 40 + (i // 16) * 62
        pic.paste(glyph(mem, 0x7608 + 8 * i, 1, 8).resize((8 * sc, 8 * sc), Image.NEAREST), (x, y + 16))
        d.text((x, y), f'${code:02X} {chr(code)}', fill=K.DIM, font=fs)
    big = int([a for a in open(os.path.join(CASE, 'build', 'game.lst'))
               if a.split()[2:3] == ['BigDigits:']][0].split()[1], 16)
    d.text((12, 300), f'BigDigits ${big:04X}: 10 digits x 15 rows x 2 bytes (BigDigit: digit n at BigDigits + 30 n)',
           fill=K.TEXT, font=f)
    for n in range(10):
        pic.paste(glyph(mem, big + 30 * n, 2, 15).resize((16 * 4, 15 * 4), Image.NEAREST), (12 + n * 100, 330))
        d.text((12 + n * 100, 396), str(n), fill=K.DIM, font=f)
    wrap(d, 'Code $3C < and $3E > draw "m/h" for K<> (km/h); \' and " mark minutes and seconds in times '
            '("3\'00"00"); @ is the lap table\'s per cent sign; ? and = in the name grid are END and the delete key. '
            'FrameChars ($8AB3) and FrameChars2 hold 8 pieces each (corners, top, sides, bottom): "[%\\+/])^" for the '
            'HUD\'s two frames and the name cursor, "()*/+&%$" for DrawWindow. The printer adds 8 x (A - $20) to Font (the '
            'code\'s base Font - $100 plus 8 x A).', 12, 430, WIDTH - 24, fs, K.DIM)
    pic.save(args.out)
    print(args.out, pic.size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('hud')
    s.add_argument('--work', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('font')
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'hud': cmd_hud, 'font': cmd_font}[args.cmd](args)


if __name__ == '__main__':
    main()

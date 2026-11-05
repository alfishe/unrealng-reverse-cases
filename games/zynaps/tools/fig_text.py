#!/usr/bin/env python3
"""The game's text as figures (docs/08-hud-and-text.md): the two fonts and the pages the messages make.

    python3 tools/fig_text.py font
    python3 tools/fig_text.py pages

  font   docs/img/hud/font.png: the ROM characters $20-$7F as the ROM draws them and as PrintChar $A321 prints them
         ("split bold": ROM row 0 dropped, row 1 on line 0, line 1 blank, rows 2-7 on lines 2-7, each row ORed with
         itself shifted left in the left nibble, mask $F0), and the game's 54 glyphs $80-$B5 from $B54F.
  pages  docs/img/hud/pages.png: the messages printed by a model of PrintString $A401 / PrintChar on blank screens,
         one page per caller: the credits (21), the keyboard definition (13 + 14-18), the selections (19), PREPARE
         FOR COMBAT (24), the role of honour (25 + 26, 27): every one of the 28 messages appears in one of them.

The bytes come from build/game.bin (the image $61A8-$FFFE) and the 48K ROM of unreal-ng (data/rom/48.rom). The model
follows the print codes of print.asm: 0 attribute, 1 ink, 2 paper, 3 column, 4 row, 5 column + n (low byte, no
carry), 6 row + n, $1B n message n, $FF the end.
"""
import os
import sys

from PIL import Image, ImageDraw

import zybplot as P

BASE = 0x61A8
ROM = os.path.join(P.K.unreal_root(None), 'data', 'rom', '48.rom')


def image():
    m = bytearray(0x10000)
    g = open(os.path.join(P.CASE, 'build', 'game.bin'), 'rb').read()
    m[BASE:BASE + len(g)] = g
    m[0:0x4000] = open(ROM, 'rb').read()[:0x4000]
    return m


def bold(b):
    return ((b << 1) & 0xF0 | b) & 0xFF


def printed_rom(m, code):
    g = m[0x3C00 + 8 * code:0x3C00 + 8 * code + 8]
    return [bold(g[1]), 0] + [bold(g[k]) for k in range(2, 8)]


def glyph(m, code):
    if code >= 0x80:
        a = 0xB14F + 8 * code
        return list(m[a:a + 8])
    return printed_rom(m, code)


class Printer:
    def __init__(self, m):
        self.m = m
        self.scr = bytearray(6912)
        self.pos = 0x5800
        self.attr = 0x47
        self.pending = None

    def char(self, b):
        if self.pending is not None:
            code, self.pending = self.pending, None
            c = b
            if code == 0:
                self.attr = c
            elif code == 1:
                self.attr = self.attr & 0xF8 | c
            elif code == 2:
                self.attr = self.attr & 0xC7 | (c << 3) & 0xFF
            elif code == 3:
                self.pos = self.pos & 0xFFE0 | c
            elif code == 4:
                self.set_row(c)
            elif code == 5:
                self.pos = self.pos & 0xFF00 | (self.pos + c) & 0xFF
            elif code == 6:
                self.set_row(((self.pos << 3) >> 8 & 0x1F) + c & 0xFF)
            return
        if b < 0x20:
            self.pending = b
            return
        off = self.pos - 0x5800
        if 0 <= off < 768:
            self.scr[0x1800 + off] = self.attr
            h = ((self.pos >> 8) << 3 | (self.pos >> 8) >> 5) & 0xFF ^ 0x82
            for i, v in enumerate(glyph(self.m, b)):
                a = ((h + i) << 8 | self.pos & 0xFF) - 0x4000
                if 0 <= a < 0x1800:
                    self.scr[a] = v
        self.pos += 1

    def set_row(self, c):
        r = (c >> 3 | c << 5) & 0xFF
        self.pos = (0x58 | r & 3) << 8 | (r ^ self.pos & 0xFF) & 0xE0 ^ self.pos & 0xFF

    def string(self, a):
        while True:
            b = self.m[a]
            if self.pending is None and b == 0xFF:
                return
            if self.pending is None and b == 0x1B:
                self.message(self.m[a + 1])
                a += 2
                continue
            self.char(b)
            a += 1

    def message(self, n):
        a = 0x82ED
        for _ in range(n + 1):
            while self.m[a] != 0xFF:
                a += 1
            a += 1
        self.string(a)

    def picture(self, scale=2):
        img = P.screen(bytes(self.scr))
        return img.resize((256 * scale, 192 * scale), Image.NEAREST)


def font():
    m = image()
    S = 3
    cell = 8 * S + 6
    W = 16 * cell * 2 + 60
    img = Image.new('RGB', (W, 6 * cell + 120 + 6 * cell + 70), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 6), 'PrintChar $A321 has two fonts: the ROM characters $20-$7F redrawn "split bold" (right), the 54 glyphs $80-$B5', fill=P.K.TEXT, font=P.K.font(14))

    def put(x, y, rows, col=(230, 230, 230)):
        for i, v in enumerate(rows):
            for b in range(8):
                c = col if v & (0x80 >> b) else (40, 42, 52)
                d.rectangle([x + b * S, y + i * S, x + b * S + S - 1, y + i * S + S - 1], fill=c)

    y0 = 50
    d.text((10, y0 - 18), 'the ROM ($3C00 + 8 code), as the ROM prints it', fill=P.K.DIM, font=P.K.font(12))
    d.text((16 * cell + 50, y0 - 18), 'as PrintChar prints it: line 1 blank, the left nibble bold', fill=P.K.DIM,
           font=P.K.font(12))
    for k in range(96):
        code = 0x20 + k
        x, y = 10 + (k % 16) * cell, y0 + (k // 16) * cell
        put(x, y, m[0x3C00 + 8 * code:0x3C08 + 8 * code], (200, 200, 210))
        put(x + 16 * cell + 40, y, printed_rom(m, code), (255, 220, 90))
    y1 = y0 + 6 * cell + 40
    d.text((10, y1 - 22), 'the game\'s glyphs $80-$B5 at $B54F (8 lines as they are): the ZYNAPS logo $80-$A3 and '
                          '$A4-$B5 with the HEWSON lettering', fill=P.K.DIM, font=P.K.font(12))
    for k in range(54):
        code = 0x80 + k
        x, y = 10 + (k % 18) * (cell + 22), y1 + (k // 18) * (cell + 18)
        put(x, y, glyph(m, code), (120, 220, 255))
        d.text((x, y + 8 * S + 1), f'{code:02X}', fill=P.K.DIM, font=P.K.font(10))
    img = img.crop((0, 0, W, y1 + 3 * (cell + 18) + 10))
    path = P.out('hud', 'font.png')
    img.save(path)
    print('wrote', os.path.relpath(path, P.CASE), img.size)


PAGES = [('credits: 21 (7, 0-6, 20, 2 inside)', [21]),
         ('keys: 13, then 14-18 (no key names)', [13, 14, 15, 16, 17, 18]),
         ('selections: 19', [19]),
         ('level start: 24 (23 inside)', [24]),
         ('role of honour: 25, then 27', [25, 27]),
         ('no rank: 25, then 26', [25, 26])]


def pages():
    m = image()
    pics = []
    for title, msgs in PAGES:
        pr = Printer(m)
        if 14 in msgs:
            pr.message(13)
            pr.set_row(5)
            for n in msgs[1:]:
                pr.message(n)
        else:
            for n in msgs:
                pr.message(n)
        pics.append((title, pr.picture(1)))
    W, H = 3 * (256 + 20) + 20, 2 * (192 + 40) + 66
    img = Image.new('RGB', (W, H), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 8), 'The pages the messages make: the strings at $82EE printed by a model of PrintString $A401 on\n'
                    'blank screens ("n" is PlayerDigit $84BB before the game writes the digit)', fill=P.K.TEXT, font=P.K.font(14))
    for k, (title, pic) in enumerate(pics):
        x, y = 20 + (k % 3) * (256 + 20), 66 + (k // 3) * (192 + 40)
        img.paste(pic, (x, y + 16))
        d.text((x, y), title, fill=P.K.TEXT, font=P.K.font(12))
    path = P.out('hud', 'pages.png')
    img.save(path)
    print('wrote', os.path.relpath(path, P.CASE), img.size)


if __name__ == '__main__':
    {'font': font, 'pages': pages}[sys.argv[1]]()

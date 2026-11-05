#!/usr/bin/env python3
"""The panel, the fonts, the pages and the options menu of Zynaps GS as figures (docs/08-hud-and-text.md).
(The panel, font and pages parts are adapted from the 48K case's tools/fig_panel.py and tools/fig_text.py.)

    python3 tools/fig_hud.py panel [--npz work/zgsB/e1/bot.npz --frame 2200]
    python3 tools/fig_hud.py font
    python3 tools/fig_hud.py menufont
    python3 tools/fig_hud.py pages
    python3 tools/fig_hud.py menu

  panel     docs/img/hud/panel.png: the score line and the panel of one frame, x3, every part the code writes boxed
            and named; the five pod icons PodIcons $B4AF; the fuel lamps and the speed bar cut from the recording.
  font      docs/img/hud/font.png: the ROM characters $20-$7F as the ROM draws them and as PrintChar $A321 prints them
            ("split bold"), and the 54 glyphs $80-$B5 at $B54F.
  menufont  docs/img/hud/menu-font.png: the ROM characters and the menu's bold copy that MakeFont $6FA2 leaves in
            bank 7 at $FD00 (each row ORed with itself shifted right), read from the running menu (f1), checked
            byte for byte against that rule.
  pages     docs/img/hud/pages.png: the messages printed by a model of PrintString $A401 on blank screens.
  menu      docs/img/hud/menu.png: the options menu as it starts and after the hidden key 0 and key 8 (f1), each
            line with the key that changes it, the code it writes and the address.

The bytes: build/game.bin (the image $5C00-$FFFF), the 48 ROM and bank 7 as the running menu has them
(work/zgsB/f1/menu0-cpu.bin, menu1-cpu.bin: the 64 K Z80 view, ROM 48 and bank 7 paged).
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

import zgsbplot as P

BASE = 0x5C00
F1 = os.path.join(P.CASE, 'work', 'zgsB', 'f1')
FONT = P.K.font


def image():
    m = bytearray(0x10000)
    g = open(os.path.join(P.CASE, 'build', 'game.bin'), 'rb').read()
    m[BASE:BASE + len(g)] = g
    m[0:0x4000] = open(os.path.join(F1, 'menu0-cpu.bin'), 'rb').read()[:0x4000]
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
    """PrintString $A401 / PrintChar $A321 as a model: 0 attribute, 1 ink, 2 paper, 3 column, 4 row, 5 column + n
    (the low byte, no carry), 6 row + n, $1B n message n, $FF the end"""

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


S = 3
MARKS = [  # (row, col, w, h, label, colour)
    (0, 2, 8, 1, 'score $5802: PrintPlayerScore $A4AE (ScoreJob $AC7A)', (255, 255, 120)),
    (20, 1, 2, 2, 'spinner $5A81: DrawSpinner $A8BE, each frame', (120, 220, 255)),
    (20, 29, 2, 2, 'spinner $5A9D: DrawSpinner', (120, 220, 255)),
    (20, 6, 2, 2, 'pod icon $5086: PodIconJob $AC2C', (120, 255, 140)),
    (22, 6, 2, 1, 'ink step $5AC6: PanelFrame $AB13', (255, 170, 80)),
    (22, 1, 2, 1, 'fuel lamps $5AC1: PanelFrame', (255, 110, 110)),
    (22, 29, 2, 1, 'fuel lamps $5ADD: PanelFrame', (255, 110, 110)),
    (23, 14, 4, 1, 'speed bar $5AEE-$5AF1: PanelFrame', (230, 140, 255)),
    (21, 11, 10, 2, 'burst: rows 21-22, columns 11-20', (200, 200, 200)),
    (20, 24, 2, 3, 'lives $5AD8 + LifeSteps: DrawLives $A4EF', (255, 90, 90)),
]


def panel(npz, frame):
    rec = P.Rec(npz)
    i = rec.index(frame)
    full = rec.screen_img(i, 1)
    top, pan = full.crop((0, 0, 256, 8)), full.crop((0, 152, 256, 192))
    Wd = 256 * S + 470
    img = Image.new('RGB', (Wd, 1100), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f = FONT(13)
    d.text((10, 8), f'The play panel at {rec.name} frame {int(rec.F[i])}: rows 0 and 19-23, x{S}. PanelFrame $AB13 '
                    f'writes only attributes each frame;', fill=P.K.TEXT, font=FONT(15))
    d.text((10, 28), 'the pixels come from RestorePanel $A979, the spinners, the icon and the print routine',
           fill=P.K.TEXT, font=FONT(15))
    y_top, y_pan = 60, 60 + 8 * S + 16
    img.paste(top.resize((256 * S, 8 * S), Image.NEAREST), (10, y_top))
    img.paste(pan.resize((256 * S, 40 * S), Image.NEAREST), (10, y_pan))
    ly = 60
    for k, (r, c, w, h, label, col) in enumerate(MARKS):
        y = y_top if r == 0 else y_pan + (r - 19) * 8 * S
        x = 10 + c * 8 * S
        d.rectangle([x, y, x + w * 8 * S - 1, y + h * 8 * S - 1], outline=col, width=2)
        d.text((x + 2, y + 2), str(k + 1), fill=col, font=FONT(14))
        d.text((256 * S + 24, ly), f'{k + 1} {label}', fill=col, font=f)
        ly += 18
    m = image()
    yi = y_pan + 40 * S + 30
    d.text((10, yi), 'the five pod icons, PodIcons $B4AF + 32 n (n = the selector, record +7), as PodIconJob colours '
                     'them:\nthe top row $46 (yellow), the bottom row $45 (cyan)', fill=P.K.TEXT, font=f)
    names = ['0 speed-up', '1 laser', '2 plasma', '3 homing missiles', '4 seeker']
    for n in range(5):
        b = m[0xB4AF + 32 * n:0xB4AF + 32 * n + 32]
        ic = Image.new('RGB', (16, 16))
        for cell, (cx, cy) in zip([b[0:8], b[8:16], b[16:24], b[24:32]], [(0, 0), (8, 0), (0, 8), (8, 8)]):
            for yy, v in enumerate(cell):
                for xx in range(8):
                    ink = (255, 255, 0) if cy == 0 else (0, 255, 255)
                    ic.putpixel((cx + xx, cy + yy), ink if v & (0x80 >> xx) else (0, 0, 0))
        x = 10 + n * 190
        img.paste(ic.resize((16 * 5, 16 * 5), Image.NEAREST), (x, yi + 40))
        d.text((x, yi + 40 + 84), names[n], fill=P.K.TEXT, font=f)
    fuel, speed = rec.var(0x80E6), rec.var(0x7FA7)
    yg = yi + 40 + 120
    d.text((10, yg), f'the gauges in {rec.name}, 8 frames after each value is reached: the fuel lamps $5AC1-$5AC2 (the '
                     f'right one dark below $40, both below $20)\nand the speed bar $5AEE-$5AF1 (speed / 32 - 1 lit '
                     f'cells):', fill=P.K.TEXT, font=f)

    def first(pred, after=0):
        for k in range(len(rec.F)):
            if rec.F[k] > after and all(pred(j) for j in range(k, min(k + 5, len(rec.F)))):
                return min(k + 4, len(rec.F) - 1)     # the panel shows a value a frame or more after it is set
        return None
    cases = [('fuel >= $40', first(lambda k: fuel[k] >= 0x40, 100), 'fuel'),
             ('fuel $20-$3F', first(lambda k: 0x20 <= fuel[k] < 0x40), 'fuel'),
             ('fuel < $20', first(lambda k: fuel[k] < 0x20), 'fuel'),
             ('speed $40', first(lambda k: speed[k] == 0x40, 100), 'speed'),
             ('speed $60', first(lambda k: speed[k] == 0x60, 100), 'speed')]
    rows = []
    for n, (label, k, what) in enumerate(cases):
        if k is None:
            continue
        pic = rec.screen_img(k, 1)
        box = (0, 168, 40, 184) if what == 'fuel' else (104, 176, 152, 192)
        crop = pic.crop(box)
        x = 10 + n * 190
        img.paste(crop.resize((crop.width * 4, crop.height * 4), Image.NEAREST), (x, yg + 44))
        scr = rec.S[k]
        attrs = f'$5AC1 ${scr[0x1800 + 0x2C1]:02X} $5AC2 ${scr[0x1800 + 0x2C2]:02X}' if what == 'fuel' else \
            'lit ' + str(sum(1 for c in range(4) if scr[0x1800 + 0x2EE + c] == 0x31)) + ' of 4'
        d.text((x, yg + 44 + crop.height * 4 + 4), f'{label}\n{rec.name} frame {int(rec.F[k])}\n' +
               (f'Fuel ${fuel[k]:02X}\n' if what == 'fuel' else f'speed ${speed[k]:02X}\n') + attrs,
               fill=P.K.TEXT, font=f)
        rows.append((label, int(rec.F[k]), fuel[k], speed[k], attrs))
    img = img.crop((0, 0, Wd, yg + 44 + 64 + 90))
    P.saveimg(img, P.out('hud', 'panel.png'))
    for r in rows:
        print(r)


def put(d, x, y, rows, col, scale):
    for i, v in enumerate(rows):
        for b in range(8):
            c = col if v & (0x80 >> b) else (40, 42, 52)
            d.rectangle([x + b * scale, y + i * scale, x + b * scale + scale - 1, y + i * scale + scale - 1], fill=c)


def font():
    m = image()
    sc = 3
    cell = 8 * sc + 6
    W = 16 * cell * 2 + 60
    img = Image.new('RGB', (W, 6 * cell + 120 + 6 * cell + 70), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 6), 'PrintChar $A321 has two fonts: the ROM characters $20-$7F redrawn "split bold" (right), the 54 '
                    'glyphs $80-$B5', fill=P.K.TEXT, font=FONT(15))
    y0 = 52
    d.text((10, y0 - 20), 'the 48 ROM ($3C00 + 8 code), as the ROM prints it', fill=P.K.DIM, font=FONT(13))
    d.text((16 * cell + 50, y0 - 20), 'as PrintChar prints it: line 1 blank, the left nibble bold', fill=P.K.DIM,
           font=FONT(13))
    for k in range(96):
        code = 0x20 + k
        x, y = 10 + (k % 16) * cell, y0 + (k // 16) * cell
        put(d, x, y, m[0x3C00 + 8 * code:0x3C08 + 8 * code], (200, 200, 210), sc)
        put(d, x + 16 * cell + 40, y, printed_rom(m, code), (255, 220, 90), sc)
    y1 = y0 + 6 * cell + 44
    d.text((10, y1 - 24), 'the game\'s glyphs $80-$B5 at $B54F (8 lines as they are): the ZYNAPS logo $80-$A3 and '
                          '$A4-$B5 with the HEWSON lettering', fill=P.K.DIM, font=FONT(13))
    for k in range(54):
        code = 0x80 + k
        x, y = 10 + (k % 18) * (cell + 22), y1 + (k // 18) * (cell + 18)
        put(d, x, y, glyph(m, code), (120, 220, 255), sc)
        d.text((x, y + 8 * sc + 1), f'{code:02X}', fill=P.K.DIM, font=FONT(11))
    img = img.crop((0, 0, W, y1 + 3 * (cell + 18) + 10))
    P.saveimg(img, P.out('hud', 'font.png'))


def menufont():
    cpu = open(os.path.join(F1, 'menu1-cpu.bin'), 'rb').read()
    rom, made = cpu[0x3D00:0x4000], cpu[0xFD00:0x10000]
    rule = bytes((b | b >> 1) for b in rom)
    same = sum(1 for a, b in zip(made, rule) if a == b)
    sc = 3
    cell = 8 * sc + 6
    W = 16 * cell * 2 + 60
    img = Image.new('RGB', (W, 6 * cell + 160), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 6), 'The options menu\'s font: MakeFont $6FA2 copies the 48 ROM\'s characters ($3D00) into bank 7 at '
                    '$FD00, each row ORed with itself shifted right', fill=P.K.TEXT, font=FONT(15))
    d.text((10, 26), f'(f1, the running menu: {same} of 768 bytes at $FD00-$FFFF equal ROM | ROM >> 1); '
                     f'PrintText $6EE9 draws the menu with it', fill=P.K.DIM, font=FONT(13))
    y0 = 78
    d.text((10, y0 - 20), 'the 48 ROM, $3D00 + 8 (code - 32)', fill=P.K.DIM, font=FONT(13))
    d.text((16 * cell + 50, y0 - 20), 'bank 7, $FD00 + 8 (code - 32), as MakeFont left it', fill=P.K.DIM,
           font=FONT(13))
    for k in range(96):
        x, y = 10 + (k % 16) * cell, y0 + (k // 16) * cell
        put(d, x, y, rom[8 * k:8 * k + 8], (200, 200, 210), sc)
        put(d, x + 16 * cell + 40, y, made[8 * k:8 * k + 8], (120, 230, 255), sc)
    P.saveimg(img.crop((0, 0, W, y0 + 6 * cell + 10)), P.out('hud', 'menu-font.png'))


PAGES = [('credits: 21 (7, 0-6, 20, 2)', [21]),
         ('keys: 13, then 14-18', [13, 14, 15, 16, 17, 18]),
         ('selections: 19', [19]),
         ('level start: 24 (23 inside)', [24]),
         ('role of honour: 25, then 27', [25, 27]),
         ('no rank: 25, then 26', [25, 26]),
         ('high scores: 22, the table $8261', [22, 'table'])]


def pages():
    m = image()
    pics = []
    for title, msgs in PAGES:
        pr = Printer(m)
        if 'table' in msgs:
            pr.message(22)
            pr.attr = 0x46
            for e in range(5):            # HiScorePage: PrintString, then PrintBcd with C = '.', A' = $46
                a = 0x8261 + 14 * e
                pr.string(a)
                digits = ''.join(f'{v:02X}' for v in pr.m[a + 10:a + 14])
                lead = min(len(digits) - len(digits.lstrip('0')), 7)
                for ch in '.' * lead:
                    pr.char(ord(ch))
                pr.attr = 0x46
                for ch in digits[lead:]:
                    pr.char(ord(ch))
        elif 14 in msgs:
            pr.message(13)
            pr.set_row(5)
            for n in msgs[1:]:
                pr.message(n)
        else:
            for n in msgs:
                pr.message(n)
        pics.append((title, pr.picture(1)))
    W, H = 4 * (256 + 20) + 20, 2 * (192 + 40) + 90
    img = Image.new('RGB', (W, H), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 8), 'The pages the 28 messages make: the strings at $82EE printed by a model of\nPrintString $A401 on '
                    'blank screens\n("n" is PlayerDigit $84BB before the game writes the digit)', fill=P.K.TEXT,
           font=FONT(15))
    for k, (title, pic) in enumerate(pics):
        x, y = 20 + (k % 4) * (256 + 20), 90 + (k // 4) * (192 + 40)
        img.paste(pic, (x, y + 18))
        d.text((x, y), title, fill=P.K.TEXT, font=FONT(13))
    P.saveimg(img, P.out('hud', 'pages.png'))


MENU_NOTES = [  # (row, key, what it does, colour)
    (3, '1', 'Start $6EB3, E = 0: music and effects', (90, 230, 230)),
    (4, '2', 'Start, E = 1: effects only', (90, 230, 230)),
    (6, '3', 'toggles $7005; Start: JR ($18) at $B218', (230, 230, 230)),
    (7, '4', 'TurboKey $6E8A: the loader\'s reader', (230, 230, 230)),
    (9, '5', 'SaturnsKey $6E8F: FX 21 on / off', (230, 230, 230)),
    (10, '6', 'ShootingKey $6E94: NORMAL / DISABLED / CHANNEL', (230, 230, 230)),
    (11, '7', 'TimerKey $6EA3: the effects gate 0-9', (230, 230, 230)),
    (13, '8', 'hidden: toggles $7006; Start: RET at $9B50', (110, 140, 255)),
    (14, 'Q-P A S', 'hidden: SelectLevel $6E6F, LD B,n at $B073', (110, 140, 255)),
]


def menu():
    shots = [('as the boot leaves it (f1 m0)', os.path.join(F1, 'menu0-cpu.bin')),
             ('after the hidden key 0, then key 8 (f1 m1)', os.path.join(F1, 'menu1-cpu.bin'))]
    sc = 2
    W = 2 * (256 * sc + 20) + 470
    img = Image.new('RGB', (W, 192 * sc + 120), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 8), 'ZYNAPS OPTIONS (the driver file\'s menu, PrintText $6EE9): key 0 writes $16 (AT) over the zero at '
                    'TextEnd $7164, so the two hidden lines print', fill=P.K.TEXT, font=FONT(15))
    d.text((10, 28), 'the screens are the 6912 bytes of the running menu (f1); the notes on the right name each key\'s '
                     'routine and what Start $6EB3 writes into the game', fill=P.K.DIM, font=FONT(13))
    for k, (title, path) in enumerate(shots):
        cpu = open(path, 'rb').read()
        pic = P.screen(cpu).resize((256 * sc, 192 * sc), Image.NEAREST)
        x = 10 + k * (256 * sc + 20)
        img.paste(pic, (x, 76))
        d.text((x, 56), title + f': $7164 = ${cpu[0x7164]:02X}', fill=P.K.TEXT, font=FONT(13))
        if k == 1:
            for row, key, _, col in MENU_NOTES:
                y = 76 + row * 8 * sc
                d.rectangle([x, y - 1, x + 256 * sc - 1, y + 8 * sc], outline=col, width=1)
    x0 = 10 + 2 * (256 * sc + 20)
    for row, key, what, col in MENU_NOTES:
        y = 76 + row * 8 * sc
        d.line([x0 - 18, y + 8, x0 - 4, y + 8], fill=col, width=2)
        d.text((x0, y), f'key {key}: {what}', fill=col, font=FONT(13))
    P.saveimg(img, P.out('hud', 'menu.png'))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['panel', 'font', 'menufont', 'pages', 'menu'])
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'zgsB', 'e1', 'bot.npz'))
    p.add_argument('--frame', type=int, default=2200)
    a = p.parse_args()
    if a.what == 'panel':
        panel(a.npz, a.frame)
    else:
        {'font': font, 'menufont': menufont, 'pages': pages, 'menu': menu}[a.what]()


if __name__ == '__main__':
    sys.exit(main())

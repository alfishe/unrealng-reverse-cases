#!/usr/bin/env python3
"""The figures of doc 08 (text, fonts, HUD texts), from the case's build: both fonts, the small font's four shifts
against the bytes the death recording shows, the texts kept as data drawn in their own fonts, the menu screens.

    python3 tools/fig_text.py fonts   OUT.png     Font8x8 (bank 6 $F5E4) and SmallFont ($7C59), enlarged, with codes
    python3 tools/fig_text.py shifts  OUT.png     "AMM:078" ($FDC0) composed cell by cell; checked against death 8100
    python3 tools/fig_text.py sheet   OUT.png     every text kept as data, decoded and drawn in the font it selects
    python3 tools/fig_text.py screens OUT.png     the menu screens of doc 08 from the menu recording's screenshots
    python3 tools/fig_text.py panel   OUT.png     the cockpit panel (death 8139) with every field, its variable and routine
    python3 tools/fig_text.py list                the data sheet as markdown (address, bytes, decoded text)

Sources: build/game.bin (the Z80 view $5B00-$FFFF: banks 5, 2, 0) and build/bank6.bin (bank 6 from $C000), the
outputs of tools/build.sh; work/stage1/rec/menu/screens for the screenshots.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

C = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = open(os.path.join(C, 'build/game.bin'), 'rb').read()
BANK6 = open(os.path.join(C, 'build/bank6.bin'), 'rb').read()

# the operand count of each PrintString control code (ControlCodes $6F8F); the rest take none
OPS = {0: 1, 1: 1, 2: 2, 5: 1, 6: 1, 7: 2, 8: 2, 9: 1, 13: 1}

# The strings kept as data: (bank, address, what). Bank 0 means the Z80 view with bank 0 at $C000.
TEXTS = [
    (6, 0xF93F, 'options: the control menu (OptionsText)'),
    (6, 0xC5EE, 'load code prompt'),
    (6, 0xC53E, 'load code refused'),
    (6, 0xC72A, 'save code heading'),
    (6, 0xC8D9, 'tape prompt'),
    (6, 0xC90D, 'catalogue found'),
    (6, 0xC8A0, 'disk version leftover'),
    (6, 0xC8B2, 'disk version leftover'),
    (6, 0xCC94, 'failure heading'),
    (6, 0xCCAB, 'failure reason 1'),
    (6, 0xCCBE, 'failure reason 2'),
    (6, 0xCCD8, 'failure reason 3'),
    (6, 0xCCED, 'failure reason 4'),
    (6, 0xCD01, 'failure reason 5'),
    (6, 0xD3EA, 'status view: hit'),
    (6, 0xD401, 'status view: collision'),
    (6, 0xD418, 'final score (no reader)'),
    (6, 0xD46C, 'status screen totals'),
    (6, 0xC101, 'status clocks'),
    (6, 0xD6DA, 'weapon text 1 of 13'),
    (6, 0xD936, 'stores: payload'),
    (6, 0xD963, 'stores: payload exceeded'),
    (6, 0xD990, 'stores: number exceeded'),
    (6, 0xDA5E, 'quit prompt'),
    (6, 0xDAA1, 'status map legend'),
    (6, 0xDAE1, 'briefing map legend'),
    (0, 0xDB97, 'goal message'),
    (0, 0xC618, 'damage message'),
    (0, 0xD512, 'desertion warning: blank'),
    (0, 0xD520, 'desertion warning'),
    (0, 0xD0AB, 'number at $0000 (patched)'),
    (0, 0xFDC0, 'HUD: ammunition'),
    (0, 0xFDCD, 'HUD: turret mode MANUAL'),
    (0, 0xFDD7, 'HUD: turret mode AUTO'),
    (0, 0xFDE1, 'HUD: turret mode OFF'),
    (0, 0xFDEB, 'HUD: two numbers'),
    (0, 0xFDF9, 'HUD: one number'),
    (0, 0xFFCF, 'HUD: tank hit'),
    (0, 0xFFDB, 'HUD: collided'),
    (5, 0x7E2F, 'ClockText'),
    (5, 0x7C06, 'message line: blank'),
    (2, 0x87F0, 'BlankMessage'),
    (2, 0xBA6E, 'view name: IR SIGHT'),
    (2, 0xBA86, 'view name: REAR VIEW'),
    (2, 0xBA93, 'view name: BINOC X2'),
]


def rd(bank, a):
    """A byte of the Z80 view with BANK at $C000 (bank 0 / 5 / 2: the game image; 6: bank 6)"""
    if bank == 6 and a >= 0xC000:
        return BANK6[a - 0xC000]
    return GAME[a - 0x5B00]


def decode(bank, a, limit=400):
    """[(kind, value, operands)] of the string at A up to $FF; kind 'char', 'code' or 'token'"""
    out = []
    for _ in range(limit):
        c = rd(bank, a)
        a += 1
        if c == 0xFF:
            break
        if c < 0x20:
            k = OPS.get(c, 0)
            out.append(('code', c, [rd(bank, a + i) for i in range(k)]))
            a += k
        elif c >= 0x82:
            out.append(('token', c, []))
        else:
            out.append(('char', c, []))
    return out, a


def text_of(items):
    s = []
    for kind, v, ops in items:
        if kind == 'char':
            s.append({0x80: '{road}', 0x81: '{river}'}.get(v, chr(v)))
        elif kind == 'code':
            s.append('{%d%s}' % (v, ''.join(' $%02X' % o for o in ops)))
        else:
            s.append('{token $%02X}' % v)
    return ''.join(s)


def glyph8(c):
    o = 0xF5E4 + 8 * (c - 0x20) - 0xC000
    return BANK6[o:o + 8]


def glyph5(c):
    """The small font's 5 rows of C ("0" to "["), as stored: inverted, pixels in the high 5 bits"""
    o = 0x7C59 + 5 * (c - 0x30) - 0x5B00
    return GAME[o:o + 5]


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


BG, FG, GRID, LABEL = (18, 18, 24), (235, 235, 235), (70, 70, 84), (170, 170, 190)
YELLOW, BLACK = (255, 255, 0), (0, 0, 0)


def cmd_fonts(out):
    W = 1050
    f13, f11 = font(14), font(12)
    s8, s5 = 3, 4
    cell8 = 8 * s8 + 40
    rows8 = (98 + 15) // 16
    per5 = 12
    cell5w, cell5h = 6 * s5 + 58, 5 * s5 + 22
    rows5 = (44 + per5 - 1) // per5
    H = 40 + rows8 * (8 * s8 + 22) + 50 + rows5 * cell5h + 20
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Font8x8, bank 6 $F5E4-$F8F3: 98 glyphs for $20-$81, 8 bytes each, top row first '
           '(PrintChar $6FF0)', fill=FG, font=f13)
    y0 = 36
    for i in range(98):
        c = 0x20 + i
        x = 10 + (i % 16) * cell8
        y = y0 + (i // 16) * (8 * s8 + 22)
        g = glyph8(c)
        d.rectangle((x - 1, y - 1, x + 8 * s8, y + 8 * s8), outline=GRID)
        for r in range(8):
            for b in range(8):
                if g[r] & (0x80 >> b):
                    d.rectangle((x + b * s8, y + r * s8, x + b * s8 + s8 - 1, y + r * s8 + s8 - 1), fill=FG)
        d.text((x + 8 * s8 + 3, y + 4), '%02X' % c, fill=LABEL, font=f11)
    y0 = 36 + rows8 * (8 * s8 + 22) + 10
    d.text((10, y0), 'SmallFont, $7C59-$7D34: 44 glyphs "0" to "[", 5 bytes each, stored inverted (a 0 bit is a pixel)',
           fill=FG, font=f13)
    d.text((10, y0 + 18), 'the 6 bits of a cell as the panel shows them: clear bits yellow (paper), set bits black '
           '(ink); ":" is a space, "[" a full stop', fill=LABEL, font=f11)
    y0 += 42
    for i in range(44):
        c = 0x30 + i
        x = 10 + (i % per5) * cell5w
        y = y0 + (i // per5) * cell5h
        g = glyph5(c)
        for r in range(5):
            for b in range(6):
                col = BLACK if g[r] & (0x80 >> b) else YELLOW
                d.rectangle((x + b * s5, y + r * s5, x + b * s5 + s5 - 1, y + r * s5 + s5 - 1), fill=col)
        d.rectangle((x - 1, y - 1, x + 6 * s5, y + 5 * s5), outline=GRID)
        d.text((x + 6 * s5 + 6, y + 2), '%s %02X' % (chr(c), c), fill=LABEL, font=f11)
    im.save(out)
    print(out, im.size)


# The bytes the death recording shows at the start of frame 8100, pixel lines 5-9, screen bytes 2-7: AMM:078
RECORDED = [
    '11100011 10101110 10111111 11100011 00000110 00111111',
    '11011101 01010101 01011111 11011001 11101101 11011111',
    '11000001 01010101 01011111 11010101 11101110 00111111',
    '11011101 01110101 11011111 11001101 11011101 11011111',
    '11011101 01110101 11011111 11100011 11011110 00111111',
]
SHIFT_ROUTINE = {0: 'l_6E08', 6: 'l_6E20', 4: 'l_6E48', 2: 'l_6E84'}
SHIFT_COL = {0: (90, 160, 255), 6: (255, 120, 90), 4: (120, 220, 120), 2: (230, 120, 230)}


def compose_small(text, column, nbytes, background=0xFF):
    """Print TEXT from 6-pixel column COLUMN as PrintSmallChar does: cell k at pixel 6 k, the shift (6 k) AND 7
    picks the routine; each routine replaces the cell's 6 pixels (the 5 glyph bits and the gap bit) in the 16-bit
    pair of screen bytes. Returns 5 rows of NBYTES bytes and the cells [(char, pixel, shift)]"""
    rows = [[background] * nbytes for _ in range(5)]
    cells = []
    px = 6 * column
    for ch in text:
        c = ord(ch)
        shift = px & 7
        b = px >> 3
        g = glyph5(c)
        for r in range(5):
            pair = rows[r][b] << 8 | (rows[r][b + 1] if b + 1 < nbytes else 0)
            mask = 0xFC00 >> shift
            val = (g[r] & 0xFC) << 8 >> shift
            pair = pair & ~mask | val
            rows[r][b] = pair >> 8 & 255
            if b + 1 < nbytes:
                rows[r][b + 1] = pair & 255
        cells.append((ch, px, shift))
        px += 6
    return rows, cells


def cmd_shifts(out):
    rec = [[int(x, 2) for x in r.split()] for r in RECORDED]
    rows, cells = compose_small('AMM:078', 3, 8)
    # compare the cells' own pixels (bytes 2-7, pixels 18-59): the text "AMM:078" from column 3
    start, end = 18, 18 + 6 * 7
    same = all(((rows[r][(x >> 3)] >> (7 - (x & 7))) & 1) == ((rec[r][(x >> 3) - 2] >> (7 - (x & 7))) & 1)
               for r in range(5) for x in range(start, end))
    print('composed = recorded (death 8100, lines 5-9, pixels 18-59):', same)
    W = 1050
    s = 20
    f13, f11 = font(14), font(13)
    x0, y0 = 40, 60
    nb = 6
    H = y0 + 5 * s + 260
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'PrintSmallChar prints "AMM:078" ($FDC0: code 7 line 5 column 3) in 6-pixel cells over 8-pixel '
           'bytes:', fill=FG, font=f13)
    d.text((10, 28), 'the cell\'s pixel offset in its byte picks one of four routines (ShiftRoutines $6E9F)',
           fill=FG, font=f13)
    for r in range(5):
        for x in range(nb * 8):
            byte = rec[r][x >> 3]
            on = byte >> (7 - (x & 7)) & 1
            X, Y = x0 + x * s, y0 + r * s
            d.rectangle((X, Y, X + s - 2, Y + s - 2), fill=BLACK if on else YELLOW)
    # byte boundaries
    for b in range(nb + 1):
        X = x0 + b * 8 * s - 1
        d.line((X, y0 - 8, X, y0 + 5 * s + 6), fill=FG, width=2)
        if b < nb:
            d.text((x0 + b * 8 * s + 4 * s - 30, y0 + 5 * s + 8), 'byte %d' % (b + 2), fill=LABEL, font=f11)
    # cells
    for ch, px, shift in cells:
        X = x0 + (px - 16) * s
        col = SHIFT_COL[shift]
        d.rectangle((X, y0 - 6, X + 6 * s - 2, y0 - 2), fill=col)
        d.rectangle((X, y0 + 5 * s + 30, X + 6 * s - 2, y0 + 5 * s + 34), fill=col)
        d.text((X + 2, y0 + 5 * s + 38), '"%s"' % (' ' if ch == ':' else ch), fill=col, font=f11)
        d.text((X + 2, y0 + 5 * s + 56), 'px %d' % px, fill=col, font=f11)
        d.text((X + 2, y0 + 5 * s + 74), '+%d' % shift, fill=col, font=f11)
    ly = y0 + 5 * s + 104
    for i, (shift, what) in enumerate([(0, 'offset 0: one byte, AND $03 keeps 2 pixels'),
                                        (2, 'offset 2: one byte, AND $C0 keeps 2 pixels, glyph >> 2'),
                                        (4, 'offset 4: two bytes, 4 pixels in the first, 2 in the next'),
                                        (6, 'offset 6: two bytes, 2 pixels in the first, 4 in the next')]):
        X = 20
        Y = ly + i * 22
        d.rectangle((X, Y + 3, X + 14, Y + 15), fill=SHIFT_COL[shift])
        d.text((X + 20, Y), f'{SHIFT_ROUTINE[shift]} ${ {0: "6E08", 2: "6E84", 4: "6E48", 6: "6E20"}[shift]}: {what}',
               fill=FG, font=f11)
    d.text((20, ly + 96), 'The pixels: death, start of frame 8100, screen lines 5-9, bytes 2-7; '
           'the composition from the font gives the same ' + ('bits' if same else 'bits? NO'), fill=LABEL, font=f11)
    d.text((20, ly + 116), 'The next cell: offset (offset - 2) AND 7, one byte on when the offset was not 0 '
           '(SmallFontAdvance $6DC0)', fill=LABEL, font=f11)
    im.save(out)
    print(out, im.size)


def render_text(items, scale=2):
    """Lines of (font, char) runs as PrintString lays them: positioning codes start a new line in the sheet"""
    lines = [[]]
    small = False
    for kind, v, ops in items:
        if kind == 'code':
            if v in (5, 6, 7):
                small = True
            elif v in (1, 2):
                small = False
            if v in (1, 2, 6, 7, 10, 11) and lines[-1]:
                lines.append([])
            if v == 8:
                lines[-1].append((small, 'num'))
        elif kind == 'char':
            lines[-1].append((small, v))
    return [ln for ln in lines if ln]


def draw_line(d, x, y, run, s):
    for small, v in run:
        if v == 'num':
            for c in '000':
                x = draw_char(d, x, y, small, ord(c), s, dim=True)
            continue
        x = draw_char(d, x, y, small, v, s)
    return x


def draw_char(d, x, y, small, c, s, dim=False):
    if small:
        if not 0x30 <= c <= 0x5B:
            c = 0x3A
        g = glyph5(c)
        col = (190, 190, 120) if dim else YELLOW
        for r in range(5):
            for b in range(6):
                if not g[r] & (0x80 >> b):
                    d.rectangle((x + b * s, y + (r + 1) * s, x + b * s + s - 1, y + (r + 2) * s - 1), fill=col)
        return x + 6 * s
    g = glyph8(c) if 0x20 <= c <= 0x81 else bytes(8)
    col = (150, 150, 150) if dim else FG
    for r in range(8):
        for b in range(8):
            if g[r] & (0x80 >> b):
                d.rectangle((x + b * s, y + r * s, x + b * s + s - 1, y + r * s + s - 1), fill=col)
    return x + 8 * s


def cmd_sheet(out):
    W = 1050
    s = 2
    f11 = font(12)
    entries = []
    for bank, a, what in TEXTS:
        items, end = decode(bank, a)
        entries.append((bank, a, end, what, render_text(items)))
    lh = 8 * s + 6
    H = 34 + sum(max(1, len(e[4])) * lh + 8 for e in entries) + 10
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The texts kept as data, drawn by their own fonts from the bytes (tools/fig_text.py sheet); '
           'code-8 numbers as grey 000', fill=FG, font=f11)
    y = 34
    for bank, a, end, what, lines in entries:
        d.text((10, y + 2), f'bank {bank} ${a:04X}', fill=LABEL, font=f11)
        d.text((10, y + 18), what[:26], fill=(120, 120, 140), font=font(11)) if len(lines) > 1 else None
        for ln in lines:
            draw_line(d, 210, y, ln, s)
            y += lh
        y += 8
        d.line((10, y - 4, W - 10, y - 4), fill=(40, 40, 50))
    im.save(out)
    print(out, im.size)


SCREENS = [
    ('006287-mission-1-marked.png', 'catalogue, mission 1 chosen (menu 6287)'),
    ('006431-mission-1-briefing.png', 'briefing, mission 1 (menu 6431)'),
    ('010686-status.png', 'status screen (menu 10686)'),
    ('010817-save-code.png', 'save code (menu 10817)'),
    ('001874-load-typed.png', 'load code typed (menu 1874)'),
    ('000095-options.png', 'options (menu 95)'),
]


def cmd_screens(out):
    base = os.path.join(C, 'work/stage1/rec/menu/screens')
    tw, th = 512, 384
    pad, lab = 8, 24
    W = 1050  # 2 * tw + 3 * pad is 1048: one more pixel each side
    H = 3 * (th + lab + pad) + pad
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f = font(14)
    for i, (name, what) in enumerate(SCREENS):
        x = pad + 1 + (i % 2) * (tw + pad)
        y = pad + (i // 2) * (th + lab + pad)
        p = Image.open(os.path.join(base, name)).convert('RGB')
        if p.size != (tw, th):
            p = p.resize((tw, th), Image.NEAREST)
        d.text((x, y), what, fill=FG, font=f)
        im.paste(p, (x, y + lab))
    im.save(out)
    print(out, im.size)


# The cockpit's fields: (x0, y0, x1, y1) in Spectrum pixels, the label, what it shows, the routine. The boxes are the
# bounding boxes of the writes in death 8093-8159 and 8600-8611 (writers_map traces), by routine.
PANEL = [
    ((16, 4, 63, 10), 'AMM:078', '$C527 rounds, code 8: 3 digits', 'PrintAmmo $C519, string $FDC0'),
    ((16, 16, 63, 21), 'slot line', 'MANUAL/AUTO/OFF, range, timer', 'PrintSlotName $D313 ($FDCD...)'),
    ((80, 0, 87, 23), 'ammo bar', 'slot rounds / 4, 24 lines', 'UpdateAmmoBars $7336, DrawBar $744F'),
    ((128, 0, 231, 23), 'slot icons', 'the four slots $8368', 'DrawSlotIcons $73BA'),
    ((0, 32, 255, 126), '3D view', 'the back buffer', 'copy l_89A8 (doc 06)'),
    ((96, 118, 159, 126), 'message', 'TANK:HIT, COLLIDED, views', 'MessageOnce $7D5D, MessageTimer $87D6'),
    ((32, 138, 55, 142), 'bearing', 'BearingTo - heading', 'DrawBearing $D637 (bank 6)'),
    ((64, 144, 71, 175), 'speed bar', 'abs($7E8E) / 2 lines, at most 29', 'DrawSpeedBar $D612 (bank 6)'),
    ((80, 144, 87, 175), 'fuel bar', '$7C58 / 2 (fuel high byte)', 'DrawFuelBar $D629 (bank 6)'),
    ((176, 132, 215, 163), 'radar', 'blip list $6768', 'DrawRadar $C05E, PlotRadarPixel $A9FE'),
    ((176, 177, 207, 183), 'heading', '$7612 heading, shifted strip', 'DrawHeadingStrip $D598 (bank 6)'),
    ((224, 145, 231, 150), 'lamp', 'flips $3C, 4 lines $525C', 'BlinkLamp $8475, 8 frames'),
    ((192, 150, 199, 153), 'marks', 'flips bits $30 at $5758, $5078', 'BlinkWarning $8459, 12 frames'),
]
PANEL_COL = [(255, 80, 80), (255, 160, 60), (255, 230, 60), (140, 230, 90), (90, 200, 255), (200, 120, 255),
             (255, 110, 200), (120, 255, 200), (255, 255, 255), (80, 160, 255), (255, 200, 140), (255, 90, 90),
             (190, 190, 255)]


def cmd_panel(out):
    shot = Image.open(os.path.join(C, 'work/stage1/rec/death/screens/008139-drive-01.png')).convert('RGB')
    W = 1050
    sx, sy = 2, 2
    f13, f12 = font(14), font(12)
    top = 30
    rowh = 20
    H = top + 384 + 16 + rowh * len(PANEL) + 40
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 6), 'The cockpit panel and its writers: death, frame 8139 (screenshot); boxes from the write traces '
           '8093-8159, 8600-8611', fill=FG, font=f13)
    x0 = 10
    im.paste(shot, (x0, top))
    for i, ((a, b, c, e), name, what, who) in enumerate(PANEL):
        col = PANEL_COL[i % len(PANEL_COL)]
        if name == '3D view':
            d.rectangle((x0 + a * sx, top + b * sy, x0 + c * sx + 1, top + e * sy + 1), outline=col, width=1)
        else:
            d.rectangle((x0 - 1 + a * sx, top - 1 + b * sy, x0 + c * sx + 2, top + e * sy + 2), outline=col, width=2)
        tx = x0 + c * sx + 4 if c < 240 else x0 + a * sx + 4
        ty = top + b * sy - 2
        if name == '3D view':
            tx, ty = x0 + 80 * sx, top + 40 * sy
        elif name == 'marks':
            tx, ty = x0 + a * sx - 22, top + b * sy - 4
        d.rectangle((tx, ty, tx + 16, ty + 15), fill=(0, 0, 0))
        d.text((tx + 2, ty), '%d' % (i + 1), fill=col, font=f12)
    # the legend on the right of the screenshot and below it
    lx = x0 + 512 + 16
    d.text((lx, top), 'n  field: what it shows', fill=LABEL, font=f12)
    for i, (box, name, what, who) in enumerate(PANEL):
        col = PANEL_COL[i % len(PANEL_COL)]
        d.text((lx, top + 20 + i * 28), '%-2d %s: %s' % (i + 1, name, what), fill=col, font=f12)
        d.text((lx + 26, top + 34 + i * 28), who, fill=LABEL, font=f12)
    y = top + 384 + 12
    d.text((x0, y), 'Not written in either window: the clock face and the three green lamps (drawn once with the panel '
           'picture).', fill=LABEL, font=f12)
    d.text((x0, y + 18), 'The screenshot is the Spectrum screen at 2x. The ammo bar and the fuel bar share column 10 '
           '(x 80-87): one at lines 0-23, one at lines 144-175.', fill=LABEL, font=f12)
    im = im.crop((0, 0, W, y + 44))
    im.save(out)
    print(out, im.size)


def cmd_list():
    print('| Bank | Address | Bytes | Use | Decoded (control codes in braces) |')
    print('| --- | --- | --- | --- | --- |')
    for bank, a, what in TEXTS:
        items, end = decode(bank, a)
        t = text_of(items).replace('|', '\\|')
        print(f'| {bank} | `${a:04X}-${end - 1:04X}` | {end - a} | {what} | `{t}` |')


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'list':
        cmd_list()
    elif cmd in ('fonts', 'shifts', 'sheet', 'screens', 'panel') and len(sys.argv) > 2:
        globals()['cmd_' + cmd](sys.argv[2])
    else:
        sys.exit(__doc__)

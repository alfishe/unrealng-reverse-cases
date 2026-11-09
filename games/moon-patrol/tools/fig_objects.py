#!/usr/bin/env python3
"""Figures of docs/07-objects.md (writer mpB). Each subcommand draws one figure into docs/img/objects/.

  python3 tools/fig_objects.py list    list.png    the object list at $BEF8 after the first two segments of the
                                                   Beginner course ($B7E8): every record byte by byte, by kind
  python3 tools/fig_objects.py boxes   boxes.png   the buggy's box ($B212) and a rock's box at four moments: apart,
                                                   touching, jumped over (x AND $FC equal), in the air but low
  python3 tools/fig_objects.py movers  movers.png  x against passes for the ground movers, from the handlers' rules:
                                                   rock / crater / mine, tank, shell, low flyer (its two pauses)
  python3 tools/fig_objects.py all

Data: the image work/mkgame/original.bin (the course script, the record templates of the spawners, the sprites).
No emulator is needed; the UFO records' random fields are marked as such.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_rendering as R  # noqa: E402

K = R.K
MEM = R.MEM
W = R.W
F, FB, FS = R.F, R.FB, R.FS
R.OUT = os.path.join(R.CASE, 'docs', 'img', 'objects')

KIND = {0x9A92: ('ObjCrater', (230, 210, 60)), 0x99C3: ('ObjRock', (200, 140, 90)),
        0x9978: ('ObjPoint', (200, 110, 230)), 0x99A3: ('ObjLamps', (240, 120, 160)),
        0x9B6B: ('UfoHandler', (90, 200, 120)), 0x975E: ('ListStop', (150, 150, 170))}


def build_list():
    """Run the spawners of the first two Beginner segments the way the commands write their records."""
    recs = []
    a = 0xB7E8
    segs = 0
    while segs < 2:
        w = MEM[a] | MEM[a + 1] << 8
        a += 2
        if w == 0x976C:
            a += 2
        elif w == 0x9760:
            segs += 1
        elif w == 0x97E8:
            while MEM[a] != 0xFF:
                recs.append((0x9A92, [MEM[a], 0x00], None)); a += 1
            a += 1
        elif w == 0x97C5:
            while MEM[a] != 0xFF:
                recs.append((0x99C3, [MEM[a], 0x0F, 0x94, 0xF4, 0x0C, 0x0C], None)); a += 1
            a += 1
        elif w == 0x9775:
            recs.append((0x9978, [MEM[a], MEM[a + 1]], None)); a += 2
        elif w == 0x97AD:
            while MEM[a] != 0xFF:
                recs.append((0x99A3, [MEM[a], MEM[a + 1]], None)); a += 2
            a += 1
        elif w in (0x9821, 0x9827):
            t = 1 if w == 0x9821 else 5
            while MEM[a] != 0xFF:
                f = [MEM[a], t, 0xFF, 0x00, None, None, None, 0x08, 0x0F, None, 0x1D, 0xFF, 4, 4, None, None, 5, 5]
                recs.append((0x9B6B, f, {4, 5, 6, 9})); a += 1
            a += 1
        else:
            raise SystemExit('unknown command $%04X at $%04X' % (w, a - 2))
    recs.append((0x975E, [], None))
    return recs


def fig_list():
    recs = build_list()
    im, d = R.canvas(900)
    R.title(d, 'The object list at $BEF8 after the first two segments of the Beginner course',
            'One box a byte, 16 bytes a row; each record starts with its handler word; ? = random (R XOR FRAMES)')
    cell = 52
    x0, y0 = 90, 80
    addr = 0xBEF8
    col = 0
    row = 0
    legend = {}
    for h, fields, rnd in recs:
        name, c = KIND[h]
        legend[name] = c
        data = [h & 0xFF, h >> 8] + fields
        for i, v in enumerate(data):
            if col == 0:
                d.text((16, y0 + row * (cell + 6) + 16), '$%04X' % (addr), font=FS, fill=K.DIM)
            x = x0 + col * (cell + 3)
            y = y0 + row * (cell + 6)
            fill = c if i < 2 else tuple(int(v_ * 0.45) for v_ in c)
            d.rectangle([x, y, x + cell, y + cell], fill=fill)
            if i == 0:
                d.rectangle([x, y, x + 3, y + cell], fill=(255, 255, 255))
            txt = '?' if (rnd and (i - 2) in rnd) else ('%02X' % v if v is not None else '--')
            d.text((x + 13, y + 16), txt, font=F, fill=(0, 0, 0) if i < 2 else K.TEXT)
            addr += 1
            col += 1
            if col == 16:
                col = 0
                row += 1
    y = y0 + (row + 1) * (cell + 6) + 14
    x = 16
    for name, c in legend.items():
        d.rectangle([x, y, x + 18, y + 18], fill=c)
        d.text((x + 24, y), name, font=FS, fill=K.TEXT)
        x += 30 + int(FS.getlength(name)) + 20
    d.text((16, y + 28), 'Bright boxes: the handler word (white bar: the record start). Dark: the delay, then the '
           'fields.', font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, y + 56)), 'list.png')
    return recs


def fig_boxes():
    im, d = R.canvas(600)
    R.title(d, 'BoxOverlap $A7FE: the buggy\'s box against a rock\'s, four moments',
            'Lines 120-163, x 32-111, 4 screen px a pixel. Grey: the sprites as drawn. Frames: the boxes it compares')
    buggy = R.bits(0xE140, 5, 23)
    rock = R.bits(0xDB10, 3, 12)
    s = 4
    cases = [('apart: rock x $5C', 0x92, 0x5C, 'carry: no contact'),
             ('touching: rock x $54', 0x92, 0x54, 'NC: BuggyKill'),
             ('over it: rock x $38, buggy y $80', 0x80, 0x38, 'carry, and x AND $FC = $38: 80'),
             ('in the air, too low: y $8A', 0x8A, 0x40, 'NC: BuggyKill')]
    x0s = [16, 16 + 80 * s + 40]
    y = 80
    for k, (name, by, rx, res) in enumerate(cases):
        x = x0s[k % 2]
        if k == 2:
            y += 44 * s + 70
        d.text((x, y), name, font=FS, fill=K.TEXT)
        d.text((x, y + 20), res, font=FS, fill=(255, 210, 70))
        oy = y + 44
        d.rectangle([x, oy, x + 80 * s, oy + 44 * s], fill=(0, 0, 0), outline=R.GRID)

        def px(gx, gy, c):
            if 32 <= gx < 112 and 120 <= gy < 164:
                d.rectangle([x + (gx - 32) * s, oy + (gy - 120) * s, x + (gx - 32) * s + s - 1,
                             oy + (gy - 120) * s + s - 1], fill=c)
        for yy in range(23):
            for xx in range(40):
                if buggy[yy][xx]:
                    px(0x38 + xx, by - 9 + yy, (190, 190, 190))
        for yy in range(12):
            for xx in range(24):
                if rock[yy][xx]:
                    px(rx + xx, 0x94 + yy, (200, 140, 90))
        for (bx, byy, bw, bh, c) in ((0x38, by, 0x1D, 0x0D, (90, 160, 255)), (rx, 0x94, 0x0C, 0x0C, (230, 90, 80))):
            d.rectangle([x + (bx - 32) * s, oy + (byy - 120) * s, x + (bx + bw - 32) * s, oy + (byy + bh - 120) * s],
                        outline=c, width=2)
        d.line([x, oy + (160 - 120) * s, x + 80 * s, oy + (160 - 120) * s], fill=(230, 210, 60))
    tx = x0s[1] + 80 * s + 30
    for i, t in enumerate(['blue: the buggy, y, x $38,', '  height $0D, width $1D', 'red: the rock, y $94,',
                           '  12 x 12', 'yellow line: line 160']):
        d.text((tx, 120 + i * 22), t, font=FS, fill=K.TEXT)
    R.save(im.crop((0, 0, W, y + 44 + 44 * s + 14)), 'boxes.png')


def fig_movers():
    im, d = R.canvas(620)
    R.title(d, 'The ground movers: x against main-loop passes, from the handlers\' rules (buggy alive)',
            'One dot a pass; x 0-255 up the side; the dashed line is the buggy at x $38')
    ox, oy, pw, ph = 70, 90, 900, 400
    passes = 100
    d.rectangle([ox, oy, ox + pw, oy + ph], outline=R.GRID)
    for xv in range(0, 257, 64):
        yy = oy + ph - xv * ph / 256
        d.text((ox - 50, yy - 9), '$%02X' % min(xv, 255), font=FS, fill=K.DIM)
        d.line([ox, yy, ox + pw, yy], fill=(32, 32, 44))
    for pv in range(0, passes + 1, 20):
        xx = ox + pv * pw / passes
        d.text((xx - 10, oy + ph + 6), str(pv), font=FS, fill=K.DIM)
    yb = oy + ph - 0x38 * ph / 256
    for xx in range(ox, ox + pw, 12):
        d.line([xx, yb, xx + 6, yb], fill=(190, 190, 190))

    def series(xs, c, label, ly):
        pts = [(ox + i * pw / passes, oy + ph - x * ph / 256) for i, x in enumerate(xs) if x is not None]
        for p in pts:
            d.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=c)
        d.text(ly, label, font=FS, fill=c)
    rock = []
    x = 0xF4
    for i in range(passes):
        rock.append(x if x > 0 else None)
        x = x - 4 if x > 0 else 0
    tank, shell = [], []
    x = 0xE7
    sx = None
    for i in range(passes):
        tank.append(x if (x is not None and 0 < x < 256) else None)
        x = x - 4 if x is not None else None
        if x is not None and x <= 0:
            x = None
        if i == 8:
            sx = 0xC1
        shell.append(sx)
        if sx is not None:
            sx -= 6
            if sx < 0:
                sx = None
    flyer = []
    x, wait = 0, 0
    for i in range(passes):
        flyer.append(x)
        if x == 0x0F:                       # $A060: the first pause (16-23, random), 20 drawn
            wait = 20
        if x < 0x10:
            x += 1
            continue
        if x == 0x88:                       # $A07F: the second pause (4-11, random), 8 drawn
            wait = 8
        if x in (0x10, 0x8C):
            wait -= 1
            if wait:
                continue
        x += 4
        if x == 0xF0:
            break
    flyer += [None] * (passes - len(flyer))
    series(rock, (200, 140, 90), 'rock: -4 a pass', (ox, oy + ph + 34))
    series(tank, (90, 200, 120), 'tank: -4 a pass', (ox + 200, oy + ph + 34))
    series(shell, (230, 90, 80), 'shell: -6 a pass', (ox + 400, oy + ph + 34))
    series(flyer, (90, 160, 255), 'low flyer: +1, stop at $10, +4, stop at $8C', (ox, oy + ph + 58))
    d.text((ox + pw - 60, oy + ph + 26), 'passes', font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, oy + ph + 90)), 'movers.png')


SIZES = {0xAFDD: (2, 4), 0xB003: (2, 8), 0xB02A: (2, 9), 0xB069: (3, 8), 0xB0BA: (3, 8), 0xB0E2: (3, 12),
         0xB10D: (3, 16), 0xB115: (3, 16), 0xB184: (4, 16), 0xB1C8: (5, 23)}

KINDS = [('UFO saucer A ($9821)', [1, 2, 3, 4]), ('UFO saucer B ($9827)', [5, 6, 7, 8, 9, 10]),
         ('spinner ($982D)', [11, 12, 13, 14]), ('bomb, falling bomb, bomb crater', [0x1D, 0x1E, 0x10]),
         ('UFO explosions', [0x26, 0x28, 0x2A, 0x2E, 0x30]), ('rock, its explosion', [0x0F, 0x2A, 0x2C]),
         ('mine (blink)', [0x11, 0x12]), ('tank, its explosion', [0x13, 0x32, 0x34]),
         ('low flyer, its explosion', [0x14, 0x36, 0x38]), ('boulders: small, medium, large', [0x40, 0x44, 0x4C]),
         ('green plant: stem frames', [0x64, 0x67, 0x6A, 0x6D]), ('green plant: head frames', [0x74, 0x76, 0x78])]


def sprite(n):
    a = 0xB2D6 + 4 * n
    drw = MEM[a] | MEM[a + 1] << 8
    g = MEM[a + 2] | MEM[a + 3] << 8
    wb, h = SIZES.get(drw, (0, 0))
    return drw, g, wb, h


def fig_kinds():
    im, d = R.canvas(1400)
    R.title(d, 'The object kinds as drawn (slot 0 of each sprite, from SpriteTable $B2D6)',
            '3 screen pixels a Spectrum pixel; the label is the sprite number; frames of one kind left to right')
    s = 3
    x0, y = 16, 72
    col = 0
    rowh = 0
    for name, sprs in KINDS:
        x = x0 + col * 520
        d.text((x, y), name, font=FS, fill=K.TEXT)
        cx = x
        hmax = 0
        for n in sprs:
            drw, g, wb, h = sprite(n)
            if not wb:
                raise SystemExit('sprite $%02X: drawer $%04X not sized' % (n, drw))
            d.text((cx, y + 22), '$%02X' % n, font=FS, fill=K.DIM)
            bw, bh = R.draw_bits(d, cx, y + 44, R.bits(g, wb, h), s, bytelines=False)
            cx += bw + 14
            hmax = max(hmax, bh)
        rowh = max(rowh, 44 + hmax + 16)
        col += 1
        if col == 2:
            col, y, rowh = 0, y + rowh, 0
    R.save(im.crop((0, 0, W, y + rowh + 4)), 'kinds.png')


FIGS = {'kinds': fig_kinds, 'list': fig_list, 'boxes': fig_boxes, 'movers': fig_movers}

if __name__ == '__main__':
    names = sys.argv[1:] or ['all']
    for n in (FIGS if names == ['all'] else names):
        FIGS[n]()

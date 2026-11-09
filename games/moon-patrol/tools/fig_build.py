#!/usr/bin/env python3
"""The figure of doc 03 (build and load), 1050 pixels wide, into docs/img/load/.

    python3 tools/fig_build.py tape    # the four blocks of orig/MoonPatrol.tap.zip in time, and where they land

The times are the ROM's standard timing, from the bytes of each block (flag and checksum included): a pilot of 8063
pulses for a header and 3223 for data, 2168 T each; the sync pulses 667 + 735 T; a 0 bit 2 x 855 T, a 1 bit
2 x 1710 T; 3 500 000 T a second. The pauses are the TZX's (orig/, doc 03 3.1).
"""
import io
import os
import sys
import zipfile

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig_design import BG, F13, F14B, F16B, GREY, INK, WIDTH  # noqa: E402

CASE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(CASE, 'docs', 'img', 'load')
PAUSES_MS = [1014, 2170, 1088, 5712]
COLS = [(120, 120, 200), (60, 160, 90), (120, 120, 200), (210, 80, 60)]
NAMES = ['header "MOONPATROL"', 'BASIC', 'header "MOON"', 'the game, 40 712 bytes']


def blocks():
    z = zipfile.ZipFile(os.path.join(CASE, 'orig', 'MoonPatrol.tap.zip'))
    tap = z.read('Moon Patrol.tap')
    i, out = 0, []
    while i < len(tap):
        n = tap[i] | tap[i + 1] << 8
        out.append(tap[i + 2:i + 2 + n])
        i += 2 + n
    return out


def times(body):
    """(pilot seconds, data seconds) of one block at ROM speed"""
    pilot = (8063 if body[0] == 0 else 3223) * 2168 + 667 + 735
    ones = sum(bin(b).count('1') for b in body)
    data = ones * 3420 + (len(body) * 8 - ones) * 1710
    return pilot / 3.5e6, data / 3.5e6


def tape():
    bl = blocks()
    segs = []
    t = 0.0
    for k, body in enumerate(bl):
        p, dt = times(body)
        segs.append((k, t, t + p, 'pilot'))
        segs.append((k, t + p, t + p + dt, 'data'))
        t += p + dt
        segs.append((k, t, t + PAUSES_MS[k] / 1000.0, 'pause'))
        t += PAUSES_MS[k] / 1000.0
    total = t
    img = Image.new('RGB', (WIDTH, 470), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 6), 'The tape at ROM speed: %.1f s with the TZX pauses; four standard blocks, no turbo' % total,
           font=F16B, fill=INK)
    x0, x1 = 30, WIDTH - 30
    sx = (x1 - x0) / total
    y = 60
    for k, a, b, kind in segs:
        xa, xb = x0 + a * sx, x0 + b * sx
        if kind == 'pilot':
            d.rectangle((xa, y, max(xa + 1, xb), y + 34), fill=(200, 200, 200))
        elif kind == 'data':
            d.rectangle((xa, y, max(xa + 1, xb), y + 34), fill=COLS[k])
        else:
            d.rectangle((xa, y + 14, max(xa + 1, xb), y + 20), fill=(235, 235, 230))
    for s in range(0, int(total) + 1, 30):
        x = x0 + s * sx
        d.line((x, y + 36, x, y + 42), fill=INK)
        d.text((x - 10, y + 44), '%d s' % s, font=F13, fill=INK)
    # labels of the four blocks, staggered
    ly = y + 70
    for k in range(4):
        a = [s for s in segs if s[0] == k and s[3] == 'pilot'][0][1]
        b = [s for s in segs if s[0] == k and s[3] == 'data'][0][2]
        p, dt = times(bl[k])
        xa = x0 + a * sx
        row = ly + 20 * k
        d.line((xa, y + 34, xa, row + 6), fill=COLS[k])
        d.text((xa + 4, row - 2), 'block %d: %s, %d bytes on tape: pilot %.1f s + data %.1f s' % (
            k, NAMES[k], len(bl[k]), p, dt), font=F13, fill=INK)
    d.rectangle((x0, ly + 86, x0 + 14, ly + 98), fill=(200, 200, 200))
    d.text((x0 + 20, ly + 84), 'pilot and sync', font=F13, fill=INK)
    d.rectangle((x0 + 170, ly + 90, x0 + 184, ly + 94), fill=(205, 205, 200))
    d.text((x0 + 190, ly + 84), 'pause (TZX)', font=F13, fill=INK)
    # the memory bar
    my = 300
    d.text((16, my - 44), 'Where the blocks land, $4000-$FFFF', font=F14B, fill=INK)
    m0, m1 = 30, WIDTH - 30
    mx = (m1 - m0) / 0xC000

    def X(a):
        return m0 + (a - 0x4000) * mx
    d.rectangle((X(0x4000), my, X(0xFFFF), my + 40), outline=GREY, fill=(245, 245, 240))
    d.rectangle((X(0x4000), my, X(0x5AFF), my + 40), fill=(200, 200, 210))
    d.text((X(0x4000) + 4, my + 12), 'screen', font=F13, fill=INK)
    d.rectangle((X(0x5CCB), my, X(0x5CCB + 187) + 1, my + 40), fill=COLS[1])
    d.rectangle((X(0x60F8), my, X(0xFFFF), my + 40), fill=COLS[3])
    d.text((X(0x6400), my + 12), 'block 3: the game, $60F8-$FFFF (LOAD "" CODE at the header\'s 24824)', font=F13,
           fill=(255, 255, 255))
    marks = [(0x5CCB, 'BASIC at PROG $5CCB', 0), (0x60F7, 'RAMTOP $60F7 (CLEAR 24823) for the load', 1),
             (0x8000, 'entry $8000 (USR 32768)', 0), (0xC34F, 'RAMTOP $C34F (CLEAR 49999): inside the image', 2)]
    for a, text, row in marks:
        x = X(a)
        d.line((x, my - 4, x, my + 52 + 22 * row), fill=INK, width=2)
        tw = d.textlength(text, font=F13)
        tx = x + 4 if x + 4 + tw < WIDTH - 8 else x - 4 - tw
        d.text((tx, my + 46 + 22 * row), text, font=F13, fill=INK)
    for a in (0x4000, 0x8000, 0xC000, 0xFFFF):
        d.text((X(a) - (40 if a == 0xFFFF else 0), my - 18), '$%04X' % a, font=F13, fill=GREY)
    d.text((16, 440), 'python3 tools/fig_build.py tape     (times from the TAP\'s bytes at the ROM\'s timing; '
           'pauses from the TZX)', font=F13, fill=GREY)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, 'tape.png')
    img.save(out)
    print(out, img.size, 'total %.1f s' % total, [(len(b), '%.1f+%.1f' % times(b)) for b in bl])


if __name__ == '__main__':
    tape()

#!/usr/bin/env python3
"""Figures of doc 10 (gameplay logic).

  python3 tools/fig_gameplay.py password --score 4000 --done 1 docs/img/gameplay/save-code.png

The save code: the 32-bit score and the ten mission flags packed into ten characters by EncodePassword $CE2E (bank 6),
computed here from the code's rules, not from a recording. 1050 px wide, fonts 11 pt or more.
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

W = 1050
BG = (20, 22, 26)
FG = (230, 230, 230)
DIM = (150, 150, 160)
SC = (90, 170, 250)      # score bits
FL = (250, 190, 70)      # mission flags
CK = (120, 220, 120)     # checksum
F11, F12, F14, F16 = (kitlib.font(n) for n in (11, 12, 14, 16))
ALPHABET = '9876543210ZYXWVUTSRQPONMLKJIHABCDEFG'


def encode(score, done):
    sb = score.to_bytes(4, 'little')
    flags = [0xFF if i + 1 in done else 0 for i in range(10)]
    nib = []
    for b in sb:
        nib += [b >> 4, b & 15]
    vals = [nib[i] | (flags[i] & 0x10) for i in range(8)]
    c = sb[0] ^ sb[1] ^ sb[2] ^ sb[3]
    vals.append((flags[8] & 1) | (flags[9] & 2) | (c & 7) << 2)
    vals.append((c >> 3) & 0x1F)
    return sb, flags, nib, c, vals


def fig_password(out, score, done):
    sb, flags, nib, c, vals = encode(score, done)
    img = Image.new('RGB', (W, 470), BG)
    dr = ImageDraw.Draw(img)
    dr.text((14, 10), 'The save code: score %d, missions done %s (EncodePassword $CE2E, worked from the code)'
            % (score, ','.join(map(str, done)) or 'none'), font=F16, fill=FG)
    # the score bytes
    dr.text((14, 46), 'Score $CC79, low byte first:', font=F14, fill=DIM)
    for i, b in enumerate(sb):
        x = 250 + i * 198
        dr.rectangle((x, 44, x + 188, 70), outline=SC)
        dr.text((x + 6, 48), 'byte %d = $%02X (%s %s)' % (i, b, format(b >> 4, '04b'), format(b & 15, '04b')),
                font=F12, fill=FG)
    dr.text((14, 84), 'checksum = XOR of the 4 bytes = $%02X = %s' % (c, format(c, '08b')), font=F14, fill=CK)
    # the ten values: 5 bits each
    top = 130
    dr.text((14, top), 'value', font=F12, fill=DIM)
    dr.text((14, top + 36), 'bits 4..0', font=F12, fill=DIM)
    dr.text((14, top + 120), 'char', font=F12, fill=DIM)
    cw = 96
    for i, v in enumerate(vals):
        x = 90 + i * cw
        dr.text((x + 30, top), '%d: %d' % (i, v), font=F12, fill=FG)
        for k in range(5):
            bit = (v >> (4 - k)) & 1
            if i < 8:
                col = FL if k == 0 else SC
            elif i == 8:
                col = CK if k < 3 else FL
            else:
                col = CK
            bx = x + 4 + k * 17
            dr.rectangle((bx, top + 30, bx + 15, top + 60), fill=col if bit else BG, outline=col)
            dr.text((bx + 4, top + 36), str(bit), font=F12, fill=BG if bit else col)
        if i < 8:
            lab = ('flag %d' % (i + 1), 'nibble %d' % i)
        elif i == 8:
            lab = ('chk 2..0', 'flag 10, 9')
        else:
            lab = ('chk 7..3', '')
        dr.text((x + 4, top + 66), lab[0], font=F11, fill=DIM)
        dr.text((x + 4, top + 82), lab[1], font=F11, fill=DIM)
        dr.rectangle((x + 22, top + 110, x + 66, top + 150), outline=FG)
        dr.text((x + 37, top + 118), ALPHABET[v], font=F16, fill=FG)
    code = ''.join(ALPHABET[v] for v in vals)
    y = top + 180
    dr.text((14, y), 'code: %s    (alphabet $CF5F: value 0 = "9", 10 = "Z", 29 = "A")' % code, font=F16, fill=FG)
    y += 40
    for col, t in ((SC, 'score nibble, Score byte n/2, high nibble first'),
                   (FL, 'mission flag: bit 4 of MissionsDone 1-8; bits 0, 1 for missions 9, 10'),
                   (CK, 'checksum bits: 3 in value 8, 5 in value 9 (covers the score only)')):
        dr.rectangle((14, y + 2, 30, y + 16), fill=col)
        dr.text((40, y), t, font=F12, fill=FG)
        y += 26
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print(out, code)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('password')
    p.add_argument('--score', type=int, default=4000)
    p.add_argument('--done', default='1')
    p.add_argument('out')
    a = ap.parse_args()
    if a.cmd == 'password':
        fig_password(a.out, a.score, [int(x) for x in a.done.split(',') if x])


if __name__ == '__main__':
    main()

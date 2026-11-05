#!/usr/bin/env python3
"""Decodes a scroller text of the intros: KOI-7 N2 letters (lower case Latin and @[\\]^ ` {|}~ drawn as Cyrillic
by the intro's own font), $01 LO HI switches the font (HI $3D: the ROM's Latin font, read as ASCII), $00 ends.

  scroller_text.py IMAGE BASE START [--end END]

IMAGE is a file whose first byte is at BASE (hex); START (hex) the text's first byte.
"""
import argparse

LOWER = dict(zip('@abcdefghijklmnopqrstuvwxyz[\\]^`{|}~',
                 'юабцдефгхийклмнопярстужвьызшэщчюшэщч'))


def koi7(b):
    c = chr(b)
    if 'a' <= c <= 'z' or c in '{|}~`':
        return LOWER[c]
    if 'A' <= c <= 'Z' or c in '\\':
        return LOWER[c.lower() if c != '\\' else '|'].upper()
    return c


def decode(img, base, start, end=None):
    out, i, latin = [], start - base, False
    while i < len(img) and (end is None or i + base < end):
        b = img[i]
        if b == 0:
            out.append('\n[$00: end]')
            break
        if b == 1:
            font = img[i + 1] | img[i + 2] << 8
            latin = (font >> 8) == 0x3D
            out.append(f'[font ${font:04X}]')
            i += 3
            continue
        out.append(chr(b) if latin and 32 <= b < 127 else koi7(b) if 32 <= b < 127 else f'<{b:02X}>')
        i += 1
    return ''.join(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('image')
    p.add_argument('base')
    p.add_argument('start')
    p.add_argument('--end')
    a = p.parse_args()
    img = open(a.image, 'rb').read()
    print(decode(img, int(a.base, 16), int(a.start, 16), int(a.end, 16) if a.end else None))


if __name__ == '__main__':
    main()

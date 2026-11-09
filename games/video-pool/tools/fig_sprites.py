#!/usr/bin/env python3
"""The first sprite sheet of the case (stage 1): the pre-shifted ball sprites at $D000 and the 8x8 font at $DEF4,
drawn from the image (tools/image.py), each cell labelled with its address; the drawing routine in the title.

    python3 tools/fig_sprites.py --image work/mkgame/original.bin --out docs/img/sprites/balls-and-font.png

Balls: 56 sprites of 3 bytes x 16 lines (48 bytes), index = shift x 7 + ball (cue, 1-6), shift 0-7 pixels right,
$D000-$DA7F, XORed onto the screen by $959F (3 bytes a line, `INC H` down). Font: 36 glyphs of 8 bytes, a-z then
0-9, $DEF4-$E013, read by the print routine $9E7C.
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

INK, PAPER, GRID, TEXT, BG = (0, 0, 0), (0, 205, 0), (90, 90, 90), (235, 235, 235), (24, 24, 28)


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def glyph(mem, addr, wbytes, h, scale, ink=INK, paper=PAPER):
    img = Image.new('RGB', (wbytes * 8 * scale, h * scale), paper)
    d = ImageDraw.Draw(img)
    for y in range(h):
        for xb in range(wbytes):
            b = mem[addr + y * wbytes + xb]
            for bit in range(8):
                if b >> (7 - bit) & 1:
                    x = xb * 8 + bit
                    d.rectangle([x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1], fill=ink)
    return img


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--image', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    mem = open(args.image, 'rb').read()
    s = 4
    cw, ch = 24 * s + 14, 16 * s + 34
    left, top = 90, 84
    W = left + 7 * cw + 20
    fy = top + 8 * ch + 50
    H = fy + 5 * (8 * s + 30) + 60
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    f, fb, fs = font(15), font(19), font(13)
    d.text((10, 8), 'Video Pool: every ball pre-shifted 8 times, and the font', font=fb, fill=TEXT)
    d.text((10, 32), 'balls $D000-$DA7F, XORed onto the screen by $959F; 24 x 16 pixels each (3 bytes x 16 lines)',
           font=fs, fill=(190, 190, 190))
    d.text((10, 48), 'one row per shift 0-7 pixels; green = paper, black = set bits; font $DEF4, printed by $9E7C',
           font=fs, fill=(190, 190, 190))
    names = ['cue', '1', '2', '3', '4', '5', '6']
    for b, n in enumerate(names):
        d.text((left + b * cw + 30, top - 18), n, font=f, fill=TEXT)
    for sh in range(8):
        d.text((10, top + sh * ch + 20), f'shift {sh}', font=f, fill=TEXT)
        for b in range(7):
            a = 0xD000 + (sh * 7 + b) * 48
            x, y = left + b * cw, top + sh * ch
            img.paste(glyph(mem, a, 3, 16, s), (x, y))
            d.rectangle([x - 1, y - 1, x + 24 * s, y + 16 * s], outline=GRID)
            d.text((x, y + 16 * s + 3), '$%04X' % a, font=fs, fill=(200, 200, 200))
    d.text((10, fy - 30), 'the font: 36 glyphs of 8 x 8, a-z then 0-9, 8 bytes each', font=f, fill=TEXT)
    chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    gw = 8 * s + 40
    per = (W - 20) // gw
    for i, c in enumerate(chars):
        a = 0xDEF4 + i * 8
        x, y = 10 + (i % per) * gw, fy + (i // per) * (8 * s + 30)
        img.paste(glyph(mem, a, 1, 8, s, ink=(255, 255, 255), paper=(0, 0, 160)), (x, y))
        d.text((x, y + 8 * s + 2), '%s $%04X' % (c, a), font=fs, fill=(200, 200, 200))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    img.save(args.out)
    print(args.out, img.size)


if __name__ == '__main__':
    main()

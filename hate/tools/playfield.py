#!/usr/bin/env python3
"""The playfield of H.A.T.E. as the game keeps it and as the blit `$D35E` shows it (docs/06-rendering.md).

Input: a 64 K memory image of a moment between two passes (`memanim.py`'s memory_at, saved as a .bin). The scroll
state `$C32E` / `$C32F` in it is already the next pass's; the blit that drew the screen ran with the state before
(`--state-before`, the default, undoes the step of `$D3F9`).

Panels: the 32 strips the screen shows, side by side as stored (unskewed); the same strips placed by the blit's
address list `$D5B2` (lines that land in ROM are dropped); the real screen of the moment.

    python3 playfield.py mem.bin out.png [--scale 2] [--state-now]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zxscreen  # noqa: E402

LIST, ENTRIES = 0xD5B2, 528


def state_before(mem):
    """$D3F9 toggles $C32F between 0 and $80, and steps $C32E when it goes from $80 to 0"""
    c32e, c32f = mem[0xC32E], mem[0xC32F]
    return (c32e, 0x00) if c32f == 0x80 else ((c32e - 1) & 63, 0x80)


def strips(mem, c32e, c32f):
    """For each screen column: (buffer page, first byte) of its 128-line strip"""
    d = 0x80 + c32e + (c32f & 0x7F)
    out = []
    for j in range(32):
        out.append((d, (c32f & 0xFE) if j % 2 == 0 else c32f))
        d += 2
        if d >= 0xC0:
            d -= 0x40
    return out


def blit(mem, c32e, c32f):
    """{screen address: byte} as $D35E writes them"""
    pops = [mem[a] | mem[a + 1] << 8 for a in range(LIST, LIST + 2 * ENTRIES, 2)]
    out, it = {}, iter(pops)
    for j, (d, e) in enumerate(strips(mem, c32e, c32f)):
        for n in ([4] + [8] * 15 + [4]) if j % 2 == 0 else [8] * 16:
            hl = next(it)
            for k in range(n):
                address = (hl - 0x100 * k) & 0xFFFF
                if 0x4000 <= address < 0x5800:
                    out[address] = mem[(d << 8) | e]
                e = (e + 1) & 0xFF
    return out


def bits(img, x0, y0, byte, scale, ink=(230, 230, 230)):
    for b in range(8):
        if byte & (0x80 >> b):
            img.paste(ink, (x0 + b * scale, y0, x0 + (b + 1) * scale, y0 + scale))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('mem')
    p.add_argument('png')
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--state-now', action='store_true', help='use $C32E / $C32F as they are in the image')
    args = p.parse_args()
    mem = open(args.mem, 'rb').read()
    c32e, c32f = (mem[0xC32E], mem[0xC32F]) if args.state_now else state_before(mem)
    s = args.scale
    font = ImageFont.load_default()
    w, h = 256 * s, 192 * s
    img = Image.new('RGB', (3 * w + 4 * 16, h + 40), (24, 24, 30))
    draw = ImageDraw.Draw(img)

    # 1: the strips as stored, byte 0 at the bottom (the blit draws upward)
    x0, y0 = 16, 28
    panel = Image.new('RGB', (w, h), (12, 12, 16))
    for j, (d, e) in enumerate(strips(mem, c32e, c32f)):
        for k in range(128):
            bits(panel, j * 8 * s, (191 - k) * s, mem[(d << 8) | ((e + k) & 0xFF)], s)
    img.paste(panel, (x0, y0))
    draw.text((x0, 8), f'stored: 32 strips of 128 lines ($C32E={c32e}, $C32F=${c32f:02X})', fill=(220, 220, 200),
              font=font)

    # 2: the blit's placement, ink only
    x1 = x0 + w + 16
    panel = Image.new('RGB', (w, h), (12, 12, 16))
    for address, byte in blit(mem, c32e, c32f).items():
        y = ((address >> 8) & 7) | ((address >> 2) & 0x38) | ((address >> 5) & 0xC0)
        bits(panel, (address & 31) * 8 * s, y * s, byte, s)
    img.paste(panel, (x1, y0))
    draw.text((x1, 8), 'placed by the address list $D5B2', fill=(220, 220, 200), font=font)

    # 3: the screen
    x2 = x1 + w + 16
    img.paste(zxscreen.render(mem[0x4000:0x5B00], s), (x2, y0))
    draw.text((x2, 8), 'the screen', fill=(220, 220, 200), font=font)
    img.save(args.png)


if __name__ == '__main__':
    main()

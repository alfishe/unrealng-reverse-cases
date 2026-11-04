#!/usr/bin/env python3
"""Render a ZX Spectrum screen (6912 bytes, or a 64 K image with the screen at $4000) to a PNG.

    python3 zxscreen.py image.bin out.png [--scale 2] [--flash-off]
"""
import argparse

from PIL import Image

BASIC = (0, 0xCD)
BRIGHT = (0, 0xFF)


def palette(index, bright):
    level = (BRIGHT if bright else BASIC)[1]
    return (level if index & 2 else 0, level if index & 4 else 0, level if index & 1 else 0)


def render(screen, scale=2):
    image = Image.new('RGB', (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x0000 | ((y & 0xC0) << 5) | ((y & 0x07) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            bits = screen[row + column]
            attr = screen[0x1800 + (y >> 3) * 32 + column]
            ink, paper = palette(attr & 7, attr & 0x40), palette((attr >> 3) & 7, attr & 0x40)
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if bits & (0x80 >> bit) else paper
    return image.resize((256 * scale, 192 * scale), Image.NEAREST) if scale != 1 else image


def main():
    p = argparse.ArgumentParser()
    p.add_argument('image')
    p.add_argument('png')
    p.add_argument('--scale', type=int, default=2)
    args = p.parse_args()
    data = open(args.image, 'rb').read()
    screen = data[0x4000:0x5B00] if len(data) == 0x10000 else data[:6912]
    render(screen, args.scale).save(args.png)


if __name__ == '__main__':
    main()

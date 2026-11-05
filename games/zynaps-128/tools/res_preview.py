#!/usr/bin/env python3
"""Previews of the graphics resources (src/res/gfx, README there): each set at 2x, a grid line between bytes, the
sprites drawn as the game shows them (the object's paper colour where block 2's bit is set, black elsewhere), the
tiles and wave cells as ink on paper. For looking only: the source is the editable PNG beside each preview.

    python3 tools/res_preview.py [--image work/mkgame/original.bin] [--out src/res/gfx]

The bytes come from the image (block 2's bytes, as the set-up moves them; copied from the 48K case, ../zynaps/tools), at the addresses of src/res/gfx/README.md.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_gfx  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCALE = 2
GRID = (60, 60, 72)
GAP_COLOUR = (40, 40, 48)
KINDS = []  # res_formats.py loads every tools/res_*.py as a plugin: this one adds no format
RESOURCES = [  # (name, address, size, ink colour)
    ('tiles', 0xBC00, 2048, (205, 205, 205)),
    ('wave-cells', 0xC400, 1024, (0, 205, 0)),
    ('sprites', 0xE000, 0x748, (205, 205, 0)),
    ('pod', 0xF048, 192, (0, 0, 205)),
]


def preview(png_bytes, ink, rows):
    import io
    src = Image.open(io.BytesIO(png_bytes))
    w, h = src.size
    out = Image.new('RGB', (w * SCALE, h * SCALE), GAP_COLOUR)
    px = out.load()
    for y in range(h):
        for x in range(w):
            v = src.getpixel((x, y))
            colour = GAP_COLOUR if v == 2 else (ink if v == 1 else (0, 0, 0))
            for dy in range(SCALE):
                for dx in range(SCALE):
                    px[x * SCALE + dx, y * SCALE + dy] = colour
    draw = ImageDraw.Draw(out)
    for x in range(0, w, 8):  # a line left of every byte column
        draw.line([(x * SCALE, 0), (x * SCALE, h * SCALE - 1)], fill=GRID)
    for y in range(0, h, 8) if rows else ():  # the tiles' 8-line rows
        draw.line([(0, y * SCALE), (w * SCALE - 1, y * SCALE)], fill=GRID)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--image', default=os.path.join(ROOT, 'work', 'mkgame', 'original.bin'))
    p.add_argument('--out', default=os.path.join(ROOT, 'src', 'res', 'gfx'))
    args = p.parse_args()
    image = open(args.image, 'rb').read()
    os.makedirs(args.out, exist_ok=True)
    for name, addr, size, ink in RESOURCES:
        data = image[addr:addr + size]
        path = os.path.join(args.out, f'{name}.preview.png')
        preview(res_gfx.to_editable(data, f'gfx/{name}.bin'), ink, name == 'tiles').save(path)
        print(path)
    return 0


if __name__ == '__main__':
    sys.exit(main())

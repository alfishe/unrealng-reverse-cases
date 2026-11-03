#!/usr/bin/env python3
"""PNG previews of the game's graphic resources (src/res, listed in src/res/README.md): the screens, the font, the
course tiles, the sprite blocks and the explosion frames. The previews are for looking only; the source of the game
is the .bin / .scr files, assembled with INCBIN.

    python3 tools/res_preview.py [--out docs/img/res] [--scale 3]

Sprite blocks (docs/06-rendering.md 6.6): four pre-shifted frames, each a row of strips 8 pixels wide; a strip is a
mask byte and a pixel byte a line, the first pair the bottom line (the blit shows the buffer column bottom line
first). The last frame is one strip narrower. Drawn as the game draws them: AND mask, OR pixels; a pixel whose mask
bit is set and pixel bit clear is transparent (shown as the checkered background).
"""
import argparse
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zxscreen  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'src', 'res')

INK, PAPER = (230, 230, 230), (24, 24, 32)
CHECK = ((70, 70, 80), (90, 90, 100))
GAP = 4

# Block size: (lines a strip, strips of frames 0-3), docs/06-rendering.md 6.6
SPRITE_LAYOUT = {
    630: (21, (4, 4, 4, 3)),  # types 0-3
    420: (14, (4, 4, 4, 3)),  # pads and dishes
    374: (17, (3, 3, 3, 2)),  # types 4-10
    182: (13, (2, 2, 2, 1)),  # types 11-13
    168: (21, (4,)),          # an explosion frame (drawn as a type 3)
}


def bitmap(data, columns, glyphs, height=8, width_bytes=1):
    """Glyphs of 1 bit a pixel, one byte a line, laid out in a grid"""
    rows = (glyphs + columns - 1) // columns
    w, h = 8 * width_bytes + 1, height + 1
    image = Image.new('RGB', (columns * w + 1, rows * h + 1), (60, 60, 70))
    px = image.load()
    for g in range(glyphs):
        x0, y0 = 1 + (g % columns) * w, 1 + (g // columns) * h
        for y in range(height):
            byte = data[g * height + y]
            for bit in range(8):
                px[x0 + bit, y0 + y] = INK if byte & (0x80 >> bit) else PAPER
    return image


def sprite_block(data):
    lines, frames = SPRITE_LAYOUT[len(data)]
    strip = lines * 2
    widest = max(frames)
    image = Image.new('RGB', (len(frames) * (widest * 8 + GAP) + GAP, lines + 2 * GAP), (60, 60, 70))
    px = image.load()
    at = 0
    for f, strips in enumerate(frames):
        x0 = GAP + f * (widest * 8 + GAP)
        for s in range(widest):
            for y in range(lines):
                for bit in range(8):
                    px[x0 + s * 8 + bit, GAP + y] = CHECK[((s * 8 + bit) // 2 + y // 2) & 1]
        for s in range(strips):
            for line in range(lines):
                mask, pixels = data[at + 2 * line], data[at + 2 * line + 1]
                y = GAP + lines - 1 - line
                for bit in range(8):
                    m, p = mask & (0x80 >> bit), pixels & (0x80 >> bit)
                    if p:
                        px[x0 + s * 8 + bit, y] = INK
                    elif not m:
                        px[x0 + s * 8 + bit, y] = PAPER
            at += strip
    assert at == len(data), (len(data), at)
    return image


def save(image, path, scale):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.resize((image.width * scale, image.height * scale), Image.NEAREST).save(path)
    print(os.path.relpath(path, ROOT))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'res'))
    p.add_argument('--scale', type=int, default=3)
    args = p.parse_args()
    read = lambda name: open(os.path.join(RES, name), 'rb').read()  # noqa: E731
    for name in ('loading', 'game'):
        save(zxscreen.render(read(f'screens/{name}.scr'), 1), os.path.join(args.out, f'screen-{name}.png'), 2)
    font = read('gfx/font.bin')
    save(bitmap(font, 16, len(font) // 8), os.path.join(args.out, 'font.png'), args.scale)
    tiles = read('gfx/tiles.bin')
    save(bitmap(tiles, 18, len(tiles) // 8), os.path.join(args.out, 'tiles.png'), args.scale)
    for kind in ('sprites', 'explosions'):
        folder = os.path.join(RES, 'gfx', kind)
        for name in sorted(os.listdir(folder)):
            if name.endswith('.bin'):
                save(sprite_block(read(f'gfx/{kind}/{name}')),
                     os.path.join(args.out, kind, name[:-4] + '.png'), args.scale)
    return 0


if __name__ == '__main__':
    sys.exit(main())

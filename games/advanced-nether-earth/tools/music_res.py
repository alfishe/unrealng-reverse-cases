#!/usr/bin/env python3
"""The music part's resources (src/res/music/): the title cards of bank 1 as PNG, the build turns them into bytes.

| Source | Built | Format |
| --- | --- | --- |
| `title-eternity-industry.png` | `titles/eternity-industry.bin` | 192 x 32, a byte a column of 8 pixels, the pixel lines in order (24 bytes a line), bit 7 left, white = ink |
| `title-presents.png` | `titles/presents.bin` | 96 x 32 (12 bytes a line) |
| `title-advanced-nether-earth.png` | `titles/advanced-nether-earth.bin` | 144 x 56 (18 bytes a line) |

The tunes (`*.pt2`, `*.pt3`) are turned into bytes by tools/music_ptmodule.py.

    python3 tools/music_res.py build --out build/music/res      # every PNG to its .bin
    python3 tools/music_res.py export IMAGE BASE                # the bitmaps out of a bank 1 image to the PNGs
"""
import argparse
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res', 'music')
TITLES = [('eternity-industry', 0xD9AB, 24, 32), ('presents', 0xDCAB, 12, 32), ('advanced-nether-earth', 0xDE2B, 18, 56)]


def to_png(data, w, h):
    im = Image.new('1', (w * 8, h))
    for y in range(h):
        for x in range(w * 8):
            im.putpixel((x, y), (data[y * w + x // 8] >> (7 - x % 8)) & 1)
    return im


def from_png(path, w, h):
    im = Image.open(path).convert('1')
    assert im.size == (w * 8, h), f'{path}: {im.size}, want {(w * 8, h)}'
    out = bytearray(w * h)
    for y in range(h):
        for x in range(w * 8):
            if im.getpixel((x, y)):
                out[y * w + x // 8] |= 0x80 >> (x % 8)
    return bytes(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    b = s.add_parser('build')
    b.add_argument('--out', required=True)
    e = s.add_parser('export')
    e.add_argument('image')
    e.add_argument('base', type=lambda v: int(v, 16))
    a = p.parse_args()
    for name, addr, w, h in TITLES:
        png = os.path.join(RES, f'title-{name}.png')
        if a.cmd == 'build':
            os.makedirs(os.path.join(a.out, 'titles'), exist_ok=True)
            open(os.path.join(a.out, 'titles', f'{name}.bin'), 'wb').write(from_png(png, w, h))
        else:
            d = open(a.image, 'rb').read()[addr - a.base:addr - a.base + w * h]
            to_png(d, w, h).save(png)


if __name__ == '__main__':
    main()

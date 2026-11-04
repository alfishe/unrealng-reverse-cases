#!/usr/bin/env python3
"""Editable sources for ANE's resources (src/res/README.md); the build turns them into the bytes it assembles.

| Source | Built | Format |
| --- | --- | --- |
| `gfx/game-font.png` | `gfx/game-font.bin` | the game's Cyrillic font ($C500-$C6FF, codes $20-$5F), NE's font format: 8 x 8 glyphs, 16 a row, index 0 paper, 1 ink |
| `text/nether-plus-w.txt` | (tools/mkdisk.py) | the file NETHER+.W: UTF-8 here, CP866 with CR LF on the disk |

The glyph format and its PNG palette are Nether Earth's (games/nether-earth/tools/res_formats.py, used as is).

    python3 tools/res_formats.py build --out build/res      # every source to its .bin
    python3 tools/res_formats.py export FONT.bin            # the font bytes to src/res/gfx/game-font.png
"""
import argparse
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, os.path.join(ROOT, '..', 'nether-earth', 'tools'))
import res_formats as ne  # noqa: E402

FONT = 'gfx/game-font.png'


def build(out):
    data = ne.png_to_font(Image.open(os.path.join(RES, FONT)), FONT)
    path = os.path.join(out, 'gfx', 'game-font.bin')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def export(font_bin):
    ne.font_to_png(open(font_bin, 'rb').read()).save(os.path.join(RES, FONT))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    b = s.add_parser('build')
    b.add_argument('--out', required=True)
    e = s.add_parser('export')
    e.add_argument('font')
    a = p.parse_args()
    if a.cmd == 'build':
        build(a.out)
    else:
        export(a.font)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The loading picture as the loader draws it: python3 tools/fig_loading.py [OUT.png] [ROM]

Reads src/res/loader/PictureText.txt (24 rows of 32 codes) and src/res/loader/PictureGraphics.png and draws them as
PrintPictureChar $5FC9 does: codes below $5F from the ROM font ($3C00 + 8 x code, from the 48K ROM, by default
$UNREAL_NG/data/rom/48.rom), $5F and up from PictureGraphics (frame = code - $60). The attributes are the bands of
Loader $5F1D-$5F9D, replayed fill by fill (FillAttributes $5FC4 calls and the INC HL skips between them); the flashing
"IS LOADING" is drawn in its first phase. Writes docs/img/loading.png (scale 2) by default.
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as rf  # noqa: E402

COL = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0),
       (215, 215, 215)]
# Loader's fills from $5800 in order: (cells skipped before the fill, attribute, count)
FILLS = [(0, 7, 8), (0, 5, 16), (0, 7, 8)] * 2 + [
    (0, 6, 96), (0, 7, 43), (0, 0x85, 10), (0, 7, 12), (0, 0x10, 30)] + [(2, 0x17, 30)] * 5 + [
    (2, 2, 30), (1, 5, 160), (1, 0x10, 30)] + [(2, 0x17, 30)] * 3 + [(2, 2, 30)]


def attributes():
    a, p = bytearray(768), 0
    for skip, v, n in FILLS:
        p += skip
        a[p:p + n] = bytes([v]) * n
        p += n
    return a


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(rf.ROOT, 'docs', 'img', 'loading.png')
    rom = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.environ.get('UNREAL_NG', ''), 'data', 'rom',
                                                             '48.rom')
    with open(rom, 'rb') as f:
        font = f.read()[0x3C00:0x4000]
    with open(os.path.join(rf.RES, 'loader', 'PictureText.txt'), 'rb') as f:
        text = rf.page_in('loader/PictureText.bin', f.read())
    with open(os.path.join(rf.RES, 'loader', 'PictureGraphics.png'), 'rb') as f:
        graphics = rf.png_to_sheet(f.read())
    attr = attributes()
    img = Image.new('RGB', (256, 192))
    px = img.load()
    for row in range(24):
        for col in range(32):
            code = text[row * 32 + col]
            g = font[code * 8:code * 8 + 8] if code < 0x5F else graphics[(code - 0x60) * 8:(code - 0x60) * 8 + 8]
            at = attr[row * 32 + col]
            ink, paper = COL[at & 7], COL[at >> 3 & 7]
            for k in range(8):
                for bit in range(8):
                    px[col * 8 + bit, row * 8 + k] = ink if g[k] >> (7 - bit) & 1 else paper
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.resize((512, 384), Image.NEAREST).save(out)
    print(out)


if __name__ == '__main__':
    main()

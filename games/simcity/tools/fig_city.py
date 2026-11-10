#!/usr/bin/env python3
"""A whole city map (96 x 96 cells, 768 x 768 pixels) drawn from the resources and a saved city.

The tiles come from the editable sheets src/res/graphics/Cells.png and Buildings.png (tools/res_formats.py turns
them into the bytes the game draws from: CellTiles `$EA68` / CellAttrs `$F530`, BuildingTiles `$ED58` /
BuildingAttrs `$F58E`). The city is the map a SAVE writes (SaveCity: a 31-byte header block and the 9216-byte map
`$C450`, both flag `$FF`) or the map in a memory image (.szx). The cells are decoded the way DrawView `$650B` and
StartBuilding `$655B` do: a byte below `$80` is cell tile n; a byte `$80-$BF` starts a building row (first AND 7
cells wide), the `$C0-$FF` bytes after it go on with it, cell k of the row showing building tile
(second AND `$3F`) x 8 + (third AND 7) + k. Left out, as in tools/fig_tiles.py: the blink (BlinkCell, the `$A0-$AF`
buildings) and the road traffic tiles (RoadTraffic).

    python3 tools/fig_city.py work/stage1/rec/menus/town.tap scratch.png        # a saved city
    python3 tools/fig_city.py work/stage1/rec/metro/end.szx scratch.png         # the map in a memory image
    python3 tools/fig_city.py ... out.png --header                              # print the save header too
"""
import argparse
import io
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import res_formats as RF  # noqa: E402

SIDE, MAP = 96, 0xC450


def tiles(sheet):
    t, a = RF.png_to_tiles(open(os.path.join(RF.RES, 'graphics', sheet), 'rb').read())
    return t, a


def tap_blocks(path):
    d = open(path, 'rb').read()
    i, out = 0, []
    while i + 2 <= len(d):
        n = d[i] | d[i + 1] << 8
        out.append(d[i + 2:i + 2 + n])
        i += 2 + n
    return out


def load_city(path):
    """(the 9216 map bytes, the 31-byte header or None)"""
    if path.lower().endswith('.szx'):
        import szx
        mem = szx.read(path)[0]
        return bytes(mem[MAP:MAP + SIDE * SIDE]), None
    header = city = None
    for b in tap_blocks(path):
        if len(b) == 33 and b[0] == 0xFF:
            header = b[1:32]
        if len(b) == SIDE * SIDE + 2 and b[0] == 0xFF:
            city = b[1:-1]
    if city is None:
        raise SystemExit('fig_city: no 9216-byte map block in %s' % path)
    return city, header


def draw(city):
    ct, ca = tiles('Cells.png')
    bt, ba = tiles('Buildings.png')
    img = Image.new('RGB', (SIDE * 8, SIDE * 8))
    px = img.load()
    for r in range(SIDE):
        row = city[r * SIDE:(r + 1) * SIDE]
        c = 0
        while c < SIDE:
            v = row[c]
            if v < 0x80:
                put(px, c, r, ct, ca, v)
                c += 1
                continue
            back = 0
            while row[c - back] >= 0xC0:      # a row cut by the left edge (FindBuildingStart)
                back += 1
            s = c - back
            n = (row[s + 1] & 0x3F) * 8 + (row[s + 2] & 7) + back
            for k in range((row[s] & 7) - back):
                if c < SIDE:
                    put(px, c, r, bt, ba, n + k)
                c += 1
    return img


def put(px, c, r, t, a, n):
    attr = a[n]
    for y in range(8):
        b = t[n * 8 + y]
        for x in range(8):
            ink = (b >> (7 - x)) & 1
            px[c * 8 + x, r * 8 + y] = RF.zx_rgb(attr & 7 if ink else (attr >> 3) & 7, (attr >> 6) & 1)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('city')
    p.add_argument('out')
    p.add_argument('--header', action='store_true')
    args = p.parse_args()
    city, header = load_city(args.city)
    if args.header and header:
        funds = header[12] | header[13] << 8 | header[14] << 16
        print('file %r funds %d month %d year %d city %r' % (header[:12].decode('latin-1'), funds, header[16],
              header[17] | header[18] << 8, header[20:31].decode('latin-1')))
    draw(city).save(args.out)
    print('fig_city: %s' % args.out)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""A first map of every level, drawn from the game image's data alone (tools/image.py).

    python3 tools/mapdraw.py work/mkgame/original.bin docs/img/maps [--scale 1]

The data, read from the code: the level table `$E4AE` (11 bytes a level) points at the level's first zone record
(bytes 8-9); zone records are 7 bytes from `$D55C` (byte 0 the char set, 0 or 1; bytes 1-2 the zone's map; 3-4 its
exits table; 5-6 its objects), the zones of a level running up to the next level's first record (LevelZones, `$D64A`
the end). A zone's map is rows of eight tile numbers (`$AD5A`: (row / 4) x 8 + map); a tile is 4 x 4 char codes at
`$C31C` + tile x 16; a char is 8 bytes at `$7100` + code x 8 (set 0) or `$7A00` + code x 8 (set 1, `$AC83`), its
attribute byte at `$7900` + code or `$8200` + code. A zone's rows run up to the next zone's map. Each level is one
PNG: its zones side by side (six to a row), in the order of their records, each headed by its record's address
and its height in tile rows.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

B = 0x5B00
LEVELS = 0xE4AE
ZONES_END = 0xD64A
TILES = 0xC31C
CHARS = (0x7100, 0x7A00)
ATTRS = (0x7900, 0x8200)
NAMES = ('South America', 'Egypt', 'Schwarzendumpf castle', 'Missile base')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=1)
    a = ap.parse_args()
    img = open(a.image, 'rb').read()
    rd = lambda adr, n=1: img[adr - B:adr - B + n]  # noqa: E731
    w16 = lambda adr: rd(adr)[0] | rd(adr + 1)[0] << 8  # noqa: E731
    firsts = [w16(LEVELS + 11 * n + 8) for n in range(4)] + [ZONES_END]
    zones = []
    for lv in range(4):
        z = firsts[lv]
        while z < firsts[lv + 1]:
            zones.append((lv, z, rd(z)[0], w16(z + 1)))
            z += 7
    maps = [m for _, _, _, m in zones] + [TILES]
    os.makedirs(a.out, exist_ok=True)
    for lv in range(4):
        mine = [(i, z) for i, z in enumerate(zones) if z[0] == lv]
        strips = []
        for i, (_, zaddr, cset, mbase) in mine:
            rows = (maps[i + 1] - mbase) // 8
            strip = Image.new('RGB', (256, rows * 32), (0, 0, 0))
            px = strip.load()
            for r in range(rows):
                for c in range(8):
                    tile = rd(mbase + r * 8 + c)[0]
                    codes = rd(TILES + tile * 16, 16)
                    for k, code in enumerate(codes):
                        cx, cy = c * 32 + (k % 4) * 8, r * 32 + (k // 4) * 8
                        attr = rd(ATTRS[cset] + code)[0]
                        ink, paper = zxscreen.palette(attr & 7, bool(attr & 0x40)), zxscreen.palette(attr >> 3 & 7, bool(attr & 0x40))
                        for y in range(8):
                            bits = rd(CHARS[cset] + code * 8 + y)[0]
                            for x in range(8):
                                px[cx + x, cy + y] = ink if bits & 0x80 >> x else paper
            strips.append((zaddr, mbase, rows, strip))
        cols = min(6, len(strips))
        grid = [strips[i:i + cols] for i in range(0, len(strips), cols)]
        f1, f2 = K.font(30), K.font(24)
        heights = [max(st.height for *_, st in row) + 44 for row in grid]
        out = Image.new('RGB', (cols * 272 + 16, 56 + sum(heights)), (40, 40, 40))
        d = ImageDraw.Draw(out)
        d.text((8, 8), f'Level {lv + 1}: {NAMES[lv]}, {len(strips)} zones, drawn from the data', fill=(255, 255, 255),
               font=f1)
        y = 56
        for row, h in zip(grid, heights):
            for k, (zaddr, mbase, rows, st) in enumerate(row):
                x = 8 + k * 272
                d.text((x, y + 4), f'${zaddr:04X}: {rows} rows', fill=(230, 230, 230), font=f2)
                out.paste(st, (x, y + 40))
            y += h
        if a.scale != 1:
            out = out.resize((out.width * a.scale, out.height * a.scale), Image.NEAREST)
        path = os.path.join(a.out, f'level{lv + 1}.png')
        out.save(path)
        print(path, out.size)


if __name__ == '__main__':
    main()

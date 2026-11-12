#!/usr/bin/env python3
"""A first map of a stage drawn from its data, as stage 1 reads them (stage 1 of the work; the format is from the
code, see WALKTHROUGH 6.2):

- the stage's graphics and map are RLE-packed in the stage block (stage 1: `$B4B2`, escape byte first, then
  `ESC count value` runs, `ESC ESC` ends; Unrle `$A424`), unpacked to `$5B00` by `$9890-$9896` when a room is built;
- `$5B00` holds five words, offsets from `$5B0A`: tile kinds (one byte a tile), the tile bitmaps (8 bytes a tile),
  the tile attributes, the blocks (4 tiles a block: top left, top right, bottom left, bottom right) and the map;
- the map is one or more grids of block numbers; each grid's record (stage 1: `$9B6F`, `$9B8A`, `$9B96`) starts with
  its width and height in blocks and ends with its offset in the map section (IX+6); a room is a 14 x 9-block window
  of a grid (RoomCells `$9928`: offset = row `$FE22` x width + column `$FE21`).

    python3 tools/stagemap.py MEM.bin PACKED RECORDS OUT.png [--sheet TILES.png]
    python3 tools/stagemap.py work/stage1/mem/c1-stage1.bin B4B2 9B6F docs/img/maps/stage1.png --sheet docs/img/sprites/stage1-tiles.png
"""
import argparse

from PIL import Image, ImageDraw, ImageFont

PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0),
       (205, 205, 205)]
PALB = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0),
        (255, 255, 255)]


def unrle(m, hl):
    esc = m[hl]
    hl += 1
    out = bytearray()
    while True:
        a = m[hl]
        hl += 1
        if a != esc:
            out.append(a)
            continue
        if m[hl] == esc:
            return bytes(out), hl + 1
        out += bytes([m[hl + 1]]) * m[hl]
        hl += 2


def font(size):
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('mem')
    ap.add_argument('packed')
    ap.add_argument('records')
    ap.add_argument('out')
    ap.add_argument('--sheet')
    a = ap.parse_args()
    m = open(a.mem, 'rb').read()
    packed = int(a.packed, 16)
    d, end = unrle(m, packed)
    w = [d[i] | d[i + 1] << 8 for i in range(0, 10, 2)]
    base = 10
    kinds, bitmaps, attrs, blocks, grid = (base + x for x in w)
    ntiles = (attrs - bitmaps) // 8

    def tile(im, k, x0, y0):
        at = d[attrs + k]
        p = PALB if at & 64 else PAL
        ink, pap = p[at & 7], p[(at >> 3) & 7]
        for y in range(8):
            v = d[bitmaps + k * 8 + y]
            for x in range(8):
                im.putpixel((x0 + x, y0 + y), ink if v & (128 >> x) else pap)

    recs = []
    r = int(a.records, 16)
    total = len(d) - grid
    while sum(x[0] * x[1] for x in recs) < total and len(recs) < 8:
        recs.append((m[r], m[r + 1], m[r + 6] | m[r + 7] << 8, r))
        nxt = m.find(bytes([(sum(x[0] * x[1] for x in recs)) & 255, (sum(x[0] * x[1] for x in recs)) >> 8]),
                     r + 8, r + 64)
        if nxt < 0:
            break
        r = nxt - 6
    f = font(14)
    scale = 1
    width = max(x[0] for x in recs) * 16 + 20
    height = sum(x[1] * 16 + 40 for x in recs) + 10
    im = Image.new('RGB', (width, height), (40, 40, 40))
    dr = ImageDraw.Draw(im)
    y = 10
    for gw, gh, off, at in recs:
        dr.text((10, y), f'grid at ${at:04X}: {gw} x {gh} blocks, map offset {off} (unpacked ${0x5B0A + grid - base + off:04X}); '
                f'rooms are 14 x 9-block windows (white frames: the 14-column steps)', font=f, fill=(255, 255, 255))
        y += 26
        for j in range(gh):
            for i in range(gw):
                b = d[grid + off + j * gw + i]
                for t, (dx, dy) in enumerate(((0, 0), (8, 0), (0, 8), (8, 8))):
                    tile(im, d[blocks + b * 4 + t], 10 + i * 16 + dx, y + j * 16 + dy)
        for i in range(0, gw + 1, 14):
            dr.line([(10 + i * 16, y), (10 + i * 16, y + gh * 16)], fill=(255, 255, 255))
        y += gh * 16 + 14
    im.save(a.out)
    print(f'packed ${packed:04X}-${end - 1:04X} ({end - packed} bytes) -> {len(d)} bytes; offsets {w}; {ntiles} tiles; '
          f'grids {[(x[0], x[1], x[2]) for x in recs]}; image {im.size}')
    if a.sheet:
        cols = 14
        rows = (ntiles + cols - 1) // cols
        s = Image.new('RGB', (cols * 40 + 10, rows * 52 + 10), (40, 40, 40))
        sd = ImageDraw.Draw(s)
        for k in range(ntiles):
            t = Image.new('RGB', (8, 8))
            tile(t, k, 0, 0)
            x0, y0 = 10 + (k % cols) * 40, 10 + (k // cols) * 52
            s.paste(t.resize((32, 32), Image.NEAREST), (x0, y0))
            sd.text((x0, y0 + 34), f'{k}', font=font(11), fill=(220, 220, 220))
        s.save(a.sheet)


if __name__ == '__main__':
    main()

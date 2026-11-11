#!/usr/bin/env python3
"""The rooms drawn from the resources (src/res), no emulator and no image.

A room is 8 x 4 back-tiles (rooms/rooms.txt, RoomGrids `$D600`); a back-tile is 4 x 4 tile indices
(rooms/backtiles.txt, BackTiles `$C600`); a tile is 8 bytes of pixels and an attribute (tiles/base.png: TilePixels
`$F000`, TileAttrs `$DF00`). Tiles `$80-$FF` come from tiles/alt.png (AltTilePixels `$FA00`, AltTileAttrs `$C580`) in
the rooms of the `alternate` line of rooms.txt (RoomsOnAltTiles `$9AC6`; the room builder swaps the two halves). A room
is 32 x 16 cells, 256 x 128 pixels: the play window above the panel. Room R = level x 12 + column, levels 0-5 top to
bottom; rooms `$46` and `$47` (level 5, columns 10 and 11) are two explorers' own rooms, reached only through room
`$29`'s left exit (ExplorerRooms `$A66C`). Each room shows its creatures at their start places (the first frame of
their animation, rooms/rooms.txt, white) and the items that lie there at the start (tables/item-places.csv, yellow;
items taken at the start, the Energy Crystal, are not drawn).

    python3 tools/fig_rooms.py docs/img/maps/rooms.png [--room 14 --out-room docs/img/maps/room-14.png]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import res_formats as RF  # noqa: E402
import zxscreen  # noqa: E402
import kitlib as K  # noqa: E402


def resources():
    """{bin name: bytes} of the room and tile resources, from their editable files"""
    out = {}
    for rel in ('rooms/rooms.txt', 'tiles/base.png', 'tiles/alt.png', 'rooms/backtiles.txt', 'sprites/creatures.png',
                'sprites/items.png', 'tables/item-places.csv'):
        kind = 'group' if rel in RF.GROUPS else 'single'
        out.update(RF.to_bytes(rel, kind, open(os.path.join(RF.RES, rel), 'rb').read()))
    return out


def room_image(r, room):
    alt = room in r['rooms/alt-rooms.bin']
    im = Image.new('RGB', (256, 128))
    px = im.load()
    grid = r['rooms/grids.bin'][room * 32:room * 32 + 32]
    for b in range(32):
        bx, by = (b % 8) * 4, (b // 8) * 4
        d = r['rooms/backtiles.bin'][grid[b] * 16:grid[b] * 16 + 16]
        for t in range(16):
            tile = d[t]
            cx, cy = bx + t % 4, by + t // 4
            if tile >= 0x80 and alt:
                bits = r['tiles/alt-pixels.bin'][(tile - 0x80) * 8:(tile - 0x80) * 8 + 8]
                attr = r['tiles/alt-attrs.bin'][tile - 0x80]
            else:
                bits = r['tiles/base-pixels.bin'][tile * 8:tile * 8 + 8]
                attr = r['tiles/base-attrs.bin'][tile]
            ink = zxscreen.palette(attr & 7, attr & 0x40)
            paper = zxscreen.palette((attr >> 3) & 7, attr & 0x40)
            for y in range(8):
                for x in range(8):
                    px[cx * 8 + x, cy * 8 + y] = ink if bits[y] & (0x80 >> x) else paper
    for k in range(3):
        rec = r['rooms/table.bin'][room * 12 + 4 * k:room * 12 + 4 * k + 4]
        if any(rec) and rec[1] >= 0x40:
            sprite(px, r['sprites/creatures.bin'], rec[1] - 0x40, rec[2], rec[3] & 0x7F, (255, 255, 255))
    places = r['tables/item-places.bin']
    for i in range(0, len(places), 3):
        b0, b1, b2 = places[i:i + 3]
        if b0 == room:
            sprite(px, r['sprites/items.bin'], b1 & 31, (b2 & 3) * 64 + (b1 & 0xE0) // 4,
                   (b2 & 0xFC) * 2 & 255, (255, 230, 0))
    return im


def sprite(px, sheet, frame, x0, y0, colour):
    """a 24 x 24 sprite (three columns of 24 bytes) in colour with a black outline, clipped to the room"""
    d = sheet[frame * 72:frame * 72 + 72]
    on = {(x, y) for x in range(24) for y in range(24) if d[(x // 8) * 24 + y] & (0x80 >> (x % 8))}
    for x, y in on:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in on and 0 <= x0 + x + dx < 256 and 0 <= y0 + y + dy < 128:
                px[x0 + x + dx, y0 + y + dy] = (0, 0, 0)
    for x, y in on:
        if 0 <= x0 + x < 256 and 0 <= y0 + y < 128:
            px[x0 + x, y0 + y] = colour


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--room', type=lambda s: int(s, 16))
    ap.add_argument('--out-room')
    a = ap.parse_args()
    r = resources()
    rooms = len(r['rooms/grids.bin']) // 32
    if a.room is not None:
        room_image(r, a.room).resize((512, 256), Image.NEAREST).save(a.out_room)
    w, h, top, lab = 128, 64, 88, 24
    f, fs = K.font(22), K.font(20)
    levels = (rooms + 11) // 12
    o = Image.new('RGB', (12 * (w + 4) + 44, top + levels * (h + lab + 4)), (24, 24, 28))
    d = ImageDraw.Draw(o)
    d.text((4, 4), 'The %d rooms drawn from src/res/rooms and src/res/tiles: room R = level x 12 + column' % rooms,
           font=f, fill=(235, 235, 235))
    d.text((4, 32), 'Levels L0-L5 (rows), columns 0-11; the label is R in hex; * = the alternate tile set',
           font=fs, fill=(190, 190, 190))
    d.text((4, 58), 'White: the creatures at their start places; yellow: the items at the start of a game',
           font=fs, fill=(190, 190, 190))
    for room in range(rooms):
        lv, col = divmod(room, 12)
        x, y = 40 + col * (w + 4), top + lv * (h + lab + 4)
        o.paste(room_image(r, room).resize((w, h), Image.LANCZOS), (x, y + lab))
        star = '*' if room in r['rooms/alt-rooms.bin'] else ''
        d.text((x + 1, y), f'{room:02X}{star}', font=fs, fill=(255, 220, 90))
    for lv in range(levels):
        d.text((2, top + lv * (h + lab + 4) + lab + 20), f'L{lv}', font=fs, fill=(200, 200, 200))
    o.save(a.out)


if __name__ == '__main__':
    main()

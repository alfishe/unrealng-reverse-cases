#!/usr/bin/env python3
"""The rooms drawn from the data of the image as loaded (work/mkgame/original.bin), no emulator.

A room is 8 x 4 back-tiles at `$D600 + room * 32`; a back-tile is 4 x 4 tile indices at `$C600 + index * 16`; a tile
is 8 bytes of pixels at `$F000 + tile * 8` and an attribute at `$DF00 + tile`. Tiles `$80-$FF` have two sets: the
base set at `$F400` / `$DF80` and the alternate at `$FA00` / `$C580`, which the 15 rooms listed at `$9AC6` use
(SwapTileSet `$918D`, RoomSetup `$9880`). So a room is 32 x 16 cells, 256 x 128 pixels: the play window above the
panel. The rooms sit at their numbers, room = level * 12 + column, levels 0-5 top to bottom.

    python3 tools/fig_rooms.py work/mkgame/original.bin docs/img/maps/rooms.png [--room 14 --out-room docs/img/maps/room-14.png]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import zxscreen  # noqa: E402
import kitlib as K  # noqa: E402


def room_image(m, room):
    alt = room in m[0x9AC6:0x9AC6 + 15]
    im = Image.new('RGB', (256, 128))
    px = im.load()
    bt = m[0xD600 + room * 32:0xD600 + room * 32 + 32]
    for b in range(32):
        bx, by = (b % 8) * 4, (b // 8) * 4
        d = m[0xC600 + bt[b] * 16:0xC600 + bt[b] * 16 + 16]
        for t in range(16):
            tile = d[t]
            cx, cy = bx + t % 4, by + t // 4
            if tile < 0x80:
                bits, attr = 0xF000 + tile * 8, m[0xDF00 + tile]
            elif alt:
                bits, attr = 0xFA00 + (tile - 0x80) * 8, m[0xC580 + tile - 0x80]
            else:
                bits, attr = 0xF400 + (tile - 0x80) * 8, m[0xDF80 + tile - 0x80]
            ink = zxscreen.palette(attr & 7, attr & 0x40)
            paper = zxscreen.palette((attr >> 3) & 7, attr & 0x40)
            for y in range(8):
                row = m[bits + y]
                for x in range(8):
                    px[cx * 8 + x, cy * 8 + y] = ink if row & (0x80 >> x) else paper
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('out')
    ap.add_argument('--room', type=lambda s: int(s, 16))
    ap.add_argument('--out-room')
    a = ap.parse_args()
    m = open(a.image, 'rb').read()
    if a.room is not None:
        room_image(m, a.room).resize((512, 256), Image.NEAREST).save(a.out_room)
    w, h, top, lab = 128, 64, 64, 24
    f, fs = K.font(22), K.font(20)
    o = Image.new('RGB', (12 * (w + 4) + 44, top + 6 * (h + lab + 4)), (24, 24, 28))
    d = ImageDraw.Draw(o)
    d.text((4, 4), 'The 70 rooms drawn from the data: room R is the back-tile row at $D600 + R * 32', font=f,
           fill=(235, 235, 235))
    d.text((4, 32), 'Levels L0-L5 (rows), columns 0-11; the label is R in hex', font=fs, fill=(190, 190, 190))
    for room in range(70):
        lv, col = divmod(room, 12)
        x, y = 40 + col * (w + 4), top + lv * (h + lab + 4)
        o.paste(room_image(m, room).resize((w, h), Image.LANCZOS), (x, y + lab))
        d.text((x + 1, y), f'{room:02X}', font=fs, fill=(255, 220, 90))
    for lv in range(6):
        d.text((2, top + lv * (h + lab + 4) + lab + 20), f'L{lv}', font=fs, fill=(200, 200, 200))
    o.save(a.out)


if __name__ == '__main__':
    main()

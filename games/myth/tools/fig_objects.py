#!/usr/bin/env python3
"""Doc 07's figures: one room decoded from the stage's packed graphics, and the records as a data sheet.

    python3 tools/fig_objects.py decode docs/img/rooms/decode-room7.png
    python3 tools/fig_objects.py records docs/img/rooms/records.png

decode: stage 1's graphics (src/res/stage1/graphics.txt and tiles.png, packed again by tools/res_stage.py and
unpacked with its unrle, the bytes Unrle `$A424` leaves at `$5B00`), grid 0, room 7 (RoomColumn 11, RoomRow 6, the
values c1 holds at frame 16550). Left: the room's 14 x 9 block numbers as RoomCells reads them from the map. Right:
the 28 x 18 cells drawn from the tiles' pixels and colours, as RoomChange draws them. Under: block 51's chain from
the map byte to the four tiles. The decode was checked against c1's Cells `$7280` at frame 16540: all 504 cells equal.
records: the five record layouts of stage 1 (the grid record, a placement, a kind row, an actor record, a span), each
with a real example: Grid0 `$9B6F`, placement 0, kind row 4, actor record 13 at c1 frame 16550, the first span at
c1 frame 16202.
"""
import os
import sys

from PIL import Image

from figmyth import F, TEXT, DIM, HI, PANEL, COLOURS, CASE, canvas, save, zx_colour

import res_stage  # noqa: E402

ROOM_COL, ROOM_ROW, GRID_W, GRID_MAP = 11, 6, 69, 0
BLOCK_ROW, BLOCK_COL = 4, 0


def unpacked(stage='stage1'):
    res_stage.RES = os.path.join(CASE, 'src', 'res')
    raw = open(os.path.join(res_stage.RES, stage, 'graphics.txt'), 'rb').read()
    d, _, _ = res_stage.unrle(res_stage.graphics_in(stage + '/graphics.bin', raw))
    return d


def tile_image(pix, att, t, scale):
    a = att[t]
    ink = zx_colour(a & 7, bool(a & 0x40))
    paper = zx_colour((a >> 3) & 7, bool(a & 0x40))
    im = Image.new('RGB', (8, 8))
    for y in range(8):
        b = pix[8 * t + y]
        for x in range(8):
            im.putpixel((x, y), ink if b & (0x80 >> x) else paper)
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def decode(out):
    d = unpacked()
    w = [int.from_bytes(d[i:i + 2], 'little') for i in range(0, 10, 2)]
    K, P, A, B, M = (10 + x for x in w)
    kinds, pix, att, blk, mp = d[K:P], d[P:A], d[A:B], d[B:M], d[M:]
    start = GRID_MAP + ROOM_ROW * GRID_W + ROOM_COL
    im, dr, y0 = canvas(800, 'One room decoded: stage 1, grid 0, room 7',
                        'The unpacked graphics at $5B00: kinds $5B0A, pixels $5BCE, colours $61EE, blocks $62B2, map $647A.\n'
                        'Room 7: RoomColumn 11, RoomRow 6, so the window starts at map byte 6 x 69 + 11 = 425, $6623.\n'
                        'Left: its 14 x 9 blocks. Right: the 28 x 18 cells drawn from the tiles. Gold: block 51.')
    # the block numbers
    cw, ch = 31, 24
    x0, y = 16, y0 + 30
    dr.text((x0, y - 24), 'the window\'s block numbers (map bytes)', font=F(14), fill=TEXT)
    for r in range(9):
        for c in range(14):
            b = mp[start + r * GRID_W + c]
            bx, by = x0 + c * cw, y + r * ch
            hot = (r, c) == (BLOCK_ROW, BLOCK_COL)
            dr.rectangle((bx, by, bx + cw - 2, by + ch - 2), fill=(150, 110, 40) if hot else (PANEL if b == 0 else (52, 52, 70)),
                         outline=HI if hot else None)
            dr.text((bx + 3, by + 4), '%d' % b, font=F(13), fill=TEXT if b else DIM)
    # the room drawn
    sc = 2
    rx, ry = x0 + 14 * cw + 24, y
    dr.text((rx, ry - 24), 'the cells drawn from the tiles (2 x)', font=F(14), fill=TEXT)
    for r in range(9):
        for c in range(14):
            b = mp[start + r * GRID_W + c]
            for k, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                t = blk[4 * b + k]
                im.paste(tile_image(pix, att, t, sc), (rx + (2 * c + dx) * 8 * sc, ry + (2 * r + dy) * 8 * sc))
    hx, hy = rx + 2 * BLOCK_COL * 8 * sc, ry + 2 * BLOCK_ROW * 8 * sc
    dr.rectangle((hx - 1, hy - 1, hx + 16 * sc, hy + 16 * sc), outline=HI, width=2)
    # the chain
    y = ry + 18 * 8 * sc + 24
    a = start + BLOCK_ROW * GRID_W + BLOCK_COL
    b = mp[a]
    tiles = list(blk[4 * b:4 * b + 4])
    steps = ['map byte $%04X = %d' % (0x5B00 + M + a, b),
             'block %d at $%04X: %s' % (b, 0x5B00 + B + 4 * b, ' '.join('%02X' % t for t in tiles)),
             'tiles %s' % ', '.join(str(t) for t in tiles)]
    dr.text((16, y), '  ->  '.join(steps), font=F(14), fill=HI)
    y += 24
    dr.text((16, y), 'the four tiles in the order top left, top right, bottom left, bottom right', font=F(13), fill=DIM)
    y += 28
    for k, t in enumerate(tiles):
        tx = 16 + k * 258
        im.paste(tile_image(pix, att, t, 8), (tx, y))
        lines = ['tile %d' % t, 'kind %d at $%04X' % (kinds[t], 0x5B0A + t),
                 'colour $%02X at $%04X' % (att[t], 0x5B00 + A + t), 'pixels at $%04X' % (0x5B00 + P + 8 * t),
                 ' '.join('%02X' % v for v in pix[8 * t:8 * t + 4]), ' '.join('%02X' % v for v in pix[8 * t + 4:8 * t + 8])]
        for i, ln in enumerate(lines):
            dr.text((tx + 72, y + i * 18 - 4), ln, font=F(13), fill=TEXT if i == 0 else DIM)
    y += 64 + 50
    dr.text((16, y), 'A kind is bits: 0 is open (CopyBuffer copies it every pass); bit 1 solid; bit 3 deadly.\n'
            'Kind 7 is a solid wall, 5 passable scenery, 15 a deadly wall.', font=F(13), fill=DIM)
    save(im.crop((0, 0, im.width, y + 44)), out)


RECORDS = [
    ('A grid record, 9 bytes: Grid0 $9B6F', ['width', 'height', 'start col', 'start row', 'rooms', '', 'map', '',
                                             'per row'],
     '45 15 16 00 78 9B 00 00 06', '69 x 21 blocks; the first window at block column 22, row 0 (room 2); room table $9B78; map offset 0; 6 rooms a row'),
    ('A placement, 3 bytes: Grid0Placements[0] $9BA0', ['kind', 'X', 'Y'],
     '04 22 0E', 'kind 4 (StrikeableActor) at grid cell 34, 14; room 7 starts at cell 22, 12, so it stands at column 12, row 2'),
    ('A kind row, 9 bytes: ActorKinds[4] $9CAE', ['Y offset', 'handler', '', '+8', '+9', '+$0A', '+$0B', '+$0C', '+$0F'],
     '00 C4 A7 04 01 00 00 46 00', 'Y offset 0, StrikeableActor $A7C4, +8 = 4 (hit count and frame), +9 = 1 (opaque), attribute $46, +$0F = 0'),
    ('An actor record, 18 bytes: record 13 $75CA at c1 16550', ['X', 'Y', 'width', 'height', 'frame', '', 'handler', '',
                                                                '+8', 'flags', 'state', 'item', 'attr', 'base X',
                                                                'base Y', '+$0F', 'index', 'shift'],
     '0C 12 02 0E F8 E1 C4 A7 04 01 00 00 46 0C 10 00 00 00',
     'placement 0: column 12, line 18 (base line 16 + frame 4\'s offset 2), 2 x 14 from frame 4, image $E1F8; +$10 = index 0'),
    ('A span, 6 bytes: SpanTable[0] $76A0 at c1 16202', ['length', '0', 'buffer', '', 'screen', ''],
     '1C 00 02 5B C2 40', '28 cells from buffer $5B02 to screen $40C2: row 6, columns 2-29'),
]


def records(out):
    im, d, y = canvas(900, 'The records of stage 1, byte by byte, each with a real example',
                      'Gold: the example\'s bytes. Under each box: the field. A two-byte field (an address) spans two '
                      'boxes, low byte first.')
    bw = 56
    for i, (title, fields, example, note) in enumerate(RECORDS):
        c = COLOURS[i % len(COLOURS)]
        d.rectangle((16, y + 2, 26, y + 18), fill=c)
        d.text((34, y), title, font=F(15), fill=TEXT)
        y += 26
        vals = example.split()
        for k, (f, v) in enumerate(zip(fields, vals)):
            bx = 16 + k * bw
            d.rectangle((bx, y, bx + bw - 4, y + 30), fill=PANEL, outline=c)
            d.text((bx + 14, y + 6), v, font=F(15), fill=HI)
            d.text((bx + 2, y + 34 + (16 if k % 2 else 0)), '+%X' % k if not f else f[:9], font=F(13), fill=DIM)
        y += 72
        d.text((16, y), note, font=F(13), fill=TEXT)
        y += 34
    save(im.crop((0, 0, im.width, y)), out)


if __name__ == '__main__':
    {'decode': decode, 'records': records}[sys.argv[1]](sys.argv[2])

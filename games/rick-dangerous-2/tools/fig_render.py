#!/usr/bin/env python3
"""The figures of doc 06 (rendering).

    python3 tools/fig_render.py build --level 1 --section 5 --row 20 docs/img/render/build.png
    python3 tools/fig_render.py sprite --level 1 --sprite 6 --x 226 docs/img/render/sprite.png
    python3 tools/fig_render.py view --work W --at F:T docs/img/render/view.png [--title T]

build: one map row of a section decoded as BuildView `$88D4` does it: the row's 8 bytes (block numbers, from
maps.bin at the section's map offset + 8 x row), one block's 16 cell numbers as a 4 x 4 square, and the row as the
32 x 4 cells it becomes, each cell drawn from its 8 bytes and attribute (the level's resources, src/res/levels).

sprite: one sprite of the level's sprites.bin (Sprites `$C26D` + 128 x n) byte by byte: its two head bytes, the first
rows' six bytes (data 2, data 1, data 0, mask 0, mask 2, mask 1, as ComposeSprite pops them), the pixels it gives
(paper where mask 0 and data 0, ink where data 1, the cell's own pixel where mask 1), and the same sprite at x AND 7 =
the --x's shift, spread over 4 cell columns as ComposeShifted lays it.

view: the renderer's buffers at one moment of a recording (TTD memory_at): ViewCells `$6B00` (32 x 44 cell numbers)
drawn with the level's cells as they are in memory (CellGraphics `$A900`, CellAttrs `$B100`), the screen's window on
it (view rows 8-31; row 8 is the HUD's, so the screen's rows 1-23 are view rows 9-31); DirtyMap `$6600` (32 x 40, same
index), each byte coloured: 0 nothing, 1 restore the level cell, n >= 2 show spare cell n; and the screen.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_rooms as FR  # noqa: E402
import zxscreen  # noqa: E402

W = 1050


def cell_image(gfx, attrs, cell):
    img = Image.new('RGB', (8, 8))
    px = img.load()
    at = attrs[cell]
    for y in range(8):
        row = gfx[8 * cell + y]
        for x in range(8):
            px[x, y] = FR.rgb(at, row >> (7 - x) & 1)
    return img


def fig_build(a):
    b = FR.level_bytes(a.level)
    maps, sec, blocks = b['level/maps.bin'], b['level/sections.bin'], b['level/blocks.bin']
    gfx, attrs = b['level/cell-graphics.bin'], b['level/cell-attrs.bin']
    ent = sec[8 * a.section:8 * a.section + 8]
    moff = ent[0] << 8 | ent[1]
    row = list(maps[moff + 8 * a.row:moff + 8 * a.row + 8])
    f, fs, fb = K.font(14), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 640), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((16, 10), 'BuildView: level %d section %d, map row %d (maps + $%04X): 8 block numbers -> 32 x 4 cells'
           % (a.level, a.section, a.row, moff + 8 * a.row), fill=K.TEXT, font=fb)
    # the 8 bytes
    d.text((16, 44), 'the map row, 8 bytes:', fill=K.DIM, font=f)
    for i, v in enumerate(row):
        x = 220 + i * 96
        d.rectangle((x, 40, x + 88, 66), fill=K.PANEL, outline=K.ROUTINE_COLOURS[i])
        d.text((x + 6, 44), '$%02X = %d' % (v, v), fill=K.ROUTINE_COLOURS[i], font=f)
    # one block's cell numbers
    pick = a.block_index
    blk = row[pick]
    d.text((16, 90), 'block %d (Blocks + 16 x %d = $%04X): 16 cell numbers, 4 rows of 4' % (blk, blk, 0xB200 + 16 * blk),
           fill=K.TEXT, font=f)
    for cy in range(4):
        for cx in range(4):
            c = blocks[16 * blk + 4 * cy + cx]
            x, y = 16 + cx * 70, 116 + cy * 30
            d.rectangle((x, y, x + 64, y + 26), fill=K.PANEL, outline=K.ROUTINE_COLOURS[pick])
            d.text((x + 6, y + 4), '%d' % c, fill=K.TEXT, font=f)
    # the block drawn big
    bimg = Image.new('RGB', (32, 32))
    for cy in range(4):
        for cx in range(4):
            bimg.paste(cell_image(gfx, attrs, blocks[16 * blk + 4 * cy + cx]), (cx * 8, cy * 8))
    big = bimg.resize((128, 128), Image.NEAREST)
    img.paste(big, (320, 116))
    bd = ImageDraw.Draw(img)
    for k in range(1, 4):
        bd.line((320 + 32 * k, 116, 320 + 32 * k, 244), fill=(90, 90, 90))
        bd.line((320, 116 + 32 * k, 448, 116 + 32 * k), fill=(90, 90, 90))
    d.text((470, 120), 'drawn: each cell is 8 bytes of CellGraphics\n($A900 + 8 x cell) in the colours of its\n'
           'CellAttrs byte ($B100 + cell)', fill=K.TEXT, font=fs)
    # the whole row of blocks
    d.text((16, 270), 'the row in ViewCells: 8 blocks side by side, 32 cells wide, 4 cell rows (shown 3 x)', fill=K.TEXT,
           font=f)
    rimg = Image.new('RGB', (256, 32))
    for i, bn in enumerate(row):
        for cy in range(4):
            for cx in range(4):
                rimg.paste(cell_image(gfx, attrs, blocks[16 * bn + 4 * cy + cx]), (i * 32 + cx * 8, cy * 8))
    rbig = rimg.resize((768, 96), Image.NEAREST)
    img.paste(rbig, (16, 296))
    for i in range(8):
        d.rectangle((16 + i * 96, 296, 16 + i * 96 + 95, 391), outline=K.ROUTINE_COLOURS[i])
        d.text((16 + i * 96 + 4, 396), 'block %d' % row[i], fill=K.ROUTINE_COLOURS[i], font=fs)
    # the cell numbers of the row
    d.text((16, 424), 'the same 4 rows as ViewCells holds them (cell numbers, 32 a row):', fill=K.TEXT, font=f)
    for cy in range(4):
        nums = []
        for i, bn in enumerate(row):
            nums += list(blocks[16 * bn + 4 * cy:16 * bn + 4 * cy + 4])
        d.text((16, 450 + cy * 20), ' '.join('%02X' % n for n in nums), fill=K.TEXT, font=K.font(12))
    img = img.crop((0, 0, W, 540))
    img.save(a.out)
    print(a.out, img.size, row)


def sprite_pixels(spr):
    """[(rows of 24 values: 0 paper, 1 ink, 3 see-through)] from a sprite's bytes"""
    rows = spr[1]
    out = []
    for r in range(rows):
        d2, d1, d0, m0, m2, m1 = spr[2 + 6 * r:8 + 6 * r]
        line = []
        for dat, msk in ((d0, m0), (d1, m1), (d2, m2)):
            for bit in range(7, -1, -1):
                db, mb = dat >> bit & 1, msk >> bit & 1
                line.append(1 if db else (3 if mb else 0))
        out.append(line)
    return out


def fig_sprite(a):
    b = FR.level_bytes(a.level)
    sp = b['level/sprites.bin']
    spr = sp[128 * a.sprite:128 * a.sprite + 128]
    pix = sprite_pixels(spr)
    f, fs, fb = K.font(14), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 620), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((16, 10), 'Sprite %d of level %d (Sprites + 128 x %d = $%04X): head, rows of 6 bytes, pixels'
           % (a.sprite, a.level, a.sprite, 0xC26D + 128 * a.sprite), fill=K.TEXT, font=fb)
    d.text((16, 40), 'head: +0 = $%02X (added to the strip offset), +1 = $%02X = %d rows' % (spr[0], spr[1], spr[1]),
           fill=K.TEXT, font=f)
    d.text((16, 66), 'row  data2 data1 data0 mask0 mask2 mask1', fill=K.DIM, font=fs)
    for r in range(min(spr[1], 21)):
        bs = spr[2 + 6 * r:8 + 6 * r]
        d.text((16, 84 + r * 18), '%3d   ' % r + '    '.join('%02X' % v for v in bs), fill=K.TEXT, font=fs)
    colours = {0: (0, 0, 0), 1: (230, 230, 230), 3: (60, 90, 60)}
    sc = 10
    x0, y0 = 360, 70
    for r, line in enumerate(pix):
        for c, v in enumerate(line):
            d.rectangle((x0 + c * sc, y0 + r * sc, x0 + c * sc + sc - 1, y0 + r * sc + sc - 1), fill=colours[v])
    for k in range(4):
        d.line((x0 + 8 * k * sc, y0 - 4, x0 + 8 * k * sc, y0 + len(pix) * sc + 4), fill=(200, 80, 80))
    d.text((x0, y0 + len(pix) * sc + 8), 'aligned: 3 bytes a row\nblack = paper (mask 0, data 0)\nwhite = ink (data 1)\n'
           'green = the cell shows through (mask 1)', fill=K.TEXT, font=fs)
    sh = a.x & 7
    x1 = 660
    d.text((x1, 40), 'x = %d: x AND 7 = %d, shifted into 4 columns' % (a.x, sh), fill=K.TEXT, font=f)
    for r, line in enumerate(pix):
        full = [3] * sh + line + [3] * (32 - 24 - sh)
        for c, v in enumerate(full):
            d.rectangle((x1 + c * sc, y0 + r * sc, x1 + c * sc + sc - 1, y0 + r * sc + sc - 1), fill=colours[v])
    for k in range(5):
        d.line((x1 + 8 * k * sc, y0 - 4, x1 + 8 * k * sc, y0 + len(pix) * sc + 4), fill=(200, 80, 80))
    d.text((x1, y0 + len(pix) * sc + 8), 'a fourth byte: data 0, mask $FF shifted in', fill=K.TEXT, font=fs)
    img = img.crop((0, 0, W, max(y0 + len(pix) * sc + 90, 84 + 21 * 18 + 10)))
    img.save(a.out)
    print(a.out, img.size)


def fig_view(a):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(a.work)
    fr, _, t = a.at.partition(':')
    fr, t = int(fr), int(t or 0)

    def mem(addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': fr, 'tinframe': t,
                                         'offset': addr, 'length': n}, ok=False)
        return bytes.fromhex((r.structured or {})['hex'])
    view, dirty = mem(0x6B00, 32 * 44), mem(0x6600, 32 * 40)
    gfx, attrs, flags, scr = mem(0xA900, 2048), mem(0xB100, 256), mem(0xA800, 256), mem(0x4000, 0x1B00)
    vimg = Image.new('RGB', (256, 352))
    for r in range(44):
        for c in range(32):
            vimg.paste(cell_image(gfx, attrs, view[32 * r + c]), (c * 8, r * 8))
    s = 1.28
    VW, VH = int(256 * s), int(352 * s)
    vbig = vimg.resize((VW, VH), Image.NEAREST)
    img = Image.new('RGB', (W, VH + 120), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f, fs, fb = K.font(13), K.font(11), K.font(15)
    d.text((10, 6), a.title or ('The renderer\'s buffers at frame %d T %d' % (fr, t)), fill=K.TEXT, font=fb)
    top = 50
    x0 = 10
    img.paste(vbig, (x0, top))
    # the screen's window: view rows 8-31
    d.rectangle((x0, top + int(8 * 8 * s), x0 + VW - 1, top + int(32 * 8 * s) - 1), outline=(250, 220, 120), width=2)
    d.text((x0, top - 18), 'ViewCells $6B00: 32 x 44 cells', fill=K.TEXT, font=f)
    # front cells
    for r in range(44):
        for c in range(32):
            if flags[view[32 * r + c]] & 0x80:
                xx, yy = x0 + int(c * 8 * s), top + int(r * 8 * s)
                d.line((xx, yy, xx + int(8 * s) - 1, yy + int(8 * s) - 1), fill=(250, 120, 220))
    # dirty map
    x1 = x0 + VW + 20
    d.text((x1, top - 18), 'DirtyMap $6600: 32 x 40, same index', fill=K.TEXT, font=f)
    d.rectangle((x1, top, x1 + VW - 1, top + VH - 1), fill=K.PANEL)
    cs = 8 * s
    counts = {0: 0, 1: 0, 2: 0}
    for r in range(40):
        for c in range(32):
            v = dirty[32 * r + c]
            xx, yy = x1 + c * cs, top + r * cs
            if v == 1:
                d.rectangle((xx, yy, xx + cs - 2, yy + cs - 2), fill=(70, 120, 220))
                counts[1] += 1
            elif v >= 2:
                d.rectangle((xx, yy, xx + cs - 2, yy + cs - 2), fill=(240, 200, 70))
                counts[2] += 1
    d.rectangle((x1, top + int(8 * cs), x1 + VW - 1, top + int(32 * cs) - 1), outline=(250, 220, 120), width=2)
    # screen
    x2 = x1 + VW + 20
    simg = zxscreen.render(scr, 1).convert('RGB').resize((VW, int(192 * s)), Image.NEAREST)
    img.paste(simg, (x2, top + int(8 * cs)))
    d.text((x2, top + int(8 * cs) - 18), 'the screen $4000', fill=K.TEXT, font=f)
    ly = top + VH + 10
    d.text((x0, ly), 'yellow frame: the screen\'s window, view rows 8-31 (row 8 = the HUD row). Pink diagonal: a cell '
           'drawn in front of the sprites (CellFlags bit 7).', fill=K.TEXT, font=fs)
    d.text((x0, ly + 18), 'DirtyMap: yellow = a spare cell n >= 2 to show (%d), blue = 1, restore the level cell (%d), '
           'dark = 0, nothing to do.' % (counts[2], counts[1]), fill=K.TEXT, font=fs)
    img.save(a.out)
    print(a.out, img.size, counts)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('build')
    p.add_argument('--level', type=int, default=1)
    p.add_argument('--section', type=int, default=5)
    p.add_argument('--row', type=int, default=20)
    p.add_argument('--block-index', type=int, default=0)
    p.add_argument('out')
    p.set_defaults(fn=fig_build)
    p = sub.add_parser('sprite')
    p.add_argument('--level', type=int, default=1)
    p.add_argument('--sprite', type=int, default=6)
    p.add_argument('--x', type=int, default=226)
    p.add_argument('out')
    p.set_defaults(fn=fig_sprite)
    p = sub.add_parser('view')
    p.add_argument('--work', required=True)
    p.add_argument('--at', required=True)
    p.add_argument('--title')
    p.add_argument('out')
    p.set_defaults(fn=fig_view)
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    a.fn(a)


if __name__ == '__main__':
    main()

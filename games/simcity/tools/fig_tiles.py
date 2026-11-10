#!/usr/bin/env python3
"""Doc 02: the map cells' tiles and a whole city, drawn from memory the way the view draws them.

A map byte below `$80` is a cell: its 8 pixel rows at `$EA68 + 8 x cell` (copied by `$647D-$648A`) and its
attribute at `$F530 + cell` (the table `$652F` puts in `$6505`, read at `$6490`). A byte from `$80` starts a row of
a building, the bytes from `$C0` go on with it (the view loop `$650B`, `$655B`): the row is `(first AND 7)` cells
wide and its cells are drawn from a second table, tile `$ED58 + 8 x n`, attribute `$F58E + n` (`$64EF-$6501`), with
n = `(second AND $3F) x 8 + (third AND 7)` for the first cell and one more for each next one. Left out: the blink of
cells `$54-$56` and of buildings `$A0-$AF` (bit 5 of the pass counter `$8F9F`) and the swap of cells 7 and 8 to
`$34-$37` next to some cells (`$64A9`).

    python3 tools/fig_tiles.py sheet work/mkgame/original.bin docs/img/sprites/tiles.png --used work/stage1/rec/*/end.szx
    python3 tools/fig_tiles.py map work/stage1/rec/city2/end.szx docs/img/play/city-map.png [--scale 1]
    python3 tools/fig_tiles.py check work/stage1/rec/city2/end.szx    # the view drawn from the map vs the screen
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import szx  # noqa: E402

TILES, ATTRS, MAP, SIDE = 0xEA68, 0xF530, 0xC450, 96
BG, TEXT, DIM = (24, 24, 30), (235, 235, 235), (170, 170, 180)


def memory(path):
    if path.endswith('.szx'):
        return szx.read(path)[0]
    return bytearray(open(path, 'rb').read())


def cell_image(mem, cell, tiles=TILES, attrs=ATTRS):
    im = Image.new('RGB', (8, 8))
    px = im.load()
    attr = mem[attrs + cell]
    ink, paper = K.ink_colour(attr & 7, attr & 0x40), K.ink_colour((attr >> 3) & 7, attr & 0x40)
    for y in range(8):
        bits = mem[tiles + 8 * cell + y]
        for x in range(8):
            px[x, y] = ink if bits & (0x80 >> x) else paper
    return im


def building_image(mem, n):
    return cell_image(mem, n, 0xED58, 0xF58E)


def city(mem):
    im = Image.new('RGB', (SIDE * 8, SIDE * 8))
    for y in range(SIDE):
        row = MAP + y * SIDE
        count = index = 0
        for x in range(SIDE):
            c = mem[row + x]
            if count == 0 and c >= 0x80:
                back = 0
                while back < x and mem[row + x - back] & 0xC0 == 0xC0:
                    back += 1
                ix = row + x - back
                count = (mem[ix] & 7) - back
                index = (mem[ix + 1] & 0x3F) * 8 + (mem[ix + 2] & 7) + back
            if count > 0:
                im.paste(building_image(mem, index), (x * 8, y * 8))
                count -= 1
            else:
                im.paste(cell_image(mem, c), (x * 8, y * 8))
            index += 1
    return im


def used_tiles(paths):
    """the cells and the building tiles (n) found on the maps of the given images"""
    cells, ns = set(), set()
    for path in paths:
        mem = memory(path)
        for y in range(SIDE):
            row = MAP + y * SIDE
            for x in range(SIDE):
                c = mem[row + x]
                if c < 0x80:
                    cells.add(c)
                elif c < 0xC0 and x + 2 < SIDE:
                    n = (mem[row + x + 1] & 0x3F) * 8 + (mem[row + x + 2] & 7)
                    ns.update(range(n, n + (c & 7)))
    return cells, ns


def sheet(mem, out, cells_used, ns_used):
    scale, cols = 4, 16
    cw, ch = 8 * scale + 18, 8 * scale + 22
    f_title, f_head, f_lab, f_note = K.font(24), K.font(19), K.font(13), K.font(15)
    n_cells, n_build = 0xF58E - ATTRS, 0xF4      # 94 cells, 244 building tiles (their attributes end where the buildings' begin)
    rows_c, rows_b = (n_cells + cols - 1) // cols, (n_build + cols - 1) // cols
    w = 40 + cols * cw
    h = 96 + 40 + rows_c * ch + 50 + rows_b * ch + 20
    img = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'The map tiles, from the image at the entry', fill=TEXT, font=f_title)
    d.text((14, 44), 'a yellow frame: on a map of the stage 1 recordings; label: the cell or n in hex', fill=DIM,
           font=f_note)
    y0 = 92
    d.text((14, y0), f'cells $00-${n_cells - 1:02X}: tile ${TILES:04X} + 8 x cell, attribute ${ATTRS:04X} + cell',
           fill=TEXT, font=f_head)

    def grid(top, count, draw, used):
        for i in range(count):
            x, y = 30 + (i % cols) * cw, top + (i // cols) * ch
            img.paste(draw(i).resize((8 * scale, 8 * scale), Image.NEAREST), (x, y))
            if i in used:
                d.rectangle((x - 2, y - 2, x + 8 * scale + 1, y + 8 * scale + 1), outline=(255, 210, 60), width=2)
            d.text((x, y + 8 * scale + 3), f'{i:02X}', fill=DIM, font=f_lab)

    grid(y0 + 34, n_cells, lambda i: cell_image(mem, i), cells_used)
    y1 = y0 + 34 + rows_c * ch + 10
    d.text((14, y1), 'building rows: n $00-$F3, tile $ED58 + 8 x n, attribute $F58E + n', fill=TEXT, font=f_head)
    grid(y1 + 34, n_build, lambda i: building_image(mem, i), ns_used)
    img.save(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('cmd', choices=['sheet', 'map', 'check'])
    p.add_argument('src')
    p.add_argument('out', nargs='?')
    p.add_argument('--scale', type=int, default=1)
    p.add_argument('--used', nargs='*', default=[], help='images whose maps mark the tiles in use (sheet)')
    a = p.parse_args()
    mem = memory(a.src)
    if a.cmd == 'sheet':
        sheet(mem, a.out, *used_tiles(a.used))
    elif a.cmd == 'map':
        im = city(mem)
        if a.scale != 1:
            im = im.resize((im.width * a.scale, im.height * a.scale), Image.NEAREST)
        im.save(a.out)
    else:
        vx, vy = mem[0x6507], mem[0x6508]
        screen = K.render_screen(mem)
        view = city(mem).crop((vx * 8, vy * 8, vx * 8 + 256, vy * 8 + 128))
        diff = sum(1 for p, q in zip(view.getdata(), screen.crop((0, 64, 256, 192)).getdata()) if p != q)
        print(f'view ({vx}, {vy}): {diff} of {256 * 128} pixels differ from the screen rows 8-23')
        if a.out:
            both = Image.new('RGB', (256, 272), BG)
            both.paste(view, (0, 0))
            both.paste(screen.crop((0, 64, 256, 192)), (0, 144))
            both.save(a.out)


if __name__ == '__main__':
    main()

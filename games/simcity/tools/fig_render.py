#!/usr/bin/env python3
"""Doc 06 (rendering): the figures drawn from the resources and from memory images.

    python3 tools/fig_render.py layout work/stage1/rec/tools/end.szx docs/img/rendering/layout.png
    python3 tools/fig_render.py building work/stage1/rec/tools/end.szx 54 37 docs/img/rendering/building-row.png
    python3 tools/fig_render.py cells docs/img/rendering/cells-sheet.png
    python3 tools/fig_render.py sprites docs/img/rendering/movers-pointer.png
    python3 tools/fig_render.py overview work/stage1/rec/metro/end.szx 5 docs/img/rendering/overview-metro.png
    python3 tools/fig_render.py check MEMORY.bin AREA LAYER ROWS     # the overview emulation against a real screen

The tiles come from src/res/graphics (Cells.png, Buildings.png, Movers.png, Pointer.png through res_formats.py), the
map and the arrays from a memory image (.szx, or a raw 64 K .bin). `overview` draws the maps window's picture the way
DrawOverview `$9C57`, OverviewCell `$9BC3`, ShrinkLine `$9BF9`, LayerOf `$9D44` and PatternMark do it, into a 6912-byte
screen, so `check` can compare it byte for byte with the screen of a recording.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import res_formats as RF  # noqa: E402
import szx  # noqa: E402

MAP, SIDE = 0xC450, 96
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
YEL, RED, GRN, BLU, CYA, ORA = (240, 200, 70), (230, 90, 80), (90, 200, 120), (90, 150, 250), (70, 210, 220), \
    (250, 150, 60)


def memory(path):
    if path.endswith('.szx'):
        return bytes(szx.read(path)[0])
    return open(path, 'rb').read()


def sheet(name):
    return RF.png_to_tiles(open(os.path.join(RF.RES, 'graphics', name), 'rb').read())


def zx(attr, ink):
    colour = attr & 7 if ink else (attr >> 3) & 7
    return K.ink_colour(colour, attr & 0x40)


def tile_image(data, attr, scale):
    im = Image.new('RGB', (8, 8))
    px = im.load()
    for y in range(8):
        for x in range(8):
            px[x, y] = zx(attr, (data[y] >> (7 - x)) & 1)
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def save(im, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    im.save(out)
    print(out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# layout: the screen's areas


def layout(src, out):
    mem = memory(src)
    scr = K.render_screen(mem).resize((768, 576), Image.NEAREST)
    W, H = 1050, 660
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(15), K.font(12)
    d.text((12, 8), 'The screen: a menu bar, the tool palette, the status box and a 32 x 16 cell view of the map',
           font=f, fill=TEXT)
    x0, y0 = 12, 40
    im.paste(scr, (x0, y0))
    cell = 24
    areas = [  # rows, columns, colour, label
        (0, 0, 1, 32, YEL, 'row 0: menu bar (DrawStatusPanel $5F13)'),
        (1, 2, 2, 28, GRN, 'rows 1-2: 14 tool icons, 2 x 2 tiles (DrawToolIcons $5DD2)'),
        (2, 0, 1, 1, ORA, 'row 2, column 0: the scroll corner'),
        (3, 0, 5, 32, BLU, 'rows 3-7: status box: tool, price, date, name, funds'),
        (8, 0, 16, 32, RED, 'rows 8-23: the view, 32 x 16 map cells (DrawView $650B)'),
    ]
    ly = y0
    for r, c, h, w, col, label in areas:
        d.rectangle([x0 + c * cell, y0 + r * cell, x0 + (c + w) * cell - 1, y0 + (r + h) * cell - 1], outline=col,
                    width=3)
    lx = x0 + 768 + 16
    texts = [
        (YEL, 'row 0', 'menu bar: SYSTEM, OPTIONS,', 'DISASTERS, WINDOWS'),
        (GRN, 'rows 1-2', '14 tool icons, 2 x 2 tiles', 'each, columns 2-29'),
        (ORA, 'row 2, col 0', 'the scroll corner', '(ScrollClick $6CBF)'),
        (BLU, 'rows 3-7', 'status box: tool and price,', 'date, city name, funds'),
        (RED, 'rows 8-23', 'the view: 32 x 16 cells of', 'the 96 x 96 map, 8 x 8 px'),
    ]
    for col, a, b, c in texts:
        d.rectangle([lx, ly + 4, lx + 12, ly + 16], fill=col)
        d.text((lx + 20, ly), a, font=f, fill=TEXT)
        d.text((lx + 20, ly + 20), b, font=fs, fill=DIM)
        d.text((lx + 20, ly + 36), c, font=fs, fill=DIM)
        ly += 64
    d.text((lx, ly + 10), 'one attribute per 8 x 8', font=fs, fill=DIM)
    d.text((lx, ly + 26), 'cell = one map cell:', font=fs, fill=DIM)
    d.text((lx, ly + 42), 'no colour clash in the view', font=fs, fill=DIM)
    d.text((x0, y0 + 576 + 12), f'{src.split("/rec/")[-1]} (the recording\'s last frame), the screen at 3 x; frames: the areas the code draws',
           font=fs, fill=DIM)
    save(im, out)


# ---------------------------------------------------------------------------------------------------------------
# building: one building, map bytes to tiles


def building(src, col, row, out):
    mem = memory(src)
    btiles, battrs = sheet('Buildings.png')
    first = mem[MAP + SIDE * row + col]
    width = first & 7
    rows = []
    r = row
    while True:
        b = mem[MAP + SIDE * r + col]
        if not (0x80 <= b < 0xC0) or (r > row and b & 0x20):
            break
        rows.append(bytes(mem[MAP + SIDE * r + col:MAP + SIDE * r + col + width]))
        r += 1
    W = 1050
    H = 120 + len(rows) * 64 + 40
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(15), K.font(13)
    d.text((12, 8), 'One building on the map: each row is a start byte, two bytes of the tile number n, fillers',
           font=f, fill=TEXT)
    d.text((12, 30), f'map cell ({col}, {row}) of {src.split("/rec/")[-1]}, address ${MAP + SIDE * row + col:04X}; '
           f'cell k of a row shows BuildingTiles + 8 (n + k)', font=fs, fill=DIM)
    hdr = 64
    d.text((12, hdr), 'map bytes (CityMap)', font=fs, fill=DIM)
    d.text((300, hdr), 'start byte', font=fs, fill=DIM)
    d.text((470, hdr), 'n', font=fs, fill=DIM)
    d.text((540, hdr), 'tiles n .. n + width - 1', font=fs, fill=DIM)
    d.text((860, hdr), 'drawn', font=fs, fill=DIM)
    y = hdr + 24
    whole = Image.new('RGB', (8 * width, 8 * len(rows)))
    for i, rb in enumerate(rows):
        x = 12
        for k, b in enumerate(rb):
            colr = YEL if k == 0 else (CYA if k in (1, 2) else DIM)
            d.rectangle([x, y, x + 44, y + 40], outline=colr, width=2)
            d.text((x + 6, y + 12), f'{b:02X}', font=f, fill=colr)
            x += 46
        s = rb[0]
        d.text((300, y + 2), f'width {s & 7}', font=fs, fill=TEXT)
        d.text((300, y + 20), ('top row, ' + ('powered' if s & 0x10 else 'no power')) if s & 0x20 else 'lower row',
               font=fs, fill=TEXT)
        n = (rb[1] & 0x3F) * 8 + (rb[2] & 7)
        d.text((470, y + 2), f'{n}', font=f, fill=CYA)
        d.text((470, y + 22), f'${n:02X}', font=fs, fill=DIM)
        x = 540
        for k in range(width):
            t = n + k
            ti = tile_image(btiles[8 * t:8 * t + 8], battrs[t], 5)
            im.paste(ti, (x, y))
            d.text((x + 6, y + 41), f'{t:02X}', font=K.font(10), fill=DIM)
            whole.paste(tile_image(btiles[8 * t:8 * t + 8], battrs[t], 1), (8 * k, 8 * i))
            x += 48
        y += 64
    sc = max(1, min(160 // (8 * width), (H - 110) // (8 * len(rows))))
    im.paste(whole.resize((8 * width * sc, 8 * len(rows) * sc), Image.NEAREST), (860, hdr + 24))
    save(im, out)


# ---------------------------------------------------------------------------------------------------------------
# cells: the 94 cell tiles grouped by what they are

GROUPS = [
    ('water, coast, land, trees', [0, 1, 3, 4, 5, 2, 6]),
    ('road: 7 + NetworkShapes offset 0-10, bridges $12 $13', list(range(0x07, 0x14))),
    ('rail: $14 + offset 0-10, bridges $1F $20', list(range(0x14, 0x21))),
    ('power line: $21 + offset 0-10, over water $2C $2D', list(range(0x21, 0x2E))),
    ('crossings $2E-$33; traffic tiles $34-$37 (RoadTraffic)', list(range(0x2E, 0x38))),
    ('parks $38 $39, rubble $3A, no power $3B, houses $3C-$43', list(range(0x38, 0x44))),
    ('flood $44, fire $45, rubble $46-$48, zone frame $49-$50', list(range(0x44, 0x51))),
    ('zone centres powered $51-$53 / unpowered $54-$56, $57 $58, radiation $59', list(range(0x51, 0x5A))),
    ('animation frames: fire $5A $5B, flood $5C $5D (copied into $45, $44)', list(range(0x5A, 0x5E))),
]


def cells(out):
    tiles, attrs = sheet('Cells.png')
    sc, step = 4, 44
    W = 1050
    H = 60 + len(GROUPS) * 82
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(15), K.font(12), K.font(11)
    d.text((12, 8), 'The 94 cell tiles (src/res/graphics/Cells.png): a map byte below $80 is its own tile number',
           font=f, fill=TEXT)
    d.text((12, 30), 'tile CellTiles $EA68 + 8 x code, attribute CellAttrs $F530 + code; label: the code in hex',
           font=fs, fill=DIM)
    y = 58
    for title, codes in GROUPS:
        d.text((12, y), title, font=fs, fill=TEXT)
        x = 12
        for c in codes:
            a = attrs[c] if c < len(attrs) else 0x07
            im.paste(tile_image(tiles[8 * c:8 * c + 8], a, sc), (x, y + 18))
            d.text((x + 6, y + 18 + 33), f'{c:02X}', font=ft, fill=DIM)
            x += step
        y += 82
    save(im, out)


# ---------------------------------------------------------------------------------------------------------------
# sprites: the five movers and the pointer


def sprites(out):
    mv = RF.png_to_mono(open(os.path.join(RF.RES, 'graphics', 'Movers.png'), 'rb').read(), 160, RF.movers_order)
    pt = RF.png_to_mono(open(os.path.join(RF.RES, 'graphics', 'Pointer.png'), 'rb').read(), 16, RF.pointer_order)
    W, H = 1050, 360
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(15), K.font(12)
    d.text((12, 8), 'The movers (MoverSprites $A884, 16 x 16, 2 bytes a row) and the pointer (8 rows + 8 mask rows)',
           font=f, fill=TEXT)
    names = ['0 plane', '1 tornado', '2 tornado', '3 train across', '4 train down']
    sc = 7
    x = 12
    for s in range(5):
        pic = Image.new('RGB', (16, 16), PANEL)
        px = pic.load()
        for y in range(16):
            for xx in range(16):
                b = mv[s * 32 + y * 2 + xx // 8]
                if b >> (7 - (xx & 7)) & 1:
                    px[xx, y] = (235, 235, 235)
        im.paste(pic.resize((16 * sc, 16 * sc), Image.NEAREST), (x, 44))
        d.text((x, 44 + 16 * sc + 6), names[s], font=fs, fill=TEXT)
        d.text((x, 44 + 16 * sc + 22), f'${0xA884 + 32 * s:04X}', font=fs, fill=DIM)
        x += 16 * sc + 16
    sc2 = 14
    for k, (label, off) in enumerate([('pointer arrow (OR)', 0), ('pointer mask (AND)', 8)]):
        pic = Image.new('RGB', (8, 8), PANEL)
        px = pic.load()
        for y in range(8):
            b = pt[off + y]
            for xx in range(8):
                if b >> (7 - xx) & 1:
                    px[xx, y] = (235, 235, 235)
        x = 12 + k * (8 * sc2 + 40)
        im.paste(pic.resize((8 * sc2, 8 * sc2), Image.NEAREST), (x, 210 - 8))
        d.text((x + 8 * sc2 + 8 if k else x + 8 * sc2 + 8, 210), '', font=fs, fill=TEXT)
        d.text((x, 210 + 8 * sc2 - 2), label, font=fs, fill=TEXT)
        d.text((x, 210 + 8 * sc2 + 14), f'${0x5CEC + off:04X}', font=fs, fill=DIM)
    d.text((330, 214), 'white = a set bit. A mover is ORed onto the screen (DrawMover $7735);', font=fs, fill=DIM)
    d.text((330, 232), 'the pointer: screen AND mask, OR arrow (DrawPointer $5CFE), 8 bytes saved first.', font=fs,
           fill=DIM)
    d.text((330, 250), 'src/res/graphics/Movers.png and Pointer.png', font=fs, fill=DIM)
    save(im, out)


# ---------------------------------------------------------------------------------------------------------------
# overview: the maps window picture, emulated

LAYERS = ['CITY', 'POLLUTN', 'POLICE', 'FIREDEP', 'TRAFFIC', 'POWER', 'TRANSPT', 'CRIME']
AREA_CELLS = [(0, 0), (0, 24), (0, 48), (24, 0), (24, 24), (24, 48), (48, 0), (48, 24), (48, 48)]  # (row, column)


def overview_screen(mem, area, layer, rows=48, screen=None):
    """The bytes DrawOverview leaves at $4000-$5AFF for one area and layer (rows: how many cell rows to draw)"""
    ctiles = mem[0xEA68:0xEA68 + 752]
    btiles = mem[0xED58:0xED58 + 1952]
    flags = mem[0x6F9C:0x6F9C + 90]
    colours = mem[0x9CFA:0x9CFA + 8]
    scr = bytearray(screen if screen is not None else bytes(6912))

    def g48(base, r, c):
        return mem[base + 48 * (r >> 1) + (c >> 1)]

    def g24(base, r, c):
        return mem[base + 24 * (r >> 2) + (c >> 2)]

    def flag(b):
        return 0x99 if b & 0x80 else flags[b]

    r0, c0 = AREA_CELLS[area]
    cc_col, cc_row = mem[0x84A2], mem[0x84A3]
    for rr in range(rows):
        row = r0 + rr
        left, tile = 0, 0
        for cc in range(48):
            col = c0 + cc
            a = MAP + SIDE * row + col
            b = mem[a]
            if not left and b >= 0x80:
                ix, back = a, 0
                while mem[ix] & 0xC0 == 0xC0:
                    back += 1
                    ix -= 1
                left = (mem[ix] & 7) - back
                tile = (mem[ix + 1] & 0x3F) * 8 + (mem[ix + 2] & 7) + back
            if left:
                left -= 1
                data = mem[0xED58 + 8 * tile:0xED58 + 8 * tile + 8]
            else:
                t = b
                if b in (7, 8):
                    tr = g48(0xB6D0, row, col)
                    hi = 0x34 if b == 7 else 0x36
                    if tr >= 0xDC:
                        t = hi
                    elif tr >= 0x96:
                        t = hi + 1  # Blink is $10 in the maps window
                data = ctiles[8 * t:8 * t + 8]
            right = cc & 1
            line0 = 4 * rr
            xbyte = 8 + cc // 2
            for k in range(4):
                v = data[1 + 2 * k]
                c = (v & 0x80) | ((v & 0x20) << 1) | ((v & 0x08) << 2) | ((v & 0x02) << 3)
                mask = 0x0F
                if right:
                    c >>= 4
                    mask = 0xF0
                adr = K.screen_address(line0 + k, xbyte) - 0x4000
                scr[adr] = (scr[adr] & mask) | c
            attr_at = 0x1800 + (line0 >> 3) * 32 + xbyte
            scr[attr_at] = 0x21
            v = None
            pattern = False
            fl = flag(b)
            if layer in (1, 4):
                v = g48(0xADD0 if layer == 1 else 0xB6D0, row, col) >> 5
            elif layer in (2, 3):
                v = g24(0xAB90 if layer == 2 else 0xA950, row, col) >> 1
            elif layer == 5:
                pattern = bool(mem[0xBFD0 + 12 * row + (col >> 3)] & mem[0x5B11 + (col & 7)])
            elif layer == 6:
                pattern = bool(fl & 6)
            elif layer == 7 and fl & 0x10:
                dist = (abs(cc_row - row) + abs(cc_col - col)) & 0xFF
                if dist >= 0x20:
                    dist = 0x1F
                e = (15 - ((32 - dist) >> 1)) & 0xFF
                p = g24(0xAB90, row, col)
                e = (e - p) if e >= p else 0
                v = e >> 1
            if v:
                scr[attr_at] = colours[v] if v < 8 else mem[0x9CFA + v]
            if pattern:
                hi, lo, m = (0xA0, 0x50, 0x0F) if not right else (0x0A, 0x05, 0xF0)
                for k in range(4):
                    adr = K.screen_address(line0 + k, xbyte) - 0x4000
                    scr[adr] = (scr[adr] & m) | (hi if k % 2 == 0 else lo)
            tile += 1  # DrawOverviewNext: BuildingTile + 1 after every cell
    return scr


def overview(src, area, out):
    mem = memory(src)
    area -= 1
    pw = 240
    W = 1050
    cols = 4
    H = 70 + 2 * (pw + 34)
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    f, fs = K.font(15), K.font(12)
    r0, c0 = AREA_CELLS[area]
    d.text((12, 8), f'The maps window, area {area + 1} (map rows {r0}-{r0 + 47}, columns {c0}-{c0 + 47}): '
           'the eight layers as DrawOverview draws them', font=f, fill=TEXT)
    d.text((12, 30), f'{os.path.basename(os.path.dirname(src)) or src} {os.path.basename(src)}; '
           '4 x 4 pixels a cell (5 x 5 here); the paper colour: one attribute for 2 x 2 cells', font=fs, fill=DIM)
    gap = (W - 24 - cols * pw) // (cols + 1)
    for layer in range(8):
        scr = overview_screen(mem, area, layer)
        full = bytearray(mem)
        full[0x4000:0x5B00] = scr
        pic = K.render_screen(full).crop((64, 0, 256, 192)).resize((pw, pw), Image.NEAREST)
        x = 12 + gap + (layer % cols) * (pw + gap)
        y = 56 + (layer // cols) * (pw + 34)
        im.paste(pic, (x, y + 20))
        d.text((x, y), f'{layer} {LAYERS[layer]}', font=fs, fill=TEXT)
    save(im, out)


def check(mem_path, area, layer, rows):
    mem = memory(mem_path)
    scr = overview_screen(mem, area - 1, layer, rows, screen=mem[0x4000:0x5B00])
    bad = 0
    for line in range(4 * rows):
        for x in range(8, 32):
            adr = K.screen_address(line, x) - 0x4000
            if scr[adr] != mem[0x4000 + adr]:
                bad += 1
    abad = sum(1 for r in range((4 * rows) // 8) for x in range(8, 32)
               if scr[0x1800 + 32 * r + x] != mem[0x5800 + 32 * r + x])
    print(f'area {area} layer {layer}: {rows} cell rows, {4 * rows * 24} bitmap bytes: {bad} differ; '
          f'{(4 * rows) // 8 * 24} attributes: {abad} differ')


def main():
    a = sys.argv[1:]
    if not a:
        raise SystemExit(__doc__)
    cmd = a[0]
    if cmd == 'layout':
        layout(a[1], a[2])
    elif cmd == 'building':
        building(a[1], int(a[2]), int(a[3]), a[4])
    elif cmd == 'cells':
        cells(a[1])
    elif cmd == 'sprites':
        sprites(a[1])
    elif cmd == 'overview':
        overview(a[1], int(a[2]), a[3])
    elif cmd == 'check':
        check(a[1], int(a[2]), int(a[3]), int(a[4]))
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

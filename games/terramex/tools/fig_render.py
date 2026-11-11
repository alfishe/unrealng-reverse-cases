#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from the built image (build/game.bin = $7200-$FFFF, build/explorers.bin =
the five explorer sets, build/select.bin = the selector at $C000) and, for the annotated frame, from the memory of a
recording at the start of a frame (TTD memory_at of the instance of a work folder, kit/rs.py open).

    python3 tools/fig_render.py roombuild --room 14 --pick 2,3 --out docs/img/render/roombuild-14.png
    python3 tools/fig_render.py sprites --set 2 --out docs/img/render/sprite-space.png
    python3 tools/fig_render.py outline --set 2 --frame 2 --row 9 --out docs/img/render/outline-mirror.png
    python3 tools/fig_render.py shift --set 2 --frame 2 --x 42 --out docs/img/render/plot-shift.png
    python3 tools/fig_render.py frame --work W --at 6001 --label 'explorers frame 6001' --out docs/img/render/frame-6001.png
    python3 tools/fig_render.py cursor --out docs/img/render/cursor-frames.png
    python3 tools/fig_render.py sheets --out docs/img/render/tile-sheets.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)
HOT = (230, 40, 160)


def image():
    """the 64 KB memory as the built tape leaves it, game image at $7200 and the explorer set 0 at $6000"""
    mem = bytearray(0x10000)
    g = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[0x7200:0x7200 + len(g)] = g
    return mem


def explorer_set(mem, n):
    e = open(os.path.join(CASE, 'build', 'explorers.bin'), 'rb').read()
    mem[0x6000:0x7200] = e[n * 0x1200:(n + 1) * 0x1200]
    return mem


def tile_map(mem, room):
    """BuildTileMap $9914: room grid $D600 + 32 x room, back-tile b = 16 tiles at $C600 + 16 x b, at
    $F800 + 128 x row + 4 x column (+ 32 x i + j)"""
    grid = mem[0xD600 + 32 * room:0xD600 + 32 * room + 32]
    tm = bytearray(512)
    for r in range(4):
        for c in range(8):
            t = mem[0xC600 + 16 * grid[r * 8 + c]:0xC600 + 16 * grid[r * 8 + c] + 16]
            for i in range(4):
                for j in range(4):
                    tm[128 * r + 4 * c + 32 * i + j] = t[4 * i + j]
    return grid, tm


def draw_cells(mem, tm, scale):
    """DrawRoom $99A4: tile t = 8 bytes at $F000 + 8 x t, attribute $DF00 + t"""
    im = Image.new('RGB', (256, 128))
    px = im.load()
    for n in range(512):
        t = tm[n]
        a = mem[0xDF00 + t]
        ink, paper = K.ink_colour(a & 7, a & 0x40), K.ink_colour((a >> 3) & 7, a & 0x40)
        for y in range(8):
            b = mem[0xF000 + 8 * t + y]
            for x in range(8):
                px[(n % 32) * 8 + x, (n // 32) * 8 + y] = ink if b & (0x80 >> x) else paper
    return im.resize((256 * scale, 128 * scale), Image.NEAREST)


def sprite_bits(mem, frame):
    a = 0x6000 + 72 * frame
    return [mem[a + 24 * c:a + 24 * c + 24] for c in range(3)]


def sprite_image(cols, scale, ink=(255, 255, 255), paper=(0, 0, 0)):
    im = Image.new('RGB', (24, 24), paper)
    px = im.load()
    for c, col in enumerate(cols):
        for y, b in enumerate(col):
            for x in range(8):
                if b & (0x80 >> x):
                    px[c * 8 + x, y] = ink
    return im.resize((24 * scale, 24 * scale), Image.NEAREST)


def outline_masks(cols, mem, last_row_quirk=True):
    """DrawSpriteRow $9C7E: mask = OutlineMasks $FF00 [above | this | below]; the first row's above is 0, the last
    row's below is the next column's first byte"""
    masks = []
    flat = b''.join(cols) + b'\0'
    for c in range(3):
        m = []
        for y in range(24):
            i = 24 * c + y
            above = 0 if y == 0 else flat[i - 1]
            below = flat[i + 1] if (y < 23 or last_row_quirk) else 0
            m.append(mem[0xFF00 + (above | flat[i] | below)])
        masks.append(m)
    return masks


def composite(cols, masks, scale, back=(150, 150, 160)):
    """(background AND mask) OR graphic on a grey background: cleared border black, ink white"""
    im = Image.new('RGB', (24, 24), back)
    px = im.load()
    for c in range(3):
        for y in range(24):
            for x in range(8):
                bit = 0x80 >> x
                if cols[c][y] & bit:
                    px[c * 8 + x, y] = (255, 255, 255)
                elif not masks[c][y] & bit:
                    px[c * 8 + x, y] = (0, 0, 0)
    return im.resize((24 * scale, 24 * scale), Image.NEAREST)


def title(d, t, sub=None):
    d.text((14, 10), t, font=K.font(16), fill=FG)
    if sub:
        d.text((14, 32), sub, font=K.font(12), fill=DIM)


def arrow(d, a, b, col=FG):
    d.line((a, b), fill=col, width=2)
    import math
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for s in (2.6, -2.6):
        d.line((b, (b[0] + 10 * math.cos(ang + s), b[1] + 10 * math.sin(ang + s))), fill=col, width=2)


# ---------------------------------------------------------------------------------------------------------------------

def fig_roombuild(room, pick, out):
    mem = image()
    grid, tm = tile_map(mem, room)
    pr, pc = pick
    bt = grid[pr * 8 + pc]
    im = Image.new('RGB', (W, 760), BG)
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    title(d, f'Room ${room:02X} built: room grid -> back-tile -> tile map -> pixels (from build/game.bin)',
          'BuildTileMap $9914 writes the tile map $F800; DrawRoom $99A4 draws it to the screen and the back buffer')
    # 1: the room grid
    x0, y0, cw, ch = 14, 76, 46, 30
    d.text((x0, y0 - 20), f'1. room grid ${0xD600 + 32 * room:04X}: 4 x 8 back-tiles', font=fb, fill=FG)
    for r in range(4):
        for c in range(8):
            x, y = x0 + c * cw, y0 + r * ch
            hot = (r, c) == (pr, pc)
            d.rectangle((x, y, x + cw - 3, y + ch - 3), fill=(255, 225, 240) if hot else (255, 255, 255),
                        outline=HOT if hot else (150, 150, 155), width=2 if hot else 1)
            d.text((x + 10, y + 6), f'{grid[r * 8 + c]:02X}', font=f, fill=FG)
    d.text((x0, y0 + 4 * ch + 4), f'byte {pr * 8 + pc} = ${bt:02X} (row {pr}, column {pc})', font=fs, fill=HOT)
    # 2: the back-tile's 16 tiles
    x1 = 420
    d.text((x1, y0 - 20), f'2. back-tile ${bt:02X} (${0xC600 + 16 * bt:04X})', font=fb, fill=FG)
    tiles = mem[0xC600 + 16 * bt:0xC600 + 16 * bt + 16]
    for i in range(4):
        for j in range(4):
            x, y = x1 + j * 40, y0 + i * 30
            d.rectangle((x, y, x + 37, y + 27), fill=(255, 255, 255), outline=(150, 150, 155))
            d.text((x + 7, y + 6), f'{tiles[4 * i + j]:02X}', font=f, fill=FG)
    # 3: its pixels at 4 x
    x2 = 660
    d.text((x2, y0 - 20), '3. drawn (4 x)', font=fb, fill=FG)
    sub = bytearray(512)
    for i in range(4):
        for j in range(4):
            sub[32 * i + j] = tiles[4 * i + j]
    blk = draw_cells(mem, sub, 4).crop((0, 0, 128, 128))
    im.paste(blk, (x2, y0))
    d.text((x2 + 140, y0), 'tile t:', font=fs, fill=DIM)
    d.text((x2 + 140, y0 + 18), '8 pixel bytes at', font=fs, fill=FG)
    d.text((x2 + 140, y0 + 36), '$F000 + 8 x t', font=fs, fill=FG)
    d.text((x2 + 140, y0 + 60), 'attribute at', font=fs, fill=FG)
    d.text((x2 + 140, y0 + 78), '$DF00 + t', font=fs, fill=FG)
    d.text((x2 + 140, y0 + 102), f'tile ${tiles[0]:02X}: attr ${mem[0xDF00 + tiles[0]]:02X}', font=fs, fill=DIM)
    # 4: the tile map and the window
    y3 = 250
    d.text((14, y3 - 24), f'4. the tile map $F800 (32 x 16 tiles) drawn by DrawRoom, 2 x; back-tile ${bt:02X} '
                          f'lands at ${0xF800 + 128 * pr + 4 * pc:04X}', font=fb, fill=FG)
    win = draw_cells(mem, tm, 2)
    im.paste(win, (14, y3))
    for r in range(5):
        d.line((14, y3 + 64 * r, 14 + 512, y3 + 64 * r), fill=(120, 120, 130))
    for c in range(9):
        d.line((14 + 64 * c, y3, 14 + 64 * c, y3 + 256), fill=(120, 120, 130))
    d.rectangle((14 + 64 * pc, y3 + 64 * pr, 14 + 64 * pc + 64, y3 + 64 * pr + 64), outline=HOT, width=3)
    # the tile map bytes of the picked block, and the address rule
    xt = 545
    d.text((xt, y3), 'the tile map, rows 0-3 of the block:', font=fs, fill=DIM)
    for i in range(4):
        a = 0xF800 + 128 * pr + 4 * pc + 32 * i
        d.text((xt, y3 + 20 + 18 * i), f'${a:04X}: ' + ' '.join(f'{tm[a - 0xF800 + j]:02X}' for j in range(4)), font=f,
               fill=FG)
    lines = ['cell n of the window (0-511):',
             '  tile    = $F800 [n]',
             '  attr    -> $5800 + n',
             '  screen  H = $40 | (n >> 8) << 3, L = n AND $FF',
             '  buffer  the same address OR $E000',
             '  8 pixel rows: H + 0 ... H + 7',
             '',
             'the window = the screen\'s top two thirds;',
             'the back buffer $E000-$EFFF = its pixels.']
    for k, t in enumerate(lines):
        d.text((xt, y3 + 104 + 18 * k), t, font=f, fill=FG)
    # the arrows
    arrow(d, (x0 + 8 * cw + 2, y0 + pr * ch + 14), (x1 - 6, y0 + 50), HOT)
    arrow(d, (x1 + 164, y0 + 60), (x2 - 6, y0 + 60), HOT)
    d.text((14, 540), 'How to read: the pink cell of the grid names a back-tile; its 16 tile numbers become a 4 x 4 '
                      'block of the tile map; DrawRoom', font=fs, fill=FG)
    d.text((14, 558), 'turns each tile number into 8 pixel bytes and an attribute. The grid of grey lines shows the '
                      '32 back-tiles of the room.', font=fs, fill=FG)
    im = im.crop((0, 0, W, 584))
    im.save(out)


def fig_sprites(setn, out):
    mem = explorer_set(image(), setn)
    per, sc = 16, 2
    cw, chh = 64, 74
    rows = (160 + per - 1) // per
    im = Image.new('RGB', (W, 66 + rows * chh + 70), BG)
    d = ImageDraw.Draw(im)
    title(d, 'The sprite space: frame F at $6000 + 72 x F, frames $00-$9F (explorer set '
             f'{setn} copied to $6000)', 'three columns of 24 bytes per frame; the colour of the label is the '
                                         'region: explorer set, creatures, the blank $7F, items')
    regions = [(0x00, 0x3F, (46, 140, 60), 'explorer $6000'), (0x40, 0x7E, (40, 100, 200), 'creatures $7200'),
               (0x7F, 0x7F, (150, 150, 160), 'blank $83B8'), (0x80, 0x9F, (225, 120, 20), 'items $8400')]
    for fr in range(160):
        col = next(c for a, b, c, _ in regions if a <= fr <= b)
        x, y = 14 + (fr % per) * cw, 60 + (fr // per) * chh
        im.paste(sprite_image(sprite_bits(mem, fr), sc, ink=(255, 255, 255), paper=(20, 20, 28)), (x, y + 16))
        d.text((x, y), f'{fr:02X} {0x6000 + 72 * fr:04X}', font=K.font(11), fill=col)
    y = 60 + rows * chh + 6
    x = 14
    for a, b, c, t in regions:
        d.rectangle((x, y + 2, x + 14, y + 16), fill=c)
        d.text((x + 20, y), f'${a:02X}-${b:02X} {t}', font=K.font(13), fill=FG)
        x += 250
    d.text((14, y + 26), 'The explorer set holds 64 frames: walking 0-3, the portrait 9, climbing $20-$23 and the '
                         'rest; the selector copies the chosen one to $6000.', font=K.font(12), fill=DIM)
    im.save(out)


def fig_outline(setn, frame, row, out):
    mem = explorer_set(image(), setn)
    cols = sprite_bits(mem, frame)
    masks = outline_masks(cols, mem)
    mir = [bytes(mem[0xFE00 + b] for b in cols[c]) for c in (2, 1, 0)]
    mmasks = outline_masks(mir, mem)
    sc = 7
    im = Image.new('RGB', (W, 720), BG)
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    title(d, f'Frame ${frame:02X} of explorer set {setn}: the graphic, its outline mask and the mirror',
          'DrawSpriteRow $9C7E: mask = OutlineMasks $FF00 [above OR this OR below]; buffer = (buffer AND mask) OR graphic;'
          ' build/explorers.bin')
    panels = [('graphic (72 bytes)', sprite_image(cols, sc, paper=(20, 20, 28))),
              ('bit 7 clear: as stored, faces left', composite(cols, masks, sc)),
              ('bit 7 set: mirrored, faces right', composite(mir, mmasks, sc))]
    for i, (t, p) in enumerate(panels):
        x = 14 + i * 345
        d.text((x, 54), t, font=fb, fill=FG)
        im.paste(p, (x, 76))
        if i < 2:
            d.line((x, 76 + row * sc + sc // 2, x + 24 * sc, 76 + row * sc + sc // 2), fill=HOT)
    d.text((14, 76 + 24 * sc + 8), 'grey = the background left alone; black = cleared by the mask (the outline); '
                                   'white = the graphic. The pink line is the row worked below.', font=fs, fill=DIM)
    # worked row, column 1
    y = 76 + 24 * sc + 40
    c = 1
    above, this, below = cols[c][row - 1], cols[c][row], cols[c][row + 1]
    o = above | this | below
    mk = mem[0xFF00 + o]
    d.text((14, y), f'Worked example: row {row}, column {c} (byte ${0x6000 + 72 * frame + 24 * c + row:04X} of '
                    'the sprite space)', font=fb, fill=FG)

    def bitrow(yy, name, v, colr=FG, note=''):
        d.text((14, yy + 4), name, font=f, fill=colr)
        for k in range(8):
            on = v >> (7 - k) & 1
            d.rectangle((260 + k * 30, yy, 260 + k * 30 + 26, yy + 24), fill=(60, 60, 70) if on else (255, 255, 255),
                        outline=(150, 150, 155))
        d.text((260 + 8 * 30 + 12, yy + 4), f'${v:02X}  {note}', font=f, fill=colr)
    rows_ = [('above', above, FG, f'row {row - 1}'), ('this', this, FG, f'row {row}'),
             ('below', below, FG, f'row {row + 1}'), ('o = above OR this OR below', o, FG, ''),
             ('OutlineMasks [o]', mk, HOT, 'NOT (o OR o << 1 OR o >> 1)'),
             ('mirror: BitReverse [this]', mem[0xFE00 + this], (40, 100, 200), 'bit 7 set (facing right): column 2 - 1 = 1')]
    for k, (n, v, col, note) in enumerate(rows_):
        bitrow(y + 26 + 30 * k, n, v, col, note)
    yy = y + 26 + 30 * len(rows_) + 10
    for t in ['The mask clears this byte\'s pixels and all eight neighbours, diagonals included (rows ORed, then '
              'spread left and right).',
              'Pixels at the byte\'s edge get no outline from the next column (o << 1 and o >> 1 stay in the byte).',
              'The first row of a column has "above" = 0; the last row reads the next column\'s first byte '
              '(a quirk: the outline can leak).']:
        d.text((14, yy), t, font=fs, fill=FG)
        yy += 20
    im = im.crop((0, 0, W, yy + 10))
    im.save(out)


def fig_shift(setn, frame, x, out):
    """the plot of one row at X mod 8 = k: the graphic and mask spread over two bytes"""
    mem = explorer_set(image(), setn)
    cols = sprite_bits(mem, frame)
    masks = outline_masks(cols, mem)
    k = x & 7
    im = Image.new('RGB', (W, 470), BG)
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    title(d, f'X = ${x:02X}: X mod 8 = {k}, so every byte of the sprite is shifted {k} pixels right over two '
             'buffer bytes', f'BufferAddress $9CEE picks the plotter: IY = $9C97 + 4 x {k} = ${0x9C97 + 4 * k:04X} '
                             '(PlotRowAligned $9CE7 when k = 0); explorer set '
                             f'{setn}, frame ${frame:02X}')
    sc = 5
    # the sprite on a 32-pixel strip, before and after the shift
    for i, kk in enumerate((0, k)):
        x0 = 14 + i * 520
        d.text((x0, 54), f'k = {kk}' + (' (aligned)' if kk == 0 else f' (X = ${x:02X})'), font=fb, fill=FG)
        strip = Image.new('RGB', (32, 24), (150, 150, 160))
        px = strip.load()
        for y in range(24):
            g = (cols[0][y] << 16 | cols[1][y] << 8 | cols[2][y]) << (8 - kk)
            clear = (~(masks[0][y] << 16 | masks[1][y] << 8 | masks[2][y]) & 0xFFFFFF) << (8 - kk)
            for xx in range(32):
                bit = 1 << (31 - xx)
                if g & bit:
                    px[xx, y] = (255, 255, 255)
                elif clear & bit:
                    px[xx, y] = (0, 0, 0)
        im.paste(strip.resize((32 * sc, 24 * sc), Image.NEAREST), (x0, 76))
        for b in range(5):
            d.line((x0 + b * 8 * sc, 76, x0 + b * 8 * sc, 76 + 24 * sc), fill=HOT if b in (0, 4) else (90, 90, 200))
        d.text((x0 + 32 * sc + 10, 76), 'buffer bytes C, C+1, C+2, C+3', font=fs, fill=DIM)
        d.text((x0 + 32 * sc + 10, 94), '(blue lines: byte edges)', font=fs, fill=DIM)
    y = 76 + 24 * sc + 20
    lines = ['Each sprite byte g and its mask m become a 16-bit pair: ADD HL,HL / SLL D / RLA repeated 8 - k times',
             '(PlotRowShift1-7 $9C9B-$9CB3, entered at $9C97 + 4 x k), then',
             '  (BC)   = (BC)   AND E OR H      the left byte',
             '  (BC+1) = (BC+1) AND D OR L      the right byte',
             'so a 3-column sprite covers 4 buffer bytes when k > 0; the copy to the screen is always 4 bytes x 24 '
             'rows (CopyRects $9BEB).',
             'SLL D shifts a 1 in from the right: the mask keeps the background beside the sprite.',
             'PlotShiftUnused $9C97 (k = 0 through the shifter) is never run: k = 0 goes to PlotRowAligned $9CE7.']
    for t in lines:
        d.text((14, y), t, font=f, fill=FG)
        y += 22
    im = im.crop((0, 0, W, y + 10))
    im.save(out)


def screen_xy(addr):
    a = addr - 0x4000
    return (a & 0x1F) * 8, ((a >> 11) & 3) * 64 + ((a >> 5) & 7) * 8 + ((a >> 8) & 7)


def memory_of(work, frame):
    """$0000-$FFFF at the start of frame (TTD memory_at of the instance of work; $0000-$3FFF left zero)"""
    sys.path.insert(0, HERE)
    import fig_controls
    s = fig_controls.session(work)
    return bytes(0x4000) + b''.join(fig_controls.mem(s, frame, a, 0x1000) for a in range(0x4000, 0x10000, 0x1000))


def fig_frame(work, frame, label, out):
    mem = memory_of(work, frame)
    sc = 3
    scr = K.render_screen(mem[0x4000:0x5B00], 0).resize((256 * sc, 192 * sc), Image.NEAREST)
    im = Image.new("RGB", (W, 192 * sc + 160), K.BACKGROUND)
    im.paste(scr, (0, 60))
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    d.text((10, 8), f'Code against the screen: {label}', font=fb, fill=K.TEXT)
    d.text((10, 32), 'boxes from memory sampled at the frame start: the slots $5B04, ActorRects $5B44, the floor '
                     'items $5C0E, the panel addresses', font=fs, fill=K.DIM)
    cols = [(255, 80, 200), (80, 200, 255), (120, 255, 120), (255, 200, 60), (200, 160, 255)]
    x0 = 784
    y = 64
    d.text((x0, y), 'slot  X  Y  frame flags', font=fs, fill=K.DIM)
    for s in range(5):
        X, Y, F, FL = mem[0x5B04 + 4 * s:0x5B08 + 4 * s]
        ra = mem[0x5B44 + 4 * s] | mem[0x5B45 + 4 * s] << 8
        pl = mem[0x5B46 + 4 * s] | mem[0x5B47 + 4 * s] << 8
        sx, sy = screen_xy(ra & 0x5FFF)
        d.rectangle((sx * sc, 60 + sy * sc, (sx + 32) * sc, 60 + (sy + 24) * sc), outline=cols[s], width=1)
        d.rectangle((X * sc, 60 + (Y & 0x7F) * sc, (X + 24) * sc, 60 + ((Y & 0x7F) + 24) * sc), outline=cols[s],
                    width=3)
        d.text((x0, y + 18 + 34 * s), f'{s}  {X:02X} {Y:02X} {F:02X}  {FL:02X}', font=f, fill=cols[s])
        d.text((x0, y + 34 + 34 * s), f'   rect ${ra:04X} plot ${pl:04X}', font=fs, fill=K.DIM)
    y += 18 + 34 * 5 + 6
    for i, a in enumerate((0x5C0E, 0x5C13)):
        X, Y, it = mem[a:a + 3]
        d.text((x0, y), f'item {i + 1} ${a:04X}: X {X:02X} Y {Y:02X} = {it:02X}', font=fs, fill=(255, 140, 60))
        if it < 0xFE:
            d.rectangle((X * sc, 60 + Y * sc, (X + 24) * sc, 60 + (Y + 24) * sc), outline=(255, 140, 60), width=3)
        y += 18
    panel = [(0x5092, 3, 'portrait $5092 (DrawPortrait)'), (0x5032, 3, 'held item $5032'),
             (0x5081, 9, 'spare lives $5081 (DrawSpareLives)'), (0x5096, 9, 'bearers $5096 (DrawBearers)'),
             (0x5036, 9, 'carried items $5036')]
    y += 8
    for a, w, t in panel:
        sx, sy = screen_xy(a)
        d.rectangle((sx * sc, 60 + sy * sc, (sx + 8 * w) * sc, 60 + (sy + 24) * sc), outline=(255, 255, 120), width=2)
        d.text((x0, y), t, font=fs, fill=(255, 255, 120))
        y += 18
    yb = 60 + 192 * sc + 8
    for t in ['thick box = the sprite at (X, Y), 24 x 24; thin box = what CopyRects copies (4 bytes x 24 rows at '
              'ActorRects);',
              'orange = a floor item (DrawItem); yellow = the panel fields.',
              'Slots 3 and 4 are blank (frame $7F at X 0, Y 0): their rectangle at the top left is still drawn and '
              'copied every pass.']:
        d.text((10, yb), t, font=fs, fill=K.TEXT)
        yb += 20
    im = im.crop((0, 0, W, yb + 8))
    im.save(out)


def fig_cursor(out):
    sel = open(os.path.join(CASE, 'build', 'select.bin'), 'rb').read()
    base = 0xC000
    sc = 6
    im = Image.new('RGB', (W, 330), BG)
    d = ImageDraw.Draw(im)
    title(d, 'The selector\'s hand cursor: CursorSprites $CD8F, four frames pre-shifted by 0, 2, 4, 6 pixels', 'graphic 3 columns x 16 bytes, then the mask; frame (x AND 6) / 2; '
                                       'screen = (screen AND mask) OR graphic; build/select.bin')
    for k in range(4):
        a = 0xCD8F + 0x60 * k - base
        g, m = sel[a:a + 48], sel[a + 48:a + 96]
        p = Image.new('RGB', (24, 16), (150, 150, 160))
        px = p.load()
        for y in range(16):
            for c in range(3):
                gb, mb = g[16 * c + y], m[16 * c + y]
                for b in range(8):
                    bit = 0x80 >> b
                    if gb & bit:
                        px[c * 8 + b, y] = (255, 255, 255)
                    elif not mb & bit:
                        px[c * 8 + b, y] = (0, 0, 0)
        x = 14 + k * 258
        d.text((x, 56), f'frame {k}: x AND 6 = {2 * k}, ${0xCD8F + 0x60 * k:04X}', font=K.font(13), fill=FG)
        im.paste(p.resize((24 * sc, 16 * sc), Image.NEAREST), (x, 78))
        for b in range(4):
            d.line((x + b * 8 * sc, 78, x + b * 8 * sc, 78 + 16 * sc), fill=(90, 90, 200))
    yb = 78 + 16 * sc + 14
    for t in ['grey = the picture left alone; black = cleared by the mask; white = the graphic; blue lines = byte '
              'edges.',
              'The cursor moves 2 pixels a frame (MoveCursor $C1D5), so four pre-shifted copies cover every even x; '
              'odd x never occurs.',
              'Before each draw RestoreUnderCursor $C1A2 copies the 3 x 16 bytes back from SelectorPicture $CF0F.']:
        d.text((14, yb), t, font=K.font(12), fill=FG)
        yb += 20
    im = im.crop((0, 0, W, yb + 8))
    im.save(out)


def fig_sheets(out):
    """the resource sheets the renderer reads: the two tile sets, the flame and capsule frames, the panel"""
    res = os.path.join(CASE, 'src', 'res')
    base = Image.open(os.path.join(res, 'tiles', 'base.png')).convert('RGB')
    alt = Image.open(os.path.join(res, 'tiles', 'alt.png')).convert('RGB')
    flames = Image.open(os.path.join(res, 'graphics', 'flames.png')).convert('RGB')
    caps = Image.open(os.path.join(res, 'graphics', 'capsules.png')).convert('RGB')
    panel = Image.open(os.path.join(res, 'screens', 'panel.png')).convert('RGB')
    im = Image.new('RGB', (W, 1000), BG)
    d = ImageDraw.Draw(im)
    f = K.font(13)
    title(d, 'The sheets the renderer reads (src/res): the tiles, the animated tiles, the panel',
          'tiles/base.png = TilePixels $F000 + TileAttrs $DF00; tiles/alt.png = $FA00 + $C580, swapped in for tiles '
          '$80-$FF; screens/panel.png')
    sc = 3
    y0 = 78
    d.text((14, y0), 'base set: tiles $00-$FF, 16 a row', font=f, fill=FG)
    im.paste(base.resize((base.width * sc, base.height * sc), Image.NEAREST), (14, y0 + 22))
    x1 = 14 + base.width * sc + 30
    d.text((x1, y0), 'alternate set: tiles $80-$FF (15 rooms)', font=f, fill=FG)
    im.paste(alt.resize((alt.width * sc, alt.height * sc), Image.NEAREST), (x1, y0 + 22))
    ya = y0 + 22 + alt.height * sc + 20
    s5 = 5
    d.text((x1, ya), 'graphics/flames.png: 4 frames of tile $B5 (base set)', font=f, fill=FG)
    im.paste(flames.resize((flames.width * s5, flames.height * s5), Image.NEAREST), (x1, ya + 22))
    yc = ya + 22 + flames.height * s5 + 18
    d.text((x1, yc), 'graphics/capsules.png: 4 frames of tiles $8C-$8D (alternate)', font=f, fill=FG)
    im.paste(caps.resize((caps.width * s5, caps.height * s5), Image.NEAREST), (x1, yc + 22))
    yp = y0 + 22 + base.height * sc + 26
    d.text((14, yp), 'screens/panel.png: the bottom third ($5000-$57FF), 4 x; yellow = the fields the play code redraws',
           font=f, fill=FG)
    ps = 4
    px, py = 14, yp + 22
    im.paste(panel.resize((panel.width * ps, panel.height * ps), Image.NEAREST), (px, py))
    fields = [(0x5092, 3, 'portrait'), (0x5032, 3, 'held'), (0x5081, 9, 'spare lives $5081'),
              (0x5096, 9, 'bearers $5096'), (0x5036, 9, 'loads $5036')]
    for a, w, t in fields:
        row, col = (a & 0xFF) >> 5, a & 0x1F
        bx, by = px + col * 8 * ps, py + row * 8 * ps
        d.rectangle((bx, by, bx + w * 8 * ps - 1, by + 24 * ps - 1), outline=(240, 200, 0), width=3)
        d.rectangle((bx + 3, by + 3, bx + 3 + len(t) * 8, by + 20), fill=(240, 200, 0))
        d.text((bx + 5, by + 4), t, font=K.font(12), fill=FG)
    yb = py + panel.height * ps + 12
    for t in ['How to read: each tile cell shows its 8 x 8 pixels in its attribute colours. The alternate sheet replaces '
              'the lower half of the base sheet',
              '(tiles $80-$FF) while the hero is in one of its 15 rooms. The flame and capsule frames are copied into '
              'the tile bitmaps every pass.']:
        d.text((14, yb), t, font=K.font(12), fill=FG)
        yb += 20
    im = im.crop((0, 0, W, yb + 8))
    im.save(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['roombuild', 'sprites', 'outline', 'shift', 'frame', 'cursor', 'sheets'])
    p.add_argument('--room', default='14')
    p.add_argument('--pick', default='2,3')
    p.add_argument('--set', type=int, default=2)
    p.add_argument('--frame', type=lambda v: int(v, 0), default=2)
    p.add_argument('--row', type=int, default=9)
    p.add_argument('--x', type=lambda v: int(v, 0), default=42)
    p.add_argument('--work')
    p.add_argument('--at', type=int)
    p.add_argument('--label', default='')
    p.add_argument('--out', required=True)
    a = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.what == 'roombuild':
        fig_roombuild(int(a.room, 16), tuple(int(v) for v in a.pick.split(',')), a.out)
    elif a.what == 'sprites':
        fig_sprites(a.set, a.out)
    elif a.what == 'outline':
        fig_outline(a.set, a.frame, a.row, a.out)
    elif a.what == 'shift':
        fig_shift(a.set, a.frame, a.x, a.out)
    elif a.what == 'frame':
        fig_frame(a.work, a.at, a.label, a.out)
    elif a.what == 'sheets':
        fig_sheets(a.out)
    else:
        fig_cursor(a.out)


if __name__ == '__main__':
    main()

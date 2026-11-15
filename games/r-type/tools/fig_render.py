#!/usr/bin/env python3
"""The figures of doc 6 (rendering): the buffers, a metatile in its four variants, the game's objects, the code
against the screen on one real frame, and the scroll of the right edge pass by pass.

    python3 tools/fig_render.py memory --out docs/img/render/memory.png
    python3 tools/fig_render.py metatile --level 1 --tile 9 --out docs/img/render/metatile.png
    python3 tools/fig_render.py objects --out docs/img/render/game-objects.png
    python3 tools/fig_render.py frame --work W --frame F --out docs/img/render/frame.png
    python3 tools/fig_render.py scrollzoom --work W --from F --to G --out docs/img/play/scroll-edge.gif

memory: the 48K's RAM from $5B00 to $83FF, a row a page, coloured by what the scroll and the drawers keep there (the
addresses of src/game/game.ann). metatile: one metatile of a level (tools/levelmap.py reads the resources) drawn by
the four cutters $8741, $8778, $87B8, $87F2, with the source cell each target cell comes from, and the column cut
into ColumnBuffer $5E00. objects: the game's own objects (GameObjects $BC67, cells at Sprites $A604) from
build/game.bin. frame: one frame of a recording opened in W (time_travel memory_at, T 0): the screen, its pixels
without attributes, SolidMap $7E00 (the cell tags) and DrawnMap $8100 with PlayAttrs $7800 over the pixel shadow
$6000. scrollzoom: the right eight columns of the playfield, frame by frame, raw pixels and the tags, with
ScrollStep, MetaColumn and MapColumn.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, os.path.join(CASE, 'tools'))
import kitlib as K  # noqa: E402

WIDTH = 1050
GAME_BASE = 0x7000


def game_image():
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[GAME_BASE:GAME_BASE + len(data)] = data
    return mem


def zx(attr, bright_bit=True):
    ink = K.ink_colour(attr & 7, bright_bit and attr & 0x40)
    paper = K.ink_colour((attr >> 3) & 7, bright_bit and attr & 0x40)
    return ink, paper


def draw_cell(px, x0, y0, rows, attr, mono=False):
    ink, paper = ((255, 255, 255), (0, 0, 0)) if mono else zx(attr)
    for y, b in enumerate(rows):
        for x in range(8):
            px[x0 + x, y0 + y] = ink if b & (0x80 >> x) else paper


# ---------------------------------------------------------------------------------------------------------------
# memory

REGIONS = [
    (0x5B00, 0x5B63, 'free at play', (60, 60, 70)),
    (0x5B64, 0x5CFF, 'EntryCopy: 414 bytes copied at the entry', (120, 90, 160)),
    (0x5D00, 0x5DFF, 'BitReverse: mirrored cells, keys 6-0', (230, 150, 60)),
    (0x5E00, 0x5EB3, 'ColumnBuffer: the next column, 20 cells of 9 bytes', (240, 210, 70)),
    (0x5EB4, 0x5EE3, 'ShipShots', (90, 200, 120)),
    (0x5F00, 0x5F9B, 'MissileA, B, C', (90, 200, 120)),
    (0x5FC1, 0x5FFC, 'Explosions', (90, 200, 120)),
    (0x6000, 0x6FFF, 'pixel shadow: rows 0-15 (screen + $2000)', (70, 150, 250)),
    (0x7800, 0x7A7F, 'PlayAttrs: the attribute shadow, 20 x 32', (230, 90, 80)),
    (0x7A80, 0x7AEF, 'GameVars: the scroll, the ship, the beam', (200, 110, 230)),
    (0x7AF0, 0x7CD7, 'Font: 61 glyphs', (180, 180, 190)),
    (0x7CD8, 0x7D81, 'HiScoreTable and its spare entry', (180, 180, 190)),
    (0x7E00, 0x807F, 'SolidMap: one tag a cell, 20 x 32', (70, 210, 220)),
    (0x8080, 0x80CF, 'RowTable: each row\'s screen and attribute address', (240, 120, 180)),
    (0x8100, 0x837F, 'DrawnMap: 1 = a sprite cell is on the screen', (150, 220, 90)),
]


def cmd_memory(args):
    first, last = 0x5B, 0x83
    rows = last - first + 1
    rh, cw, x0, y0 = 15, 3, 70, 46
    legend_y = y0 + rows * rh + 16
    pic = Image.new('RGB', (WIDTH, legend_y + 8 * 22 + 30), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, small = K.font(14), K.font(12)
    d.text((12, 10), 'The buffers of the scroll and the drawers, $5B00-$83FF in play (a row is 256 bytes)',
           fill=K.TEXT, font=K.font(16))
    colour = {}
    for a, b, _, c in REGIONS:
        for x in range(a, b + 1):
            colour[x] = c
    third = (40, 105, 200)
    for page in range(first, last + 1):
        y = y0 + (page - first) * rh
        d.text((12, y), f'${page:02X}00', fill=K.DIM, font=small)
        for lo in range(256):
            addr = page << 8 | lo
            c = colour.get(addr)
            if c is None and 0x7000 <= addr <= 0x77FF:
                c = third if lo < 0x80 else (110, 110, 120)
            if c is None:
                c = K.PANEL
            d.rectangle([x0 + lo * cw, y, x0 + lo * cw + cw - 1, y + rh - 3], fill=c)
    d.text((x0 + 256 * cw + 12, y0 + (0x70 - first) * rh - 2), '$7000-$77FF: low halves', fill=K.TEXT, font=small)
    d.text((x0 + 256 * cw + 12, y0 + (0x70 - first) * rh + 14), 'shadow rows 16-19,', fill=K.TEXT, font=small)
    d.text((x0 + 256 * cw + 12, y0 + (0x70 - first) * rh + 30), 'high halves texts and', fill=K.TEXT, font=small)
    d.text((x0 + 256 * cw + 12, y0 + (0x70 - first) * rh + 46), 'variables ($7080, $7180 ...)', fill=K.TEXT,
           font=small)
    items = REGIONS[1:] + [(0x7000, 0x77FF, 'pixel shadow rows 16-19: the low half of each page', third),
                           (0x7080, 0x77FF, 'texts and variables: the high halves', (110, 110, 120))]
    seen = set()
    k = 0
    for a, b, text, c in items:
        if text in seen:
            continue
        seen.add(text)
        col, row = k % 2, k // 2
        x, y = 12 + col * 520, legend_y + row * 22
        d.rectangle([x, y + 2, x + 14, y + 14], fill=c)
        d.text((x + 22, y), f'${a:04X} {text}', fill=K.TEXT, font=small)
        k += 1
    pic = pic.crop((0, 0, WIDTH, legend_y + ((k + 1) // 2) * 22 + 10))
    pic.save(args.out)
    print(args.out, pic.size)


# ---------------------------------------------------------------------------------------------------------------
# metatile

def rev(b):
    return int(f'{b:08b}'[::-1], 2)


def variant_cells(t, variant):
    """[(target row, target column, source row, source column, attr, 8 rows)] the way the cutters build a metatile"""
    out = []
    for r in range(4):
        for c in range(4):
            sr, sc = (3 - r if variant & 2 else r), (3 - c if variant & 1 else c)
            cell = t[sr * 36 + sc * 9: sr * 36 + sc * 9 + 9]
            attr, rows = cell[0], list(cell[1:])
            if variant & 2:
                rows = rows[::-1]
            if variant & 1:
                rows = [rev(b) for b in rows]
            out.append((r, c, sr, sc, attr, rows))
    return out


def cmd_metatile(args):
    import levelmap as L
    lv = L.levels()[args.level]
    addr, t = lv.tile(args.tile)
    s = 6
    tile_px = 32 * s
    pic = Image.new('RGB', (WIDTH, 760), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, small, big = K.font(13), K.font(12), K.font(16)
    d.text((12, 10), f'Level {args.level}, metatile {args.tile} (${addr:04X}, 144 bytes) cut by the four drawers',
           fill=K.TEXT, font=big)
    names = [('$00 + n: CutMetatile $8741', 'as stored'), ('$40 + n: CutMetatileMirrored $8778', 'left to right'),
             ('$80 + n: CutMetatileFlipped $87B8', 'upside down'), ('$C0 + n: CutMetatileBoth $87F2', 'both')]
    for v in range(4):
        x0, y0 = 12 + v * 258, 64
        img = Image.new('RGB', (32, 32))
        px = img.load()
        for r, c, sr, sc, attr, rows in variant_cells(t, v):
            draw_cell(px, c * 8, r * 8, rows, attr)
        pic.paste(img.resize((tile_px, tile_px), Image.NEAREST), (x0, y0))
        for r, c, sr, sc, attr, rows in variant_cells(t, v):
            x, y = x0 + c * 8 * s, y0 + r * 8 * s
            d.rectangle([x, y, x + 8 * s - 1, y + 8 * s - 1], outline=(90, 90, 100))
            d.text((x + 3, y + 2), f'{sr}{sc}', fill=(255, 255, 255), font=small, stroke_width=2,
                   stroke_fill=(0, 0, 0))
        d.text((x0, y0 - 22), f'map byte ${v * 0x40 + args.tile:02X}', fill=K.TEXT, font=f)
        d.text((x0, y0 + tile_px + 6), names[v][0], fill=K.TEXT, font=small)
        d.text((x0, y0 + tile_px + 22), names[v][1], fill=K.DIM, font=small)
    d.text((12, 312), 'The digits in a cell: the row and column of the stored cell it comes from. Mirrored: the column '
                      'XOR 3 and every', fill=K.DIM, font=small)
    d.text((12, 328), 'byte through BitReverse $5D00. Flipped: the 4 rows and the 8 lines read backwards from +$8F. '
                      'Both: the two at once.', fill=K.DIM, font=small)
    # the stored bytes: 4 rows of 4 cells of 9 bytes
    y0 = 362
    d.text((12, y0), 'The 144 bytes as stored: 4 rows (stride 36) of 4 cells, each the attribute then 8 pixel lines; '
                     'bit 7 of the attribute = solid', fill=K.TEXT, font=f)
    for r in range(4):
        y = y0 + 24 + r * 22
        d.text((12, y), f'+{r * 36:3d}', fill=K.DIM, font=small)
        for c in range(4):
            cell = t[r * 36 + c * 9: r * 36 + c * 9 + 9]
            x = 64 + c * 245
            d.text((x, y), f'{cell[0]:02X}', fill=(255, 120, 120) if cell[0] & 0x80 else (240, 200, 70), font=small)
            d.text((x + 24, y), ' '.join(f'{b:02X}' for b in cell[1:]), fill=K.TEXT, font=small)
    # the cut of one column into ColumnBuffer
    y0 = 476
    d.text((12, y0), 'Step 2-6 of the scroll: one map byte, one metatile, its column MetaColumn (0-3) cut into '
                     'ColumnBuffer $5E00', fill=K.TEXT, font=f)
    d.text((12, y0 + 18), 'as 4 cells of 9 bytes: 8 pixel lines, then the attribute. Five map bytes fill the 20 cells; '
                          'step 0 copies them to column 31.', fill=K.DIM, font=small)
    for mc in range(4):
        x0, yy = 12 + mc * 258, y0 + 48
        d.text((x0, yy), f'MetaColumn {mc}: ColumnBuffer cells', fill=K.TEXT, font=small)
        for r in range(4):
            cell = t[r * 36 + mc * 9: r * 36 + mc * 9 + 9]
            img = Image.new('RGB', (8, 8))
            draw_cell(img.load(), 0, 0, list(cell[1:]), cell[0])
            y = yy + 20 + r * 52
            pic.paste(img.resize((48, 48), Image.NEAREST), (x0, y))
            d.text((x0 + 56, y + 2), ' '.join(f'{b:02X}' for b in cell[1:5]), fill=K.TEXT, font=small)
            d.text((x0 + 56, y + 18), ' '.join(f'{b:02X}' for b in cell[5:9]) + f'  {cell[0]:02X}', fill=K.TEXT,
                   font=small)
    pic.save(args.out)
    print(args.out, pic.size)


# ---------------------------------------------------------------------------------------------------------------
# objects

NAMES = {2: 'ship, nose down', 3: 'ship, level', 4: 'ship, nose up', 0x16: 'beam, small', 0x17: 'beam, middle',
         0x18: 'beam, full', 0x62: 'shield', 0x63: 'beam glow'}


def cmd_objects(args):
    mem = game_image()
    table = 0xBC67
    ents = []
    for n in range(1, 112):
        e = table + (n - 1) * 4
        w, h, p = mem[e], mem[e + 1], mem[e + 2] | mem[e + 3] << 8
        if not (w and h):
            continue
        img = Image.new('RGB', (w * 8, h * 8), (70, 70, 80))
        px = img.load()
        a = p
        for i in range(w * h):
            if mem[a] == 0x36:
                a += 1
                continue
            draw_cell(px, (i % w) * 8, (i // w) * 8, list(mem[a + 1:a + 9]), mem[a])
            a += 9
        ents.append((n, w, h, p, img))
    s = 2
    f = K.font(11)
    x = y = 0
    rowh = 0
    place = []
    for n, w, h, p, img in ents:
        bw, bh = max(img.width * s, 52) + 8, img.height * s + 18
        if x + bw > WIDTH - 24:
            x, y, rowh = 0, y + rowh, 0
        place.append((x, y, n, img))
        x += bw
        rowh = max(rowh, bh)
    pic = Image.new('RGB', (WIDTH, y + rowh + 60), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    d.text((12, 10), f'The game\'s objects: GameObjects $BC67 ({len(ents)} of 111 entries drawn, number in hex, x{s}; '
                     'grey = an empty cell $36)', fill=K.TEXT, font=K.font(14))
    for x, y, n, img in place:
        pic.paste(img.resize((img.width * s, img.height * s), Image.NEAREST), (12 + x, 40 + y))
        d.text((12 + x, 40 + y + img.height * s + 1), f'{n:02X}', fill=K.TEXT if n in NAMES else K.DIM, font=f)
    pic.save(args.out)
    print(args.out, pic.size, len(ents))


# ---------------------------------------------------------------------------------------------------------------
# frame and scrollzoom: a recording

class Live:
    def __init__(self, work):
        sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import re_session  # noqa: E402
        self.session, _ = re_session.session_of(work)

    def mem(self, frame, address, length):
        r = self.session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame),
                                              'tinframe': 0, 'offset': address, 'length': length}, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data:
            raise SystemExit(f'memory_at {frame} ${address:04X}: {r.text}')
        return bytes.fromhex(data)


def tag_colour(t):
    if t == 0:
        return None
    if t >= 0xDC:
        return (70, 210, 220)
    if t == 0xFA:
        return (240, 200, 70)
    return (230, 90, 80)


def raw_pixels(mem, base=0x4000, rows=24):
    img = Image.new('RGB', (256, rows * 8))
    px = img.load()
    for y in range(rows * 8):
        a = K.screen_address(y, 0) - 0x4000 + base
        for c in range(32):
            b = mem[a + c]
            for x in range(8):
                px[c * 8 + x, y] = (230, 230, 230) if b & (0x80 >> x) else (0, 0, 0)
    return img


def cmd_frame(args):
    live = Live(args.work)
    f = args.frame
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = live.mem(f, 0x4000, 6912)
    mem[0x6000:0x7800] = live.mem(f, 0x6000, 6144)
    mem[0x7800:0x7A80] = live.mem(f, 0x7800, 640)
    mem[0x7E00:0x8080] = live.mem(f, 0x7E00, 640)
    mem[0x8100:0x8380] = live.mem(f, 0x8100, 640)
    var = live.mem(f, 0x7A80, 16)
    s = 2
    pw, ph = 256 * s, 160 * s
    pic = Image.new("RGB", (WIDTH, 2 * ph + 220), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    big, f13, small = K.font(16), K.font(13), K.font(12)
    d.text((12, 8), args.title or f'One frame against its buffers: {args.label} frame {f}, memory at T 0',
           fill=K.TEXT, font=big)
    d.text((12, 30), f'ScrollStep {var[2]}, MetaColumn {var[3]}, MapColumn {var[4]}, FrameCounter ${var[9]:02X}',
           fill=K.DIM, font=small)
    # a: the screen
    scr = K.render_screen(mem).crop((0, 0, 256, 160)).resize((pw, ph), Image.NEAREST)
    x1, y1 = 12, 70
    pic.paste(scr, (x1, y1))
    d.text((x1, y1 - 18), 'a. the screen (rows 0-19)', fill=K.TEXT, font=f13)
    # b: raw pixels and SolidMap tags
    raw = raw_pixels(mem, rows=20).resize((pw, ph), Image.NEAREST).convert('RGBA')
    over = Image.new('RGBA', raw.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(over)
    counts = {}
    for r in range(20):
        for c in range(32):
            t = mem[0x7E00 + r * 32 + c]
            col = tag_colour(t)
            if col:
                counts[t >= 0xDC and 'scenery' or (t == 0xFA and 'soft' or 'sprite')] = counts.get(
                    t >= 0xDC and 'scenery' or (t == 0xFA and 'soft' or 'sprite'), 0) + 1
                od.rectangle([c * 8 * s, r * 8 * s, c * 8 * s + 8 * s - 1, r * 8 * s + 8 * s - 1],
                             fill=col + (95,), outline=col + (255,))
            if mem[0x8100 + r * 32 + c] == 1:
                od.rectangle([c * 8 * s + 4, r * 8 * s + 4, c * 8 * s + 8 * s - 5, r * 8 * s + 8 * s - 5],
                             outline=(150, 220, 90, 255), width=2)
    raw = Image.alpha_composite(raw, over).convert('RGB')
    x2 = 12 + pw + 2 + 0
    x2 = WIDTH - pw - 12
    pic.paste(raw, (x2, y1))
    d.text((x2, y1 - 18), 'b. pixels without attributes; SolidMap tags; DrawnMap', fill=K.TEXT, font=f13)
    # c: the pixel shadow with PlayAttrs
    shadow = bytearray(0x10000)
    shadow[0x4000:0x5800] = mem[0x6000:0x7800]
    shadow[0x5800:0x5A80] = mem[0x7800:0x7A80]
    sh = K.render_screen(shadow).crop((0, 0, 256, 160)).resize((pw, ph), Image.NEAREST)
    y3 = y1 + ph + 40
    pic.paste(sh, (x1, y3))
    d.text((x1, y3 - 18), 'c. the pixel shadow $6000 with PlayAttrs $7800', fill=K.TEXT, font=f13)
    # d: the tags as numbers
    tg = Image.new('RGB', (pw, ph), K.PANEL)
    td = ImageDraw.Draw(tg)
    tf = K.font(10)
    for r in range(20):
        for c in range(32):
            t = mem[0x7E00 + r * 32 + c]
            col = tag_colour(t)
            if col:
                td.rectangle([c * 16, r * 16, c * 16 + 15, r * 16 + 15], fill=tuple(v // 2 for v in col))
                td.text((c * 16 + 1, r * 16 + 2), f'{t:02X}', fill=(255, 255, 255), font=tf)
    pic.paste(tg, (x2, y3))
    d.text((x2, y3 - 18), 'd. SolidMap $7E00, the tag of each cell (hex)', fill=K.TEXT, font=f13)
    ly = y3 + ph + 12
    legend = [((70, 210, 220), 'scenery: tag $DC or more (shifted on the screen)'),
              ((230, 90, 80), 'a sprite: tag below $DC (copied from the shadow)'),
              ((240, 200, 70), 'soft cell $FA'), ((150, 220, 90), 'DrawnMap = 1 (inner square)')]
    for i, (c, text) in enumerate(legend):
        x = 12 + (i % 2) * 520
        y = ly + (i // 2) * 20
        d.rectangle([x, y + 2, x + 14, y + 14], fill=c)
        d.text((x + 22, y), text, fill=K.TEXT, font=small)
    pic = pic.crop((0, 0, WIDTH, ly + 46))
    pic.save(args.out)
    print(args.out, pic.size, counts)


def cmd_scrollzoom(args):
    live = Live(args.work)
    cols = args.columns
    c0 = 32 - cols
    s = args.scale
    pictures, durations = [], []
    prev = None
    for f in range(args.start, args.end + 1):
        var = live.mem(f, 0x7A80, 16)
        key = (var[2], var[9])
        if prev == key:
            continue
        prev = key
        scr = live.mem(f, 0x4000, 6912)
        solid = live.mem(f, 0x7E00, 640)
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = scr
        shown = K.render_screen(mem).crop((c0 * 8, 0, 256, 160)).resize((cols * 8 * s, 160 * s), Image.NEAREST)
        raw = raw_pixels(mem, rows=20).crop((c0 * 8, 0, 256, 160)).resize((cols * 8 * s, 160 * s), Image.NEAREST)
        rd = ImageDraw.Draw(raw)
        for r in range(20):
            for c in range(c0, 32):
                t = solid[r * 32 + c]
                col = tag_colour(t)
                if col:
                    x, y = (c - c0) * 8 * s, r * 8 * s
                    rd.rectangle([x, y, x + 8 * s - 1, y + 8 * s - 1], outline=col, width=2)
        pw = cols * 8 * s
        pic = Image.new('RGB', (WIDTH, 160 * s + 110), K.BACKGROUND)
        d = ImageDraw.Draw(pic)
        d.text((12, 8), args.title, fill=K.TEXT, font=K.font(15))
        pic.paste(shown, (12, 64))
        pic.paste(raw, (12 + pw + 30, 64))
        d.text((12, 44), f'the screen, columns {c0}-31', fill=K.TEXT, font=K.font(13))
        d.text((12 + pw + 30, 44), 'the pixels without attributes; outlines: SolidMap tags', fill=K.TEXT,
               font=K.font(13))
        x3 = 12 + 2 * pw + 60
        lines = [f'frame {f}', '', f'ScrollStep  {var[2]}', f'MetaColumn  {var[3]}', f'MapColumn   {var[4]}',
                 f'FrameCounter ${var[9]:02X}', '', 'step 0: ColumnBuffer to', '  column 31',
                 'step 7: PlayAttrs and', '  SolidMap one cell left', 'every pass: the scenery', '  1 pixel left']
        for i, line in enumerate(lines):
            d.text((x3, 64 + i * 20), line, fill=K.TEXT if i < 6 else K.DIM, font=K.font(13))
        for c in range(c0, 32):
            d.text((12 + (c - c0) * 8 * s + 4, 64 + 160 * s + 4), str(c), fill=K.DIM, font=K.font(11))
            d.text((12 + pw + 30 + (c - c0) * 8 * s + 4, 64 + 160 * s + 4), str(c), fill=K.DIM, font=K.font(11))
        d.text((12, 64 + 160 * s + 26), args.note, fill=K.DIM, font=K.font(12))
        pictures.append(pic)
        durations.append(args.delay)
    durations[-1] = args.hold
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), pictures[0].size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('memory')
    s.add_argument('--out', required=True)
    s = sub.add_parser('metatile')
    s.add_argument('--level', type=int, default=1)
    s.add_argument('--tile', type=int, default=9)
    s.add_argument('--out', required=True)
    s = sub.add_parser('objects')
    s.add_argument('--out', required=True)
    s = sub.add_parser('frame')
    s.add_argument('--work', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--label', default='')
    s.add_argument('--title', default='')
    s.add_argument('--out', required=True)
    s = sub.add_parser('scrollzoom')
    s.add_argument('--work', required=True)
    s.add_argument('--from', dest='start', type=int, required=True)
    s.add_argument('--to', dest='end', type=int, required=True)
    s.add_argument('--columns', type=int, default=8)
    s.add_argument('--scale', type=int, default=2)
    s.add_argument('--title', default='')
    s.add_argument('--note', default='')
    s.add_argument('--delay', type=int, default=200)
    s.add_argument('--hold', type=int, default=1500)
    s.add_argument('--out', required=True)
    a = p.parse_args()
    {'memory': cmd_memory, 'metatile': cmd_metatile, 'objects': cmd_objects, 'frame': cmd_frame,
     'scrollzoom': cmd_scrollzoom}[a.cmd](a)


if __name__ == '__main__':
    main()

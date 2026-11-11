#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from src/res, the loaded image and the recordings' memory.

    python3 tools/fig_render.py layout --screen work/docs/esB/c1-14300.scr --out docs/img/render/layout.png
    python3 tools/fig_render.py format --out docs/img/render/cell-format.png
    python3 tools/fig_render.py sheet --out docs/img/render/sheet.png
    python3 tools/fig_render.py cavegfx --out docs/img/render/cave-graphics.png
    python3 tools/fig_render.py window --out docs/img/render/window-over-cave.png
    python3 tools/fig_render.py map --out docs/img/render/map-glyphs.png

layout: a screen of c1 (frame 14300, memory_at, work/docs/esB/dump.py) with the window's 16 x 11 cells, the time bar
and the panel line marked. format: the 36-byte cell graphic of GfxBoulder `$9B2C` byte by byte. sheet: every cell
graphic of the image (src/res/graphics put back by tools/fig_caves.py) with its label, address and frames. cavegfx:
each cave's exit, boulder, wall and earth as CaveSetup `$9313` leaves them (src/res/caves/caves.txt). window: cave
1 with the zone where WindowOrigin `$8DA6` follows the player and three windows. map: the map screen's 16 glyphs
MapGlyphs `$9A00` with MapAttrs `$9A80` and the frame glyphs MapFrameGlyphs `$E9C0`.
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
import fig_caves as FC  # noqa: E402
import res_formats  # noqa: E402

FG, DIM, BG, PANEL = K.TEXT, K.DIM, K.BACKGROUND, K.PANEL
W = 1050
RED, BLUE, YEL, GRN, ORA, CYA, MAG = (230, 90, 80), (90, 150, 250), (240, 200, 70), (90, 200, 120), (250, 150, 60), \
    (70, 210, 220), (200, 110, 230)


def notes(d, y, lines, n_fg, f=None):
    f = f or K.font(13)
    for i, line in enumerate(lines):
        d.text((18, y + i * 21), line, font=f, fill=FG if i < n_fg else DIM)
    return y + len(lines) * 21


def screen_image(data):
    return K.render_screen(bytes(0x4000) + data, 0x4000) if len(data) == 6912 else None


def fig_layout(scr, out):
    data = open(scr, 'rb').read()
    img = K.render_screen(data, 0) if False else None
    mem = bytearray(0x4000) + bytearray(data)
    img = K.render_screen(mem, 0x4000)
    s = 3
    big = img.resize((256 * s, 192 * s), Image.NEAREST)
    h = 192 * s + 40 + 160
    im = Image.new('RGB', (W, h), BG)
    im.paste(big, (14, 40))
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    d.text((14, 10), 'The screen in play: a 16 x 11 window of 16 x 16 cells, the time bar, the panel (c1 frame 14300)',
           font=ft, fill=FG)
    x0, y0 = 14, 40
    for c in range(17):
        d.line((x0 + c * 16 * s, y0, x0 + c * 16 * s, y0 + 176 * s), fill=(255, 255, 255), width=1)
    for r in range(12):
        d.line((x0, y0 + r * 16 * s, x0 + 256 * s, y0 + r * 16 * s), fill=(255, 255, 255), width=1)
    for c in range(16):
        d.text((x0 + c * 16 * s + 3, y0 + 2), str(c), font=fs, fill=(255, 255, 255))
    for r in range(11):
        d.text((x0 + 3, y0 + r * 16 * s + 16), str(r), font=fs, fill=(255, 255, 255))
    # the player's cell (window column 8, row 5)
    px, py = x0 + 8 * 16 * s, y0 + 5 * 16 * s
    d.rectangle((px, py, px + 16 * s, py + 16 * s), outline=RED, width=3)
    d.rectangle((x0, y0 + 176 * s, x0 + 256 * s, y0 + 184 * s), outline=YEL, width=2)
    d.rectangle((x0, y0 + 184 * s, x0 + 256 * s, y0 + 192 * s), outline=CYA, width=2)
    tx = x0 + 256 * s + 14
    side = [
        (FG, 'the window'), (DIM, 'character rows 0-21,'), (DIM, '16 x 11 cells of'), (DIM, '2 x 2 characters;'),
        (DIM, 'DrawWindow $8D78'), (DIM, 'redraws all 176'), (DIM, 'each pass'), (FG, ''),
        (RED, 'the player'), (DIM, 'cell 284 = row 9,'), (DIM, 'column 14 of the'), (DIM, 'cave; ViewOrigin'),
        (DIM, '$FD70 = 126 ='), (DIM, 'row 4, column 6:'), (DIM, 'window column 8,'), (DIM, 'row 5'), (FG, ''),
        (YEL, 'row 22: time bar'), (DIM, '4 pixel lines at'), (DIM, '$52C0 (doc 08)'), (FG, ''),
        (CYA, 'row 23: panel'), (DIM, 'cave, gems, lives,'), (DIM, 'score (doc 08)'),
    ]
    for i, (c, t) in enumerate(side):
        d.text((tx, y0 + i * 21), t, font=f, fill=c)
    y = y0 + 192 * s + 14
    notes(d, y, [
        'How to read: the screen of c1 at the start of frame 14300 (memory_at), x3; the white grid is the 16 x 11 cells,',
        'numbered by window column and row; the red box the player; yellow the time bar, cyan the panel line.',
        'The point: the play area is the whole top 22 character rows; every cell owns its 2 x 2 attributes, so a cell',
        'never clashes with its neighbour: the graphics carry their colours, and the screen is attribute-exact by design.',
        'Rows 22 and 23 belong to the HUD; the window code never touches them.',
        'python3 tools/fig_render.py layout --screen work/docs/esB/c1-14300.scr (work/docs/esB/dump.py c1 4000 6912 14300)',
    ], 5)
    im.save(out)


def fig_format(out):
    m = FC.resource_memory()
    a = 0x9B2C  # GfxBoulder, cave 1 colours
    m = FC.cave_setup(m, res_formats.read_caves()[0][0])
    g = m[a:a + 36]
    s = 20
    h = 16 * s + 60 + 200
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs, fb = K.font(17), K.font(13), K.font(12), K.font(14)
    d.text((14, 10), 'A cell graphic: 36 bytes, 4 attributes then 32 pixel bytes in zigzag order (GfxBoulder $9B2C)',
           font=ft, fill=FG)
    x0, y0 = 20, 50
    tile, _ = FC.graphic(m, 2)
    im.paste(tile.resize((16 * s, 16 * s), Image.NEAREST), (x0, y0))
    for line in range(16):
        for half in range(2):
            idx = 4 + 2 * line + (half if line % 2 == 0 else 1 - half)
            order = 2 * line + (half if line % 2 == 0 else 1 - half)
            x, y = x0 + half * 8 * s, y0 + line * s
            d.rectangle((x, y, x + 8 * s - 1, y + s - 1), outline=(60, 60, 70))
            d.rectangle((x + 8 * s - 30, y + 2, x + 8 * s - 4, y + s - 3), fill=(14, 14, 20))
            d.text((x + 8 * s - 28, y + 3), f'{order:2d}', font=fs, fill=(255, 255, 255))
    # arrows of the zigzag on the right
    ax = x0 + 16 * s + 16
    for line in range(16):
        y = y0 + line * s + s // 2
        if line % 2 == 0:
            d.line((ax, y, ax + 50, y), fill=GRN, width=2); d.polygon([(ax + 50, y - 4), (ax + 58, y), (ax + 50, y + 4)], fill=GRN)
        else:
            d.line((ax + 8, y, ax + 58, y), fill=ORA, width=2); d.polygon([(ax + 8, y - 4), (ax, y), (ax + 8, y + 4)], fill=ORA)
        if line in (0, 7, 8, 15):
            d.text((ax + 66, y - 8), {0: 'line 0: left, right', 7: 'line 7: right, left', 8: 'SUB 7, SET 5,E: next',
                                       15: 'line 15'}[line], font=fs, fill=DIM)
    # attribute boxes
    bx = ax + 230
    d.text((bx, y0), 'bytes 0-3: the attributes', font=fb, fill=FG)
    pos = [(0, 0, 'TL'), (1, 0, 'TR'), (1, 1, 'BR'), (0, 1, 'BL')]
    for i, (cx, cy, nm) in enumerate(pos):
        x, y = bx + cx * 90, y0 + 28 + cy * 60
        at = g[i]
        pal = FC.BRIGHT if at & 64 else FC.PAL
        d.rectangle((x, y, x + 86, y + 56), fill=pal[at >> 3 & 7], outline=pal[at & 7], width=4)
        d.text((x + 6, y + 6), f'{i}: {nm}', font=f, fill=(255, 255, 255))
        d.text((x + 6, y + 28), f'${at:02X}', font=f, fill=(255, 255, 255))
    d.text((bx, y0 + 156), 'DrawCell $8F60 writes them at', font=f, fill=DIM)
    d.text((bx, y0 + 176), 'E, E+1, E+33, E+32 of $5800+', font=f, fill=DIM)
    d.text((bx, y0 + 196), '(INC E, SET 5,E, DEC E)', font=f, fill=DIM)
    # bytes in hex
    hy = y0 + 236
    d.text((bx, hy), 'the 36 bytes at $9B2C (cave 1):', font=fb, fill=FG)
    for i, v in enumerate(g):
        x, y = bx + (i % 12) * 38, hy + 26 + (i // 12) * 24
        d.rectangle((x, y, x + 34, y + 20), fill=YEL if i < 4 else PANEL)
        d.text((x + 6, y + 3), f'{v:02X}', font=f, fill=(10, 10, 14) if i < 4 else FG)
    y = y0 + 16 * s + 16
    notes(d, y, [
        'How to read: the boulder at 20 x; each 8-pixel run is one byte, its number the order in the 32 pixel bytes (byte',
        '4 + n of the graphic). Even lines are stored left then right (green), odd lines right then left (orange): DrawCell',
        'steps the screen address with INC E / DEC E and INC D only, never reloading it. Bytes 0-3 are the attributes in the',
        'order top left, top right, bottom right, bottom left, again the order one INC E, SET 5,E, DEC E walk visits them.',
        'The point: the storage order is the drawing order, so DrawCell is a straight run of LD A,(HL); LD (DE),A pairs with',
        'one register step between them: about 1 300 T a cell with the loop around it, no inner loop, no address table.',
        'Cave 1 colours (CaveSetup $9313: $46 bright on the left half, plain on the right: the boulder\'s shading).',
        'python3 tools/fig_render.py format (the image work/mkgame/original.bin with src/res/graphics put back)',
    ], 7)
    im.save(out)


SHEET = [  # label, address, frames, who points the table at it
    ('BlankGraphic', 0xAA72, 1, 'word 0: empty'), ('CellGraphics (exit)', 0x9B08, 1, 'word 1: exit'),
    ('GfxBoulder', 0x9B2C, 1, 'word 2'), ('GfxEarth', 0x9B50, 1, 'word 6 (24 caves)'),
    ('GfxGem', 0x9B74, 1, 'word 7; DrawPass ink'),
    ('GfxPlayerRight', 0x9B98, 4, 'word 3, AnimateCells'), ('GfxPlayerLeft', 0x9C28, 4, 'word 4, AnimateCells'),
    ('GfxWall1', 0x9CB8, 1, 'word 5'), ('GfxWall2', 0x9CDC, 1, 'word 5'), ('GfxWall3', 0x9D00, 1, 'word 5'),
    ('GfxWall4', 0x9D24, 1, 'word 5'), ('GfxWall5', 0x9D48, 1, 'word 5'), ('GfxWall6', 0x9D6C, 1, 'word 5'),
    ('GfxSpare', 0x9D90, 1, 'never read'), ('GfxDeathRight', 0x9DB4, 1, 'word 3, DeathView'),
    ('GfxDeathLeft', 0x9DD8, 1, 'word 4, DeathView'),
    ('CellGraphics2 (potion)', 0x9E20, 4, 'word 12'), ('GfxSwitch', 0x9EB0, 1, 'word 11'),
    ('GfxFire', 0x9ED4, 4, 'word 15'), ('GfxTeleporter', 0x9F64, 12, 'word 13, 12 phases'),
    ('GfxBubble', 0xA114, 4, 'word 14'), ('GfxDissolve', 0xA1A4, 7, 'words 21-27'),
    ('GfxForceField', 0xA2A0, 8, 'word 9, 8 phases'), ('GfxAntiGrav', 0xA3C0, 4, 'word 10'),
    ('GfxFallingEarth', 0xA450, 4, 'word 6 (5 caves)'), ('GfxJellyBean', 0xA4E0, 4, 'word 8'),
    ('GfxBurst', 0xA570, 4, 'words 16-20'),
    ('ExtraGraphics', 0xED28, 1, 'word 5 or 6'), ('GfxExtraWall2', 0xED4C, 1, 'word 5'),
    ('GfxExtraWall3', 0xED70, 1, 'word 5'), ('GfxExtraWall4', 0xED94, 1, 'word 5'),
    ('GfxExtraWall5', 0xEDB8, 1, 'word 5'), ('ExtraGraphic2', 0xEE00, 1, 'word 5'),
    ('ExtraGraphic3', 0xEF00, 1, 'word 5'), ('ExtraGraphic4', 0xFBA0, 1, 'word 6 (cave 15)'),
    ('GfxExtraWall9', 0xFBC4, 1, 'word 5'),
]


def tile_at(m, a):
    m = bytearray(m)
    m[0x8000:0x8002] = a.to_bytes(2, 'little')
    return FC.graphic(m, 0)[0]


def fig_sheet(out):
    m = FC.cave_setup(FC.resource_memory(), res_formats.read_caves()[0][0])
    s = 3
    tw = 16 * s
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    # layout: rows of entries, each entry = label line + its frames
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    placed, x, y, rowh = [], 14, 46, 0
    for name, a, n, who in SHEET:
        wdt = int(max(n * (tw + 4) - 4, probe.textlength(name, font=f), probe.textlength(who, font=fs),
                  probe.textlength(f'${a:04X} x{n}', font=fs)))
        if x + wdt > W - 14:
            x, y = 14, y + rowh
            rowh = 0
        placed.append((name, a, n, who, x, y))
        x += wdt + 18
        rowh = max(rowh, tw + 70)
    h = y + rowh + 180
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 12), 'Every cell graphic: label, address, frames of 36 bytes, the table word that shows it', font=ft,
           fill=FG)
    for name, a, n, who, x, y in placed:
        for k in range(n):
            t = tile_at(m, a + 36 * k)
            im.paste(t.resize((tw, tw), Image.NEAREST), (x + k * (tw + 4), y + 52))
        d.text((x, y), f'{name}', font=f, fill=FG)
        d.text((x, y + 17), f'${a:04X} x{n}', font=fs, fill=DIM)
        d.text((x, y + 33), who, font=fs, fill=DIM)
    notes(d, h - 170, [
        'How to read: each tile at 3 x, drawn by the DrawCell order from the bytes at its address; a row of tiles is the',
        'frames of one animation, 36 bytes apart, stepped by AnimateCells $900B / AnimateTable $90B2 through AnimPhase $FD72',
        '(4 phases), ForceFieldPhase (8) and TeleporterPhase (12). Colours as loaded with cave 1\'s CaveSetup; the exit,',
        'boulder, GfxWall1 and earth take each cave\'s colours (figure cave-graphics.png), the gem the cycling ink.',
        'The point: 77 graphics of 36 bytes in two blocks ($9B08-$A5FF, cells-a and cells-b) and nine extras the caves',
        'pick by parameter; there are no sprites: the player, the hazards and every effect are cells of the grid.',
        'python3 tools/fig_render.py sheet (src/res/graphics/*.png put back into work/mkgame/original.bin, fig_caves.py)',
    ], 6)
    im.save(out)


def fig_cavegfx(out):
    base = FC.resource_memory()
    caves = res_formats.read_caves()
    names = [ln for ln in open(os.path.join(res_formats.RES, 'texts', 'cave-names.txt'), encoding='utf-8')
             if ln.startswith('"')]
    names = [res_formats.unquote(ln.strip()).decode('latin-1').strip() for ln in names]
    s = 2
    tw = 16 * s
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    cw, ch = 258, 74
    h = 46 + 8 * ch + 190
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 12), 'What CaveSetup changes per cave: the exit, boulder, wall and earth (cells 1, 2, 5, 6) of caves 1-32',
           font=ft, fill=FG)
    for n, (p, cells) in enumerate(caves, 1):
        m = FC.cave_setup(base, p)
        x, y = 14 + (n - 1) % 4 * cw, 46 + (n - 1) // 4 * ch
        d.text((x, y), f'{n:02d} {names[n - 1][:22]}', font=fs, fill=FG)
        for k, v in enumerate((1, 2, 5, 6)):
            t, _ = FC.graphic(m, v)
            im.paste(t.resize((tw, tw), Image.NEAREST), (x + k * (tw + 4), y + 18))
        wn = [nm for nm, a, _, _ in SHEET if a == p['wall_graphic']]
        en = [nm for nm, a, _, _ in SHEET if a == p['earth_graphic']]
        d.text((x + 4 * (tw + 4) + 4, y + 18), (wn[0] if wn else '?').replace('Gfx', ''), font=fs, fill=DIM)
        d.text((x + 4 * (tw + 4) + 4, y + 34), (en[0] if en else '?').replace('Gfx', ''), font=fs, fill=DIM)
    notes(d, 46 + 8 * ch + 8, [
        'How to read: per cave, its name, then the exit, boulder, wall and earth cells as drawn after CaveSetup $9313, and',
        'the names of its wall and earth graphics (wall_graphic, earth_graphic of src/res/caves/caves.txt). The exit,',
        'boulder, GfxWall1 and GfxEarth take the cave\'s four colour parameters (attributes bright, plain, plain, bright).',
        'The point: two table words and four colours make 32 caves look different with one set of graphics; a wall',
        'graphic other than GfxWall1 keeps its own colours, which is why wall1_colour shows only where GfxWall1 is used.',
        'python3 tools/fig_render.py cavegfx (src/res/caves/caves.txt, src/res/graphics, fig_caves.cave_setup)',
    ], 5)
    im.save(out)


def fig_window(out):
    base = FC.resource_memory()
    p, cells = res_formats.read_caves()[0]
    cave = FC.draw_cave(FC.cave_setup(base, p), cells)
    s = 2
    big = cave.resize((480 * s, 320 * s), Image.NEAREST).convert('RGB')
    # dim the cave so the marks read
    big = Image.blend(big, Image.new('RGB', big.size, (0, 0, 0)), 0.45)
    h = 320 * s + 50 + 230
    im = Image.new('RGB', (W, h), BG)
    im.paste(big, (14, 46))
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    d.text((14, 12), 'WindowOrigin over cave 1: where the window follows the player, and three windows', font=ft,
           fill=FG)
    x0, y0, c = 14, 46, 16 * s
    # the centre zone: player columns 8-22, rows 5-14
    d.rectangle((x0 + 8 * c, y0 + 5 * c, x0 + 23 * c, y0 + 15 * c), outline=YEL, width=3)
    d.text((x0 + 8 * c + 4, y0 + 5 * c + 4), 'player in columns 8-22, rows 5-14: the window moves with him', font=f,
           fill=YEL)
    wins = [(285, GRN, 'start, cell 285'), (434, ORA, 'cell 434 (c1 14340)'), (17, CYA, 'cell 17: clamped')]
    for i, (cell, col, lab) in enumerate(wins):
        r, q = divmod(cell, 30)
        q2, r2 = min(max(q, 8), 22), min(max(r, 5), 14)
        oq, orr = q2 - 8, r2 - 5
        d.rectangle((x0 + oq * c + 2 * i, y0 + orr * c + 2 * i, x0 + (oq + 16) * c - 2 * i, y0 + (orr + 11) * c - 2 * i),
                    outline=col, width=3)
        d.rectangle((x0 + q * c, y0 + r * c, x0 + (q + 1) * c, y0 + (r + 1) * c), fill=col)
        d.text((x0 + oq * c + 6 + 2 * i, y0 + (orr + 11) * c - 22 - 2 * i), lab + f': origin {30 * orr + oq}', font=f,
               fill=col)
    for q in range(0, 30, 5):
        d.text((x0 + q * c + 2, y0 + 320 * s + 2), str(q), font=fs, fill=DIM)
    for r in range(0, 20, 5):
        d.text((x0 + 480 * s + 4, y0 + r * c + 2), str(r), font=fs, fill=DIM)
    notes(d, y0 + 320 * s + 22, [
        'How to read: cave 1 from src/res, dimmed; the yellow box the player places where the window is centred on him',
        '(window column 8, row 5); each coloured frame a 16 x 11 window with the player\'s cell filled; the numbers on',
        'the edges the cave\'s columns and rows. Outside the yellow box the window stops at the cave\'s edge and the player',
        'walks off centre (cyan).',
        'The point: the window moves a whole cell at a time, in the same pass as the player, so the scroll is a jump of',
        '16 pixels each pass; 15 x 10 = 150 origins cover the 30 x 20 cave.',
        'python3 tools/fig_render.py window (src/res/caves/caves.txt; WindowOrigin $8DA6 clamps as in the listing)',
    ], 6)
    im.save(out)


def fig_map(out):
    m = FC.resource_memory()
    ft, f, fs = K.font(17), K.font(13), K.font(12)
    s = 6
    h = 46 + 2 * (8 * s + 56) + 120 + 190
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 12), 'The map screen\'s glyphs: MapGlyphs $9A00 coloured by MapAttrs $9A80, and the frame glyphs',
           font=ft, fill=FG)
    names = ['empty', 'exit', 'boulder', 'player R', 'player L', 'wall', 'earth', 'gem', 'jelly', 'f. field',
             'arrow', 'switch', 'potion', 'teleport', 'bubble', 'fire']
    for v in range(16):
        g = m[0x9A00 + 8 * v:0x9A08 + 8 * v]
        at = m[0x9A80 + v]
        pal = FC.BRIGHT if at & 64 else FC.PAL
        x, y = 14 + (v % 8) * 128, 46 + (v // 8) * (8 * s + 56)
        for yy in range(8):
            for xx in range(8):
                on = g[yy] >> (7 - xx) & 1
                d.rectangle((x + xx * s, y + yy * s, x + xx * s + s - 1, y + yy * s + s - 1),
                            fill=pal[at & 7] if on else pal[at >> 3 & 7])
        d.text((x, y + 8 * s + 4), f'{v:X} {names[v]}', font=f, fill=FG)
        d.text((x, y + 8 * s + 22), f'attr ${at:02X}', font=fs, fill=DIM)
    y = 46 + 2 * (8 * s + 56) + 6
    d.text((14, y), 'MapFrameGlyphs $E9C0 (8 glyphs: corners and edges), attribute $43:', font=f, fill=FG)
    for k in range(8):
        g = m[0xE9C0 + 8 * k:0xE9C8 + 8 * k]
        x = 14 + k * 70
        for yy in range(8):
            for xx in range(8):
                on = g[yy] >> (7 - xx) & 1
                d.rectangle((x + xx * 6, y + 24 + yy * 6, x + xx * 6 + 5, y + 24 + yy * 6 + 5),
                            fill=FC.BRIGHT[3] if on else (0, 0, 0))
        d.text((x, y + 76), f'+{8 * k}', font=fs, fill=DIM)
    notes(d, h - 190, [
        'How to read: each cell code 0-15 as its 8 x 8 map glyph at 6 x, in the colour MapAttrs gives it (ink and paper);',
        'below, the frame\'s eight glyphs as DrawMapFrame $EA00 picks them by offset (+0 top left, +8 top, +16 top right,',
        '+24 left, +32 right, +40 bottom left, +48 bottom, +56 bottom right).',
        'The point: one character a cell makes the 30 x 20 cave fit in 30 x 20 characters, inside a frame of 32 x 22;',
        'codes from $10 (the burst and dissolve steps, the vacated mark) get attribute 0 (MapCellAttr $EAB3): black on',
        'black, so whatever pixels were under them vanish.',
        'python3 tools/fig_render.py map (work/mkgame/original.bin with src/res/graphics put back)',
    ], 6)
    im.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=['layout', 'format', 'sheet', 'cavegfx', 'window', 'map'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--screen')
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    {'layout': lambda: fig_layout(a.screen, a.out), 'format': lambda: fig_format(a.out),
     'sheet': lambda: fig_sheet(a.out), 'cavegfx': lambda: fig_cavegfx(a.out), 'window': lambda: fig_window(a.out),
     'map': lambda: fig_map(a.out)}[a.what]()
    print(a.out)


if __name__ == '__main__':
    main()

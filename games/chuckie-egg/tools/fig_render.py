#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from the image and from recordings (TTD memory_at, access traces).

    python3 tools/fig_render.py charset --out docs/img/render/charset.png
    python3 tools/fig_render.py sprites --out docs/img/render/sprites.png
    python3 tools/fig_render.py layout --work W --frame 2400 --out docs/img/render/layout.png
    python3 tools/fig_render.py maprow --work W --frame 300 --row 1 --out docs/img/render/maprow.png
    python3 tools/fig_render.py drawsprite --trace TR --at 606:31168 --out docs/img/render/drawsprite.png
    python3 tools/fig_render.py flicker --trace TR --out docs/img/render/flicker.png [--json OUT.json]

W is a work folder whose instance holds the recording (re_session.py session.json); `layout` and `maprow` read
levels-1-3 (work/stage1/rec/levels-1-3/session.ttd). TR is an access trace of levels-1-3 (`analysis trace`, kept in
W/traces/): `drawsprite` uses frames 600-612, `flicker` frames 600-900. The image is build/game.bin
(`sh tools/build.sh`), the game block `$8214-$CBE7`. A memory sample of frame N is the memory at the start of frame
N (TTD memory_at, tinframe 0) unless a T is given.

The beam: a 48K frame is 69 888 T, the interrupt at T 1812, the first paper pixel at T 16 152 (1812 + 14 340), 224 T
a line, two bytes every 8 T; so byte c of line l is read at T 16 152 + 224 l + 4 c of its frame.
"""
import argparse
import collections
import json
import os
import sys
import textwrap

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

GAME = os.path.join(CASE, 'build', 'game.bin')
ORG = 0x8214
W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)
RED, GREEN, BLUE, ORANGE, PURPLE = (200, 40, 40), (46, 140, 60), (40, 100, 200), (225, 120, 20), (150, 60, 170)
FT, PAPER, LINE_T = 69888, 16152, 224
CHARSET, HUDCHARS, SPRITES, HENS, LIVEMAP = 0x84F0, 0x89E0, 0x8DF0, 0x9010, 0x61A8
SPRITE_BUFFER, CELL_BUFFER = 0x72A0, 0x72DD
CELL_ATTR = [6, 3, 3, 7, 3, 4, 6, 7, 7]   # CellAttributes $984F, codes 9 and up: 6


def game():
    return open(GAME, 'rb').read()


def byte(img, address):
    return img[address - ORG]


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n, t=0):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                               'offset': addr, 'length': n}, ok=False)
    st = r.structured or {}
    if 'hex' not in st:
        raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
    return bytes.fromhex(st['hex'])


def notes(d, x, y, lines, f, width=124, first_dim=None):
    """wrapped paragraphs; a paragraph starting with '$ ' is a command, drawn dim"""
    for para in lines:
        cmd = para.startswith('$ ')
        for line in textwrap.wrap(para[2:] if cmd else para, width):
            d.text((x, y), line, font=f, fill=DIM if cmd else FG)
            y += 17
        y += 3
    return y


def glyph_rows(img, code):
    return [byte(img, CHARSET + 8 * code + i) for i in range(8)]


def draw_bits(d, x, y, rows, width_bits, scale, ink=FG, paper=None, grid=None):
    for r, bits in enumerate(rows):
        for c in range(width_bits):
            on = bits >> (width_bits - 1 - c) & 1
            if on or paper:
                d.rectangle([x + c * scale, y + r * scale, x + (c + 1) * scale - 1, y + (r + 1) * scale - 1],
                            fill=ink if on else paper)
    if grid:
        for c in range(0, width_bits + 1, 8):
            d.line([x + c * scale, y, x + c * scale, y + len(rows) * scale], fill=grid)


def zx(attr_ink, bright=False):
    return K.ink_colour(attr_ink, bright)


# ---------------------------------------------------------------------------------------------------------------------
# the character set

GROUPS = [(0x00, 0x05, 'map cells', ORANGE), (0x0B, 0x1D, 'HUD labels', PURPLE), (0x20, 0x7F, 'the font', BLUE),
          (0x80, 0x8E, 'title blocks', RED), (0x8F, 0x96, 'A+F CHUCKIE EGG', RED), (0x97, 0x9A, 'key names', GREEN),
          (0x9B, 0x9D, 'LEVEL', PURPLE), (0x9E, 0xA7, 'HUD digits', ORANGE), (0xA8, 0xB5, 'the cage', GREEN),
          (0xB6, 0xB7, 'life, cursor', BLUE), (0xB8, 0xCB, 'A&F SOFTWARE', RED)]


def group_of(code):
    for a, b, name, col in GROUPS:
        if a <= code <= b:
            return name, col
    return None, GRID


def fig_charset(out):
    img = game()
    per, cw, ch, sc = 16, 62, 50, 3
    rows = (0xCC + per - 1) // per
    x0, y0 = 30, 76
    h = y0 + rows * ch + 260
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    d.text((14, 10), 'The character set: one table of 8 x 8 glyphs, codes 0-$CB, for the map, the HUD and every text',
           font=ft, fill=FG)
    d.text((14, 36), 'CharacterSet $84F0 holds codes 0-$9D, HudCharacters $89E0 codes $9E-$CB right after it. '
           'Glyph = $84F0 + 8 x code, top row first.', font=f, fill=DIM)
    for code in range(0xCC):
        r, c = divmod(code, per)
        x, y = x0 + c * cw, y0 + r * ch
        name, col = group_of(code)
        rows8 = glyph_rows(img, code)
        d.rectangle([x - 2, y - 2, x + 8 * sc + 1, y + 8 * sc + 1], outline=col, width=2 if name else 1)
        ink = zx(CELL_ATTR[code]) if code <= 5 else FG
        paper = (0, 0, 0) if code <= 5 else (255, 255, 255)
        draw_bits(d, x, y, rows8, 8, sc, ink=ink, paper=paper)
        d.text((x + 30, y + 4), f'{code:02X}', font=fs, fill=FG if any(rows8) else DIM)
    y = y0 + rows * ch + 6
    lx = 30
    for a, b, name, col in GROUPS:
        label = f'{name} {a:02X}-{b:02X}'
        tw = d.textlength(label, font=f)
        if lx + tw + 30 > W - 20:
            lx, y = 30, y + 22
        d.rectangle([lx, y + 3, lx + 12, y + 15], outline=col, width=2)
        d.text((lx + 18, y), label, font=f, fill=FG)
        lx += tw + 40
    y += 30
    y = notes(d, 14, y, [
        'How to read: one box per code, the glyph at 3x with its hex code; the frame colour is the group. The map '
        'cells 0-5 (empty, ladder left, ladder right, egg, grain, brick) are drawn in the ink their CellAttributes '
        '$984F give them on black paper: 6 yellow, 3 magenta, 7 white, 4 green. Grey codes are blank glyphs.',
        'The point: the map, the HUD, the menus and the title logo all come from this one table through PrintChar '
        '$9C40, which copies the 8 bytes down one cell. A map cell is a character code; the screen build (6.3) is '
        'PrintChar over LiveMap. The HUD digits $9E-$A7 are a second digit set, 7 rows under a blank line, beside '
        'the font digits $30-$39.',
        '$ python3 tools/fig_render.py charset --out '
        'docs/img/render/charset.png (from build/game.bin; no recording)'], f)
    im = im.crop((0, 0, W, y))
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------
# the sprite sheets

SPRITE_NAMES = ['right 0', 'right 1', 'right 2', 'right 3', 'left 0', 'left 1', 'left 2', 'left 3', 'duck 0', 'duck 1',
                'duck L 0', 'duck L 1', 'blank', 'climb 0', 'climb 1', 'climb 2', 'climb 3']
HEN_NAMES = ['left', 'right', 'climb 0', 'climb 1', 'left +4', 'right +4', 'peck L', 'peck R']


def frame_rows(img, base, n):
    return [byte(img, base + 32 * n + 2 * r) << 8 | byte(img, base + 32 * n + 2 * r + 1) for r in range(16)]


def bbox(rows, width=16):
    used = [r for r in range(16) if rows[r]]
    o = 0
    for v in rows:
        o |= v
    cols = [c for c in range(width) if o >> (width - 1 - c) & 1]
    return (cols[0], used[0], cols[-1], used[-1]) if used else None


def draw_frame_box(d, x, y, rows, sc, width=16, box=RED):
    d.rectangle([x - 1, y - 1, x + width * sc, y + 16 * sc], outline=GRID)
    draw_bits(d, x, y, rows, width, sc, ink=FG, paper=(232, 232, 228))
    b = bbox(rows, width)
    if b:
        d.rectangle([x + b[0] * sc, y + b[1] * sc, x + (b[2] + 1) * sc - 1, y + (b[3] + 1) * sc - 1], outline=box)


def fig_sprites(out):
    img = game()
    sc, cw = 4, 112
    h = 1010
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    d.text((14, 10), 'The sprite sheets: Harry, the duck and the hens, 16 x 16, no masks, shifted at draw time',
           font=ft, fill=FG)
    y = 44
    d.text((14, y), 'Sprites $8DF0-$900F: 17 frames of 16 x 16 (2 bytes x 16 rows, top row first), drawn by '
           'DrawSprite $9A4C (frame A at $8DF0 + 32 A)', font=f, fill=BLUE)
    y += 24
    for n in range(17):
        r, c = divmod(n, 9)
        x, yy = 24 + c * cw, y + r * 108
        rows = frame_rows(img, SPRITES, n)
        draw_frame_box(d, x, yy, rows, sc)
        d.text((x, yy + 16 * sc + 4), f'{n} {SPRITE_NAMES[n]}', font=fs, fill=FG)
        d.text((x, yy + 16 * sc + 18), f'${SPRITES + 32 * n:04X}', font=fs, fill=DIM)
    y += 2 * 108 + 8
    d.text((14, y), 'HenSprites $9010-$910F: 8 frames of 16 x 16, drawn by DrawHen $929C from the last row up '
           '(read backwards)', font=f, fill=BLUE)
    y += 24
    for n in range(8):
        x = 24 + n * cw
        rows = frame_rows(img, HENS, n)
        draw_frame_box(d, x, y, rows, sc)
        d.text((x, y + 16 * sc + 4), f'{n} {HEN_NAMES[n]}', font=fs, fill=FG)
        d.text((x, y + 16 * sc + 18), f'${HENS + 32 * n:04X}', font=fs, fill=DIM)
    y += 108
    d.text((14, y), 'DrawSprite shifts at draw time: Harry right 1 in SpriteBuffer $72A0 (16 rows of 3 bytes) for '
           'x AND 7 = 0 to 7', font=f, fill=BLUE)
    y += 24
    sc3 = 3
    rows = frame_rows(img, SPRITES, 1)
    for s in range(8):
        x = 24 + s * 126
        shifted = [(v << 8) >> s for v in rows]
        d.rectangle([x - 1, y - 1, x + 24 * sc3, y + 16 * sc3], outline=GRID)
        draw_bits(d, x, y, shifted, 24, sc3, ink=FG, paper=(232, 232, 228), grid=(170, 170, 200))
        d.text((x, y + 16 * sc3 + 4), f'x AND 7 = {s}', font=fs, fill=FG)
    y += 16 * sc3 + 30
    y = notes(d, 14, y, [
        'How to read: each frame at 4x on grey; the red box is the bounding box of its pixels. Harry walks with '
        'frames 0, 1, 0, 3 (frame 2 is a byte-for-byte copy of 0; 1 and 3 differ from it in 13 pixels of the legs); '
        'the left frames 4-7 are the right ones mirrored bit for bit. Harry\'s frames leave row 0, row 15 and two '
        'columns on each side blank; the duck (8-11) fills the box; frame 12 is empty (it erases). A hen walks left '
        'with 0 and right with 1 (columns 0-7) when x AND 4 is 0, and with 4 and 5 (columns 4-11) when it is set: '
        'DrawHen writes whole bytes at x >> 3, so these are the walk pre-shifted by half a byte, in a second pose '
        '(14 pixels differ from 0-1 moved by 4). Climbing 2-3 (by y AND 4) sit in columns 4-11; pecking 6-7 span '
        'the width in rows 6-15. The bottom strip is frame 1 as DrawSprite shifts it into 24-bit rows, one byte '
        'boundary every 8 pixels (blue lines).',
        'The point: there are no masks, and no stored shifts for Harry and the duck: DrawSprite shifts a 16-pixel '
        'frame into three bytes at draw time (1244 T per pixel of shift, 6.4) and ORs it over a background it '
        'rebuilds from the map. Harry\'s blank margins are his eraser: he moves one pixel at a time, so the new '
        '24 x 16 box always covers the old picture.',
        '$ python3 tools/fig_render.py sprites --out docs/img/render/sprites.png (from build/game.bin; no recording)'],
        f)
    im = im.crop((0, 0, W, y + 6))
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------
# the screen layout of a real frame

def fig_layout(work, frame, out):
    s = session(work)
    m = mem(s, frame, 0x4000, 0x1B00)
    full = bytearray(0x10000)
    full[0x4000:0x5B00] = m
    scr = K.render_screen(full).resize((768, 576), Image.NEAREST)
    h = 576 + 330
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    d.text((14, 10), f'The screen layout: levels-1-3 frame {frame} (level 2), with the three coordinate systems of '
           'the code', font=ft, fill=FG)
    x0, y0 = 150, 50
    im.paste(scr, (x0, y0))
    d.text((8, y0 - 18), 'char row / H', font=fs, fill=DIM)
    d.text((x0 + 768 + 10, y0 - 18), 'map row / y', font=fs, fill=DIM)
    for r in range(24):
        yy = y0 + r * 24
        d.line([x0 - 6, yy, x0, yy], fill=GRID)
        d.text((10, yy + 5), f'{r:2d}  H {23 - r:2d}', font=fs, fill=FG if r >= 3 else PURPLE)
        if r >= 3:
            d.text((x0 + 778, yy + 5), f'row {23 - r:2d}  y {191 - 8 * r:3d}', font=fs, fill=FG)
    d.text((x0 + 778, y0 + 5), 'HUD', font=fs, fill=PURPLE)
    d.text((x0 + 778, y0 + 29), 'HUD: lives', font=fs, fill=PURPLE)
    d.text((x0 + 778, y0 + 53), 'HUD', font=fs, fill=PURPLE)
    d.rectangle([x0 - 1, y0 + 72 - 1, x0 + 768, y0 + 576], outline=ORANGE, width=2)
    d.rectangle([x0 - 1, y0 - 1, x0 + 768, y0 + 72 - 1], outline=PURPLE, width=2)
    y = y0 + 576 + 12
    y = notes(d, 14, y, [
        'How to read: the screen at 3x as memory holds it at the start of the frame. Left: the character row 0-23 '
        'and PrintChar\'s row H, counted from the bottom (H = 23 - row). Right: the map row (LiveMap row 0 is the '
        'bottom row of the screen) and y, the sprite coordinate of the cell\'s top line (y = 191 - line, 0 at the '
        'bottom). Purple: the HUD, character rows 0-2 (PrintChar H 23 and 21); orange: the play area, rows 3-23, '
        'the 21 rows of LiveMap $61A8 printed as characters.',
        'The colours: empty cells are yellow ink (6) on black, so Harry (ink 6) never clashes on an empty cell; '
        'ladders and grain are magenta (3), eggs white (7), bricks green (4); hens are cyan (5); the HUD row of the '
        'player in play is white on red.',
        'The point: everything counts up from the bottom: the map is stored bottom row first, PrintChar\'s H and '
        'the sprites\' y grow upwards. Only the screen\'s own line order runs downwards, and every draw routine '
        'turns y into a line as 191 - y.',
        f'$ python3 tools/fig_render.py layout --work W --frame {frame} --out docs/img/render/layout.png '
        '(W holds work/stage1/rec/levels-1-3/session.ttd)'], f)
    im = im.crop((0, 0, W, y))
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------
# one map row, byte to picture

def fig_maprow(work, frame, row, out):
    s = session(work)
    img = game()
    live = mem(s, frame, LIVEMAP + 32 * row, 32)
    m = mem(s, frame, 0x4000, 0x1B00)
    full = bytearray(0x10000)
    full[0x4000:0x5B00] = m
    scr = K.render_screen(full)
    srow = 23 - row
    strip = scr.crop((0, srow * 8, 256, srow * 8 + 8)).resize((768, 24), Image.NEAREST)
    h = 470
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    d.text((14, 10), f'One map row, byte to picture: LiveMap row {row} (${LIVEMAP + 32 * row:04X}), levels-1-3 frame '
           f'{frame}', font=ft, fill=FG)
    x0 = 140
    y = 50
    d.text((14, y + 4), 'LiveMap bytes', font=f, fill=FG)
    for c in range(32):
        d.text((x0 + c * 24 + 4, y + 4), f'{live[c]:02X}', font=fs, fill=FG)
        d.rectangle([x0 + c * 24, y, x0 + c * 24 + 23, y + 22], outline=GRID)
    y += 34
    d.text((14, y + 4), 'glyph 8 x code', font=f, fill=FG)
    for c in range(32):
        code = live[c]
        draw_bits(d, x0 + c * 24, y, glyph_rows(img, code), 8, 3, ink=FG, paper=(232, 232, 228))
    y += 34
    d.text((14, y + 4), 'attribute', font=f, fill=FG)
    for c in range(32):
        code = live[c]
        a = CELL_ATTR[code] if code < 9 else 6
        d.rectangle([x0 + c * 24, y, x0 + c * 24 + 23, y + 22], fill=(0, 0, 0))
        d.text((x0 + c * 24 + 8, y + 4), str(a), font=fs, fill=zx(a))
    y += 34
    d.text((14, y + 4), f'screen row {srow}', font=f, fill=FG)
    im.paste(strip, (x0, y))
    y += 34
    d.text((14, y), 'columns', font=fs, fill=DIM)
    for c in range(0, 32, 4):
        d.text((x0 + c * 24 + 4, y), str(c), font=fs, fill=DIM)
    y += 26
    counts = collections.Counter(live)
    names = {0: 'empty', 1: 'ladder left', 2: 'ladder right', 3: 'egg', 4: 'grain', 5: 'brick'}
    summary = ', '.join(f'{counts[k]} x {k} {names.get(k, "?")}' for k in sorted(counts))
    wc = next((c for c in range(32) if live[c]), 0)
    y = notes(d, 14, y, [
        f'How to read: the 32 bytes of the row ({summary}); under each its glyph from CharacterSet $84F0 + 8 x '
        'code (top row first), the attribute SetupLevel gives it from CellAttributes $984F, and at the bottom the '
        f'real screen row {srow} at 3x, read from memory at the same frame. PrintChar $9C40 prints byte c of row '
        f'{row} at column c, H = {row}: screen row 23 - H = {srow}.',
        f'Worked through for column {wc}: LiveMap + 32 x {row} + {wc} = ${LIVEMAP + 32 * row + wc:04X} holds '
        f'{live[wc]:02X}; the glyph is at $84F0 + 8 x ${live[wc]:02X} = ${CHARSET + 8 * live[wc]:04X}; PrintChar '
        f'puts its 8 bytes at ${K.screen_address(8 * srow, wc):04X} (row {srow}, column {wc}), one line down each '
        f'(INC D); SetupLevel gives ${0x5800 + 32 * srow + wc:04X} the attribute CellAttributes[{live[wc]}] = '
        f'{CELL_ATTR[live[wc]] if live[wc] < 9 else 6}.',
        'The point: the play area is a character screen: a cell is a byte, a byte is a glyph and an attribute, and '
        'the screen row matches the bytes exactly. Eggs and grain are taken by writing 0 into LiveMap; the next '
        'DrawSprite rebuilds the background from the map, so the egg disappears from the screen with no draw of '
        'its own.',
        f'$ python3 tools/fig_render.py maprow --work W --frame {frame} --row {row} --out docs/img/render/maprow.png '
        '(W holds work/stage1/rec/levels-1-3/session.ttd)'], f)
    im = im.crop((0, 0, W, y))
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------
# DrawSprite worked example from a trace

def first_index(trace, start, pcs, stop=None):
    for i in range(start, len(trace.instructions)):
        x = trace.instructions[i]
        if x.pc in pcs:
            return i
        if stop is not None and i > stop:
            break
    return None


def fig_drawsprite(trace_path, at, out):
    t = K.access_trace(None).load(trace_path)
    fa, ta = (int(v) for v in at.split(':'))
    I = t.instructions
    i0 = next(i for i, x in enumerate(I) if x.pc == 0x9A4C and (x.frame, x.t) >= (fa, ta))
    x0 = I[i0]
    frame_no, X, Y = x0.af >> 8, x0.hl & 255, x0.hl >> 8
    i_back = first_index(t, i0, {0x9A93})        # DrawSpriteBack: SpriteBuffer shifted
    i_or = first_index(t, i0, {0x9B11})          # DrawSpriteOr: CellBuffer built
    i_scr = first_index(t, i_or, {0x9B4E})       # DrawSpriteRow: the OR done
    i_att = first_index(t, i_or, {0x9B7B})       # DrawSpriteAttrs: the screen written
    i_end = first_index(t, i_or, {0x9BD7})       # DrawSpriteDone
    m0, m1, m2, m3, m4, m5 = (t.memory_at(i) for i in (i0, i_back, i_or, i_scr, i_att, i_end))
    sh = X & 7
    off = 7 - (Y & 7)

    def buf(m, base, rows):
        return [m[base + 3 * r] << 16 | m[base + 3 * r + 1] << 8 | m[base + 3 * r + 2] for r in range(rows)]

    sc = 8
    h = 900
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    T = (I[i_end].frame - x0.frame) * FT + I[i_end].t - x0.t
    d.text((14, 10), f'DrawSprite at work: levels-1-3 frame {x0.frame} T {x0.t}, Harry frame {frame_no} at x {X}, '
           f'y {Y} ({T} T)', font=ft, fill=FG)
    y = 44
    frows = [m0[SPRITES + 32 * frame_no + 2 * r] << 8 | m0[SPRITES + 32 * frame_no + 2 * r + 1] for r in range(16)]
    panels = [
        ('1. the frame', f'Sprites + 32 x {frame_no}', [v << 8 for v in frows], 16),
        (f'2. SpriteBuffer, >> {sh}', '$72A0, 16 x 3 bytes', buf(m1, SPRITE_BUFFER, 16), 16),
        ('3. CellBuffer', '$72DD, 24 x 3 bytes', buf(m2, CELL_BUFFER, 24), 24),
        ('4. ORed', f'lines {off}-{off + 15} of 3', buf(m3, SPRITE_BUFFER, 16), 16)]
    px = 14
    for title, sub, rows, n in panels:
        d.text((px, y), title, font=f, fill=FG)
        d.text((px, y + 17), sub, font=fs, fill=DIM)
        yy = y + 38
        d.rectangle([px - 1, yy - 1, px + 24 * sc, yy + n * sc], outline=GRID)
        draw_bits(d, px, yy, rows, 24, sc, ink=FG, paper=(232, 232, 228), grid=(170, 170, 200))
        if n == 24:
            d.rectangle([px - 3, yy + off * sc - 2, px + 24 * sc + 2, yy + (off + 16) * sc + 1], outline=RED, width=2)
        px += 24 * sc + 66
    y += 38 + 24 * sc + 20
    # the screen box before and after, with attributes
    line0 = 191 - Y
    col0 = X >> 3

    def crop(m):
        full = bytearray(m)
        scr = K.render_screen(full)
        return scr.crop((col0 * 8 - 8, (line0 & ~7) - 8, col0 * 8 + 32, (line0 & ~7) + 32)).resize((40 * 6, 40 * 6),
                                                                                                    Image.NEAREST)
    for k, (title, m) in enumerate((('5. the screen before', m0), ('6. after the pixels', m4),
                                    ('7. after the attributes', m5))):
        xx = 14 + k * 300
        d.text((xx, y), title, font=f, fill=FG)
        im.paste(crop(m), (xx, y + 20))
        bx = xx + 8 * 6
        by = y + 20 + (line0 - ((line0 & ~7) - 8)) * 6
        d.rectangle([bx, by, bx + 24 * 6, by + 16 * 6], outline=RED, width=2)
    y += 20 + 240 + 14
    y = notes(d, 14, y, [
        'How to read: 1-4 are bitmaps at 8x, one byte boundary every 8 pixels (blue lines); 5-7 are the screen '
        'around the sprite at 6x, one character cell of margin, the red box the 24 x 16 pixels DrawSprite writes. '
        f'Each picture is memory_at of the trace at an instruction: the call ($9A4C), DrawSpriteBack $9A93 (the '
        f'shift done), DrawSpriteOr $9B11 (the cells built), DrawSpriteRow $9B4E (the OR done), DrawSpriteAttrs '
        f'$9B7B (the screen written) and DrawSpriteDone $9BD7.',
        f'Worked through: frame {frame_no} is copied as 16 rows of 2 bytes into rows of 3 and shifted right {sh} '
        f'times (x AND 7 = {sh}). CellBuffer gets the glyphs of the 3 x 3 map cells from LiveMap row {Y >> 3} '
        f'(y >> 3) and the two below, column {X >> 3} (x >> 3) and the two right of it, 24 lines. The 16 lines '
        f'from line 7 - (y AND 7) = {off} are ORed into SpriteBuffer, and the 48 bytes go to the screen from line '
        f'191 - y = {line0}, column {col0}, downwards. Then 3 x 3 attribute cells get 6 (yellow).',
        'The point: the background is rebuilt from the map for every draw, so the old picture inside the box is '
        'wiped with no separate erase, and the egg or grain taken from LiveMap vanishes in the same write.',
        f'$ python3 tools/fig_render.py drawsprite --trace TR --at {at} --out docs/img/render/drawsprite.png (TR = '
        'work/docs/ceB/levels-1-3/traces/600_0-612_0.uatr, an access trace of levels-1-3 frames 600-612)'], f)
    im = im.crop((0, 0, W, y))
    im.save(out)


# ---------------------------------------------------------------------------------------------------------------------
# flicker, measured against the beam

def beam_t(line, column):
    return PAPER + LINE_T * line + 4 * column


def draw_events(t):
    """the calls of DrawSprite, DrawHen (A = 0: the erase) and PaintCells with their screen writes in time order"""
    ranges = [(0x929C, 0x93DD, 'DrawHen'), (0x93DD, 0x9420, 'DrawHen'), (0x9538, 0x95C0, 'PaintCells'),
              (0x9A4C, 0x9BFF, 'DrawSprite'), (0xA07B, 0xA0C8, 'DrawLift')]
    calls, cur = [], {}
    entries = {0x929C: 'DrawHen', 0x9538: 'PaintCells', 0x9A4C: 'DrawSprite', 0xA07B: 'DrawLift'}
    for x in t.instructions:
        T0 = x.frame * FT + x.t
        if x.pc in entries:
            name = entries[x.pc]
            arg = x.bc & 255 if name == 'DrawLift' else x.af >> 8
            cur[name] = {'kind': name, 'T': T0, 'a': arg, 'x': x.hl & 255, 'y': x.hl >> 8, 'w': []}
            calls.append(cur[name])
        owner = next((n for a, b, n in ranges if a <= x.pc < b), None)
        if owner and owner in cur:
            for c in x.cycles:
                if c.tag == 'W' and 0x4000 <= c.address < 0x5B00:
                    cur[owner]['w'].append((T0 + c.dt, c.address, c.value))
    return calls


def missing_lines(erase, draw):
    """(frame, line) pairs the beam read after the erase wrote the line and before the draw wrote it again"""
    e, dd = {}, {}
    for T, a, v in erase['w']:
        if a < 0x5800:
            e.setdefault(a, T)
    for T, a, v in draw['w']:
        if a < 0x5800:
            dd[a] = T
    out = set()
    for a in set(e) & set(dd):
        for fr in range(e[a] // FT, dd[a] // FT + 1):
            b = fr * FT + beam_t(K.screen_line(a), a & 31)
            if e[a] < b < dd[a]:
                out.add((fr, K.screen_line(a)))
    return out


def measure(t):
    calls = draw_events(t)
    res = {'frames': [t.from_frame, t.to_frame]}
    hens = [c for c in calls if c['kind'] == 'DrawHen']
    hm = []
    for i, c in enumerate(hens[:-1]):
        if c['a'] == 0 and hens[i + 1]['a'] != 0:
            m = missing_lines(c, hens[i + 1])
            hm.append({'erase': c['w'][0][0], 'draw': hens[i + 1]['w'][-1][0], 'missing': sorted(m),
                       'x': c['x'], 'y': c['y']})
    res['hens'] = hm
    ds = [c for c in calls if c['kind'] == 'DrawSprite']
    dk = []
    for i, c in enumerate(ds):
        if c['a'] == 12 and c['w']:
            nxt = next((n for n in ds[i + 1:] if 8 <= n['a'] <= 11), None)
            if nxt and nxt['w']:
                m = missing_lines(c, nxt)
                dk.append({'erase': c['w'][0][0], 'draw': nxt['w'][-1][0], 'missing': sorted(m)})
    res['duck'] = dk
    harry = [c for c in ds if c['a'] not in (8, 9, 10, 11, 12) and c['w']]
    tear = 0
    for c in harry:
        bm = [(T, a) for T, a, v in c['w'] if a < 0x5800]
        T0, T1 = bm[0][0], bm[-1][0]
        lines = {K.screen_line(a) for _, a in bm}
        if any(T0 < fr * FT + beam_t(ln, 0) < T1 for ln in lines for fr in range(T0 // FT, T1 // FT + 1)):
            tear += 1
    res['harry'] = {'draws': len(harry), 'beam_inside': tear,
                    'T': sorted(c['w'][-1][0] - c['T'] for c in harry)}
    last, shown, events = {}, collections.Counter(), 0
    seq = sorted((T, a, v, c['kind']) for c in calls if c['kind'] in ('PaintCells', 'DrawSprite')
                 and c['a'] not in (8, 9, 10, 11, 12) for T, a, v in c['w'] if a >= 0x5800)
    for T, a, v, who in seq:
        if who == 'PaintCells':
            last[a] = (T, v)
        elif a in last:
            Tp, vp = last.pop(a)
            if vp != 6:
                events += 1
                r, col = divmod(a - 0x5800, 32)
                if any(Tp < fr * FT + beam_t(8 * r + k, col) < T for fr in range(Tp // FT, T // FT + 1)
                       for k in range(8)):
                    shown[vp] += 1
    res['attr'] = {'cells_not_6': events, 'read_in_between': dict(shown)}
    lifts = [c for c in calls if c['kind'] == 'DrawLift']
    lm = 0
    for i, c in enumerate(lifts[:-1]):
        if c['a'] == 0 and lifts[i + 1]['a'] == 0xFF and missing_lines(c, lifts[i + 1]):
            lm += 1
    res['lifts'] = {'pairs': sum(1 for i, c in enumerate(lifts[:-1]) if c['a'] == 0), 'missing': lm}
    return res


def tv_picture(t, frames):
    """{frame: 256 x 192 image} of what the beam read: each line from memory at the moment the beam read it"""
    memory = bytearray(t.memory)
    want = sorted(frames)
    out = {fr: (bytearray(6144), bytearray(768 * 8)) for fr in want}
    reads = []
    for fr in want:
        for ln in range(192):
            reads.append((fr * FT + beam_t(ln, 0), fr, ln))
    reads.sort()
    k = 0

    def take(fr, ln):
        bm, at = out[fr]
        base = K.screen_address(ln, 0)
        bm[ln * 32:ln * 32 + 32] = memory[base:base + 32]
        at[ln * 32:ln * 32 + 32] = memory[0x5800 + (ln >> 3) * 32:0x5800 + (ln >> 3) * 32 + 32]
    for x in t.instructions:
        T0 = x.frame * FT + x.t
        while k < len(reads) and reads[k][0] <= T0:
            take(reads[k][1], reads[k][2])
            k += 1
        if k >= len(reads):
            break
        for c in x.cycles:
            if c.tag == 'W':
                memory[c.address] = c.value
    pics = {}
    for fr, (bm, at) in out.items():
        im = Image.new('RGB', (256, 192))
        px = im.load()
        for ln in range(192):
            for col in range(32):
                bits, a = bm[ln * 32 + col], at[ln * 32 + col]
                ink, paper = K.ink_colour(a & 7, a & 0x40), K.ink_colour((a >> 3) & 7, a & 0x40)
                for b in range(8):
                    px[col * 8 + b, ln] = ink if bits & (0x80 >> b) else paper
        pics[fr] = im
    return pics


def fig_flicker(trace_path, out, json_out=None):
    t = K.access_trace(None).load(trace_path)
    res = measure(t)
    if json_out:
        json.dump(res, open(json_out, 'w'), indent=1)
    duck = [e for e in res['duck'] if e['missing']]
    hens = [e for e in res['hens'] if e['missing']]
    de = duck[0]
    he = max(hens, key=lambda e: len(e['missing']))
    dframe = de['missing'][0][0]
    hframe = he['missing'][0][0]
    pics = tv_picture(t, [dframe - 1, dframe, dframe + 1, hframe - 1, hframe, hframe + 1])
    calls = draw_events(t)
    h = 1180
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    ft, f, fs = K.font(17), K.font(13), K.font(11)
    n_frames = res['frames'][1] - res['frames'][0]
    d.text((14, 10), 'Flicker, measured: the beam reads a sprite\'s lines after its erase, before its redraw',
           font=ft, fill=FG)

    def beam_panel(x0, y0, w, hgt, frame, events, title, band):
        d.text((x0, y0 - 20), title, font=f, fill=FG)
        d.rectangle([x0, y0, x0 + w, y0 + hgt], outline=GRID)

        def X(T):
            return x0 + (T - frame * FT) / FT * w

        def Y(ln):
            return y0 + ln / 192 * hgt
        d.rectangle([x0, Y(band[0]), x0 + w, Y(band[1] + 1)], fill=(250, 228, 228))
        d.line([X(frame * FT + PAPER), Y(0), X(frame * FT + PAPER + LINE_T * 192), Y(192)], fill=BLUE, width=2)
        for kind, col in events:
            for T, a, v in kind:
                if a < 0x5800 and frame * FT <= T < (frame + 1) * FT:
                    xx, yy = X(T), Y(K.screen_line(a))
                    d.rectangle([xx - 1, yy - 1, xx + 1, yy + 1], fill=col)
        for v in (0, 64, 128, 191):
            d.text((x0 - 26, Y(v) - 7), str(v), font=fs, fill=DIM)
        for T in (0, 20000, 40000, 60000):
            d.text((X(frame * FT + T) - 10, y0 + hgt + 4), str(T), font=fs, fill=DIM)
        d.text((x0 + w / 2 - 40, y0 + hgt + 18), 'T in the frame', font=fs, fill=DIM)
    dcalls = [c for c in calls if c['kind'] == 'DrawSprite' and c['w'] and c['w'][0][0] == de['erase']]
    dnext = [c for c in calls if c['kind'] == 'DrawSprite' and c['w'] and c['w'][-1][0] == de['draw']]
    hcalls = [c for c in calls if c['kind'] == 'DrawHen' and c['w'] and c['w'][0][0] == he['erase']]
    hnext = [c for c in calls if c['kind'] == 'DrawHen' and c['w'] and c['w'][-1][0] == he['draw']]
    dl = [ln for _, ln in de['missing']]
    hl = [ln for _, ln in he['missing']]
    beam_panel(50, 70, 440, 300, dframe, [(dcalls[0]['w'], RED), (dnext[0]['w'], GREEN)],
               f'The caged duck, frame {dframe}: lines {min(dl)}-{max(dl)} read blank', (min(dl), max(dl)))
    beam_panel(570, 70, 440, 300, hframe, [(hcalls[0]['w'], RED), (hnext[0]['w'], GREEN)],
               f'A hen, frame {hframe}: lines {min(hl)}-{max(hl)} read without it', (min(hl), max(hl)))
    y = 70 + 300 + 44
    d.text((14, y), 'What the TV showed (each line as the beam read it) in three frames, and the memory at the end of '
           'the middle one:', font=f, fill=FG)
    y += 22

    def crop(pic, line, col, n):
        return pic.crop((col * 8, line, col * 8 + n * 8, line + 32)).resize((n * 8 * 4, 32 * 4), Image.NEAREST)
    dl0, hl0 = (min(dl) - 8) & ~7, (min(hl) - 8) & ~7
    dcol = dcalls[0]['x'] >> 3
    hcol = max(0, (hcalls[0]['x'] >> 3) - 1)
    end = bytearray(t.memory_at(next(i for i, x in enumerate(t.instructions) if x.frame == dframe + 1)))
    endh = bytearray(t.memory_at(next(i for i, x in enumerate(t.instructions) if x.frame == hframe + 1)))
    xx = 14
    for fr in (dframe - 1, dframe, dframe + 1):
        im.paste(crop(pics[fr], dl0, dcol, 3), (xx, y))
        d.text((xx, y + 132), f'TV {fr}', font=fs, fill=FG)
        xx += 108
    im.paste(crop(K.render_screen(end), dl0, dcol, 3), (xx, y))
    d.text((xx, y + 132), f'memory end {dframe}', font=fs, fill=DIM)
    xx += 150
    for fr in (hframe - 1, hframe, hframe + 1):
        im.paste(crop(pics[fr], hl0, hcol, 3), (xx, y))
        d.text((xx, y + 132), f'TV {fr}', font=fs, fill=FG)
        xx += 108
    im.paste(crop(K.render_screen(endh), hl0, hcol, 3), (xx, y))
    d.text((xx, y + 132), f'memory end {hframe}', font=fs, fill=DIM)
    y += 160
    dn = len(res['duck'])
    hn = len(res['hens'])
    hmiss = sorted(len(e['missing']) for e in res['hens'] if e['missing'])
    a = res['attr']
    rows = [
        ('the duck in its cage (frame 12, then 8-11)', f'{dn} redraws', f'{len(duck)} with the whole duck blank in '
         f'one TV frame'),
        ('the hens (EraseHen, then DrawHen)', f'{hn} moves', f'{len(hens)} with lines read blank: '
         f'{", ".join(map(str, hmiss))} lines'),
        ('Harry (DrawSprite, one write a line)', f'{res["harry"]["draws"]} draws', f'{res["harry"]["beam_inside"]} '
         'with the beam inside the write (a 1-pixel shear)'),
        ('Harry\'s colour (PaintCells, then DrawSprite 6)', f'{a["cells_not_6"]} cells', 'read in the map colour: '
         + ', '.join(f'{v} x ink {k}' for k, v in sorted(a['read_in_between'].items()))),
        ('the lifts (DrawLift 0, then $FF)', f'{res["lifts"]["pairs"]} moves', f'{res["lifts"]["missing"]} with '
         'lines read blank')]
    for r in rows:
        d.text((14, y), r[0], font=f, fill=FG)
        d.text((390, y), r[1], font=f, fill=FG)
        d.text((520, y), r[2], font=f, fill=FG)
        y += 19
    y += 8
    y = notes(d, 14, y, [
        'How to read: in the two timelines x is the T-state of the frame and y the screen line; the blue line is the '
        'beam reading the paper (line l at T 16 152 + 224 l), red dots are the erase\'s writes, green dots the '
        'redraw\'s, and the pink band the lines the beam read between them. The crops are at 4x: "TV" is the '
        'picture the beam built, line by line from memory at its read time (replayed from the trace); "memory end" '
        'is the screen memory at the end of the frame, what a screenshot shows. The table counts every event of '
        f'the {n_frames} frames.',
        'The point: the game never waits for the beam. Harry cannot flicker, because DrawSprite writes each line '
        'once with the background and the sprite already combined. The hens and the caged duck are erased first '
        'and drawn again later in the pass, so when the beam passes in between they vanish from one TV frame. The '
        'window is about 23 300 T (6.7 ms, one DrawSprite) for the duck and 7 900 T (2.3 ms) for a hen, a third '
        'and a ninth of a frame, as the counts show. Harry\'s colour flickers too: PaintCells gives his cells back the map colours before he moves and DrawSprite paints them yellow '
        'about 20 000 T later.',
        f'$ python3 tools/fig_render.py flicker --trace TR --out docs/img/render/flicker.png (TR = '
        'work/docs/ceB/levels-1-3/traces/600_0-900_0.uatr, an access trace of levels-1-3 frames 600-900)'], f)
    im = im.crop((0, 0, W, y))
    im.save(out)
    print(json.dumps({k: v for k, v in res.items() if k in ('attr', 'lifts')}),
          'duck', dn, len(duck), 'hens', hn, len(hens), hmiss, 'harry', res['harry']['draws'],
          res['harry']['beam_inside'], 'frames', dframe, hframe)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['charset', 'sprites', 'layout', 'maprow', 'drawsprite', 'flicker'])
    p.add_argument('--work')
    p.add_argument('--trace')
    p.add_argument('--frame', type=int)
    p.add_argument('--row', type=int)
    p.add_argument('--at', help='drawsprite: F:T, the first DrawSprite call from there')
    p.add_argument('--json')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.what == 'charset':
        fig_charset(args.out)
    elif args.what == 'sprites':
        fig_sprites(args.out)
    elif args.what == 'layout':
        fig_layout(args.work, args.frame, args.out)
    elif args.what == 'maprow':
        fig_maprow(args.work, args.frame, args.row, args.out)
    elif args.what == 'drawsprite':
        fig_drawsprite(args.trace, args.at, args.out)
    else:
        fig_flicker(args.trace, args.out, args.json)
    print(args.out)


if __name__ == '__main__':
    main()

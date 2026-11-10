#!/usr/bin/env python3
"""The figures of doc 06 (rendering), drawn from the image, the resource sheets and recordings read with TTD
memory_at.

    python3 tools/fig_render.py sheets --out docs/img/render/sheets.png
    python3 tools/fig_render.py tiles --out docs/img/render/tiles.png
    python3 tools/fig_render.py room --work W --room 84 --frame 15466 --out docs/img/render/room84.png
    python3 tools/fig_render.py list --work W --frame 15010 --out docs/img/render/sprite-list.png
    python3 tools/fig_render.py shift --out docs/img/render/shift.png
    python3 tools/fig_render.py mirror --out docs/img/render/mirror.png
    python3 tools/fig_render.py scroll --work W --from 14380 --to 14560 --step 12 --out docs/img/render/scroll.png
    python3 tools/fig_render.py exhaust --work W --from 14700 --to 14716 --out docs/img/render/exhaust.png

The image is build/game.bin (`sh tools/build.sh`), the game block `$60C0-$FDFF` as loaded, so the enemy and object
frames are at their stored shift (0). W is a work folder whose instance holds `c1` (work/stage1/c1/session.ttd,
re_session.py session.json). A memory sample of frame N is the memory at the start of frame N (TTD memory_at,
tinframe 0): the sprite list then holds what the interrupt of frame N will draw, since WaitFrame closes the list
before its HALT.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

GAME = os.path.join(CASE, 'build', 'game.bin')
ORG = 0x60C0
W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)
ACC = [(200, 40, 40), (40, 100, 200), (46, 140, 60), (225, 120, 20), (170, 50, 170), (0, 140, 150),
       (150, 110, 20), (90, 90, 100)]
TILE_GRAPHICS, TILE_ATTRS, ROOM_LAYOUTS, BIT_REVERSE = 0x6EA8, 0x6F36, 0xBD06, 0x9A4C


class Image64:
    """the 64 K view of the game block as loaded"""

    def __init__(self):
        data = open(GAME, 'rb').read()
        self.m = bytearray(0x10000)
        self.m[ORG:ORG + len(data)] = data

    def __getitem__(self, a):
        return self.m[a]

    def word(self, a):
        return self.m[a] | self.m[a + 1] << 8


def notes(d, y, lines, f, n_fg):
    for i, line in enumerate(lines):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < n_fg else DIM)
    return y + len(lines) * 18


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': addr, 'length': n, 'format': 'base64'}, ok=False)
    st = r.structured or {}
    if 'hex' not in st:
        raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
    return bytes.fromhex(st['hex'])


def screen_at(s, frame):
    m = bytearray(0x10000)
    m[0x4000:0x5B00] = mem(s, frame, 0x4000, 6912)
    return m


def bitmap(data, width, rows, scale, ink=(235, 235, 235), paper=(0, 0, 0), grid=None):
    im = Image.new('RGB', (width * 8 * scale, rows * scale), paper)
    d = ImageDraw.Draw(im)
    for r in range(rows):
        for c in range(width):
            b = data[r * width + c]
            for bit in range(8):
                if b & 0x80 >> bit:
                    x = (c * 8 + bit) * scale
                    d.rectangle([x, r * scale, x + scale - 1, r * scale + scale - 1], fill=ink)
    if grid:
        for c in range(1, width):
            d.line([(c * 8 * scale, 0), (c * 8 * scale, rows * scale)], fill=grid)
    return im


# ---------------------------------------------------------------------------------------------------------------------

SHEETS = [
    ('Droid.png', 'Droid $9C40-$A257: 14 frames of 40 rows', 'MoveDroid $7208, TurnRound $7866 (mirrored in place)', 3),
    ('Probe.png', 'Probe $AF85-$B048: 4 frames, shift byte + 16 x 3', 'MoveShot3 $82AA, ShiftGraphic3', 3),
    ('Enemies.png', 'Enemies $A74E-$AEC4: 9 kinds + explosion', 'MoveEnemy $90E7, ShiftGraphic3 (in place)', 3),
    ('Objects.png', 'Objects $B049-$B901: 5 kinds, death, probe blast', 'MoveObject $809D, ShiftGraphic4 (in place)', 3),
    ('Patrollers.png', 'Patrollers $B902-$BC01: right, left', 'MovePatrollers $6AAD, never shifted', 2),
    ('Materialise.png', 'Materialise $AEC5-$AF84', 'MoveEnemy, never shifted', 2),
    ('ShotGraphics.png', 'Shots $8814-$8853: weapons 1, 2', 'MoveShot $8298', 3),
]


def sheet(name, scale):
    im = Image.open(os.path.join(CASE, 'src', 'res', 'sprites', name)).convert('P')
    pal = {0: (0, 0, 0), 1: (235, 235, 235), 2: (70, 70, 85)}
    rgb = Image.new('RGB', im.size)
    px, out = im.load(), rgb.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            out[x, y] = pal.get(px[x, y], (120, 0, 0))
    return rgb.resize((im.size[0] * scale, im.size[1] * scale), Image.NEAREST)


def fig_sheets(out):
    f, fs, ft = K.font(13), K.font(11), K.font(17)
    pics = [(sheet(n, s), t, r) for n, t, r, s in SHEETS]
    im = Image.new('RGB', (W, 1240), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 8), 'The sprite sheets of src/res/sprites, as drawn by the XOR list (all frames as loaded)', font=ft,
           fill=FG)

    def put(i, x, y):
        p, t, r = pics[i]
        d.text((x, y), t, font=f, fill=FG)
        d.text((x, y + 17), r, font=fs, fill=DIM)
        im.paste(p, (x, y + 36))
        return y + 36 + p.size[1] + 14
    y1 = put(0, 14, 40)
    put(1, 14 + pics[0][0].size[0] + 24, 40)
    y2 = put(2, 14, y1)
    put(3, 14 + pics[2][0].size[0] + 24, y1)
    x3 = 14 + pics[2][0].size[0] + pics[3][0].size[0] + 48
    y = put(4, x3, y1)
    y = put(5, x3, y)
    put(6, x3, y)
    y = notes(d, y2 + 4, [
        'How to read: each sheet at 3 x (2 x for the patrollers and the materialise frames), one frame per cell; grey',
        'lines are the sheet grid. The droid sheet holds the right-facing set: TurnRound mirrors the whole set in place with',
        'BitReverse when the droid turns. Enemy, probe and object frames start with a shift byte (0 here) and are',
        'shifted in place to the pixel x before each draw; patrollers and the materialise frames are never shifted.',
        'From the resource sheets (tools/res_formats.py): python3 tools/fig_render.py sheets --out '
        'docs/img/render/sheets.png'], f, 4)
    im.crop((0, 0, W, y + 8)).save(out)


def tile_of(img, t):
    g = img.word(TILE_GRAPHICS - 2 + 2 * t)
    a = img.word(TILE_ATTRS - 2 + 2 * t)
    if not g:
        return None
    w, h = img[g], img[g + 1]
    data = bytes(img[g + 2 + i] for i in range(w * h))
    cells = w * ((h + 7) // 8)
    if img[a] & 0x80:
        attrs = [img[a] & 0x7F] * cells
    else:
        attrs = [img[a + i] for i in range(cells)]
    return g, a, w, h, data, attrs


def colour_tile(w, h, data, attrs, scale):
    im = Image.new('RGB', (w * 8 * scale, h * scale))
    px = im.load()
    for r in range(h):
        for c in range(w):
            at = attrs[(r // 8) * w + c]
            ink, paper = K.ink_colour(at & 7, at & 0x40), K.ink_colour(at >> 3 & 7, at & 0x40)
            b = data[r * w + c]
            for bit in range(8):
                col = ink if b & 0x80 >> bit else paper
                for yy in range(scale):
                    for xx in range(scale):
                        px[(c * 8 + bit) * scale + xx, r * scale + yy] = col
    return im


def fig_tiles(out):
    img = Image64()
    f, fs, ft = K.font(12), K.font(11), K.font(17)
    im = Image.new('RGB', (W, 1700), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 8), 'The 70 tiles: TileGraphics $6EA8 and TileAttrs $6F36, drawn with their colours (2 x)', font=ft,
           fill=FG)
    x, y, row_h = 14, 40, 0
    for t in range(1, 71):
        tl = tile_of(img, t)
        if not tl:
            continue
        g, a, w, h, data, attrs = tl
        p = colour_tile(w, h, data, attrs, 2)
        cw = max(p.size[0], 92)
        if x + cw > W - 14:
            x, y, row_h = 14, y + row_h + 8, 0
        d.text((x, y), f'{t} {w}x{h // 8}', font=f, fill=FG)
        d.text((x, y + 15), f'${g:04X}', font=fs, fill=DIM)
        d.rectangle([x - 1, y + 31, x + p.size[0], y + 32 + p.size[1]], outline=GRID)
        im.paste(p, (x, y + 32))
        row_h = max(row_h, 32 + p.size[1])
        x += cw + 10
    y = notes(d, y + row_h + 14, [
        'How to read: each tile with its number, its size in character cells (width x height) and the address of its',
        'graphic. A graphic is a width in bytes, a height in pixel rows, then the rows, top first. The colours come',
        'from a TileAttrs block: a first byte with bit 7 set is one colour for every cell, else one byte a cell.',
        'Tile 49 has no graphic. Cells with attribute 0 (in tiles 33, 34, 39, 40, 52) stay free in the cell table.',
        'From build/game.bin: python3 tools/fig_render.py tiles --out docs/img/render/tiles.png'], f, 4)
    im.crop((0, 0, W, y + 8)).save(out)


def room_triples(img, room):
    off = img.word(ROOM_LAYOUTS + 2 * room)
    a = ROOM_LAYOUTS + off
    out = []
    while not img[a] & 0x80:
        out.append((a, img[a], img[a + 1], img[a + 2]))
        a += 3
    return ROOM_LAYOUTS + 2 * room, off, out, a


def draw_layout(img, triples):
    """DrawRoomLayout $6C93 to $6D89, byte for byte: the screen bytes it writes (address -> value)"""
    scr = {}
    for _, col, row, t in triples:
        tl = tile_of(img, t)
        g = img.word(TILE_GRAPHICS - 2 + 2 * t)
        a = img.word(TILE_ATTRS - 2 + 2 * t)
        L = ((((row >> 3) | (row << 5)) & 0xFF) & 0xE0) | col
        H = (row & 0x18) | 0x40
        L += 0xA0
        if L > 0xFF:
            L &= 0xFF
            H += 8
        w, h = img[g], img[g + 1]
        de = g + 2
        base_h, base_l = H, L
        for r in range(h):
            hl = (H << 8) | L
            for _ in range(w):
                hh, ll = hl >> 8, hl & 0xFF
                if (hh & 0xF8) == 0x58:
                    continue
                if (hh & 0xF8) == 0x40 and (ll & 0xE0) < 0xC0:
                    de += 1
                    continue
                scr[hl] = img[de]
                hl = (hh << 8) | ((ll + 1) & 0xFF)
                de += 1
            H += 1
            if H & 7 == 0:
                L += 0x20
                if L > 0xFF:
                    L &= 0xFF
                else:
                    H -= 8
        ah = ((base_h >> 3) & 3) | 0x58
        al = base_l
        rows = h >> 3
        fill = img[a] & 0x80
        for r in range(rows):
            hl = (ah << 8) | al
            for c in range(w):
                hh, ll = hl >> 8, hl & 0xFF
                if hh >= 0x5B or (hh == 0x58 and (ll & 0xE0) < 0xC0):
                    if not fill:
                        a += 1
                    if fill:
                        break
                    continue
                scr[hl] = (img[a] & 0x7F) if fill else img[a]
                hl = (hh << 8) | ((ll + 1) & 0xFF)
                if not fill:
                    a += 1
            al += 0x20
            if al > 0xFF:
                al &= 0xFF
                ah += 1
        del tl
    return scr


def fig_room(work, room, frame, out):
    img = Image64()
    ptr, off, triples, end = room_triples(img, room)
    scr = draw_layout(img, triples)
    m = bytearray(0x10000)
    for a, v in scr.items():
        m[a] = v
    s = session(work)
    real = screen_at(s, frame)
    same = diff = 0
    for a in range(0x40C0, 0x5800):
        if K.screen_line(a) < 48:
            continue
        if m[a] == real[a]:
            same += 1
        else:
            diff += 1
    adiff = sum(1 for a in range(0x58C0, 0x5B00) if m[a] != real[a])
    scale = 2
    mine = K.render_screen(m).crop((0, 40, 256, 192)).resize((512, 304), Image.NEAREST)
    shot = K.render_screen(real).crop((0, 40, 256, 192)).resize((512, 304), Image.NEAREST)
    im = Image.new('RGB', (W, 900), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'Room {room} from its bytes: RoomLayouts word ${ptr:04X} = ${off:04X}, {len(triples)} triples '
                    f'at ${ROOM_LAYOUTS + off:04X}-${end:04X}', font=ft, fill=FG)
    d.text((14, 32), 'the triples drawn by a Python copy of DrawRoomLayout', font=f, fill=FG)
    d.text((14 + 512 + 12, 32), f'the screen of c1 at frame {frame} (sprites and item included)', font=f, fill=FG)
    im.paste(mine, (14, 52))
    im.paste(shot, (14 + 512 + 12, 52))
    for i, (_, col, row, t) in enumerate(triples):
        tl = tile_of(img, t)
        w, h = tl[2], tl[3]
        y0 = (row + 5) * 8 - 40
        x0 = col * 8
        box = [14 + x0 * scale, 52 + y0 * scale, 14 + (x0 + w * 8) * scale - 1, min(52 + 303, 52 + (y0 + h) * scale - 1)]
        c = ACC[i % len(ACC)]
        d.rectangle(box, outline=c, width=2)
        d.text((box[0] + 3, max(52, box[1]) + 2), str(t), font=fs, fill=(255, 255, 255))
    d.line([(14, 52 + 8 * scale), (14 + 512, 52 + 8 * scale)], fill=(255, 80, 80))
    y = 52 + 304 + 10
    d.text((14, y), 'line 48 (screen row 6) is drawn by the red line; above it the clip drops the bytes', font=fs,
           fill=DIM)
    y += 22
    cols = 3
    for i, (a, col, row, t) in enumerate(triples):
        cx = 14 + (i % cols) * 340
        cy = y + (i // cols) * 18
        d.text((cx, cy), f'${a:04X}: {col:02X} {row:02X} {t:02X}  tile {t} at {col},{row}', font=f,
               fill=ACC[i % len(ACC)])
    y += ((len(triples) + cols - 1) // cols) * 18 + 4
    d.text((14, y), f'${end:04X}: {img[end]:02X}  a column byte with bit 7 ends the room', font=f, fill=FG)
    y = notes(d, y + 26, [
        f'How to read: left, the play area (screen lines 40-191) as the Python copy of DrawRoomLayout $6C93 draws it',
        f'from the triples below; each box is one tile, its number at the corner. Right, the real screen. Of the',
        f'{same + diff} bitmap bytes of lines 48-191, {same} are equal and {diff} differ; {adiff} of the 576 play '
        f'attributes differ.',
        'The differences are the item ED 8 (DrawItem $6E0D draws it after the tiles) and the colours the droid and its',
        'exhaust put on the play area in the frame after the draw. Boxes are cut at the screen\'s bottom edge.',
        f'From build/game.bin and c1: python3 tools/fig_render.py room --work W --room {room} --frame {frame} --out '
        f'{out}'], f, 5)
    im.crop((0, 0, W, y + 8)).save(out)


def fig_list(work, frame, out):
    s = session(work)
    lst = mem(s, frame, 0xFF01, 128)
    after = screen_at(s, frame + 1)
    ents = []
    for i in range(16):
        e = lst[i * 8:i * 8 + 8]
        g = e[0] | e[1] << 8
        if not g:
            break
        ents.append((0xFF01 + i * 8, g, e[2] | e[3] << 8, e[4], e[5], e[6] | e[7] << 8, e))
    im = Image.new('RGB', (W, 820), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'The sprite list $FF01 as the interrupt of c1 frame {frame} finds it ({len(ents)} entries)',
           font=ft, fill=FG)
    names = {0x630D: 'Enemy2 flags', 0x631F: 'Enemy4 flags', 0x6304: 'Enemy1 flags', 0x6316: 'Enemy3 flags',
             0x635B: 'DroidFlags', 0x0000: 'ROM 0: ignored'}
    y = 40
    hdr = ['entry', 'bytes', 'graphic', 'flag pointer', 'w x rows', 'screen', 'column, line', 'graphic as drawn']
    xs = [14, 80, 300, 380, 530, 610, 680, 800]
    for x, h in zip(xs, hdr):
        d.text((x, y), h, font=f, fill=DIM)
    y += 22
    gm = mem(s, frame, 0x6000, 0xA000)
    gm = bytes(0x6000) + gm
    for i, (a, g, fp, w, r, sa, e) in enumerate(ents):
        c = ACC[i % len(ACC)]
        thumb = bitmap(gm[g:g + w * r * 8], w, r * 8, 2)
        h = max(28, thumb.size[1] + 6)
        d.text((xs[0], y), f'${a:04X}', font=f, fill=c)
        d.text((xs[1], y), ' '.join(f'{b:02X}' for b in e), font=f, fill=FG)
        d.text((xs[2], y), f'${g:04X}', font=f, fill=FG)
        d.text((xs[3], y), f'${fp:04X} {names.get(fp, "")}', font=fs, fill=FG)
        d.text((xs[4], y), f'{w} x {r}', font=f, fill=FG)
        d.text((xs[5], y), f'${sa:04X}', font=f, fill=FG)
        d.text((xs[6], y), f'{sa & 31}, {K.screen_line(sa)}', font=f, fill=FG)
        im.paste(thumb, (xs[7], y))
        y += h
    y += 10
    shot = K.render_screen(after).resize((512, 384), Image.NEAREST)
    im.paste(shot, (14, y))
    dd = ImageDraw.Draw(im)
    for i, (a, g, fp, w, r, sa, e) in enumerate(ents):
        x0, y0 = (sa & 31) * 8 * 2, K.screen_line(sa) * 2
        dd.rectangle([14 + x0 + i % 2, y + y0 + i % 2, 14 + x0 + w * 16 - 1, y + y0 + r * 16 - 1],
                     outline=ACC[i % len(ACC)], width=2)
    ny = notes(d, y, [], f, 0)
    tx = 14 + 512 + 16
    lines = [
        'How to read: one line per 8-byte entry:',
        'graphic, flag pointer, width in bytes,',
        'height in character rows, screen address.',
        f'Below, the screen at frame {frame + 1}, after',
        'the XOR, each entry boxed in its colour.',
        '',
        'Each enemy has two entries: the old image',
        '(buffer A, flag pointer 0: an erase always',
        '"collides", so its flag goes to ROM) and the',
        'new image (buffer B, flag pointer = the',
        'enemy record + 1). The XOR of the old image',
        'erases it, the XOR of the new one draws it.',
        '',
        f'python3 tools/fig_render.py list --work W',
        f'--frame {frame} --out {out}']
    for i, line in enumerate(lines):
        d.text((tx, y + i * 18), line, font=f, fill=FG if i < 12 else DIM)
    im.crop((0, 0, W, max(ny, y + 384) + 10)).save(out)


def shifted(data, rows, width, n):
    out = bytearray(data)
    for r in range(rows):
        v = int.from_bytes(out[r * width:(r + 1) * width], 'big') >> n
        out[r * width:(r + 1) * width] = v.to_bytes(width, 'big')
    return out


def fig_shift(out):
    img = Image64()
    g = 0xA74E
    data = bytes(img[g + 1 + i] for i in range(48))
    im = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), 'ShiftGraphic3 $7EBB: enemy kind 1, frame 0 ($A74E), at the eight pixel offsets', font=ft,
           fill=FG)
    scale = 5
    for n in range(8):
        p = bitmap(shifted(data, 16, 3, n), 3, 16, scale, grid=(90, 90, 120))
        x = 14 + (n % 4) * 256
        y = 40 + (n // 4) * 130
        d.text((x, y), f'x AND 7 = {n}: {n} x (SRL, RR, RR)', font=f, fill=FG)
        im.paste(p, (x, y + 18))
    notes(d, 310, [
        'How to read: the 3 x 16 bytes of the frame after ShiftGraphic3, 5 x, the blue lines between the three bytes',
        'of a row. The frame is 16 pixels wide in 24: the spare byte takes the 7 pixels a shift pushes out. Byte 0 of',
        'the frame (at $A74E) holds the offset it is stored at; ShiftGraphic3 shifts from that offset to the wanted',
        'one (right with SRL, RR, RR; left with SLA, RL, RL), writes the new offset, and the next call starts from',
        'there. So the graphic in the image changes in play: the bytes at $A74F-$A77E are those of the last offset',
        'drawn. The cost is 16 rows x |new - old| x 3 shifts of (IX+d): up to 7 x 16 x 3 x 23 T = 7728 T.',
        'MoveEnemy then copies the 48 bytes to the enemy\'s buffer ($6708 + 96 x n: A old image, B new image), so two',
        'enemies of the same kind at different offsets each keep their own picture until the interrupt draws it.',
        'From build/game.bin: python3 tools/fig_render.py shift --out docs/img/render/shift.png'], f, 8)
    im.save(out)


def fig_mirror(out):
    img = Image64()
    rev = [img[BIT_REVERSE + i] for i in range(256)]
    im = Image.new('RGB', (W, 700), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), 'BitReverse $9A4C and the turn: a byte\'s bits reversed, three bytes of a row swapped', font=ft,
           fill=FG)
    x0, y0 = 14, 40
    d.text((x0, y0), 'BitReverse[n], n = row x 16 + column', font=f, fill=FG)
    for c in range(16):
        d.text((x0 + 34 + c * 28, y0 + 20), f'{c:X}', font=fs, fill=DIM)
    for r in range(16):
        d.text((x0, y0 + 38 + r * 18), f'{r:X}0', font=fs, fill=DIM)
        for c in range(16):
            d.text((x0 + 30 + c * 28, y0 + 38 + r * 18), f'{rev[r * 16 + c]:02X}', font=fs, fill=FG)
    # a droid walk frame and its mirror
    g = 0x9C40
    data = bytes(img[g + i] for i in range(120))
    mir = bytearray(120)
    for r in range(40):
        a, b, c = data[r * 3:r * 3 + 3]
        mir[r * 3:r * 3 + 3] = bytes((rev[c], rev[b], rev[a]))
    p1 = bitmap(data, 3, 40, 4, grid=(90, 90, 120))
    p2 = bitmap(mir, 3, 40, 4, grid=(90, 90, 120))
    px = 520
    d.text((px, y0), 'frame 0 ($9C40) as loaded', font=f, fill=FG)
    im.paste(p1, (px, y0 + 20))
    d.text((px + 260, y0), 'after TurnMirror3', font=f, fill=FG)
    im.paste(p2, (px + 260, y0 + 20))
    notes(d, y0 + 20 + 164 + 200, [
        'How to read: left, the 256-byte table: the byte at $9A4C + n is n with its bits in reverse order (n = $01',
        'gives $80). Right, the droid\'s first walk frame (3 x 40 bytes) and the same frame after TurnMirror3 $78A4:',
        'for every row, left = BitReverse[right], middle = BitReverse[middle], right = BitReverse[left].',
        'The table is not page aligned ($9A4C), so each lookup reloads DE and adds A to E with a carry into D (LD DE;',
        'ADD A,E; LD E,A; JR NC; INC D), where a table at $xx00 needs only LD E,A. TurnRound mirrors the whole droid set',
        'in place in five steps, one per acting pass of the turn (TurnSequence 8, 9, 10, 9, 8): four of 160 rows of 3',
        'bytes and one of 80 rows of 2 bytes (TurnMirror2) that then skips the front frame $A0A0, which is symmetric.',
        'From build/game.bin: python3 tools/fig_render.py mirror --out docs/img/render/mirror.png'], f, 7)
    im.crop((0, 0, W, y0 + 20 + 164 + 200 + 8 * 18 + 10)).save(out)


def fig_scroll(work, a, b, step, out):
    s = session(work)
    frames = list(range(a, b + 1, step))
    scale = 2
    cw, ch = (19 * 8 + 16) * scale, 48 * scale
    cols = W // (cw + 10)
    rows = (len(frames) + cols - 1) // cols
    im = Image.new('RGB', (W, 60 + rows * (ch + 30) + 160), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'The scroller window $402C (columns 12-30, lines 8-39), c1 frames {a}-{b}, every {step}th frame',
           font=ft, fill=FG)
    for i, fr in enumerate(frames):
        m = screen_at(s, fr)
        v = mem(s, fr, 0x63C7, 8)
        p = K.render_screen(m).crop((88, 0, 88 + 19 * 8 + 16, 48)).resize((cw, ch), Image.NEAREST)
        x = 14 + (i % cols) * (cw + 10)
        y = 40 + (i // cols) * (ch + 30)
        d.text((x, y), f'{fr}: line {v[5]}, delay {v[6]}', font=fs, fill=FG)
        im.paste(p, (x, y + 14))
    y = 40 + rows * (ch + 30)
    notes(d, y, [
        'How to read: screen lines 0-47 of columns 11-31 at the start of each frame (ScrollLine $63CC and ScrollDelay',
        '$63CD sampled there). Every ScrollDelay interrupts InterruptScroll $9640 copies 31 lines of 19 bytes one pixel',
        'line up, then draws pixel row ScrollLine of the next 19 characters of the message into the bottom line',
        '(Font - $101 + 8 x code + line). After 8 lines the delay is 15 instead of 5: a full text line rests on screen.',
        'With no message (ScrollText 0, here from 14400) the copy goes on and blank lines rise: the text leaves upwards.',
        f'From c1: python3 tools/fig_render.py scroll --work W --from {a} --to {b} --step {step} --out {out}'], f, 5)
    im.crop((0, 0, W, y + 6 * 18 + 8)).save(out)


def fig_exhaust(work, a, b, out):
    s = session(work)
    scale = 4
    frames = list(range(a, b + 1))
    v0 = mem(s, a, 0x6359, 2)
    col, y = v0[0], v0[1]
    x0 = max(0, col - 2) * 8
    y0 = min(max(48, y - 8), 192 - 64)
    cw, ch = 7 * 8, 64
    per = W // (cw * scale // 2 + 10)
    im = Image.new('RGB', (W, 700), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'The exhaust under the droid, c1 frames {a}-{b} (screen at each frame start)', font=ft, fill=FG)
    sc = 2
    px_w = cw * sc
    cols = W // (px_w + 8)
    yy = 40
    for i, fr in enumerate(frames):
        m = screen_at(s, fr)
        r = mem(s, fr, 0x65E5, 24)
        p = K.render_screen(m).crop((x0, y0, x0 + cw, y0 + ch)).resize((px_w, ch * sc), Image.NEAREST)
        x = 14 + (i % cols) * (px_w + 8)
        y1 = yy + (i // cols) * (ch * sc + 40)
        d.text((x, y1), f'{fr}', font=fs, fill=FG)
        d.text((x, y1 + 13), ' '.join(f'{r[k * 3 + 1]:02X}' for k in range(1, 8, 2)), font=fs, fill=DIM)
        im.paste(p, (x, y1 + 28))
    y = yy + ((len(frames) + cols - 1) // cols) * (ch * sc + 40)
    notes(d, y, [
        'How to read: a crop of 7 x 8 columns round the droid at each frame start, 2 x; under the frame number, the',
        'middle bytes of the odd rows of ExhaustRows $65E5 (the even rows stay 0). DroidExhaust $8DD2 XORs the 8 rows',
        'x 3 bytes onto the screen 5 character rows below the droid\'s top, before MoveDroid (erase) and after it',
        '(draw), skipping wall and item cells and colouring each cell $45; ExhaustStep $8E7E rotates the rows, and',
        'ExhaustPick $8EAC gives each flame a random life of 8-39 steps (Random AND $1C).',
        f'From c1: python3 tools/fig_render.py exhaust --work W --from {a} --to {b} --out {out}'], f, 5)
    im.crop((0, 0, W, y + 6 * 18 + 8)).save(out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['sheets', 'tiles', 'room', 'list', 'shift', 'mirror', 'scroll', 'exhaust'])
    p.add_argument('--work')
    p.add_argument('--room', type=int, default=84)
    p.add_argument('--frame', type=int)
    p.add_argument('--from', dest='a', type=int)
    p.add_argument('--to', dest='b', type=int)
    p.add_argument('--step', type=int, default=1)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.what == 'sheets':
        fig_sheets(args.out)
    elif args.what == 'tiles':
        fig_tiles(args.out)
    elif args.what == 'room':
        fig_room(args.work, args.room, args.frame, args.out)
    elif args.what == 'list':
        fig_list(args.work, args.frame, args.out)
    elif args.what == 'shift':
        fig_shift(args.out)
    elif args.what == 'mirror':
        fig_mirror(args.out)
    elif args.what == 'scroll':
        fig_scroll(args.work, args.a, args.b, args.step, args.out)
    else:
        fig_exhaust(args.work, args.a, args.b, args.out)


if __name__ == '__main__':
    main()

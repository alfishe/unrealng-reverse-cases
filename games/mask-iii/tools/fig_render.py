#!/usr/bin/env python3
"""The figures of doc 6 (rendering), drawn from the game image (build/game.bin) and src/res.

    python3 tools/fig_render.py room --out docs/img/render/room-bytes.png
    python3 tools/fig_render.py zones --out docs/img/render/zones.png
    python3 tools/fig_render.py frames --out docs/img/render/matt-frames.png
    python3 tools/fig_render.py shift --out docs/img/render/shift-mask.png
    python3 tools/fig_render.py memory --out docs/img/render/buffers.png

room: room 0, screen 0 from its map bytes (RoomMaps $7600) through the blocks (Blocks $8500) and the zone 0 characters
($E000, attributes $EF00) to the picture, with one block and one character worked byte by byte. zones: the four zone
character sets as DrawRoom finds them live at $E000 after SwapZone $A198, solid characters (attribute bit 7) marked.
frames: Matt's ten frames (MattRun $CD60, MattJump $D160, MattCrouch $D1E0) with the mask MakeMask $A777 makes of
each. shift: one frame row through MakeMask, the shift tables of BuildTables $A860 and DrawShifted $A6FE onto a
background. memory: the renderer's buffers at $E000-$FFFF.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_controls as F  # noqa: E402
import roommap  # noqa: E402

K = F.K
WIDTH = F.WIDTH
GRID = (70, 70, 80)
HILITE = (250, 200, 60)


def zx(attr, bright=None):
    br = bool(attr & 0x40) if bright is None else bright
    return roommap.colour(attr & 7, br), roommap.colour((attr >> 3) & 7, br)


def char_image(mem, base, attr, scale):
    """one 8 x 8 character from mem[base], ink and paper from attr, scale x"""
    ink, paper = zx(attr & 0x47)
    im = Image.new('RGB', (8, 8))
    px = im.load()
    for y in range(8):
        b = mem[base + y]
        for x in range(8):
            px[x, y] = ink if b & (0x80 >> x) else paper
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def bits_image(rows, width_bits, scale, on=(235, 235, 235), off=(30, 30, 36), grid=True):
    """rows of ints (width_bits each, top bit left) as a bit grid"""
    w, h = width_bits * scale, len(rows) * scale
    im = Image.new('RGB', (w + 1, h + 1), GRID)
    d = ImageDraw.Draw(im)
    for y, v in enumerate(rows):
        for x in range(width_bits):
            c = on if v & (1 << (width_bits - 1 - x)) else off
            d.rectangle((x * scale + 1, y * scale + 1, x * scale + scale - 1 if grid else x * scale + scale,
                         y * scale + scale - 1 if grid else y * scale + scale), fill=c)
    return im


# ---------------------------------------------------------------------------------------------------------------
# room: map bytes to picture

def cmd_room(args):
    mem = F.image()
    room, scr = 0, 0
    base = 0x7600 + 240 * room + 8 * scr
    bx0, by0 = args.block_col, args.block_row
    f, fs, fb = K.font(15), K.font(13), K.font(17)
    im = Image.new('RGB', (WIDTH, 900), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'Room 0, screen 0 drawn from its bytes: map -> blocks -> characters -> screen (game image as loaded)')

    # 1. the map bytes, 8 x 5 blocks
    x0, y0, cw, ch = 12, 44, 46, 30
    d.text((x0, y0), 'RoomMaps $7600 + 240 x room + 8 x screen: 8 x 5 blocks', fill=K.TEXT,
           font=fs)
    y0 += 22
    for by in range(5):
        d.text((x0, y0 + by * ch + 7), '$%04X' % (base + 48 * by), fill=K.DIM, font=fs)
        for bx in range(8):
            v = mem[base + 48 * by + bx]
            r = (x0 + 52 + bx * cw, y0 + by * ch, x0 + 52 + bx * cw + cw - 3, y0 + by * ch + ch - 3)
            sel = (bx, by) == (bx0, by0)
            d.rectangle(r, outline=HILITE if sel else GRID, width=2 if sel else 1)
            d.text((r[0] + 10, r[1] + 6), '%02X' % v, fill=HILITE if sel else K.TEXT, font=f)
    note_y = y0 + 5 * ch + 6
    F.wrap(d, 'Map rows 0 and 1 (the top half of block row 0) are never shown: DrawRoom fills the character map '
           'from $F080, FlushDirty shows rows 2-19, from $F0C0.', x0, note_y, 430, fs,
           fill=K.DIM)

    # 2. the chosen block: 16 codes and their characters
    blk = mem[base + 48 * by0 + bx0]
    bb = 0x8500 + 16 * blk
    x1, y1 = 520, 44
    d.text((x1, y1), 'Block $%02X: Blocks $8500 + 16 x $%02X = $%04X' % (blk, blk, bb), fill=K.TEXT,
           font=fs)
    sc = 6
    for cy in range(4):
        for cx in range(4):
            code = mem[bb + 4 * cy + cx]
            attr = mem[0xEF00 + code]
            cim = char_image(mem, 0xE000 + 8 * code, attr, sc)
            px, py = x1 + cx * 132, y1 + 24 + cy * 62
            im.paste(cim, (px, py))
            d.rectangle((px - 1, py - 1, px + 8 * sc, py + 8 * sc), outline=GRID)
            d.text((px + 8 * sc + 6, py + 2), '$%02X' % code, fill=K.TEXT, font=f)
            d.text((px + 8 * sc + 6, py + 22), 'a $%02X' % attr, fill=K.DIM, font=fs)

    # 3. one character byte by byte
    code = mem[bb + 4 * args.char_row + args.char_col]
    attr = mem[0xEF00 + code]
    y2 = 330
    d.text((x0, y2), 'Character $%02X: ZoneChars $E000 + 8 x $%02X = $%04X, attribute ZoneAttrs $EF00 + $%02X = $%02X'
           % (code, code, 0xE000 + 8 * code, code, attr), fill=K.TEXT, font=fs)
    rows = [mem[0xE000 + 8 * code + i] for i in range(8)]
    for i, v in enumerate(rows):
        d.text((x0, y2 + 26 + i * 20), '$%04X  $%02X  %s' % (0xE000 + 8 * code + i, v, format(v, '08b')),
               fill=K.TEXT, font=f)
    ink, paper = zx(attr & 0x47)
    bim = bits_image(rows, 8, 20, on=ink, off=paper)
    im.paste(bim, (300, y2 + 24))
    lines = ['attribute $%02X = %s' % (attr, format(attr, '08b')),
             'bit 7 = %d: %s' % (attr >> 7, 'solid (IsSolid $B993 reads it)' if attr & 0x80 else 'not solid'),
             'bit 6 = %d: bright' % ((attr >> 6) & 1), 'bits 3-5 = %d: paper' % ((attr >> 3) & 7),
             'bits 0-2 = %d: ink' % (attr & 7),
             'FlushDirty writes $%02X AND $47 = $%02X:' % (attr, attr & 0x47), 'no flash, black paper, the solid',
             'flag never reaches the screen']
    for i, t in enumerate(lines):
        d.text((480, y2 + 26 + i * 20), t, fill=K.TEXT if i < 5 else HILITE, font=fs)

    # 4. the screen
    y3 = 548
    pic = roommap.draw_screen(mem, room, scr, scale=2)
    im.paste(pic, (x0, y3 + 22))
    d.text((x0, y3), 'The play area: screen rows 0-17 = map rows 2-19, scale 2', fill=K.TEXT, font=fs)
    # the chosen block on screen: map rows 4*by0-2 .. 4*by0+1 visible from row 0
    sx = x0 + bx0 * 32 * 2
    sy = y3 + 22 + (by0 * 32 - 16) * 2
    d.rectangle((sx, max(y3 + 22, sy), sx + 64, sy + 64), outline=HILITE, width=2)
    F.wrap(d, 'The yellow frame is block $%02X; the map is 32 characters wide, so a block row writes 4 bytes, then '
           'adds $1C to step to the next character row (LDI x 4, +$1C, three times, at $A928).' % blk,
           x0 + 530, y3 + 30, 490, fs)
    F.wrap(d, 'The byte path for a whole screen: 40 map bytes, 640 block bytes, 576 visible characters of 8 bytes '
           'plus an attribute each; DrawRoom then marks all 576 cells dirty and FlushDirty copies them.',
           x0 + 530, y3 + 130, 490, fs, fill=K.DIM)
    im = im.crop((0, 0, WIDTH, y3 + 22 + 288 + 12))
    im.save(args.out)
    print(args.out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# zones

def cmd_zones(args):
    f, fs = K.font(15), K.font(13)
    sc = 3
    names = ['zone 0: the surface (rooms 0-3)', 'zone 1: the caverns (rooms 4-6)', 'zone 2: the moon (rooms 7-9)',
             'zone 3: the base (rooms 10-15)']
    cell = 8 * sc + 1
    pw = 16 * cell
    im = Image.new('RGB', (WIDTH, 44 + 2 * (pw + 40) + 50), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'The four zone character sets as SwapZone $A198 makes them live at $E000 (attributes $EF00)')
    for z in range(4):
        mem = roommap.res_memory(z)
        ox = 12 + (z % 2) * (pw + 110)
        oy = 44 + (z // 2) * (pw + 40)
        oy += 22
        solid = 0
        for n in range(256):
            a = mem[0xEF00 + n]
            cim = char_image(mem, 0xE000 + 8 * n, a, sc)
            px, py = ox + (n % 16) * cell, oy + (n // 16) * cell
            im.paste(cim, (px, py))
            if a & 0x80:
                solid += 1
                d.rectangle((px, py, px + 8 * sc - 1, py + 8 * sc - 1), outline=(230, 60, 60))
        d.text((ox, oy - 22), '%s, %d solid' % (names[z], solid), fill=K.TEXT, font=f)
        for r in range(0, 16, 2):
            d.text((ox + pw + 6, oy + r * cell + 5), '$%X0' % r, fill=K.DIM, font=fs)
    F.wrap(d, 'Each character in its own ink on black paper, sixteen a row (character n at row n / 16). A red frame '
           'marks attribute bit 7, the solid flag IsSolid $B993 tests; FlushDirty masks it off with AND $47.',
           12, im.height - 44, WIDTH - 24, fs, fill=K.DIM)
    im.save(args.out)
    print(args.out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# frames and masks

def frame_rows(mem, addr, w, h):
    """a w x h character frame stored column by column -> list of h*8 ints of w*8 bits"""
    rows = []
    for y in range(h * 8):
        v = 0
        for c in range(w):
            v = (v << 8) | mem[addr + c * h * 8 + y]
        rows.append(v)
    return rows


def dilate(rows, bits):
    """MakeMask: OR of the row above, the row and the row below, then the $F700 table (b | b<<1 | b>>1) per byte"""
    out = []
    mask = (1 << bits) - 1
    for y in range(len(rows)):
        v = rows[y] | (rows[y - 1] if y else 0) | (rows[y + 1] if y + 1 < len(rows) else 0)
        # the table works byte by byte: bits do not cross byte edges
        r = 0
        for c in range(bits // 8):
            b = (v >> (bits - 8 - 8 * c)) & 0xFF
            r = (r << 8) | ((b | (b << 1) | (b >> 1)) & 0xFF)
        out.append(r & mask)
    return out


def cmd_frames(args):
    mem = F.image()
    f, fs = K.font(14), K.font(12)
    frames = [('run %d' % i, 0xCD60 + 128 * i) for i in range(8)] + [('$D160', 0xD160), ('$D1E0', 0xD1E0)]
    sc = 3
    fw = 32 * sc + 1
    gap = 4
    im = Image.new('RGB', (WIDTH, 44 + 2 * (fw + 30) + 70), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, "Matt's ten frames (4 x 4 characters, 128 bytes each) and the masks MakeMask $A777 builds from them")
    for i, (name, a) in enumerate(frames):
        rows = frame_rows(mem, a, 4, 4)
        mrows = dilate(rows, 32)
        x = 12 + i * (fw + gap + 2)
        fim = bits_image(rows, 32, sc, grid=False)
        mim = bits_image(mrows, 32, sc, on=(90, 150, 250), grid=False)
        # the frame drawn over its mask
        com = mim.copy()
        px = com.load()
        for y, v in enumerate(rows):
            for b in range(32):
                if v & (1 << (31 - b)):
                    for yy in range(sc):
                        for xx in range(sc):
                            px[b * sc + xx + 1, y * sc + yy + 1] = (240, 240, 240)
        im.paste(fim, (x, 66))
        im.paste(com, (x, 66 + fw + 30))
        d.text((x, 46), name, fill=K.TEXT, font=f)
        d.text((x, 66 + fw + 6), '$%04X' % a, fill=K.DIM, font=fs)
    F.wrap(d, 'Top: the frames. SelectFrame $A349 takes run frame ((x / 4) AND 7) (x negated when facing left), so '
           'one frame lasts 4 x units = 8 pixels of walking; $D160 is the jump frame (states 8, 10, 12), $D1E0 the '
           'crouch (state 4). Bottom: the mask (blue) under the frame: the frame grown by one pixel up, down, left '
           'and right. Where the mask is set and the frame is not, the background is cleared to black: the dark '
           'outline that keeps Matt readable on any scenery.', 12, 66 + 2 * fw + 40, WIDTH - 24, fs)
    im.save(args.out)
    print(args.out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# one row through mask, shift and draw

def cmd_shift(args):
    mem = F.image()
    f, fs = K.font(14), K.font(13)
    a = 0xCD60
    rows = frame_rows(mem, a, 4, 4)
    mrows = dilate(rows, 32)
    y = args.row
    sprite, mask = rows[y], mrows[y]
    bg = 0x55AA55AA55 & 0xFFFFFFFFFF
    sc = 14
    im = Image.new('RGB', (WIDTH, 560), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'One row of run frame 0 (line %d) drawn at x AND 3 = 0..3: mask, shift tables, background' % y)
    yy = 44
    for s in range(4):
        shift = 2 * s
        sp = (sprite << 8) >> shift
        mk = (mask << 8) >> shift
        out = (bg & ~mk & 0xFFFFFFFFFF) | sp
        d.text((12, yy), 'x AND 3 = %d: %s' % (s, 'DrawAligned $A688, 4 bytes, no table' if s == 0 else
                                               'DrawShifted $A6FE, tables $%02X00 (left part) and $%02X00 (right '
                                               'part), %d pixels' % (0xF6 + 2 * s, 0xF7 + 2 * s, shift)),
               fill=K.TEXT, font=f)
        x = 220
        for label, v, col in (('frame', sp, (240, 240, 240)), ('mask', mk, (90, 150, 250)),
                              ('screen', out, (240, 240, 240))):
            d.text((12 if label == 'frame' else 12, yy + 22), '', font=fs)
            bim = bits_image([v], 40, sc, on=col)
            im.paste(bim, (x, yy + 22))
            d.text((x - 60, yy + 24), label, fill=K.DIM, font=fs)
            yy += sc + 6
        for c in range(5):
            d.line((x + c * 8 * sc, yy - 3 * (sc + 6) + 20, x + c * 8 * sc, yy), fill=HILITE)
        yy += 36
    F.wrap(d, 'Five bytes wide for four bytes of frame: the shift spills into the next character column, which is '
           'why DrawObject takes (w + 1) x (h + 1) cells. The screen byte is (background AND NOT mask) OR frame. The '
           'background here is a test pattern; in the game it is the 8 bytes DrawObject copied from the zone '
           'character the cell held. BuildTables $A860 makes $F800/$F900 (2 px), $FA00/$FB00 (4 px), $FC00/$FD00 '
           '(6 px): for byte b, page $F8+2k holds b >> 2(k+1), page $F9+2k the bits pushed out. An x unit is 2 '
           'pixels, so a sprite moves on a 2-pixel grid and needs only these three shifts.', 12, yy, WIDTH - 24, fs)
    im.save(args.out)
    print(args.out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# the buffers

AREAS = [
    (0xE000, 0xE800, 'ZoneChars: live zone set, 256 characters', (60, 140, 90)),
    (0xE800, 0xEE00, 'sprite characters, rebuilt each pass', (190, 120, 60)),
    (0xEE00, 0xEF00, 'their attributes', (150, 100, 60)),
    (0xEF00, 0xF000, 'ZoneAttrs (bit 7 = solid)', (40, 110, 70)),
    (0xF000, 0xF080, 'mask buffer (MakeMask)', (90, 150, 250)),
    (0xF080, 0xF300, 'character map 32 x 20 ($F0C0 = row 0)', (220, 200, 70)),
    (0xF300, 0xF3C0, 'mirrored frame (MirrorFrame)', (120, 160, 240)),
    (0xF3C0, 0xF600, 'dirty marks 32 x 18', (230, 80, 70)),
    (0xF600, 0xF700, 'bit reverse', (150, 150, 160)),
    (0xF700, 0xF800, 'dilate', (110, 110, 200)),
    (0xF800, 0xFE00, 'shift tables 2 / 4 / 6 px', (170, 120, 210)),
]


def cmd_memory(args):
    f, fs = K.font(14), K.font(13)
    im = Image.new('RGB', (WIDTH, 300), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    F.title(d, 'The renderer\'s memory, $E000-$FDFF: what each buffer holds during a pass')
    x0, x1, y0 = 12, WIDTH - 12, 60
    span = 0xFE00 - 0xE000
    for i, (lo, hi, name, col) in enumerate(AREAS):
        a = x0 + (lo - 0xE000) * (x1 - x0) // span
        b = x0 + (hi - 0xE000) * (x1 - x0) // span
        d.rectangle((a, y0, b - 1, y0 + 40), fill=col)
        ly = y0 + 60 + (i % 6) * 28
        lx = x0 + (i // 6) * 520
        d.rectangle((lx, ly + 2, lx + 14, ly + 16), fill=col)
        d.text((lx + 22, ly), '$%04X-$%04X  %s' % (lo, hi - 1, name), fill=K.TEXT, font=fs)
    d.text((x0, y0 - 18), '$E000', fill=K.DIM, font=fs)
    d.text((x1 - 44, y0 - 18), '$FE00', fill=K.DIM, font=fs)
    im.save(args.out)
    print(args.out, im.size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    r = sub.add_parser('room')
    r.add_argument('--block-col', type=int, default=0)
    r.add_argument('--block-row', type=int, default=1)
    r.add_argument('--char-col', type=int, default=2)
    r.add_argument('--char-row', type=int, default=1)
    r.add_argument('--out', required=True)
    for name in ('zones', 'frames', 'memory'):
        s = sub.add_parser(name)
        s.add_argument('--out', required=True)
    s = sub.add_parser('shift')
    s.add_argument('--row', type=int, default=10)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'room': cmd_room, 'zones': cmd_zones, 'frames': cmd_frames, 'shift': cmd_shift, 'memory': cmd_memory}[
        args.cmd](args)


if __name__ == '__main__':
    main()

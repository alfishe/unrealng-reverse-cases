#!/usr/bin/env python3
"""Doc 06: a sprite frame decoded byte by byte, plain and mirrored through the bit-reversal table at `$5B00`; and the
colour clash: a part of a screenshot enlarged, with its cell grid and the two colours of each cell.

    python3 tools/fig_render.py sprite 1 docs/img/render/sprite-mirror.png
    python3 tools/fig_render.py clash docs/img/play/level1-start.png docs/img/render/clash.png 0 6 14 11

A frame is 126 bytes at SpriteFrames `$8401` + 126 F: 21 rows of 6 bytes in the order the drawers POP them
(OR3, OR2, OR1, AND1, AND3, AND2; column 1 is the left one). The screen byte becomes (screen AND mask) OR pixels. The
mirrored frame swaps columns 1 and 3 and reverses the bits of every byte, as SpriteAlignedMirror `$A444` does through
the table BuildMirrorTable `$AB6A` fills (`$5B00` + n = n with its bits reversed). The image is build/game.bin
(`$5B00` on); the table is computed here as the routine computes it.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 75)
MIRROR = [int(f'{n:08b}'[::-1], 2) for n in range(256)]


def frame_rows(img, f):
    a = 0x8401 + 126 * f - 0x5B00
    raw = img[a:a + 126]
    rows = []
    for r in range(21):
        or3, or2, or1, and1, and3, and2 = raw[6 * r:6 * r + 6]
        rows.append(((and1, or1), (and2, or2), (and3, or3)))
    return rows


def mirrored(rows):
    return [tuple((MIRROR[m], MIRROR[p]) for m, p in reversed(row)) for row in rows]


def draw_frame(d, rows, ox, oy, cell, bg=(0, 160, 200)):
    """Over a cyan background: mask 0 and pixel 1 draw ink; mask 1 keeps the background; mask 0 pixel 0 is black"""
    for y, row in enumerate(rows):
        for c, (m, p) in enumerate(row):
            for b in range(8):
                bit = 7 - b
                keep, ink = m >> bit & 1, p >> bit & 1
                col = (20, 200, 60) if ink else (bg if keep else (0, 0, 0))
                x = ox + (8 * c + b) * cell
                d.rectangle((x, oy + y * cell, x + cell - 2, oy + y * cell + cell - 2), fill=col)


def cmd_sprite(f, png):
    img = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    rows = frame_rows(img, f)
    mrows = mirrored(rows)
    W, cell = 1050, 12
    H = 110 + 21 * cell + 290
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    addr = 0x8401 + 126 * f
    d.text((12, 10), f'Sprite frame {f} at ${addr:04X}: 21 rows of 3 (mask, pixels) pairs, and its mirror image',
           fill=TEXT, font=K.font(21))
    d.text((12, 42), 'Green: pixels (OR). Black: mask 0, pixel 0 (cleared). Cyan: mask 1 (background kept). '
           'tools/fig_render.py', fill=DIM, font=K.font(14))
    oy = 80
    d.text((20, oy - 4), 'as stored (bit 0 of +6 clear)', fill=TEXT, font=K.font(15))
    draw_frame(d, rows, 20, oy + 20, cell)
    ox2 = 20 + 24 * cell + 40
    d.text((ox2, oy - 4), 'mirrored (bit 0 of +6 set)', fill=TEXT, font=K.font(15))
    draw_frame(d, mrows, ox2, oy + 20, cell)
    # the bytes of row 10: as stored and mirrored
    tx = ox2 + 24 * cell + 30
    r = 10
    raw = img[addr - 0x5B00 + 6 * r:addr - 0x5B00 + 6 * r + 6]
    d.text((tx, oy - 4), f'row {r}: the 6 bytes as popped', fill=TEXT, font=K.font(15))
    names = ['OR3', 'OR2', 'OR1', 'AND1', 'AND3', 'AND2']
    for i, (n, v) in enumerate(zip(names, raw)):
        d.text((tx, oy + 22 + 22 * i), f'{n:<5} ${v:02X}  {v:08b}', fill=TEXT, font=K.font(14))
    (m1, p1), (m2, p2), (m3, p3) = rows[r]
    y = oy + 22 + 22 * 6 + 14
    d.text((tx, y), 'mirrored: column 3 first, each byte', fill=TEXT, font=K.font(15))
    d.text((tx, y + 20), 'through $5B00 + byte:', fill=TEXT, font=K.font(15))
    for i, (name, v) in enumerate((('AND3', m3), ('OR3', p3), ('AND1', m1), ('OR1', p1))):
        d.text((tx, y + 44 + 22 * i), f'{name:<5} ${v:02X} -> ${MIRROR[v]:02X}  {MIRROR[v]:08b}', fill=TEXT,
               font=K.font(14))
    # the screen rule
    by = oy + 20 + 21 * cell + 30
    d.text((12, by), 'A byte on screen: new = (old AND mask) OR pixels. Row 10, column 1, over a background byte $AA:',
           fill=TEXT, font=K.font(15))
    old = 0xAA
    new = old & m1 | p1
    lines = [f'old     ${old:02X}  {old:08b}', f'AND1    ${m1:02X}  {m1:08b}', f'and     ${old & m1:02X}  {old & m1:08b}',
             f'OR1     ${p1:02X}  {p1:08b}', f'new     ${new:02X}  {new:08b}']
    for i, ln in enumerate(lines):
        d.text((30, by + 26 + 22 * i), ln, fill=TEXT, font=K.font(15))
    d.text((420, by + 26), 'The mirror table: $5B00 + n = n with its bits reversed.', fill=TEXT, font=K.font(15))
    for i, n in enumerate((0x01, 0x0F, 0x3C, 0xA0, 0xE6)):
        d.text((420, by + 52 + 22 * i), f'$5B{n:02X} = ${MIRROR[n]:02X}   {n:08b} -> {MIRROR[n]:08b}', fill=TEXT,
               font=K.font(15))
    out.save(png)
    print(png, out.size)


SPECCY = {(0, 0, 0): 'K', (0, 0, 1): 'B', (1, 0, 0): 'R', (1, 0, 1): 'M', (0, 1, 0): 'G', (0, 1, 1): 'C', (1, 1, 0): 'Y',
          (1, 1, 1): 'W'}


def cmd_clash(src, png, col, row, cols, rows):
    """cells col..col+cols-1, rows row..row+rows-1 of a screenshot (any whole scale of 256 x 192), enlarged; each cell
    labelled with the colours it shows (one colour: ink and paper alike, or a cell of one colour)"""
    im = Image.open(src).convert('RGB')
    im = im.resize((256, 192), Image.NEAREST)
    z, top = 6, 40
    out = Image.new('RGB', (cols * 8 * z + 40, rows * 8 * z + top + 56), BG)
    d = ImageDraw.Draw(out)
    crop = im.crop((col * 8, row * 8, (col + cols) * 8, (row + rows) * 8)).resize((cols * 8 * z, rows * 8 * z),
                                                                                   Image.NEAREST)
    out.paste(crop, (20, top))
    d.text((20, 10), f'{os.path.basename(src)}: columns {col}-{col + cols - 1}, char rows {row}-{row + rows - 1}',
           fill=TEXT, font=K.font(15))
    for r in range(rows):
        for c in range(cols):
            x, y = 20 + c * 8 * z, top + r * 8 * z
            d.rectangle((x, y, x + 8 * z, y + 8 * z), outline=GRID)
            names = sorted({SPECCY[tuple(int(v > 100) for v in im.getpixel((col * 8 + c * 8 + i, row * 8 + r * 8 + j)))]
                            for i in range(8) for j in range(8)})
            label = ''.join(names)
            d.rectangle((x + 2, y + 2, x + 6 + 7 * len(label), y + 16), fill=BG)
            d.text((x + 4, y + 2), label, fill=TEXT, font=K.font(11))
    d.text((20, top + rows * 8 * z + 8), 'The colours found in each cell: K black, B blue, C cyan, G green, W white.',
           fill=DIM, font=K.font(15))
    d.text((20, top + rows * 8 * z + 30), 'Never more than two (ink and paper); a sprite adds none of its own.',
           fill=DIM, font=K.font(15))
    out.save(png)
    print(png, out.size)


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == 'sprite':
        cmd_sprite(int(sys.argv[2]), sys.argv[3])
    elif len(sys.argv) >= 8 and sys.argv[1] == 'clash':
        cmd_clash(sys.argv[2], sys.argv[3], *map(int, sys.argv[4:8]))
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The 32 caves drawn whole from the game's own data, and the cell graphics as a sheet.

    python3 tools/fig_caves.py --out docs/img [--states work/stage1/rzx/start]

A cave N (1-32) is 314 bytes at `$BEC6 + N * $13A` in the loaded image: 300 bytes of cells packed two to a byte, the
low nibble first, unpacked row by row into 30 x 20 cells (`$82B6-$82E5`), then 14 parameter bytes. A cell value V
(0-31) is drawn by `$8F60` from the graphic whose address is the word at `$8000 + 2 * V`: 36 bytes, the four
attributes of its 2 x 2 character cells (top left, top right, bottom right, bottom left), then 32 pixel bytes, two a
line, left then right on even lines and right then left on odd ones. Some table entries change per cave (the
cave's start sets them), so each cave is drawn with the table of a state at that cave's start: the RZX archive's
start snapshot of the cave (`earthNN.rzx.001.z80`, the cave's intro; `earth01` starts at the menu, so cave 1 is
drawn from work/stage1/probe/level1.szx, cave 1 in play after c1's load).

Writes maps/cave-NN.png (480 x 320, one pixel a pixel), maps/caves.png (all 32, labelled) and
sprites/cells-cave01.png (each table entry with its value and address, x3).
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import res_formats  # noqa: E402
CELL_RES = ('cells-a', 'cells-b', 'extra-a', 'extra-b', 'extra-c', 'extra-d', 'blank')

PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
W, H = 30, 20


def memory(path):
    return open(path, 'rb').read()


def res_addresses():
    """{resource name: its entry's address} from the @res lines of src/game/game.ann"""
    out, addr = {}, None
    for ln in open(os.path.join(CASE, 'src', 'game', 'game.ann'), encoding='utf-8'):
        m = re.match(r'\$([0-9A-F]{4}) [a-z]+ ', ln)
        if m:
            addr = int(m.group(1), 16)
        elif ln.startswith('@res ') and addr is not None:
            out[ln.split()[1]] = addr
    return out


def resource_memory():
    """the loaded image with every cell graphics resource of src/res put back at its address"""
    m = bytearray(memory(os.path.join(CASE, 'work', 'mkgame', 'original.bin')))
    for name, addr in res_addresses().items():
        if name.startswith('graphics/') and os.path.exists(os.path.join(res_formats.RES, name[:-4] + '.png')) \
                and name[:-4].split('/')[1] in CELL_RES:
            d = res_formats.read_cells(name)
            m[addr:addr + len(d)] = d
    return m


def cave_setup(m, params):
    """CaveSetup $9313: the cave's earth and wall graphics into the table, its four colours into four graphics
    (SetGraphicColour $9305: attributes bright, plain, plain, bright)"""
    m = bytearray(m)
    m[0x800C:0x800E] = params['earth_graphic'].to_bytes(2, 'little')
    m[0x800A:0x800C] = params['wall_graphic'].to_bytes(2, 'little')
    for field, a in (('door_colour', 0x9B08), ('boulder_colour', 0x9B2C), ('wall1_colour', 0x9CB8),
                     ('earth_colour', 0x9B50)):
        c = params[field]
        m[a:a + 4] = bytes((c | 0x40, c & 0x3F, c & 0x3F, c | 0x40))
    return m


def graphic(m, v):
    """16 x 16 RGB pixels of cell value v (None when the table entry is 0)"""
    a = m[0x8000 + 2 * v] | m[0x8001 + 2 * v] << 8
    if not a:
        return None, 0
    attrs = m[a:a + 4]
    px = m[a + 4:a + 36]
    rows = [[0, 0] for _ in range(16)]
    for line in range(16):
        b0, b1 = px[2 * line], px[2 * line + 1]
        rows[line] = [b0, b1] if line % 2 == 0 else [b1, b0]
    cell_attr = {(0, 0): attrs[0], (0, 1): attrs[1], (1, 1): attrs[2], (1, 0): attrs[3]}
    img = Image.new('RGB', (16, 16))
    for y in range(16):
        for x in range(16):
            at = cell_attr[(y // 8, x // 8)]
            pal = BRIGHT if at & 64 else PAL
            on = rows[y][x // 8] >> (7 - x % 8) & 1
            img.putpixel((x, y), pal[at & 7] if on else pal[at >> 3 & 7])
    return img, a


def draw_cave(m, cells):
    img = Image.new('RGB', (W * 16, H * 16))
    cache = {}
    for i, v in enumerate(cells):
        if v not in cache:
            cache[v] = graphic(m, v)[0]
        if cache[v]:
            img.paste(cache[v], (i % W * 16, i // W * 16))
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img'))
    a = ap.parse_args()
    base = resource_memory()
    os.makedirs(os.path.join(a.out, 'maps'), exist_ok=True)
    os.makedirs(os.path.join(a.out, 'sprites'), exist_ok=True)
    names = [ln for ln in open(os.path.join(res_formats.RES, 'texts', 'cave-names.txt'), encoding='utf-8')
             if ln.startswith('"')]
    names = [res_formats.unquote(ln.strip()).decode('latin-1').strip() for ln in names]
    sheet = Image.new('RGB', (4 * 244, 8 * 182), (24, 24, 30))
    d = ImageDraw.Draw(sheet)
    caves = res_formats.read_caves()
    for n, (params, cells) in enumerate(caves, 1):
        cave = draw_cave(cave_setup(base, params), cells)
        cave.save(os.path.join(a.out, 'maps', f'cave-{n:02d}.png'))
        x, y = (n - 1) % 4 * 244 + 2, (n - 1) // 4 * 182 + 2
        sheet.paste(cave.resize((240, 160)), (x, y + 18))
        d.text((x, y + 2), f'{n:02d} {names[n - 1] if n <= len(names) else ""}', fill=(235, 235, 235))
    sheet.save(os.path.join(a.out, 'maps', 'caves.png'))
    m = cave_setup(base, caves[0][0])
    tiles = Image.new('RGB', (8 * 80, 4 * 84), (24, 24, 30))
    d = ImageDraw.Draw(tiles)
    for v in range(32):
        g, addr = graphic(m, v)
        x, y = v % 8 * 80 + 16, v // 8 * 84 + 4
        if g:
            tiles.paste(g.resize((48, 48), Image.NEAREST), (x, y))
        d.text((x - 8, y + 52), f'{v:2d} ${addr:04X}' if addr else f'{v:2d} none', fill=(235, 235, 235))
    tiles.save(os.path.join(a.out, 'sprites', 'cells-cave01.png'))
    print('caves 1-%d, cells sheet written under' % len(caves), a.out)


if __name__ == '__main__':
    main()

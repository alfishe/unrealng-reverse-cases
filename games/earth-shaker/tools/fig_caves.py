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
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)

PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
W, H = 30, 20
CAVE1 = os.path.join(CASE, 'work', 'stage1', 'probe', 'level1.szx')  # cave 1 in play (the RZX's earth01 starts at the menu)


def memory(path):
    if path.endswith('.bin'):
        return open(path, 'rb').read()
    if path.endswith('.szx'):
        sys.path.insert(0, HERE)
        import szx
        return bytes(szx.read(path)[0])
    from skoolkit.snapshot import Snapshot
    return bytes(0x4000) + bytes(Snapshot.get(path).ram())


def cave_cells(m, n):
    base = 0xBEC6 + n * 0x13A
    cells = []
    for b in m[base:base + 300]:
        cells += [b & 15, b >> 4]
    return cells, m[base + 300:base + 314]


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


def draw_cave(m, n):
    cells, _ = cave_cells(m, n)
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
    ap.add_argument('--states', default=os.path.join(CASE, 'work', 'stage1', 'rzx', 'start'))
    a = ap.parse_args()
    image = memory(os.path.join(CASE, 'work', 'mkgame', 'original.bin'))
    os.makedirs(os.path.join(a.out, 'maps'), exist_ok=True)
    os.makedirs(os.path.join(a.out, 'sprites'), exist_ok=True)
    names = [image[0x9700 + 20 * i:0x9714 + 20 * i].decode('ascii').strip() for i in range(32)]
    sheet = Image.new('RGB', (4 * 244, 8 * 182), (24, 24, 30))
    d = ImageDraw.Draw(sheet)
    for n in range(1, 33):
        st = CAVE1 if n == 1 else os.path.join(a.states, f'earth{n:02d}.rzx.001.z80')
        m = memory(st) if os.path.exists(st) else image
        m = m[:0xBEC6] + image[0xBEC6:0xE740] + m[0xE740:]  # the cave data as loaded
        cave = draw_cave(m, n)
        cave.save(os.path.join(a.out, 'maps', f'cave-{n:02d}.png'))
        x, y = (n - 1) % 4 * 244 + 2, (n - 1) // 4 * 182 + 2
        sheet.paste(cave.resize((240, 160)), (x, y + 18))
        d.text((x, y + 2), f'{n:02d} {names[n - 1]}', fill=(235, 235, 235))
    sheet.save(os.path.join(a.out, 'maps', 'caves.png'))
    m = memory(CAVE1)
    tiles = Image.new('RGB', (8 * 80, 4 * 84), (24, 24, 30))
    d = ImageDraw.Draw(tiles)
    for v in range(32):
        g, addr = graphic(m, v)
        x, y = v % 8 * 80 + 16, v // 8 * 84 + 4
        if g:
            tiles.paste(g.resize((48, 48), Image.NEAREST), (x, y))
        d.text((x - 8, y + 52), f'{v:2d} ${addr:04X}' if addr else f'{v:2d} none', fill=(235, 235, 235))
    tiles.save(os.path.join(a.out, 'sprites', 'cells-cave01.png'))
    print('caves 1-32, cells sheet written under', a.out)


if __name__ == '__main__':
    main()

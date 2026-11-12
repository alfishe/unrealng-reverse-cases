#!/usr/bin/env python3
"""A first map of a level drawn from its data (stage 1): the level block (side B, bit-reversed; tools/image.py) at
`$A800`, its header at `$C200`: `$C202` the section table, `$C204` the base of the maps. A table entry is 8 bytes:
the map's offset from `$C204` (big-endian), two bytes not decoded yet, and two more big-endian offsets from `$C202`
(the setup at `$8A6D` copies them to `$88D0`, `$88D2`, `$8995` and `$8B3E`). A map is 8 blocks wide (one screen),
row after row; a block (`$B200` + 16 x n) is 4 x 4 cells, row by row; a cell's 8 pixel bytes are at `$A900` + 8 x t
and its attribute at `$B100` + t (the builder `$88D4`, the drawer `$77B1`). A section's height is taken as far as the
next section's map (the last one: --last rows, one screen by default); each section is drawn as a column, labelled with its number and map
address. Level 1 is taken from side A's code block, the copy a 128K plays without side B; the
others from side B, their maps' last 768 bytes decrypted as `$894E` does (`tools/image.py` decrypt_maps).

    python3 tools/level_map.py N OUT.png [--memory Z80.BIN] [--last 8] [--scale 1] [--count 10]
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import image as I  # noqa: E402

INK = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def cell(mem, t):
    a = mem[0xB100 + t]
    pal = BRIGHT if a & 64 else INK
    ink, paper = pal[a & 7], pal[(a >> 3) & 7]
    im = Image.new('RGB', (8, 8))
    px = im.load()
    for y in range(8):
        b = mem[0xA900 + 8 * t + y]
        for x in range(8):
            px[x, y] = ink if b & (0x80 >> x) else paper
    return im


def sections(mem, last, count=10):
    w = lambda a: mem[a] | mem[a + 1] << 8  # noqa: E731
    tbl, base = w(0xC202), w(0xC204)
    offs = []
    for i in range(16):
        e = mem[tbl + 8 * i:tbl + 8 * i + 8]
        off = e[0] << 8 | e[1]
        if i and (off == 0 or off <= offs[-1] or base + off >= tbl):
            break
        offs.append(off)
    out = []
    for i, off in enumerate(offs):
        rows = (offs[i + 1] - off) // 8 if i + 1 < len(offs) else last
        out.append((i, base + off, rows))
    return out[:count]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', type=int)
    ap.add_argument('out')
    ap.add_argument('--memory', help='a 64 K dump with the level in place (level 1 as resident on the 128K)')
    ap.add_argument('--last', type=int, default=8)
    ap.add_argument('--scale', type=int, default=1)
    ap.add_argument('--count', type=int, default=16, help='draw the first COUNT sections only')
    a = ap.parse_args()
    # level 1 as the 128K plays it: the copy in side A's code block (it differs from side B's block 1 in 762 bytes)
    mem = open(a.memory, 'rb').read() if a.memory else I.image(None) if a.level == 1 else I.decrypt_maps(I.image(a.level))
    cells = {}
    secs = sections(mem, a.last, a.count)
    gap, top = 24, 40
    f = K.font(28)
    W = len(secs) * (256 + gap)
    H = top + max(r for _, _, r in secs) * 32
    im = Image.new('RGB', (W, H), (40, 40, 40))
    d = ImageDraw.Draw(im)
    for k, (i, addr, rows) in enumerate(secs):
        x0 = k * (256 + gap)
        d.text((x0 + 2, 4), f'{i}: ${addr:04X}', fill=(255, 255, 255), font=f)
        for r in range(rows):
            for c in range(8):
                blk = mem[addr + 8 * r + c]
                for j in range(16):
                    t = mem[0xB200 + 16 * blk + j]
                    if t not in cells:
                        cells[t] = cell(mem, t)
                    im.paste(cells[t], (x0 + 32 * c + 8 * (j % 4), top + 32 * r + 8 * (j // 4)))
    if a.scale > 1:
        im = im.resize((W * a.scale, H * a.scale), Image.NEAREST)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size, [(i, hex(addr), rows) for i, addr, rows in secs])


if __name__ == '__main__':
    main()

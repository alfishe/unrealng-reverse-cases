#!/usr/bin/env python3
"""Doc 06 figure: the three cell maps the screen builder leaves behind a screen, beside the screen itself.

    python3 tools/fig_cellmaps.py --work work/docs/docA/c1 --frame 16200 --out docs/img/render/cell-maps.png

Reads $4000-$63FF at the end of FRAME (TTD memory_at on the instance of WORK, cached in WORK/mem-at/) and draws
four panels, one character cell = one square:
  - the screen;
  - OpenCells $5B00: 0 (red) = scenery printed there, a sprite's pixels are masked out; $FF = open;
  - AttrCopy $5E00: 0 (green) = a sprite colours the cell; any other value = the scenery's attribute, kept;
  - CellTypes $6100: 0 empty, 1 solid (grey), 2-17 an object kind (numbered).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exlib  # noqa: E402

K = exlib.K
KIND_COLOURS = [(230, 90, 60), (240, 200, 60), (90, 200, 230), (200, 110, 220), (120, 220, 120), (250, 150, 60)]


def memory(work, frame):
    cache = os.path.join(work, 'mem-at', f'{frame}_4000.bin')
    if os.path.isfile(cache):
        return open(cache, 'rb').read()
    data = exlib.read(exlib.session(work), frame, 0x4000, 0x2400)
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    open(cache, 'wb').write(data)
    return data


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frame', type=int, required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--title', default='')
    args = p.parse_args()
    data = memory(args.work, args.frame)
    mem = bytearray(0x10000)
    mem[0x4000:0x6400] = data
    screen = K.render_screen(mem)
    S = 1.5
    pw, ph = int(256 * S), int(192 * S)
    cell = 8 * S
    gap, top, cap = 16, 54, 40
    W = 2 * pw + 3 * gap
    H = top + 2 * (ph + cap) + gap
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fs, fb = K.font(12), K.font(10), K.font(15)
    title = args.title or (f'Screen 0 (c1 {args.frame}): sprites hide behind scenery, '
                           'colour black cells, stop at solid')
    d.text((gap, 10), title, fill=K.TEXT, font=fb)
    d.text((gap, 32), 'one square = one character cell; the maps are 32 cells a row', fill=K.DIM, font=f)
    big = screen.resize((pw, ph), Image.NEAREST)
    dim = Image.blend(big, Image.new('RGB', big.size, (0, 0, 0)), 0.6)
    open_cells, attr_copy, types = data[0x1B00:0x1E00], data[0x1E00:0x2100], data[0x2100:0x2400]

    def panel(k, base, caption):
        r, c = divmod(k, 2)
        x, y = gap + c * (pw + gap), top + r * (ph + cap)
        im.paste(base, (x, y))
        d.multiline_text((x, y + ph + 4), caption, fill=K.TEXT, font=f, spacing=2)
        return x, y

    panel(0, big, 'the screen as the player sees it\n(rows 22-23: the HUD)')
    n0 = sum(1 for v in open_cells[:704] if v == 0)
    x, y = panel(1, dim.copy(), f'OpenCells $5B00: red = 0, scenery in front\n'
                                f'({n0} of 704 cells): sprite pixels masked')
    for i, v in enumerate(open_cells[:704]):
        if v == 0:
            cy, cx = divmod(i, 32)
            d.rectangle([x + cx * cell, y + cy * cell, x + (cx + 1) * cell - 2, y + (cy + 1) * cell - 2],
                        outline=(230, 70, 60), width=2)
    nz = sum(1 for v in attr_copy[:704] if v == 0)
    x, y = panel(2, dim.copy(), f'AttrCopy $5E00: green = 0, black cells ({nz});\n'
                                'a sprite sets its colour only there')
    for i, v in enumerate(attr_copy[:704]):
        if v == 0:
            cy, cx = divmod(i, 32)
            d.rectangle([x + cx * cell + 3, y + cy * cell + 3, x + (cx + 1) * cell - 4, y + (cy + 1) * cell - 4],
                        fill=(70, 200, 90))
    ns = sum(1 for v in types[:704] if v == 1)
    kinds = sorted({v for v in types[:704] if v > 1})
    x, y = panel(3, dim.copy(), f'CellTypes $6100: grey = 1 solid ({ns} cells);\n'
                                f'numbered = object kinds ({", ".join(map(str, kinds)) or "none"}: a turret)')
    for i, v in enumerate(types[:704]):
        cy, cx = divmod(i, 32)
        box = [x + cx * cell, y + cy * cell, x + (cx + 1) * cell - 2, y + (cy + 1) * cell - 2]
        if v == 1:
            d.rectangle(box, fill=(150, 150, 160))
        elif v > 1:
            d.rectangle(box, fill=KIND_COLOURS[v % len(KIND_COLOURS)])
            d.text((box[0] + 1, box[1]), str(v), fill=(0, 0, 0), font=fs)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size, 'open 0:', n0, 'attr 0:', nz, 'solid:', ns, 'kinds:', kinds)


if __name__ == '__main__':
    main()

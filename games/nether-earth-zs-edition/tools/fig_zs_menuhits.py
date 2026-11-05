#!/usr/bin/env python3
"""Doc 05 figure: where SPACE does what in the '99 start-up menu (docs/img/controls/menu-hits.png).

MenuSelect ($D9F5, src/menu99/menumain.asm) takes the character cell under the pointer's top-left corner
(row = y / 8, column = x / 8) and decides by the row, the column and the cell's attribute:

- rows 0-9: nothing;
- rows 10-16 with attribute 5, 6 or $47 (an item's colour, or a marked one): columns 0-10 LEVEL = row - 9,
  11-22 the UPGRADING toggle of the row, 23-31 CONTROL = row - 9 (rows 10-12), REDEFINE (row 13), nothing below;
- rows 17 and on with attribute 2: before row 21 START (columns 0-7), LOAD MAP (8-17), DESCRIPTION (18-31); from
  row 21 ADVICES (0-9), GREETS (10-17), ABOUT ZS NE (18-31).

The rule is applied here to the real attributes of r99 at --frame (TTD memory_at from the re_session instance of
--work), so every coloured cell is one where SPACE acts. The pointer's starting place (8,8) is marked.

    python3 tools/fig_zs_menuhits.py --work work/docs/zsA/r99 --frame 3020 --out docs/img/controls/menu-hits.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402
import zxscreen  # noqa: E402
from fig_common import font  # noqa: E402

ACTIONS = [('LEVEL = row - 9', (92, 143, 214)), ('UPGRADING toggle', (199, 125, 219)),
           ('CONTROL = row - 9', (89, 201, 165)), ('REDEFINE', (76, 175, 80)), ('START', (229, 83, 75)),
           ('LOAD MAP', (217, 164, 65)), ('DESCRIPTION', (240, 220, 90)), ('ADVICES', (150, 120, 255)),
           ('GREETS', (255, 140, 200)), ('ABOUT ZS NE', (120, 220, 255))]


def action(row, col, attr):
    if row < 10:
        return None
    if row < 17:
        if attr not in (5, 6, 0x47):
            return None
        if col < 11:
            return 0
        if col < 23:
            return 1
        return 2 if row < 13 else 3 if row == 13 else None
    if attr != 2:
        return None
    if row < 21:
        return 4 if col < 8 else 5 if col < 18 else 6
    return 7 if col < 10 else 8 if col < 18 else 9


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--frame', type=int, default=3020)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    s = Z.session(a.work)
    scr = Z.memory_at(s, a.frame, 0, 0x4000, 0x1B00)
    sc = 3
    img = zxscreen.render(scr, sc).convert('RGBA')
    over = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    counts = [0] * len(ACTIONS)
    for row in range(24):
        for col in range(32):
            k = action(row, col, scr[0x1800 + 32 * row + col])
            if k is None:
                continue
            counts[k] += 1
            x, y = col * 8 * sc, row * 8 * sc
            c = ACTIONS[k][1]
            d.rectangle([x, y, x + 8 * sc - 1, y + 8 * sc - 1], fill=c + (110,), outline=c + (255,))
    img = Image.alpha_composite(img, over).convert('RGB')
    dd = ImageDraw.Draw(img)
    dd.rectangle([8 * sc - 3, 8 * sc - 3, 8 * sc + 3, 8 * sc + 3], outline=(255, 255, 255), width=2)
    f, fs = font(17), font(14)
    pad, head, side = 12, 58, 300
    out = Image.new('RGB', (img.width + side + 2 * pad, img.height + head + pad), (21, 22, 27))
    out.paste(img, (pad, head))
    do = ImageDraw.Draw(out)
    do.text((pad, 8), "The start-up menu: SPACE acts only on the cells of an item's colour; the pointer's top-left "
            "corner picks the cell", fill=(230, 230, 230), font=f)
    do.text((pad, 32), f"r99 frame {a.frame}, the attributes read back; MenuSelect $D9F5 applied to every cell",
            fill=(184, 188, 200), font=fs)
    y = head
    for (name, c), n in zip(ACTIONS, counts):
        do.rectangle([img.width + 2 * pad, y + 2, img.width + 2 * pad + 16, y + 18], fill=c)
        do.text((img.width + 2 * pad + 24, y), f'{name}: {n} cells', fill=(230, 230, 230), font=fs)
        y += 26
    y += 10
    for line in ('white square: the pointer at (8,8),', 'where every menu entry puts it', '',
                 'other cells: SPACE redraws the', 'menu (rows 17 on) or does nothing'):
        do.text((img.width + 2 * pad, y), line, fill=(184, 188, 200), font=fs)
        y += 20
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    out.save(a.out)
    print(a.out, out.size, counts)


if __name__ == '__main__':
    main()

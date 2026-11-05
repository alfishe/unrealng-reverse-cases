#!/usr/bin/env python3
"""The play panel annotated, and its gauges as w1 saw them (docs/08-hud-and-text.md).

    python3 tools/fig_panel.py [--npz work/zyB/w1-frames.npz --frame 2200]

docs/img/hud/panel.png:
  - top: the score line (row 0) and the panel (rows 19-23) of one w1 frame, x3, every cell the code writes boxed
    and named with its address and writer;
  - middle: the five pod icons PodIcons $B4AF (32 bytes each, record +7 picks one), as PodIconJob draws them;
  - bottom: the gauges cut from w1 at the frames where they change: the fuel lamps $5AC1/$5ADD at Fuel $80E6 >= $40,
    $20-$3F, < $20, and the speed bar $5AEE at the speeds $40 and $60.
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw

import zybplot as P
import fig_weapons as W
import fig_text as T

S = 3
MARKS = [  # (row, col, w, h, label, colour)
    (0, 2, 8, 1, 'score $5802: PrintPlayerScore $A4AE', (255, 255, 120)),
    (20, 1, 2, 2, 'spinner $5A81 (DrawSpinner)', (120, 220, 255)),
    (20, 29, 2, 2, 'spinner $5A9D', (120, 220, 255)),
    (20, 6, 2, 2, 'pod icon: PodIconJob ($5086)', (120, 255, 140)),
    (22, 6, 2, 1, 'ink step $5AC6', (255, 170, 80)),
    (22, 1, 2, 1, 'fuel lamps $5AC1', (255, 110, 110)),
    (22, 29, 2, 1, 'fuel lamps $5ADD', (255, 110, 110)),
    (23, 14, 4, 1, 'speed bar $5AEE', (230, 140, 255)),
    (21, 11, 10, 2, 'burst rows 21-22, cols 11-20', (200, 200, 200)),
    (22, 24, 6, 1, 'lives $5AD8 (DrawLives)', (255, 90, 90)),
]


def strip(rec, i, rows):
    img = W.screen_img(rec, i, 1)
    return [img.crop((0, 8 * r0, 256, 8 * (r1 + 1))) for r0, r1 in rows]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'zyB', 'w1-frames.npz'))
    p.add_argument('--frame', type=int, default=2200)
    a = p.parse_args()
    rec = W.Rec(a.npz)
    i = int(np.where(rec.F == a.frame)[0][0])
    top, panel = strip(rec, i, [(0, 0), (19, 23)])
    Wd = 256 * S + 300
    img = Image.new('RGB', (Wd, 1060), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f = P.K.font(12)
    d.text((10, 8), f'The play panel at w1 frame {a.frame}: rows 0 and 19-23, x{S}. PanelFrame $AB13 writes only '
                    f'attributes each frame;', fill=P.K.TEXT, font=P.K.font(14))
    d.text((10, 26), 'the pixels come from RestorePanel, the spinners, the icon and the print routine',
           fill=P.K.TEXT, font=P.K.font(14))
    y_top, y_pan = 56, 56 + 8 * S + 16
    img.paste(top.resize((256 * S, 8 * S), Image.NEAREST), (10, y_top))
    img.paste(panel.resize((256 * S, 40 * S), Image.NEAREST), (10, y_pan))
    ly = 56
    for k, (r, c, w, h, label, col) in enumerate(MARKS):
        y = y_top if r == 0 else y_pan + (r - 19) * 8 * S
        x = 10 + c * 8 * S
        d.rectangle([x, y, x + w * 8 * S - 1, y + h * 8 * S - 1], outline=col, width=2)
        d.text((x + 2, y + 2), str(k + 1), fill=col, font=P.K.font(13))
        d.text((256 * S + 24, ly), f'{k + 1} {label}', fill=col, font=f)
        ly += 17
    # the icons
    m = T.image()
    yi = y_pan + 40 * S + 30
    d.text((10, yi), 'the five pod icons, PodIcons $B4AF + 32 n (n = the selector, record +7), coloured as PodIconJob does: '
                     'the top row $46 (yellow), the bottom row $45 (cyan):', fill=P.K.TEXT, font=f)
    names = ['0 speed-up', '1 laser', '2 plasma', '3 homing missiles', '4 seeker']
    for n in range(5):
        b = m[0xB4AF + 32 * n:0xB4AF + 32 * n + 32]
        ic = Image.new('RGB', (16, 16))
        q = [b[0:8], b[8:16], b[16:24], b[24:32]]
        for cell, (cx, cy) in zip(q, [(0, 0), (8, 0), (0, 8), (8, 8)]):
            for yy, v in enumerate(cell):
                for xx in range(8):
                    ink = (255, 255, 0) if cy == 0 else (0, 255, 255)
                    ic.putpixel((cx + xx, cy + yy), ink if v & (0x80 >> xx) else (0, 0, 0))
        x = 10 + n * 170
        img.paste(ic.resize((16 * 5, 16 * 5), Image.NEAREST), (x, yi + 22))
        d.text((x, yi + 22 + 82), names[n], fill=P.K.TEXT, font=f)
    # the gauges over w1
    fuel, speed = rec.var(0x80E6), rec.var(0x7FA7)
    yg = yi + 22 + 110
    d.text((10, yg), 'the gauges in w1, 8 frames after each value is reached: the fuel lamps $5AC1-$5AC2 (the right one dark below $40, '
                     'both below $20)\nand the speed bar $5AEE-$5AF1 (speed / 32 - 1 lit cells):', fill=P.K.TEXT, font=f)

    def first(pred):
        for k in range(len(rec.F)):
            if pred(k) and all(pred(j) for j in range(k, min(k + 9, len(rec.F)))):
                return k + 8   # the panel shows a value a frame or more after it is set: 8 frames on
        return None
    cases = [('fuel >= $40', first(lambda k: fuel[k] >= 0x40 and rec.F[k] > 100), 'fuel'),
             ('fuel $20-$3F', first(lambda k: 0x20 <= fuel[k] < 0x40), 'fuel'),
             ('fuel < $20', first(lambda k: fuel[k] < 0x20), 'fuel'),
             ('speed $40', first(lambda k: speed[k] == 0x40 and rec.F[k] > 100), 'speed'),
             ('speed $60', first(lambda k: speed[k] == 0x60 and rec.F[k] > 200), 'speed')]
    for n, (label, k, what) in enumerate(cases):
        if k is None:
            continue
        pic = W.screen_img(rec, k, 1)
        box = (0, 168, 40, 184) if what == 'fuel' else (104, 176, 152, 192)
        crop = pic.crop(box)
        x = 10 + n * 170
        img.paste(crop.resize((crop.width * 4, crop.height * 4), Image.NEAREST), (x, yg + 40))
        d.text((x, yg + 40 + crop.height * 4 + 4), f'{label}\nw1 frame {int(rec.F[k])} Fuel ${fuel[k]:02X}'
               if what == 'fuel' else f'{label}\nw1 frame {int(rec.F[k])}', fill=P.K.TEXT, font=f)
    img = img.crop((0, 0, Wd, yg + 40 + 64 + 50))
    path = P.out('hud', 'panel.png')
    img.save(path)
    print('wrote', os.path.relpath(path, P.CASE), img.size)


if __name__ == '__main__':
    main()

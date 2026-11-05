#!/usr/bin/env python3
"""The play screen's panel with its parts named (docs/08-hud-and-text.md 8.2).

    python3 tools/fig_panel.py FRAME [--npz work/z128B/w1-frames.npz]

docs/img/hud/panel.png: the score row (row 0) and the panel (rows 19-23) of one w1 frame at 4x, each part boxed at
the attribute cells its routine writes (the addresses in the labels), with the values that frame held: the score,
the lives (+4), the pod selector (+7), the speed (+$0B) and Fuel ($80E6).
"""
import argparse
import os

from PIL import Image, ImageDraw

import fig_weapons as W
import z128plot as P

# (name, attribute address of the top-left cell, width, height in cells, colour, the routine)
PARTS = [
    ('score, player 1', 0x5802, 8, 1, (255, 240, 120), 'PrintPlayerScore $A4AE'),
    ('score, player 2', 0x5816, 8, 1, (255, 240, 120), 'PrintPlayerScore $A4AE'),
    ('spinner', 0x5A81, 2, 2, (120, 220, 255), 'DrawSpinner $A8BE'),
    ('spinner', 0x5A9D, 2, 2, (120, 220, 255), 'DrawSpinner $A8BE'),
    ('pod icon', 0x5A86, 2, 2, (120, 255, 140), 'PodIconJob $AC2C'),
    ('ink cells', 0x5AC6, 2, 1, (255, 150, 60), 'PanelFrame $AB1D'),
    ('fuel lamps', 0x5AC1, 2, 1, (255, 120, 220), 'PanelFrame $AB5B'),
    ('fuel lamps', 0x5ADD, 2, 1, (255, 120, 220), 'PanelFrame $AB5B'),
    ('burst', 0x5AAB, 10, 2, (200, 160, 255), 'PanelFrame $ABB1'),
    ('speed bar', 0x5AEE, 4, 1, (90, 200, 255), 'PanelFrame $AB44'),
    ('lives: 6 marks from $5AD8 by the steps at $81C0 (+1, -32, -32, +31, -32)', 0x5A98, 2, 3, (255, 90, 80),
     'DrawLives $A4EF'),
]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('frame', type=int)
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'z128B', 'w1-frames.npz'))
    a = p.parse_args()
    rec = W.Rec(a.npz)
    i = int(list(rec.F).index(a.frame))
    S = 4
    scr = P.screen(bytes(rec.S[i])).resize((256 * S, 192 * S), Image.NEAREST)
    top = scr.crop((0, 0, 256 * S, 8 * S))
    pan = scr.crop((0, 152 * S, 256 * S, 192 * S))
    L, T = 20, 90
    gap = 40
    H = T + 8 * S + gap + 40 * S + 260
    img = Image.new('RGB', (256 * S + 2 * L, H), P.K.BACKGROUND)
    img.paste(top, (L, T))
    img.paste(pan, (L, T + 8 * S + gap))
    d = ImageDraw.Draw(img)
    v = rec.V[i]
    score = bytes(v[0:4]).hex()
    d.text((L, 8), f'The panel at w1 frame {a.frame}: each part has its own routine and its own cells\n'
                   f'(the boxes: the attribute cells each routine writes)', fill=P.K.TEXT, font=P.K.font(15))
    d.text((L, 46), f'this frame: score {int(score)}, lives +4 = {v[4]}, pod selector +7 = {v[7]} '
                    f'({W.ACTIONS[v[7]]}), side weapon +8 = {v[8]}, speed +$0B = ${v[11]:02X}, '
                    f'Fuel $80E6 = ${v[0x80E6 - W.B]:02X}', fill=P.K.DIM, font=P.K.font(13))
    d.text((L, T - 16), 'row 0', fill=P.K.DIM, font=P.K.font(12))
    d.text((L, T + 8 * S + gap - 16), 'rows 19-23', fill=P.K.DIM, font=P.K.font(12))
    f = P.K.font(13)
    legend_y = T + 8 * S + gap + 40 * S + 16
    for k, (name, at, w, h, col, who) in enumerate(PARTS):
        off = at - 0x5800
        row, colm = off // 32, off % 32
        x = L + colm * 8 * S
        y = T + row * 8 * S if row == 0 else T + 8 * S + gap + (row - 19) * 8 * S
        d.rectangle([x - 1, y - 1, x + w * 8 * S + 1, y + h * 8 * S + 1], outline=col, width=3)
        d.text((x + 3, y + 2), str(k + 1), fill=col, font=P.K.font(14))
        lx = L
        ly = legend_y + k * 20
        d.text((lx, ly), f'{k + 1} {name}: ${at:04X}, row {row} column {colm}, {w} x {h} cells; {who}', fill=col,
               font=f)
    path = P.out('hud', 'panel.png')
    img.save(path)
    print('wrote', os.path.relpath(path, P.CASE), img.size)


if __name__ == '__main__':
    main()

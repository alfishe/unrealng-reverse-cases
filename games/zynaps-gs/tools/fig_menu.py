#!/usr/bin/env python3
"""Doc 05 figure: the options menu as it boots and after keys 3-7, 0, 8 and T, with what each option writes into
Zynaps's code or the driver's variables.

    python3 tools/fig_menu.py --dir work/zgsA/menu --before 900 --after 1227 --out docs/img/controls/menu-options.png
    python3 tools/fig_anim.py --dir work/zgsA/menu --step 1 --delay 80 --title T --out docs/img/controls/menu.gif

The screens are tools/cap_tour.py menu's captures (a fresh boot of the original TRD; steps.log names the keys and
their frames). The writes come from src/disk/menu.ann (Start $6E9B, SelectLevel $6E6F, the option keys) and the
bytes the capture read after the keys ($B073 = 06 05 after T).
"""
import argparse
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
# key, item, the byte or code it writes, when
WRITES = [
    ('1', 'START MUSIC & EFFECTS', 'SoundModeOption = 0: level modules + 10 FX', 'Start'),
    ('2', 'START ONLY EFFECTS', 'SoundModeOption = 1: 21 FX, no module', 'Start'),
    ('3', 'INFINITE ROUNDS', '$B218: JR NC ($30) -> JR ($18), never game over', 'Start'),
    ('4', 'TURBO LOADER', "the loader's sector reader: own / TR-DOS fn 5", 'at once'),
    ('5', 'SATURNS', 'FX 21 loaded, SaturnSound ($B464) on', 'at once'),
    ('6', 'SHOOTING', "the shot's sound: normal / none / channel 1", 'at once'),
    ('7', 'EFFECTS TIMER', 'the gate length 0-9 into the driver (2 at boot)', 'Start'),
    ('0', '(not listed)', 'shows lines 8 and Q-P,A-S; arms their keys', 'at once'),
    ('8', 'INFINITE LIFE (hidden)', '$9B50: RET NZ ($C0) -> RET ($C9), never killed', 'Start'),
    ('Q..S', 'SELECT LEVEL (hidden)', '$B073: LD B,(HL); INC B -> LD B,n (T: 06 05)', 'at once'),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--dir', default=os.path.join(Z.CASE, 'work', 'zgsA', 'menu'))
    ap.add_argument('--before', type=int, default=900)
    ap.add_argument('--after', type=int, default=1227)
    ap.add_argument('--out', default=Z.out('controls', 'menu-options.png'))
    args = ap.parse_args()
    f, fb = K.font(12), K.font(15)
    shots = [Z.render(open(os.path.join(args.dir, f'{n:06d}.scr'), 'rb').read(), 2).resize((432, 324), Image.LANCZOS)
             for n in (args.before, args.after)]
    W, top = 900, 52
    table_top = top + 324 + 34
    im = Image.new('RGB', (W, table_top + 22 + 18 * len(WRITES) + 40), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Key 0 reveals two hidden options; the options become bytes in Zynaps\'s code', fill=K.TEXT, font=fb)
    d.text((10, 28), 'left: the menu at boot; right: after keys 3 4 5 6 7 7 0 8 T (each option changed once); '
                     'the hidden lines are blue', fill=K.DIM, font=f)
    for i, (shot, n) in enumerate(zip(shots, (args.before, args.after))):
        x = 10 + i * 448
        im.paste(shot, (x, top))
        d.text((x, top + 328), f'work/zgsA/menu frame {n}', fill=K.DIM, font=f)
    cols = [10, 52, 230, 690]
    for c, h in zip(cols, ('key', 'item', 'what it writes', 'when')):
        d.text((c, table_top), h, fill=(230, 230, 170), font=f)
    for r, row in enumerate(WRITES):
        y = table_top + 20 + 18 * r
        hidden = r >= 8 or row[0] == '0'
        for c, text in zip(cols, row):
            d.text((c, y), text, fill=(120, 150, 255) if hidden and c < 230 else K.TEXT, font=f)
    d.text((10, table_top + 24 + 18 * len(WRITES)), '"Start" = written by keys 1 and 2 on their way to the installer;'
           ' "at once" = written when the key is pressed', fill=K.DIM, font=f)
    im.save(args.out)
    print(args.out, im.size)


if __name__ == '__main__':
    main()

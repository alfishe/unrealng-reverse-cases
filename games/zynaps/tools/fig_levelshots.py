#!/usr/bin/env python3
"""Doc 01 figures: one screenshot of each of the 12 levels of r1, in the order they were played, and a sheet of all.

    python3 tools/fig_levelshots.py --work work/zyA/r1 --out-dir docs/img/design

The frames are picked by hand from a scan of r1 (one frame inside each level counter's span, scenery or a fight on
screen). For each the script reads the player record ($7F9C: +6 the level counter) and LevelOrder ($8003), so the
label's level number is the one the game played, not assumed. Writes level-NN-L.png (2x, NN the play order, L the
level) and levels-sheet.png.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zynlib as Z  # noqa: E402

K = Z.K
FRAMES = [2400, 8000, 18000, 23700, 29600, 33300, 43200, 47800, 54500, 58900, 66400, 70300]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out-dir', required=True)
    args = p.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)
    s = Z.session(args.work)
    f, fb = K.font(12), K.font(15)
    cols, cw, ch = 3, 288, 216 + 20
    sheet = Image.new('RGB', (10 + cols * (cw + 10), 60 + 4 * (ch + 8)), K.BACKGROUND)
    d = ImageDraw.Draw(sheet)
    d.text((10, 8), 'The 12 levels in the order r1 played them: 0 1 2, then 3-8 shuffled (7 6 5 4 8 3), then 9 10 11',
           fill=K.TEXT, font=fb)
    d.text((10, 30), 'label: play order, level (LevelOrder[counter]), r1 frame, score', fill=K.DIM, font=f)
    for i, fr in enumerate(FRAMES):
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = Z.read(s, fr, 0x4000, 6912)
        rec = Z.read(s, fr, 0x7F9C, 16)
        order = Z.read(s, fr, 0x8003, 12)
        counter = rec[6]
        level = order[counter]
        screen = K.render_screen(mem)
        name = f'level-{counter + 1:02d}-{level}.png'
        screen.resize((512, 384), Image.NEAREST).save(os.path.join(args.out_dir, name))
        x, y = 10 + (i % cols) * (cw + 10), 54 + (i // cols) * (ch + 8)
        sheet.paste(screen.resize((cw, 216), Image.NEAREST), (x, y + 18))
        d.text((x, y + 2), f'#{counter + 1} level {level}  frame {fr}  score {int(rec[0:4].hex())}', fill=K.TEXT,
               font=f)
        print(name, fr, 'counter', counter, 'level', level)
    sheet.save(os.path.join(args.out_dir, 'levels-sheet.png'))
    print(os.path.join(args.out_dir, 'levels-sheet.png'), sheet.size)


if __name__ == '__main__':
    main()

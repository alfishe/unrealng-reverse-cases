#!/usr/bin/env python3
"""Doc 03's 48K screens: the explorer chosen during the load, on stage 2's second 48K try.

    python3 tools/fig_load48k.py docs/img/load/48k-screens.png

The three screens are work/stage2/p48/orig2/a-stop.png, b-selector.png and c-chosen.png, taken by
work/stage2/probe_48k_orig2.py on a clone of a 48K power-on with the original TZX at ROM speed (no .ttd): the tape
paused after block 4, SPACE, the cursor walked onto Fortisque-Smithe with O and Z, SPACE. Each is drawn at 4/3 x.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

BG, TEXT, DIM = (20, 20, 26), (235, 235, 235), (175, 175, 185)
SHOTS = [('a-stop.png', 'STOP THE TAPE (one RAM found)', 'ShowStopTape, run in place at $7495'),
         ('b-selector.png', 'SPACE: the 48K selector', "inside the loader's CALL $7200"),
         ('c-chosen.png', 'FIRE: set 0 copied to $6000', 'EXPLORER SELECTED, START TAPE')]


def main():
    out = sys.argv[1]
    W, S, GAP, LEFT = 1050, 4 / 3, 13, 12
    pw, ph = int(256 * S), int(192 * S)
    f, fs, fb = kitlib.font(14), kitlib.font(13), kitlib.font(19)
    img = Image.new('RGB', (W, 60 + ph + 70), BG)
    d = ImageDraw.Draw(img)
    d.text((LEFT + 8, 12), 'The 48K path up to the explorer\'s choice (stage 2, a clone of a 48K power-on, no .ttd)',
           font=fb, fill=TEXT)
    d.text((LEFT + 8, 38), 'work/stage2/p48/orig2: the original TZX at ROM speed, the tape paused after block 4',
           font=fs, fill=DIM)
    for i, (name, l1, l2) in enumerate(SHOTS):
        shot = Image.open(os.path.join(C, 'work', 'stage2', 'p48', 'orig2', name)).convert('RGB')
        x = LEFT + i * (pw + GAP)
        img.paste(shot.resize((pw, ph), Image.NEAREST), (x, 60))
        d.text((x, 66 + ph), l1, font=f, fill=TEXT)
        d.text((x, 84 + ph), l2, font=fs, fill=DIM)
    img.save(out)
    print(out)


if __name__ == '__main__':
    main()

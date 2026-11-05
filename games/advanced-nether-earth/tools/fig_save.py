#!/usr/bin/env python3
"""Doc 03: the disk save and load in recording r2, as six screens (docs/img/load/save-load-r2.png).

    python3 tools/fig_save.py [--shots work/stage3/r2/screens-rec] [--png docs/img/load/save-load-r2.png]

The screens are r2's (kit/screen_shot.py, the `$4000` page at each frame); the captions give the frame and what
the frame proves. Nothing is drawn: the figure is the recording.
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, FG, DIM = (21, 22, 27), (230, 230, 230), (184, 188, 200)
SHOTS = [
    (7202, 'play, day 0 00.35', 'before the save'),
    (7652, 'key 5: the disk module, bank 4', 'its save screen at $4000'),
    (7947, '"test" typed, "Saving..."', '$D92B-$FFFF to the disk'),
    (8102, 'play again, 05.00', 'the save returns to play'),
    (9202, 'menu 5, load "test": 05.30', 'the saved game goes on'),
    (10602, 'load "nether": day 29, 10.35', "the disk's own saved game"),
]


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('--shots', default=os.path.join(CASE, 'work/stage3/r2/screens-rec'))
    a.add_argument('--png', default=os.path.join(CASE, 'docs/img/load/save-load-r2.png'))
    args = a.parse_args()
    font = ImageFont.load_default()
    tw, th = 320, 240
    W, H = 3 * (tw + 16) + 16, 2 * (th + 48) + 56
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((16, 10), 'Recording r2: a disk save, a load of it, a load of nether.N; play goes on from each',
           fill=FG, font=font)
    d.text((16, 26), 'Pentagon 128, the original SCL; recording frames; key 5 in play saves, menu item 5 loads',
           fill=DIM, font=font)
    for i, (frame, top, bottom) in enumerate(SHOTS):
        x, y = 16 + (i % 3) * (tw + 16), 50 + (i // 3) * (th + 48)
        shot = Image.open(os.path.join(args.shots, 'f%d.png' % frame)).convert('RGB').resize((tw, th))
        img.paste(shot, (x, y + 28))
        d.text((x, y), 'f%d  %s' % (frame, top), fill=FG, font=font)
        d.text((x, y + 13), bottom, fill=DIM, font=font)
    os.makedirs(os.path.dirname(args.png), exist_ok=True)
    img.save(args.png)
    print(args.png)


if __name__ == '__main__':
    main()

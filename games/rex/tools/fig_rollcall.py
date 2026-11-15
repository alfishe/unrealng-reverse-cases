#!/usr/bin/env python3
"""The menu's roll call, every enemy as the menu shows it: the box of the screenshots of the recording menu-rollcall
(kit/screen_shot.py, frames below), in the order of RollCallTexts $DC26, with the object kind each one is.

    python3 tools/fig_rollcall.py [--shots work/docs/rxA/roll]

writes docs/img/play/roll-call.png.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# (frame of menu-rollcall, the kind in ObjectTable +9, KillScores x 100)
ROLL = [(1650, 0, 100), (2200, 1, 200), (2700, 8, 600), (3220, 12, 300), (3740, 11, 800), (4260, 10, 500),
        (4780, 9, 600), (100, 15, 200), (600, 13, 1000), (1150, 14, 0)]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--shots', default='work/docs/rxA/roll')
    a = p.parse_args()
    cw, ch, scale, cols = 128, 40, 2, 4
    w, h = cw * scale, ch * scale
    font, small = K.font(16), K.font(14)
    out = Image.new("RGB", (1050, 40 + 3 * (h + 30)), (24, 24, 30))
    d = ImageDraw.Draw(out)
    d.text((10, 8), 'The roll call: the ten enemies the menu names, in its order, with their kind and score',
           fill=(240, 240, 240), font=font)
    for i, (frame, kind, score) in enumerate(ROLL):
        im = Image.open(os.path.join(C, a.shots, 'm%d.png' % frame)).convert('RGB').crop((12, 4, 12 + cw, 4 + ch))
        x, y = 6 + (i % cols) * (w + 6), 40 + (i // cols) * (h + 30)
        out.paste(im.resize((w, h), Image.NEAREST), (x, y))
        d.text((x, y + h + 4), 'kind %d, frame %d' % (kind, frame), fill=(220, 220, 220), font=small)
    path = os.path.join(C, 'docs/img/play/roll-call.png')
    out.save(path)
    print(path, out.size)


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The two sides' titles (docs/03-build-and-load.md 3.12): Side A's from c1, Side B's from b1's live run past the
Lenslok (work/b1_live.py), each the screen as the recording left it.

    python3 tools/fig_sides.py [A.scr] [B.scr]   # -> docs/img/load/sides.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import kitlib as K  # noqa: E402

BG, TEXT, DIM = (14, 14, 20), (220, 220, 230), (130, 130, 145)


def screen(path):
    scr = open(path, 'rb').read()[:6912]
    return K.render_screen(bytes(0x4000) + scr + bytes(0x10000 - 0x4000 - 6912)).resize((384, 288), Image.NEAREST)


def main():
    a = sys.argv[1] if len(sys.argv) > 1 else os.path.join(E.CASE, 'work', 'c1', 'screens', '002250.scr')
    b = sys.argv[2] if len(sys.argv) > 2 else os.path.join(E.CASE, 'work', 'b1', 'live', 'title.scr')
    im = Image.new('RGB', (2 * 384 + 60, 288 + 96), BG)
    d = ImageDraw.Draw(im)
    d.text((20, 10), 'Both sides open on the same Cobra: the Adder of Side B is blueprint 17, met only in flight',
           fill=TEXT, font=K.font(15))
    for k, (path, label) in enumerate(((a, 'Side A ("With Krait ship"): c1, frame 2250'),
                                       (b, 'Side B ("With Adder ship"): b1, entry + 400 frames'))):
        x = 20 + k * (384 + 20)
        im.paste(screen(path), (x, 40))
        d.text((x, 40 + 288 + 10), label, fill=DIM, font=K.font(12))
    d.text((20, im.height - 22), 'python3 tools/fig_sides.py', fill=DIM, font=K.font(12))
    out = os.path.join(E.CASE, 'docs', 'img', 'load', 'sides.png')
    im.save(out)
    print('wrote', os.path.relpath(out, E.CASE))


if __name__ == '__main__':
    main()

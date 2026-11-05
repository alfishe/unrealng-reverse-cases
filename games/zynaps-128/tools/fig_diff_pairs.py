#!/usr/bin/env python3
"""Doc 13's paired figures: one figure of the 48K case (left) and the same figure of this case (right), side by side
at the same height, each under a label strip (docs/img/diff/*-pair.png).

    python3 tools/fig_diff_pairs.py [NAME ...]        (default: all of PAIRS)

Both figures are the cases' own, made from their recordings by the commands in their docs; nothing is redrawn here.
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.normpath(os.path.join(HERE, '..'))
Z48 = os.path.normpath(os.path.join(C, '..', 'zynaps'))
sys.path.insert(0, os.path.join(C, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# name: (the 48K figure, its label, this case's figure, its label, the title)
PAIRS = {
    'pass': ('loop/pass.png', '48K: c2 301-308, 69 888 T a frame',
             'loop/pass.png', '2 in 1: c1 12200-12209, Pentagon, 71 680 T a frame',
             'The play pass, two frames: the same parts in the same order; the 2 in 1 adds the AY engine (white) and '
             'longer waits (olive)'),
    'beam': ('render/beam-pass.png', '48K: c2 301-302, DrawPlayfield from line 30',
             'render/beam-pass.png', '2 in 1: c1 12200-12201, Pentagon, DrawPlayfield from line 29',
             'DrawPlayfield behind the beam on both machines: the 2018 waits move it to the same line on the '
             'Pentagon'),
    'levels': ('design/levels-sheet.png', "48K: r1's twelve levels",
               'design/levels-sheet.png', "2 in 1: r3's twelve levels",
               'The same twelve levels; the middle six (3-8) come in a new random order every game, on both'),
}


def pair(name, out_dir):
    left, llab, right, rlab, title = PAIRS[name]
    a = Image.open(os.path.join(Z48, 'docs/img', left)).convert('RGB')
    b = Image.open(os.path.join(C, 'docs/img', right)).convert('RGB')
    h = max(a.height, b.height)
    a = a.resize((round(a.width * h / a.height), h), Image.LANCZOS) if a.height != h else a
    b = b.resize((round(b.width * h / b.height), h), Image.LANCZOS) if b.height != h else b
    gap, top, strip = 16, 40, 26
    im = Image.new('RGB', (a.width + b.width + 3 * gap, h + top + strip + gap), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((gap, 10), title, fill=K.TEXT, font=K.font(16))
    for x, img, lab in ((gap, a, llab), (2 * gap + a.width, b, rlab)):
        d.rectangle((x, top, x + img.width - 1, top + strip - 4), fill=(40, 40, 52))
        d.text((x + 8, top + 4), lab, fill=K.TEXT, font=K.font(13))
        im.paste(img, (x, top + strip))
    out = os.path.join(out_dir, f'{name}-pair.png')
    os.makedirs(out_dir, exist_ok=True)
    im.save(out)
    print('wrote', out, im.size)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('names', nargs='*', default=list(PAIRS))
    ap.add_argument('--out-dir', default=os.path.join(C, 'docs/img/diff'))
    a = ap.parse_args()
    for n in a.names:
        pair(n, a.out_dir)


if __name__ == '__main__':
    main()

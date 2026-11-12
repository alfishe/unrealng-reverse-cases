#!/usr/bin/env python3
"""A block reveal on screen: the room before and after RevealZone `$A569` adds a zone, the new zone's cells outlined.
Reads the open recording (re_session.py open) with TTD memory_at: the screen at two frames, and the room's zone plane
`$6700` (cell = 20 x row + column, zone bits 7-2) and RevealedZones `$6DFF` after.

    python3 tools/fig_reveal.py --work work/docs/zsA/r004000 --before 552 --after 565 --out docs/img/loop/reveal-room9.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--before', type=int, required=True)
    ap.add_argument('--after', type=int, required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--label', default='r004000')
    a = ap.parse_args()
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(a.work)

    def mem(frame, off, n):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': off, 'length': n},
                   ok=False)
        return bytes.fromhex(r.structured['hex'])

    sb, sa = mem(a.before, 0x4000, 6912), mem(a.after, 0x4000, 6912)
    zb, za = mem(a.before, 0x6DFF, 1)[0], mem(a.after, 0x6DFF, 1)[0]
    plane = mem(a.after, 0x6700, 220)
    new = za & ~zb & 0xFC
    scale = 2
    f = K.font(14)
    fs = K.font(12)
    W = 1050
    top = 30
    img = Image.new('RGB', (W, top + 384 + 130), (16, 16, 20))
    d = ImageDraw.Draw(img)
    d.text((10, 6), f'A block reveal: zone ${new:02X} of room 9 appears, RevealedZones $6DFF ${zb:02X} -> ${za:02X}',
           fill='white', font=f)
    for k, (scr, title) in enumerate([(sb, f'{a.label} frame {a.before}: before'),
                                      (sa, f'{a.label} frame {a.after}: after, the new zone outlined')]):
        x0 = 6 + k * (512 + 14)
        im = K.render_screen(scr, 0).resize((512, 384), resample=0)
        img.paste(im, (x0, top))
        if k == 1:
            for cell in range(220):
                if plane[cell] & new:
                    r, c = divmod(cell, 20)
                    x, y = 8 + 12 * c, 8 + 16 * r
                    d.rectangle([x0 + x * scale, top + y * scale, x0 + (x + 12) * scale - 1,
                                 top + (y + 16) * scale - 1], outline=(255, 80, 80))
        d.text((x0, top + 388), title, fill='white', font=fs)
    notes = ['The play window is 20 x 11 cells of 12 x 16 pixels at (8, 8); each red box is a cell whose zone byte',
             f'($6700 + cell, read at frame {a.after}) has bit ${new:02X}. Before the reveal those cells are black:',
             'RedrawCellMask $8868 erases a cell whose zone bits are not in RevealedZones. The pass that adds the',
             'zone redraws all 220 cells (RedrawCellsMasked $8855) and stalls the main loop for 11.6 frames.']
    for i, t in enumerate(notes):
        d.text((10, top + 410 + 16 * i), t, fill=(200, 200, 200), font=fs)
    img.save(a.out)
    print(a.out, img.size)


if __name__ == '__main__':
    main()

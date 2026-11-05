#!/usr/bin/env python3
"""Doc 06 figure: Final Cut's scroller keeps half of its text's pixel rows in each of the two screens and shows
them in turn, so the eye adds the halves.

    python3 tools/ttd_dump.py --work work/docR/r4 --frame 2500 --out work/docR/fcdump/f2500 --pages 5-7
    python3 tools/fig_fc_interlace.py --bank5 work/docR/fcdump/f2500-bank5.bin --bank7 work/docR/fcdump/f2500-bank7.bin \
        --frame 2500 --out docs/img/render/fc-interlace.png

Three screens of the same moment: the normal screen (bank 5), the shadow screen (bank 7), and the two averaged, as
the eye sees a 48.8 Hz alternation (the Pentagon's frame rate); under each, the scroller's text columns enlarged.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

BG, FG, DIM = (21, 22, 27), (232, 232, 238), (184, 188, 200)


def screen(path):
    data = open(path, 'rb').read()
    mem = bytearray(0x10000)
    mem[0x4000:0x4000 + len(data)] = data
    return K.render_screen(mem, 0x4000)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--bank5', required=True)
    p.add_argument('--bank7', required=True)
    p.add_argument('--frame', type=int, required=True)
    p.add_argument('--crop', default='0,40,128,48', help='x,y,w,h of the enlarged part (screen pixels)')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    a, b = screen(args.bank5), screen(args.bank7)
    mix = Image.blend(a, b, 0.5)
    x, y, w, h = (int(v) for v in args.crop.split(','))
    S, Z = 2, 4
    pw = 256 * S
    title_h, cap_h = 44, 40
    W = 3 * pw + 4 * 16
    H = title_h + cap_h + 192 * S + 16 + h * Z + 30
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    d.text((16, 10), f'Final Cut, frame {args.frame} of r4: each screen holds half of the text\'s pixel rows and its own '
                     f'alien; shown in turn each frame, the eye adds them', fill=FG, font=K.font(17))
    caps = ['bank 5, the normal screen: every other row\nof the 16-row font; the alien in magenta',
            'bank 7, the shadow screen: the other rows;\nthe alien drawn again in green',
            'the two averaged, as the eye sees $7FFD bit 3\nflip each frame: whole letters, a two-tone alien']
    for i, (img, cap) in enumerate(zip((a, b, mix), caps)):
        x0 = 16 + i * (pw + 16)
        d.text((x0, title_h), cap, fill=DIM, font=K.font(14))
        out.paste(img.resize((pw, 192 * S), Image.NEAREST), (x0, title_h + cap_h))
        d.rectangle([x0 + x * S, title_h + cap_h + y * S, x0 + (x + w) * S, title_h + cap_h + (y + h) * S],
                    outline=(229, 83, 75), width=2)
        crop = img.crop((x, y, x + w, y + h)).resize((w * Z, h * Z), Image.NEAREST)
        cy = title_h + cap_h + 192 * S + 16
        out.paste(crop, (x0, cy))
        d.rectangle([x0, cy, x0 + w * Z, cy + h * Z], outline=(229, 83, 75), width=1)
    d.text((16, H - 24), f'Red frame: screen pixels x {x}-{x + w - 1}, y {y}-{y + h - 1}, enlarged {Z} x below. '
                         f'Memory read with tools/ttd_dump.py at the end of frame {args.frame}.', fill=DIM,
           font=K.font(13))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    out.save(args.out)


if __name__ == '__main__':
    main()

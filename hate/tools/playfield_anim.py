#!/usr/bin/env python3
"""An animation of the scroll: the strips as stored beside the screen, one picture per sample of the recording
(docs/06-rendering.md). Needs an unreal-ng instance with the recording open (re_session.py open).

    python3 playfield_anim.py --work work/m1 --from 35500 --to 35620 --step 2 out.gif
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memanim  # noqa: E402
import playfield  # noqa: E402
import zxscreen  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=2, help='frames between samples')
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--delay', type=int, default=80)
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    p.add_argument('out')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    s, font = args.scale, ImageFont.load_default()
    w, h = 256 * s, 192 * s
    pictures = []
    for frame in range(args.start, args.end + 1, args.step):
        mem = memanim.memory_at(session, frame, 0)
        c32e, c32f = playfield.state_before(mem)
        img = Image.new('RGB', (2 * w + 48, h + 40), (24, 24, 30))
        draw = ImageDraw.Draw(img)
        panel = Image.new('RGB', (w, h), (12, 12, 16))
        for j, (d, e) in enumerate(playfield.strips(mem, c32e, c32f)):
            for k in range(128):
                playfield.bits(panel, j * 8 * s, (191 - k) * s, mem[(d << 8) | ((e + k) & 0xFF)], s)
        img.paste(panel, (16, 28))
        img.paste(zxscreen.render(mem[0x4000:0x5B00], s), (w + 32, 28))
        draw.text((16, 8), f'stored strips  $C32E={c32e:2d} $C32F=${c32f:02X}', fill=(220, 220, 200), font=font)
        draw.text((w + 32, 8), f'the screen, frame {frame}', fill=(220, 220, 200), font=font)
        pictures.append(img.convert('P', palette=Image.ADAPTIVE, colors=64))
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=args.delay, loop=0, optimize=True)
    print(args.out, len(pictures), 'pictures')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The object records of H.A.T.E. at a moment of the recording (docs/07-objects.md): a table of the live records
and, with --png, the screen with each visible one labelled.

The labels use the isometric projection read from the blit and `$EFA5` (x = distance - across, line = 215 -
distance / 2 - across / 2 - height, distance = position - `$D14D`); they land within a few pixels of the sprite.

    python3 objects_shot.py --work work/m1 FRAME [--png out.png] [--unreal <unreal-ng checkout>]
"""
import argparse
import os
import sys

from PIL import ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memanim  # noqa: E402
import zxscreen  # noqa: E402

NAMES = {0: 'player', 1: 'player', 2: 'dome', 3: 'dome', 4: 'missile', 5: 'missile', 6: 'missile', 7: 'missile',
         8: 'jet', 9: 'jet', 10: 'cube', 11: 'pod', 12: 'shot', 14: 'pad', 15: 'dish'}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--png')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    p.add_argument('frame', type=int)
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    mem = memanim.memory_at(session, args.frame, 0)
    img = zxscreen.render(mem[0x4000:0x5B00], 3)
    draw = ImageDraw.Draw(img)
    scrolled = mem[0xD14D] | mem[0xD14E] << 8
    a = 0xC000
    while not mem[a] & 0x40:
        r = mem[a:a + 16]
        if not r[0] & 0x80:
            dist = (r[1] | r[2] << 8) - scrolled
            print(f'{a:04X} type {r[0] & 15:2} {NAMES.get(r[0] & 15, ""):8} flags {r[0]:02X} distance {dist:5} '
                  f'across {r[3]:3} height {r[4]:3} dir {r[5]} speed {r[6]} behaviour {r[7]:02X}')
            if 0 <= dist < 0x11F:
                x, y = dist - r[3] - 8, 215 - dist // 2 - r[3] // 2 - r[4]
                draw.rectangle((x * 3, y * 3 - 30, x * 3 + 30, y * 3), outline=(255, 0, 255))
                draw.text((x * 3, y * 3 - 42), NAMES.get(r[0] & 15, str(r[0] & 15)), fill=(255, 255, 255))
        a += 16
    if args.png:
        img.save(args.png)


if __name__ == '__main__':
    main()

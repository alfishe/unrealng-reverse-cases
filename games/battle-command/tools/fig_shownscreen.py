#!/usr/bin/env python3
"""A GIF of the screen the player sees over a stretch of a recording: kit/screen_anim.py, but the 128K screen that
is shown, not always bank 5's.

Battle Command shows either the normal screen (bank 5 `$4000`) or the shadow screen (bank 7 `$C000`): the game keeps
the `$7FFD` screen bit as the `OR` operand at `$7284` (PageMain / PageShadowScreen in paging.asm), so each picture
reads that byte at the frame and takes the screen it names. Read with TTD `memory_at` from the instance that holds
the recording (`re_session.py open`).

    python3 tools/fig_shownscreen.py --work W --from 0 --to 640 --step 4 OUT.gif [--scale 2] [--label]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402
import zxscreen  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402


def read(session, space, frame, offset, length):
    r = session.call('time_travel', {'action': 'memory_at', 'space': space, 'frame': frame, 'tinframe': 0,
                                     'offset': offset, 'length': length}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def shown_screen(session, frame):
    """(screen bytes, 'bank 5' or 'bank 7') at the frame's start"""
    if read(session, 'cpu', frame, 0x7284, 1)[0] & 0x08:
        return read(session, 'ram', frame, 7 * 0x4000, 0x1B00), 'bank 7'
    return read(session, 'ram', frame, 5 * 0x4000, 0x1B00), 'bank 5'


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--delay', type=int, default=80)
    p.add_argument('--hold', type=int, default=1500)
    p.add_argument('--label', action='store_true', help='print the frame and the screen bank in a band below the screen')
    p.add_argument('out')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    pictures = []
    for f in range(args.start, args.end + 1, args.step):
        data, bank = shown_screen(session, f)
        im = zxscreen.render(data, args.scale).convert('RGB')
        if args.label:
            # a band of its own under the screen, so the label never hides a button or a text
            framed = Image.new('RGB', (im.width, im.height + 24), (0, 0, 0))
            framed.paste(im, (0, 0))
            im = framed
            d = ImageDraw.Draw(im)
            d.text((6, im.height - 20), f'frame {f}  {bank}', fill=(255, 255, 255), font=kitlib.font(14))
        pictures.append(im.convert('P', palette=0, colors=32))
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0, optimize=True)
    print(f'{args.out}: {len(pictures)} pictures')


if __name__ == '__main__':
    main()

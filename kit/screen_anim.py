#!/usr/bin/env python3
"""A GIF of the Spectrum screen over a stretch of a TTD recording (the case's docs): one picture every
--step frames, read with TTD memory_at from the unreal-ng instance that holds the recording.

    python3 screen_anim.py --work work/p2 --from 3300 --to 3520 --step 4 out.gif [--scale 2 | --width 1050]
           [--delay 80] [--hold 1500] [--unreal UNREAL_NG_CHECKOUT]

--scale N draws each Spectrum pixel as N x N (2: 512 x 384). --width W draws the picture W px wide instead (1050: the
documents' figure width, 1050 x 788): the screen at the largest whole scale that fits (4 for 1050), then resized to W
with a smooth filter, the colours kept to one palette for the whole GIF (kitlib.save_gif).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zxscreen  # noqa: E402


def screen_at(session, frame):
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                     'offset': 0x4000, 'length': 0x1B00}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(body['hex'])


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True, help='the work folder of the recording (session.json)')
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--scale', type=int, default=2, help='pixels per Spectrum pixel (2: 512 px)')
    p.add_argument('--width', type=int, default=0, help='the picture width in px (1050: the figure width); '
                                                       'overrides --scale')
    p.add_argument('--delay', type=int, default=80, help='ms per picture')
    p.add_argument('--hold', type=int, default=1500, help='ms on the last picture')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    p.add_argument('out')
    args = p.parse_args()
    import kitlib
    sys.path.insert(0, os.path.join(kitlib.unreal_root(args.unreal or None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    frames = range(args.start, args.end + 1, args.step)
    durations = [args.delay] * (len(frames) - 1) + [args.hold]
    if args.width:
        from PIL import Image
        whole = max(1, args.width // 256)
        pictures = []
        for f in frames:
            im = zxscreen.render(screen_at(session, f), whole).convert('RGB')
            if im.width != args.width:
                im = im.resize((args.width, round(im.height * args.width / im.width)), Image.LANCZOS)
            pictures.append(im)
        kitlib.save_gif(args.out, pictures, durations)
        print(f'{args.out}: {len(pictures)} pictures, {pictures[0].width} x {pictures[0].height}')
        return
    pictures = [zxscreen.render(screen_at(session, f), args.scale).convert('P', palette=0, colors=16)
                for f in frames]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0,
                     optimize=True)
    print(f'{args.out}: {len(pictures)} pictures')


if __name__ == '__main__':
    main()

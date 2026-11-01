#!/usr/bin/env python3
"""A GIF of the Spectrum screen over a stretch of a TTD recording (docs/10-gameplay-logic.md): one picture every
--step frames, read with TTD memory_at from the unreal-ng instance that holds the recording.

    python3 screen_anim.py --work work/p2 --from 3300 --to 3520 --step 4 out.gif [--scale 2] [--delay 80]
           [--unreal UNREAL_NG_CHECKOUT]
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
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--delay', type=int, default=80, help='ms per picture')
    p.add_argument('--hold', type=int, default=1500, help='ms on the last picture')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    p.add_argument('out')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    pictures = [zxscreen.render(screen_at(session, f), args.scale).convert('P', palette=0, colors=16)
                for f in range(args.start, args.end + 1, args.step)]
    durations = [args.delay] * (len(pictures) - 1) + [args.hold]
    pictures[0].save(args.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0,
                     optimize=True)
    print(f'{args.out}: {len(pictures)} pictures')


if __name__ == '__main__':
    main()

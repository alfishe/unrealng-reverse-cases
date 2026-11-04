#!/usr/bin/env python3
"""Screenshots of a TTD recording at named moments: the Spectrum screen as PNG, read with TTD memory_at from the
unreal-ng instance that holds the recording (re_session.py open).

    python3 screen_shot.py --work W --out-dir docs/img title=1200 menu=1450:0 play=3300 [--scale 2] [--screen 4000]

Each NAME=F[:T] gives OUT_DIR/NAME.png. T is TTD units in the frame; a frame alone is its end (memory_at's rule).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('--out-dir', required=True)
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--screen', default='4000')
    p.add_argument('--unreal')
    p.add_argument('shots', nargs='+', help='NAME=F[:T]')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    base = K.hex_address(args.screen)
    os.makedirs(args.out_dir, exist_ok=True)
    for shot in args.shots:
        name, _, moment = shot.partition('=')
        frame, _, t = moment.partition(':')
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame), 'offset': base, 'length': 0x1B00}
        if t:
            body['tinframe'] = int(t)
        r = session.call('time_travel', body, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data or not (r.structured or {}).get('exact', False):
            raise SystemExit(f'{shot}: memory_at: {r.text}')
        image = K.render_screen(bytes.fromhex(data), 0)
        image = image.resize((256 * args.scale, 192 * args.scale), resample=0)
        path = os.path.join(args.out_dir, name + '.png')
        image.save(path)
        print(path)


if __name__ == '__main__':
    sys.exit(main())

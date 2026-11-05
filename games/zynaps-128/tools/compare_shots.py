#!/usr/bin/env python3
"""The raw screens (6912 bytes from $4000) of a TTD recording at given frames, for tools/fig_compare.py.

The recording must be open in a live unreal-ng instance (re_session.py open / capture, its work folder W):

    python3 tools/compare_shots.py --work W --name c1 --out work/stage2/compare/shots 1990 2740 3460:12000

Each F[:T] gives OUT/NAME/F.scr (OUT/NAME/F-T.scr with a T-state). memory_at must answer exact (a frame alone is
its end, memory_at's rule). Real emulator memory only: fig_compare.py renders these bytes and nothing else.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, '..', '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True, help='the re_session.py work folder of the open recording')
    p.add_argument('--name', required=True, help='the recording name (the sub-folder of --out)')
    p.add_argument('--out', default=os.path.join(HERE, '..', 'work', 'stage2', 'compare', 'shots'))
    p.add_argument('--unreal')
    p.add_argument('moments', nargs='+', help='F[:T]')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    folder = os.path.join(args.out, args.name)
    os.makedirs(folder, exist_ok=True)
    for moment in args.moments:
        frame, _, t = moment.partition(':')
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame), 'offset': 0x4000, 'length': 0x1B00}
        if t:
            body['tinframe'] = int(t)
        r = session.call('time_travel', body, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data or not (r.structured or {}).get('exact', False):
            raise SystemExit(f'{moment}: memory_at: {r.text}')
        path = os.path.join(folder, moment.replace(':', '-') + '.scr')
        with open(path, 'wb') as f:
            f.write(bytes.fromhex(data))
        print(path)


if __name__ == '__main__':
    sys.exit(main())

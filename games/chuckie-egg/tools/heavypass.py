#!/usr/bin/env python3
"""The main loop's passes measured on a live instance through the WebAPI: from each state, N slow ticks; for each
the T-states from `$98BE` (the slow work) to the next `$9858` (the loop's top), and from `$9858` to `$98BE` (the
130 light passes before it). skip_until stops at a PC (breakpoints ignored); the beam's frame and T-state give the
time.

    python3 tools/heavypass.py --port-base 36210 --ticks 300 STATE.szx ...
"""
import argparse
import json
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402

FRAME_T = 69888


def now(lab):
    b = lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/video/beam'}).structured['body']
    return b['frame'] * FRAME_T + b['tstate_in_frame']


def skip(lab, pc):
    r = lab.post('/skip_until', {'pc': hex(pc), 'max_tstates': 5000000})
    return bool(r.get('hit'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('states', nargs='+')
    ap.add_argument('--ticks', type=int, default=300)
    ap.add_argument('--port-base', type=int, default=36210)
    ap.add_argument('--out')
    args = ap.parse_args()
    lab = Lab(args.port_base)
    result = {}
    try:
        for st in args.states:
            lab.load(st)
            heavy, light = [], []
            if not skip(lab, 0x9858):
                print(st, 'no main loop'); continue
            for _ in range(args.ticks):
                t0 = now(lab)
                if not skip(lab, 0x98BE):
                    break
                t1 = now(lab)
                if not skip(lab, 0x9858):
                    break
                t2 = now(lab)
                light.append(t1 - t0)
                heavy.append(t2 - t1)
            hs = sorted(heavy)
            r = dict(ticks=len(heavy), heavy_max=hs[-1], heavy_median=hs[len(hs) // 2], heavy_min=hs[0],
                     light_median=sorted(light)[len(light) // 2], light_max=max(light))
            result[st] = r
            print(st, r, flush=True)
    finally:
        lab.close()
    if args.out:
        json.dump(result, open(args.out, 'w'), indent=1)


if __name__ == '__main__':
    main()

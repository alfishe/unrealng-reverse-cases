#!/usr/bin/env python3
"""The play's passes timed on a live instance of ours (128K).

From each state, N passes: a pass runs from one exit of the frame wait `$7A53` (at `$7A5B`, the counter `$7A60`
reached C) to the next; its work is the part up to the next entry of `$7A53` (the rest is the wait). skip_until stops
at a PC (breakpoints ignored); the beam's frame and T-state give the time (70 908 T a 128K frame).

    python3 tools/passes.py --passes 300 STATE.z80|szx ... [--port-base 37500] [--out work/stage1/passes.json]
"""
import argparse
import json
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402

FRAME_T, WAIT, TOP = 70908, 0x7A53, 0x7A5B


def now(lab):
    b = lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/video/beam'}).structured['body']
    return b['frame'] * FRAME_T + b['tstate_in_frame']


def skip(lab, pc, frames=20):
    return bool(lab.post('/skip_until', {'pc': hex(pc), 'max_tstates': frames * FRAME_T}).get('hit'))


def stats(ts):
    s = sorted(ts)
    return dict(min=s[0], median=s[len(s) // 2], max=s[-1], frames_median=round(s[len(s) // 2] / FRAME_T, 2),
                frames_max=round(s[-1] / FRAME_T, 2), heaviest=ts.index(s[-1]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('states', nargs='+')
    ap.add_argument('--passes', type=int, default=300)
    ap.add_argument('--port-base', type=int, default=37500)
    ap.add_argument('--out')
    args = ap.parse_args()
    lab = Lab(args.port_base, os.environ.get("BIN"), "128K")
    result = {}
    try:
        for st in args.states:
            lab.load(st)
            if not skip(lab, TOP, 3000):
                print(st, 'no pass')
                continue
            t, passes, work = now(lab), [], []
            for _ in range(args.passes):
                if not skip(lab, WAIT):
                    break
                tw = now(lab)
                if not skip(lab, TOP):
                    break
                t2 = now(lab)
                work.append(tw - t)
                passes.append(t2 - t)
                t = t2
            r = dict(passes=len(passes), pass_t=stats(passes), work_t=stats(work),
                     over_one_frame=sum(1 for p in passes if p > FRAME_T + FRAME_T // 2))
            result[st] = r
            print(st, json.dumps(r), flush=True)
    finally:
        lab.close()
    if args.out:
        json.dump(result, open(args.out, 'w'), indent=1)


if __name__ == '__main__':
    main()

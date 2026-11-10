#!/usr/bin/env python3
"""The main loop's passes measured on a live instance through the WebAPI. The game runs with interrupts off except
at its main wait (`$795D-$7975`: `EI; NOP; HALT` at `$796B-$796D`, `DI` at `$796E`), so a pass is the time from one
wake (`$796E`, after the interrupt's handler `$95D0` returned) to the next: the work (`$796E` to the next `HALT`
`$796D`) and the wait with the handler (`$796D` to `$796E`). For each state, N passes with keys held (or none):
the T-states of the work, the handler's time (the wake's T-state in its frame: the interrupt comes at the
frame's T 0 and the handler draws the sprites before the wake), and the pass in frames (the frame numbers of two
wakes apart). skip_until stops at a PC
(breakpoints ignored); the beam's frame and T-state give the time.

The main loop (`$6911-$698F`) waits twice a pass (`CALL $795D` at `$6911` and `$6929`): each wait is a half-pass
here. The whole passes are measured too: from one `$6911` to the next, in frames and in T-states.

    python3 tools/passes.py --port-base 36910 --passes 300 [--keys X] --out work/stage1/passes.json STATE.szx ...
"""
import argparse
import json
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402

FRAME_T = 69888
WAKE, HALT, TOP = 0x796E, 0x796D, 0x6911


def now(lab):
    b = lab.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/video/beam'}).structured['body']
    return b['frame'], b['tstate_in_frame']


def skip(lab, pc):
    r = lab.post('/skip_until', {'pc': hex(pc), 'max_tstates': 20000000})
    return bool(r.get('hit'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('states', nargs='+')
    ap.add_argument('--passes', type=int, default=300)
    ap.add_argument('--keys', nargs='*', default=[])
    ap.add_argument('--port-base', type=int, default=36910)
    ap.add_argument('--out')
    args = ap.parse_args()
    lab = Lab(args.port_base)
    result = {}
    try:
        for st in args.states:
            lab.load(st)
            lab.keys(args.keys)
            work, frames, handler, rooms = [], [], [], []
            if not skip(lab, WAKE):
                print(st, 'no main loop')
                continue
            t0 = now(lab)
            for _ in range(args.passes):
                if not skip(lab, HALT):
                    break
                t1 = now(lab)
                if not skip(lab, WAKE):
                    break
                t2 = now(lab)
                work.append((t1[0] - t0[0]) * FRAME_T + t1[1] - t0[1])
                frames.append(t2[0] - t0[0])
                handler.append(t2[1])
                rooms.append(lab.read(0x6363, 1)[0])
                t0 = t2
            tops, room_of = [], []
            if skip(lab, TOP):
                a = now(lab)
                for _ in range(args.passes // 2):
                    if not skip(lab, TOP):
                        break
                    b = now(lab)
                    tops.append(((b[0] - a[0]) * FRAME_T + b[1] - a[1], b[0] - a[0]))
                    room_of.append(lab.read(0x6363, 1)[0])
                    a = b
            lab.keys([])
            whole_hist = {f: sum(1 for _, x in tops if x == f) for f in sorted({x for _, x in tops})}
            hk = max(range(len(tops)), key=lambda i: tops[i][0]) if tops else None
            hist = {f: frames.count(f) for f in sorted(set(frames))}
            k = max(range(len(work)), key=lambda i: work[i])
            r = dict(passes=len(work), work_median=sorted(work)[len(work) // 2], work_max=work[k],
                     work_max_index=k, work_max_frames=frames[k], frames_per_pass=hist,
                     mean_frames=round(sum(frames) / len(frames), 3), handler_median=sorted(handler)[len(handler) // 2],
                     handler_max=max(handler), heaviest_work_plus_handler=max(w + h for w, h in zip(work, handler)),
                     rooms=sorted(set(rooms)), passes_whole=len(tops), whole_frames=whole_hist,
                     whole_mean_frames=round(sum(x for _, x in tops) / len(tops), 3) if tops else None,
                     whole_t_median=sorted(t for t, _ in tops)[len(tops) // 2] if tops else None,
                     heaviest_whole_t=tops[hk][0] if tops else None,
                     heaviest_whole_frames=tops[hk][1] if tops else None)
            result[os.path.relpath(st)] = r
            print(st, r, flush=True)
    finally:
        lab.close()
    if args.out:
        json.dump(result, open(args.out, 'w'), indent=1)


if __name__ == '__main__':
    main()

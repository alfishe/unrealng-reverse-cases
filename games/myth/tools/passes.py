#!/usr/bin/env python3
"""The main-loop passes of a stretch of a recording: each pass from one fetch of the loop's top (`$7839` in the
stage blocks) to the next, its start (frame:t), its length in T-states and frames, the interrupts it took
(entries of `$FEFE`), and the T-states spent in the busy-wait `$79AB-$79B0`. The trace is taken once on the
re_session instance that holds the recording (kit/kitlib.py load_trace) and kept in W/traces/.

    python3 tools/passes.py --work work/stage1/c1o --window 16158-16658 [--top 7839] [--json OUT]
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    K.add_trace_args(ap)
    ap.add_argument('--top', default='7839')
    ap.add_argument('--json')
    a = ap.parse_args()
    top = int(a.top.lstrip('$'), 16)
    tr = K.load_trace(a)
    times = K.instruction_times(tr)
    ins = tr.instructions
    starts = [i for i, x in enumerate(ins) if x.pc == top]
    rows = []
    for i, j in zip(starts, starts[1:]):
        ints = sum(1 for k in range(i, j) if ins[k].pc == 0xFEFE)
        wait = sum(times[k + 1] - times[k] for k in range(i, j) if 0x79AB <= ins[k].pc <= 0x79B0)
        rows.append(dict(start=f'{ins[i].frame}:{ins[i].t // max(1, tr.units_per_t)}', t=times[j] - times[i],
                         frames=round((times[j] - times[i]) / tr.frame_t, 2), ints=ints, wait=wait))
    print('start\tT\tframes\tints\twaitT')
    for r in rows:
        print(f"{r['start']}\t{r['t']}\t{r['frames']}\t{r['ints']}\t{r['wait']}")
    if rows:
        s = sorted(r['t'] for r in rows)
        heavy = max(rows, key=lambda r: r['t'] - r['wait'])
        summary = dict(passes=len(rows), frame_t=tr.frame_t, min=s[0], median=s[len(s) // 2], max=s[-1],
                       frames_median=round(s[len(s) // 2] / tr.frame_t, 2), frames_max=round(s[-1] / tr.frame_t, 2),
                       heaviest_work=heavy)
        print(json.dumps(summary))
        if a.json:
            json.dump(dict(summary=summary, passes=rows), open(a.json, 'w'), indent=1)


if __name__ == '__main__':
    main()

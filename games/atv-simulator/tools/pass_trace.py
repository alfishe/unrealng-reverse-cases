#!/usr/bin/env python3
"""The work of every pass in a window of a recording, from its trace: Pass (`$D851`) to the first WaitFrames
(`$D86B`) after it, the interrupt entries inside included, in T and as a share of a pass's 7 x 69 888 = 489 216 T.
Unlike tools/pass_time.py (a replay with the keys set at pass starts) it measures the recording itself.

    python3 tools/pass_trace.py --work W --window 15150:0-15450:0 [--top 10]

W is a `kit/rs.py open` folder whose instance holds the recording (the trace is kept in W/traces/), or give
--trace FILE.uatr. Prints the count, the least and the most, and the heaviest passes with their start and end.
c1 over 15 150-15 450 and 15 400-15 800: the heaviest pass starts at frame 15 412, 446 565 T, 91.3 % (doc 04, 4.7).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PASS, WAIT, FRAMES = 0xD851, 0xD86B, 7


def main():
    ap = argparse.ArgumentParser()
    K.add_trace_args(ap)
    ap.add_argument('--top', type=int, default=10)
    a = ap.parse_args()
    tr = K.load_trace(a)
    frame_t, unit = tr.frame_t, max(1, tr.units_per_t)

    def at(x):
        return x.frame * frame_t + x.t // unit

    passes, start = [], None
    for x in tr.instructions:
        if x.pc == PASS:
            start = x
        elif x.pc == WAIT and start is not None:
            passes.append((at(x) - at(start), start.frame, start.t // unit, x.frame, x.t // unit))
            start = None
    if not passes:
        raise SystemExit('no whole pass in the window')
    budget = FRAMES * frame_t
    print(f'passes {len(passes)}, least {min(passes)[0]} T, most {max(passes)[0]} T')
    for w, f0, t0, f1, t1 in sorted(passes, reverse=True)[:a.top]:
        print(f'{w:7d} T {100 * w / budget:5.1f} %  Pass {f0} T {t0} to WaitFrames {f1} T {t1}')


if __name__ == '__main__':
    main()

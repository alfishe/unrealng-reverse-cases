#!/usr/bin/env python3
"""The work of every pass in a window of a recording, from its trace: Pass (`$D851`) to the first WaitFrames
(`$D86B`) after it, the interrupt entries inside included, in T and as a share of a pass's 7 x 69 888 = 489 216 T.
Unlike tools/pass_time.py (a replay with the keys set at pass starts) it measures the recording itself.

    python3 tools/pass_trace.py --work W --window 15150:0-15450:0 [--top 10]

W is a `kit/rs.py open` folder whose instance holds the recording (the trace is kept in W/traces/), or give
--trace FILE.uatr. Prints the count, the least and the most, and the heaviest passes with their start and end.
The kit's form: `python3 kit/pass_time.py --start D851 --end D86B --budget-frames 7 --work W --window ...`.
c1 over 15 150-15 450 and 15 400-15 800: the heaviest pass starts at frame 15 412, 446 565 T, 91.3 % (doc 04, 4.7).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import importlib.util  # noqa: E402
# kit/pass_time.py under its own name (this case has a tools/pass_time.py too)
_spec = importlib.util.spec_from_file_location('kit_pass_time', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit', 'pass_time.py'))
PT = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(PT)

PASS, WAIT, FRAMES = 0xD851, 0xD86B, 7


def main():
    ap = argparse.ArgumentParser()
    K.add_trace_args(ap)
    ap.add_argument('--top', type=int, default=10)
    a = ap.parse_args()
    found, frame_t = PT.trace_passes(K.load_trace(a), PASS, WAIT)
    passes = [(p['T'], p['start'][0], p['start'][1], p['end'][0], p['end'][1]) for p in found]
    if not passes:
        raise SystemExit('no whole pass in the window')
    budget = FRAMES * frame_t
    print(f'passes {len(passes)}, least {min(passes)[0]} T, most {max(passes)[0]} T')
    for w, f0, t0, f1, t1 in sorted(passes, reverse=True)[:a.top]:
        print(f'{w:7d} T {100 * w / budget:5.1f} %  Pass {f0} T {t0} to WaitFrames {f1} T {t1}')


if __name__ == '__main__':
    main()

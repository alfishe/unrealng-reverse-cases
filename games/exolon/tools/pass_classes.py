#!/usr/bin/env python3
"""Doc 04 table: MainLoop's passes of a recording by class, with the machine's own frame length.

    python3 tools/pass_classes.py --work work/docs/fillL/c128 --from 12000 --to 28215 --frame-t 70908

The passes and the classes are those of `tools/fig_pass_lengths.py` (its find_event caches WORK/passes-*.txt are
shared): a pass runs from one MainLoop `$75BE` start to the next, gaps over 5 000 000 T are the time between games,
and each pass takes the first class whose routine started inside it. `--frame-t` is the frame of the model the
recording ran on: 69 888 T on the 48K, 70 908 T on the 128K.
"""
import argparse
import bisect
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exlib  # noqa: E402
import fig_pass_lengths as L  # noqa: E402


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='lo', type=int, required=True)
    p.add_argument('--to', dest='hi', type=int, required=True)
    p.add_argument('--frame-t', type=int, default=69888)
    a = p.parse_args()
    ft = a.frame_t
    s = lambda: exlib.session(a.work)  # noqa: E731
    starts = [f * ft + t for f, t in L.hits(s, a.work, '75BE', a.lo, a.hi)]
    marks = {name: sorted(f * ft + t for ad in addrs for f, t in L.hits(s, a.work, ad, a.lo, a.hi))
             for name, addrs, _ in L.CLASSES}
    passes = {name: [] for name, _, _ in L.CLASSES}
    for k in range(len(starts) - 1):
        x, y = starts[k], starts[k + 1]
        if y - x > 5000000:
            continue
        for name, addrs, _ in L.CLASSES:
            m = marks[name]
            i = bisect.bisect_left(m, x)
            if not addrs or (i < len(m) and m[i] < y):
                passes[name].append(y - x)
                break
    print(f'{len(starts)} pass starts, {sum(len(v) for v in passes.values())} complete passes, frame {ft} T')
    print('| Class | Passes | Median | Range |')
    print('| --- | ---: | ---: | --- |')
    for name, _, _ in L.CLASSES:
        v = sorted(passes[name])
        if v:
            med = v[len(v) // 2]
            print(f'| {name} | {len(v)} | {med} T ({med / ft:.2f} frames) | {v[0]}-{v[-1]} T |')


if __name__ == '__main__':
    main()

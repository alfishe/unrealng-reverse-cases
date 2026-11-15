#!/usr/bin/env python3
"""Frames per pass over a window of a recording: the frame counter `$7A8A` (the interrupt `$BE23` adds 1, the main
loop `$8649` sets 0 at the top of each pass and waits at `$868C` until it is 3) read at the start of every frame
through `time_travel memory_at` (no seek), from the instance a re_session.py work folder names.

    python3 tools/pass_frames.py --work work/stage1/rec/l2 --from 4000 --to 6000 [--csv OUT.csv]

A pass starts where the sampled counter falls (the reset at `$8649`); its length in frames is the distance to the
next fall. Prints the histogram of pass lengths, the mean frames a pass over the whole passes inside the window, and
the longest passes with their first frame (the heaviest work). The counter is sampled at each frame's start, so a
pass is placed to the frame in which its reset was first seen.
"""
import argparse
import collections
import json
import os
import sys

sys.path.insert(0, os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'), 'tools',
                                'verification', 'mcp'))
import mcplib  # noqa: E402

COUNTER = 0x7A8A


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='frm', type=int, required=True)
    ap.add_argument('--to', type=int, required=True)
    ap.add_argument('--csv')
    a = ap.parse_args()
    d = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{d['port_base'] + 200}/mcp", d['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    vals = []
    for f in range(a.frm, a.to + 1):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                   'offset': COUNTER, 'length': 1})
        vals.append(bytes.fromhex((r.structured or {})['hex'])[0])
    if a.csv:
        with open(a.csv, 'w') as o:
            o.write('frame,counter\n')
            for i, v in enumerate(vals):
                o.write(f'{a.frm + i},{v}\n')
    starts = [a.frm + i for i in range(1, len(vals)) if vals[i] < vals[i - 1]]
    lens = [(b - x, x) for x, b in zip(starts, starts[1:])]
    hist = collections.Counter(n for n, _ in lens)
    print(f'window {a.frm}-{a.to}: {len(lens)} whole passes from frame {starts[0]} to {starts[-1]}')
    print('frames a pass: ' + ', '.join(f'{k}: {hist[k]}' for k in sorted(hist)))
    if lens:
        print(f'mean {(starts[-1] - starts[0]) / len(lens):.3f} frames a pass')
        print('longest: ' + ', '.join(f'{n} frames from {x}' for n, x in sorted(lens, key=lambda t: -t[0])[:8]))


if __name__ == '__main__':
    main()

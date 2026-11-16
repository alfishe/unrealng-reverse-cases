#!/usr/bin/env python3
"""Frames per main-loop pass of a recording: the pass counter `$7C2E` (+1 a pass, found by its steady +1 steps)
read at each frame of a window through `time_travel memory_at`; prints the histogram of frames between steps and
the frames of the longest passes.

    python3 tools/pass_frames.py --work work/stage1/open-c1 --from 14075 --to 19265 [--addr 7C2E] [--every 1]
"""
import argparse
import json
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'), 'tools',
                                'verification', 'mcp'))
import mcplib  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='f0', type=int, required=True)
    ap.add_argument('--to', dest='f1', type=int, required=True)
    ap.add_argument('--addr', default='7C2E')
    a = ap.parse_args()
    d = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{d['port_base'] + 200}/mcp", d['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    addr = int(a.addr, 16)
    prev, last, gaps = None, None, []
    for f in range(a.f0, a.f1):
        v = bytes.fromhex(s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                                 'offset': addr, 'length': 1}).structured['hex'])[0]
        if prev is not None and v != prev:
            if last is not None:
                gaps.append((f - last, last))
            last = f
        prev = v
    h = Counter(g for g, _ in gaps)
    print(f'{len(gaps)} passes in frames {a.f0}-{a.f1}: ' + ', '.join(f'{k} frames x{h[k]}' for k in sorted(h)))
    print('mean', round(sum(g for g, _ in gaps) / max(1, len(gaps)), 2))
    print('longest:', sorted(gaps, reverse=True)[:5])


if __name__ == '__main__':
    main()

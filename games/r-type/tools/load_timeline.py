#!/usr/bin/env python3
"""The load as a timeline: the 64 K view of a recording every STEP frames through `time_travel memory_at` (no seek),
from the instance a re_session.py work folder names, and the address ranges that changed since the last sample.

    python3 tools/load_timeline.py --work work/stage1/c1 --from 2599 --to 11702 --step 100 [--out DIR]

Prints one line per sample that changed something: the frame and the changed ranges (gaps under 64 bytes joined),
with their sizes. With --out, keeps each sample as DIR/FRAME.bin (the 64 K at the frame's start).
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'), 'tools',
                                'verification', 'mcp'))
import mcplib  # noqa: E402


def dump(s, frame):
    out = b''
    for off in range(0, 0x10000, 0x4000):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                   'offset': off, 'length': 0x4000})
        out += bytes.fromhex((r.structured or {})['hex'])
    return out


def ranges(a, b, gap=64):
    out, start, last = [], None, None
    for i in range(0x4000, 0x10000):
        if a[i] != b[i]:
            if start is None:
                start = i
            elif i - last > gap:
                out.append((start, last))
                start = i
            last = i
    if start is not None:
        out.append((start, last))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='frm', type=int, required=True)
    ap.add_argument('--to', type=int, required=True)
    ap.add_argument('--step', type=int, default=100)
    ap.add_argument('--out')
    a = ap.parse_args()
    d = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{d['port_base'] + 200}/mcp", d['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    if a.out:
        os.makedirs(a.out, exist_ok=True)
    prev = None
    frames = list(range(a.frm, a.to, a.step)) + [a.to]
    for f in frames:
        cur = dump(s, f)
        if a.out:
            open(os.path.join(a.out, f'{f:06d}.bin'), 'wb').write(cur)
        if prev is not None:
            rs = ranges(prev, cur)
            if rs:
                print(f, ' '.join(f'${x:04X}-${y:04X}({y - x + 1})' for x, y in rs), flush=True)
        prev = cur


if __name__ == '__main__':
    main()

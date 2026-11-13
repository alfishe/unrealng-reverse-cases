#!/usr/bin/env python3
"""Bytes of a recording over its frames through `time_travel memory_at` (no seek), from the instance a re_session.py
work folder names (`$RS open` first): for each frame FROM, FROM+STEP, ... TO the bytes at each address, printed
where any of them changed.

    python3 tools/ttd_watch.py --work work/stage1/energy --addr 837D,81FF --from 0 --to 18500 --step 50
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ttd_dump import mcplib, read  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--addr', required=True)
    ap.add_argument('--from', dest='a', type=int, default=0)
    ap.add_argument('--to', type=int, required=True)
    ap.add_argument('--step', type=int, default=50)
    a = ap.parse_args()
    d = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{d['port_base'] + 200}/mcp", d['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    addrs = [int(x, 16) for x in a.addr.split(',')]
    last = None
    for f in range(a.a, a.to + 1, a.step):
        v = tuple(read(s, 'cpu', f, 0, x, 1)[0][0] for x in addrs)
        if v != last:
            print(f, ' '.join(f'${x:04X}={b:02X}' for x, b in zip(addrs, v)), flush=True)
            last = v


if __name__ == '__main__':
    main()

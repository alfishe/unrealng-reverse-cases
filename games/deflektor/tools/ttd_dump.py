#!/usr/bin/env python3
"""Dump memory of a recording at a moment through `time_travel memory_at` (no seek): the 64 K CPU view and the eight
RAM pages of a 128K, from the instance a re_session.py work folder names.

    python3 tools/ttd_dump.py --work work/stage1/c1 --frame 21597 --t 67875 --out work/images/entry

Writes OUT.cpu.bin (65536 bytes, the pages paged in then) and OUT.ram.bin (8 x 16384 bytes, page 0 first; 128K only),
and OUT.json (the frame, T-state and the paging memory_at reports).
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.join(os.environ.get("UNREAL_NG", "/Volumes/TB4-4Tb/Projects/Test/unreal-ng"), "tools", "verification", "mcp"))
import mcplib  # noqa: E402


def read(s, space, frame, t, off, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': space, 'frame': frame, 'tinframe': t,
                               'offset': off, 'length': n})
    st = r.structured or {}
    return bytes.fromhex(st['hex']), st


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--frame', type=int, required=True)
    ap.add_argument('--t', type=int, default=0)
    ap.add_argument('--out', required=True)
    ap.add_argument('--no-ram', action='store_true')
    a = ap.parse_args()
    d = json.load(open(os.path.join(a.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{d['port_base'] + 200}/mcp", d['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    cpu, info = b'', None
    for off in range(0, 0x10000, 0x4000):
        b, st = read(s, 'cpu', a.frame, a.t, off, 0x4000)
        cpu += b
        info = info or st
    open(a.out + '.cpu.bin', 'wb').write(cpu)
    meta = {'work': a.work, 'frame': a.frame, 't': a.t, 'banks': info.get('banks')}
    if d['model'] != '48K' and not a.no_ram:
        ram = b''
        for p in range(8):
            b, _ = read(s, 'ram', a.frame, a.t, p * 0x4000, 0x4000)
            ram += b
        open(a.out + '.ram.bin', 'wb').write(ram)
    json.dump(meta, open(a.out + '.json', 'w'), indent=1)
    print(a.out, json.dumps(meta['banks']))


if __name__ == '__main__':
    main()

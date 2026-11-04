#!/usr/bin/env python3
"""Dumps memory of a recording at a moment (time_travel memory_at) from the instance a work folder holds.

  ttd_dump.py --work W --frame F [--tinframe T] --out DIR/NAME [--pages 0-7] [--cpu]

Writes NAME-bankN.bin (16 K each, space ram, page N at N x 0x4000) for the pages asked and, with --cpu, NAME-cpu.bin
(the 64 K Z80 view at that moment). Refuses a read that is not exact. The unreal-ng checkout is $UNREAL_NG or the
reverse-cases repository's submodule.
"""

import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402


def session(work):
    state = json.load(open(os.path.join(work, 'session.json')))
    return mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])


def read(s, space, frame, tinframe, offset, length):
    body = {'action': 'memory_at', 'space': space, 'frame': frame, 'offset': offset, 'length': length}
    if tinframe is not None:
        body['tinframe'] = tinframe
    r = s.call('time_travel', body, ok=False)
    st = r.structured or {}
    if r.is_error or not st.get('exact', False) or len(st.get('hex', '')) != 2 * length:
        raise SystemExit(f'memory_at {space} frame {frame} t {tinframe} +{offset:#x}: {r.text[:300]}')
    return bytes.fromhex(st['hex'])


def pages_of(text):
    a, _, b = text.partition('-')
    return range(int(a), int(b or a) + 1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True)
    p.add_argument('--frame', type=int, required=True)
    p.add_argument('--tinframe', type=int)
    p.add_argument('--out', required=True)
    p.add_argument('--pages', default='0-7')
    p.add_argument('--cpu', action='store_true')
    args = p.parse_args()
    s = session(args.work)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    for n in pages_of(args.pages):
        data = read(s, 'ram', args.frame, args.tinframe, n * 0x4000, 0x4000)
        open(f'{args.out}-bank{n}.bin', 'wb').write(data)
    if args.cpu:
        data = b''.join(read(s, 'cpu', args.frame, args.tinframe, o, 0x4000) for o in range(0, 0x10000, 0x4000))
        open(f'{args.out}-cpu.bin', 'wb').write(data)


if __name__ == '__main__':
    main()

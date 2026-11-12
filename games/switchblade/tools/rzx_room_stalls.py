#!/usr/bin/env python3
"""Split the RZX run's room-change stalls into the room build (EnterRoom $95C3 .. its RET $95F8), the zone reveals
(CALL RedrawCellsMasked $959A .. $959D) and the passes (MainLoop $8DFE fetches). Prints one TSV line per event in the
windows [change-2, change+120] of the room-change stalls of stalls.json.

    python3 tools/rzx_room_stalls.py RZX STALLS.json STOP > OUT.tsv
"""
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402

EV = {0x8DFE: 'pass', 0x95C3: 'enter', 0x95E6: 'planes_done', 0x95EA: 'redraw_room', 0x95ED: 'redraw_room_done',
      0x95F8: 'enter_ret', 0x959A: 'reveal', 0x959D: 'reveal_done'}
rzx, stalls, stop = sys.argv[1], sys.argv[2], int(sys.argv[3])
W = [(s['from'] - 2, s['from'] + 120) for s in json.load(open(stalls))['stalls'] if s['room_change'] and s['from'] < stop]
LIVE = set()
SEEN = set()
for a, b in W:
    LIVE.update(range(a, b + 1))
print('frame\tfetch\tevent\troom')


def hook(tracefile, context, fetch_counter, pc):
    e = EV.get(pc)
    if e and context.frame_count in LIVE:
        if e == 'pass':
            if context.frame_count in SEEN:
                return
            SEEN.add(context.frame_count)
        print(f'{context.frame_count}\t{fetch_counter}\t{e}\t{context.simulator.memory[0x6BDD]}')


rzxplay.trace_exec = hook
d = os.path.join(os.path.dirname(os.path.abspath(stalls)), 'trace.dummy')
try:
    rzxplay.main([rzx, '--quiet', '--no-screen', '--trace', d, '--stop', str(stop)])
finally:
    if os.path.exists(d):
        os.remove(d)

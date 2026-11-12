#!/usr/bin/env python3
"""The whole RZX Archive run as our own recordings: one tools/rzx_replay.py segment of 2000 frames from each
tools/rzx_snap.py snapshot (work/stage2/rzx/snap-FFFFFF.z80), work/stage2/rzx/rFFFFFF/ with its l1.json; a
segment whose l1.json exists is skipped. Two workers split the segments (--worker 0 / 1 of --workers 2), each on its
own port base.

    python3 tools/rzx_capture.py --port-base 37470 --worker 0 --workers 2
    python3 tools/rzx_capture.py --port-base 37475 --worker 1 --workers 2

The key replay drifts (the main loop runs free, and a held key moves Hiro by the passes it lasts; our machine's
timing is not SPIN's), so each segment restarts from the RZX's own state; record.json gives each segment's
divergences from the RZX's state (tools/rzx_snap.py state.tsv).

    python3 tools/rzx_capture.py --rooms --port-base 37470 [--only 12345,...]

--rooms: one 300-frame segment from 15 frames before the RZX first enters each room (snapshots in
work/stage2/rzx/rooms, tools/rzx_snap.py --snap at those frames), work/stage2/rzx/rooms/eFFFFFF/: the room's build
and first moments as our own recording, whatever the 2000-frame segments' drift missed.
"""
import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
LAST = 142957  # the RZX's last frame + 1 (tools/rzx_snap.py)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port-base', type=int, required=True)
    ap.add_argument('--worker', type=int, default=0)
    ap.add_argument('--workers', type=int, default=1)
    ap.add_argument('--step', type=int, default=2000)
    ap.add_argument('--only', default='')
    ap.add_argument('--rooms', action='store_true')
    a = ap.parse_args()
    rooms = os.path.join(CASE, 'work', 'stage2', 'rzx', 'rooms')
    if a.rooms:
        a.step = 300
        starts = sorted(int(f[5:11]) for f in os.listdir(rooms) if f.startswith('snap-') and f != 'snap-000000.z80')
    else:
        starts = list(range(0, LAST, a.step))
    if a.only:
        starts = [int(x) for x in a.only.split(',')]
    for k, s in enumerate(starts):
        if k % a.workers != a.worker:
            continue
        work = os.path.join(rooms, f'e{s:06d}') if a.rooms else os.path.join(CASE, 'work', 'stage2', 'rzx', f'r{s:06d}')
        if os.path.exists(os.path.join(work, 'l1.json')):
            continue
        e = min(s + a.step, LAST)
        print(f'segment {s}-{e}', flush=True)
        subprocess.run([sys.executable, os.path.join(HERE, 'rzx_replay.py'), str(s), str(e), '--work', work,
                        '--port-base', str(a.port_base)] + (['--snaps', rooms] if a.rooms else []), cwd=CASE)


if __name__ == '__main__':
    main()

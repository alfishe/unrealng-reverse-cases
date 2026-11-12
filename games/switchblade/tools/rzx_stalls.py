#!/usr/bin/env python3
"""The main loop's stalls in the RZX run, and what the CPU did in each: runs of 10 or more frames in which the main
loop (`$8DFE`) was not fetched (work/stage1/passes.tsv, tools/rzx_passes.py), split into those that begin within 3
frames of a room change (tools/rzx_snap.py OUT/state.tsv) and the others; for every stall, SkoolKit's rzxplay is run
with a per-instruction hook and the instructions fetched in the stall's frames are counted by address.

    PYTHONPATH=$SKOOLKIT_VENV/lib/python3.12/site-packages python3 tools/rzx_stalls.py RZX PASSES.tsv STATE.tsv OUT.json

OUT.json: {"stalls": [{"from", "frames", "room_change", "pcs": {ADDR: count, ...}}]} (the 40 busiest addresses of each
stall); the case's .ann names them (tools/l1q.py, src/game/game.ann).
"""
import argparse
import collections
import json
import os
import tempfile

from skoolkit import rzxplay

WINDOWS = []      # (first, last) frames of the stalls to trace
PCS = {}          # first frame -> Counter
CTX = []


def hook(tracefile, context, fetch_counter, pc):
    f = context.frame_count
    for a, b in WINDOWS:
        if a <= f <= b:
            PCS.setdefault(a, collections.Counter())[pc] += 1
            return


def stalls(passes, state, horizon):
    ran = set()
    with open(passes) as f:
        f.readline()
        for line in f:
            k, p, _ = (int(x) for x in line.split())
            if p:
                ran.add(k)
    room, changes = None, []
    with open(state) as f:
        f.readline()
        for line in f:
            v = line.split()
            if v[1] != room:
                if room is not None:
                    changes.append(int(v[0]))
                room = v[1]
    first, last = min(ran), min(max(ran), horizon)
    out, k = [], first
    while k <= last:
        if k not in ran:
            j = k
            while j + 1 <= last and j + 1 not in ran:
                j += 1
            n = j - k + 1
            if n >= 10:
                near = [c for c in changes if k - 3 <= c <= k + 3]
                out.append({'from': k, 'frames': n, 'room_change': near[0] if near else None})
            k = j + 1
        else:
            k += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('passes')
    ap.add_argument('state')
    ap.add_argument('out')
    ap.add_argument('--all', action='store_true', help='trace the room-change stalls too')
    a = ap.parse_args()
    found = stalls(a.passes, a.state, 10 ** 9)
    trace = [s for s in found if a.all or s['room_change'] is None]
    WINDOWS.extend((s['from'], s['from'] + s['frames'] - 1) for s in trace)
    stop = max(b for _, b in WINDOWS) + 1
    rzxplay.trace_exec = hook
    dummy = os.path.join(tempfile.mkdtemp(dir=os.path.dirname(os.path.abspath(a.out))), 'trace')
    rzxplay.main([a.rzx, '--quiet', '--no-screen', '--trace', dummy, '--stop', str(stop)])
    for s in found:
        c = PCS.get(s['from'])
        if c:
            s['instructions'] = sum(c.values())
            s['pcs'] = {f'${pc:04X}': n for pc, n in c.most_common(40)}
    json.dump({'stalls': found}, open(a.out, 'w'), indent=1)
    print(f'{len(found)} stalls of 10 frames or more, {len(trace)} away from a room change, traced')


if __name__ == '__main__':
    main()

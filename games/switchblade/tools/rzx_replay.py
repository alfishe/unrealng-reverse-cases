#!/usr/bin/env python3
"""A segment of the RZX Archive run as a normal recording of our own, with its L1: the 48K machine loads
tools/rzx_snap.py's snap-FROM.z80 (the state at the end of RZX frame FROM-1), the TTD recording starts, and the input
script tests/inputs/rzx-FROM.txt (tools/rzx_script.py: the keys the RZX's player held, frame by frame) is played.
Every CHECK frames, and at each key change, the game's state (the room `$6BDD`, the map row and column, Hiro's Y and
X, the lives, the energy) is compared with the RZX's own (tools/rzx_snap.py OUT/state.tsv); every difference is
logged (record.json "diverged"). Then end.szx, session.ttd, l1.json and record.json, as tools/record.py leaves them.

    python3 tools/rzx_replay.py FROM TO --work work/stage2/rzx/rFROM [--port-base 37470] [--stop-on-divergence]

The game reads the keys once a frame in the interrupt (ReadControls `$8529`), so a frame-exact replay of the held
keys gives the RZX's run as long as the machine's timing does not move an event across a frame boundary.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402
import rzx_script  # noqa: E402

RZX = os.path.join(CASE, 'work', 'stage2', 'rzx')
STATE = (('room', 0x6BDD), ('row', 0x69DF), ('col', 0x69E0), ('y', 0x5D00), ('x', 0x5D01), ('lives', 0x664D),
         ('energy', 0x6642))


def rzx_state():
    rows = {}
    with open(os.path.join(RZX, 'state.tsv')) as f:
        head = f.readline().split()
        for line in f:
            v = [int(x) for x in line.split()]
            rows[v[0]] = dict(zip(head[1:], v[1:]))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('start', type=int)
    ap.add_argument('stop', type=int)
    ap.add_argument('--work', required=True)
    ap.add_argument('--port-base', type=int, default=37470)
    ap.add_argument('--check', type=int, default=250)
    ap.add_argument('--stop-on-divergence', action='store_true')
    ap.add_argument('--no-build', action='store_true')
    ap.add_argument('--snaps', default=RZX, help='the folder of snap-FROM.z80 (default work/stage2/rzx; the room '
                    'entries: work/stage2/rzx/rooms)')
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    snap = os.path.join(a.snaps, f'snap-{a.start:06d}.z80')
    lines = rzx_script.script(os.path.join(RZX, 'inputs.json'), a.start, a.stop)
    name = os.path.basename(work)
    os.makedirs(os.path.join(CASE, 'tests', 'inputs'), exist_ok=True)
    open(os.path.join(CASE, 'tests', 'inputs', f'{name}.txt'), 'w').write('\n'.join(lines) + '\n')
    events = []
    for line in lines:
        if line.startswith('#'):
            continue
        f, keys = line.split()
        events.append((int(f), [] if keys in ('-', 'END') else keys.split('+'), keys == 'END'))
    ref = rzx_state()
    lab = Lab(a.port_base, model='48K')
    lab.session_json(work)
    began = time.time()
    diverged, rooms = [], {}
    try:
        lab.load(snap)
        lab.start_recording()
        lab.frame = 0

        def check():
            got = lab.read(0x5D00, 2) + lab.read(0x6642, 12) + lab.read(0x69DF, 2) + lab.read(0x6BDD, 1)
            now = {'y': got[0], 'x': got[1], 'energy': got[2], 'lives': got[2 + 11], 'row': got[14], 'col': got[15],
                   'room': got[16]}
            rooms.setdefault(now['room'], lab.frame)
            want = ref.get(a.start + lab.frame - 1)  # the RZX's state at the end of the frame before
            if want and any(now[k] != want[k] for k in now):
                diverged.append({'frame': lab.frame, 'rzx_frame': a.start + lab.frame - 1, 'ours': now,
                                 'rzx': {k: want[k] for k in now}})
                return True
            return False

        for (f, keys, end), nxt in zip(events, events[1:] + [None]):
            lab.keys(keys)
            if end:
                break
            stop = nxt[0]
            while lab.frame < stop:
                n = min(stop - lab.frame, a.check - lab.frame % a.check)
                lab.run(n)
                if lab.frame % a.check == 0 or lab.frame == stop:
                    if check() and a.stop_on_divergence:
                        raise StopIteration
        lab.keys([])
    except StopIteration:
        pass
    try:
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': 'rzx_replay', 'note': __doc__.split('\n\n')[0], 'model': '48K',
               'start': os.path.relpath(snap, CASE), 'rzx_frames': [a.start, a.stop], 'frames': lab.frame,
               'rooms': {str(k): v for k, v in rooms.items()},
               'rzx_rooms': sorted({r['room'] for f, r in ref.items() if a.start <= f < a.stop}),
               'diverged': diverged[:50], 'diverged_count': len(diverged), 'pokes': [],
               'script': f'tests/inputs/{name}.txt'}
        s = lab.s
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        if not a.no_build:
            try:
                s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 1000}, ok=False)
            except OSError as e:
                rec['build_call'] = str(e)
            st = ''
            for _ in range(720):
                try:
                    st = s.call('analysis', {'action': 'status'}, ok=False).text
                except OSError:
                    st = ': running'
                if ': running' not in st and os.path.exists(os.path.join(work, 'l1.json')):
                    break
                time.sleep(10)
            rec['status'] = st.splitlines()[-3:]
        rec['seconds'] = round(time.time() - began)
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k: rec.get(k) for k in ('frames', 'diverged_count', 'status', 'seconds')}, indent=1))
        if diverged:
            print('first divergence', json.dumps(diverged[0]))
    finally:
        lab.close()


if __name__ == '__main__':
    main()

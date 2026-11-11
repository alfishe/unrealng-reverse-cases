#!/usr/bin/env python3
"""The armour recording (docs 07 and 10): the death plan of tools/record.py (Blast Em Mission, the Turret, the tank
driven ahead and turned, the cannon fired) with a POKE at the mission start that sets the four armour bytes
`$8301-$8304` to 1. The first enemy hit then empties a gauge: PlayerHit `$CAA5` takes the underflow branch to
ArmourDestroyed `$CB38`, the failure reason `$7BF9` = `$CCAB` "UNIT DESTROYED" and the mission-failed screen. The POKE
is on the recording's machine only. The plan stops 400 frames after the failure reason is set.

    python3 tools/rec_armour.py --work work/docs/bcC/rec/armour --port-base 37370 \
        --start work/stage1/explore/loaded.szx

Writes session.ttd, end.szx, l1.json, record.json and inputs.txt (the keys held) into the work folder.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402
from record import Run, mission_tape, load_mission, fit, k, STORES  # noqa: E402


def plan_armour(r):
    r.shot('title')
    mission_tape(r)
    load_mission(r, 1)
    fit(r, {1: 'Turret'})
    r.b.click(*STORES['start'], after=150)
    r.shot('start')
    r.moments.append({'frame': r.lab.frame, 'name': 'armour-before', 'value': list(r.lab.read(0x8301, 4))})
    r.poke(0x8301, [1, 1, 1, 1], 'armour 1 on every side and the top (the death by armour)')
    k(r, '1', 10)
    for i in range(60):
        r.b.hold(['Q'] if i % 4 else ['Q', 'O'], 150)
        k(r, 'SPACE', 25)
        fail = r.lab.read(0x7BF9, 2)
        r.moments.append({'frame': r.lab.frame, 'name': f'drive-{i:02d}', 'armour': list(r.lab.read(0x8301, 4)),
                          'fail': fail[0] | fail[1] << 8})
        r.shot(f'drive-{i:02d}')
        if fail[0] | fail[1]:
            break
    r.b.wait(400)
    r.shot('end')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--port-base', type=int, default=37370)
    ap.add_argument('--start', required=True)
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    lab = Lab(a.port_base)
    lab.session_json(work)
    r = Run(lab, work)
    began = time.time()
    try:
        lab.load(os.path.abspath(a.start))
        lab.start_recording()
        lab.frame = 0
        r.b.t0 = 0
        plan_armour(r)
        lab.keys([])
        lab.save(os.path.join(work, 'end.szx'))
        rec = {'plan': 'armour', 'note': plan_armour.__doc__ or __doc__.split('\n\n')[0], 'start': a.start,
               'frames': lab.frame, 'moments': r.moments, 'mouse': r.b.mouse_log, 'tape': r.tape_log,
               'pokes': r.pokes, 'seconds': round(time.time() - began)}
        r.b.script(os.path.join(work, 'inputs.txt'), start=0)
        s = lab.s
        s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 30000})
        st = s.call('analysis', {'action': 'status'}).text
        while ': running' in st:
            time.sleep(5)
            st = s.call('analysis', {'action': 'status'}).text
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k2: rec[k2] for k2 in ('frames', 'ttd', 'seconds')}, indent=1))
    finally:
        lab.close()


if __name__ == '__main__':
    main()

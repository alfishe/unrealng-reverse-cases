#!/usr/bin/env python3
"""A recording of the RZX Archive run (work/candidates/rzxarchive/myth.rzx, SPIN 0.5, 100 151 frames in six
segments, each from a 128K Z80 snapshot: the menu, then each stage as loaded): unreal-ng plays the RZX
(rzx_playback: every IN and interrupt from the file, so the split of the run into calls does not change it) on a
fresh muted 128K, with the TTD recording started at RZX frame FROM (the frames before it played unrecorded), for
FRAMES frames; screens every --every frames, then end.szx, l1.json, session.ttd and record.json. Another player's
run: a witness only where the documents say so.

    python3 tools/rec_rzx.py --work work/stage1/rec/rzx-s1 --from 0 --frames 32896 [--port-base 37475]
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

RZX = os.path.join(CASE, 'work', 'candidates', 'rzxarchive', 'myth.rzx')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--from', dest='start', type=int, default=0)
    ap.add_argument('--frames', type=int, required=True)
    ap.add_argument('--every', type=int, default=500)
    ap.add_argument('--port-base', type=int, default=37475)
    ap.add_argument('--ranges', default='4000-FFFF')
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(os.path.join(work, 'screens'), exist_ok=True)
    lab = Lab(a.port_base, model='128K')
    lab.session_json(work, a.ranges)
    began = time.time()
    rec = {'rzx': os.path.relpath(RZX, CASE), 'from': a.start, 'frames': a.frames, 'moments': [], 'status_rzx': []}
    try:
        r = lab.s.call('rzx_playback', {'action': 'play', 'path': RZX}, ok=False)
        rec['play'] = r.text
        lab.s.call('control_execution', {'action': 'pause'}, ok=False)
        lab.mute()
        lab.s.call('control_execution', {'action': 'take_control'}, ok=False)
        done = 0
        while done < a.start:
            n = min(5000, a.start - done)
            lab.run(n)
            done += n
        rec['status_rzx'].append(lab.s.call('rzx_playback', {'action': 'status'}, ok=False).text)
        lab.save(os.path.join(work, 'start.szx'))
        lab.start_recording()
        lab.frame = 0
        while lab.frame < a.frames:
            lab.run(min(a.every, a.frames - lab.frame))
            name = f'{lab.frame:06d}-rzx{a.start + lab.frame:06d}.png'
            lab.shot(os.path.join(work, 'screens', name))
            rec['moments'].append({'frame': lab.frame, 'rzx_frame': a.start + lab.frame})
        rec['status_rzx'].append(lab.s.call('rzx_playback', {'action': 'status'}, ok=False).text)
        lab.save(os.path.join(work, 'end.szx'))
        s = lab.s
        # the TTD first: a build that outlives the HTTP timeout must not lose the recording
        d = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        rec['ttd'] = (d.text or '').splitlines()[:2]
        # no L1: unreal-ng's analysis instance refuses a session recorded during RZX playback ("this machine
        # cannot take the session: device rzxplayback"); the TTD (memory_at, find_last) works
        rec['l1'] = 'not built: the analysis instance cannot load a session with the rzxplayback device'
        rec['seconds'] = round(time.time() - began)
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k: rec[k] for k in ('status_rzx', 'ttd', 'seconds')}, indent=1))
    finally:
        lab.close()


if __name__ == '__main__':
    main()

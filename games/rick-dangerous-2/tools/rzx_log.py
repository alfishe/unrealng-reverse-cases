#!/usr/bin/env python3
"""Play one RZX of the RZX archive's rick2.zip (Jim Waterman's run, SPIN 0.5, 128K, one file a level) in unreal-ng
(`/rzx/play`, tolerant) and keep what it reached: the screen every --every frames (screens.bin, 6912 bytes a
sample), the 64 K the Z80 sees every --mem frames (mem.bin), a saved state every --state frames (at<N>.szx, after N
frames of the RZX; start.szx before the first) and the RZX status. Someone else's play: a witness only where said.
unreal-ng keeps no TTD history of an RZX playback (games/tujad WALKTHROUGH 5), so recordings start from the states.

    python3 tools/rzx_log.py --rzx work/candidates/rzxarchive/rick2-1.rzx --out work/stage1/rzx/l1 --port-base 37505
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rzx', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--every', type=int, default=25)
    ap.add_argument('--mem', type=int, default=250)
    ap.add_argument('--state', type=int, default=1000)
    ap.add_argument('--port-base', type=int, default=37505)
    a = ap.parse_args()
    from lab import Lab
    os.makedirs(a.out, exist_ok=True)
    lab = Lab(a.port_base, model='128K')
    try:
        lab.post('/rzx/play', {'path': os.path.abspath(a.rzx), 'desync_mode': 'tolerant'})
        lab.mute()
        lab.s.call('control_execution', {'action': 'pause'}, ok=False)
        lab.save(os.path.join(a.out, 'start.szx'))
        n, last = 0, {}
        with open(os.path.join(a.out, 'screens.bin'), 'wb') as fs, open(os.path.join(a.out, 'mem.bin'), 'wb') as fm:
            fs.write(lab.read(0x4000, 6912))
            fm.write(lab.read(0, 65536))
            while True:
                lab.run(a.every)
                n += a.every
                fs.write(lab.read(0x4000, 6912))
                if n % a.mem == 0:
                    fm.write(lab.read(0, 65536))
                if n % a.state == 0:
                    st = lab.s.call('invoke_api', {'method': 'GET',
                                                   'path': '/api/v1/emulator/{id}/rzx/status'}).structured['body']
                    last = {k: st.get(k) for k in ('state', 'frame', 'total_frames', 'desyncs', 'drift', 'summary')}
                    print(n, last, flush=True)
                    if st.get('state') != 'playing':
                        break
                    lab.save(os.path.join(a.out, f'at{n:06d}.szx'))
        json.dump({'every': a.every, 'mem': a.mem, 'state': a.state, 'frames': n, 'last': last},
                  open(os.path.join(a.out, 'log.json'), 'w'), indent=1)
    finally:
        lab.close()


if __name__ == '__main__':
    main()

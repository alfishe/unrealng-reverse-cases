#!/usr/bin/env python3
"""Recording m1: Zynaps 2 in 1 played with the Kempston mouse (K-MOUSE on), for docs/05.

    python3 tools/rec_mouse.py --work work/z128A/m1 --port-base 16271 --binary B

A fresh Pentagon 128 (RAM zeroed, muted), the TRD autostarted as tools/model_run.py does it: the boot list ENTER, the
title, `2` on the options screen (K-MOUSE on, INF.LIVES off), `0`, the Hewson picture, the game menu. The TTD
recording starts there (`analysis start record`), so m1's frames count from the menu. Then, recorded:

  - the start button held 35 frames (the game reads bit 1 of `$FADF`; unreal-ng gives it the right button, docs/05);
  - 250 frames to play;
  - a square course of mouse glides, each followed by 40 frames, with a left click (fire) after each glide.

The input events go into the recording (mouse_input calls on the live machine), so memory_at and the access trace
replay them. The recording is dumped to W/session.ttd and the instance is kept up (W/session.json): re_session.py
build --work W, the kit's trace scripts --work W. Prints, per glide, the frame, the driver's position MouseX/MouseY
(`$FED9`/`$FEDA`) and the ship's X/Y (`$F36F`-`$F372`) read from the live machine.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
UNREAL = os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng')
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import corpus  # noqa: E402

TRD = os.path.join(CASE, 'work', 'media', 'trd', 'Zynaps(2In1)(km).trd')
COURSE = [(0, 0), (40, 0), (0, 30), (-40, 0), (0, -30), (80, 20), (-60, -20), (30, 40), (-50, -40)]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--port-base', type=int, default=16271)
    p.add_argument('--binary', required=True)
    a = p.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    proc = mcplib.launch(a.binary, a.port_base)
    with open(os.path.join(work, 'session.json'), 'w') as f:
        json.dump({'pid': proc.pid, 'binary': a.binary, 'port_base': a.port_base, 'model': 'PENTAGON',
                   'ranges': '4000-FFFF'}, f)
    s = mcplib.Session(f'http://127.0.0.1:{a.port_base + 200}/mcp', 'PENTAGON')
    s.destroy_all()
    s.call('emulator_manage', {'action': 'create', 'model': 'PENTAGON', 'ram_power_on': 'zero'}, ok=False)
    s.call('emulator_manage', {'action': 'start'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'run_frames', 'frames': 100}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('load_software', {'path': TRD, 'autostart': True}, ok=False)
    m = corpus.Machine(s, a.port_base)

    def run(n):
        s.call('control_execution', {'action': 'run_frames', 'frames': n}, ok=False)

    def key(k, n=3):
        s.call('type_input', {'action': 'press', 'key': k}, ok=False)
        run(n)
        s.call('type_input', {'action': 'release', 'key': k}, ok=False)

    run(300)
    key('enter')
    run(600)
    key('space')
    run(150)
    key('2')
    run(20)
    print('options $5D40/$5D41', m.read(0x5D40, 2).hex())
    key('0')
    run(550)
    key('space')
    run(150)
    s.call('analysis', {'action': 'start', 'record': True})
    run(10)
    s.call('mouse_input', {'action': 'press', 'button': 'right'}, ok=False)
    run(35)
    s.call('mouse_input', {'action': 'release', 'button': 'right'}, ok=False)
    run(250)
    log = []
    for dx, dy in COURSE:
        if dx or dy:
            s.call('mouse_input', {'action': 'glide', 'dx': dx, 'dy': dy}, ok=False)
        run(40)
        s.call('mouse_input', {'action': 'press', 'button': 'left'}, ok=False)
        run(4)
        s.call('mouse_input', {'action': 'release', 'button': 'left'}, ok=False)
        st = s.call('time_travel', {'action': 'status'}, ok=False).text or ''
        entry = {'glide': [dx, dy], 'mouse_xy': m.read(0xFED9, 2).hex(), 'ship': m.read(0xF36F, 4).hex(),
                 'status': st.split(',')[0][:80]}
        print(json.dumps(entry))
        log.append(entry)
    run(100)
    r = s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
    print(r.text[:200])
    with open(os.path.join(work, 'rec_mouse.json'), 'w') as f:
        json.dump(log, f, indent=1)


if __name__ == '__main__':
    main()

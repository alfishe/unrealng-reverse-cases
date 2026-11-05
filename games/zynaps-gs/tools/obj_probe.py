#!/usr/bin/env python3
"""A frame-by-frame log of the objects and the collision grid on a live gs_session.py instance (docs/07-objects.md).

    python3 tools/obj_probe.py --work W --frames N --out PREFIX [--fire 10,6] [--y 8]

From the instance's present state (a game in play) it runs one frame at a time and reads, at each frame's end:
the 16 object records $F36C-$F62B, the collision grid $FC00-$FD8F (X bytes $FC00, Y bytes $FD00), the hit masks
$80BB, $80E5, $80E3, $80E4, the player record $7F9C, $80E0-$80EF, FireHeld $8184, $7F62-$7F81 (gs_podbot.py's
vars layout) and the screen. Fire is held --fire ON frames, released OFF frames, over and over (so FireHeld runs
through every count: the seeker needs exactly 7, the plasma 3); the ship keeps to row --y.

Out: PREFIX.npz (frames, vars, objs, screen, grid, masks; zgsbplot.Rec reads it), PREFIX-script.txt (the inputs).
"""
import argparse
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gs_session as g  # noqa: E402

NAMES = {'KF': 'fire', 'KU': 'up', 'KD': 'down'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', type=int, default=300)
    p.add_argument('--out', required=True)
    p.add_argument('--fire', default='10,6')
    p.add_argument('--y', type=int, default=8)
    a = p.parse_args()
    on, off = (int(v) for v in a.fire.split(','))
    L = g.Live(a.work)
    s = L.s
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)

    def mem(addr, n):
        for attempt in range(5):
            try:
                return L.get(f'/memory/read/{addr}?length={n}&format=binary', raw=True)
            except Exception:       # a slow answer: ask again
                time.sleep(1)
        raise SystemExit(f'no answer reading ${addr:04X}')

    held, script, last = set(), ['0 -'], 0
    F, V, O, S, G, M = [], [], [], [], [], []
    for frame in range(a.frames):
        y = mem(0xF36C + 6, 1)[0]
        want = {'KF'} if frame % (on + off) < on else set()
        if y < a.y:
            want.add('KD')
        elif y > a.y:
            want.add('KU')
        if want != held:
            for k in held - want:
                s.call('joystick_input', {'action': 'release', 'buttons': NAMES[k]}, ok=False)
            for k in want - held:
                s.call('joystick_input', {'action': 'press', 'buttons': NAMES[k]}, ok=False)
            script.append(f'+{frame - last} ' + (' '.join(sorted(want)) or '-'))
            last = frame
            held = want
        L.run(1)
        F.append(frame + 1)
        V.append(np.frombuffer(mem(0x7F9C, 16) + mem(0x80E0, 16) + mem(0x8184, 1) + mem(0x7F62, 32), dtype=np.uint8))
        O.append(np.frombuffer(mem(0xF36C, 44 * 16), dtype=np.uint8))
        S.append(np.frombuffer(mem(0x4000, 6912), dtype=np.uint8))
        G.append(np.frombuffer(mem(0xFC00, 0x190), dtype=np.uint8))
        m = mem(0x80BB, 1) + mem(0x80E5, 1) + mem(0x80E3, 2)
        M.append(np.frombuffer(m, dtype=np.uint8))
        if frame % 100 == 0:
            print(frame, flush=True)
    for k in held:
        s.call('joystick_input', {'action': 'release', 'buttons': NAMES[k]}, ok=False)
    script.append(f'+{a.frames - last} -')
    open(a.out + '-script.txt', 'w').write('# tools/obj_probe.py\n' + '\n'.join(script) + '\n')
    np.savez_compressed(a.out + '.npz', frames=np.array(F), vars=np.array(V), objs=np.array(O), screen=np.array(S),
                        grid=np.array(G), masks=np.array(M))
    print('done', a.frames, 'frames')


if __name__ == '__main__':
    main()

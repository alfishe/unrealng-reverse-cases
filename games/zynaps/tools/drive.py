#!/usr/bin/env python3
"""Drive a live instance of a work folder by hand-written steps (exploration, not recordings).

    python3 tools/drive.py --work W STEP [STEP ...]

Steps: run:N (N frames), hold:KEYS:N (keys held N frames, then released; KEYS joined by +, Kempston KF KL KR KU KD),
tap:KEYS (5 frames held, 10 up), shot:OUT.png (the screen), save:PATH.szx, load:PATH.szx, peek:ADDR:LEN (hex), poke:ADDR:HEX (memory write),
script:PATH[:EVERY] (an input script, a screenshot next to it every EVERY frames), mute.
Prints each peek.
"""
import argparse
import os
import sys

import zynlib as Z

KEMPSTON = {'KF': 'fire', 'KL': 'left', 'KR': 'right', 'KU': 'up', 'KD': 'down'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('steps', nargs='+')
    args = p.parse_args()
    s = Z.session(args.work)
    sys.path.insert(0, os.path.join(Z.K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import corpus  # noqa: E402
    import json
    port = json.load(open(os.path.join(args.work, 'session.json')))['port_base']
    m = corpus.Machine(s, port)

    def keys(text, down):
        for k in text.split('+'):
            if k in KEMPSTON:
                s.call('joystick_input', {'action': 'press' if down else 'release', 'buttons': KEMPSTON[k]}, ok=False)
            else:
                s.call('type_input', {'action': 'press' if down else 'release', 'key': k}, ok=False)

    def run(n):
        if n > 0:
            s.call('control_execution', {'action': 'run_frames', 'frames': n})

    def shot_to(path):
        mem = bytearray(0x10000)
        mem[0x4000:0x4000 + 6912] = m.read(0x4000, 6912)
        Z.K.render_screen(mem).resize((512, 384)).save(path)

    import mm_session  # noqa: E402
    for step in args.steps:
        kind, _, rest = step.partition(':')
        if kind == 'run':
            run(int(rest))
        elif kind == 'hold':
            k, n = rest.rsplit(':', 1)
            keys(k, True)
            run(int(n))
            keys(k, False)
        elif kind == 'tap':
            keys(rest, True)
            run(5)
            keys(rest, False)
            run(10)
        elif kind == 'shot':
            shot_to(rest)
        elif kind == 'save':
            m.post('/snapshot/save', {'path': os.path.abspath(rest), 'force': True})
        elif kind == 'load':
            m.post('/snapshot/load', {'path': os.path.abspath(rest)})
        elif kind == 'peek':
            a, n = rest.split(':')
            data = m.read(int(a, 16), int(n, 16))
            print(f'{a}: ' + ' '.join(f'{b:02X}' for b in data))
        elif kind == 'poke':
            a, data = rest.split(':')
            s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': '0x' + a, 'hex': data})
        elif kind == 'script':
            path, _, every = rest.partition(':')
            at, held = 0, []
            for frame, ks in mm_session.parse_script(path):
                while at < frame:
                    n = frame - at if not every else min(frame - at, int(every) - at % int(every))
                    run(n)
                    at += n
                    if every and at % int(every) == 0:
                        shot_to(os.path.join(os.path.dirname(os.path.abspath(path)), f'shot-{at:06d}.png'))
                if ks is None:
                    break
                for k in held:
                    keys(k, False)
                for k in ks:
                    keys(k, True)
                held = ks
            for k in held:
                keys(k, False)
        elif kind == 'mute':
            s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                  'body': {'muted': True}}, ok=False)
        else:
            raise SystemExit('unknown step ' + step)


if __name__ == '__main__':
    main()

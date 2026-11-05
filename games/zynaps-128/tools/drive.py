#!/usr/bin/env python3
"""(Copied from games/advanced-nether-earth/tools/drive.py.) Drives the live instance a work folder holds (exploration, not evidence: record what matters with
re_session.py capture --inputs).

  drive.py --work W STEP...

Steps, run in order:
  run:N            run N frames
  key:K[+K2]:N     hold the keys (type_input names: space, enter, cs, ss, a ...) for N frames, then release
  joy:B[+B2]:N     hold Kempston buttons (fire, left, right, up, down) for N frames
  shot:PATH        the screen (6912 bytes from $4000 of the shown screen page) to PATH.png
  mem:ADDR:LEN     print LEN bytes at the Z80 address ADDR (hex) now
  pages:PREFIX     the 8 RAM pages now to PREFIX-bankN.bin
  cpu:PATH         the 64 K Z80 view now to PATH
  poke:ADDR:HEX    write bytes at the Z80 address ADDR now (an experiment: never in a recording)
  save:PATH        a snapshot (.szx) of the machine now
  load:PATH        load a snapshot
"""

import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import corpus  # noqa: E402

KIT = os.path.join(HERE, '..', '..', '..', 'kit')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True)
    p.add_argument('steps', nargs='+')
    args = p.parse_args()
    state = json.load(open(os.path.join(args.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    for step in args.steps:
        kind, _, rest = step.partition(':')
        if kind == 'run':
            s.call('control_execution', {'action': 'run_frames', 'frames': int(rest)})
        elif kind in ('key', 'joy'):
            keys, _, n = rest.rpartition(':')
            names = keys.split('+')
            for k in names:
                if kind == 'key':
                    s.call('type_input', {'action': 'press', 'key': k}, ok=False)
                else:
                    s.call('joystick_input', {'action': 'press', 'buttons': k}, ok=False)
            s.call('control_execution', {'action': 'run_frames', 'frames': int(n)})
            for k in names:
                if kind == 'key':
                    s.call('type_input', {'action': 'release', 'key': k}, ok=False)
                else:
                    s.call('joystick_input', {'action': 'release', 'buttons': k}, ok=False)
        elif kind == 'shot':
            r = s.call('capture_media', {'action': 'screenshot', 'path': os.path.abspath(rest + '.png')}, ok=False)
            print((r.text or '').splitlines()[:1])
        elif kind == 'mem':
            a, _, n = rest.partition(':')
            r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'offset': int(a, 16),
                                       'length': int(n)}, ok=False)
            print((r.structured or {}).get('hex', r.text))
        elif kind == 'pages':
            m = corpus.Machine(s, state['port_base'])
            for n in range(8):
                open(f'{rest}-bank{n}.bin', 'wb').write(m.read_page('ram', n))
        elif kind == 'cpu':
            data = b''
            for o in range(0, 0x10000, 0x4000):
                r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'offset': o, 'length': 0x4000})
                data += bytes.fromhex(r.structured['hex'])
            open(rest, 'wb').write(data)
        elif kind == 'poke':
            a, _, h = rest.partition(':')
            s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': '0x' + a, 'hex': h})
        elif kind == 'save':
            s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}/snapshot/save',
                                  'body': {'path': os.path.abspath(rest), 'force': True}}, ok=False)
        elif kind == 'load':
            s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}/snapshot/load',
                                  'body': {'path': os.path.abspath(rest)}}, ok=False)
        else:
            raise SystemExit(f'unknown step {step}')


if __name__ == '__main__':
    main()

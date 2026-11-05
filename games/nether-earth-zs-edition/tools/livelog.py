#!/usr/bin/env python3
"""Drives the live instance a work folder holds and writes what it did as an input script (mm_session format), so
that re_session.py capture --inputs replays it into a recording (exploration first, evidence second).

  livelog.py --work W --script S.txt [--reset] STEP...

The frame counter lives in W/livelog.json (0 = where the capture's input scripts begin); --reset starts it at the
offset given by --start (default 10: the length of inputs/none.txt, the script the exploring capture ran).
Steps:
  run:N               run N frames
  key:K[+K2]:N        hold keys (type_input names: a, ss, cs, enter, space ...) N frames, then release
  goto:X,Y            the ZS'99 menu pointer (x $DD74, y $DD75) to X,Y with Q A O P, one frame a step
  shot:PATH           a screenshot PATH.png
  save:PATH           a snapshot
  mem:ADDR:LEN        print bytes now
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402

NAMES = {'ss': 'SS', 'cs': 'CS', 'enter': 'ENTER', 'space': 'SPACE'}


class Live:
    def __init__(self, work, script, reset, start):
        st = json.load(open(os.path.join(work, 'session.json')))
        self.s = mcplib.Session(f"http://127.0.0.1:{st['port_base'] + 200}/mcp", st['model'])
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        self.s.call('control_execution', {'action': 'pause'}, ok=False)
        self.state_path = os.path.join(work, 'livelog.json')
        self.frame = start if reset or not os.path.exists(self.state_path) else json.load(open(self.state_path))['frame']
        self.script = open(script, 'w' if reset else 'a')

    def run(self, n):
        if n > 0:
            self.s.call('control_execution', {'action': 'run_frames', 'frames': n})
            self.frame += n

    def press(self, keys, down):
        for k in keys:
            self.s.call('type_input', {'action': 'press' if down else 'release', 'key': k})
        if down:
            self.script.write(f"{self.frame} {' '.join(NAMES.get(k, k.upper()) for k in keys)}\n")
        else:
            self.script.write(f'{self.frame} -\n')

    def mem(self, addr, n):
        r = self.s.call('memory_access', {'action': 'read', 'space': 'cpu', 'offset': f'0x{addr:04X}', 'length': n})
        out = []
        for line in r.structured['hexdump'].splitlines():
            out += [int(x, 16) for x in line.split(':', 1)[1].split('|')[0].split()]
        return bytes(out[:n])

    def goto(self, x, y):
        for _ in range(400):
            px, py = self.mem(0xDD74, 2)
            keys = []
            if abs(px - x) > 1:
                keys.append('p' if px < x else 'o')
            if abs(py - y) > 1:
                keys.append('a' if py < y else 'q')
            if not keys:
                return px, py
            self.press(keys, True)
            self.run(1)
            self.press(keys, False)
            self.run(1)
        raise SystemExit(f'goto {x},{y}: pointer stuck at {px},{py}')

    def close(self):
        self.script.close()
        json.dump({'frame': self.frame}, open(self.state_path, 'w'))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True)
    p.add_argument('--script', required=True)
    p.add_argument('--reset', action='store_true')
    p.add_argument('--start', type=int, default=10)
    p.add_argument('steps', nargs='+')
    a = p.parse_args()
    L = Live(a.work, a.script, a.reset, a.start)
    try:
        for step in a.steps:
            kind, _, rest = step.partition(':')
            if kind == 'run':
                L.run(int(rest))
            elif kind == 'key':
                keys, _, n = rest.rpartition(':')
                L.press(keys.split('+'), True)
                L.run(int(n))
                L.press(keys.split('+'), False)
            elif kind == 'goto':
                x, y = (int(v) for v in rest.split(','))
                print('pointer', L.goto(x, y))
            elif kind == 'shot':
                L.s.call('capture_media', {'action': 'screenshot', 'path': os.path.abspath(rest + '.png')}, ok=False)
            elif kind == 'save':
                L.s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}/snapshot/save',
                                        'body': {'path': os.path.abspath(rest), 'force': True}}, ok=False)
            elif kind == 'mem':
                a2, _, n = rest.partition(':')
                print(L.mem(int(a2, 16), int(n)).hex())
            else:
                raise SystemExit(f'unknown step {step}')
    finally:
        L.close()
        print('frame', L.frame)


if __name__ == '__main__':
    main()

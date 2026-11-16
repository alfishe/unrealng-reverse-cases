#!/usr/bin/env python3
"""Replay an input script (tests/inputs/NAME.txt) on a fresh muted instance without recording: the start state of
its "# Start:" line (or power-on), each line's keys held from its frame, POKE and TAPE lines applied at their
frames; screens at --shots frames (comma-separated) and the PC printed at each, a state saved with --save-at.

    python3 tools/replay.py tests/inputs/stages.txt --out work/stage1/replay-stages --shots 6600,6700 [--port-base 37780]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('script')
    ap.add_argument('--out', required=True)
    ap.add_argument('--port-base', type=int, default=37780)
    ap.add_argument('--model', default='48K')
    ap.add_argument('--shots', default='')
    ap.add_argument('--save-at', default='')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    lines = open(a.script).read().splitlines()
    start = next((l.split(':', 1)[1].strip() for l in lines if l.startswith('# Start:')), None)
    events = []
    for l in lines:
        if l.startswith('#') or not l.strip():
            continue
        f, _, rest = l.partition(' ')
        events.append((int(f), rest.strip()))
    marks = sorted({int(x) for x in a.shots.split(',') if x} | {int(x) for x in a.save_at.split(',') if x})
    saves = {int(x) for x in a.save_at.split(',') if x}
    lab = Lab(a.port_base, model=a.model)
    try:
        if start:
            lab.load(os.path.join(CASE, start))
        lab.mute()
        lab.frame = 0
        todo = sorted([(f, 'E', t) for f, t in events] + [(m, 'M', '') for m in marks])
        for f, kind, text in todo:
            if f > lab.frame:
                lab.run(f - lab.frame)
            if kind == 'M':
                pc = lab.regs()['special']['pc']
                lab.shot(os.path.join(a.out, f'{f:06d}.png'))
                print(f, f'PC ${pc:04X}', flush=True)
                if f in saves:
                    lab.save(os.path.join(a.out, f'{f:06d}.szx'))
                continue
            w = text.split()
            if w[0] == 'END':
                break
            if w[0] == 'POKE':
                lab.write(int(w[1]), bytes(int(x) for x in w[2:]))
            elif w[0] == 'TAPE':
                if w[1] == 'INSERT':
                    lab.s.call('load_software', {'path': os.path.join(CASE, text.split(' ', 2)[2]), 'autostart': False,
                                                 'play': False}, ok=False)
                    lab.mute()
                elif w[1] == 'PLAY':
                    lab.post('/tape/play', {})
            else:
                lab.keys([] if w[0] == '-' else w)
    finally:
        lab.close()


if __name__ == '__main__':
    main()

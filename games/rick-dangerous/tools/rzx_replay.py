#!/usr/bin/env python3
"""Replay the RZX run's keys (tools/rzx_script.py) on the original game in a live lab instance and compare the
screen with the RZX's own (tools/rzx_dump.py's screens.bin) every --every RZX frames.

    python3 tools/rzx_replay.py --start work/stage1/probe/menu-cursor.szx --script work/stage1/rzx/all.txt \
        --from 0 --to 59869 [--port-base 37495] [--save-every 2500 --save-dir work/stage1/rzx/orig]

The start state is the original's (loaded from the original tape), at the moment that stands for RZX frame FROM.
Each line of the script holds its keys until the next line, in one run call a line (as re_session.py capture
does). Prints, per checkpoint, the share of the 6144 bitmap bytes that differ from the RZX's screen; with
--save-every, saves an SZX of the original's state at those RZX frames (the warp points of later recordings).
The RZX is someone else's run on a re-release build: what it reaches is evidence for the original only where the
screens agree.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402


def parse(path):
    lines = []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        f, *keys = line.split()
        lines.append((int(f), [] if keys in (['-'], ['END']) else keys, keys == ['END']))
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', required=True)
    ap.add_argument('--script', required=True)
    ap.add_argument('--from', dest='a', type=int, default=0)
    ap.add_argument('--to', dest='b', type=int, default=59869)
    ap.add_argument('--port-base', type=int, default=37495)
    ap.add_argument('--every', type=int, default=250)
    ap.add_argument('--rzx', default='work/stage1/rzx')
    ap.add_argument('--save-every', type=int, default=0)
    ap.add_argument('--save-dir', default='')
    ap.add_argument('--shots', default='', help='save our screen (PNG) at every checkpoint into this folder')
    ap.add_argument('--stop-at', type=float, default=0.5, help='stop when this share of the bitmap differs')
    a = ap.parse_args()
    idx = json.load(open(os.path.join(a.rzx, 'index.json')))['frames']
    scr = open(os.path.join(a.rzx, 'screens.bin'), 'rb').read()
    ref = {f: scr[i * 6912:i * 6912 + 6144] for i, f in enumerate(idx)}
    lab = Lab(a.port_base, model='128K', attach=True)
    lab.load(a.start)
    lab.keys([])
    script = [(f + a.a, k, e) for f, k, e in parse(a.script)]
    marks = sorted({f for f in ref if a.a < f <= a.b} | ({f for f in range(a.a, a.b + 1, a.save_every)
                                                          if f > a.a} if a.save_every else set()))
    now = a.a
    pos = 0
    keys = []
    for folder in (a.save_dir, a.shots):
        if folder:
            os.makedirs(folder, exist_ok=True)
    while marks:
        target = marks[0]
        while pos < len(script) and script[pos][0] <= now:
            keys = script[pos][1]
            pos += 1
        nxt = min(target, script[pos][0] if pos < len(script) else target)
        if nxt > now:
            lab.keys(keys)
            lab.run(nxt - now)
            now = nxt
        if now == target:
            marks.pop(0)
            if target in ref:
                mine = lab.read(0x4000, 6144)
                d = sum(1 for x, y in zip(mine, ref[target]) if x != y) / 6144
                print(f'{target} {d:.3f}', flush=True)
                if a.shots:
                    lab.shot(os.path.join(a.shots, f'o{target:05d}.png'), 1)
                if d > a.stop_at:
                    print('diverged')
                    break
            if a.save_every and target % a.save_every == 0 and a.save_dir:
                lab.save(os.path.join(a.save_dir, f'orig-{target:05d}.szx'))
    lab.keys([])


if __name__ == '__main__':
    main()

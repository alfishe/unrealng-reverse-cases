#!/usr/bin/env python3
"""Doc 10's technique runs: c1's play start (work/stage1/rec/c1/play.szx, c1 frame 14 075) replayed with c1's own
input script (tests/inputs/c1.txt), and one change made to the keys from a given frame. Each run samples the bike's
variables every frame of its window into a JSON-lines file and saves a 1050 px GIF of the screen.

    python3 tools/play_techniques.py RUN --port-base 37795 --out work/docs/erC/tech [--gif docs/img/play/NAME.gif]
    python3 tools/play_techniques.py list

The runs (frames are c1's, from power-on):
    ramp-plain       c1's keys as recorded (the control: the ramp at 15 487 taken without a wheelie)
    ramp-wheelie     c1's keys, but THROTTLE + WHEELIE held from 15 380 to 15 500 (a wheelie into the ramp)
    land-wheelie     c1's keys, but THROTTLE + WHEELIE held from 15 600 to 15 640 (a wheelie at the landing)
    cheat            c1's keys, CAPS SHIFT + Q held at 14 200 until CheatStep reads $FF, then c1's keys to 14 700
    brake-bend       c1's keys, but BRAKES (SPACE) instead of THROTTLE from 15 130 to 15 170 (no rider hit)

A run is an experiment on the case's own instance: no TTD recording, no POKE; the input it plays is printed in the
JSON's first line, so the run is repeated by the same command.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

START = os.path.join(CASE, 'work', 'stage1', 'rec', 'c1', 'play.szx')
START_FRAME = 14075
SCRIPT = os.path.join(CASE, 'tests', 'inputs', 'c1.txt')
VARS = {'Speed': (0x7C33, 2), 'ScrollStep': (0x9136, 2), 'JumpHeight': (0x5CE9, 2), 'JumpSpeed': (0x5CFD, 2),
        'LateralX': (0x913F, 2), 'Pose': (0x9175, 1), 'Lean': (0x9176, 1), 'Wheelies': (0x916F, 1),
        'BounceTime': (0xA1C9, 1), 'FallTime': (0x916E, 1), 'PassCount': (0x7C2E, 1), 'CheatStep': (0xA670, 1),
        'Timer': (0x5E1F, 1), 'Riders': (0x5C80, 90)}
RUNS = {
    'ramp-plain': {'window': (15380, 15700), 'change': []},
    'ramp-wheelie': {'window': (15380, 15700), 'change': [(15380, 15500, ['Q', 'A'])]},
    'land-wheelie': {'window': (15560, 15700), 'change': [(15600, 15640, ['Q', 'A'])]},
    'cheat': {'window': (14180, 14700), 'change': [], 'cheat': 14200},
    'brake-bend': {'window': (15100, 15320), 'change': [(15130, 15170, ['SPACE'])]},
}


def script_events():
    ev = []
    for line in open(SCRIPT):
        if line.startswith('#') or not line.strip():
            continue
        parts = line.split()
        f = int(parts[0])
        if parts[1] == 'END':
            break
        if parts[1] == 'POKE' or parts[1] == 'TAPE':
            continue
        ev.append((f, [] if parts[1] == '-' else parts[1:]))
    return ev


def keys_at(events, frame):
    held = []
    for f, k in events:
        if f > frame:
            break
        held = k
    return held


def sample(lab):
    row = {}
    for name, (a, n) in VARS.items():
        b = lab.read(a, n)
        row[name] = b.hex() if n > 2 else (b[0] if n == 1 else b[0] | b[1] << 8)
    return row


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('run')
    ap.add_argument('--port-base', type=int, default=37795)
    ap.add_argument('--out', default=os.path.join(CASE, 'work', 'docs', 'erC', 'tech'))
    ap.add_argument('--gif')
    ap.add_argument('--every', type=int, default=4, help='a GIF picture every N frames')
    a = ap.parse_args()
    if a.run == 'list':
        for k, v in RUNS.items():
            print(k, v)
        return
    run = RUNS[a.run]
    events = script_events()
    lo, hi = run['window']
    os.makedirs(a.out, exist_ok=True)
    lab = Lab(a.port_base)
    pictures = []
    try:
        lab.load(START)
        lab.mute()
        frame = START_FRAME
        played = []

        def held_at(f):
            for c0, c1, k in run['change']:
                if c0 <= f < c1:
                    return k
            return keys_at(events, f)

        cheat = run.get('cheat')
        with open(os.path.join(a.out, a.run + '.jsonl'), 'w') as out:
            out.write(json.dumps({'run': a.run, 'start': os.path.relpath(START, CASE), 'start_frame': START_FRAME,
                                  'script': os.path.relpath(SCRIPT, CASE), 'change': run['change'],
                                  'cheat': cheat}) + '\n')
            while frame < hi:
                keys = held_at(frame)
                if cheat is not None and frame >= cheat:
                    if lab.read(0xA670, 1)[0] != 0xFF:
                        keys = ['CS', 'Q']
                    else:
                        cheat = None
                if sorted(keys) != sorted(lab.held):
                    lab.keys(keys)
                    played.append((frame, keys))
                if frame >= lo:
                    row = sample(lab)
                    row['f'] = frame
                    row['keys'] = keys
                    out.write(json.dumps(row) + '\n')
                    if a.gif and (frame - lo) % a.every == 0:
                        p = os.path.join(a.out, f'{a.run}-{frame:06d}.png')
                        lab.shot(p, scale=1)
                        pictures.append(p)
                    lab.run(1)
                    frame += 1
                else:
                    # to the next key change or the window, whichever comes first
                    nxt = min([f for f, _ in events if f > frame] + [lo] +
                              [c for c0, c1, _ in run['change'] for c in (c0, c1) if c > frame] +
                              ([cheat] if cheat is not None and cheat > frame else []))
                    lab.run(nxt - frame)
                    frame = nxt
            out.write(json.dumps({'played': played}) + '\n')
    finally:
        lab.keys([])
        lab.close()
    if a.gif:
        from PIL import Image
        ims = [Image.open(p).convert('RGB') for p in pictures]
        w = 1050
        ims = [im.resize((w, round(im.height * w / im.width)), Image.NEAREST) for im in ims]
        ims[0].save(a.gif, save_all=True, append_images=ims[1:], duration=[120] * (len(ims) - 1) + [1500], loop=0)
        print(f'{a.gif}: {len(ims)} pictures, {ims[0].width} x {ims[0].height}')


if __name__ == '__main__':
    main()

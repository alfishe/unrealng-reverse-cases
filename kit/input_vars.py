#!/usr/bin/env python3
"""Find the variables that follow the player's input: the bytes that move one way while a direction is held and the
other way while the opposite one is, over a recording played from an input script.

    python3 input_vars.py --work W --inputs tests/inputs/play.txt --start F [--range 5B00-FFFF] [--step 4]
           [--lag 0,1,2,3] [--top 12]

The memory is sampled every --step frames with TTD memory_at from the instance that holds the recording
(re_session.py open / capture). --start is the recording frame the script's frame 0 played at (capture.json's
load_frames for a --record-load capture; try --lag when unsure: the score of each lag is printed). For each axis
(KL/KR or O/P: left-right, KU/KD or Q/A: up-down) a byte scores +1 for every step it moved the way the held
direction says, -1 for the other way; the bytes with the best score per axis are printed with how often they moved
when nothing was held (a counter or a timer moves anyway: a coordinate does not; bytes that change in more than a
fifth of the idle steps are left out). Fire (KF, SPACE, M) is scored as a
byte that changes in the steps fire went down.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402

AXES = {
    'x': ({'KR', 'P'}, {'KL', 'O'}),
    'y': ({'KD', 'A'}, {'KU', 'Q'}),
}
FIRE = {'KF', 'SPACE', 'M'}


def parse_script(path):
    """[(frame, keys)] of a zx-reaper input script (frame absolute), keys a set, None at END"""
    out, frame = [], 0
    for line in open(path):
        line = line.split('#')[0].strip()
        if not line:
            continue
        when, *keys = line.split()
        frame = frame + int(when[1:]) if when.startswith('+') else int(when)
        if keys == ['END']:
            out.append((frame, None))
            break
        out.append((frame, set() if keys == ['-'] else {k for key in keys for k in key.split('+')}))  # W+O: W, O
    return out


def held_at(script, frame):
    keys = set()
    for f, k in script:
        if f > frame:
            break
        if k is None:
            return set()
        keys = k
    return keys


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--inputs', required=True)
    p.add_argument('--start', type=int, required=True)
    p.add_argument('--range', default='5B00-FFFF')
    p.add_argument('--step', type=int, default=4)
    p.add_argument('--lag', default='0', help='frames the game reacts late, comma-separated to try several')
    p.add_argument('--top', type=int, default=12)
    p.add_argument('--unreal')
    args = p.parse_args()
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(args.work)
    lo, hi = K.hex_range(args.range)
    script = parse_script(args.inputs)
    end = script[-1][0]

    samples = []
    for frame in range(0, end + 1, args.step):
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': args.start + frame, 'tinframe': 0, 'offset': lo,
                'length': hi - lo + 1}
        r = session.call('time_travel', body, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data:
            raise SystemExit(f'memory_at frame {args.start + frame}: {r.text}')
        samples.append((frame, bytes.fromhex(data)))
    print(f'{len(samples)} samples of ${lo:04X}-${hi:04X}, every {args.step} frames from {args.start}')

    for lag in (int(x) for x in args.lag.split(',')):
        score = {axis: [0] * (hi - lo + 1) for axis in AXES}
        idle = [0] * (hi - lo + 1)
        fire = [0] * (hi - lo + 1)
        fire_steps = idle_steps = 0
        for (f0, m0), (f1, m1) in zip(samples, samples[1:]):
            keys = held_at(script, f0 - lag)
            pressed_fire = bool(keys & FIRE) and not (held_at(script, f0 - lag - args.step) & FIRE)
            fire_steps += pressed_fire
            idle_steps += not keys
            for i in range(hi - lo + 1):
                d = (m1[i] - m0[i] + 128) % 256 - 128
                if not d:
                    continue
                if not keys:
                    idle[i] += 1
                if pressed_fire:
                    fire[i] += 1
                for axis, (plus, minus) in AXES.items():
                    sign = 1 if keys & plus else -1 if keys & minus else 0
                    if sign:
                        score[axis][i] += 1 if (d > 0) == (sign > 0) else -1
        print(f'\nlag {lag}: {idle_steps} idle steps, {fire_steps} fire presses')
        # a coordinate stays put while nothing is held: bytes that change in more than a fifth of the idle steps are
        # buffers, counters and timers, left out
        quiet = [i for i in range(hi - lo + 1) if idle[i] <= idle_steps // 5]
        for axis in AXES:
            best = sorted(quiet, key=lambda i: -abs(score[axis][i]))[:args.top]
            print(f'  {axis}: ' + ', '.join(f'${lo + i:04X} {score[axis][i]:+d} (idle {idle[i]})' for i in best))
        best = sorted(quiet, key=lambda i: -fire[i])
        print('  fire: ' + ', '.join(f'${lo + i:04X} {fire[i]} (idle {idle[i]})' for i in best[:args.top]))


if __name__ == '__main__':
    sys.exit(main())

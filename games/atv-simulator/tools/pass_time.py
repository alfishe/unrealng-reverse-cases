#!/usr/bin/env python3
"""The work of every pass of the main loop, timed: from Pass (`$D851`) to the first arrival at WaitFrames (`$D86B`):
the controls, the clock and both players' updates, with the interrupt handler's entries that land inside. Over
recording c1's play: its state play.szx (frame 14 821, the trail 1 intro) and c1's input script
(tests/inputs/c1.txt), the keys set at each pass's start to what the script holds at that frame (so they change up to
7 frames later than in c1), to c1's end (frame 22 397).

    python3 tools/pass_time.py [--port-base 37780] [--out work/stage2/pass]

Each pass: control_execution run_until_pc `$D851`, the time (inspect_state snapshot: frame, T in the frame), run_until_pc
`$D86B`, the time again; the work is the difference in T. A pass is 7 x 69 888 = 489 216 T. Prints the count, the
least, the mean and the most, the ten heaviest passes (their frame in c1's numbering, the state at their end) and
writes OUT/passes.json; at each new most it saves OUT/heaviest.png and OUT/heaviest.szx (the machine paused at
`$D86B` after that pass's work).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

START, START_FRAME = os.path.join(CASE, 'work', 'stage1', 'rec', 'c1', 'play.szx'), 14821
SCRIPT = os.path.join(CASE, 'tests', 'inputs', 'c1.txt')
FRAME_T = 69888
BUDGET = 7 * FRAME_T


def script():
    """[(frame, keys)] of c1's input lines, and the last frame"""
    out, end = [], 0
    for line in open(SCRIPT):
        if line.startswith('#') or not line.strip():
            continue
        f, rest = line.split(' ', 1)
        f, rest = int(f), rest.strip()
        if rest == 'END':
            end = f
        elif not rest.startswith(('TAPE', 'POKE')):
            out.append((f, [] if rest == '-' else rest.split()))
    return out, end


def now(lab):
    t = lab.s.call('inspect_state', {'aspects': ['snapshot']}, ok=False).structured['snapshot']
    return t['time']['frame'], t['time']['t'], t['regs']


def pc_of(regs):
    for k in ('pc', 'PC'):
        if k in regs:
            return regs[k]
    pc = (regs.get('special') or {}).get('pc')
    return int(pc, 16) if isinstance(pc, str) else pc


def run_to(lab, pc, frames):
    lab.s.call('control_execution', {'action': 'run_until_pc', 'pc': pc, 'max_tstates': frames * FRAME_T}, ok=False)
    f, t, regs = now(lab)
    return f, t, pc_of(regs) == int(pc, 16)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port-base', type=int, default=37780)
    ap.add_argument('--out', default=os.path.join(CASE, 'work', 'stage2', 'pass'))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    events, end = script()
    lab = Lab(a.port_base)
    passes, held = [], None
    try:
        lab.load(START)
        lab.mute()
        f0, _t, _r = now(lab)
        while True:
            f, _t, _r = now(lab)
            c1 = START_FRAME + f - f0
            if c1 >= end:
                break
            keys = [k for fr, k in events if fr <= c1][-1] if events else []
            if keys != held:
                lab.keys(keys)
                held = keys
            fa, ta, ok = run_to(lab, '0xD851', 8)
            if not ok:
                continue
            fb, tb, ok = run_to(lab, '0xD86B', 8)
            if not ok:
                continue
            work = (fb - fa) * FRAME_T + tb - ta
            st = lab.read(0xD6B6, 0xF0)
            rec = {'c1_frame': START_FRAME + fa - f0, 'T': work, 'percent': round(100 * work / BUDGET, 1),
                   'frames_counted': lab.read(0xD6BC, 1)[0], 'speed': st[0xD77E - 0xD6B6],
                   'mounted': st[0xD774 - 0xD6B6], 'track': st[0xD78A - 0xD6B6] | st[0xD78B - 0xD6B6] << 8,
                   'deferred_a': lab.read(0x8148, 1)[0], 'deferred_b': lab.read(0x81EB, 1)[0],
                   'deferred_attrs': lab.read(0x828E, 1)[0]}
            if not passes or work > max(p['T'] for p in passes):
                lab.shot(os.path.join(a.out, 'heaviest.png'))
                lab.save(os.path.join(a.out, 'heaviest.szx'))
            passes.append(rec)
        lab.keys([])
    finally:
        lab.close()
    json.dump(passes, open(os.path.join(a.out, 'passes.json'), 'w'), indent=0)
    ts = [p['T'] for p in passes]
    print('passes %d: least %d T (%.1f %%), mean %d T, most %d T (%.1f %% of %d)'
          % (len(ts), min(ts), 100 * min(ts) / BUDGET, sum(ts) // len(ts), max(ts), 100 * max(ts) / BUDGET, BUDGET))
    for p in sorted(passes, key=lambda p: -p['T'])[:10]:
        print(json.dumps(p))
    return 0


if __name__ == '__main__':
    sys.exit(main())

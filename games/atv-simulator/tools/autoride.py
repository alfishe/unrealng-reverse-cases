#!/usr/bin/env python3
"""A search bot for ATV Simulator: rides the trails from a state at the menu and finds, by trial on saved states,
where to jump (or wheelie, or slow down) so the ATV gets past each obstacle. The result is a plan: a list of
(keys, frames) segments from the start state, which tools/record.py replays segment for segment (one run_frames
call each, the same splits, so the replay is the same run).

    python3 tools/autoride.py --start work/stage1/rec/c1/menu.szx --out work/stage1/ride/plan.json \
        [--trails 6] [--port-base 37780] [--poke 60250=0 ...] [--players 1]

What it reads each pass (7 frames, the game's pass, doc 04): the current player's record at `$D77D` (+6 the rider's
sprite frame: `$40` and above while he rides, 0-7 walking, `$18` jumping; +8 his x; +13/+14 the distance along the
trail), the trail number `$D6BF` (0-5) and the clock `$D6C9` (three ASCII digits). On foot it runs right to the ATV
(or left, when the crash threw him past it) and jumps on (fire), as the instructions say; riding it holds right.

On a crash it goes back to the last checkpoint before the crash (a state saved every 120 units of distance) and tries
actions at distances before it: a jump, a wheelie held a few passes, a slow approach with repeated jumps (the
instructions' "wheelie slowly towards them and jump repeatedly"). The first action that carries the ATV 150 units past
the crash is kept. The log is printed: each crash, each try, the kept action.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402

REC, TRAIL, CLOCK = 0xD77D, 0xD6BF, 0xD6C9
PASS = 7


class Rider:
    def __init__(self, lab, work):
        self.lab, self.work = lab, work
        self.segs = []          # (keys, frames) from the start state
        self.n = 0

    def hold(self, keys, frames):
        self.lab.keys(keys)
        self.lab.run(frames)
        self.segs.append((list(keys), frames))

    def st(self):
        b = self.lab.read(REC, 0x24)
        return {'frame': b[6], 'face': b[7], 'x': b[8], 'pos': b[13] | b[14] << 8,
                'trail': self.lab.read(TRAIL, 1)[0], 'clock': self.lab.read(CLOCK, 3).decode('latin1')}

    def save(self):
        self.n += 1
        p = os.path.join(self.work, f'ck{self.n:04d}.szx')
        self.lab.save(p)
        return {'state': p, 'segs': len(self.segs)}

    def restore(self, ck):
        self.lab.held = ['KL', 'KR', 'KU', 'KD', 'KF']
        self.lab.keys([])
        self.lab.load(ck['state'])
        self.lab.held = []
        self.segs = self.segs[:ck['segs']]


def riding(s):
    return s['frame'] >= 0x40


def on_foot(r, s):
    """One pass on foot: back to the ATV and on it"""
    if s['frame'] == 0x18:
        r.hold([], PASS)
    elif s['x'] > 0x46:
        r.hold(['KL'], PASS)
    elif s['face'] == 1:
        r.hold(['KR'], 2)
    elif s['x'] < 0x30:
        r.hold(['KR'], PASS)
    else:
        r.hold(['KR', 'KF'], 6)


def act(r, action):
    """Plays one planned action; returns nothing (the passes it takes are in the segments)"""
    kind = action['kind']
    if kind == 'jump':
        r.hold(['KR', 'KF'], PASS)
    elif kind == 'wheelie':
        for _ in range(action.get('n', 4)):
            r.hold(['KR', 'KU'], PASS)
    elif kind == 'climb':
        for k in range(action.get('n', 12)):
            r.hold(['KU', 'KF'] if k % 2 else ['KU'], PASS)
    elif kind == 'coast':
        for _ in range(action.get('n', 3)):
            r.hold([], PASS)
    elif kind == 'wjump':
        r.hold(['KR', 'KU', 'KF'], PASS)
    elif kind == 'brake':
        for _ in range(action.get('n', 3)):
            r.hold(['KL'], PASS)
    elif kind == 'jump2':
        r.hold(['KR', 'KF'], PASS)
        r.hold(['KR'], PASS)
        r.hold(['KR', 'KF'], PASS)


def ride(r, plan, stop_pos=None, max_passes=4000, checkpoints=None, until_trail=None):
    """Rides with @p plan ({trail: [(pos, action)]}) until a crash (returns ('crash', state)), @p stop_pos passed,
    the trail @p until_trail reached, or the passes run out"""
    s = r.st()
    trail = s['trail']
    done = {(trail, p) for p, _a in plan.get(str(trail), []) if p <= s['pos']}
    was_riding = riding(s)
    last_ck = s['pos']
    for _ in range(max_passes):
        s = r.st()
        if until_trail is not None and s['trail'] >= until_trail:
            return 'trail', s
        if s['trail'] != trail:
            trail, was_riding, last_ck = s['trail'], False, -999
        if not riding(s):
            if was_riding and s['pos'] > 20:
                return 'crash', s
            was_riding = False      # a new trail starts on foot at distance 0
            on_foot(r, s)
            continue
        was_riding = True
        if stop_pos is not None and s['pos'] >= stop_pos:
            return 'passed', s
        todo = [(p, a) for p, a in plan.get(str(trail), []) if p <= s['pos'] and (trail, p) not in done]
        if todo:
            p, a = todo[0]
            done.add((trail, p))
            act(r, a)
            continue
        if checkpoints is not None and (s['pos'] - last_ck >= 120 or last_ck > s['pos']):
            checkpoints.append(dict(r.save(), pos=s['pos'], trail=trail))
            last_ck = s['pos']
        r.hold(['KR'], PASS)
    return 'timeout', r.st()


def candidates(crash):
    out = []
    for off in range(5, 260, 5):
        out.append((crash - off, {'kind': 'jump'}))
    for off in range(5, 120, 5):
        out.append((crash - off, {'kind': 'wjump'}))
    for off in range(40, 240, 20):
        out.append((crash - off, {'kind': 'wheelie', 'n': 4}))
        out.append((crash - off, {'kind': 'jump2'}))
    for off in range(20, 160, 20):
        out.append((crash - off, {'kind': 'climb', 'n': 14}))
        out.append((crash - off, {'kind': 'coast', 'n': 4}))
        out.append((crash - off, {'kind': 'brake', 'n': 3}))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--port-base', type=int, default=37780)
    ap.add_argument('--trails', type=int, default=6)
    ap.add_argument('--poke', action='append', default=[])
    ap.add_argument('--plan', help='a plan to start from (its actions are kept)')
    a = ap.parse_args()
    work = os.path.splitext(os.path.abspath(a.out))[0] + '-states'
    os.makedirs(work, exist_ok=True)
    lab = Lab(a.port_base)
    r = Rider(lab, work)
    plan = json.load(open(a.plan))['actions'] if a.plan else {}
    log = []
    try:
        lab.load(os.path.abspath(a.start))
        pokes = []
        for p in a.poke:
            addr, val = (int(x) for x in p.split('='))
            lab.write(addr, bytes([val]))
            pokes.append([addr, val])
        r.hold(['SPACE'], 4)
        r.hold([], 10)
        checkpoints = [dict(r.save(), pos=0, trail=0)]
        fails = 0
        while True:
            res, s = ride(r, plan, checkpoints=checkpoints, until_trail=a.trails)
            print('ride:', res, s, len(r.segs), flush=True)
            log.append({'result': res, 'state': s})
            if res != 'crash':
                break
            crash, trail = s['pos'], s['trail']
            best = None
            for p, action in candidates(crash):
                if p < 0:
                    continue
                cks = [c for c in checkpoints if c['trail'] == trail and c['pos'] <= p - 10]
                if not cks:
                    continue
                ck = cks[-1]
                r.restore(ck)
                trial = {k: list(v) for k, v in plan.items()}
                trial.setdefault(str(trail), []).append((p, action))
                trial[str(trail)].sort(key=lambda x: x[0])
                res2, s2 = ride(r, trial, stop_pos=crash + 150, max_passes=200, until_trail=trail + 1)
                print(f'  try {p} {action} -> {res2} {s2["pos"]}', flush=True)
                if res2 in ('passed', 'trail'):
                    best = (p, action, ck)
                    break
            if best is None:
                fails += 1
                print('no action passes the crash at', trail, crash, [(c['trail'], c['pos']) for c in checkpoints], flush=True)
                break
            p, action, ck = best
            plan.setdefault(str(trail), []).append((p, action))
            plan[str(trail)].sort(key=lambda x: x[0])
            log.append({'kept': [trail, p, action]})
            r.restore(ck)
            checkpoints = [c for c in checkpoints if c['segs'] <= ck['segs']]
        json.dump({'start': os.path.relpath(os.path.abspath(a.start)), 'pokes': pokes, 'actions': plan,
                   'segments': r.segs, 'end': r.st(), 'log': log}, open(a.out, 'w'), indent=0)
        print('segments', len(r.segs), 'frames', sum(f for _k, f in r.segs), 'end', r.st())
    finally:
        lab.close()


if __name__ == '__main__':
    main()

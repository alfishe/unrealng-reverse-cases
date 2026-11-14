#!/usr/bin/env python3
"""The passes of the main loop in an access trace, step by step (doc 04).

    python3 tools/pass_steps.py --work W --window F:T-F:T [--csv OUT]

A pass runs from one exit of the frame wait (`$7A5B`, the counter `$7A60` reached C) to the next. Each instruction's
T-states (to the next instruction) go to the step it belongs to: the routine the main loop `$7D2D-$7EB3` called last
(named by build/game.lst), "loop" for the main loop's own lines, "interrupt" for the IM 2 handler `$FEFE-$FF20` and
what it calls. For each pass: its start (frame:T), its length in frames, the T-states of each step, the interrupts
taken and the frames whose interrupt was lost (no handler entry in that frame).
"""
import argparse
import os
import sys
from bisect import bisect_right

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

LOOP_LO, LOOP_HI = 0x7D2D, 0x7EB3
HANDLER, HANDLER_RET, PASS_END = 0xFEFE, 0xFF20, 0x7A5B


def labels():
    out = []
    for line in open(os.path.join(CASE, 'build', 'game.lst')):
        m = K.LINE.match(line)
        if m:
            lm = K.LABEL.match(m.group(3))
            if lm:
                out.append((int(m.group(1), 16), lm.group(1)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def passes(tr):
    addrs, names = labels()
    units = max(1, tr.units_per_t)
    ft = tr.frame_t

    def at(x):
        return x.frame * ft + x.t // units

    ins = tr.instructions
    out, cur, step, in_handler, prev_in_loop = [], None, 'loop', False, False
    handled = set()
    for i, x in enumerate(ins[:-1]):
        dt = at(ins[i + 1]) - at(x)
        if x.pc == HANDLER:
            in_handler = True
            handled.add(x.frame)
        if x.pc == PASS_END and not in_handler:
            if cur:
                cur['end'] = at(x)
                out.append(cur)
            cur = dict(start=at(x), frame=x.frame, t=x.t // units, steps={}, ints=0)
        if in_handler:
            key = 'interrupt'
            if x.pc == HANDLER and cur:
                cur['ints'] += 1
        else:
            inloop = LOOP_LO <= x.pc < LOOP_HI
            if inloop:
                step = 'loop'
            elif prev_in_loop:
                j = bisect_right(addrs, x.pc) - 1
                step = names[j] if j >= 0 else '$%04X' % x.pc
            prev_in_loop = inloop
            key = step
        if cur is not None:
            cur['steps'][key] = cur['steps'].get(key, 0) + dt
        if in_handler and x.pc == HANDLER_RET:
            in_handler = False
    for p in out:
        f0, f1 = p['start'] // ft, p['end'] // ft
        p['lost'] = [f for f in range(f0 + 1, f1 + 1) if f not in handled]
        p['frames'] = (p['end'] - p['start']) / ft
    return out


def main():
    ap = argparse.ArgumentParser()
    K.add_trace_args(ap)
    ap.add_argument('--csv')
    a = ap.parse_args()
    tr = K.load_trace(a)
    ps = passes(tr)
    keys = []
    for p in ps:
        for k in p['steps']:
            if k not in keys:
                keys.append(k)
    for p in ps:
        work = sum(v for k, v in p['steps'].items() if k not in ('WaitFrames', 'WaitFramesLoop', 'interrupt'))
        print('pass at %d:%d  %.2f frames  work %d T  ints %d  lost %s' % (
            p['frame'], p['t'], p['frames'], work, p['ints'], p['lost']))
        for k, v in sorted(p['steps'].items(), key=lambda kv: -kv[1]):
            print('    %-24s %8d T' % (k, v))
    if a.csv:
        with open(a.csv, 'w') as f:
            f.write('frame,t,frames,ints,lost,' + ','.join(keys) + '\n')
            for p in ps:
                f.write('%d,%d,%.3f,%d,%d,' % (p['frame'], p['t'], p['frames'], p['ints'], len(p['lost'])) +
                        ','.join(str(p['steps'].get(k, 0)) for k in keys) + '\n')


if __name__ == '__main__':
    main()

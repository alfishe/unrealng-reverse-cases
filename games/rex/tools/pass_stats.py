#!/usr/bin/env python3
"""Cut an access trace of play into passes of the main loop and sum each pass's steps.

    python3 tools/pass_stats.py TRACE.uatr --listing build/game.lst [--loop 9586] [--build 9583] [--sp 6000]
        [--steps] [--passes]

A pass runs from one fetch of MainPass (`--loop`, part 1 `$9586`, part 2 `$9588`) to the next; the pass that starts
at MainLoop (`--build`, part 1 `$9583`, part 2 `$9585`) builds a room first. A step is a CALL made at the loop's level (SP = `--sp`, the
main loop's stack: part 1 `$6000`, part 2 `$6190`): every instruction run until the loop's next instruction is that
step's, its T-states the time to the next instruction. The loop's own instructions are "loop".

--passes prints one line a pass: its start (frame:T), its length in T and frames, and the room build if any;
--steps prints the T-states of each step summed over the passes, and its share.
"""
import argparse
import collections
import os
import sys

R = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('trace')
    p.add_argument('--listing', required=True)
    p.add_argument('--loop', default='9586')
    p.add_argument('--build', default='9583')
    p.add_argument('--sp', default='6000')
    p.add_argument('--steps', action='store_true')
    p.add_argument('--passes', action='store_true')
    p.add_argument('--unreal')
    a = p.parse_args()
    t = K.access_trace(a.unreal).load(a.trace)
    lst = K.Listing(a.listing)
    loop, build, sp = (int(x, 16) for x in (a.loop, a.build, a.sp))
    names = {addr: n for addr, n in lst.labels}
    xs = t.instructions
    absolute = [x.frame * t.frame_t + x.t for x in xs]
    passes = []          # (index of the start, built)
    step = 'loop'
    per_pass = []
    cur = None
    for i, x in enumerate(xs):
        if x.pc in (loop, build) and x.sp == sp:
            if cur is not None:
                per_pass.append(cur)
            cur = collections.Counter()
            passes.append((i, x.pc == build))
        if x.sp == sp and loop - 3 <= x.pc < loop + 0x100 or x.pc == build:
            step = 'loop'
            nxt = xs[i + 1].pc if i + 1 < len(xs) else None
            if nxt is not None and xs[i + 1].sp == sp - 2:
                step = names.get(nxt, f'${nxt:04X}')
        if cur is not None and i + 1 < len(xs):
            dt = absolute[i + 1] - absolute[i]
            cur['loop' if (x.sp == sp and step == 'loop') else step] += dt
    if a.passes:
        for k, (i, built) in enumerate(passes[:-1]):
            j = passes[k + 1][0]
            length = absolute[j] - absolute[i]
            print(f'{xs[i].frame}:{xs[i].t}\t{length}\t{length / t.frame_t:.2f}\t{"room built" if built else ""}')
    if a.steps:
        total = collections.Counter()
        light = [c for (i, b), c in zip(passes, per_pass) if not b]
        for c in light:
            total.update(c)
        s = sum(total.values())
        print(f'{len(light)} passes without a room build, {s} T, {s / max(1, len(light)):.0f} T a pass')
        for name, v in total.most_common():
            print(f'{name}\t{v / len(light):.0f}\t{100 * v / s:.1f}%')
        for (i, b), c in zip(passes, per_pass):
            if b:
                s = sum(c.values())
                print(f'room build at {xs[i].frame}:{xs[i].t}: {s} T')
                for name, v in c.most_common(8):
                    print(f'  {name}\t{v}\t{100 * v / s:.1f}%')


if __name__ == '__main__':
    sys.exit(main())

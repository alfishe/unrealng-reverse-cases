#!/usr/bin/env python3
"""The main-loop passes of an access trace: each pass from one fetch of MainLoop `$8DFE` to the next, its start
(frame:t, the trace's TTD units), its length in CPU T-states, how many ActorUpdate `$8E2B` calls it made, whether
an actor was redrawn (BlitWindow `$8C68`), a reveal (RedrawCellsMasked `$8855`) or a room build (EnterRoom `$95C3`)
ran, and the interrupts it took. With --steps, the T-states of each step of the passes (routine by routine on the
loop's call level), summed over the trace.

    python3 tools/pass_stats.py work/docs/zsA/r004000/traces/530_0-553_0.uatr [--steps]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

MARKS = {0x8E2B: 'upd', 0x8C68: 'blit', 0x8855: 'reveal', 0x95C3: 'room', 0xFF01: 'weapon', 0xFF64: 'meters'}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('trace')
    ap.add_argument('--steps', action='store_true')
    a = ap.parse_args()
    tr = K.access_trace().load(a.trace)
    times = K.instruction_times(tr)
    units = max(1, tr.units_per_t)
    starts = [i for i, x in enumerate(tr.instructions) if x.pc == 0x8DFE]
    print('pass\tstart\tT\tframes\tupdates\tblits\treveal\troom\tints')
    for n, (i, j) in enumerate(zip(starts, starts[1:])):
        seen = {k: 0 for k in MARKS.values()}
        ints = 0
        for x in tr.instructions[i:j]:
            if x.pc in MARKS:
                seen[MARKS[x.pc]] += 1
            if x.pc == 0x8456:
                ints += 1
        t = times[j] - times[i]
        x = tr.instructions[i]
        print(f'{n}\t{x.frame}:{x.t}\t{t}\t{t / tr.frame_t:.2f}\t{seen["upd"]}\t{seen["blit"]}\t{seen["reveal"]}\t'
              f'{seen["room"]}\t{ints}')
    if a.steps and len(starts) > 1:
        # T-states by the routine called from the loop's own level (SP = $5C00 - 2 inside a call from the loop)
        own, step, isr = 0, {}, 0
        i0, i1 = starts[0], starts[-1]
        names = {0x8E2B: 'ActorUpdate', 0xFF01: 'PanelWeapon', 0xFF64: 'PanelMeters', 0x6682: 'PauseGame',
                 0x66B6: 'PendingMessage'}
        cur = None
        in_int = 0
        for k in range(i0, i1):
            x = tr.instructions[k]
            dt = times[k + 1] - times[k]
            if x.pc == 0x8456:
                in_int = 1
            if in_int:
                isr += dt
                if x.pc == 0x8470 + 0 and False:
                    pass
                if x.pc == 0x8470:  # RETI
                    in_int = 0
                continue
            if x.sp == 0x5C00 or 0x8DFE <= x.pc <= 0x8E2A:
                if x.pc in names:
                    cur = names[x.pc]
                else:
                    cur = None
                    own += dt
                    continue
            if x.pc in names:
                cur = names[x.pc]
            step[cur or 'other'] = step.get(cur or 'other', 0) + dt
        total = times[i1] - times[i0]
        npass = len(starts) - 1
        print(f'\n{npass} passes, {total} T, {total / npass:.0f} T a pass; loop own {own} T ({own / npass:.0f} a pass); '
              f'interrupts {isr} T')
        for k, v in sorted(step.items(), key=lambda kv: -kv[1]):
            print(f'{k}\t{v}\t{v / npass:.0f} a pass\t{100 * v / total:.1f} %')


if __name__ == '__main__':
    main()

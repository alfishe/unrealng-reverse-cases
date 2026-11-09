#!/usr/bin/env python3
"""Where the time of each interrupt goes: from an access trace of a window of a recording, every entry of the IM 2
handler (`$FCFC` -> `$80F0`, the RET at `$8105`) with its length, and inside it every task the scheduler `$9155`
calls (`$9170 CALL $9187` with HL = the task, back at `$9173`), with T-states; plus the calls of chosen routines
anywhere in the window (their entry to the instruction after the CALL that reached them).

    python3 tools/task_costs.py --work work/runs/w1 --window 1200:0-1300:0 [--routines 9548,959F,90F5]

Prints per task: calls, mean / min / max T a call, its share of the window; per interrupt: the T from entry to RET
and the frames it spans; and per routine: calls and mean / max T (inclusive). One frame is 69 888 T.
"""
import argparse
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

FRAME_T = 69888


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--routines', default='')
    p.add_argument('--per-irq', action='store_true', help='one row per interrupt: its T, each task\'s T and the '
                   'calls of each routine of --routines in it')
    args = p.parse_args()
    tr = K.load_trace(args)
    times = K.instruction_times(tr)
    ins = tr.instructions
    total = times[-1] - times[0] if ins else 0
    tasks = defaultdict(list)
    handler = []
    open_task, open_irq = None, None
    want = {int(x, 16) for x in args.routines.split(',') if x}
    calls = defaultdict(list)
    stack = []  # (routine, return address, start time)
    rows, row = [], None
    for i, x in enumerate(ins):
        t = times[i]
        if x.pc == 0xFCFC:
            open_irq = t
            row = {'t0': t, 'tasks': {}, 'calls': defaultdict(int)}
        elif x.pc == 0x8105 and open_irq is not None:
            handler.append(t - open_irq)
            open_irq = None
            if row:
                row['len'] = t - row['t0']
                rows.append(row)
                row = None
        if x.pc == 0x9170:
            open_task = (x.hl, t)
        elif x.pc == 0x9173 and open_task:
            tasks[open_task[0]].append(t - open_task[1])
            if row:
                row['tasks'][open_task[0]] = t - open_task[1]
            open_task = None
        if row and x.pc in want:
            row['calls'][x.pc] += 1
        if stack and x.pc == stack[-1][1] and x.sp >= stack[-1][3]:
            r, _, t0, _ = stack.pop()
            calls[r].append(t - t0)
        if x.pc in want and i:
            prev = ins[i - 1]
            # the return address is the word the CALL pushed: read it from the stack write of the previous instruction
            ret = None
            writes = [c for c in prev.cycles if c.tag == 'W']
            if len(writes) >= 2:
                ret = writes[0].value << 8 | writes[1].value if writes[0].address > writes[1].address else \
                    writes[1].value << 8 | writes[0].value
            if ret is not None:
                stack.append((x.pc, ret, t, x.sp + 2))
    print(f'window {args.window or args.trace}: {len(ins)} instructions, {total} T ({total / FRAME_T:.1f} frames)')
    if handler:
        print(f'interrupt entries {len(handler)}: mean {sum(handler) / len(handler):.0f} T, min {min(handler)}, '
              f'max {max(handler)} ({max(handler) / FRAME_T:.2f} frames)')
    print('task      calls   mean T    min T    max T   share')
    for a, v in sorted(tasks.items(), key=lambda kv: -sum(kv[1])):
        print(f'${a:04X} {len(v):9} {sum(v) / len(v):8.0f} {min(v):8} {max(v):8} {100 * sum(v) / max(1, total):6.1f} %')
    if args.per_irq:
        names = sorted(tasks)
        print('frame   T irq  ' + ' '.join(f'${a:04X}' for a in names) + '  ' +
              ' '.join(f'n{a:04X}' for a in sorted(want)))
        for r in rows:
            f = (r['t0'] - times[0]) / FRAME_T
            print(f"{f:5.1f} {r['len']:7} " + ' '.join(f"{r['tasks'].get(a, 0):5}" for a in names) + '  ' +
                  ' '.join(f"{r['calls'].get(a, 0):5}" for a in sorted(want)))
    if want:
        print('routine   calls   mean T    max T   share')
        for a in sorted(want):
            v = calls.get(a, [])
            if v:
                print(f'${a:04X} {len(v):9} {sum(v) / len(v):8.0f} {max(v):8} {100 * sum(v) / max(1, total):6.1f} %')
            else:
                print(f'${a:04X}         0')


if __name__ == '__main__':
    main()

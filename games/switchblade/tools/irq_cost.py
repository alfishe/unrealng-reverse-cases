#!/usr/bin/env python3
"""The interrupt's cost in an access trace: for each entry of InterruptHandler `$8456`, the CPU T-states to the
instruction after its RETI (`$8470`), and how much of that GameTick `$8472-$850B` and the sound call (`$853F` up,
or bank 4 on a 128K) took.

    python3 tools/irq_cost.py TRACE.uatr
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

tr = K.access_trace().load(sys.argv[1])
times = K.instruction_times(tr)
rows = []
i = 0
n = len(tr.instructions)
while i < n:
    if tr.instructions[i].pc == 0x8456:
        j, tick, snd = i, 0, 0
        while j < n - 1 and tr.instructions[j].pc != 0x8470:
            dt = times[j + 1] - times[j]
            pc = tr.instructions[j].pc
            if 0x8472 <= pc <= 0x8528 or 0x8E77 <= pc <= 0x8E97:
                tick += dt
            elif pc >= 0x853F and not (0x8456 <= pc <= 0x8471):
                snd += dt
            j += 1
        if j < n - 1:
            rows.append((tr.instructions[i].frame, times[j + 1] - times[i], tick, snd))
        i = j + 1
    else:
        i += 1
print('frame\tT\tGameTick\tsound')
for r in rows:
    print('\t'.join(map(str, r)))
if rows:
    k = len(rows)
    print(f'mean over {k}: {sum(r[1] for r in rows) / k:.0f} T, GameTick {sum(r[2] for r in rows) / k:.0f}, '
          f'sound {sum(r[3] for r in rows) / k:.0f}; max {max(r[1] for r in rows)} T; '
          f'{100 * sum(r[1] for r in rows) / k / tr.frame_t:.1f} % of a frame')

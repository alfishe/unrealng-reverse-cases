#!/usr/bin/env python3
"""An input script (mm_session format, as tools/record.py writes them) from the RZX's port reads
(tools/rzx_snap.py OUT/inputs.json): the keys the player held in RZX frames FROM .. TO-1, for a recording started
from tools/rzx_snap.py's snap-FROM.z80 (the state when RZX frame FROM begins; script frame 0 = RZX frame FROM).

    python3 tools/rzx_script.py work/stage2/rzx/inputs.json FROM TO > tests/inputs/rzx-FROM.txt

The run's player used option 1 of the menu (the keys 6 left, 7 right, 8 down, 9 up, 0 fire: the half row `$EFFE`,
read once a frame by ReadControls `$8529` in the interrupt's tick, and by the high-score entry), P (`$DFFE`, the
tick's pause test `$84B4`) and 1 on the menu (`$F7FE` at `$6A8A`). A frame's keys are those of its last read of each
half row. The tick's half rows (`$EFFE`, `$DFFE`, read in every frame the interrupt runs the tick) keep their keys
through a frame with no read (a room build under DI); a key of another half row (the menu's 1) is held only in the
frames whose reads saw it down. A line is written only where the keys change.
"""
import json
import sys

ROWS = {0xF7FE: ['1', '2', '3', '4', '5'], 0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
        0xEFFE: ['0', '9', '8', '7', '6'], 0x7FFE: ['SPACE', 'SS', 'M', 'N', 'B'], 0xFEFE: ['CS', 'Z', 'X', 'C', 'V'],
        0xDFFE: ['P', 'O', 'I', 'U', 'Y'], 0xBFFE: ['ENTER', 'L', 'K', 'J', 'H']}


CARRY = (0xEFFE, 0xDFFE)


def frame_keys(reads, a, b):
    """{frame: [keys]} for frames a..b-1; the tick's half rows' state carried from the frames before a"""
    state = {}
    for f in sorted(int(k) for k in reads):
        if f >= a:
            break
        for pc, port, v in reads[str(f)]:
            if port in CARRY:
                state[port] = v
    out = {}
    for f in range(a, b):
        state = {p: v for p, v in state.items() if p in CARRY}
        for pc, port, v in reads.get(str(f), []):
            if port in ROWS:
                state[port] = v
        keys = []
        for port, names in ROWS.items():
            v = state.get(port, 0xFF)
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        out[f] = keys
    return out


def script(inputs, a, b):
    reads = json.load(open(inputs))['reads']
    fk = frame_keys(reads, a, b)
    lines = [f'# The RZX Archive run (switchblade.rzx: xmikex and Jamie Angus, SPIN, 48K; someone else\'s play), RZX '
             f'frames {a}-{b - 1} as held keys, from work/stage2/rzx/snap-{a:06d}.z80 (tools/rzx_script.py)']
    last = None
    for f in range(a, b):
        if fk[f] != last:
            lines.append(f'{f - a} {"+".join(fk[f]) or "-"}')
            last = fk[f]
    lines.append(f'{b - a} END')
    return lines


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    print('\n'.join(script(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))))

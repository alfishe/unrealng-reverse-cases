#!/usr/bin/env python3
"""An input script (mm_session format) from the RZX's port reads (tools/rzx_inputs.py): the keys the player held in
RZX frames FROM+1 .. TO, for a capture started from tools/rzx_dump.py's snap-FROM.z80 (the state after RZX frame FROM).

    python3 tools/rzx_script.py work/stage1/rzx/inputs.json FROM TO [--each] > tests/inputs/rzx-FROM.txt

The player chose the cursor keys (the re-release's reads at `$A1BC`, port `$EFFE`: 6 7 8 0, and `$A1E5`, port
`$F7FE`: 5); a frame's keys are those of its last read of each port. A line is written only where the keys change, or with --each one line a frame
(so the capture runs the segment in one-frame calls).
"""
import json
import sys

KEMP = [(1, 'KR'), (2, 'KL'), (4, 'KD'), (8, 'KU'), (16, 'KF')]
ROWS = {0xF7FE: ['1', '2', '3', '4', '5'], 0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
        0xEFFE: ['0', '9', '8', '7', '6'], 0x7FFE: ['SPACE', 'SS', 'M', 'N', 'B'], 0xFEFE: ['CS', 'Z', 'X', 'C', 'V'],
        0xDFFE: ['P', 'O', 'I', 'U', 'Y'], 0xBFFE: ['ENTER', 'L', 'K', 'J', 'H']}


def frame_keys(reads, a, b):
    per = {}
    for f, pc, port, v in reads:
        if a < f <= b:
            st = per.setdefault(f, {})
            if port & 0xFF == 0x1F:
                st['kemp'] = v
            elif port in ROWS:
                st[port] = v
    out, state = {}, {}
    for f in range(a + 1, b + 1):
        state.update(per.get(f, {}))
        keys = [n for bit, n in KEMP if state.get('kemp', 0) & bit]
        for port, names in ROWS.items():
            v = state.get(port, 0xFF)
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        out[f] = keys
    return out


def main():
    each = '--each' in sys.argv
    args = [x for x in sys.argv[1:] if x != '--each']
    log, a, b = args[0], int(args[1]), int(args[2])
    reads = json.load(open(log))['reads']
    fk = frame_keys(reads, a, b)
    print(f'# RZX archive rick1.rzx (SPIN 0.5, 128K, a re-release build; someone else\'s run), frames {a + 1}-{b} as held '
          f'keys, from tools/rzx_dump.py snap-{a:05d}.z80 (tools/rzx_script.py)')
    last = None
    for f in range(a + 1, b + 1):
        if each or fk[f] != last:
            print(f'{f - a - 1} {" ".join(fk[f]) or "-"}')
            last = fk[f]
    print(f'{b - a} END')


if __name__ == '__main__':
    main()

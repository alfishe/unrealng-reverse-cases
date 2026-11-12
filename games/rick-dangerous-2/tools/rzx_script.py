#!/usr/bin/env python3
"""An input script (mm_session format) from the RZX's port reads (tools/rzx_inputs.py): the keys the player held in
RZX frames FROM+1 .. TO, for a capture started from tools/rzx_log.py's at<FROM>.szx (the state after FROM frames of
the RZX's playback; start.szx for FROM 0).

    python3 tools/rzx_script.py work/stage1/rzx/inputs-l2.json FROM TO [--each] > tests/inputs/rzx-l2-FROM.txt

The game reads its controls at `$7254` into `$7253` (the method in `$7252`: 0 keyboard, 1 Kempston, 2 cursor,
3 Sinclair) and the pause, quit and menu keys in the helpers at `$71C0-$724A`. A frame's keys are those of its last
read of each port; the reads of the ROM's LD-BYTES (PC below `$4000`, the next level's load at the end of a part)
are not keys and are left out. A line is written only where the keys change, or with --each one line a frame.
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
        if a < f <= b and pc >= 0x4000:
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
    print(f'# RZX archive rick2 (Jim Waterman, SPIN 0.5): {log}, frames {a + 1}-{b} as held keys, '
          f'from the state after frame {a} (tools/rzx_script.py)')
    last = None
    for f in range(a + 1, b + 1):
        if each or fk[f] != last:
            print(f'{f - a - 1} {" ".join(fk[f]) or "-"}')
            last = fk[f]
    print(f'{b - a} END')


if __name__ == '__main__':
    main()

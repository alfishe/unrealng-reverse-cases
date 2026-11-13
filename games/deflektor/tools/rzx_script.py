#!/usr/bin/env python3
"""An input script (mm_session format) from the RZX's port reads (tools/rzx_dump.py's inputs.json): the keys the
player held in RZX frames FROM+1 .. TO, for a capture started from snap-FROM.z80 (the state after RZX frame FROM).

    python3 tools/rzx_script.py work/stage1/rzx/inputs.json FROM TO > tests/inputs/rzx-FROM.txt

inputs.json holds, for each keyboard half-row, the frames where the value of the frame's last read changed. The RZX
player used the Sinclair joystick (control `$81FD` = 1: half-rows `$F7FE` and `$EFFE`, read at `$98AF` and `$98B7`)
and the menu keys; a pressed key is a low bit 0-4 of its half-row. A line is written only where the keys change.
"""
import bisect
import json
import sys

ROWS = {'F7FE': ['1', '2', '3', '4', '5'], 'FDFE': ['A', 'S', 'D', 'F', 'G'], 'FBFE': ['Q', 'W', 'E', 'R', 'T'],
        'EFFE': ['0', '9', '8', '7', '6'], '7FFE': ['SPACE', 'SS', 'M', 'N', 'B'], 'FEFE': ['CS', 'Z', 'X', 'C', 'V'],
        'DFFE': ['P', 'O', 'I', 'U', 'Y'], 'BFFE': ['ENTER', 'L', 'K', 'J', 'H']}


def value_at(changes, f):
    i = bisect.bisect_right(changes, [f, 0x100])
    return changes[i - 1][1] if i else 0xFF


def main():
    log, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    ch = json.load(open(log))['changes']
    print(f"# RZX archive deflektor.rzx (Roman Rugalenko, recorded with rollback; someone else's run), frames "
          f"{a + 1}-{b} as held keys, from tools/rzx_dump.py snap-{a:06d}.z80 (tools/rzx_script.py)")
    last = None
    for f in range(a + 1, b + 1):
        keys = []
        for port, names in ROWS.items():
            v = value_at(ch.get(port, []), f)
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        if keys != last:
            print(f'{f - a - 1} {" ".join(keys) or "-"}')
            last = keys
    print(f'{b - a} END')


if __name__ == '__main__':
    main()

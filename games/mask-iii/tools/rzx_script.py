#!/usr/bin/env python3
"""An input script (mm_session format) from the RZX's port reads: the keys the RZX's player held in RZX frames
FROM .. TO-1 (0-based: frame FROM is the first one played after kit/rzx_dump.py's snap-FROM.z80, the state after FROM
frames of the RZX), for a capture started from that snapshot; script frame k is RZX frame FROM + k.

    python3 tools/rzx_script.py work/stage1/rzx/snaps/inputs.json FROM TO > tests/inputs/rzx-FROM.txt

inputs.json is kit/rzx_dump.py's: for each keyboard half-row port the frames where the frame's last read value
changed. The RZX's player (ZXDB mask3.rzx) used the Interface 2 stick (port `$EFFE`: 0 fire, 9 up, 8 down, 7 right,
6 left; the game reads it at `$A0AB`) and the keys 1-4 (port `$F7FE`, the MASK choice). A line is written only where
the held keys change.
"""
import json
import sys

ROWS = {0xF7FE: ['1', '2', '3', '4', '5'], 0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
        0xEFFE: ['0', '9', '8', '7', '6'], 0x7FFE: ['SPACE', 'SS', 'M', 'N', 'B'], 0xFEFE: ['CS', 'Z', 'X', 'C', 'V'],
        0xDFFE: ['P', 'O', 'I', 'U', 'Y'], 0xBFFE: ['ENTER', 'L', 'K', 'J', 'H']}


def frame_keys(changes, a, b):
    """{frame: [keys]} for frames a .. b-1: each port's last value in the frame"""
    out = {}
    for f in range(a, b):
        keys = []
        for port, names in ROWS.items():
            v = 0xFF
            for fr, val in changes.get(f'{port:04X}', []):
                if fr > f:
                    break
                v = val
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        out[f] = keys
    return out


def main():
    path, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    changes = json.load(open(path))['changes']
    fk = frame_keys(changes, a, b)
    print(f'# ZXDB mask3.rzx: frames {a}-{b - 1} as held keys, from the state after frame {a} '
          f'(tools/rzx_script.py {path} {a} {b})')
    last = None
    for f in range(a, b):
        if fk[f] != last:
            print(f'{f - a} {" ".join(fk[f]) or "-"}')
            last = fk[f]
    print(f'{b - a} END')


if __name__ == '__main__':
    main()

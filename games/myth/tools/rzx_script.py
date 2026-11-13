#!/usr/bin/env python3
"""An input script (mm_session format, as tools/record.py writes them: `FRAME KEY KEY`, `FRAME -` releases,
`FRAME END`) from the port reads of the RZX Archive's myth.rzx (tools/rzx_inputs.py OUT/inputs.json): the keys the
player held in RZX frames FROM .. TO-1, for a recording started from the state when RZX frame FROM begins (an input
block's own snapshot work/stage1/rzx/snapN.z80 at FROM = blocks[N], or tools/rzx_inputs.py's snap-FROM.z80); script
frame 0 = RZX frame FROM.

    python3 tools/rzx_script.py work/stage2/rzx/inputs.json FROM TO > tests/inputs/rzx-NAME.txt

The run's player defined the keys 6 7 8 9 0 on the menu (DEFINE KEYS, the any-key scan `$9939` of the front block:
the half row `$EFFE`), so in play the key readers `$FC90-$FCDA` read `$EFFE` only (6 left, 7 right, 8 down, 9 up,
0 fire: the Sinclair joystick's keys); SPACE (`$7FFE`) opens the item window (`$8A5A`, `$8F7F`, `$88FB` and the
others of the stage blocks) and takes the logo, the credits and the menu (`$7969`, `$9A26`, `$9D2C`). The game has
no frame sync: a pass of the main loop takes about three frames and reads each half row once, so most frames read
nothing. A half row keeps its keys through the frames that do not read it (the player holds a key, the RZX only shows it when the game looks). Only the low five
bits of a read are keys (bit 6 is EAR, which the RZX gives as the tape left it). The keys change midway between the two reads that saw the change (frame_keys). A
line is written only where the keys change.
"""
import json
import sys

ROWS = {0xF7FE: ['1', '2', '3', '4', '5'], 0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
        0xEFFE: ['0', '9', '8', '7', '6'], 0x7FFE: ['SPACE', 'SS', 'M', 'N', 'B'], 0xFEFE: ['CS', 'Z', 'X', 'C', 'V'],
        0xDFFE: ['P', 'O', 'I', 'U', 'Y'], 0xBFFE: ['ENTER', 'L', 'K', 'J', 'H']}


def frame_keys(reads, a, b):
    """{frame: [keys]} for frames a..b-1. Each half row's reads are taken per frame (the last read of the frame);
    where two reads of a half row in frames f1 < f2 differ, the keys change at frame (f1 + f2 + 1) // 2, midway, so a
    read that falls a frame earlier or later in our machine than in the RZX's still sees what the player held"""
    per = {}
    for f in sorted(int(k) for k in reads):
        for pc, port, v in reads[str(f)]:
            if port in ROWS:
                per.setdefault(port, {})[f] = v & 0x1F
    change = {}
    for port, seen in per.items():
        frames = sorted(seen)
        cur = 0x1F
        for i, f in enumerate(frames):
            v = seen[f]
            if v != cur:
                prev = frames[i - 1] if i else f - 1
                change.setdefault((prev + f + 1) // 2, {})[port] = v
                cur = v
    state = {}
    for f in sorted(change):
        if f >= a:
            break
        state.update(change[f])
    out = {}
    for f in range(a, b):
        state.update(change.get(f, {}))
        keys = []
        for port, names in ROWS.items():
            v = state.get(port, 0x1F)
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        out[f] = keys
    return out


def script(inputs, a, b, start=''):
    reads = json.load(open(inputs))['reads']
    fk = frame_keys(reads, a, b)
    lines = [f'# The RZX Archive run (myth.rzx, 128K; someone else\'s play), RZX frames {a}-{b - 1} as held keys, '
             f'from {start or f"the state when RZX frame {a} begins"} (tools/rzx_script.py)']
    last = None
    for f in range(a, b):
        if fk[f] != last:
            lines.append(f'{f - a} {" ".join(fk[f]) or "-"}')
            last = fk[f]
    lines.append(f'{b - a} END')
    return lines


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    print('\n'.join(script(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))))

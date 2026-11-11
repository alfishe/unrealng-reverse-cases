#!/usr/bin/env python3
"""An RZX playthrough replayed in unreal-ng frame by frame, checked against the RZX at every frame, written as an
input script with one line a frame (so re_session.py capture splits the run into the same one-frame calls and
reaches the same states: docs/unreal-ng-run-frames-faults.md).

    python3 tools/rzx_align.py work/stage1/rzx/earth01.ins.json --snapshot work/stage1/rzx/start/earth01.rzx.001.z80 \
        --out tests/inputs/rzx-earth01.txt [--port-base 37110]

The log is tools/rzx_inputs.py's (the reads, and NAME.state.bin: `$FD7E-$FFFF` at the end of every RZX frame). From the
RZX's start snapshot, each frame runs with the keys the RZX held in the frame it should match (tools/rzx_script.py
frame_keys); after it the same bytes are read and compared with the RZX frames near it. An RZX frame is not always one
video frame (the menu's tune runs with the interrupt masked): where they part, the offset between the two counts moves
to the RZX frame that matches; every move is listed in NAME.align.json. A frame that matches no RZX frame within
WINDOW (fewer than LIMIT bytes apart) for STREAK frames running ends the replay there: the script stops at the last frame that matched.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402
from rzx_script import frame_keys  # noqa: E402

STATE, SIZE = 0xFD7E, 0x10000 - 0xFD7E
WINDOW, LIMIT, STREAK = 3, 24, 12


def diff(a, b):
    return sum(1 for x, y in zip(a, b) if x != y)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('log')
    ap.add_argument('--snapshot', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--port-base', type=int, default=37110)
    ap.add_argument('--tail', type=int, default=50)
    args = ap.parse_args()
    log = json.load(open(args.log))
    raw = open(os.path.splitext(args.log)[0] + '.state.bin', 'rb').read()
    states = [raw[i:i + SIZE] for i in range(0, len(raw), SIZE)]  # states[k]: the end of RZX frame k
    keys = frame_keys(log)
    lab = Lab(args.port_base)
    lines, moves, inexact = [], [], 0
    off, g, last_good, streak = 0, 0, 0, 0
    try:
        lab.load(args.snapshot)
        held = []
        while g + off < len(states):
            want = sorted(keys[g + off])
            if want != held:
                lab.keys(want)
                held = want
            lines.append(f"{g} {' '.join(want) or '-'}")
            lab.run(1)
            got = lab.read(STATE, SIZE)
            best = None
            for d in sorted(range(-WINDOW, WINDOW + 1), key=abs):
                k = g + off + d
                if 0 <= k < len(states):
                    n = diff(got, states[k])
                    if best is None or n < best[0]:
                        best = (n, d)
                    if n == 0:
                        break
            if best[0] >= LIMIT:  # inside a long piece of work (the cave unpacked, the screen drawn): go on a while
                streak += 1
                if streak > STREAK:
                    print(f'frame {g}: no RZX frame within {WINDOW} for {STREAK} frames (nearest {best[0]} bytes '
                          f'apart, offset {off})')
                    moves.append({'frame': g, 'lost': best[0], 'offset': off})
                    break
                g += 1
                continue
            streak = 0
            if best[1]:
                off += best[1]
                moves.append({'frame': g, 'offset': off, 'bytes': best[0]})
            inexact += best[0] > 0
            g += 1
            last_good = g
            if g % 1000 == 0:
                print(f'frame {g}, RZX frame {g + off}, offset {off}, inexact {inexact}', flush=True)
        lab.keys([])
    finally:
        lab.close()
    lines = lines[:last_good]
    head = (f"# {log['rzx']} (someone else's recording) replayed from its start snapshot, one line a frame, "
            f"checked against the RZX at every frame (tools/rzx_align.py): {last_good} frames to RZX frame "
            f"{last_good + off} of {len(states)}")
    open(args.out, 'w').write('\n'.join([head] + lines + [f'{last_good + args.tail} END']) + '\n')
    json.dump({'frames': last_good, 'rzx_frames': len(states), 'end_offset': off, 'inexact_frames': inexact,
               'moves': moves}, open(os.path.splitext(args.log)[0] + '.align.json', 'w'), indent=1)
    print(f'{args.out}: {last_good} frames, RZX frame {last_good + off} of {len(states)}, inexact {inexact}')


if __name__ == '__main__':
    main()

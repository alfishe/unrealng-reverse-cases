#!/usr/bin/env python3
"""Per-frame memory of a recording, for the zyB figures: two windows read by TTD memory_at at the end of each frame.

    python3 tools/ttd_dump.py --work work/zyB/w1 --frames 0:5985 [--every 1] --out work/zyB/w1-frames.npz

The windows: $7F9C-$81FF (the player records, the game and system variables, the controls, the script state) and
$F36C-$F62B (the 16 object records of 44 bytes). Stored as uint8 arrays `vars` and `objs`, one row a frame, with
`frames`. With --screen also the screen ($4000-$5AFF) as `screen`.
"""
import argparse
import numpy as np
import zynlib as Z

p = argparse.ArgumentParser()
p.add_argument('--work', required=True)
p.add_argument('--frames', required=True)
p.add_argument('--every', type=int, default=1)
p.add_argument('--screen', action='store_true')
p.add_argument('--out', required=True)
a = p.parse_args()
lo, hi = map(int, a.frames.split(':'))
s = Z.session(a.work)
fr = list(range(lo, hi + 1, a.every))
V, O, S = [], [], []
for f in fr:
    V.append(np.frombuffer(Z.read(s, f, 0x7F9C, 0x8200 - 0x7F9C), np.uint8))
    O.append(np.frombuffer(Z.read(s, f, 0xF36C, 44 * 16), np.uint8))
    if a.screen:
        S.append(np.frombuffer(Z.read(s, f, 0x4000, 6912), np.uint8))
    if f % 1000 == 0:
        print(f, flush=True)
extra = {'screen': np.array(S)} if a.screen else {}
np.savez_compressed(a.out, frames=np.array(fr), vars=np.array(V), objs=np.array(O), **extra)
print('wrote', a.out, len(fr), 'frames')

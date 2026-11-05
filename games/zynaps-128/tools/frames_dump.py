#!/usr/bin/env python3
"""Per-frame memory of a recording for the z128B figures (docs 07 and 10), read by TTD memory_at at each frame's end.

    python3 tools/frames_dump.py --work work/z128B/w1 --frames 700:9700 [--every 2] [--screen] \
        --out work/z128B/w1-frames.npz

Adapted from ../zynaps/tools/ttd_dump.py. The windows:

- `vars`: `$7F9C`-`$81FF` (the player records, the game variables, Fuel `$80E6`, FireHeld `$8184`), the CPU view;
- `objs`: the 16 object records of 44 bytes at `$F36C`-`$F62B`, read from RAM page 0 (space ram) because the
  interrupt's engine call maps page 4 at `$C000` and a frame can end inside it;
- `screen` (with --screen): `$4000`-`$5AFF`, RAM page 5.

One row a frame, with `frames`.
"""
import argparse

import numpy as np

import z128lib as Z

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
    O.append(np.frombuffer(Z.read(s, f, 0xF36C - 0xC000, 44 * 16, space='ram', page=0), np.uint8))
    if a.screen:
        S.append(np.frombuffer(Z.read(s, f, 0x0000, 6912, space='ram', page=5), np.uint8))
    if f % 1000 == 0:
        print(f, flush=True)
extra = {'screen': np.array(S)} if a.screen else {}
np.savez_compressed(a.out, frames=np.array(fr), vars=np.array(V), objs=np.array(O), **extra)
print('wrote', a.out, len(fr), 'frames')

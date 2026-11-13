#!/usr/bin/env python3
"""How far an RZX segment recording stays on the RZX's course: for each of its screens (`screens/NNNNNN.scr`, every
250 frames) the share of the 6144 bitmap bytes that differ from the RZX's own screen at frame FROM + NNNNNN
(tools/rzx_dump.py's screens.bin, every 250 frames).

    python3 tools/rzx_sync.py work/stage1/rzx FROM work/stage1/rzx/rFROM
"""
import glob
import json
import os
import sys

rzx, a, rec = sys.argv[1], int(sys.argv[2]), sys.argv[3]
ix = json.load(open(os.path.join(rzx, 'index.json')))
pos = {f: i for i, f in enumerate(ix['frames'])}
sc = open(os.path.join(rzx, 'screens.bin'), 'rb')
out = []
for p in sorted(glob.glob(os.path.join(rec, 'screens', '*.scr'))):
    k = int(os.path.basename(p)[:6])
    if a + k not in pos:
        continue
    sc.seek(pos[a + k] * 6912)
    r = sc.read(6144)
    o = open(p, 'rb').read()[:6144]
    out.append((k, sum(x != y for x, y in zip(r, o)) * 100.0 / 6144))
print(' '.join(f'{k}:{d:.1f}' for k, d in out))
worst = max((d for _, d in out), default=0)
print(f'worst {worst:.1f} %')

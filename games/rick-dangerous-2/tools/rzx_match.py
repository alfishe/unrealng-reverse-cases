#!/usr/bin/env python3
"""How long a recording made from an RZX state keeps to the RZX: each saved screen of the recording (re_session's
screens/NNNNNN.scr, after NNNNNN frames) against the RZX log's screen after FROM + NNNNNN frames (tools/rzx_log.py,
one every 25 frames). Prints the differing bytes of each pair and the last frame that matches exactly.

    python3 tools/rzx_match.py work/stage1/rzx/l2 1000 work/stage1/rec/rzx-l2-01000
"""
import json
import os
import sys

log, start, rec = sys.argv[1], int(sys.argv[2]), sys.argv[3]
every = json.load(open(os.path.join(log, 'log.json')))['every']
s = open(os.path.join(log, 'screens.bin'), 'rb').read()
good = 0
for f in sorted(os.listdir(os.path.join(rec, 'screens'))):
    n = int(f[:-4])
    i = (start + n) // every
    if (start + n) % every or (i + 1) * 6912 > len(s):
        continue
    ours = open(os.path.join(rec, 'screens', f), 'rb').read()
    d = sum(1 for a, b in zip(ours, s[i * 6912:(i + 1) * 6912]) if a != b)
    print(f'frame {n}: {d} bytes differ')
    if d == 0 and good == n - 250 or (d == 0 and good == 0 and n == 250):
        good = n
print(f'in step with the RZX up to frame {good}')

#!/usr/bin/env python3
"""The executed HALT, DI, EI, IM 1 / IM 2 and LD I,A instructions of the game ($5B00 up) over L1 builds, with their
counts: the witnesses of the interrupt set-up.

    python3 tools/irq_sites.py work/runs/a1/l1.json ...
"""
import json
import sys

OPS = {'76': 'HALT', 'F3': 'DI', 'FB': 'EI', 'ED56': 'IM 1', 'ED5E': 'IM 2', 'ED46': 'IM 0', 'ED47': 'LD I,A'}
tot = {}
for path in sys.argv[1:]:
    for z, p, code, cls, cnt, *r in json.load(open(path))['instructions']:
        if code.upper() in OPS and int(z[1:], 16) >= 0x5B00:
            tot[z] = (OPS[code.upper()], tot.get(z, ('', 0))[1] + cnt)
for z in sorted(tot):
    print(z, *tot[z])

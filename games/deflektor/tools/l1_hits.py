#!/usr/bin/env python3
"""How many times each given instruction ran in each recording's L1 (l1.json): the witness that a path was reached.

    python3 tools/l1_hits.py 86A6,A66F,A6EE work/stage1/*/l1.json work/stage1/rzx/r*/l1.json
"""
import json
import os
import sys

addrs = ['$' + a.upper() for a in sys.argv[1].split(',')]
tot = {a: 0 for a in addrs}
print('recording\t' + '\t'.join(addrs))
for p in sys.argv[2:]:
    d = json.load(open(p))
    c = {}
    for r in d['instructions']:
        c[r[0]] = c.get(r[0], 0) + r[4]
    row = [c.get(a, 0) for a in addrs]
    for a, n in zip(addrs, row):
        tot[a] += n
    if any(row):
        print(os.path.basename(os.path.dirname(p)) + '\t' + '\t'.join(map(str, row)))
print('all\t' + '\t'.join(str(tot[a]) for a in addrs))

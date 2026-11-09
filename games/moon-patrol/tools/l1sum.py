#!/usr/bin/env python3
"""Execution counts of instructions (and routine entries with their first / last frame) over every L1 build of the
case: work/game (c1 from frame 256, fast load) and the stage-1 recordings work/runs/{a1,g1,t1,p2,h1,i1,i2,h2}.
The witness for a routine's name: which recordings ran it, how often, and when.

    python3 tools/l1sum.py 9751 97E8 ...          # each address: count per build, routine entries and frames
    python3 tools/l1sum.py --range 9696-9760      # every instruction start in the range with its counts
    python3 tools/l1sum.py --reads B7E8-B7F0      # data reads per byte per build
"""
import argparse
import json
import os

CASE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
BUILDS = ['game', 'runs/a1', 'runs/g1', 'runs/t1', 'runs/p2', 'runs/h1', 'runs/i1', 'runs/i2', 'runs/h2']
BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def load():
    out = {}
    for b in BUILDS:
        d = json.load(open(os.path.join(CASE, 'work', b, 'l1.json')))
        ex = {}
        for z, p, code, cls, cnt, *r in d['instructions']:
            if p in BASES:
                ex[int(z[1:], 16)] = (cnt, code)
        rs = {int(r['entry'][1:], 16): r for r in d['routines'] if r['page'] in BASES}
        reads = [0] * 0x10000
        for pg in d.get('byte_counts', []):
            base = BASES.get(pg['page'])
            if base is not None:
                for i, n in enumerate(pg['reads']):
                    reads[base + i] = n
        out[b.split('/')[-1]] = (ex, rs, reads)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('addrs', nargs='*')
    p.add_argument('--range')
    p.add_argument('--reads')
    a = p.parse_args()
    L = load()
    if a.reads:
        lo, hi = (int(x, 16) for x in a.reads.split('-'))
        for x in range(lo, hi + 1):
            print('$%04X ' % x + ' '.join('%s:%d' % (k, v[2][x]) for k, v in L.items() if v[2][x]))
        return
    addrs = [int(x, 16) for x in a.addrs]
    if a.range:
        lo, hi = (int(x, 16) for x in a.range.split('-'))
        addrs = sorted({x for v in L.values() for x in v[0] if lo <= x <= hi})
    for x in addrs:
        cnts = ' '.join('%s:%d' % (k, v[0][x][0]) for k, v in L.items() if x in v[0])
        line = '$%04X %s' % (x, cnts or 'not executed in any build')
        ents = []
        for k, v in L.items():
            r = v[1].get(x)
            if r:
                pr = r['profile']
                ents.append('%s %d@%d-%d' % (k, pr['entries'], pr['first_frame'], pr['last_frame']))
        if ents:
            line += ' | entries ' + ', '.join(ents)
        print(line)


if __name__ == '__main__':
    main()

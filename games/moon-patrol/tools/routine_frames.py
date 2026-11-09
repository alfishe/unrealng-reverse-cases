#!/usr/bin/env python3
"""Entries, first and last frame of chosen routines (or blocks containing an address) in L1 builds: when a code path
first ran in a recording. Frames are the L1's (since the recording's first frame).

    python3 tools/routine_frames.py work/runs/i1/l1.json 9775 99A3 9B6B ...
"""
import json
import sys


def main():
    path, addrs = sys.argv[1], [int(a, 16) for a in sys.argv[2:]]
    d = json.load(open(path))
    execs = {}
    for z, p, code, cls, cnt, *r in d['instructions']:
        execs[int(z[1:], 16)] = cnt
    rs = {int(r['entry'][1:], 16): r for r in d['routines']}
    for a in addrs:
        r = rs.get(a)
        if r:
            pr = r['profile']
            print('$%04X routine entries %d frames %d-%d' % (a, pr['entries'], pr['first_frame'], pr['last_frame']))
        else:
            print('$%04X %s' % (a, 'executed %d times (not a routine entry)' % execs[a] if a in execs else 'not executed'))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Execution counts of the game's instructions over the eight L1 builds (work/game, the c1 game window, and the seven
stage 1 recordings in work/stage1/rec): one column a build, the total last. The witness for "ran N times" in
src/game/game.ann.

    python3 tools/l1count.py 9858 B34C ...          # the count of the instruction at each address
    python3 tools/l1count.py --never 911E-B15F       # the instruction starts in a range no build ran (from the listing)
    python3 tools/l1count.py --ran 8214-CBE8         # the ranges of addresses the builds ran, merged
    python3 tools/l1count.py --reads 8214-CBE8       # the ranges of bytes read as data (no instruction there), merged
    python3 tools/l1count.py --writes 8214-CBE8      # the ranges of bytes written, merged
"""
import argparse
import json
import os

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILDS = ['work/game'] + ['work/stage1/rec/' + n for n in
                          ('idle-1p', 'tour-type2', 'tour-redefine', 'levels-1-3', 'fall-death', 'gameover-name',
                           'levels-1-9')]
SHORT = ['c1', 'idle', 'type2', 'redef', 'l1-3', 'fall', 'name', 'l1-9']


def counts():
    out = []
    for b in BUILDS:
        d = json.load(open(os.path.join(CASE, b, 'l1.json')))
        c = {}
        for addr, page, code, _kind, cnt, *_r in d['instructions']:
            a = int(addr[1:], 16)
            c[a] = (c.get(a, (0, 0))[0] + cnt, len(code) // 2)
        out.append(c)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument('addrs', nargs='*')
    p.add_argument('--ran')
    p.add_argument('--reads')
    p.add_argument('--writes')
    args = p.parse_args()
    if args.reads or args.writes:
        rng = args.reads or args.writes
        key = 'reads' if args.reads else 'writes'
        lo, hi = (int(x, 16) for x in rng.split('-'))
        code = set()
        for c in counts():
            for a, (n, ln) in c.items():
                code.update(range(a, a + ln))
        tot = [0] * 0x10000
        for b in BUILDS:
            d = json.load(open(os.path.join(CASE, b, 'l1.json')))
            for page in d['byte_counts']:
                base = {5: 0x4000, 2: 0x8000, 0: 0xC000}.get(page['page'])
                if base is None:
                    continue
                for i, n in enumerate(page[key]):
                    tot[base + i] += n
        a = lo
        while a < hi:
            if tot[a] and (key == 'writes' or a not in code):
                s0, n = a, 0
                while a < hi and tot[a] and (key == 'writes' or a not in code):
                    n += tot[a]
                    a += 1
                print('$%04X-$%04X %5d bytes, %d %s' % (s0, a - 1, a - s0, n, key))
            else:
                a += 1
        return
    cs = counts()
    if args.ran:
        lo, hi = (int(x, 16) for x in args.ran.split('-'))
        ran = sorted({a + k for c in cs for a, (n, ln) in c.items() if lo <= a < hi for k in range(ln)})
        runs, start = [], None
        for i, a in enumerate(ran):
            if start is None:
                start = a
            if i + 1 == len(ran) or ran[i + 1] != a + 1:
                runs.append((start, a))
                start = None
        for s, e in runs:
            print('$%04X-$%04X %d bytes' % (s, e, e - s + 1))
        return
    print('addr   ' + ' '.join('%9s' % s for s in SHORT) + '     total')
    for t in args.addrs:
        a = int(t.lstrip('$'), 16)
        row = [c.get(a, (0, 0))[0] for c in cs]
        print('$%04X ' % a + ' '.join('%9d' % n for n in row) + ' %9d' % sum(row))


if __name__ == '__main__':
    main()

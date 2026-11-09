#!/usr/bin/env python3
"""The union of several L1 builds (l1.json) per byte of $4000-$FFFF: executed (an instruction's byte), read as data,
written; then the runs of bytes alike, classified (code, code also read, data read, written, written and read,
untouched), with the first and last writer frame where it helps. The input of the memory map of doc 02.

    python3 tools/l1map.py work/c1/l1.json work/runs/m1/l1.json ... [--min 16] [--from 5B00] [--to FFFF]
    python3 tools/l1map.py ... --dump work/stage1/l1map.json   # per-byte flags for the figure

Classes: X executed, XR executed and read (code read as data), R read only, W written only (a buffer the game
fills, never read back in these recordings), WR written and read (variables, buffers), XW executed and written
(code patched or overlaid), - untouched.
"""
import argparse
import json

BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def load(paths):
    ex, rd, wr = [0] * 0x10000, [0] * 0x10000, [0] * 0x10000
    for path in paths:
        doc = json.load(open(path))
        for z80, page, code, _cls, count, *_ in doc['instructions']:
            a = int(z80[1:], 16)
            for i in range(len(code) // 2):
                ex[(a + i) & 0xFFFF] += count
        for page in doc.get('byte_counts', []):
            base = BASES.get(page['page'])
            if base is None:
                continue
            for i in range(0x4000):
                rd[base + i] += page['reads'][i]
                wr[base + i] += page['writes'][i]
    return ex, rd, wr


def klass(e, r, w):
    k = ('X' if e else '') + ('R' if r else '') + ('W' if w else '')
    if k in ('XR', 'X', 'R', 'W', 'XW', 'XRW'):
        return {'XRW': 'XW'}.get(k, k)
    if k == 'RW':
        return 'WR'
    return k or '-'


def runs(ex, rd, wr, lo, hi):
    out, start, cur = [], lo, None
    for a in range(lo, hi + 1):
        k = klass(ex[a], rd[a], wr[a])
        if cur is None:
            cur = k
        elif k != cur:
            out.append((start, a - 1, cur))
            start, cur = a, k
    out.append((start, hi, cur))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('l1', nargs='+')
    p.add_argument('--from', dest='lo', default='5B00')
    p.add_argument('--to', dest='hi', default='FFFF')
    p.add_argument('--min', type=int, default=1, help='print runs of at least this many bytes')
    p.add_argument('--dump')
    args = p.parse_args()
    ex, rd, wr = load(args.l1)
    lo, hi = int(args.lo, 16), int(args.hi, 16)
    rs = runs(ex, rd, wr, lo, hi)
    tot = {}
    for a, b, k in rs:
        tot[k] = tot.get(k, 0) + b - a + 1
        if b - a + 1 >= args.min:
            print('$%04X-$%04X %6d %s' % (a, b, b - a + 1, k))
    print('totals:', ', '.join('%s %d' % kv for kv in sorted(tot.items())))
    if args.dump:
        json.dump({'ex': ex, 'rd': rd, 'wr': wr}, open(args.dump, 'w'))


if __name__ == '__main__':
    main()

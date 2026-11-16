#!/usr/bin/env python3
"""A first memory map from L1 builds: each byte of the 64K view ($4000-$FFFF, pages 5, 2, 0) classed as code (an
instruction starts or runs there), written data (written by a data write), read-only data (read, never written) or
untouched, over the union of the builds given; runs of one class are printed with their lengths (runs shorter than
--merge bytes fold into their neighbour, so code islands and table gaps read as one region).

    python3 tools/l1_regions.py L1 [L1 ...] [--from 5B00] [--merge 32]
"""
import argparse
import json

BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}
NAMES = {0: 'untouched', 1: 'read-only data', 2: 'written data', 3: 'code'}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('l1', nargs='+')
    ap.add_argument('--from', dest='lo', default='5B00')
    ap.add_argument('--merge', type=int, default=32)
    a = ap.parse_args()
    cls = [0] * 0x10000
    for path in a.l1:
        d = json.load(open(path))
        for p in d['byte_counts']:
            base = BASES.get(p['page'])
            if base is None:
                continue
            for i in range(0x4000):
                if p['writes'][i]:
                    cls[base + i] = max(cls[base + i], 2)
                elif p['reads'][i]:
                    cls[base + i] = max(cls[base + i], 1)
        for row in d['instructions']:
            z80, page = int(row[0][1:], 16), row[1]
            if page in BASES:
                for k in range(len(row[2]) // 2):
                    cls[(z80 + k) & 0xFFFF] = 3
    lo = int(a.lo, 16)
    runs = []
    for addr in range(lo, 0x10000):
        if runs and runs[-1][2] == cls[addr]:
            runs[-1][1] = addr
        else:
            runs.append([addr, addr, cls[addr]])
    merged = []
    for r in runs:
        if merged and (r[1] - r[0] + 1 < a.merge):
            merged[-1][1] = r[1]
            merged[-1][3] = True
        elif merged and merged[-1][2] == r[2]:
            merged[-1][1] = r[1]
        else:
            merged.append(r + [False])
    for s, e, c, mixed in merged:
        print(f'${s:04X}-${e:04X} {e - s + 1:6d}  {NAMES[c]}{" (with short runs of others)" if mixed else ""}')


if __name__ == '__main__':
    main()

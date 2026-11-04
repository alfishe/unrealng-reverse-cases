#!/usr/bin/env python3
"""The sector reads of an ane_sim.py log, joined into runs: the first disk sector, the count, where they went.

    python3 tools/sim_reads.py LOG
"""
import sys

FILES = [('A_NETHER.B', 16, 255), ('a_nether.E', 271, 182), ('nether.N', 453, 39), ('NETHER+.W', 492, 36)]


def where(lg):
    for name, first, n in FILES:
        if first <= lg < first + n:
            return '%s %d' % (name, lg - first)
    return 'track 0'


def main():
    runs = []
    for line in open(sys.argv[1]):
        r = line.split()
        if r[0] != 'read':
            continue
        lg = int(r[1]) * 16 + int(r[2])
        dest = int(r[4], 16) if len(r) > 4 else None
        bank = r[5] if len(r) > 5 else '?'
        frame = int(r[3]) // 71680
        if runs and lg == runs[-1][0] + runs[-1][1] and dest is not None and runs[-1][2] is not None \
                and dest == runs[-1][2] + 256 * runs[-1][1] and bank == runs[-1][3]:
            runs[-1][1] += 1
        else:
            runs.append([lg, 1, dest, bank, frame])
    for lg, n, dest, bank, frame in runs:
        print('frame %5d  disk %3d (%-14s) x%3d -> %s bank %s' % (frame, lg, where(lg), n,
                                                                  '%04X' % dest if dest is not None else '?', bank))


if __name__ == '__main__':
    main()

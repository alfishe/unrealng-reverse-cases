#!/usr/bin/env python3
"""The landscape generator NewLandscape `$6A8E` and the random generator Random `$5CC6`, reimplemented instruction
for instruction, so that a gene gives the same 96 x 96 map the game makes.

    python3 tools/landscape.py GENE                        # prints the map's md5 and the cell counts
    python3 tools/landscape.py GENE --compare MAP.bin       # compares with a 9216-byte map taken from a recording
    from landscape import Rng, generate; stages = generate(3)   # the map after each stage

The stages (NewLandscape): the map all water (0); 128 land discs (cell 2, radius 2-7, centre 16-79, a random shape
of DiscShapes); the coast (MakeCoast: a water cell whose eight-neighbour land mask is one of CoastPatterns' 66
becomes that pattern's coast cell); 32 tree discs (cell 6, radius 2-3) drawn only over land.
"""
import argparse
import hashlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TABLES = os.path.join(HERE, '..', 'build', 'res', 'tables')
SIDE = 96


class Rng:
    """Random $5CC6: seed = (254 (seed + 1) - 1) mod 65537, computed as the Z80 does; returns the new low byte"""

    def __init__(self, seed):
        self.seed = seed & 0xFFFF
        self.calls = 0

    def next(self):
        self.calls += 1
        de = self.seed
        hl = ((de & 0xFF) << 8) | 0xFD          # LD H,E; LD L,$FD
        a = de >> 8                             # LD A,D; OR A (carry clear)
        cy = 0
        for _ in range(2):                      # SBC HL,DE; SBC A,B (B = 0), twice
            r = hl - de - cy
            cy = 1 if r < 0 else 0
            hl = r & 0xFFFF
            r = a - cy
            cy = 1 if r < 0 else 0
            a = r & 0xFF
        r = hl - a - cy                         # LD E,A; LD D,B; SBC HL,DE
        cy = 1 if r < 0 else 0
        hl = r & 0xFFFF
        if cy:                                  # JR NC,RandomStore; INC HL
            hl = (hl + 1) & 0xFFFF
        self.seed = hl
        return hl & 0xFF                        # LD A,(RandomSeed)


def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v


def disc(m, cx, cy, radius, cell, over, s1, s2):
    """Disc $6C09: 49 steps of x -= (y >> s1) + 1, y += (x >> s2) + 1 in 8.8 from (0, radius); a run per step"""
    x, y = 0, radius << 8
    for _ in range(49):
        x = (x - ((s16(y) >> s1) + 1)) & 0xFFFF
        y = (y + ((s16(x) >> s2) + 1)) & 0xFFFF
        row = (cy + (y >> 8)) & 0xFF
        col = (cx + (x >> 8)) & 0xFF
        n = ((-(x >> 8)) * 2) & 0xFF            # LD A,(X high); NEG; ADD A,A
        if n == 0:
            n = 256
        for _ in range(n):
            if row < SIDE and col < SIDE:       # MapAddrChecked
                i = row * SIDE + col
                if over == 0 or m[i] == over:
                    m[i] = cell
            col = (col + 1) & 0xFF


def discs(m, rng, count, cell, over, rmask, shapes):
    for _ in range(count):
        r = rng.next() & rmask
        if r < 2:
            r = 2
        cx = (rng.next() & 0x3F) + 0x10
        cy = (rng.next() & 0x3F) + 0x10
        k = rng.next() & 3
        disc(m, cx, cy, r, cell, over, shapes[2 * k], shapes[2 * k + 1])


def is_land(m, r, c):
    return 0 <= r < SIDE and 0 <= c < SIDE and m[r * SIDE + c] == 2


def land_mask(m, r, c):
    d = 0
    for dr, dc in ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)):
        d = (d << 1) | is_land(m, r + dr, c + dc)
    return d


def make_coast(m, coast):
    masks, cells = coast[:66], coast[66:]
    for r in range(SIDE - 1, 0, -1):            # B = 96..1, C = 96..1: row and column 96 are off the map
        for c in range(SIDE - 1, 0, -1):
            if m[r * SIDE + c] != 0:
                continue
            d = land_mask(m, r, c)
            if d and d in masks:
                m[r * SIDE + c] = cells[masks.index(d)]


def generate(gene):
    shapes = open(os.path.join(TABLES, 'DiscShapes.bin'), 'rb').read()
    coast = open(os.path.join(TABLES, 'Coast.bin'), 'rb').read()
    rng = Rng(gene)
    m = bytearray(SIDE * SIDE)
    stages = [('water', bytes(m), 0)]
    discs(m, rng, 128, 2, 0, 7, shapes)
    stages.append(('land discs', bytes(m), rng.calls))
    make_coast(m, coast)
    stages.append(('coast', bytes(m), rng.calls))
    discs(m, rng, 32, 6, 2, 3, shapes)
    stages.append(('trees', bytes(m), rng.calls))
    return stages


def main():
    p = argparse.ArgumentParser()
    p.add_argument('gene', type=int)
    p.add_argument('--compare')
    a = p.parse_args()
    st = generate(a.gene)
    m = st[-1][1]
    print('gene %05d: md5 %s, %d random calls; water %d, land %d, trees %d, coast %d' % (
        a.gene, hashlib.md5(m).hexdigest(), st[-1][2], m.count(0), m.count(2), m.count(6),
        sum(m.count(k) for k in (1, 3, 4, 5))))
    if a.compare:
        ref = open(a.compare, 'rb').read()[:SIDE * SIDE]
        diff = [i for i in range(SIDE * SIDE) if ref[i] != m[i]]
        print('compare %s: %d cells differ' % (a.compare, len(diff)))
        for i in diff[:20]:
            print('  row %d col %d: game %02X, here %02X' % (i // SIDE, i % SIDE, ref[i], m[i]))
        sys.exit(1 if diff else 0)


if __name__ == '__main__':
    main()

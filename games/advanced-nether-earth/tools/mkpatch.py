#!/usr/bin/env python3
"""The first cut of src/game/ane-patches.asm: ANE's game block against NE's game, as ORG + DB patches.

    python3 tools/mkpatch.py --ne build/ne/game.bin --ane IMAGE --out FILE [--gap 4]

NE's game.bin ($5B00, games/nether-earth/tools/build.sh) and ANE's game image (the depacked game block, $6731-$D7D7,
docs/03-build-and-load.md 4) are compared byte for byte; every run of differing bytes (runs closer than --gap bytes
merged) becomes `ORG addr` with the NE entry it falls in (the nearest NE label at or below it, from
games/nether-earth/src/game/game.ann) and its bytes as DB. The reasons are written by hand over this first cut
(src/game/ane-patches.asm keeps them); this tool only proves which bytes the patches must cover.
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import game_text  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NE_ANN = os.path.join(ROOT, '..', 'nether-earth', 'src', 'game', 'game.ann')
NE_ORG = 0x5B00
LO, HI = 0x6731, 0xD7D8


def entries():
    out = []
    for line in open(NE_ANN, encoding='utf-8'):
        m = re.match(r'\$([0-9A-F]{4}) ([cbwts]) (\w+)(?: \d+)? ; (.*)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(3), m.group(2), m.group(4)))
    return sorted(out)


def owner(ents, a):
    best = None
    for e in ents:
        if e[0] <= a:
            best = e
        else:
            break
    return best


def runs(ne, ane, gap):
    out = []
    a = LO
    while a < HI:
        if ne[a - NE_ORG] == ane[a - LO]:
            a += 1
            continue
        s = a
        e = a + 1
        b = e
        while b < HI and b - e < gap:
            if ne[b - NE_ORG] != ane[b - LO]:
                e = b + 1
            b += 1
        out.append((s, e))
        a = e
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ne', required=True)
    p.add_argument('--ane', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--gap', type=int, default=4)
    a = p.parse_args()
    ne = open(a.ne, 'rb').read()
    ane = open(a.ane, 'rb').read()
    assert len(ane) == HI - LO, len(ane)
    ents = entries()
    lines = []
    total = 0
    rr = runs(ne, ane, a.gap)
    for s, e in rr:
        o = owner(ents, s)
        total += e - s
        lines.append('')
        lines.append('; %s+%X (%s): %d bytes' % (o[1], s - o[0], o[3], e - s))
        lines.append('    ORG $%04X' % s)
        data = ane[s - LO:e - LO]
        for i in range(0, len(data), 16):
            row = data[i:i + 16]
            text = game_text.decode(row)
            lines.append('    DB ' + ','.join('$%02X' % x for x in row) + ' ' * (3 + 4 * (16 - len(row))) + '; ' + text)
    with open(a.out, 'w') as f:
        f.write('\n'.join(lines).lstrip('\n') + '\n')
    print('%d runs, %d bytes' % (len(rr), total))


if __name__ == '__main__':
    main()

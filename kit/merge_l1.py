#!/usr/bin/env python3
"""Sum several L1 builds (l1.json) into one, for kit/heatmap.py over all of a case's recordings: the instructions'
runs and the per-byte reads and writes of pages 5, 2 and 0 (the 64 K view at $4000-$FFFF); the other banks' code and
data are left out (their addresses would land on bank 0's at $C000), the frames are the sum.

    python3 kit/merge_l1.py OUT.json L1 [L1 ...] [--stack LO-HI]

--stack LO-HI (hex, both included) also prints, per build, the lowest byte written in that range: the stack's low
mark when the range holds the stack and nothing else writes there (Switchblade's $5B00-$5BFF, reset to $5C00 each
pass of its main loop; Myth's $FF00-$FFFF under its turbo loader). Give play windows, not loads, for that figure: a
loader's writes in the range count too.
"""
import argparse
import json

BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def stack_range(text):
    lo, sep, hi = text.partition('-')
    if not sep:
        raise argparse.ArgumentTypeError(f'{text}: LO-HI, hex (FF00-FFFF)')
    lo, hi = int(lo.lstrip('$'), 16), int(hi.lstrip('$'), 16)
    if not 0x4000 <= lo <= hi <= 0xFFFF:
        raise argparse.ArgumentTypeError(f'{text}: a range inside $4000-$FFFF, LO <= HI')
    return lo, hi


def lowest_write(byte_counts, lo, hi):
    """the lowest address of lo..hi (in the 64 K view of pages 5, 2, 0) a build wrote, or None"""
    for a in range(lo, hi + 1):
        for p in byte_counts:
            base = BASES.get(p['page'])
            if base is not None and base <= a < base + 0x4000 and p['writes'][a - base]:
                return a
    return None


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('out', help='the merged l1.json')
    p.add_argument('l1', nargs='+', help='the L1 builds')
    p.add_argument('--stack', type=stack_range, metavar='LO-HI', help='print the lowest byte each build wrote there')
    args = p.parse_args()
    instr, pages, frames, first = {}, {}, 0, None
    for path in args.l1:
        d = json.load(open(path))
        first = first or d
        frames += d['replay']['frames']
        for row in d['instructions']:
            z80, page = row[0], row[1]
            if page not in BASES:
                continue
            key = (z80, page, row[2])
            if key in instr:
                instr[key][4] += row[4]
            else:
                instr[key] = list(row)
        for c in d['byte_counts']:
            if c['page'] not in BASES:
                continue
            acc = pages.setdefault(c['page'], {'page': c['page'], 'reads': [0] * 0x4000, 'writes': [0] * 0x4000,
                                               'last_frame': [0] * 0x4000})
            for i in range(0x4000):
                acc['reads'][i] += c['reads'][i]
                acc['writes'][i] += c['writes'][i]
                acc['last_frame'][i] = max(acc['last_frame'][i], c['last_frame'][i])
        line = f"{path} {d['replay']['frames']} frames"
        if args.stack:
            low = lowest_write(d['byte_counts'], *args.stack)
            line += '; lowest write in $%04X-$%04X: %s' % (args.stack + (f'${low:04X}' if low is not None else None,))
        print(line)
    doc = {'format': first.get('format'), 'version': first.get('version'),
           'replay': dict(first['replay'], frames=frames), 'instructions': list(instr.values()),
           'byte_counts': list(pages.values())}
    json.dump(doc, open(args.out, 'w'))


if __name__ == '__main__':
    main()

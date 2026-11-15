#!/usr/bin/env python3
"""Sum several L1 builds (l1.json) into one, for kit/heatmap.py over all of a case's recordings: the instructions'
runs and the per-byte reads and writes of pages 5, 2 and 0 (the 64 K view at $4000-$FFFF); the other banks' code and
data are left out (their addresses would land on bank 0's at $C000), the frames are the sum.

    python3 kit/merge_l1.py OUT.json L1 [L1 ...] [--stack LO-HI]

--stack LO-HI (hex, both included) also prints, per build, two marks in that range:

  lowest SP     the lowest byte a PUSH, CALL, RST or an interrupt wrote there (the L1's byte_use flag kStackWrite):
                the lowest SP the build reached, the stack's low mark, whatever else lies in the range (Rex: $5FE0
                over the object records at $5D00-$5FE5)
  lowest write  the lowest byte a data write wrote there (the L1's per-byte writes, which do not count the stack's
                own pushes): the low mark only where the stack is written as data too (LD SP,nn over a buffer read
                back with POP) and nothing else writes in the range (Switchblade's $5B00-$5BFF, Myth's $FF00-$FFFF)

The byte_use flags hold no frame: give play windows, not loads, for these figures (a loader's stack and writes in the
range count too).
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


STACK_WRITE = 1 << 3  # byte_use flags: PUSH, CALL, RST, an interrupt (unreal-ng l1model.h use::kStackWrite)


def lowest_stack_write(byte_use, lo, hi):
    """the lowest address of lo..hi (64 K view of pages 5, 2, 0) a PUSH / CALL / RST / interrupt wrote, or None"""
    low = None
    for row in byte_use:
        page, offset, length, flags = row[0], row[1], row[2], row[3]
        base = BASES.get(page)
        if base is None or not flags & STACK_WRITE:
            continue
        a, b = max(base + offset, lo), min(base + offset + length - 1, hi)
        if a <= b and (low is None or a < low):
            low = a
    return low


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('out', help='the merged l1.json')
    p.add_argument('l1', nargs='+', help='the L1 builds')
    p.add_argument('--stack', type=stack_range, metavar='LO-HI',
                   help='print the lowest SP (stack write) and the lowest data write of each build there')
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
            sp = lowest_stack_write(d.get('byte_use', []), *args.stack)
            low = lowest_write(d['byte_counts'], *args.stack)
            line += '; in $%04X-$%04X lowest SP: %s, lowest write: %s' % (
                args.stack + (f'${sp:04X}' if sp is not None else None, f'${low:04X}' if low is not None else None))
        print(line)
    doc = {'format': first.get('format'), 'version': first.get('version'),
           'replay': dict(first['replay'], frames=frames), 'instructions': list(instr.values()),
           'byte_counts': list(pages.values())}
    json.dump(doc, open(args.out, 'w'))


if __name__ == '__main__':
    main()

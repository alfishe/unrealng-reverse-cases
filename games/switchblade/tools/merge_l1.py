#!/usr/bin/env python3
"""Sum several L1 builds (l1.json) into one for kit/heatmap.py: the instructions' counts and the per-byte reads and
writes of pages 5, 2 and 0 (the 64 K view at `$4000-$FFFF`); bank 4's code and data are left out (its addresses
would land on bank 0's), the frames are the sum. Also prints the lowest byte written in `$5B00-$5BFF` (the stack's
low mark; `SP` is reset to `$5C00` on every pass of the main loop) per build that starts in the game.

    python3 tools/merge_l1.py OUT.json L1 [L1 ...]
"""
import json
import sys


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    instr, pages, frames, first = {}, {}, 0, None
    for path in paths:
        d = json.load(open(path))
        first = first or d
        frames += d['replay']['frames']
        for row in d['instructions']:
            z80, page = row[0], row[1]
            if page == 4 or page >= 256:
                continue
            key = (z80, page, row[2])
            if key in instr:
                instr[key][4] += row[4]
            else:
                instr[key] = list(row)
        low = None
        for p in d['byte_counts']:
            if p['page'] not in (5, 2, 0):
                continue
            acc = pages.setdefault(p['page'], {'page': p['page'], 'reads': [0] * 0x4000, 'writes': [0] * 0x4000,
                                               'last_frame': [0] * 0x4000})
            for i in range(0x4000):
                acc['reads'][i] += p['reads'][i]
                acc['writes'][i] += p['writes'][i]
                acc['last_frame'][i] = max(acc['last_frame'][i], p['last_frame'][i])
            if p['page'] == 5:
                w = [i for i in range(0x1B00, 0x1C00) if p['writes'][i]]
                low = f'${0x4000 + w[0]:04X}' if w else None
        print(path, d['replay']['frames'], 'frames; lowest write in $5B00-$5BFF:', low)
    doc = {'format': first.get('format'), 'version': first.get('version'),
           'replay': dict(first['replay'], frames=frames), 'instructions': list(instr.values()),
           'byte_counts': list(pages.values())}
    json.dump(doc, open(out, 'w'))


if __name__ == '__main__':
    main()

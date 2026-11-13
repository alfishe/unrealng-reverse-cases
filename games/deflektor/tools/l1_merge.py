#!/usr/bin/env python3
"""One L1 from several: the sum of the instruction counts (by address and bytes) and of the per-byte read and write
counts, the latest last-touched frame, and the frames added up, so kit/heatmap.py draws all recordings at once.

    python3 tools/l1_merge.py OUT.json W1/l1.json W2/l1.json ...
"""
import json
import sys


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    ins, pages, frames = {}, {}, 0
    for p in paths:
        d = json.load(open(p))
        frames += d['replay']['frames']
        for row in d['instructions']:
            z80, page, code, cls, count = row[:5]
            k = (z80, page, code)
            if k in ins:
                ins[k][4] += count
            else:
                ins[k] = [z80, page, code, cls, count]
        for pg in d.get('byte_counts', []):
            q = pages.setdefault(pg['page'], {'page': pg['page'], 'name': pg.get('name', ''), 'reads': [0] * 0x4000,
                                                'writes': [0] * 0x4000, 'last_frame': [0] * 0x4000})
            for i in range(0x4000):
                q['reads'][i] += pg['reads'][i]
                q['writes'][i] += pg['writes'][i]
                q['last_frame'][i] = max(q['last_frame'][i], pg['last_frame'][i])
    json.dump({'replay': {'frames': frames, 'sources': paths}, 'instructions': list(ins.values()),
               'byte_counts': list(pages.values())}, open(out, 'w'))
    print(f'{len(paths)} L1s, {frames} frames, {len(ins)} instructions')


if __name__ == '__main__':
    main()

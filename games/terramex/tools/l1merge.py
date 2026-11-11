#!/usr/bin/env python3
"""Several L1 builds (l1.json) as one, for the memory heatmap of every recording (`kit/heatmap.py` reads one file):
the instructions listed from every build (their counts add up in the heatmap), the byte counts of each page summed,
the last frame the latest, the replay's frames and instructions summed. Terramex runs on the 128K with RAM 0 at `$C000` in
play; the code of the other pages that runs at `$C000` (RAM 1: the music player; RAM 6: the explorer selector) is
left out of the instructions, so the 64 K view shows RAM 5, 2, 0 and the ROM only (their counts go to --paged).

    python3 tools/l1merge.py out.json work/game/l1.json work/stage1/b1/l1.json ...
"""
import json
import sys


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    merged = None
    pages = {}
    paged = {}
    for p in paths:
        doc = json.load(open(p))
        if merged is None:
            merged = {k: doc[k] for k in ('format', 'version')}
            merged['replay'] = dict(doc['replay'])
            merged['instructions'] = []
        else:
            for k in ('frames', 'instructions', 'tstates', 'interrupts'):
                merged['replay'][k] += doc['replay'][k]
        merged['instructions'] += [i for i in doc['instructions'] if i[1] in (0, 2, 5) or i[1] >= 256]
        for i in doc['instructions']:
            if i[1] not in (0, 2, 5) and i[1] < 256:
                paged[i[1]] = paged.get(i[1], 0) + i[4]
        for page in doc['byte_counts']:
            acc = pages.setdefault(page['page'], {'page': page['page'], 'reads': [0] * 0x4000,
                                                  'writes': [0] * 0x4000, 'last_frame': [0] * 0x4000})
            for i in range(0x4000):
                acc['reads'][i] += page['reads'][i]
                acc['writes'][i] += page['writes'][i]
                acc['last_frame'][i] = max(acc['last_frame'][i], page['last_frame'][i])
    merged['byte_counts'] = list(pages.values())
    merged['sources'] = paths
    merged['paged_executions'] = paged
    print('executions left out by page', paged)
    json.dump(merged, open(out, 'w'))
    print(out, len(paths), 'builds', merged['replay']['frames'], 'frames')


if __name__ == '__main__':
    main()

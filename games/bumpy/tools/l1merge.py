#!/usr/bin/env python3
"""Several L1 builds (l1.json) as one, for the memory heatmap of every recording (`kit/heatmap.py` reads one file):
the instructions listed from every build (their counts add up in the heatmap), the byte counts of each page summed,
the last frame the latest, the replay's frames, instructions, T-states and interrupts summed. Bumpy runs on the 48K:
RAM 5, 2, 0 and the ROM only.

    python3 tools/l1merge.py work/stage1/l1-all.json work/stage1/c1/l1.json work/stage1/rzx/l*/l1.json ...
"""
import json
import sys


def main():
    out, paths = sys.argv[1], sys.argv[2:]
    merged, pages = None, {}
    for p in paths:
        doc = json.load(open(p))
        if merged is None:
            merged = {k: doc[k] for k in ('format', 'version') if k in doc}
            merged['replay'] = dict(doc['replay'])
            merged['instructions'] = []
        else:
            for k in ('frames', 'instructions', 'tstates', 'interrupts'):
                merged['replay'][k] += doc['replay'][k]
        merged['instructions'] += doc['instructions']
        for page in doc['byte_counts']:
            acc = pages.setdefault(page['page'], {'page': page['page'], 'reads': [0] * 0x4000,
                                                  'writes': [0] * 0x4000, 'last_frame': [0] * 0x4000})
            for i in range(0x4000):
                acc['reads'][i] += page['reads'][i]
                acc['writes'][i] += page['writes'][i]
                acc['last_frame'][i] = max(acc['last_frame'][i], page['last_frame'][i])
    merged['byte_counts'] = list(pages.values())
    merged['sources'] = paths
    json.dump(merged, open(out, 'w'))
    print(out, len(paths), 'builds', merged['replay']['frames'], 'frames')


if __name__ == '__main__':
    main()

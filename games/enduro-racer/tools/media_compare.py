#!/usr/bin/env python3
"""Compare the data blocks of several Enduro Racer tapes, block by block.

    python3 tools/media_compare.py REF.tzx OTHER.tzx [OTHER2.tzx ...]

Each tape's data-carrying blocks (standard 0x10, turbo 0x11, pure data 0x14) of 4 bytes or more are listed in order;
for each block of the first tape the others are searched for a block with identical bytes. Short marker blocks
(SpeedLock 2's 3-byte `07` blocks, its 1-byte `E8` sync pieces) are skipped. Prints one line a block of REF: its
index, length, flag, and per other tape "=" (an identical block somewhere), or the closest block of the same length
with the count of differing bytes.
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def blocks(path):
    out = []
    for b in tzxblocks.parse(open(path, 'rb').read()):
        d = b.get('data')
        if d is not None and len(d) >= 4:
            out.append((b['index'], bytes(d)))
    return out


def main():
    paths = sys.argv[1:]
    ref, others = blocks(paths[0]), [blocks(p) for p in paths[1:]]
    for k, p in enumerate(paths):
        print(f'tape {k}: {os.path.basename(p)} md5 {hashlib.md5(open(p, "rb").read()).hexdigest()}')
    for idx, data in ref:
        cells = []
        for o in others:
            hit = [i for i, d in o if d == data]
            if hit:
                cells.append(f'= #{hit[0]}')
                continue
            same = [(sum(x != y for x, y in zip(d, data)), i) for i, d in o if len(d) == len(data)]
            cells.append(f'~#{min(same)[1]} {min(same)[0]} bytes differ' if same else 'none')
        print(f'#{idx:3d} len {len(data):5d} flag {data[0]:02X}: ' + ' | '.join(cells))


if __name__ == '__main__':
    main()

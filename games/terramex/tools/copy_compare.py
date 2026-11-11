#!/usr/bin/env python3
"""How much of the original's game blocks each copy holds, whatever its format (tape, disk, snapshot, Microdrive):
the original's TZX blocks 2-5 (BASIC, screen, `$6000` block, `$7200` block) cut into 256-byte pieces, and for each
copy the share of pieces found anywhere in its bytes (a zip is read member by member), plus the longest run of
consecutive pieces found in order. A packed or relocated copy shows few pieces.

    python3 tools/copy_compare.py work/candidates/*/* > work/stage1/copy-compare.tsv
"""
import io
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402
from lab import tape_file  # noqa: E402

NAMES = ['BASIC', 'screen', '$6000 block', '$7200 block']


def blocks():
    data = open(tape_file(), 'rb').read()
    out = [b for b in tzxblocks.parse(data) if b.get('data')]
    return [b['data'][1:-1] for b in out[1:5]]


def members(path):
    if path.lower().endswith('.zip'):
        z = zipfile.ZipFile(path)
        for n in z.namelist():
            if not n.endswith('/'):
                yield f'{path}!{n}', z.read(n)
    else:
        yield path, open(path, 'rb').read()


def score(block, data):
    pieces = [block[i:i + 256] for i in range(0, len(block) - 255, 256)]
    hits = [p in data for p in pieces]
    best = run = 0
    for h in hits:
        run = run + 1 if h else 0
        best = max(best, run)
    return sum(hits), len(pieces), best * 256


def main():
    bl = blocks()
    print('copy\tbytes\t' + '\t'.join(f'{n} pieces\t{n} longest run' for n in NAMES))
    for path in sys.argv[1:]:
        if os.path.isdir(path):
            continue
        for name, data in members(path):
            cols = []
            for b in bl:
                found, total, run = score(b, data)
                cols += [f'{found}/{total}', str(run)]
            print(f'{name}\t{len(data)}\t' + '\t'.join(cols))


if __name__ == '__main__':
    main()

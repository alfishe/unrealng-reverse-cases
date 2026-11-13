#!/usr/bin/env python3
"""How much of the original's game each copy holds, whatever its format (tape, disk, snapshot, Microdrive): three
reference areas cut into 256-byte pieces, and for each copy the share of pieces found anywhere in its bytes (a zip is
read member by member), plus the longest run of consecutive pieces found in order. A packed or relocated copy shows
few pieces.

The references come from the `c1` recording (memory read with `time_travel memory_at`, `tools/ttd_dump.py`):
`as loaded` = `$5C00-$9DEF` and `$C000-$FFFF` at frame 15635 t 27704 (the loader's last jump), `game` = `$6000-$DFFF`
at frame 15752 t 33930 (the jump to `$8382`, after the unpack). The original's TZX block 3 is in the loader's own
pulse code, so its bytes are not the game's bytes and cannot be compared directly.

    python3 tools/copy_compare.py work/candidates/*/* > work/stage1/copy-compare.tsv
"""
import io
import os
import sys
import zipfile

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(CASE, 'work', 'stage1', 'images')


def refs():
    ld = open(os.path.join(IMG, 'loaded.cpu.bin'), 'rb').read()
    en = open(os.path.join(IMG, 'entry.cpu.bin'), 'rb').read()
    return [('loaded $5C00-$9DEF', ld[0x5C00:0x9DF0]), ('loaded $C000-$FFFF', ld[0xC000:0x10000]),
            ('game $6000-$DFFF', en[0x6000:0xE000])]


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
    rs = refs()
    print('copy\tbytes\t' + '\t'.join(f'{n} pieces\t{n} longest run' for n, _ in rs))
    for path in sys.argv[1:]:
        if os.path.isdir(path):
            continue
        for name, data in members(path):
            cols = []
            for _, b in rs:
                found, total, run = score(b, data)
                cols += [f'{found}/{total}', str(run)]
            print(f'{os.path.relpath(name, os.path.join(CASE, "work", "candidates"))}\t{len(data)}\t' + '\t'.join(cols))


if __name__ == '__main__':
    main()

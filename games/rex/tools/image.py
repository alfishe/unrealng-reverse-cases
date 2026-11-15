#!/usr/bin/env python3
"""The 64 K image of one part of Rex as the ROM loader leaves it, cut from the original tape (orig/Rex.tzx.zip):
the loading screen at $4000 and the code block at its header's start, zero elsewhere.

    python3 tools/image.py OUT.bin [--part 1|2|demo]

Part 1: side 1 blocks 4 and 6 (REX 1, code $6018-$FFF9, entry $947A); part 2: side 1 blocks 10 and 12 (REX 2, code
$61A8-$FFF9, entry $9470); demo: side 2 blocks 4 and 6 (code $61A8-$FFF9, entry $8A84).
"""
import argparse
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

PARTS = {'1': ('Rex - Side 1.tzx', 4, 5, 6), '2': ('Rex - Side 1.tzx', 10, 11, 12), 'demo': ('Rex - Side 2.tzx', 4, 5, 6)}


def image(part):
    name, scr, hdr, code = PARTS[part]
    with zipfile.ZipFile(os.path.join(HERE, '..', 'orig', 'Rex.tzx.zip')) as z:
        blocks = list(tzxblocks.parse(z.read(name)))
    mem = bytearray(65536)
    mem[0x4000:0x5B00] = blocks[scr]['data'][1:-1]
    h = blocks[hdr]['data']
    start = h[14] | h[15] << 8
    data = blocks[code]['data'][1:-1]
    mem[start:start + len(data)] = data
    return bytes(mem), start, len(data)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--part', default='1', choices=sorted(PARTS))
    a = ap.parse_args()
    mem, start, n = image(a.part)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    open(a.out, 'wb').write(mem)
    print(f'{a.out}: part {a.part}, code ${start:04X}-${start + n - 1:04X} ({n} bytes)')


if __name__ == '__main__':
    main()

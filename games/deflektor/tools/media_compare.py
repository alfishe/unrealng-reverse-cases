#!/usr/bin/env python3
"""Compare the data blocks of the Deflektor tapes (TZX standard blocks, TAP blocks) block by block.

    python3 tools/media_compare.py work/media/*/*.tzx work/media/*/*.TAP > work/stage1/media-compare.txt

For each tape: each data block's length, flag and SHA-1 (first 12), and against the first tape given the number of
bytes that differ and the first differing offset.
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def blocks(path):
    t = open(path, 'rb').read()
    if t[:8] == b'ZXTape!\x1a':
        return [b['data'] for b in tzxblocks.parse(t) if b.get('data')]
    out, i = [], 0
    while i + 2 <= len(t):
        n = t[i] | t[i + 1] << 8
        out.append(t[i + 2:i + 2 + n])
        i += 2 + n
    return out


def main():
    paths = sys.argv[1:]
    ref = blocks(paths[0])
    for p in paths:
        print(f'== {p}')
        for k, d in enumerate(blocks(p)):
            line = f'  {k}: len {len(d):6d} flag {d[0]:02X} sha1 {hashlib.sha1(d).hexdigest()[:12]}'
            if k < len(ref):
                r = ref[k]
                diff = [j for j in range(min(len(d), len(r))) if d[j] != r[j]]
                line += f' | vs ref: {len(diff)} bytes differ' + (f', first at {diff[0]}' if diff else '')
                if len(d) != len(r):
                    line += f', length {len(r)} in ref'
            print(line)


if __name__ == '__main__':
    main()

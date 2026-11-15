#!/usr/bin/env python3
"""Compare the data blocks of the R-Type tapes (TZX standard blocks, TAP blocks) block by block.

    python3 tools/media_compare.py [--min N] TAPE ... > work/stage1/media-compare.txt

--min N leaves out data blocks of N bytes or fewer (R-Type: the SpeedLock tapes transcribed as Speedlock 7 keep the
loader's 1- and 3-byte marker blocks as data, the Speedlock 4 transcription as pulses).

For each tape: each data block's length, flag and SHA-1 (first 12), and against the first tape given the number of
bytes that differ and the first differing offset, the first tape's block it equals, and a summary line.
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


MIN = 0


def blocks(path):
    t = open(path, 'rb').read()
    if t[:8] == b'ZXTape!\x1a':
        return [b['data'] for b in tzxblocks.parse(t) if b.get('data') and len(b['data']) > MIN]
    out, i = [], 0
    while i + 2 <= len(t):
        n = t[i] | t[i + 1] << 8
        if n > MIN:
            out.append(t[i + 2:i + 2 + n])
        i += 2 + n
    return out


def main():
    global MIN
    paths = sys.argv[1:]
    if paths[:1] == ['--min']:
        MIN, paths = int(paths[1]), paths[2:]
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
            if any(d == r for r in ref):
                line += f' | = ref block {ref.index(d)}'
            print(line)
        same = sum(1 for d in blocks(p) if d in ref)
        print(f'  summary: {same} of {len(blocks(p))} blocks are in the first tape, byte for byte')


if __name__ == '__main__':
    main()

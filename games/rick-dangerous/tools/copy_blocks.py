#!/usr/bin/env python3
"""Compare copies of Rick Dangerous with the reference tape, block by block and piece by piece.

    python3 tools/copy_blocks.py REF.tzx COPY ... > work/stage1/copy-blocks.txt

For each copy (TZX, TAP, or any other file):
- a tape: its data blocks, how many of them are byte for byte a data block of the reference (by SHA-1, in any order),
  and the list of those that are not, with their lengths;
- any file: the share of the reference's Bleepload payload (the data blocks after the `Rick1` block, cut into
  64-byte pieces) found anywhere in the file's bytes.
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def tape_blocks(t):
    if t[:8] == b'ZXTape!\x1a':
        return [b['data'] for b in tzxblocks.parse(t) if b.get('data')]
    out, i = [], 0
    while i + 2 <= len(t):
        n = t[i] | t[i + 1] << 8
        if n == 0 or i + 2 + n > len(t):
            return None
        out.append(t[i + 2:i + 2 + n])
        i += 2 + n
    return out


def is_tape(path, t):
    return t[:8] == b'ZXTape!\x1a' or path.lower().endswith('.tap')


def main():
    ref = tape_blocks(open(sys.argv[1], 'rb').read())
    ref_sha = {hashlib.sha1(d).hexdigest(): k for k, d in enumerate(ref)}
    payload = b''.join(d[1:-1] for d in ref[4:])
    pieces = [payload[i:i + 64] for i in range(0, len(payload) - 63, 64)]
    print(f'reference {sys.argv[1]}: {len(ref)} data blocks, Bleepload payload {len(payload)} bytes, '
          f'{len(pieces)} pieces of 64')
    for p in sys.argv[2:]:
        t = open(p, 'rb').read()
        print(f'== {p} ({len(t)} bytes, md5 {hashlib.md5(t).hexdigest()})')
        if is_tape(p, t):
            bl = tape_blocks(t) or []
            same = [ref_sha.get(hashlib.sha1(d).hexdigest()) for d in bl]
            n_same = sum(1 for s in same if s is not None)
            print(f'  tape: {len(bl)} data blocks, {n_same} equal to a reference block')
            odd = [(k, len(d)) for k, (d, s) in enumerate(zip(bl, same)) if s is None]
            if odd:
                print('  not in the reference: ' + ', '.join(f'#{k} ({n} bytes)' for k, n in odd[:12])
                      + (' ...' if len(odd) > 12 else ''))
            seq = [s for s in same if s is not None]
            if seq and seq != sorted(seq):
                print('  the equal blocks are not in the reference order')
        found = sum(1 for pc in pieces if pc in t)
        print(f'  pieces of the reference payload found: {found} of {len(pieces)}')


if __name__ == '__main__':
    main()

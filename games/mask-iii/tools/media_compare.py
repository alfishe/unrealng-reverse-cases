#!/usr/bin/env python3
"""Compare the data blocks of several tapes (TAP, TZX, or either inside a zip) with a reference tape.

    python3 tools/media_compare.py REF FILE ...        # REF and FILE: a .tap / .tzx path, or ZIP!MEMBER

For every block of every file: its length, md5, and where it sits in the reference: "= ref block N" when the
bytes are the same, else the share of the reference's 256-byte pieces (of the block of the same length, or of
any block) found in it. Flag and checksum bytes are left out (the data only). Any other file (SCL, TRD, DSK, MDR, $B) is one block.
"""
import hashlib
import io
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import tzxblocks  # noqa: E402
import tapblocks  # noqa: E402


def read(spec):
    if '!' in spec:
        z, m = spec.split('!', 1)
        return zipfile.ZipFile(z).read(m), m
    return open(spec, 'rb').read(), spec


def data_blocks(spec):
    raw, name = read(spec)
    if raw[:8] == b'ZXTape!\x1a':
        out = [b['data'] for b in tzxblocks.parse(raw) if b.get('data')]
    elif name.lower().endswith('.tap'):
        return [bytes(d) for _o, _f, d, _ok in tapblocks.raw_blocks(raw)]
    else:
        return [raw]  # a disk, a cartridge, a TR-DOS file: searched whole
    return [d[1:-1] for d in out]


def pieces(data, size=256):
    return {data[i:i + size] for i in range(0, len(data) - size + 1, size)}


def main():
    ref = data_blocks(sys.argv[1])
    print(f'reference {sys.argv[1]}')
    for i, d in enumerate(ref):
        print(f'  ref {i}: {len(d):6d} bytes md5 {hashlib.md5(d).hexdigest()}')
    for spec in sys.argv[2:]:
        print(f'{spec}')
        for i, d in enumerate(data_blocks(spec)):
            same = [k for k, r in enumerate(ref) if r == d]
            if same:
                where = f'= ref block {same[0]}'
            else:
                best = ''
                for k, r in enumerate(ref):
                    rp = [r[j:j + 256] for j in range(0, len(r) - 255, 256)]
                    if not rp:
                        continue
                    hit = sum(1 for p in rp if p in d)
                    if hit:
                        diff = ''
                        if len(r) == len(d):
                            n = sum(1 for a, b in zip(r, d) if a != b)
                            first = next(j for j in range(len(d)) if r[j] != d[j])
                            diff = f', {n} bytes differ from offset {first}'
                        best += f' ref {k}: {hit}/{len(rp)} pieces{diff};'
                where = best or 'no piece of the reference'
            print(f'  {i}: {len(d):6d} bytes md5 {hashlib.md5(d).hexdigest()}  {where}')


if __name__ == '__main__':
    main()

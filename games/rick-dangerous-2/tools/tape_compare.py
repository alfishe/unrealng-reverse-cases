#!/usr/bin/env python3
"""Compare the blocks of every tape copy (TAP or TZX) of Rick Dangerous 2 with a reference.

Each copy's data blocks are listed with their flag, length, md5 of the payload (flag and checksum stripped) and
the name of the reference block with the same payload ("=A2" is the reference's block 2), or, for a block of the
same length, the count of differing bytes and the first differing offset. A header block is shown by its fields.

    python3 tools/tape_compare.py REF.tzx [REF2.tzx ...] -- COPY ... > work/stage1/tape-compare.txt
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tzxblocks  # noqa: E402


def tap_blocks(data):
    i, out = 0, []
    while i + 2 <= len(data):
        n = data[i] | data[i + 1] << 8
        out.append(data[i + 2:i + 2 + n])
        i += 2 + n
    return out


def blocks(path):
    data = open(path, 'rb').read()
    if path.lower().endswith('.tzx'):
        return [b['data'] for b in tzxblocks.parse(data) if b.get('data')]
    return tap_blocks(data)


def desc(raw):
    flag, body = raw[0], raw[1:-1]
    if flag == 0 and len(body) == 17:
        kind = {0: 'Program', 3: 'Bytes'}.get(body[0], str(body[0]))
        name = body[1:11].decode('latin-1')
        ln, p1, p2 = (body[11] | body[12] << 8, body[13] | body[14] << 8, body[15] | body[16] << 8)
        return f'header {kind} "{name}" len {ln} p1 {p1} p2 {p2}'
    return None


def main():
    args = sys.argv[1:]
    k = args.index('--')
    refs, copies = args[:k], args[k + 1:]
    ref = []
    for ri, r in enumerate(refs):
        for bi, raw in enumerate(blocks(r)):
            ref.append((f'{chr(65 + ri)}{bi}', raw[1:-1]))
    for ri, r in enumerate(refs):
        print(f'# reference {chr(65 + ri)}: {r}')
    for c in copies:
        print(f'== {c}')
        for bi, raw in enumerate(blocks(c)):
            body = raw[1:-1]
            d = desc(raw)
            md5 = hashlib.md5(body).hexdigest()[:10]
            same = [n for n, b in ref if b == body]
            note = ('=' + ','.join(same)) if same else ''
            if not same:
                for n, b in ref:
                    if len(b) == len(body):
                        diff = [i for i in range(len(b)) if b[i] != body[i]]
                        note += f' vs {n}: {len(diff)} bytes differ, first at +{diff[0]}' if diff else ''
                if not note:
                    sub = [n for n, b in ref if len(body) > 64 and body in b]
                    note = (' inside ' + ','.join(sub)) if sub else ' new'
            print(f'  {bi:2} flag {raw[0]:02X} {len(body):6} {md5} {d or ""} {note}')


if __name__ == '__main__':
    main()

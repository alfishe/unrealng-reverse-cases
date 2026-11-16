#!/usr/bin/env python3
"""Compare the data blocks of tapes (TAP / TZX) with a reference tape, by their bytes.

    python3 tools/media_compare.py REF.tzx OTHER.tap ...

Every block is printed with its flag, its length (flag and checksum dropped) and the first 12 hex of its SHA-1;
for the other tapes, "= ref #n" when a reference block has the same flag and bytes, or how many bytes differ from
the reference block of the same flag and length, or "not in ref".
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import tapblocks  # noqa: E402


def flagged(path):
    """(flag, body) of every block that has data: TAP blocks, TZX data blocks"""
    raw = open(path, 'rb').read()
    if tapblocks.is_tzx(raw):
        return [(b['data'][0], bytes(b['data'][1:-1])) for b in tapblocks.parse_tzx(raw)
                if b.get('data') and len(b['data']) >= 2]
    return [(flag, bytes(data)) for _o, flag, data, _ok in tapblocks.raw_blocks(raw)]


def main():
    paths = sys.argv[1:]
    ref = flagged(paths[0])
    for p in paths:
        print('==', os.path.basename(p))
        for i, (flag, body) in enumerate(flagged(p)):
            note = ''
            if p != paths[0]:
                same = [j for j, (f2, b2) in enumerate(ref) if f2 == flag and b2 == body]
                cand = [(j, b2) for j, (f2, b2) in enumerate(ref) if f2 == flag and len(b2) == len(body)]
                if same:
                    note = '= ref #%d' % same[0]
                elif cand:
                    j, b2 = cand[0]
                    diff = [k for k in range(len(body)) if body[k] != b2[k]]
                    note = 'ref #%d: %d bytes differ, the first at +%d' % (j, len(diff), diff[0])
                else:
                    note = 'not in ref'
            print('  %2d flag %02X len %6d sha1 %s %s' % (i, flag, len(body), hashlib.sha1(body).hexdigest()[:12], note))


if __name__ == '__main__':
    main()

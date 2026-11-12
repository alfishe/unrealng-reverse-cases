#!/usr/bin/env python3
"""The LZ packers of zyxremix and zyxtvmbt, and of zyxermbt's loading picture: the formats their depackers read, and
encoders that make the same choices as the packers the variants were made with, byte for byte.

    python3 tools/lzpack.py [--format intro] unpack IN OUT   # a packed stream (from its first token) -> the bytes
    python3 tools/lzpack.py [--format intro] pack IN OUT     # bytes -> the packed stream, the end token included
    python3 tools/lzpack.py [--format intro] check IN        # unpack, pack again, compare

The format (the depacker: variants/zyxremix/parts/depack.ann). A token's first byte:

- `0lllhhhh`, then `oooooooo`: a match: copy `lll` + 3 bytes (3-10) from `hhhhoooooooo` bytes back (1-4095);
- `10nnnnnn` (n 1-63), then n bytes: a literal run;
- `11nnnnnn`, then a byte: the byte `nnnnnn` + 3 times (3-66);
- `$80`: the end.

The encoder's rules, found by packing both variants' data again until every token agreed:

- greedy, one position at a time: no look-ahead;
- a match never overlaps the bytes it writes (its length is at most its distance), 10 bytes at most, distance at
  most 4094;
- of the longest matches, the farthest (the search runs from the far end of the window and keeps a match only when
  it is strictly longer);
- a fill when the run of one byte is longer than the longest match and at least 3 (an equal match wins);
- the bytes no match or fill takes collect into literal runs of at most 63.

`--format intro`, zyxermbt's loading picture (variants/zyxermbt/parts/intro.ann; tools/res_screens.py packs it from
its PNG): the same tokens, but a match is `0llllhhh`, `oooooooo`: `llll` + 3 bytes (3-18) from `hhhoooooooo` bytes
back (1-2047). The bytes are the screen in the order the depacker writes it (a cell's 8 pixel rows, the cells down
each column of a third, then the attributes). Its packer's rules, found the same way:

- greedy, no overlap, of the longest matches the farthest, as above (18 bytes at most, distance at most 2047);
- a match may start only where a literal or a match's byte went, or where a fill starts (the packer recorded no
  other position of a fill);
- a fill when its run is at least as long as the longest match (an equal fill wins).

These rules make 196 of the stream's 204 tokens; INTRO_HINTS holds the 8 they do not explain (5 matches and 3 fills,
16 of the 547 bytes: the original packer's choices at those output positions; without them the stream is 546 bytes). A hint is taken only when it still describes the bytes there, so an
edited picture packs to a valid stream all the same.
"""
import argparse
import bisect
import sys
from collections import defaultdict

MAX_FILL = 66
MAX_LITERAL = 63
# format -> (length bits, longest match, window, a fill wins an equal match, matches start from every earlier byte)
FORMATS = {'remix': (3, 10, 4094, False, True), 'intro': (4, 18, 2047, True, False)}
# the intro packer's choices the rules do not explain: output position -> token ('m', length, distance) or ('f', count)
INTRO_HINTS = {3227: ('m', 5, 63), 3278: ('f', 5), 3465: ('m', 5, 194), 6483: ('m', 4, 9), 6552: ('m', 8, 152),
               6850: ('f', 14), 6882: ('f', 14), 6896: ('m', 16, 128)}


def unpack(src, i=0, fmt='remix'):
    """(the bytes, the index after the end token) of the stream src from index i"""
    bits = FORMATS[fmt][0]
    out = bytearray()
    while True:
        b = src[i]
        if b < 0x80:
            n, off = (b >> (7 - bits)) + 3, (b & ((1 << (7 - bits)) - 1)) << 8 | src[i + 1]
            for _ in range(n):
                out.append(out[len(out) - off])
            i += 2
        elif b == 0x80:
            return bytes(out), i + 1
        elif b & 0x40:
            out += bytes([src[i + 1]]) * ((b & 0x3F) + 3)
            i += 2
        else:
            n = b & 0x3F
            out += src[i + 1:i + 1 + n]
            i += 1 + n


def hint(d, p, h):
    """the hinted token at p, when it still describes the bytes there"""
    if h and h[0] == 'm' and h[1] <= h[2] <= p and d[p - h[2]:p - h[2] + h[1]] == d[p:p + h[1]]:
        return ('m', h[1], h[2])
    if h and h[0] == 'f' and d[p:p + h[1]] == bytes([d[p]]) * h[1]:
        return ('f', h[1], d[p])
    return None


def tokens(d, fmt='remix', hints=None):
    """the encoder's tokens for d: ('m', length, distance), ('f', count, byte), ('l', count)"""
    _bits, max_match, window, fill_ties, every = FORMATS[fmt]
    where = defaultdict(list)
    for k in range(len(d) - 2):
        where[d[k:k + 3]].append(k)
    sources = set()     # the positions a match may start from (all, unless the format says otherwise)
    p, out = 0, []
    while p < len(d):
        length, dist = 0, 0
        cands = where.get(d[p:p + 3], [])
        for q in cands[bisect.bisect_left(cands, p - window):bisect.bisect_left(cands, p)]:   # far to near
            if not every and q not in sources:
                continue
            off, n = p - q, 0
            while n < max_match and p + n < len(d) and n < off and d[q + n] == d[p + n]:
                n += 1
            if n > length:
                length, dist = n, off
        run = 1
        while p + run < len(d) and run < MAX_FILL and d[p + run] == d[p]:
            run += 1
        t = hint(d, p, (hints or {}).get(p))
        if t is None and run >= 3 and (run > length or (fill_ties and run == length)):
            t = ('f', run, d[p])
        elif t is None and length >= 3:
            t = ('m', length, dist)
        if t:
            out.append(t)
            sources.update([p] if t[0] == 'f' else range(p, p + t[1]))
            p += t[1]
        else:
            sources.add(p)
            if out and out[-1][0] == 'l' and out[-1][1] < MAX_LITERAL:
                out[-1] = ('l', out[-1][1] + 1)
            else:
                out.append(('l', 1))
            p += 1
    return out


def pack(d, fmt='remix'):
    """the packed stream of d, the end token included"""
    d = bytes(d)
    bits = FORMATS[fmt][0]
    out, p = bytearray(), 0
    for t in tokens(d, fmt, INTRO_HINTS if fmt == 'intro' else None):
        if t[0] == 'm':
            out += bytes([(t[1] - 3) << (7 - bits) | t[2] >> 8, t[2] & 255])
        elif t[0] == 'f':
            out += bytes([0xC0 | (t[1] - 3), t[2]])
        else:
            out += bytes([0x80 | t[1]]) + d[p:p + t[1]]
        p += t[1]
    return bytes(out) + b'\x80'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--format', choices=sorted(FORMATS), default='remix')
    ap.add_argument('command', choices=['pack', 'unpack', 'check'])
    ap.add_argument('files', nargs='+')
    a = ap.parse_args()
    data = open(a.files[0], 'rb').read()
    if a.command == 'unpack':
        open(a.files[1], 'wb').write(unpack(data, 0, a.format)[0])
    elif a.command == 'pack':
        open(a.files[1], 'wb').write(pack(data, a.format))
    else:
        out, end = unpack(data, 0, a.format)
        same = pack(out, a.format) == data[:end]
        print('lzpack: %d bytes -> %d, packed again %s' % (end, len(out), 'identical' if same else 'DIFFERENT'))
        return 0 if same else 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

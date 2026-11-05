#!/usr/bin/env python3
"""The backward LZ packer of the NEZSEd99.B blocks, reimplemented (the depacker: tools/zsdepack.py).

Reproduces the five original streams (stage2, stage3, game, patches, menu) bit for bit: a greedy rule plus a few
recorded decisions (hints) where the original did something the rule does not explain.

    zspack.py pack IN.bin OUT.bin --far-bits N [--hints FILE]
    zspack.py hints IN.bin BLOCK.bin --far-bits N --out FILE
    zspack.py check [--media work/media/99] [--hints-dir src/sfx/hints]

`pack` writes the stream as it sits at the block's AT.. (length = the file size). `hints` derives the hints of an
original block (BLOCK.bin as read from disk: set-up, depacker, the stream at +$B0, its length the word at +$13) for
the unpacked IN.bin. `check` packs every block of work/media/99 (zs_media.py) with src/sfx/hints/NAME.lzhints,
compares with the original stream byte for byte, unpacks the result in the block's real layout (stream at AT,
output at out..end, the in-place overlap of the game included) and exits non-zero on any difference.

The stream
----------
The data D (out..end) is written by the depacker from the top down: the first token makes the byte at `end`, the
last one the byte at `out`. Below, "position" p counts from the top: p = end - address, so the depacker writes
position 0, 1, 2, ... and "earlier" bytes are at higher addresses. A match of offset k at position p copies
positions p-k, p-k+1, ... (LDDR from DE + k), so k < length is a run.

The stream S (S[0] at AT, S[-1] at AT + length - 1) is read from S[-1] down to S[1], bits from bit 7 of each byte.
The packer writes the bits in the same order: the first bit of the first token is bit 7 of S[-1]. After the last
token the byte S[1] is filled with 0 bits (always 0 in the originals) and one more byte S[0] follows that the
depacker never reads (the output's last write lands on it in the game's in-place layout). Its value is not data:
$00 in stage2, patches and menu, $2A in stage3, $71 in the game (left-overs of the packer's buffer); the hints keep it.

Tokens:  0 + 8 bits                  a literal byte
         1 1 b                       match length 2 + b (2..3)
         1 0 1 bb                    match length 4 + bb (4..7)
         1 0 0 1 bbbb                bbbb < 15: match length 8 + bbbb (8..22)
         1 0 0 1 1111 bbbbb + bytes  a literal run of 14 + bbbbb bytes (14..45)
         1 0 0 0 (8 bits)*           match length 23 + the bytes; a byte $FF adds the next one (no length limit)
offset (after a match length):
         0 1 + 5 bits                1 + bits (1..$20)
         0 0 + 9 bits                $21 + bits ($21..$220)
         1 + far bits                $221 + bits (far bits 11: up to $A20, 10: up to $620)
Every length and offset has exactly one code (the classes do not overlap).

The rule (greedy, one decision per token start p; N = data length, W = $220 + 2^far_bits):
 1. match: the longest m among offsets k = 1..min(p, W) where m = the common length of positions p.. and p-k..,
    capped at k (no self-overlap) and at N - p; among equal lengths the nearest offset. Taken if m >= 2.
 2. else a run: if the byte repeats r >= 8 times after p (offset 1), a match of min(r, 22) at offset 1
    (the only overlapping matches the originals hold; never longer than the 1001 class, never preferred to rule 1).
 3. else a literal.
 Literals: a stretch of L consecutive literals between matches is written as runs of 45 while L >= 14 remains
 (the last run takes L if 14 <= L <= 45), the rest (L < 14) as single literals after the runs.
 The originals: 16939 of 16940 decisions follow the rule (a decision = a match or one literal; stage2 2907,
 stage3 1041, game 11867, menu 1596 all, patches 528 of 529). The one miss is the patches' last match (2 bytes
 before the end: offset $64 where $15 is nearer): the original's compare runs one byte past the data's end (the
 byte below `out` in its memory, $80 explains it) and clips the length after; the hint keeps it.
 Not decided by the originals: a literal stretch of 46..59 (taken here as 45 + singles), whether a stream whose
 last bits fill a byte exactly gets an extra 0 byte (here not).

Hints (src/sfx/hints/NAME.lzhints), text, `#` comments, one line a decision:
    POS KIND LEN OFF  RULE_KIND RULE_LEN RULE_OFF
POS the position (decimal), KIND `L` (literal, LEN 1, OFF 0) or `M` (match LEN at OFF); RULE_* the decision the
rule makes there on the original data. A hint is taken only where the rule makes exactly that decision and the
hinted match is valid for the data being packed (offset in the window, the bytes equal, inside the data), so an
edited input falls back to the rule and the packer stays a real packer. One more line `pad XX` (hex) gives S[0].
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import zsdepack  # noqa: E402

MEDIA = os.path.join(ROOT, 'work', 'media', '99')
HINTS = os.path.join(ROOT, 'src', 'sfx', 'hints')
NAMES = ['stage2', 'stage3', 'game', 'patches', 'menu']
RUN_MIN, RUN_MAX = 8, 22          # rule 2
LIT_RUN_MIN, LIT_RUN_MAX = 14, 45


def window(far_bits):
    return 0x220 + (1 << far_bits)


# ---------------------------------------------------------------- the parse

class Parser:
    """The rule over D (bytes in depack order: position 0 = the top byte)"""

    def __init__(self, d, far_bits):
        self.d, self.n, self.w = d, len(d), window(far_bits)
        self.chains = {}           # 2-byte key -> positions (ascending), filled up to the current position
        self.filled = 0

    def common(self, p, q, cap):
        d = self.d
        m = 0
        while m < cap and d[p + m] == d[q + m]:
            m += 1
        return m

    def advance(self, p):
        d, ch = self.d, self.chains
        for q in range(self.filled, min(p, self.n - 1)):
            ch.setdefault(d[q:q + 2], []).append(q)
        self.filled = max(self.filled, min(p, self.n - 1))

    def rule(self, p):
        """(kind, length, offset) of the rule at P"""
        self.advance(p)
        d, n = self.d, self.n
        best, bo = 0, 0
        if p + 1 < n:
            lst = self.chains.get(d[p:p + 2], ())
            for i in range(len(lst) - 1, -1, -1):          # nearest first
                k = p - lst[i]
                if k > self.w:
                    break
                cap = min(k, n - p)
                if cap <= best:
                    continue
                m = self.common(p, p - k, cap)
                if m > best:
                    best, bo = m, k
        if best >= 2:
            return ('M', best, bo)
        if p >= 1:
            r = self.common(p, p - 1, min(RUN_MAX, n - p))
            if r >= RUN_MIN:
                return ('M', r, 1)
        return ('L', 1, 0)

    def valid(self, p, tok):
        kind, ln, off = tok
        if kind == 'L':
            return ln == 1
        return (kind == 'M' and 2 <= ln <= self.n - p and 1 <= off <= min(p, self.w)
                and all(self.d[p + i] == self.d[p + i - off] for i in range(ln)))   # LDDR semantics: runs ok


def parse(data, far_bits, hints=None):
    """Token decisions [(p, kind, length, offset, taken_from_hint)] for DATA (memory order, out..end)"""
    d = bytes(reversed(data))
    ps = Parser(d, far_bits)
    hints = (hints or {}).get('tokens', {})
    out, p = [], 0
    while p < len(d):
        tok = ps.rule(p)
        h = hints.get(p)
        used = h is not None and h[1] == tok and ps.valid(p, h[0])
        if used:
            tok = h[0]
        out.append((p,) + tok + (used,))
        p += tok[1]
    return out


# ---------------------------------------------------------------- the bits

class BitWriter:
    def __init__(self):
        self.bytes, self.cur, self.nb = [], 0, 0

    def put(self, value, count):
        for i in range(count - 1, -1, -1):
            self.cur = (self.cur << 1) | ((value >> i) & 1)
            self.nb += 1
            if self.nb == 8:
                self.bytes.append(self.cur)
                self.cur, self.nb = 0, 0

    def finish(self, pad):
        if self.nb:
            self.bytes.append(self.cur << (8 - self.nb))
        return bytes([pad]) + bytes(reversed(self.bytes))


def put_match(bw, ln, off, far_bits):
    if ln <= 3:
        bw.put(0b110 | (ln - 2), 3)
    elif ln <= 7:
        bw.put(0b10100 | (ln - 4), 5)
    elif ln <= 22:
        bw.put(0b10010000 | (ln - 8), 8)
    else:
        bw.put(0b1000, 4)
        v = ln - 23
        while v >= 255:
            bw.put(255, 8)
            v -= 255
        bw.put(v, 8)
    if off <= 0x20:
        bw.put(0b0100000 | (off - 1), 7)
    elif off <= 0x220:
        bw.put(off - 0x21, 11)
    else:
        bw.put((1 << far_bits) | (off - 0x221), far_bits + 1)


def literal_groups(count):
    """A stretch of COUNT literals: run lengths (>= 14), then the number of single literals"""
    runs = []
    while count >= LIT_RUN_MIN:
        runs.append(min(count, LIT_RUN_MAX))
        count -= runs[-1]
    return runs, count


def encode(data, toks, far_bits, pad=0):
    d = bytes(reversed(data))
    bw = BitWriter()
    lits = []

    def flush():
        runs, singles = literal_groups(len(lits))
        i = 0
        for r in runs:
            bw.put(0b1001111100000 | (r - LIT_RUN_MIN), 13)
            for b in lits[i:i + r]:
                bw.put(b, 8)
            i += r
        for b in lits[i:]:
            bw.put(b, 9)        # 0 + the byte
        lits.clear()

    for p, kind, ln, off, _ in toks:
        if kind == 'L':
            lits.append(d[p])
        else:
            flush()
            put_match(bw, ln, off, far_bits)
    flush()
    return bw.finish(pad)


def pack(data: bytes, far_bits: int, hints=None) -> bytes:
    """The stream for DATA (memory order: data[0] at `out`) as it sits at AT.., length included"""
    return encode(data, parse(data, far_bits, hints), far_bits, (hints or {}).get('pad', 0))


# ---------------------------------------------------------------- reading streams and hints

def unpack(stream, n, far_bits, log=None):
    """The N bytes STREAM depacks to (a separate layout: stream at 0, output at the top of 64 K)"""
    mem = bytearray(0x10000)
    mem[:len(stream)] = stream
    zsdepack.depack(mem, len(stream) - 1, 0xFFFF, 0x10000 - n, far_bits, log)
    return bytes(mem[0x10000 - n:])


def stream_tokens(stream, n, far_bits):
    """The original's decisions [(p, kind, length, offset)] and its literal stretches as written"""
    log = []
    unpack(stream, n, far_bits, log)
    toks, p = [], 0
    for e in log:
        if e[0] == 'lit':
            for i in range(e[1]):
                toks.append((p + i, 'L', 1, 0))
            p += e[1]
        else:
            toks.append((p, 'M', e[1], e[2]))
            p += e[1]
    return toks, log


def derive_hints(data, stream, far_bits):
    d = bytes(reversed(data))
    orig, _ = stream_tokens(stream, len(data), far_bits)
    ps = Parser(d, far_bits)
    tokens = {}
    for p, kind, ln, off in orig:
        r = ps.rule(p)
        if r != (kind, ln, off):
            tokens[p] = ((kind, ln, off), r)
    return {'tokens': tokens, 'pad': stream[0]}


def load_hints(path):
    hints = {'tokens': {}, 'pad': 0}
    if not path or not os.path.exists(path):
        return hints
    for line in open(path):
        f = line.split('#', 1)[0].split()
        if not f:
            continue
        if f[0] == 'pad':
            hints['pad'] = int(f[1], 16)
            continue
        hints['tokens'][int(f[0])] = ((f[1], int(f[2]), int(f[3])), (f[4], int(f[5]), int(f[6])))
    return hints


def save_hints(path, hints, source=''):
    lines = ['# Packer hints for tools/zspack.py' + (f': {source}' if source else ''),
             '# The original token decisions the greedy rule does not reproduce (see zspack.py docstring).',
             '# POS KIND LEN OFF  RULE_KIND RULE_LEN RULE_OFF  (POS counts down from the top byte, decimal;',
             '# a hint applies only where the rule decides RULE_* and the hinted token is valid for the data)',
             '# pad XX: the stream\'s lowest byte (never read by the depacker)',
             f'pad {hints["pad"]:02X}']
    for p in sorted(hints['tokens']):
        (k, ln, off), (rk, rl, ro) = hints['tokens'][p]
        lines.append(f'{p} {k} {ln} {off}  {rk} {rl} {ro}')
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    open(path, 'w').write('\n'.join(lines) + '\n')


def block_stream(blk):
    n = blk[0x13] | blk[0x14] << 8
    return bytes(blk[0xB0:0xB0 + n])


# ---------------------------------------------------------------- commands

def in_place_ok(stream, data, far_bits, at, out):
    """Depacks STREAM in the block's own layout (stream at AT, output from out + len - 1 down to OUT): equal to DATA
    only if no output write overwrote stream bytes before the depacker read them"""
    mem = bytearray(0x10000)
    mem[at:at + len(stream)] = stream
    end = out + len(data) - 1
    zsdepack.depack(mem, at + len(stream) - 1, end, out, far_bits)
    return bytes(mem[out:end + 1]) == data


def check(media, hints_dir):
    info = json.load(open(os.path.join(media, 'blocks.json')))
    bad = 0
    for name in NAMES:
        b = info[name]
        fb = b['far_bits']
        data = open(os.path.join(media, name + '-out.bin'), 'rb').read()
        orig = block_stream(open(os.path.join(media, name + '.bin'), 'rb').read())
        hints = load_hints(os.path.join(hints_dir, name + '.lzhints'))
        toks = parse(data, fb, hints)
        mine = encode(data, toks, fb, hints['pad'])
        used = sum(t[4] for t in toks)
        written = sum(1 for t in toks if t[1] == 'M')
        stretch = 0
        for t in toks + [(0, 'M', 0, 0, False)]:
            if t[1] == 'L':
                stretch += 1
                continue
            runs, singles = literal_groups(stretch)
            written += len(runs) + singles
            stretch = 0
        if mine == orig:
            verdict = 'identical'
        else:
            bad += 1
            i = next((i for i in range(min(len(mine), len(orig))) if mine[-1 - i] != orig[-1 - i]),
                     min(len(mine), len(orig)))
            verdict = (f'DIFFERS: {len(mine)} vs {len(orig)} bytes, first difference {i} bytes below the top '
                       f'(${int(b["load"], 16) + len(orig) - 1 - i:04X})')
        safe = in_place_ok(mine, data, fb, int(b['load'], 16), int(b['out'], 16))
        if not safe:
            bad += 1
        print(f'{name:8} {len(data):5} -> {len(mine):5} bytes, far {fb}: {written:5} tokens, {len(toks):5} decisions, '
              f'rule {len(toks) - used:5}, hints {used:2} (of {len(hints["tokens"])}), pad {hints["pad"]:02X}: '
              f'{verdict}; unpacks in place: {"yes" if safe else "NO"}')
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('pack')
    a.add_argument('inp')
    a.add_argument('out')
    a.add_argument('--far-bits', type=int, required=True)
    a.add_argument('--hints')
    a.add_argument('--at', help='hex: the block layout, the stream\'s address, to check the in-place unpack')
    a.add_argument('--dest', help='hex: the first output byte (with --at)')
    a = sub.add_parser('hints')
    a.add_argument('inp')
    a.add_argument('block')
    a.add_argument('--far-bits', type=int, required=True)
    a.add_argument('--out', required=True)
    a = sub.add_parser('check')
    a.add_argument('--media', default=MEDIA)
    a.add_argument('--hints-dir', default=HINTS)
    a = ap.parse_args()
    if a.cmd == 'pack':
        data = open(a.inp, 'rb').read()
        s = pack(data, a.far_bits, load_hints(a.hints))
        assert unpack(s, len(data), a.far_bits) == data
        open(a.out, 'wb').write(s)
        print(f'{len(data)} -> {len(s)} bytes')
        if a.at and a.dest and not in_place_ok(s, data, a.far_bits, int(a.at, 16), int(a.dest, 16)):
            print('the output overwrites the stream before it is read in this layout')
            return 1
    elif a.cmd == 'hints':
        data = open(a.inp, 'rb').read()
        orig = block_stream(open(a.block, 'rb').read())
        h = derive_hints(data, orig, a.far_bits)
        mine = pack(data, a.far_bits, h)
        save_hints(a.out, h, os.path.basename(a.block))
        print(f'{len(h["tokens"])} hints, pad {h["pad"]:02X}; '
              f'{"reproduces the stream" if mine == orig else "does NOT reproduce the stream"}')
        return 0 if mine == orig else 1
    else:
        return 1 if check(a.media, a.hints_dir) else 0


if __name__ == '__main__':
    sys.exit(main())

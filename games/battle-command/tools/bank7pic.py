#!/usr/bin/env python3
"""The packed screens of RAM bank 7 (src/bank7/bank7.ann, UnpackPicture `$FE95`): decode, encode, the parse as text.

    python3 tools/bank7pic.py list IMAGE.bin                  # every picture of a bank 7 image at $C000
    python3 tools/bank7pic.py decode BLOCK.bin OUT.scr        # one picture block to its 6912-byte screen

A picture block (one per `@res pictures/NAME.bin`):

    +0   word   the length of +2 to the end of the bit stream
    +2   word   the unpacked length, always `$1B00` (a whole screen, written from `$4000` on)
    +4   16     the table of common bytes
    +20  byte   the bits of an offset above 8 (always 1: offsets 1-511)
    +21  ...    the bit stream, read least significant bit first (`GetBits` `$FFB7`)
    then 2 bytes `$00` the decoder never reads (the packer's padding)

The stream is a list of tokens, each opening with 2 bits:

    01  LIT   8 bits: one byte
    11  TAB   4 bits i: the table's byte 15 - i
    10  COPY  a count, 8 + long bits of offset: count bytes from offset bytes back in the output
    00  RUN   a count, then 1 bit: 1 -> 4 bits i, the table's byte 15 - i; 0 -> 8 bits, the byte; count copies

A count is 6 bits n: n >= 3 is the count; n = 0: 7 bits follow; n = 1: 8 bits; n = 2: 8 bits then 6 bits above
them. Ocean's packer always used the shortest form, so the parse below does not keep it. When the stream is done,
UnpackPicture ORs BRIGHT (`$40`) into all 768 attributes on the screen; the block's own attributes keep it off.

The parse (NAME.parse.txt) keeps the packer's choices, which no simple rule reproduces (it takes a shorter match
than the longest one and farther offsets of the same bytes, docs in src/res/pictures/README.md): with it the
block builds back byte for byte. A screen that the parse does not decode to (an edited PNG) is packed by `pack`
here, greedily, into a block of the same format that UnpackPicture reads the same way.
"""
import sys

SCREEN = 0x1B00
BLOCKS = [0xC000, 0xC713, 0xCCC9, 0xD325, 0xDD75, 0xE51E, 0xE949, 0xEC82, 0xF4E1, 0xF9CD]


class BitReader:
    def __init__(self, data, pos):
        self.d, self.p, self.acc, self.n = data, pos, 0, 0

    def get(self, k):
        while self.n < k:
            self.acc |= self.d[self.p] << self.n
            self.p += 1
            self.n += 8
        v = self.acc & ((1 << k) - 1)
        self.acc >>= k
        self.n -= k
        return v


class BitWriter:
    def __init__(self):
        self.out, self.acc, self.n = bytearray(), 0, 0

    def put(self, k, v):
        self.acc |= (v & ((1 << k) - 1)) << self.n
        self.n += k
        while self.n >= 8:
            self.out.append(self.acc & 255)
            self.acc >>= 8
            self.n -= 8

    def done(self):
        if self.n:
            self.out.append(self.acc & 255)
        return bytes(self.out)


def get_count(b):
    n = b.get(6)
    if n == 0:
        return b.get(7)
    if n == 1:
        return b.get(8)
    if n == 2:
        return b.get(8) | b.get(6) << 8
    return n


def put_count(w, n):
    if 3 <= n <= 63:
        w.put(6, n)
    elif n < 128:
        w.put(6, 0)
        w.put(7, n)
    elif n < 256:
        w.put(6, 1)
        w.put(8, n)
    else:
        w.put(6, 2)
        w.put(8, n & 255)
        w.put(6, n >> 8)


def decode(block):
    """block -> (screen, parse): parse = {'table', 'long', 'pad', 'tokens'}"""
    size = block[0] | block[1] << 8
    total = block[2] | block[3] << 8
    table = block[4:20]
    long_bits = block[20]
    b = BitReader(block, 21)
    out = bytearray()
    toks = []
    while len(out) < total:
        t = b.get(2)
        if t == 1:
            v = b.get(8)
            out.append(v)
            toks.append(('LIT', v))
        elif t == 3:
            i = 15 - b.get(4)
            out.append(table[i])
            toks.append(('TAB', i))
        elif t == 2:
            n = get_count(b)
            off = b.get(8)
            if long_bits:
                off |= b.get(long_bits) << 8
            for _ in range(n):
                out.append(out[len(out) - off])
            toks.append(('COPY', n, off))
        else:
            n = get_count(b)
            if b.get(1):
                i = 15 - b.get(4)
                out += bytes([table[i]]) * n
                toks.append(('RUNTAB', n, i))
            else:
                v = b.get(8)
                out += bytes([v]) * n
                toks.append(('RUN', n, v))
    if b.p != 2 + size:
        raise ValueError('bank7pic: the stream ends at +%d, the size word says +%d' % (b.p, 2 + size))
    return bytes(out), {'table': bytes(table), 'long': long_bits, 'pad': bytes(block[b.p:]), 'tokens': toks,
                        'total': total}


def encode(parse):
    w = BitWriter()
    table, long_bits = parse['table'], parse['long']
    for t in parse['tokens']:
        k = t[0]
        if k == 'LIT':
            w.put(2, 1)
            w.put(8, t[1])
        elif k == 'TAB':
            w.put(2, 3)
            w.put(4, 15 - t[1])
        elif k == 'COPY':
            w.put(2, 2)
            put_count(w, t[1])
            w.put(8, t[2] & 255)
            if long_bits:
                w.put(long_bits, t[2] >> 8)
        elif k == 'RUNTAB':
            w.put(2, 0)
            put_count(w, t[1])
            w.put(1, 1)
            w.put(4, 15 - t[2])
        else:
            w.put(2, 0)
            put_count(w, t[1])
            w.put(1, 0)
            w.put(8, t[2])
    stream = w.done()
    size = 19 + len(stream)
    head = bytes([size & 255, size >> 8, parse['total'] & 255, parse['total'] >> 8]) + table + bytes([long_bits])
    return head + stream + parse['pad']


def unpacked(parse):
    """the bytes a parse decodes to, without the bit stream"""
    out = bytearray()
    table = parse['table']
    for t in parse['tokens']:
        if t[0] == 'LIT':
            out.append(t[1])
        elif t[0] == 'TAB':
            out.append(table[t[1]])
        elif t[0] == 'COPY':
            for _ in range(t[1]):
                out.append(out[len(out) - t[2]])
        else:
            out += bytes([table[t[2]] if t[0] == 'RUNTAB' else t[2]]) * t[1]
    return bytes(out)


def pack(screen, long_bits=1, pad=b'\0\0'):
    """a greedy parse of SCREEN (not Ocean's: used only for a changed picture)"""
    from collections import Counter
    table = bytes([v for v, _ in Counter(screen).most_common(16)]).ljust(16, b'\0')
    window = (1 << (8 + long_bits)) - 1
    toks = []
    pos = 0
    while pos < len(screen):
        run = 1
        while pos + run < len(screen) and screen[pos + run] == screen[pos] and run < 16383:
            run += 1
        best, best_off = 0, 0
        for off in range(1, min(pos, window) + 1):
            n = 0
            while pos + n < len(screen) and screen[pos + n] == screen[pos - off + n] and n < 16383:
                n += 1
            if n > best:
                best, best_off = n, off
        v = screen[pos]
        if run >= 3 and run >= best:
            toks.append(('RUNTAB', run, table.index(v)) if v in table else ('RUN', run, v))
            pos += run
        elif best >= 3:
            toks.append(('COPY', best, best_off))
            pos += best
        else:
            toks.append(('TAB', table.index(v)) if v in table else ('LIT', v))
            pos += 1
    return {'table': table, 'long': long_bits, 'pad': pad, 'tokens': toks, 'total': len(screen)}


def parse_to_text(parse, title):
    lines = ['# %s: the packer\'s parse of the picture (tools/bank7pic.py; src/res/pictures/README.md).' % title,
             '# LIT byte | TAB index | RUN count byte | RUNTAB count index | COPY count offset (numbers in hex)',
             'total %04X' % parse['total'],
             'table ' + ' '.join('%02X' % b for b in parse['table']),
             'long %d' % parse['long'],
             'pad ' + (' '.join('%02X' % b for b in parse['pad']) or '-')]
    for t in parse['tokens']:
        lines.append(t[0] + ' ' + ' '.join('%X' % v for v in t[1:]))
    return '\n'.join(lines) + '\n'


def text_to_parse(text):
    p = {'tokens': []}
    for line in text.splitlines():
        w = line.split('#')[0].split()
        if not w:
            continue
        if w[0] == 'total':
            p['total'] = int(w[1], 16)
        elif w[0] == 'table':
            p['table'] = bytes(int(x, 16) for x in w[1:])
        elif w[0] == 'long':
            p['long'] = int(w[1])
        elif w[0] == 'pad':
            p['pad'] = b'' if w[1:] == ['-'] else bytes(int(x, 16) for x in w[1:])
        elif w[0] in ('LIT', 'TAB', 'RUN', 'RUNTAB', 'COPY'):
            p['tokens'].append((w[0],) + tuple(int(x, 16) for x in w[1:]))
        else:
            raise ValueError('bank7pic: cannot read %r' % line)
    return p


def main():
    a = sys.argv[1:]
    if a[:1] == ['list'] and len(a) == 2:
        d = open(a[1], 'rb').read()
        base = 0xC000 if len(d) == 0x4000 else 0
        for adr in BLOCKS:
            o = adr - base
            size = d[o] | d[o + 1] << 8
            screen, p = decode(d[o:o + size + 4])
            print('$%04X  block %5d bytes  %4d tokens  screen %d bytes' % (adr, size + 4, len(p['tokens']),
                                                                           len(screen)))
    elif a[:1] == ['decode'] and len(a) == 3:
        screen, _ = decode(open(a[1], 'rb').read())
        open(a[2], 'wb').write(screen)
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

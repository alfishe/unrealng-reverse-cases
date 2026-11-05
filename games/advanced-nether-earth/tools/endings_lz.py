#!/usr/bin/env python3
"""The screen packer of Dead End's picture and the game menu's picture (bank 3): the depacker LzScreen ($D723, a copy
at $E73B) in Python, and a packer that gives the original streams back.

    python3 tools/endings_lz.py unpack STREAM.bin SCREEN.scr [--offset N]   the 6912-byte screen
    python3 tools/endings_lz.py pack SCREEN.scr OUT.bin [--hints FILE]       the stream
    python3 tools/endings_lz.py hints SCREEN.scr STREAM.bin [--offset N]     the decisions the greedy rule misses

The order. The depacker writes the screen in the order of character cells: down the 8 pixel lines of a cell, then the
next cell down the column of a third (8 cells), then the next column (32), then the next third (3); then the 768
attributes in their own order. A back reference counts in that order: the byte k places back in the sequence, which
the depacker finds by turning the sequence address back into a screen address (`Linear`). So the stream is plain
LZ over the sequence S, S[i] = screen[Linear($4000 + i)].

The tokens (one byte, then its operands):

    0LLLLHHH low      a match: length LLLL + 3 (3-18), distance HHH * 256 + low (1-2047), from the bytes already out
    11NNNNNN byte     a run: the byte NNNNNN + 3 times (3-66)
    10NNNNNN bytes    NNNNNN literal bytes (1-63)
    10000000          the end

The original packer's choices, as the two streams show them (1195 of the 1243 tokens): at each place the longest
match that does not overlap the bytes it copies (length <= distance), the farthest of the equally long, when it is at
least 3 and at least as long as the run of equal bytes there; else that run when it is at least 3; else a literal
byte, gathered into blocks of up to 63. The 48 other decisions (23 in the Dead End picture, 25 in the menu picture:
it saw no match or run where one was, or ended a literal block early) follow no rule found in these two streams:
--hints gives them as `index kind length [distance]` lines (src/res/endings/pictures/*.lzhints), and the packer takes
a hint only where its token is valid for the screen it packs (an edited picture falls back to the rule).
"""
import argparse
import sys


def linear(a):
    """the screen address of the sequence address a ($4000 + index): the depacker's LzScreen transform"""
    h, l = a >> 8, a & 0xFF
    if h & 0x58 == 0x58:
        return a
    c = (h & 0x58) | (l & 7)
    v = (a << 2) & 0xFFFF
    h = (v >> 8) & 0x1F
    return c << 8 | (v & 0xE0) | h


ORDER = [linear(0x4000 + i) - 0x4000 for i in range(6912)]


def unpack(data, pos=0):
    """(the screen, the stream's end offset, the tokens [(index, kind, length, distance or byte)])"""
    s, tokens = [], []
    while True:
        b = data[pos]
        if b & 0x80 == 0:
            n, dist = (b >> 3 & 15) + 3, (b & 7) << 8 | data[pos + 1]
            if dist > len(s):
                sys.exit(f'a match at {pos} reaches before the screen')
            tokens.append((len(s), 'm', n, dist))
            for _ in range(n):
                s.append(s[len(s) - dist])
            pos += 2
            continue
        b &= 0x7F
        pos += 1
        if b == 0:
            break
        if b & 0x40:
            n = (b & 0x3F) + 3
            tokens.append((len(s), 'r', n, data[pos]))
            s += [data[pos]] * n
            pos += 1
        else:
            tokens.append((len(s), 'l', b, None))
            s += list(data[pos:pos + b])
            pos += b
    if len(s) != 6912:
        sys.exit(f'the stream gives {len(s)} bytes, not a screen')
    screen = bytearray(6912)
    for i, v in enumerate(s):
        screen[ORDER[i]] = v
    return bytes(screen), pos, tokens


def match_at(s, i):
    """(length, distance): the longest non-overlapping match, the farthest of the equally long"""
    best = (0, 0)
    for dist in range(min(i, 2047), 0, -1):
        k, top = 0, min(18, dist)
        while k < top and i + k < len(s) and s[i + k] == s[i + k - dist]:
            k += 1
        if k > best[0]:
            best = (k, dist)
    return best


def valid(s, i, hint):
    kind, n, dist = hint
    if i + n > len(s):
        return False
    if kind == 'l':
        return 1 <= n <= 63
    if kind == 'r':
        return 3 <= n <= 66 and all(v == s[i] for v in s[i:i + n])
    return 3 <= n <= 18 and 1 <= dist <= min(i, 2047) and all(s[i + k] == s[i + k - dist] for k in range(n))


def pack(screen, hints=None):
    s = [screen[ORDER[i]] for i in range(6912)]
    hints = hints or {}
    out, lit, i = bytearray(), [], 0

    def flush():
        while lit:
            k = min(63, len(lit))
            out.append(0x80 | k)
            out.extend(lit[:k])
            del lit[:k]

    while i < len(s):
        hint = hints.get(i)
        if hint and valid(s, i, hint):
            kind, n, dist = hint
            if kind == 'l':
                lit.extend(s[i:i + n])
                i += n
                continue
        else:
            run = 1
            while i + run < len(s) and s[i + run] == s[i] and run < 66:
                run += 1
            n, dist = match_at(s, i)
            kind = 'm' if n >= 3 and n >= run else 'r' if run >= 3 else 'l'
            if kind == 'r':
                n = run
            if kind == 'l':
                lit.append(s[i])
                i += 1
                continue
        flush()
        if kind == 'r':
            out += bytes([0xC0 | (n - 3), s[i]])
        else:
            out += bytes([(n - 3) << 3 | dist >> 8, dist & 0xFF])
        i += n
    flush()
    out.append(0x80)
    return bytes(out)


def read_hints(path):
    hints = {}
    for line in open(path):
        line = line.split('#', 1)[0].split()
        if line:
            hints[int(line[0])] = (line[1], int(line[2]), int(line[3]) if len(line) > 3 else None)
    return hints


def find_hints(screen, tokens):
    """the original's decisions the rule does not make: replayed in order, each where the rule differs"""
    s = [screen[ORDER[i]] for i in range(6912)]
    out = []
    lit_from = None
    for index, kind, n, x in tokens:
        if kind == 'l':
            # a literal block: the rule must see no token at any of its bytes
            for j in range(index, index + n):
                run = 1
                while j + run < len(s) and s[j + run] == s[j] and run < 66:
                    run += 1
                m, _ = match_at(s, j)
                if run >= 3 or m >= 3:
                    out.append((j, 'l', index + n - j, None))
                    break
            continue
        run = 1
        while index + run < len(s) and s[index + run] == s[index] and run < 66:
            run += 1
        m, dist = match_at(s, index)
        rule = ('m', m, dist) if m >= 3 and m >= run else ('r', run, None)
        mine = (kind, n, x if kind == 'm' else None)
        if rule != mine:
            out.append((index, kind, n, x if kind == 'm' else None))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    u = sub.add_parser('unpack')
    u.add_argument('stream')
    u.add_argument('out')
    u.add_argument('--offset', type=lambda v: int(v, 0), default=0)
    k = sub.add_parser('pack')
    k.add_argument('screen')
    k.add_argument('out')
    k.add_argument('--hints')
    h = sub.add_parser('hints')
    h.add_argument('screen')
    h.add_argument('stream')
    h.add_argument('--offset', type=lambda v: int(v, 0), default=0)
    a = p.parse_args()
    if a.cmd == 'unpack':
        screen, end, tokens = unpack(open(a.stream, 'rb').read(), a.offset)
        open(a.out, 'wb').write(screen)
        print(f'{a.out}: {len(tokens)} tokens, stream {end - a.offset} bytes')
    elif a.cmd == 'pack':
        data = pack(open(a.screen, 'rb').read(), read_hints(a.hints) if a.hints else None)
        open(a.out, 'wb').write(data)
        print(f'{a.out}: {len(data)} bytes')
    else:
        screen, _, tokens = unpack(open(a.stream, 'rb').read(), a.offset)
        for index, kind, n, dist in find_hints(screen, tokens):
            print(index, kind, n, *([dist] if dist is not None else []))


if __name__ == '__main__':
    main()

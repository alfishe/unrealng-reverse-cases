#!/usr/bin/env python3
"""The game's two token sets as text (docs/08-hud-and-text.md): every token, its bytes expanded.

    python3 tools/tokens.py [--image IMAGE] [--set std|other] [--raw] [N ...]

IMAGE is the 64 K game image (default work/mkgame/original.bin). The standard set starts at the word at $F11A
($F11E), the other set at the word at $F11C ($F4F5); token n is the string after the n-th zero byte. In the
standard set (PrintToken $D421 / $D425): a byte below $0E is a control code, $0E-$1F is token code + $72,
$20-$5F a character, $60-$7F token code (the byte itself), $80-$9F a two-letter token of StdPairs $FDB3, $A0 and up
token code - $A0. In the other set (PrintOther $D470): below $20 a control code, $20-$5A a character, $5B-$80 one of
five tokens picked at random from the row at $D5F5, $81-$D6 other token code (other token n is the
n-th string, counted from 1), $D7 and up a pair of OtherPairs
$FD99. A pair's second letter '?' is not printed.
"""
import argparse
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def word(m, a):
    return m[a] | m[a + 1] << 8


def token_start(m, base, n):
    a = base
    for _ in range(n):
        while m[a]:
            a += 1
        a += 1
    return a


def pair(m, table, i):
    a, b = chr(m[table + 2 * i]), chr(m[table + 2 * i + 1])
    return a + ('' if b == '?' else b)


# OtherSetOn ($D420): the other set's printer (PrintOtherChar $D470) hands every byte to the standard one while it
# is 0. Other control 5 and standard control 10 set it, other control 6 clears it; a standard string never looks
# at it (PrintToken calls PrintCode for each byte).
STATE = {'other': True}


def std_code(m, b, depth=0, raw=False):
    if b < 0x0E:
        if b == 10:
            STATE['other'] = True
        return '{%d}' % b
    if b < 0x20 or 0x60 <= b < 0x80 or b >= 0xA0:
        t = b + 0x72 if b < 0x20 else b if b < 0x80 else b - 0xA0
        return '[%02X]' % t if raw or depth > 8 else std(m, t, depth + 1)
    if b < 0x60:
        return chr(b)
    return pair(m, 0xFDB3, b - 0x80)


def std(m, n, depth=0, raw=False):
    out = []
    a = token_start(m, word(m, 0xF11A), n)
    while m[a]:
        out.append(std_code(m, m[a], depth, raw))
        a += 1
    return ''.join(out)


def other_code(m, b, depth=0, raw=False):
    if not STATE['other']:
        return std_code(m, b, depth, raw)
    if b < 0x20:
        if b in (5, 6):
            STATE['other'] = b == 5
        return '{%d}' % b
    if b <= 0x5A:
        return chr(b)
    if b <= 0x80:
        row = m[0xD5F5 + b - 0x5B]
        keep = STATE['other']
        picks = []
        for k in range(5):
            STATE['other'] = keep
            picks.append(other(m, row + k, depth + 1) if depth < 6 else '~%02X' % (row + k))
        return '{' + '|'.join(picks) + '}'
    if b < 0xD7:
        return '[o%02X]' % b if raw or depth > 8 else other(m, b, depth + 1)
    return pair(m, 0xFD99, b - 0xD7)


def other(m, n, depth=0, raw=False):
    out = []
    a = token_start(m, word(m, 0xF11C), n - 1)       # PrintOtherN $D45F skips n - 1 strings
    while m[a]:
        out.append(other_code(m, m[a], depth, raw))
        a += 1
    return ''.join(out)


def count(m, base, end):
    n, a = 0, base
    while a < end:
        while m[a]:
            a += 1
        a += 1
        n += 1
    return n


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--image', default=os.path.join(ROOT, 'work', 'mkgame', 'original.bin'))
    p.add_argument('--set', choices=['std', 'other'], default='std')
    p.add_argument('--raw', action='store_true')
    p.add_argument('n', nargs='*')
    a = p.parse_args()
    m = open(a.image, 'rb').read()
    f = std if a.set == 'std' else other
    ns = [int(x, 0) for x in a.n] or range(256)
    for n in ns:
        STATE['other'] = True
        try:
            print('%02X %s' % (n, f(m, n, raw=a.raw)))
        except IndexError:
            break


if __name__ == '__main__':
    main()

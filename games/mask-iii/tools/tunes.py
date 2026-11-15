#!/usr/bin/env python3
"""MASK III's AY tunes ($C670-$CBA1 of RAM 4, src/res/music/tunes.txt) as text and back (tools/res_formats.py).

    python3 tools/tunes.py src/res/music/tunes.txt      # print the tunes' summary (patterns, lengths)

The bytes (the player at $C000, src/music/music.ann):
  patterns $C670-$CA71   27 patterns; a pattern is events up to $FF:
                           n d      a note (n < $7E: period index n + transpose + 12, Periods $C5C6) for d frames
                           7F d     a rest for d frames
                           80-87    the instrument (Instruments map slot n & 7, set by the order list's C0-C7)
                           88-BF    the vibrato/arpeggio form (& $0F)
                           C2       a command without operands; C0, C1, C3-FE take three operand bytes
                           FF       the pattern's end
  PatternLo/Hi $CA72/$CA8D  the 27 patterns' addresses, low bytes then high bytes
  Songs $CAA8            3 tunes x 3 words: the order list of channels A, B, C
  orders $CABA-$CBA1     a channel's order list: p (< $80) play pattern p; 80-BF repeat the next pattern n & $1F
                           times; C0-C7 v set instrument map slot n & 7 to v; FE t transpose by t; FF the end

The text has one line a piece, "@ADDR kind: tokens", in address order; a note token is NAME:frames (the name assumes
index 0 of Periods = A#0, period $0EEE at the 128K's 1.7734 MHz), a rest r:frames, other bytes $XX; the order
lists' pattern numbers are pNN. The address of every line makes the round trip exact.
"""
import re
import sys

BASE = 0xC670
END = 0xCBA2
PLO, PHI, SONGS, ORDERS = 0xCA72, 0xCA8D, 0xCAA8, 0xCABA
NPAT, NSONG = 27, 3
NAMES = ['A#', 'B-', 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-']


def note_name(n):
    i = n + 12
    return NAMES[i % 12] + str((i + 10) // 12)


NOTE = {note_name(n): n for n in range(0x7E)}


def pattern_tokens(b):
    out, i = [], 0
    while i < len(b):
        x = b[i]
        if x < 0x7E and i + 1 < len(b):
            out.append('%s:%d' % (note_name(x), b[i + 1]))
            i += 2
        elif x == 0x7F and i + 1 < len(b):
            out.append('r:%d' % b[i + 1])
            i += 2
        else:
            out.append('$%02X' % x)
            i += 1
    return out


def order_tokens(b):
    out, i = [], 0
    while i < len(b):
        x = b[i]
        if x < 0x80:
            out.append('p%02d' % x)
        elif (x == 0xFE or 0xC0 <= x <= 0xC7) and i + 1 < len(b):
            out.append('$%02X $%02X' % (x, b[i + 1]))
            i += 1
        else:
            out.append('$%02X' % x)
        i += 1
    return out


def to_text(data):
    def at(a):
        return data[a - BASE]
    pats = [at(PLO + i) | at(PHI + i) << 8 for i in range(NPAT)]
    songs = [[at(SONGS + 6 * t + 2 * c) | at(SONGS + 6 * t + 2 * c + 1) << 8 for c in range(3)] for t in range(NSONG)]
    lines = ['# MASK III: the AY tunes (tools/tunes.py has the format); tune 1 the menu, 2 game over, 3 the game start',
             '# (TuneRequest $9222 = tune; MusicStart takes tune - 1)']
    starts = sorted(set(pats) | {PLO, PHI, SONGS} | {o for s in songs for o in s} | {END})
    for a, b in zip(starts, starts[1:]):
        chunk = data[a - BASE:b - BASE]
        if a in pats:
            kind = 'pattern %02d' % pats.index(a)
            toks = pattern_tokens(chunk)
        elif a == PLO:
            kind, toks = 'patterns-lo', ['$%02X' % x for x in chunk]
        elif a == PHI:
            kind, toks = 'patterns-hi', ['$%02X' % x for x in chunk]
        elif a == SONGS:
            kind = 'songs'
            toks = ['$%04X' % (chunk[i] | chunk[i + 1] << 8) for i in range(0, len(chunk) - 1, 2)]
            toks += ['$%02X' % x for x in chunk[len(chunk) // 2 * 2:]]
        else:
            owner = [(t, c) for t in range(NSONG) for c in range(3) if songs[t][c] == a]
            kind = 'order tune %d %s' % (owner[0][0] + 1, 'ABC'[owner[0][1]]) if owner else 'order'
            toks = order_tokens(chunk)
        lines.append('@%04X %s: %s' % (a, kind, ' '.join(toks)))
    return '\n'.join(lines) + '\n'


def from_text(text):
    out = bytearray(END - BASE)
    for line in text.split('\n'):
        m = re.match(r'@([0-9A-F]{4}) ([^:]*): ?(.*)$', line)
        if not m:
            continue
        a, kind, toks = int(m.group(1), 16), m.group(2), m.group(3).split()
        b = bytearray()
        for t in toks:
            if t.startswith('$') and len(t) == 5:
                v = int(t[1:], 16)
                b += bytes((v & 0xFF, v >> 8))
            elif t.startswith('$'):
                b.append(int(t[1:], 16))
            elif t.startswith('p'):
                b.append(int(t[1:]))
            elif t.startswith('r:'):
                b += bytes((0x7F, int(t[2:])))
            else:
                name, d = t.split(':')
                b += bytes((NOTE[name], int(d)))
        out[a - BASE:a - BASE + len(b)] = b
    return bytes(out)


def main():
    text = open(sys.argv[1]).read()
    for line in text.split('\n'):
        if line.startswith('@'):
            head, toks = line.split(':', 1)
            print(head, len(toks.split()), 'tokens')


if __name__ == '__main__':
    main()

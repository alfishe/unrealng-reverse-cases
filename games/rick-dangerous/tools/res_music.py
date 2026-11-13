#!/usr/bin/env python3
"""The AY music and effects of Rick Dangerous (src/music, RAM 1 `$C000`) as one editable text, src/res/music/music.txt,
and back (a format module of tools/res_formats.py; src/res/music/README.md describes the text).

The seven resources of the music part are one group: the patterns (`$C6E5`), the tune table (`$CA8F`), the order
lists (`$CABF`), the pattern address tables (`$CC4A`, `$CC81`), the instruments (`$CCB8`) and the effects (`$CD08`).
The text holds the instruments, the effects, the tunes, the order lists and the patterns; the tune table and the
pattern address tables are made from the layout: the patterns from PATTERNS on, then the tune table and the order
lists, in the order the text gives them.

    python3 tools/res_music.py FILE.txt      # print the bytes' sizes and the round trip of a text
"""
import re
import sys

PATTERNS = 0xC6E5                 # Patterns: the first byte after EffectChannel ($C6E4)
TUNES = 8
NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
FLAGS = [(1, 'tone'), (2, 'noise'), (4, 'fixed')]
BINS = ['music/patterns.bin', 'music/tunetable.bin', 'music/orders.bin', 'music/patternlo.bin',
        'music/patternhi.bin', 'music/instruments.bin', 'music/effects.bin']
INSTRUMENT = ['attack', 'decay', 'sustain', 'release', 'peak', 'delay', 'length', 'step', 'flags']
SIGNED = {'decay', 'release'}

HEAD = """\
# Rick Dangerous (Firebird 1989), the 128K's AY music and effects: tools/res_music.py, src/res/music/README.md.
# instrument N / effect N: attack decay sustain release peak (volume 0-255, AY volume = /8), vibrato delay (frames,
#   255 none), length (0 slide, bit 7 slide that stops, else vibrato half period), step (added to the period a
#   frame), flags (tone, noise, fixed); an effect adds its period and its frames.
# tune N: the order lists of channels A, B, C.
# order NAME: P pattern, xN repeat the next pattern N times, t+N transpose (semitones), mapK=V instrument slot, end.
# pattern N: one line a step: NOTE FRAMES (C-1 is the period table's first note; played at note + transpose),
#   rest FRAMES, period $XXXX FRAMES, instrument N, cmd $XX [$YY $YY $YY]; the pattern's end byte is implied.
"""


def note_name(n):
    i = n + 12
    return '%s%d' % (NAMES[i % 12], 1 + i // 12)


def note_value(text):
    m = re.fullmatch(r'([A-G][-#])(\d+)', text)
    if not m:
        raise ValueError('not a note: %s' % text)
    n = NAMES.index(m.group(1)) + 12 * (int(m.group(2)) - 1) - 12
    if not 0 <= n < 0x7E:
        raise ValueError('note out of range: %s' % text)
    return n


def sbyte(b):
    return b - 256 if b >= 128 else b


def num(text):
    v = int(text[1:], 16) if text.startswith('$') else int(text)
    return v


def flags_text(f):
    words = [name for bit, name in FLAGS if f & bit]
    rest = f & ~7
    if rest:
        words.append('$%02X' % rest)
    return '+'.join(words) or 'none'


def flags_value(text):
    if text == 'none':
        return 0
    v = 0
    for w in text.split('+'):
        v |= num(w) if w.startswith('$') else dict((n, b) for b, n in FLAGS)[w]
    return v


def instrument_text(rec):
    vals = [rec[0], sbyte(rec[1]), rec[2], sbyte(rec[3]), rec[4], rec[5], rec[6], rec[7] | rec[8] << 8]
    vals[7] = vals[7] - 0x10000 if vals[7] >= 0x8000 else vals[7]
    parts = ['%s %d' % (k, v) for k, v in zip(INSTRUMENT, vals)]
    parts.append('flags %s' % flags_text(rec[9]))
    return ' '.join(parts)


def instrument_bytes(fields):
    out = []
    for k in INSTRUMENT[:7]:
        v = int(fields[k])
        if not (-128 if k in SIGNED else 0) <= v <= (127 if k in SIGNED else 255):
            raise ValueError('%s out of range: %d' % (k, v))
        out.append(v & 0xFF)
    step = int(fields['step'])
    if not -0x8000 <= step <= 0xFFFF:
        raise ValueError('step out of range: %d' % step)
    out += [step & 0xFF, (step >> 8) & 0xFF, flags_value(fields['flags'])]
    return bytes(out)


def fields_of(words):
    if len(words) % 2:
        raise ValueError('fields come in pairs: %s' % ' '.join(words))
    return dict(zip(words[0::2], words[1::2]))


def order_items(data, a):
    """the items of the order list at offset a, and the offset after its end byte"""
    out = []
    while True:
        b = data[a]
        if b < 0x80:
            out.append('P%d' % b)
            a += 1
        elif b == 0xFE:
            out.append('t%+d' % sbyte(data[a + 1]))
            a += 2
        elif b == 0xFF:
            out.append('end')
            return out, a + 1
        elif b < 0xC0:
            out.append('x%d' % (b - 0x80))
            a += 1
        else:
            out.append('map%d=%d' % (b - 0xC0, data[a + 1]))
            a += 2


def order_bytes(items):
    out = bytearray()
    for it in items:
        if it == 'end':
            out.append(0xFF)
            return bytes(out)
        m = re.fullmatch(r'P(\d+)|x(\d+)|t([+-]\d+)|map(\d+)=(\d+)', it)
        if not m:
            raise ValueError('not an order item: %s' % it)
        if m.group(1):
            v = int(m.group(1))
            if v >= 0x80:
                raise ValueError('pattern out of range: %s' % it)
            out.append(v)
        elif m.group(2):
            v = int(m.group(2))
            if v >= 0x40:
                raise ValueError('repeat out of range: %s' % it)
            out.append(0x80 + v)
        elif m.group(3):
            out += bytes([0xFE, int(m.group(3)) & 0xFF])
        else:
            k, v = int(m.group(4)), int(m.group(5))
            if k >= 0x3E or v > 255:
                raise ValueError('map out of range: %s' % it)
            out += bytes([0xC0 + k, v])
    raise ValueError('an order list without end')


def pattern_lines(data, a):
    """the steps of the pattern at offset a, and the offset after its end byte"""
    out = []
    while True:
        b = data[a]
        if b == 0xFF:
            return out, a + 1
        if b < 0x7E:
            out.append('%s %d' % (note_name(b), data[a + 1]))
            a += 2
        elif b == 0x7F:
            out.append('rest %d' % data[a + 1])
            a += 2
        elif b == 0x7E:
            out.append('period $%04X %d' % (data[a + 1] | data[a + 2] << 8, data[a + 3]))
            a += 4
        elif b < 0x88:
            out.append('instrument %d' % (b - 0x80))
            a += 1
        elif b < 0xC0 or b == 0xC2:
            out.append('cmd $%02X' % b)
            a += 1
        else:
            out.append('cmd ' + ' '.join('$%02X' % x for x in data[a:a + 4]))
            a += 4


def pattern_bytes(lines):
    out = bytearray()
    for line in lines:
        w = line.split()
        if w[0] == 'rest':
            out += bytes([0x7F, int(w[1])])
        elif w[0] == 'period':
            p = num(w[1])
            out += bytes([0x7E, p & 0xFF, p >> 8, int(w[2])])
        elif w[0] == 'instrument':
            out.append(0x80 + int(w[1]))
        elif w[0] == 'cmd':
            b = [num(x) for x in w[1:]]
            if not (b[0] >= 0x88 and b[0] != 0xFF and len(b) == (1 if b[0] < 0xC0 or b[0] == 0xC2 else 4)):
                raise ValueError('not a command: %s' % line)
            out += bytes(b)
        else:
            out += bytes([note_value(w[0]), int(w[1])])
    return bytes(out) + b'\xff'


def to_editable(files):
    pats_b, table, orders, lo, hi, inst, fx = (files[b] for b in BINS)
    tables = PATTERNS + len(pats_b)
    obase = tables + len(table)
    out = [HEAD]
    for i in range(0, len(inst), 10):
        out.append('instrument %d: %s\n' % (i // 10, instrument_text(inst[i:i + 10])))
    out.append('\n')
    for i in range(0, len(fx), 13):
        r = fx[i:i + 13]
        out.append('effect %d: %s period %d frames %d\n' % (i // 13, instrument_text(r[:10]), r[10] | r[11] << 8, r[12]))
    out.append('\n')
    # order lists: named by their first tune and channel, in their stored order
    ptrs = [table[i] | table[i + 1] << 8 for i in range(0, len(table), 2)]
    starts, a = [], 0
    while a < len(orders):
        starts.append(a)
        a = order_items(orders, a)[1]
    names = {}
    for k, p in enumerate(ptrs):
        names.setdefault(p - obase, 't%d%s' % (k // 3, 'abc'[k % 3]))
    for k, s in enumerate(starts):
        names.setdefault(s, 'list%d' % k)
    for t in range(len(ptrs) // 3):
        out.append('tune %d: %s\n' % (t, ' '.join(names[p - obase] for p in ptrs[3 * t:3 * t + 3])))
    out.append('\n')
    for s in starts:
        out.append('order %s: %s\n' % (names[s], ' '.join(order_items(orders, s)[0])))
    # patterns, in order; the address tables must be what the layout gives
    pstarts, a = [], 0
    while a < len(pats_b):
        pstarts.append(a)
        a = pattern_lines(pats_b, a)[1]
    for k, s in enumerate(pstarts):
        out.append('\npattern %d\n' % k)
        out += ['  %s\n' % line for line in pattern_lines(pats_b, s)[0]]
    return ''.join(out).encode('ascii')


def from_editable(raw):
    inst, fx, tunes, orders, pats = {}, {}, {}, [], []
    cur = None
    for n, line in enumerate(raw.decode('ascii').split('\n'), 1):
        line = line.rstrip()
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        try:
            if line.startswith('  '):
                if cur is None:
                    raise ValueError('a step outside a pattern')
                cur.append(line.strip())
                continue
            head, _, rest = line.partition(':')
            kind, _, which = head.partition(' ')
            words = rest.split()
            if kind == 'instrument':
                inst[int(which)] = instrument_bytes(fields_of(words))
            elif kind == 'effect':
                f = fields_of(words)
                p, fr = int(f.pop('period')), int(f.pop('frames'))
                fx[int(which)] = instrument_bytes(f) + bytes([p & 0xFF, p >> 8, fr])
            elif kind == 'tune':
                tunes[int(which)] = words
            elif kind == 'order':
                orders.append((which, order_bytes(words)))
            elif kind == 'pattern' and not rest:
                if int(which) != len(pats):
                    raise ValueError('pattern %s out of order' % which)
                cur = []
                pats.append(cur)
            else:
                raise ValueError('cannot read')
        except (ValueError, KeyError, IndexError) as e:
            raise ValueError('music.txt:%d: %s: %s' % (n, e, line))
    pats_b = [pattern_bytes(p) for p in pats]
    patterns = b''.join(pats_b)
    addr, lo, hi = PATTERNS, bytearray(), bytearray()
    for p in pats_b:
        lo.append(addr & 0xFF)
        hi.append(addr >> 8)
        addr += len(p)
    if sorted(tunes) != list(range(len(tunes))) or sorted(inst) != list(range(len(inst))) or \
            sorted(fx) != list(range(len(fx))):
        raise ValueError('music.txt: tunes, instruments and effects are numbered from 0 without gaps')
    obase = addr + 6 * len(tunes)
    where, a = {}, obase
    for name, data in orders:
        if name in where:
            raise ValueError('music.txt: order %s twice' % name)
        where[name] = a
        a += len(data)
    table = bytearray()
    for t in range(len(tunes)):
        if len(tunes[t]) != 3:
            raise ValueError('music.txt: tune %d needs three order lists' % t)
        for name in tunes[t]:
            table += bytes([where[name] & 0xFF, where[name] >> 8])
    vals = [patterns, bytes(table), b''.join(d for _n, d in orders), bytes(lo), bytes(hi),
            b''.join(inst[i] for i in range(len(inst))), b''.join(fx[i] for i in range(len(fx)))]
    return dict(zip(BINS, vals))


GROUPS = {'music/music.txt': (BINS, to_editable, from_editable)}


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    raw = open(sys.argv[1], 'rb').read()
    files = from_editable(raw)
    for name, data in files.items():
        print('%s: %d bytes' % (name, len(data)))
    print('round trip:', 'exact' if to_editable(files) == raw else 'differs')

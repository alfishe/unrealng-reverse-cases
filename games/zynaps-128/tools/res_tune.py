#!/usr/bin/env python3
"""The title tune (TitleTune $B446, its data at $FF01-$FFD3) as text: src/res/music/titletune.tune.txt.

The bytes: 27 periods (TunePeriods $FF01, one a note number, in loop passes), 7 pattern pointers (TuneOrder $FF1C),
then the patterns. A pattern byte $C0+n sets the note length to n * 16 * 256 passes, $FF ends the pattern, any other
byte is a note number. The text:

    periods 0 242 231 ...       the period of each note number
    order A A B A C C D         the patterns in play order
    pattern A                   a pattern: L<n> a length command, a number a note; one line a length command
      L1 7 6
      L2 4
    end

Lines starting with # are comments (the header and the note table are written again on every install). The patterns
are laid out in the order of the text, right after the order table, from the resource's address $FF01.

    python3 tools/res_tune.py check FILE.bin        the bytes -> text -> bytes, the same
Copied from the 48K case (../zynaps/tools): the formats of the same bytes.
"""
import sys

BASE = 0xFF01  # the resource's address: the pointers in the order table are absolute
PERIODS = 27
ORDER = 7
PASS_T = 81  # T-states of one pass of the tone loop $B486-$B49B (uncontended)
CLOCK = 3500000  # the 48K Spectrum's clock
NAMES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

HEADER = """# The title tune of Zynaps: TitleTune ($B446) plays it with the interrupts off.
# src/res/music/titletune.bin as text (tools/res_tune.py); the bytes are at $FF01-$FFD3.
# periods: a note number's period p in passes of the tone loop (81 T), two counters p and p + 1 passes, each wrap
#   flips the speaker: about 3500000 / (2 * 81 * p) Hz, with a slow beat between the two.
# order: the patterns in play order.
# pattern: L<n> sets the note length to n * 16 * 256 passes (n * 0.095 s on a 48K); a number plays that note; end closes it.
"""


def to_text(data, name=''):
    if len(data) < PERIODS + 2 * ORDER:
        raise ValueError(f'{name}: {len(data)} bytes, too short for a tune')
    periods = list(data[:PERIODS])
    pointers = [data[PERIODS + 2 * k] | data[PERIODS + 2 * k + 1] << 8 for k in range(ORDER)]
    at = PERIODS + 2 * ORDER
    patterns = []  # (offset, bytes without the $FF)
    while at < len(data):
        end = data.index(0xFF, at)
        patterns.append((at, data[at:end]))
        at = end + 1
    names = {}
    for k, (offset, _) in enumerate(patterns):
        names[BASE + offset] = NAMES[k]
    for p in pointers:
        if p not in names:
            raise ValueError(f'{name}: the order points at ${p:04X}, no pattern starts there')
    out = [HEADER]
    out.append('# note:   ' + ' '.join(f'{n:>4}' for n in range(1, PERIODS)) + '\n')
    out.append('# Hz:     ' + ' '.join(f'{round(CLOCK / (2 * PASS_T * p)):>4}' for p in periods[1:]) + '\n')
    out.append('periods ' + ' '.join(str(p) for p in periods) + '\n')
    out.append('order ' + ' '.join(names[p] for p in pointers) + '\n')
    for offset, body in patterns:
        out.append(f'\npattern {names[BASE + offset]}\n')
        line = []
        for b in body:
            if b >= 0xC0:
                if line:
                    out.append('  ' + ' '.join(line) + '\n')
                line = [f'L{b - 0xC0}']
            else:
                line.append(str(b))
        if line:
            out.append('  ' + ' '.join(line) + '\n')
        out.append('end\n')
    return ''.join(out).encode()


def from_text(text, name=''):
    periods, order, patterns, current = None, None, [], None
    for number, line in enumerate(text.decode().splitlines(), 1):
        words = line.split('#', 1)[0].split()
        if not words:
            continue
        where = f'{name}:{number}'
        if words[0] == 'periods':
            periods = [int(w) for w in words[1:]]
        elif words[0] == 'order':
            order = words[1:]
        elif words[0] == 'pattern':
            current = (words[1], bytearray())
            patterns.append(current)
        elif words[0] == 'end':
            current = None
        else:
            if current is None:
                raise ValueError(f'{where}: notes outside a pattern: {line}')
            for w in words:
                if w[0] in 'Ll':
                    n = int(w[1:])
                    if not 0 <= n <= 15:
                        raise ValueError(f'{where}: a length is L0-L15: {w}')
                    current[1].append(0xC0 + n)
                else:
                    n = int(w)
                    if not 0 <= n < 0xC0:
                        raise ValueError(f'{where}: a note is 0-191: {w}')
                    current[1].append(n)
    if periods is None or order is None:
        raise ValueError(f'{name}: no periods or no order line')
    if len(periods) != PERIODS or len(order) != ORDER:
        raise ValueError(f'{name}: {PERIODS} periods and {ORDER} order entries, the code reads exactly that many')
    if any(not 0 <= p <= 255 for p in periods):
        raise ValueError(f'{name}: a period is 0-255')
    address, starts, body = BASE + PERIODS + 2 * ORDER, {}, bytearray()
    for label, notes in patterns:
        starts[label] = address
        body += notes + b'\xff'
        address += len(notes) + 1
    out = bytearray(periods)
    for label in order:
        if label not in starts:
            raise ValueError(f'{name}: the order names {label}, no such pattern')
        out += bytes((starts[label] & 0xFF, starts[label] >> 8))
    return bytes(out + body)


KINDS = [('music/*.bin', '.tune.txt', to_text, from_text)]


def main():
    if len(sys.argv) != 3 or sys.argv[1] != 'check':
        print(__doc__)
        return 2
    data = open(sys.argv[2], 'rb').read()
    text = to_text(data, sys.argv[2])
    back = from_text(text, sys.argv[2])
    ok = back == data and to_text(back) == text
    print(f'{sys.argv[2]}: {len(data)} bytes, ' + ('both ways the same' if ok else 'FAIL'))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

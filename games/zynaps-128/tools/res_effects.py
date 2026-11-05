#!/usr/bin/env python3
"""The sound effects (EffectTable $7E5A, 6 x 8 bytes) as text: src/res/effects/effects.fx.txt.

EffectPlay $B30C copies effect n (1-6) from $7E5A + 8 (n - 1): +0 pitch A, +1 its step, +2 pitch B, +3 its step,
+4 the step change per segment, +5 the segments, +6 the flags, +7 the segment lengths (low nibble A, high B). The
text has one line an effect, its fields by name; the steps and the change are signed:

    effect 1 pitchA=$80 stepA=-2 pitchB=$01 stepB=+1 change=+0 segments=3 flags=%10000111 lenA=3 lenB=0  # the use

The flags: bit 7 two tones, bit 6 the pitches restart each segment, bit 5 SegLenA shortens, bits 4/3 step B/A
reverse, bits 0-2 which pitch a one-tone segment plays by the segment count's parity (docs/09-sound.md).

    python3 tools/res_effects.py check FILE.bin        the bytes -> text -> bytes, the same
Copied from the 48K case (../zynaps/tools): the formats of the same bytes.
"""
import sys

FIELDS = ('pitchA', 'stepA', 'pitchB', 'stepB', 'change', 'segments', 'flags')
SIGNED = {'stepA', 'stepB', 'change'}
USES = {1: 'the enemy shot', 2: 'the laser', 3: 'the plasma bounce', 4: 'a pod appears', 5: 'the next weapon',
        6: 'a weapon on'}
HEADER = """# The sound effects of Zynaps: EffectTable $7E5A, played by EffectPlay $B30C (tools/res_effects.py).
# RequestEffect $B2F0 takes effect n only when n >= the one playing: the number is the priority.
"""


def signed(b):
    return b - 256 if b >= 128 else b


def to_text(data, name=''):
    if len(data) % 8:
        raise ValueError(f'{name}: {len(data)} bytes, not whole 8-byte effects')
    out = [HEADER]
    for n in range(len(data) // 8):
        e = data[8 * n:8 * n + 8]
        words = [f'effect {n + 1}']
        for field, b in zip(FIELDS, e):
            if field in SIGNED:
                words.append(f'{field}={signed(b):+d}')
            elif field == 'flags':
                words.append(f'{field}=%{b:08b}')
            elif field == 'segments':
                words.append(f'{field}={b}')
            else:
                words.append(f'{field}=${b:02X}')
        words.append(f'lenA={e[7] & 15} lenB={e[7] >> 4}')
        line = ' '.join(words)
        if n + 1 in USES:
            line += f'  # {USES[n + 1]}'
        out.append(line + '\n')
    return ''.join(out).encode()


def number(text):
    if text.startswith('$'):
        return int(text[1:], 16)
    if text.startswith('%'):
        return int(text[1:], 2)
    return int(text, 10)


def from_text(text, name=''):
    effects = {}
    for line_no, line in enumerate(text.decode().splitlines(), 1):
        words = line.split('#', 1)[0].split()
        if not words:
            continue
        if words[0] != 'effect' or len(words) < 2:
            raise ValueError(f'{name}:{line_no}: expected "effect N field=value ..."')
        n = int(words[1])
        values = dict(w.split('=', 1) for w in words[2:])
        missing = (set(FIELDS) | {'lenA', 'lenB'}) - set(values)
        if missing:
            raise ValueError(f'{name}:{line_no}: missing {sorted(missing)}')
        e = [number(values[f]) & 0xFF for f in FIELDS]
        a, b = number(values['lenA']), number(values['lenB'])
        if not (0 <= a < 16 and 0 <= b < 16):
            raise ValueError(f'{name}:{line_no}: a segment length is a nibble')
        effects[n] = bytes(e + [a | b << 4])
    if sorted(effects) != list(range(1, len(effects) + 1)):
        raise ValueError(f'{name}: the effects must be numbered 1..n')
    return b''.join(effects[n] for n in sorted(effects))


KINDS = [('effects/*.bin', '.fx.txt', to_text, from_text)]

if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == 'check':
        data = open(sys.argv[2], 'rb').read()
        assert from_text(to_text(data)) == data
        print('effects: both ways the same')
    else:
        sys.exit(__doc__)

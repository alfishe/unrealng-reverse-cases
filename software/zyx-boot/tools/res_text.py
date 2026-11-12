#!/usr/bin/env python3
"""The menu's strings as UTF-8 text (tools/res_formats.py calls it for src/res/texts/*).

The bytes are what PrintString $6720 sends to the ROM's RST $10 one by one up to $FF. Printable ASCII stays itself;
the control codes are written in braces: {AT y,x} (22 y x), {INK n} (16 n), {PAPER n} (17 n), {BRIGHT n} (19 n),
{END} ($FF, the end mark), {$XX} any other byte (and a literal brace). A line break is only layout: one starts each
{AT} after the first, and they are dropped when the text is read back.
"""
import re

CODES = {22: ('AT', 2), 16: ('INK', 1), 17: ('PAPER', 1), 19: ('BRIGHT', 1)}
NAMES = {v[0]: (k, v[1]) for k, v in CODES.items()}


def handles(name):
    return name.startswith('texts/')


def to_editable(name, data):
    out, i = [], 0
    while i < len(data):
        b = data[i]
        if b in CODES and i + CODES[b][1] < len(data):
            word, n = CODES[b]
            if word == 'AT' and out:
                out.append('\n')
            out.append('{%s %s}' % (word, ','.join(str(x) for x in data[i + 1:i + 1 + n])))
            i += 1 + n
            continue
        if b == 0xFF:
            out.append('{END}')
        elif 32 <= b < 127 and chr(b) not in '{}':
            out.append(chr(b))
        else:
            out.append('{$%02X}' % b)
        i += 1
    return '.txt', (''.join(out) + '\n').encode('utf-8')


def from_editable(name, raw):
    text = raw.decode('utf-8').replace('\n', '')
    out = bytearray()
    for m in re.finditer(r'\{([^}]*)\}|(.)', text, re.S):
        if m.group(2) is not None:
            out += m.group(2).encode('ascii')
            continue
        token = m.group(1)
        if token == 'END':
            out.append(0xFF)
        elif token.startswith('$'):
            out.append(int(token[1:], 16))
        else:
            word, args = token.split(' ', 1)
            code, n = NAMES[word]
            values = [int(x) for x in args.split(',')]
            if len(values) != n:
                raise ValueError(f'{name}: {{{token}}} takes {n} numbers')
            out += bytes([code] + values)
    return bytes(out)

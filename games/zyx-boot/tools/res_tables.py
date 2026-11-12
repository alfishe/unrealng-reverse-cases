#!/usr/bin/env python3
"""The menu's tables and the player's note periods as text (tools/res_formats.py calls it for src/res/tables/*).

Every table is lines of numbers: `#` starts a comment, a word ending in `:` is a row label, `$XX` is hex, a plain
number decimal, `%bbbbb` binary. The stars are written as points (x y lit) and the keys as (letter row mask): the
other bytes of their records follow from those, and reading the text back rebuilds them.
"""
import re

TABLES = {
    'tables/logo-attrs.bin': 'attrs',
    'tables/corner-colours.bin': 'attrs',
    'tables/stars.bin': 'stars',
    'tables/keys.bin': 'keys',
    'tables/phase-order.bin': 'numbers',
    'tables/rhombus-columns.bin': 'numbers',
    'tables/rhombus-offsets.bin': 'numbers',
    'tables/exit-sound.bin': 'ay',
    'tables/randoms.bin': 'numbers',
    'tables/note-periods.bin': 'periods',
}

HEAD = {
    'tables/logo-attrs.bin': '# The logo''s attributes: 5 rows of 20 cells, copied by DrawScreen $6510 to $5806 (columns 6-25, rows 0-4).\n'
                             '# A cell is FBPPPIII: flash, bright, paper, ink ($47 bright white on black, $07 white, $45 bright cyan).\n',
    'tables/corner-colours.bin': '# CornerColours: the five attributes of the corner gradients (ColourCorners $6CBF): one a row in the\n'
                                 '# top-left and bottom-right corners, one a column in the top-right and bottom-left ones.\n',
    'tables/stars.bin': '# The falling stars: three tables of 20 stars (StarsA $AC84, StarsB $ACFC, StarsC $AD74).\n'
                        '# A star: x (0-255), y (0-191) of its pixel, lit = whether the screen pixel under it was set (MoveStars\n'
                        '# restores it). The record is the screen address, the RES / SET / BIT n,(HL) opcodes of its bit and lit.\n',
    'tables/keys.bin': '# KeyTable: the 24 letter keys A-X. row: the keyboard half-row (the bit reset in the port\'s high byte,\n'
                       '# 0 = $FEFE CAPS..V ... 7 = $7FFE SPACE..B); mask: the key\'s bit in the IN byte (bit 0 the outer key).\n',
    'tables/phase-order.bin': '# PhaseOrder: the rhombus phase shown at each of the 32 steps of a turn (PrintRombPhase $64DA); a phase n\n'
                              '# lies at the phase set + n x 256 (0-7 turning, 8 edge-on, 9-16 the mirrored phases).\n',
    'tables/rhombus-columns.bin': '# RombColumnOrder: the 40 rhombus pixel columns in the order the phases drop them (BuildRombPhases $62F1):\n'
                                  '# phase k keeps the first 5 x (8 - k) columns. Values 0-39.\n',
    'tables/rhombus-offsets.bin': '# RombPhaseOffsets: the pixel column where phase k\'s narrowed rhombus starts, at index 8 - k (phase 0, the\n'
                                  '# whole rhombus, at index 8: 0). Bits 7-3 the byte, bits 2-0 the pixel (ScaleRombLine $6364). Index 0 is not\n'
                                  '# read (BuildRombPhases $62F1 reads indices 8 down to 1).\n',
    'tables/exit-sound.bin': '# ExitSound: the AY registers 0-13 PlayBell $6E48 writes when a file is chosen.\n',
    'tables/randoms.bin': '# Randoms $ADEC: the places of the twinkles, 4 pairs (DrawTwinkle $6BFD takes pair n = TwinkleClock bits 6-7;\n'
                          '# NewRandoms $6BAB refills all 8 from R, the ROM and MainTick).\n',
    'tables/note-periods.bin': '# PeriodTable $C3CA (src/music): the AY tone period of each note the player plays, 86 words (note 0 = A#0,\n'
                               '# MIDI 22, to note $55 = B7), read by ChannelSound $C2A0. A line: the period (decimal), the note in the comment.\n',
}


def handles(name):
    return name in TABLES


def screen_xy(addr, bit):
    y = (addr >> 8 & 7) | (addr >> 5 & 7) << 3 | (addr >> 11 & 3) << 6
    return (addr & 31) * 8 + 7 - bit, y


def screen_addr(x, y):
    return 0x4000 | (y & 7) << 8 | (y >> 3 & 7) << 5 | (y >> 6) << 11 | x >> 3


def star_ok(rec):
    addr = rec[0] | rec[1] << 8
    bit = rec[2] >> 3 & 7
    return (0x4000 <= addr < 0x5800 and rec[2] == 0x86 | bit << 3 and rec[3] == 0xC6 | bit << 3
            and rec[4] == 0x46 | bit << 3 and rec[5] in (0, 1))


def to_editable(name, data):
    kind = TABLES[name]
    out = [HEAD[name]]
    if kind == 'attrs':
        for i in range(0, len(data), 20):
            out.append(' '.join('$%02X' % b for b in data[i:i + 20]) + '\n')
    elif kind == 'numbers':
        for i in range(0, len(data), 8):
            out.append(' '.join('%2d' % b for b in data[i:i + 8]) + '\n')
    elif kind == 'periods':
        from res_music import note_name
        for i in range(0, len(data), 2):
            out.append('%5d  # note %d, %s\n' % (data[i] | data[i + 1] << 8, i // 2, note_name(i // 2)))
    elif kind == 'ay':
        for i, b in enumerate(data):
            out.append('R%d: %d\n' % (i, b))
    elif kind == 'keys':
        for i, b in enumerate(data):
            out.append('%s: %d %%%s\n' % (chr(65 + i), b >> 5, format(b & 31, '05b')))
    elif kind == 'stars':
        for i in range(0, len(data), 6):
            rec = data[i:i + 6]
            if i % 120 == 0:
                out.append('# table %s\n' % 'ABC'[i // 120])
            if star_ok(rec):
                x, y = screen_xy(rec[0] | rec[1] << 8, rec[2] >> 3 & 7)
                out.append('%3d %3d %d\n' % (x, y, rec[5]))
            else:
                out.append('raw: ' + ' '.join('$%02X' % b for b in rec) + '\n')
    return '.txt', ''.join(out).encode('utf-8')


def numbers(text):
    vals = []
    for tok in text.split():
        if tok.endswith(':'):
            continue
        if tok.startswith('$'):
            vals.append(int(tok[1:], 16))
        elif tok.startswith('%'):
            vals.append(int(tok[1:], 2))
        else:
            vals.append(int(tok))
    return vals


def from_editable(name, raw):
    kind = TABLES[name]
    lines = [re.sub(r'#.*', '', l).strip() for l in raw.decode('utf-8').splitlines()]
    lines = [l for l in lines if l]
    out = bytearray()
    for l in lines:
        if kind == 'keys':
            _letter, row, mask = l.split()
            out.append(int(row) << 5 | int(mask[1:], 2))
        elif kind == 'periods':
            for v in numbers(l):
                out += bytes([v & 255, v >> 8])
        elif kind == 'stars' and not l.startswith('raw:'):
            x, y, lit = (int(v) for v in l.split())
            a, bit = screen_addr(x, y), 7 - (x & 7)
            out += bytes([a & 255, a >> 8, 0x86 | bit << 3, 0xC6 | bit << 3, 0x46 | bit << 3, lit])
        else:
            out += bytes(numbers(l))
    return bytes(out)

"""Resource formats (tools/res_formats.py): the game's small design tables as text.

- levels/leveltable.txt (LevelTable `$E4AE`, 5 records of 11 bytes): one line a record: the intro text by name, its
  screen address, the attribute, Rick's x and y, the first zone record by name and the first view row (ViewTopRow
  `$ADB7`, passed in C to LoadScreen `$AC83`). An `@res ... include`: the build writes leveltable.inc (kit/resinc.py), its words by name and
  record 0's field labels (LevelTextPtr ... LevelViewTop) between its bytes.
- levels/charprops.txt (CharPropsSet0 `$F6C0`, CharPropsSet1 `$F6D0`): the char property runs of each tile set,
  (count, property) x 8; BuildCharProps `$F6A9` expands them into `$5C00-$5CFF`.
- music/periods.txt (PeriodTable `$C000` of the AY player, 85 words): one note a line, its index, name and period.

    python3 tools/res_tables.py      # prints the three texts from build/res (a check by eye)
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))

_SYM = None


def sym():
    global _SYM
    if _SYM is None:
        import resinc
        _SYM = resinc.Symbols(ROOT).add('src/game/game.ann')
    return _SYM


def name_of(word):
    return sym().label(word) or '$%04X' % word


def value_of(text):
    return sym().value(text)


# ---- the level table

FIELDS = ('LevelTextPtr', 'LevelTextAt', 'LevelAttr', 'LevelRickX', 'LevelRickY', 'LevelZone', 'LevelViewTop')
PLACES = ('the jungle (South America)', 'Egypt', 'the castle (Europe)', 'the missile base (Europe)',
          'the ending (London)')
LEVEL = re.compile(r'^level (\d) text (\S+) at \$([0-9A-F]{4}) attr \$([0-9A-F]{2}) x \$([0-9A-F]{2}) '
                   r'y \$([0-9A-F]{4}) zone (\S+) view \$([0-9A-F]{2})(?:\s*;.*)?$')


def records(raw):
    for n in range(len(raw) // 11):
        r = raw[11 * n:11 * n + 11]
        yield n, (int.from_bytes(r[0:2], 'little'), int.from_bytes(r[2:4], 'little'), r[4], r[5],
                  int.from_bytes(r[6:8], 'little'), int.from_bytes(r[8:10], 'little'), r[10])


def leveltable_to_text(raw):
    if len(raw) % 11:
        raise ValueError('leveltable: %d bytes, not records of 11' % len(raw))
    out = ['# LevelTable $E4AE: one record of 11 bytes a level (tools/res_tables.py). Fields: the intro text (a word,',
           '# by name), its screen address, the attribute stored in $7900, Rick\'s x (RickX $EAAD) and y (RickY $EAAE),',
           '# the first zone record (Zones + 7n, by name), the first view row (ViewTopRow $ADB7, passed in C to $AC83).',
           '# Record 0 is the one the game starts from; a level change reads record Level $E4AD. The ending\'s record',
           '# uses only the text and attribute.']
    for n, (text, at, attr, x, y, zone, count) in records(raw):
        out.append('level %d text %s at $%04X attr $%02X x $%02X y $%04X zone %s view $%02X ; %s' % (
            n, name_of(text), at, attr, x, y, name_of(zone), count, PLACES[n] if n < len(PLACES) else ''))
    return ('\n'.join(out) + '\n').encode()


def leveltable_from_text(raw):
    out = bytearray()
    for line in raw.decode().splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        m = LEVEL.match(line.strip())
        if not m:
            raise ValueError('leveltable: cannot read %r' % line)
        if int(m.group(1)) != len(out) // 11:
            raise ValueError('leveltable: level %s out of order' % m.group(1))
        out += value_of(m.group(2)).to_bytes(2, 'little') + int(m.group(3), 16).to_bytes(2, 'little')
        out += bytes([int(m.group(4), 16), int(m.group(5), 16)]) + int(m.group(6), 16).to_bytes(2, 'little')
        out += value_of(m.group(7)).to_bytes(2, 'little') + bytes([int(m.group(8), 16)])
    return bytes(out)


def leveltable_inc(raw):
    """leveltable.inc: record 0 with its field labels, every word by name"""
    import resinc
    data = leveltable_from_text(raw)
    items = []
    for n, (text, at, attr, x, y, zone, count) in records(data):
        fields = (('w', name_of(text)), ('w', at), ('b', attr), ('b', x), ('w', y), ('w', name_of(zone)),
                  ('b', count))
        for i, (kind, v) in enumerate(fields):
            if n == 0:
                items.append(('label', FIELDS[i]))
            if kind == 'w' and isinstance(v, int):
                items += [('b', v & 0xFF), ('b', v >> 8)]  # a number, not an address: two bytes
            else:
                items.append((kind, v))
    return resinc.lines(items, ['leveltable.inc: written by tools/res_formats.py from src/res/levels/leveltable.txt'])


# ---- the char properties

PROPS = {0x00: 'nothing', 0x02: 'ladder', 0x04: 'deadly', 0x08: 'in front of the sprites', 0x10: 'platform',
         0x60: 'spring', 0x40: 'wall', 0x80: 'floor'}
RUN = re.compile(r'^set (\d) chars (\d+)-(\d+) count (\d+) property \$([0-9A-F]{2})(?:\s*;.*)?$')


def charprops_to_text(raw):
    if len(raw) != 32:
        raise ValueError('charprops: %d bytes, not 2 x 16' % len(raw))
    out = ['# CharPropsSet0 $F6C0 (levels 1-2) and CharPropsSet1 $F6D0 (levels 3-4): 8 runs a set of (count, property)',
           '# (tools/res_tables.py). BuildCharProps $F6A9 writes the property of each char into $5C00 + char; the chars',
           '# column is the run\'s range (a count of 0 is 256). Properties: bit 1 ladder, bit 2 deadly, bit 3 in front of',
           '# the sprites, bit 4 platform, bit 5 spring (with bit 6), bit 6 wall, bit 7 floor (doc 10, 10.1).']
    for s in range(2):
        c = 0
        for i in range(8):
            count, prop = raw[16 * s + 2 * i], raw[16 * s + 2 * i + 1]
            n = count or 256
            out.append('set %d chars %d-%d count %d property $%02X ; %s' % (s, c, c + n - 1, count, prop,
                                                                          PROPS.get(prop, 'bits')))
            c += n
    return ('\n'.join(out) + '\n').encode()


def charprops_from_text(raw):
    out = bytearray()
    for line in raw.decode().splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        m = RUN.match(line.strip())
        if not m:
            raise ValueError('charprops: cannot read %r' % line)
        out += bytes([int(m.group(4)), int(m.group(5), 16)])
    return bytes(out)


# ---- the AY period table

NOTES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')
PERIOD = re.compile(r'^(\d+) (\S+) (\d+)(?:\s*;.*)?$')


def periods_to_text(raw):
    if len(raw) % 2:
        raise ValueError('periods: an odd length')
    out = ['# PeriodTable $C000 of the AY player (src/music): the tone period of each note, index = the pattern\'s',
           '# note + the transpose + 12; index 0 is C-1 (tools/res_tables.py). The periods are 2 MHz values on the',
           '# 1.7734 MHz AY (doc 9). Index 20 and 24 carry the original\'s typos (1236 for 1204, 988 for 956).']
    for i in range(len(raw) // 2):
        p = int.from_bytes(raw[2 * i:2 * i + 2], 'little')
        out.append('%d %s%d %d' % (i, NOTES[i % 12], i // 12 + 1, p))
    return ('\n'.join(out) + '\n').encode()


def periods_from_text(raw):
    out = bytearray()
    for line in raw.decode().splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        m = PERIOD.match(line.strip())
        if not m or int(m.group(1)) != len(out) // 2:
            raise ValueError('periods: cannot read %r' % line)
        out += int(m.group(3)).to_bytes(2, 'little')
    return bytes(out)


SINGLES = {
    'levels/leveltable.bin': ('.txt', leveltable_to_text, leveltable_from_text),
    'levels/charprops.bin': ('.txt', charprops_to_text, charprops_from_text),
    'music/periods.bin': ('.txt', periods_to_text, periods_from_text),
}
INCLUDES = {'levels/leveltable.bin': leveltable_inc}

if __name__ == '__main__':
    for name, (_s, to_text, _f) in SINGLES.items():
        print(to_text(open(os.path.join(ROOT, 'build', 'res', name), 'rb').read()).decode())

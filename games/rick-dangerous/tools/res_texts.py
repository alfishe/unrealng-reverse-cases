"""The game's texts (src/res/texts/*.txt) and their bytes (a format module of tools/res_formats.py).

The printers `$AA8D` / `$AA9F` take a byte as a font glyph, code - `$37` (src/res/graphics/README.md, the font):
`$37-$40` are the digits 0-9, `$41-$5A` the letters, `$5B-$5D` the HUD pictures, `$5E` a comma, `$5F` a full stop,
`$60` a question mark; `$20` is a space, `$FF` ends a line, `$FE` ends the text. In the .txt file:

    digits, letters, space, comma, full stop and question mark as themselves;
    $FF as a line break; $FE as "{end}" and a line break; any other byte as "{XX}" (hex).

So "C 8@?@" of the credits is "C 1989" in the file. No line break may follow "{end}" other than its own.
"""

NAMES = ['CastleText', 'ControlsText', 'CreditsText', 'EgyptText', 'GameOverBlankText', 'GameOverText',
         'LondonText', 'MissileBaseText', 'SouthAmericaText', 'TitleText']

TO_CHAR = {0x20: ' ', 0x5E: ',', 0x5F: '.', 0x60: '?'}
TO_CHAR.update({0x37 + d: str(d) for d in range(10)})
TO_CHAR.update({c: chr(c) for c in range(0x41, 0x5B)})
TO_BYTE = {v: k for k, v in TO_CHAR.items()}


def to_text(data):
    out = []
    for b in data:
        if b == 0xFF:
            out.append('\n')
        elif b == 0xFE:
            out.append('{end}\n')
        elif b in TO_CHAR:
            out.append(TO_CHAR[b])
        else:
            out.append('{%02X}' % b)
    return ''.join(out).encode('ascii')


def from_text(raw):
    text = raw.decode('ascii')
    out = bytearray()
    i = 0
    while i < len(text):
        ch = text[i]
        if text.startswith('{end}\n', i):
            out.append(0xFE)
            i += 6
        elif ch == '{':
            j = text.index('}', i)
            out.append(int(text[i + 1:j], 16))
            i = j + 1
        elif ch == '\n':
            out.append(0xFF)
            i += 1
        else:
            if ch not in TO_BYTE:
                raise ValueError('a character the font has not: %r' % ch)
            out.append(TO_BYTE[ch])
            i += 1
    return bytes(out)


SINGLES = {'texts/%s.bin' % n: ('.txt', to_text, from_text) for n in NAMES}

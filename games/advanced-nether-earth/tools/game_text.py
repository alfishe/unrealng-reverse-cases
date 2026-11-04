#!/usr/bin/env python3
"""The game's Cyrillic: which letter each code of ANE's game font draws (src/res/gfx/game-font.png, $C400).

ANE kept NE's codes and drew Russian letters over the Latin ones, a look-alike where there is one (A, B, C, E, K,
M, O, P, T, X, and the digit 3 for З) and a free code for the rest. Й is written with И, Ё with Е; there is no Ъ.

    python3 tools/game_text.py HEX...       the codes as text
"""
import sys

GLYPHS = {
    0x23: 'Щ', 0x24: 'Э', 0x33: 'З',
    0x41: 'А', 0x42: 'В', 0x43: 'С', 0x44: 'Д', 0x45: 'Е', 0x46: 'Ф', 0x47: 'Г', 0x48: 'Н', 0x49: 'И', 0x4A: 'Ж',
    0x4B: 'К', 0x4C: 'Л', 0x4D: 'М', 0x4E: 'Ш', 0x4F: 'О', 0x50: 'Р', 0x51: 'Ы', 0x52: 'Ь', 0x53: 'Я', 0x54: 'Т',
    0x55: 'Ю', 0x56: 'Ч', 0x57: 'П', 0x58: 'Х', 0x59: 'У', 0x5A: 'Ц', 0x5B: 'Б', 0x40: '©',
}


def decode(data, digits=False):
    """the codes as text; control codes (below $20) as '.'; with digits, 3 stays 3"""
    out = []
    for b in data:
        if b == 0x33 and digits:
            out.append('3')
        elif b in GLYPHS:
            out.append(GLYPHS[b])
        elif 0x20 <= b < 0x7F:
            out.append(chr(b))
        else:
            out.append('.')
    return ''.join(out)


if __name__ == '__main__':
    print(decode(bytes.fromhex(''.join(sys.argv[1:]))))

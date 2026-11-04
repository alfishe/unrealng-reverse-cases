#!/usr/bin/env python3
"""The font and the strings of Nether Earth, from the built game image (docs/08-hud-and-text.md).

    python3 text_figs.py font docs/img/hud-font.png      the 64 glyphs, codes $20-$5F, with their codes
    python3 text_figs.py strings                          every PrintInline string as a markdown table

The image is build/game.bin ($5B00-$FCE8, what tools/build.sh assembles). A string is the bytes after a
`CALL PrintInline` ($D42D) up to the 0 that ends it; `CALL PrintKeyPrompt` ($C40C) ends in `JP PrintInline`, so the
bytes after its calls are strings as well. The control codes: 1 Y X a position, 2 A an attribute, 3 the next line,
4 N the size (high nibble the height in rows, low nibble the width in bytes).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 0x5B00
FONT = 0x6780            # code $20; PrintChar reads $6680 + 8 * code
PRINT_INLINE = 0xD42D
KEY_PROMPT = 0xC40C


def image():
    data = open(os.path.join(HERE, '..', 'build', 'game.bin'), 'rb').read()
    return bytes(BASE) + data + bytes(0x10000 - BASE - len(data))


ODD = {0x22: 'a wave', 0x40: '(c)', 0x5E: 'up arrow'}  # glyphs that are not the ASCII sign


def font(out):
    sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
    import kitlib as K
    mem = image()
    scale, cell = 4, 8 * 4 + 14
    top = 58
    sheet = Image.new('RGB', (16 * cell + 8, top + 4 * (cell + 16) + 8), (24, 24, 30))
    draw = ImageDraw.Draw(sheet)
    big, small = K.font(15), K.font(11)
    draw.text((8, 8), 'The only font: 64 glyphs for the codes $20-$5F at $6780, upper case only', fill=K.TEXT,
              font=big)
    draw.text((8, 32), 'orange: a glyph that is not the ASCII sign ($22 a wave, $40 the copyright sign, $5E an up '
              'arrow)', fill=(255, 160, 60), font=small)
    for code in range(0x20, 0x60):
        i = code - 0x20
        x0, y0 = 8 + (i % 16) * cell, top + (i // 16) * (cell + 16)
        odd = code in ODD
        draw.rectangle([x0 - 2, y0 - 2, x0 + 8 * scale + 1, y0 + 8 * scale + 1],
                       outline=(255, 160, 60) if odd else (70, 70, 80), width=2 if odd else 1)
        for line in range(8):
            byte = mem[FONT + 8 * i + line]
            for bit in range(8):
                ink = byte & (0x80 >> bit)
                colour = (230, 230, 230) if ink else (0, 0, 0)
                draw.rectangle([x0 + bit * scale, y0 + line * scale, x0 + bit * scale + scale - 1,
                                y0 + line * scale + scale - 1], fill=colour)
        draw.text((x0, y0 + 8 * scale + 3), f'${code:02X}', fill=(255, 160, 60) if odd else (150, 200, 255),
                  font=small)
    sheet.save(out)


def decode(mem, a):
    """(end, text) of the string at a: controls in braces"""
    out = []
    while mem[a]:
        c = mem[a]
        if c == 1:
            out.append(f'{{at {mem[a + 1]},{mem[a + 2]}}}')
            a += 3
        elif c == 2:
            out.append(f'{{attr ${mem[a + 1]:02X}}}')
            a += 2
        elif c == 3:
            out.append('{nl}')
            a += 1
        elif c == 4:
            out.append(f'{{size ${mem[a + 1]:02X}}}')
            a += 2
        else:
            out.append(chr(c) if 0x20 <= c < 0x7F else f'{{${c:02X}}}')
            a += 1
    return a, ''.join(out)


def strings():
    mem = image()
    print('| Address | Called from | Bytes |')
    print('| --- | --- | --- |')
    for a in range(BASE, 0xFCE9 - 2):
        if mem[a] == 0xCD and mem[a + 1] | mem[a + 2] << 8 in (PRINT_INLINE, KEY_PROMPT):
            start = a + 3
            end, text = decode(mem, start)
            if end - start > 400:
                continue
            print(f'| `${start:04X}` | `${a:04X}` | {text} |')


if __name__ == '__main__':
    if sys.argv[1] == 'font':
        font(sys.argv[2])
    else:
        strings()

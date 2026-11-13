#!/usr/bin/env python3
"""Stage 5's own resource format (src/res/stage5/), loaded by tools/res_formats.py.

    NAME (under stage5/)        editable form            what
    textlines-NAME.bin          textlines-NAME.txt       the intro's or the ending's seven lines (DrawTextLine $8EDD)

**textlines-NAME.txt.** One text line a line: `COLUMN PIXEL BYTE2 TEXT`. Each line of the original is three header
bytes (the start column in bytes 0-11 of the 12-byte page, the start pixel offset 0-7, a third byte DrawTextLine
keeps in `$FE4B` and never uses), the characters, then a 0. The characters are A-Z, the space and `\\`, which the
font draws as a full stop (TextFont glyph 27); the text keeps `\\` as the bytes have it. Lines starting with `#` are
comments.
"""


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').splitlines() if ln.strip() and not ln.startswith('#')]


def textlines_out(name, data):
    out = ['# %s: one text line a line: COLUMN PIXEL BYTE2 TEXT (tools/res_stage5.py); `\\` is the full stop'
           % name.split('/')[0]]
    i = 0
    while i < len(data):
        end = data.index(0, i + 3)
        text = data[i + 3:end]
        if any(not (65 <= b <= 90 or b in (32, 92)) for b in text):
            raise ValueError('textlines: a character outside A-Z, space and \\ at %d' % i)
        out.append('%d %d %d %s' % (data[i], data[i + 1], data[i + 2], text.decode('ascii')))
        i = end + 1
    return ('\n'.join(out) + '\n').encode('utf-8')


def textlines_in(name, raw):
    out = bytearray()
    for ln in lines_of(raw):
        col, pix, b2, text = ln.split(' ', 3)
        out += bytes([int(col), int(pix), int(b2)]) + text.encode('ascii') + b'\0'
    return bytes(out)


FORMATS = [
    (r'^stage5/textlines-[a-z0-9-]+\.bin$', '.txt', textlines_out, textlines_in),
]

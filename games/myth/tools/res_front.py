#!/usr/bin/env python3
"""The resource formats of the front (the main block `$6C3F-$A83E`: logo, credits, menu; src/front/front.ann), loaded
by tools/res_formats.py. The files and their readers: src/res/front/README.md and src/res/front-texts/README.md.

    front/logo           the logo screen (6912 bytes): a 256 x 192 colour-cell PNG
    front/font-*         the two PrintText fonts (8 bytes a glyph: width mask, 7 rows): a PNG of glyph cells
    front/keyboard       ScanKeyboard's 8 half-row ports and their 40 key characters: CSV
    front/shimmer, *-bar attribute bytes: text, one `$hh` a byte
    front-texts/*        PrintText strings (font, start byte, pixel shift, screen line, text, 0): text
    front-texts/key-names, old-define-keys: text, one quoted string (or parameters and a string) a line

Text strings are quoted, with `\\xNN` for any byte outside printable ASCII and `\\"`, `\\\\` escaped.
"""
import io
import json

# ---------------------------------------------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------------------------------------------


def quote(data):
    out = '"'
    for b in data:
        c = chr(b)
        if c in '"\\':
            out += '\\' + c
        elif 0x20 <= b < 0x7F:
            out += c
        else:
            out += '\\x%02X' % b
    return out + '"'


def unquote(t):
    t = t.strip()
    assert t[0] == '"' and t[-1] == '"', t
    t = t[1:-1]
    out = bytearray()
    i = 0
    while i < len(t):
        if t[i] == '\\':
            if t[i + 1] == 'x':
                out.append(int(t[i + 2:i + 4], 16))
                i += 4
            else:
                out.append(ord(t[i + 1]))
                i += 2
        else:
            out.append(ord(t[i]))
            i += 1
    return bytes(out)


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').splitlines() if ln.strip() and not ln.lstrip().startswith('#')]


def num(t):
    t = t.strip()
    if t.startswith('$'):
        return int(t[1:], 16)
    return int(t, 0)


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


# ---------------------------------------------------------------------------------------------------------------
# PrintText strings: font, start byte, pixel shift, screen line, text, 0
# ---------------------------------------------------------------------------------------------------------------
FONTS = {0: 'small', 1: 'large'}


def print_text_out(name, data):
    assert data[-1] == 0 and 0 not in data[4:-1], name
    font = FONTS.get(data[0], str(data[0]))
    return text_file([
        '# PrintText $9D72 parameters (src/res/front-texts/README.md)',
        'font: %s' % font,
        'column: %d' % data[1],
        'shift: %d' % data[2],
        'line: %d' % data[3],
        'text: %s' % quote(data[4:-1]),
    ])


def print_text_in(name, raw):
    kv = {}
    for ln in lines_of(raw):
        k, v = ln.split(':', 1)
        kv[k.strip()] = v.strip()
    rev = {v: k for k, v in FONTS.items()}
    font = rev[kv['font']] if kv['font'] in rev else num(kv['font'])
    return bytes([font, num(kv['column']), num(kv['shift']), num(kv['line'])]) + unquote(kv['text']) + b'\0'


def key_names_out(name, data):
    assert len(data) % 7 == 0, name
    return text_file(['# KeyNames $97B5: 7 bytes a name, UP DOWN LEFT RIGHT FIRE (the readers KeyUp to KeyFire)'] +
                     [quote(data[i:i + 7]) for i in range(0, len(data), 7)])


def key_names_in(name, raw):
    out = b''
    for ln in lines_of(raw):
        s = unquote(ln)
        assert len(s) == 7, ln
        out += s
    return out


def old_texts_out(name, data):
    lines = ['# OldDefineKeysTexts $A124 (never read): two parameter bytes, then the text, ended by 0']
    i = 0
    while i < len(data):
        j = data.index(0, i + 2)
        lines.append('%d %d %s' % (data[i], data[i + 1], quote(data[i + 2:j])))
        i = j + 1
    return text_file(lines)


def old_texts_in(name, raw):
    out = b''
    for ln in lines_of(raw):
        a, b, t = ln.split(' ', 2)
        out += bytes([num(a), num(b)]) + unquote(t) + b'\0'
    return out


# ---------------------------------------------------------------------------------------------------------------
# Attribute bytes and the keyboard table
# ---------------------------------------------------------------------------------------------------------------
ATTR_NOTES = {
    'front/shimmer.bin': 'ShimmerColours $78E2: 32-byte pattern three times; ShimmerFrame reads bytes 0-59',
    'front/menu-bar.bin': 'MenuBarColours $9A33: the menu bar attribute of pass D AND 7',
    'front/joystick-bar.bin': 'JoystickBarColours $9A8C: the joystick bar attribute of pass D AND 7',
}


def attrs_out(name, data):
    lines = ['# ' + ATTR_NOTES.get(name, name) + ' (FLASH BRIGHT PAPER INK bits 7, 6, 5-3, 2-0)']
    for i in range(0, len(data), 16):
        lines.append(' '.join('$%02X' % b for b in data[i:i + 16]))
    return text_file(lines)


def attrs_in(name, raw):
    return bytes(num(t) for ln in lines_of(raw) for t in ln.split())


def keyboard_out(name, data):
    assert len(data) == 56, name
    lines = ['# KeyRowPorts $9970 and KeyRowChars $9980: the half-row port, then its keys bit 0 first',
             '# ("-" CAPS SHIFT, "+" ENTER, "/" SPACE, "." SYMBOL SHIFT)', 'port,keys']
    for r in range(8):
        port = data[2 * r] | data[2 * r + 1] << 8
        keys = data[16 + 5 * r:21 + 5 * r]
        assert all(0x21 <= b < 0x7F and b != 0x2C for b in keys), keys
        lines.append('$%04X,%s' % (port, keys.decode('ascii')))
    return text_file(lines)


def keyboard_in(name, raw):
    ports, keys = b'', b''
    for ln in lines_of(raw)[1:]:
        p, k = ln.split(',')
        v = num(p)
        ports += bytes([v & 0xFF, v >> 8])
        assert len(k) == 5, ln
        keys += k.encode('ascii')
    return ports + keys


# ---------------------------------------------------------------------------------------------------------------
# PNGs
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return [((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v]


# The colour-cell palette: index = flash x 32 + ink x 16 + bright x 8 + colour, where ink says whether the pixel is
# set (its colour is the cell's ink) or clear (the cell's paper).
CELL_PALETTE = []
for _i in range(64):
    CELL_PALETTE += zx_rgb(_i & 7, (_i >> 3) & 1)


def png_bytes(img, key, meta):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    info.add_text(key, json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_open(raw, key):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    return img, img.load(), json.loads(img.text[key])


def screen_addr(y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)


def logo_out(name, data):
    from PIL import Image
    assert len(data) == 6912, name
    img = Image.new('P', (256, 192), 0)
    img.putpalette(CELL_PALETTE + [0] * (768 - len(CELL_PALETTE)))
    px = img.load()
    hidden = []
    for row in range(24):
        for col in range(32):
            a = data[6144 + row * 32 + col]
            flash, bright, paper, ink = a >> 7, (a >> 6) & 1, (a >> 3) & 7, a & 7
            bits = [data[screen_addr(row * 8 + k) + col] for k in range(8)]
            if all(b == 0 for b in bits):
                hidden.append([row * 32 + col, 'ink', ink])
            elif all(b == 0xFF for b in bits):
                hidden.append([row * 32 + col, 'paper', paper])
            for k in range(8):
                for x in range(8):
                    on = (bits[k] >> (7 - x)) & 1
                    px[col * 8 + x, row * 8 + k] = flash * 32 + on * 16 + bright * 8 + (ink if on else paper)
    meta = {'format': 'palette index = flash*32 + set*16 + bright*8 + colour; hidden: the colour a cell does not show',
            'hidden': hidden}
    return png_bytes(img, 'front-logo', meta)


def logo_in(name, raw):
    img, px, meta = png_open(raw, 'front-logo')
    assert img.size == (256, 192), name
    hidden = {c: (kind, v) for c, kind, v in meta['hidden']}
    out = bytearray(6912)
    for row in range(24):
        for col in range(32):
            ink = paper = None
            flash = bright = None
            for k in range(8):
                b = 0
                for x in range(8):
                    i = px[col * 8 + x, row * 8 + k]
                    f, on, br, c = i >> 5, (i >> 4) & 1, (i >> 3) & 1, i & 7
                    assert flash in (None, f) and bright in (None, br), (name, row, col)
                    flash, bright = f, br
                    if on:
                        assert ink in (None, c), (name, row, col)
                        ink = c
                    else:
                        assert paper in (None, c), (name, row, col)
                        paper = c
                    b = b << 1 | on
                out[screen_addr(row * 8 + k) + col] = b
            h = hidden.get(row * 32 + col)
            if h:
                if h[0] == 'ink':
                    ink = h[1]
                else:
                    paper = h[1]
            out[6144 + row * 32 + col] = flash << 7 | bright << 6 | paper << 3 | ink
    return bytes(out)


# Fonts: a cell of 8 x 8 a glyph and a grey line between cells, 10 glyphs a row; the cell's top row is the width
# mask (red for a set bit), rows 1-7 the glyph (black on white).
FONT_PALETTE = [255, 255, 255, 0, 0, 0, 215, 0, 0, 128, 128, 128]
FONT_GLYPHS = {'front/font-small.bin': 'A-Z, space, 0-9', 'front/font-large.bin': 'A-Z, space'}
PER_ROW = 10


def font_out(name, data):
    from PIL import Image
    assert len(data) % 8 == 0, name
    n = len(data) // 8
    rows = (n + PER_ROW - 1) // PER_ROW
    img = Image.new('P', (1 + PER_ROW * 9, 1 + rows * 9), 3)
    img.putpalette(FONT_PALETTE + [0] * (768 - len(FONT_PALETTE)))
    px = img.load()
    for g in range(n):
        x0, y0 = 1 + (g % PER_ROW) * 9, 1 + (g // PER_ROW) * 9
        for k in range(8):
            b = data[g * 8 + k]
            for x in range(8):
                on = (b >> (7 - x)) & 1
                px[x0 + x, y0 + k] = (2 if k == 0 else 1) if on else 0
    meta = {'glyphs': n, 'order': FONT_GLYPHS.get(name, ''),
            'format': 'each cell: top row the width mask (red), rows 1-7 the glyph'}
    return png_bytes(img, 'front-font', meta)


def font_in(name, raw):
    img, px, meta = png_open(raw, 'front-font')
    out = bytearray()
    for g in range(meta['glyphs']):
        x0, y0 = 1 + (g % PER_ROW) * 9, 1 + (g // PER_ROW) * 9
        for k in range(8):
            b = 0
            for x in range(8):
                v = px[x0 + x, y0 + k]
                assert v in (0, 1, 2), (name, g, k, x)
                b = b << 1 | (v != 0)
            out.append(b)
    return bytes(out)


FORMATS = [
    (r'^front/logo\.bin$', '.png', logo_out, logo_in),
    (r'^front/font-[a-z]+\.bin$', '.png', font_out, font_in),
    (r'^front/keyboard\.bin$', '.csv', keyboard_out, keyboard_in),
    (r'^front/(shimmer|menu-bar|joystick-bar)\.bin$', '.txt', attrs_out, attrs_in),
    (r'^front-texts/key-names\.bin$', '.txt', key_names_out, key_names_in),
    (r'^front-texts/old-define-keys\.bin$', '.txt', old_texts_out, old_texts_in),
    (r'^front-texts/[a-z0-9-]+\.bin$', '.txt', print_text_out, print_text_in),
]

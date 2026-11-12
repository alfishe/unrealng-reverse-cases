#!/usr/bin/env python3
"""The resources only a variant has (its own .ann parts, variants/NAME/parts), in editable forms; tools/res_formats.py
calls it beside res_gfx / res_tables / res_text. Each kind reuses the original's converter where the bytes have the
same layout:
- graphics/sky-picture.bin: zyxskybt's Skynet picture, 40 pixel rows of 20 bytes (a 160x40 sheet, tools/res_gfx.py);
- graphics/font-cyrillic.bin: zyxskybt's 32 Cyrillic letters, KOI-7 order ($60-$7F: Ю А ... Ч, then ©), 8x8;
- tables/sky-picture-attrs.bin: the picture's attributes, 5 rows of 20 cells (the logo attributes' text form);
- texts/sky-scroll.bin: zyxskybt's scrolling text, kept enciphered as the file holds it (ScrollInit `$A6B0`
  deciphers each byte e as CPL(RRCA e) XOR `$66` and hangs unless the plain bytes sum to `$AA`). The text is
  UTF-8: ASCII `$20-$5F`, `$60-$7F` as KOI-7 Cyrillic (`$7F` the © glyph), `{XX}` any other byte (`{01}`: the end,
  the scroller starts again).
"""
import res_gfx
import res_tables

SHEETS = {'graphics/sky-picture.bin': (160, 40, 1), 'graphics/font-cyrillic.bin': (8, 8, 16)}
ATTRS = {'tables/sky-picture-attrs.bin': '# zyxskybt: the Skynet picture\'s attributes, 5 rows of 20 cells, copied by '
                                         'DrawSkyPicture $7391 to $5A66 (columns 6-25, rows 19-23).\n'}
TEXTS = {'texts/sky-scroll.bin'}
KOI7 = 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ©'
CHECKSUM = 0xAA


def handles(name):
    return name in SHEETS or name in ATTRS or name in TEXTS


def decipher(e):
    r = ((e >> 1) | (e << 7)) & 0xFF
    return (~r & 0xFF) ^ 0x66


def encipher(p):
    r = (~(p ^ 0x66)) & 0xFF
    return ((r << 1) | (r >> 7)) & 0xFF


def to_editable(name, data):
    if name in SHEETS:
        res_gfx.SHEETS.setdefault(name, SHEETS[name])
        return res_gfx.to_editable(name, data)
    if name in ATTRS:
        suffix, out = res_tables.to_editable('tables/logo-attrs.bin', data)
        body = b''.join(line + b'\n' for line in out.split(b'\n') if line and not line.startswith(b'#'))
        return suffix, ATTRS[name].encode() + body
    plain = bytes(decipher(e) for e in data)
    text = ''.join(KOI7[c - 0x60] if 0x60 <= c < 0x80 else chr(c) if 0x20 <= c < 0x60 and c not in (0x7B, 0x7D)
                   else '{%02X}' % c for c in plain)
    return '.txt', (text + '\n').encode()


def from_editable(name, raw):
    if name in SHEETS:
        return res_gfx.from_editable(name, raw)
    if name in ATTRS:
        return res_tables.from_editable('tables/logo-attrs.bin', raw)
    text = raw.decode().rstrip('\n')
    out, i = bytearray(), 0
    while i < len(text):
        if text[i] == '{':
            j = text.index('}', i)
            out.append(int(text[i + 1:j], 16))
            i = j + 1
            continue
        c = text[i]
        out.append(0x60 + KOI7.index(c) if c in KOI7 else ord(c))
        i += 1
    if sum(out) & 0xFF != CHECKSUM:
        raise ValueError('%s: the plain bytes sum to $%02X, ScrollInit wants $%02X (it hangs otherwise)'
                         % (name, sum(out) & 0xFF, CHECKSUM))
    return bytes(encipher(p) for p in out)

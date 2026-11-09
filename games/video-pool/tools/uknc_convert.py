#!/usr/bin/env python3
"""Convert the case's resources (src/res) to the UKNC port's formats (doc 14, 14.5).

    python3 tools/uknc_convert.py [--out work/docs/vpD/uknc] [--check]

Writes, for each resource, a raw little-endian binary (.bin) and a MACRO-11 include (.mac, octal .WORD / .BYTE):

- balls16: the seven balls pre-shifted 16 times for word XOR in the UKNC's 320-pixel mode: 7 balls x 16 shifts x
  15 lines x 2 words = 6720 bytes. Pixel x of a line is bit (x AND 15) of word x / 16: on the UKNC the leftmost pixel
  of a byte is bit 0 (UKNCBTL Emulator.cpp, PrepareScreenRGB32), on the Spectrum it is bit 7. Index = (shift x 7 +
  ball) x 60 bytes. Only the 15 lines of the disc are kept (the Spectrum's 16th line is empty).
- font: the 36 glyphs a-z, 0-9, 8 bytes each, each byte bit-reversed (bit 0 = the leftmost pixel).
- tables: ContactTable, Table8x8, FrictionTable, CollisionRecords: the same bytes as on the Spectrum. The PDP-11 is
  little-endian like the Z80, so the 8.8 words of CollisionRecords need no change.

--check proves the conversion: shifts 0-7 of balls16, with the bit order turned back, equal the Spectrum sheet's
eight pre-shifted frames of every ball (BallSprites $D000), and the tables round-trip through res_formats.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import res_formats as R  # noqa: E402

RES = os.path.join(CASE, 'src', 'res')
# MACRO-11 keeps six characters of a symbol
LABELS = {'balls16': 'BALLS', 'font': 'FONT', 'ContactTable': 'CONTAB', 'Table8x8': 'JAWTAB',
          'FrictionTable': 'FRICTB', 'CollisionRecords': 'COLREC'}
BALLS, SHIFTS, LINES = 7, 16, 15


def rev8(b):
    return int('{:08b}'.format(b)[::-1], 2)


def spectrum_balls():
    """The Spectrum sheet: 56 frames of 3 bytes x 16 lines, frame = shift x 7 + ball"""
    return R.png_to_sheet(open(os.path.join(RES, 'graphics', 'BallSprites.png'), 'rb').read())


def ball_rows(sheet, ball):
    """Ball `ball` unshifted: 16 rows as integers, bit 23 - x = pixel x (x 0-23, Spectrum order)"""
    f = sheet[ball * 48:(ball + 1) * 48]
    return [f[3 * y] << 16 | f[3 * y + 1] << 8 | f[3 * y + 2] for y in range(16)]


def balls16(sheet):
    """7 balls x 16 shifts x 15 lines x 2 words, UKNC order: pixel x = bit x of the 32-bit line (low word first)"""
    out = bytearray()
    for shift in range(SHIFTS):
        for ball in range(BALLS):
            for row in ball_rows(sheet, ball)[:LINES]:
                line = 0
                for x in range(24):
                    if row >> (23 - x) & 1:
                        line |= 1 << (x + shift)
                if line >> 32:
                    raise SystemExit(f'ball {ball} shift {shift}: wider than two words')
                out += (line & 0xFFFF).to_bytes(2, 'little') + (line >> 16).to_bytes(2, 'little')
    return bytes(out)


def font():
    raw = R.png_to_sheet(open(os.path.join(RES, 'fonts', 'Font.png'), 'rb').read())
    return bytes(rev8(b) for b in raw)


def tables():
    t = {}
    for name in ('ContactTable', 'Table8x8', 'FrictionTable', 'CollisionRecords'):
        _suffix, _to_ed, from_ed = R.editable(f'tables/{name}.bin')
        t[name] = from_ed(name, open(os.path.join(RES, 'tables', name + '.csv'), 'rb').read())
    return t


def mac(label, data, words, per_line=8):
    """A MACRO-11 include: label, then .WORD (or .BYTE) lines in octal"""
    lines = [f'; {label}: {len(data)} bytes, from src/res by tools/uknc_convert.py', f'{label}::']
    if words:
        vals = [data[i] | data[i + 1] << 8 for i in range(0, len(data), 2)]
        for i in range(0, len(vals), per_line):
            lines.append('\t.WORD\t' + ', '.join(f'{v:06o}' for v in vals[i:i + per_line]))
    else:
        for i in range(0, len(data), per_line):
            lines.append('\t.BYTE\t' + ', '.join(f'{v:03o}' for v in data[i:i + per_line]))
    return '\n'.join(lines) + '\n'


def check(sheet, b16, tabs):
    bad = 0
    for shift in range(8):
        for ball in range(BALLS):
            spec = sheet[(shift * 7 + ball) * 48:(shift * 7 + ball + 1) * 48]
            base = (shift * 7 + ball) * LINES * 4
            for y in range(LINES):
                w0 = b16[base + 4 * y] | b16[base + 4 * y + 1] << 8
                w1 = b16[base + 4 * y + 2] | b16[base + 4 * y + 3] << 8
                line = w0 | w1 << 16
                want = spec[3 * y] << 16 | spec[3 * y + 1] << 8 | spec[3 * y + 2]
                got = 0
                for x in range(24):
                    if line >> x & 1:
                        got |= 1 << (23 - x)
                if got != want or line >> 24:
                    bad += 1
    for name, data in tabs.items():
        to_ed, from_ed = R.TABLES[f'tables/{name}.bin']
        if from_ed(to_ed(data)) != data:
            bad += 1
    print(f'check: shifts 0-7 of 7 balls against the Spectrum sheet, 4 tables: {"OK" if not bad else f"{bad} BAD"}')
    return bad == 0


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'work', 'docs', 'vpD', 'uknc'))
    p.add_argument('--check', action='store_true')
    a = p.parse_args()
    sheet = spectrum_balls()
    b16 = balls16(sheet)
    fnt = font()
    tabs = tables()
    os.makedirs(a.out, exist_ok=True)
    items = [('balls16', b16, True), ('font', fnt, False)] + [(n, d, n == 'CollisionRecords') for n, d in tabs.items()]
    for name, data, words in items:
        open(os.path.join(a.out, name + '.bin'), 'wb').write(data)
        open(os.path.join(a.out, name + '.mac'), 'w').write(mac(LABELS[name], data, words))
        print(f'{name}: {len(data)} bytes')
    if a.check and not check(sheet, b16, tabs):
        sys.exit(1)


if __name__ == '__main__':
    main()

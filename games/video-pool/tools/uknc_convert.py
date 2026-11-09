#!/usr/bin/env python3
"""Convert the case's resources (src/res) to the UKNC port's formats (doc 14, 14.5).

    python3 tools/uknc_convert.py [--out work/docs/vpD/uknc] [--rom 48.rom] [--image build/game.bin] [--check]

Writes, for each resource, a raw little-endian binary (.bin) and a MACRO-11 include (.mac, octal .WORD / .BYTE):

- balls16: the seven balls pre-shifted 16 times for word XOR in the UKNC's 320-pixel mode: 7 balls x 16 shifts x
  15 lines x 2 words = 6720 bytes. Pixel x of a line is bit (x AND 15) of word x / 16: on the UKNC the leftmost pixel
  of a byte is bit 0 (UKNCBTL Emulator.cpp, PrepareScreenRGB32), on the Spectrum it is bit 7. Index = (shift x 7 +
  ball) x 60 bytes. Only the 15 lines of the disc are kept (the Spectrum's 16th line is empty).
- font: the 36 glyphs a-z, 0-9, 8 bytes each, each byte bit-reversed (bit 0 = the leftmost pixel).
- tables: ContactTable, Table8x8, FrictionTable, CollisionRecords: the same bytes as on the Spectrum. The PDP-11 is
  little-endian like the Z80, so the 8.8 words of CollisionRecords need no change.
- glyphs: every glyph the game prints, 8 bytes each, bit-reversed like font: the 36 of the game's font (index 0-25
  a-z, 26-35 0-9), then the ROM's CHAR_SET glyphs the game uses (ROM_CODES: the characters of the texts and of the
  code's own prints: the name entry's "_" and grid, the key names' quotes and "/", the pocket marks' "x"), cut from a
  Spectrum 48K ROM image (--rom, default data/rom/48.rom of the unreal-ng checkout), then the copyright glyph $7F
  (fonts/CopyrightGlyph.png).
- texts: the 14 print-record files of src/res/text in the port's string format: each record row, column, attribute,
  length (the Spectrum's character cells and attribute byte, for the port's PrintChar to map), then one byte a
  character, its index in glyphs (no ROM or Spectrum character codes left); one label a file (TEXTS).
- sounds: the eight fixed sounds of doc 9, 9.6 (ball, cushion, pocket tone; click, name pick, last-shot beep, the two
  foul notes) and the first count-up tick, as the PPU timer's half-period count at 4 us and the cycle count, two
  words a sound. The parameters are read from the code's immediate operands in the built image (--image, default
  build/game.bin: there is no sound table, doc 9.6): SoundLoop's half periods 37 B + 61 / 37 B + 77 T (their mean),
  BEEPER's 4 (HL + 30.125) T, at 3.5 MHz; cycles C, DE + 1, and 6000 / 1200 + 1 for the count-up tick.

--check proves the conversion: shifts 0-7 of balls16, with the bit order turned back, equal the Spectrum sheet's
eight pre-shifted frames of every ball (BallSprites $D000), and the tables round-trip through res_formats; the texts
turned back through glyphs give the bytes of src/res/text and every character has a glyph; the ROM glyphs are the
ROM's (its "A" at $3D00 + 8 x $21 checked against the 48K ROM's bytes 003c42427e424200; the game's own copyright
glyph differs from the ROM's, so it is not the check); every
sound operand sits behind its opcode in the image, each count is within half a count of the Spectrum's half period
and fits the timer's 12 bits.
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
          'FrictionTable': 'FRICTB', 'CollisionRecords': 'COLREC', 'glyphs': 'GLYPHS', 'texts': 'TEXTS',
          'sounds': 'SOUNDS'}
# the print-record files and their labels inside texts.mac
TEXT_LABELS = {'HudTexts': 'HUDTXT', 'HudLastShot': 'HUDLST', 'GameOverTexts': 'GOVTXT', 'FrameBanner': 'FRMBAN',
               'PlayerBannerTexts': 'PLYBAN', 'FoulTexts': 'FOULTX', 'ScoreBlank': 'SCRBLK', 'HofTitle': 'HOFTTL',
               'PromptLeft': 'PRMPTL', 'MenuTitle': 'MENUTL', 'KeysLine': 'KEYSLN', 'VariationsTitle': 'VARTTL',
               'PresentsTexts': 'PRSTXT', 'EditorTexts': 'EDITXT'}
CHAR_SET = 0x3D00
# the ROM characters the code prints on its own, besides the texts: "_" (the name entry's empty place, NameBuffer),
# "'" and "/" (KeyName $B626), "x" (the pocket marks: CHAR_SET+704, $9D8C), space and "." (the name-entry grid)
CODE_ROM_CODES = {0x5F, 0x27, 0x2F, 0x78, 0x20, 0x2E}
IMAGE_BASE = 0x8000
# (name, kind, address of the operand's opcode): kind loop = LD BC,C+256B of SoundLoop; beeper = LD HL,period then
# LD DE,cycles-1 at +3; tally = the count-up's first tick, LD HL,1200 (TallyPitch's start) and LD HL,6000 at $99DC
SOUNDS = [('ball tone', 'loop', 0x8077), ('cushion tone', 'loop', 0x807D), ('pocket tone', 'loop', 0x8083),
          ('key click', 'beeper', 0xAF0C), ('name pick', 'beeper', 0xAF2F), ('first count-up tick', 'tally', 0x9975),
          ('last-shot beep', 'beeper', 0x9CAC), ('foul note 1', 'beeper', 0x978B), ('foul note 2', 'beeper', 0x9799)]
T_US = 3.5  # Spectrum T states a microsecond
TIMER_US = 4
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


def word_at(img, a, opcode):
    o = a - IMAGE_BASE
    if img[o] != opcode:
        raise SystemExit(f'uknc_convert: no opcode ${opcode:02X} at ${a:04X} (the image moved?)')
    return img[o + 1] | img[o + 2] << 8


def sound_params(img):
    """[(name, Spectrum half period in T, cycles)] from the code's immediate operands"""
    out = []
    for name, kind, a in SOUNDS:
        if kind == 'loop':
            bc = word_at(img, a, 0x01)
            b, c = bc >> 8, bc & 255
            out.append((name, 37 * b + 69, c))  # the mean of 37 B + 61 and 37 B + 77
        elif kind == 'beeper':
            out.append((name, 4 * (word_at(img, a, 0x21) + 30.125), word_at(img, a + 3, 0x11) + 1))
        else:
            pitch = word_at(img, a, 0x21)
            out.append((name, 4 * (pitch + 30.125), word_at(img, 0x99DC, 0x21) // pitch + 1))
    return out


def sounds(params):
    """two words a sound: the timer's half-period count at 4 us, the cycles"""
    out = bytearray()
    for _name, t, cycles in params:
        out += round(t / T_US / TIMER_US).to_bytes(2, 'little') + cycles.to_bytes(2, 'little')
    return bytes(out)


def text_files():
    """{name: the print-record bytes of src/res/text/NAME.txt}"""
    return {n: R.print_in(open(os.path.join(RES, 'text', n + '.txt'), 'rb').read()) for n in TEXT_LABELS}


def records(data):
    p = 0
    while p < len(data):
        n = data[p + 3]
        yield data[p:p + 4], data[p + 4:p + 4 + n]
        p += 4 + n


def rom_codes(texts):
    codes = set(CODE_ROM_CODES)
    for data in texts.values():
        for _head, chars in records(data):
            codes |= {c for c in chars if not (0x61 <= c <= 0x7A or 0x30 <= c <= 0x39 or c == 0x7F)}
    return sorted(codes)


def glyph_index(codes):
    """the text character code -> its index in glyphs (a-z, 0-9 the game's font, $7F the copyright glyph, the rest
    the ROM's); the ROM's "x" of the pocket marks has an index of its own, past the codes the texts can reach"""
    index = {0x61 + k: k for k in range(26)}
    index.update({0x30 + k: 26 + k for k in range(10)})
    for k, c in enumerate(codes):
        index.setdefault(c, 36 + k)
    index[0x7F] = 36 + len(codes)
    return index


def glyphs(rom, codes):
    font_raw = R.png_to_sheet(open(os.path.join(RES, 'fonts', 'Font.png'), 'rb').read())
    copy = R.png_to_sheet(open(os.path.join(RES, 'fonts', 'CopyrightGlyph.png'), 'rb').read())
    raw = font_raw + b''.join(rom[CHAR_SET + 8 * (c - 0x20):CHAR_SET + 8 * (c - 0x1F)] for c in codes) + copy
    return bytes(rev8(b) for b in raw)


def texts(files, index):
    out, starts = bytearray(), {}
    for name, data in files.items():
        starts[name] = len(out)
        for head, chars in records(data):
            out += head + bytes(index[c] for c in chars)
    return bytes(out), starts


def texts_mac(data, starts):
    lines = [f'; TEXTS: {len(data)} bytes, the print records of src/res/text by tools/uknc_convert.py: row, column,',
             '; attribute, length, then the characters as indexes into GLYPHS', 'TEXTS::']
    order = list(starts) + [None]
    for k, name in enumerate(order[:-1]):
        lo = starts[name]
        hi = starts[order[k + 1]] if order[k + 1] else len(data)
        lines.append(f'{TEXT_LABELS[name]}::\t\t; {name}.txt')
        for i in range(lo, hi, 8):
            lines.append('\t.BYTE\t' + ', '.join(f'{v:03o}' for v in data[i:min(i + 8, hi)]))
    return '\n'.join(lines) + '\n'


def default_rom():
    sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
    import kitlib  # noqa: E402
    return os.path.join(kitlib.unreal_root(), 'data', 'rom', '48.rom')


def mac(label, data, words, per_line=8, source='src/res'):
    """A MACRO-11 include: label, then .WORD (or .BYTE) lines in octal"""
    lines = [f'; {label}: {len(data)} bytes, from {source} by tools/uknc_convert.py', f'{label}::']
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


def check_more(files, index, codes, glyph_bytes, text_bytes, starts, rom, params, snd):
    bad = 0
    back = {v: k for k, v in index.items()}
    names = list(starts) + [None]
    for k, name in enumerate(names[:-1]):
        hi = starts[names[k + 1]] if names[k + 1] else len(text_bytes)
        rebuilt = bytearray()
        for head, chars in records(text_bytes[starts[name]:hi]):
            rebuilt += head + bytes(back[c] for c in chars)
        if bytes(rebuilt) != files[name]:
            bad += 1
    missing = {c for d in files.values() for _h, ch in records(d) for c in ch if c not in index}
    bad += len(missing)
    n = 0
    for k, c in enumerate(codes):
        g = bytes(rev8(b) for b in glyph_bytes[8 * (36 + k):8 * (37 + k)])
        n += 1
        if g != rom[CHAR_SET + 8 * (c - 0x20):CHAR_SET + 8 * (c - 0x1F)]:
            bad += 1
    if rom[CHAR_SET + 8 * 0x21:CHAR_SET + 8 * 0x22] != bytes.fromhex('003c42427e424200') or len(rom) < 0x4000:
        print('check: no 48K ROM character set at $3D00 (its "A")')
        bad += 1
    for k, (name, t, cycles) in enumerate(params):
        count = snd[4 * k] | snd[4 * k + 1] << 8
        if abs(count * TIMER_US * T_US - t) > TIMER_US * T_US / 2 or count > 0o7777 or cycles < 1:
            print(f'check: {name}: count {count} for {t} T')
            bad += 1
    print(f'check: {sum(1 for d in files.values() for _ in records(d))} text records of {len(files)} files back to '
          f'src/res/text, {n} ROM glyphs, {len(params)} sounds: {"OK" if not bad else f"{bad} BAD"}')
    return bad == 0


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'work', 'docs', 'vpD', 'uknc'))
    p.add_argument('--rom', help='a Spectrum 48K ROM image (default: data/rom/48.rom of the unreal-ng checkout)')
    p.add_argument('--image', default=os.path.join(CASE, 'build', 'game.bin'),
                   help='the built game $8000-$E1A7 (tools/build.sh), for the sound operands')
    p.add_argument('--check', action='store_true')
    a = p.parse_args()
    sheet = spectrum_balls()
    b16 = balls16(sheet)
    fnt = font()
    tabs = tables()
    rom = open(a.rom or default_rom(), 'rb').read()
    files = text_files()
    codes = rom_codes(files)
    index = glyph_index(codes)
    gly = glyphs(rom, codes)
    txt, starts = texts(files, index)
    params = sound_params(open(a.image, 'rb').read())
    snd = sounds(params)
    os.makedirs(a.out, exist_ok=True)
    items = [('balls16', b16, True), ('font', fnt, False)] + [(n, d, n == 'CollisionRecords') for n, d in tabs.items()]
    items += [('glyphs', gly, False), ('texts', txt, False), ('sounds', snd, True)]
    for name, data, words in items:
        open(os.path.join(a.out, name + '.bin'), 'wb').write(data)
        if name == 'texts':
            text = texts_mac(data, starts)
        elif name == 'sounds':
            text = mac(LABELS[name], data, words, 2, 'the code\'s operands (half-period count at 4 us, cycles)')
        elif name == 'glyphs':
            text = mac(LABELS[name], data, words, 8, 'src/res and the ROM\'s CHAR_SET')
        else:
            text = mac(LABELS[name], data, words)
        open(os.path.join(a.out, name + '.mac'), 'w').write(text)
        print(f'{name}: {len(data)} bytes')
    print('glyphs: %d = 36 font + %d ROM (%s) + the copyright glyph' % (
        len(gly) // 8, len(codes), ''.join(chr(c) for c in codes)))
    for (name, t, cycles), k in zip(params, range(len(params))):
        print(f'  sound {name}: half period {t:g} T, count {snd[4 * k] | snd[4 * k + 1] << 8} at 4 us, {cycles} cycles')
    if a.check:
        ok = check(sheet, b16, tabs)
        if not check_more(files, index, codes, gly, txt, starts, rom, params, snd) or not ok:
            sys.exit(1)


if __name__ == '__main__':
    main()

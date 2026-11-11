#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the game's and the bank parts').

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py export                    # src/res/**.bin / .scr with a format -> editable files
    python3 tools/res_formats.py check                     # every resource builds to its original bytes

The formats (each folder's README.md lists its files):
- FORMATS below: a name pattern of build/res, its editable files in src/res, and the two conversions.
- A Spectrum screen (6912 bytes) is a 256 x 192 indexed PNG whose 64-entry palette is
  index = flash x 32 + ink x 16 + bright x 8 + colour: the picture shows the screen without the flash, and each
  pixel's index says ink or paper, so the bytes come back exactly. A cell whose 64 pixels are all paper (or all ink)
  cannot show its other colour; the PNG text chunk `bc-hidden` keeps those cells' attributes (row,column,hex).
- pictures/NAME.bin (bank 7, UnpackPicture `$FE95`): NAME.png, the unpacked screen as above, and NAME.parse.txt,
  the packer's parse (tools/bank7pic.py). The block is built from the parse when the parse unpacks to the PNG's
  screen, else the PNG is packed again by tools/bank7pic.py pack (a valid block, other bytes).
- fonts/NAME.bin: NAME.png, a sheet of 8-pixel glyphs (FONT_ROWS gives the rows of each font).
- missions/NN-NAME.bin: NN-NAME.txt (tools/res_missions.py), with NN-NAME.preview.png the world's figure;
  missions/catalogue.bin: catalogue.txt, as a text below.
- texts/NAME.bin: NAME.txt, UTF-8 with {XX} for the bytes that are not printable ASCII (PrintString `$6FB3`).
- music/tune.bin: tune.txt, the player's data in named hex parts.
- Any other file is its bytes.

check compares each built file with the original bytes: the pictures with work/parts/bank7-c000.bin (tools/parts.py),
the other @res files with the bytes kit/mkgame.py cut (CUT_DIRS), the rest with the export of its own build (the
round trip; the tapes' byte-exact build covers them too).
"""
import argparse
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bank7pic  # noqa: E402
import res_missions  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
BANK7 = os.path.join(ROOT, 'work', 'parts', 'bank7-c000.bin')

# the pictures' names (bank 7 @res entries) -> block address
PICTURES = {'damage-board': 0xC000, 'stores': 0xC713, 'mission-select': 0xCCC9, 'grid-panel': 0xD325,
            'cockpit': 0xDD75, 'completion': 0xE51E, 'briefing': 0xE949, 'mission-status': 0xEC82,
            'title': 0xF4E1, 'map-frame': 0xF9CD}


# --------------------------------------------------------------------------------------------- the screen PNG
def zx_rgb(colour, bright):
    v = 255 if bright else 205
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


SCREEN_PALETTE = [c for i in range(64) for c in zx_rgb(i & 7, (i >> 3) & 1)]


def pixel_addr(x, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)


def screen_to_png(d, bright=False):
    """6912 bytes -> PNG bytes; bright: show every cell bright (the pictures, which UnpackPicture brightens), the
    index keeps the real bit"""
    from PIL import Image, PngImagePlugin
    img = Image.new('P', (256, 192), 0)
    pal = list(SCREEN_PALETTE)
    if bright:
        for i in range(64):
            pal[3 * i:3 * i + 3] = zx_rgb(i & 7, 1)
    img.putpalette(pal)
    px = img.load()
    attrs = d[6144:6912]
    hidden = []
    for y in range(192):
        for x in range(256):
            a = attrs[(y >> 3) * 32 + (x >> 3)]
            ink = (d[pixel_addr(x, y)] >> (7 - (x & 7))) & 1
            colour = a & 7 if ink else (a >> 3) & 7
            px[x, y] = (a >> 7) * 32 + ink * 16 + ((a >> 6) & 1) * 8 + colour
    for r in range(24):
        for c in range(32):
            cell = [d[pixel_addr(c * 8, y)] for y in range(r * 8, r * 8 + 8)]
            if all(b == 0 for b in cell) or all(b == 255 for b in cell):
                hidden.append('%d,%d,%02X' % (r, c, attrs[r * 32 + c]))
    info = PngImagePlugin.PngInfo()
    info.add_text('bc-hidden', ' '.join(hidden))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_screen(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    if img.mode != 'P':
        raise ValueError('res: a screen PNG must stay indexed (64-entry palette, tools/res_formats.py)')
    px = img.load()
    hidden = {}
    for t in img.text.get('bc-hidden', '').split():
        r, c, a = t.split(',')
        hidden[int(r), int(c)] = int(a, 16)
    d = bytearray(6912)
    for r in range(24):
        for c in range(32):
            ink = paper = None
            for y in range(r * 8, r * 8 + 8):
                b = 0
                for x in range(c * 8, c * 8 + 8):
                    i = px[x, y]
                    b = b << 1 | ((i >> 4) & 1)
                    if (i >> 4) & 1:
                        ink = i
                    else:
                        paper = i
                d[pixel_addr(c * 8, y)] = b
            if (r, c) in hidden:
                a = hidden[r, c]
            else:
                if (ink & 0x28) != (paper & 0x28):
                    raise ValueError('res: cell %d,%d: ink and paper differ in flash or bright' % (r, c))
                a = (ink >> 5) << 7 | ((ink >> 3) & 1) << 6 | (paper & 7) << 3 | (ink & 7)
            d[6144 + r * 32 + c] = a
    return bytes(d)


# ----------------------------------------------------------------------------------------------- the formats
def picture_export(name, data):
    screen, parse = bank7pic.decode(data)
    title = 'pictures/%s ($%04X)' % (name, PICTURES.get(name, 0))
    return {name + '.png': screen_to_png(screen, bright=True),
            name + '.parse.txt': bank7pic.parse_to_text(parse, title).encode()}


def picture_build(name, files):
    screen = png_to_screen(files[name + '.png'])
    parse = bank7pic.text_to_parse(files[name + '.parse.txt'].decode())
    if bank7pic.unpacked(parse) != screen:
        print('res: pictures/%s.png differs from its parse: packed again (not the original bytes)' % name)
        parse = bank7pic.pack(screen, parse['long'], parse['pad'])
    return bank7pic.encode(parse)


def screen_export(name, data):
    return {name + '.png': screen_to_png(data)}


def screen_build(name, files):
    return png_to_screen(files[name + '.png'])


# ------------------------------------------------------------------------------------------------ font sheets
# fonts/NAME.bin -> NAME.png: one glyph a cell, 16 cells a row, each glyph 8 pixels wide and ROWS high, one byte a
# row, bit 7 the left pixel; palette 0 = bit 0 (black), 1 = bit 1 (white), 2 = the grid between cells. The small
# font stores its glyphs inverted (ink is 0), so it shows black on white. A byte count that is no multiple of ROWS
# keeps its tail in the text chunk `bc-tail`.
FONT_ROWS = {'small-font': 5, 'font8x8': 8}
FONT_COLUMNS = 16


def font_export(name, data):
    from PIL import Image, PngImagePlugin
    rows = FONT_ROWS[name]
    n = len(data) // rows
    lines = (n + FONT_COLUMNS - 1) // FONT_COLUMNS
    img = Image.new('P', (FONT_COLUMNS * 9 + 1, lines * (rows + 1) + 1), 2)
    img.putpalette([0, 0, 0, 255, 255, 255, 128, 128, 128])
    px = img.load()
    for g in range(n):
        x0, y0 = 1 + (g % FONT_COLUMNS) * 9, 1 + (g // FONT_COLUMNS) * (rows + 1)
        for r in range(rows):
            b = data[g * rows + r]
            for x in range(8):
                px[x0 + x, y0 + r] = (b >> (7 - x)) & 1
    info = PngImagePlugin.PngInfo()
    info.add_text('bc-glyphs', str(n))
    info.add_text('bc-tail', data[n * rows:].hex())
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return {name + '.png': out.getvalue()}


def font_build(name, files):
    from PIL import Image
    img = Image.open(io.BytesIO(files[name + '.png']))
    px = img.load()
    rows = FONT_ROWS[name]
    n = int(img.text['bc-glyphs'])
    out = bytearray()
    for g in range(n):
        x0, y0 = 1 + (g % FONT_COLUMNS) * 9, 1 + (g // FONT_COLUMNS) * (rows + 1)
        for r in range(rows):
            b = 0
            for x in range(8):
                b = b << 1 | (px[x0 + x, y0 + r] & 1)
            out.append(b)
    return bytes(out) + bytes.fromhex(img.text.get('bc-tail', ''))



# ------------------------------------------------------------------------------------------------ the missions
# missions/NN-NAME.bin -> NN-NAME.txt (tools/res_missions.py) and NN-NAME.preview.png, the world from above (a view
# for the reader; the build ignores it). catalogue.bin stays bytes.
def mission_export(name, data):
    import tempfile
    with tempfile.TemporaryDirectory() as t:
        png = os.path.join(t, 'w.png')
        res_missions.figure(data, png, name)
        preview = open(png, 'rb').read()
    return {name + '.txt': res_missions.to_text(data, 'missions/' + name).encode(), name + '.preview.png': preview}


def mission_build(name, files):
    return res_missions.from_text(files[name + '.txt'].decode())


# ------------------------------------------------------------------------------------------------ the texts
# texts/NAME.bin -> NAME.txt, UTF-8: the characters $20-$7E as themselves, every other byte (PrintString's control
# codes below $20 and their operands, the map glyphs $80/$81, tokens from $82, the end $FF) and the braces as {XX}. A line break is
# written before a control code that follows a character; line breaks are ignored when the text is read back.
TEXT_ARGS = {0: 1, 1: 1, 2: 2, 5: 1, 8: 2, 9: 1, 13: 1}  # the operand bytes of PrintString's control codes


def text_export(name, data):
    out, prev, args = [], 0x20, 0
    for b in data:
        if args:  # an operand: always as hex
            out.append('{%02X}' % b)
            args -= 1
            continue
        if b < 0x20 and prev >= 0x20 and out:
            out.append('\n')
        out.append(chr(b) if 0x20 <= b < 0x7F and b not in (0x7B, 0x7D) else '{%02X}' % b)
        args = TEXT_ARGS.get(b, 0)
        prev = b
    return {name + '.txt': (''.join(out) + '\n').encode('utf-8')}


def text_build(name, files):
    import re
    t = files[name + '.txt'].decode('utf-8').replace('\n', '')
    out = bytearray()
    for m in re.finditer(r'\{([0-9A-F]{2})\}|(.)', t, re.S):
        out += bytes([int(m.group(1), 16)]) if m.group(1) else m.group(2).encode('ascii')
    return bytes(out)


# ------------------------------------------------------------------------------------------------ the music
# music/tune.bin (bank 4 `$C721-$CB63`, the AY player's data) -> tune.txt: the bytes as hex in named parts at their
# addresses (the ornaments, each instrument with its speed byte, the tune record, the pattern table, the three order
# lists, each pattern). The parts' boundaries come from the tables inside the data; the text keeps every byte.
TUNE_ORG = 0xC721


def tune_parts(d):
    w = lambda a: d[a - TUNE_ORG] | d[a - TUNE_ORG + 1] << 8
    cuts = {0xC721: 'OrnamentOffsets', 0xC728: 'Ornaments', 0xC75A: 'Instruments (13 envelope addresses)',
            0xC774: 'InstrumentData', 0xC869: 'TuneTable (speed, order lists A, B, C)',
            0xC870: 'PatternTable (17 words)'}
    for i in range(13):
        cuts[w(0xC75A + 2 * i) - 1] = 'instrument %d (speed, then the volume envelope)' % i
    for k, ch in enumerate('ABC'):
        cuts[w(0xC86A + 2 * k)] = 'order list %s' % ch
    for i in range(16):
        cuts[w(0xC870 + 2 * i)] = 'pattern %d' % i
    end = TUNE_ORG + len(d)
    keys = sorted(a for a in cuts if TUNE_ORG <= a < end)
    return [(a, cuts[a], d[a - TUNE_ORG:(keys[i + 1] if i + 1 < len(keys) else end) - TUNE_ORG])
            for i, a in enumerate(keys)]


def tune_export(name, data):
    out = ['# music/%s: the AY player\'s data, bank 4 $C721-$CB63 (src/bank4/music.asm, src/res/music/README.md).' % name,
           '# "@ $ADDR name" opens a part; the hex lines that follow are its bytes, in order.']
    for a, label, b in tune_parts(data):
        out.append('@ $%04X %s' % (a, label))
        out += [' '.join('%02X' % x for x in b[i:i + 16]) for i in range(0, len(b), 16)]
    return {name + '.txt': ('\n'.join(out) + '\n').encode()}


def tune_build(name, files):
    out = bytearray()
    for line in files[name + '.txt'].decode().splitlines():
        if line.startswith('@ $'):
            a = int(line[3:7], 16)
            assert a == TUNE_ORG + len(out), 'res_formats: tune part at $%04X, the bytes reach $%04X' % (
                a, TUNE_ORG + len(out))
        elif line.strip() and not line.startswith('#'):
            out += bytes(int(x, 16) for x in line.split())
    return bytes(out)


# (folder, suffix of the built file, suffixes of the editable files, export, build)
FORMATS = [('pictures', '.bin', ['.png', '.parse.txt'], picture_export, picture_build),
           ('screens', '.scr', ['.png'], screen_export, screen_build),
           ('fonts', '.bin', ['.png'], font_export, font_build),
           ('missions', '.bin', ['.txt'], mission_export, mission_build),
           ('texts', '.bin', ['.txt'], text_export, text_build),
           ('music', '.bin', ['.txt'], tune_export, tune_build)]


# missions/catalogue.bin (side 2's DIRECTORY block, loaded at bank 4 `$CB64`): the names, goals and briefings among
# the briefing maps' data, as a text of the texts' kind (UTF-8, {XX} for the other bytes)
CATALOGUE = ('missions', '.bin', ['.txt'], text_export, text_build)


def format_of(rel):
    folder, base = os.path.split(rel)
    if rel == 'missions/catalogue.bin':
        return CATALOGUE, 'catalogue'
    for f in FORMATS:
        if folder == f[0] and base.endswith(f[1]):
            return f, base[:-len(f[1])]
    return None, None


def install(files):
    for rel, data in files.items():
        f, name = format_of(rel)
        folder = os.path.join(RES, os.path.dirname(rel))
        os.makedirs(folder, exist_ok=True)
        if f:
            for n, d in f[3](name, data).items():
                open(os.path.join(folder, n), 'wb').write(d)
        else:
            open(os.path.join(RES, rel), 'wb').write(data)


def editable_sets():
    """{built rel path: (format, name, {editable file name: bytes})} and the plain files"""
    sets, plain = {}, []
    for top, _dirs, names in os.walk(RES):
        rel_top = os.path.relpath(top, RES)
        claimed = set()
        for f in FORMATS:
            if rel_top != f[0]:
                continue
            for s in sorted(n[:-len(f[2][0])] for n in names if n.endswith(f[2][0])):
                ff = format_of(os.path.join(rel_top, s + f[1]))[0]  # catalogue.txt has its own format
                parts = {s + suf: open(os.path.join(top, s + suf), 'rb').read() for suf in ff[2]
                         if os.path.exists(os.path.join(top, s + suf))}
                sets[os.path.join(rel_top, s + f[1])] = (ff, s, parts)
                claimed |= set(parts)
        for n in names:
            if n == 'README.md' or n in claimed or n.endswith('.preview.png'):
                continue
            plain.append(os.path.normpath(os.path.join(rel_top, n)))
    return sets, plain


def build_all():
    sets, plain = editable_sets()
    out = {}
    for rel, (f, name, parts) in sets.items():
        out[os.path.normpath(rel)] = f[4](name, parts)
    for rel in plain:
        out[rel] = open(os.path.join(RES, rel), 'rb').read()
    return out, sets


def build(out_dir):
    files, _ = build_all()
    for rel, data in files.items():
        dst = os.path.join(out_dir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(data)


def export():
    for top, _dirs, names in os.walk(RES):
        for n in names:
            rel = os.path.relpath(os.path.join(top, n), RES)
            f, name = format_of(rel)
            if f:
                for en, d in f[3](name, open(os.path.join(top, n), 'rb').read()).items():
                    open(os.path.join(top, en), 'wb').write(d)
                os.remove(os.path.join(top, n))
                print('res: %s -> %s' % (rel, ', '.join(name + s for s in f[2])))


# where kit/mkgame.py leaves the bytes it cut from the images (the game's and the bank parts' work folders)
CUT_DIRS = ['work/mkgame/res'] + ['work/stage2/mkbank%d/res' % n for n in (3, 4, 6, 7)]
ORIGINAL = {}


def original(rel):
    for d in CUT_DIRS:
        path = os.path.join(ROOT, d, rel)
        if os.path.exists(path):
            ORIGINAL[rel] = path
            return open(path, 'rb').read()
    return None


def check():
    files, sets = build_all()
    bank7 = open(BANK7, 'rb').read() if os.path.exists(BANK7) else None
    bad = 0
    for rel, data in sorted(files.items()):
        f, name = format_of(rel)
        if f and f[0] == 'pictures' and bank7 is not None and name in PICTURES:
            o = PICTURES[name] - 0xC000
            orig = bank7[o:o + (bank7[o] | bank7[o + 1] << 8) + 4]
            ok = data == orig
            how = 'the bank 7 block at $%04X' % PICTURES[name]
        elif original(rel) is not None:
            ok = data == original(rel)
            how = 'mkgame\'s cut ' + os.path.relpath(ORIGINAL[rel], ROOT)
        elif f:
            again = f[3](name, data)
            ok = f[4](name, again) == data
            how = 'export and build again'
        else:
            ok, how = True, 'bytes'
        bad += not ok
        print('%-4s %-40s %6d bytes  %s' % ('ok' if ok else 'BAD', rel, len(data), how))
    print('res: %d files, %d bad' % (len(files), bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check', 'export'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    if args.command == 'export':
        export()
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

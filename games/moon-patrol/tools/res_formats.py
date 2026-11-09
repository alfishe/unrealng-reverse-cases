#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against build/res # ... and gives the bytes of a build (the installed ones)

The formats (each folder's README.md lists its files):
- graphics/, fonts/: an indexed PNG sheet, frames (the pre-shifted slots of a sprite, the glyphs of a font) left to
  right in rows, one grid pixel between frames; palette 0 paper (black), 1 ink (white), 2 grid (grey: also the unused
  end of a slot's last line). The PNG text chunk `mp-sheet` holds the layout (bytes across, bytes a frame, frames a
  row, frame count, byte order), so a sheet builds back on its own. SHEETS gives each file's layout.
- text/: the strings of the print code `$FFD0` as UTF-8 text (TEXT CODES below); `{END}` is the terminator `$1F`,
  followed in the file by a line break that is not data.
- courses/, tune/: one record a line (the COURSE and TUNE sections below).
Any other file stays its bytes.
"""
import argparse
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

# ---------------------------------------------------------------------------------------------------------------
# PNG sheets
# ---------------------------------------------------------------------------------------------------------------
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128]

# the .bin name the .ann's @res gives -> (bytes across, bytes a frame, frames a row, 'rows' | 'columns'); filled
# from the graphics entries below
SHEETS = {
    # graphics A ($6132-$7EFF): the title logo, copied by BlitRows $AFAB; the rest XOR sprites (SpriteTable $B2D6)
    'graphics/TitleMoon.bin': (10, 250, 1, 'rows'),         # 10 bytes x 25 lines
    'graphics/TitlePatrol.bin': (14, 350, 1, 'rows'),       # 14 x 25
    'graphics/BuggyWreck1.bin': (2, 86, 1, 'rows'),         # the tail of wreck piece 1 (its first slots lie in the logo)
    'graphics/BuggyWreck2.bin': (2, 18, 8, 'rows'),         # 2 x 9, 8 slots
    'graphics/BuggyWreck3.bin': (2, 18, 8, 'rows'),
    'graphics/BuggyExplosion.bin': (5, 128, 4, 'rows'),     # 5 x 23 in 128-byte slots, 4 slots a frame, 8 frames
    'graphics/PlantScore.bin': (4, 64, 4, 'rows'),          # 4 x 16
    'graphics/BurstLarge.bin': (3, 48, 4, 'rows'),          # 3 x 16
    'graphics/Debris.bin': (3, 36, 4, 'rows'),              # 3 x 12
    'graphics/BurstMedium.bin': (3, 36, 4, 'rows'),
    'graphics/BurstSmall.bin': (3, 24, 4, 'rows'),          # 3 x 8
    # graphics B ($C350-$EFFF)
    'graphics/BurstTiny.bin': (2, 16, 4, 'rows'),           # 2 x 8
    'graphics/PlantFrames.bin': (4, 64, 4, 'rows'),
    'graphics/PlantSpray.bin': (4, 64, 4, 'rows'),
    'graphics/BoulderLarge.bin': (3, 48, 4, 'rows'),
    'graphics/BoulderMedium.bin': (3, 36, 4, 'rows'),
    'graphics/BoulderSmall.bin': (2, 16, 4, 'rows'),
    'graphics/UfoBomb.bin': (2, 8, 8, 'rows'),              # 2 x 4, 8 slots
    'graphics/LowFlyer.bin': (3, 24, 8, 'rows'),            # 3 x 8, 8 slots
    'graphics/Tank.bin': (5, 128, 4, 'rows'),
    'graphics/Mine.bin': (2, 8, 8, 'rows'),
    'graphics/BombCrater.bin': (3, 48, 4, 'rows'),
    'graphics/Rock.bin': (3, 36, 4, 'rows'),
    'graphics/Spinner.bin': (3, 48, 4, 'rows'),
    'graphics/UfoB.bin': (3, 24, 4, 'rows'),
    'graphics/UfoA.bin': (3, 24, 4, 'rows'),
    'graphics/Buggy.bin': (5, 128, 4, 'rows'),
    'graphics/MountainsStrip.bin': (34, 1088, 1, 'columns'),  # 34 columns of 32 lines, column by column
    'graphics/MoonBaseStrip.bin': (34, 1088, 1, 'columns'),
    'graphics/HillsStrip.bin': (34, 1088, 1, 'columns'),
    # the fonts: 8 bytes a glyph, codes $20-$7F
    'fonts/FontSmall.bin': (1, 8, 16, 'rows'),
    'fonts/FontBold.bin': (1, 8, 16, 'rows'),
    'fonts/FontPlain.bin': (1, 8, 16, 'rows'),
}


def frame_xy(k, wbytes, fsize, order):
    """the (byte column, line) of byte k of a frame: 'rows' fills a line of wbytes, then the next (a frame of
    fsize bytes may end inside its last line: the slot padding); 'columns' fills a column of fsize / wbytes lines"""
    if order == 'rows':
        return k % wbytes, k // wbytes
    lines = fsize // wbytes
    return k // lines, k % lines


def sheet_to_png(data, wbytes, fsize, cols, order='rows'):
    from PIL import Image, PngImagePlugin
    if len(data) % fsize:
        raise ValueError('%d bytes are not whole frames of %d' % (len(data), fsize))
    n = len(data) // fsize
    cols = max(1, min(cols, n))
    rows = (n + cols - 1) // cols
    fw, fh = wbytes * 8, (fsize + wbytes - 1) // wbytes
    img = Image.new('P', (cols * (fw + 1) + 1, rows * (fh + 1) + 1), 2)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            xb, y = frame_xy(k, wbytes, fsize, order)
            b = data[f * fsize + k]
            for bit in range(8):
                px[ox + xb * 8 + bit, oy + y] = (b >> (7 - bit)) & 1
    info = PngImagePlugin.PngInfo()
    info.add_text('mp-sheet', '%d %d %d %d %s' % (wbytes, fsize, cols, n, order))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_sheet(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    wbytes, fsize, cols, n, order = img.text['mp-sheet'].split()
    wbytes, fsize, cols, n = int(wbytes), int(fsize), int(cols), int(n)
    px = img.load()
    fw, fh = wbytes * 8, (fsize + wbytes - 1) // wbytes
    out = bytearray(n * fsize)
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            xb, y = frame_xy(k, wbytes, fsize, order)
            b = 0
            for bit in range(8):
                b = b << 1 | (1 if px[ox + xb * 8 + bit, oy + y] == 1 else 0)
            out[f * fsize + k] = b
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# TEXT CODES: the print code's control codes ($FDE3 through the table $F080), annotator notes 01 / 05
#   $20-$7E    the character ($60 the pound sign, written as the character itself: the font's glyph)
#   $7F        (c), written as the character (the font's copyright glyph)
#   $0D        {CR}             a new line to the left margin
#   $10 n      {INK n}          $11 n {PAPER n}  $12 n {FLASH n}  $13 n {BRIGHT n}
#   $16 x y    {AT x,y}         pixel x, then the line
#   $17 x      {TAB x}          $18 n {MARGIN n}  $19 n {LIMIT n}  $1A n {FONT n}
#   $1F        {END}            the terminator (a line break follows in the file)
#   any other  {$XX}            (also '{' and '}' themselves)
# Numbers in codes are decimal. Line breaks in the file outside {END} are not data.
# ---------------------------------------------------------------------------------------------------------------
CODES1 = {0x10: 'INK', 0x11: 'PAPER', 0x12: 'FLASH', 0x13: 'BRIGHT', 0x17: 'TAB', 0x18: 'MARGIN', 0x19: 'LIMIT',
          0x1A: 'FONT'}
NAMES1 = {v: k for k, v in CODES1.items()}
CHARS = {0x60: '£', 0x7F: '©'}
CHARS_BACK = {v: k for k, v in CHARS.items()}

def text_to_utf8(data):
    out, i = [], 0
    while i < len(data):
        b = data[i]
        if b in CODES1 and i + 1 < len(data):
            out.append('{%s %d}' % (CODES1[b], data[i + 1]))
            i += 2
            continue
        if b == 0x16 and i + 2 < len(data):
            out.append('{AT %d,%d}' % (data[i + 1], data[i + 2]))
            i += 3
            continue
        if b == 0x1F:
            out.append('{END}\n')
        elif b == 0x0D:
            out.append('{CR}')
        elif b in CHARS:
            out.append(CHARS[b])
        elif 0x20 <= b < 0x7F and chr(b) not in '{}':
            out.append(chr(b))
        else:
            out.append('{$%02X}' % b)
        i += 1
    return ''.join(out).encode('utf-8')


def utf8_to_text(raw):
    s = raw.decode('utf-8').replace('\n', '')
    out = bytearray()
    for m in re.finditer(r'\{([^}]*)\}|(.)', s, re.S):
        code, ch = m.group(1), m.group(2)
        if ch is not None:
            out.append(CHARS_BACK.get(ch, ord(ch)))
            continue
        w = code.split(' ', 1)
        if code == 'END':
            out.append(0x1F)
        elif code == 'CR':
            out.append(0x0D)
        elif code.startswith('$'):
            out.append(int(code[1:], 16))
        elif w[0] == 'AT':
            x, y = w[1].split(',')
            out += bytes([0x16, int(x), int(y)])
        elif w[0] in NAMES1:
            out += bytes([NAMES1[w[0]], int(w[1])])
        else:
            raise ValueError('unknown code {%s}' % code)
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The registry: .bin name -> (suffix, to_editable(name, bytes), from_editable(name, bytes))
# ---------------------------------------------------------------------------------------------------------------
def editable(name):
    if name in SHEETS:
        w, h, cols, order = SHEETS[name]
        return '.png', (lambda n, d: sheet_to_png(d, w, h, cols, order)), (lambda n, d: png_to_sheet(d))
    if name.startswith('text/'):
        return '.txt', (lambda n, d: text_to_utf8(d)), (lambda n, d: utf8_to_text(d))
    for prefix, fmt in EXTRA.items():
        if name.startswith(prefix):
            return fmt
    return None


# ---------------------------------------------------------------------------------------------------------------
# COURSE: the course scripts (BeginnerCourse $B7E8, ChampionCourse $BB24), read by the interpreter CourseRun $9751.
# One command a line: the command word (a handler address) by name, then its parameter bytes, decimal:
#   Wait N                 $976C, a word: the passes of the interpreter to wait
#   Point D C              $9775, a delay byte and the point code (letter = C AND $1F, 'A' + C - 1, skipping O)
#   Lights D:S ...         $97AD, (delay, lamp state) pairs, ended by $FF
#   Rocks / Craters / Mines / UfosA / UfosB / Spinners / UfosLeave / Tanks / LowFlyers / BouldersSmall /
#   BouldersMedium / BouldersLarge / Plants D ...   a list of bytes ended by $FF, one object each
#   SectorEnd P B S T      $A4EE: par time P (BCD word of seconds, $0120 = 120 s), bonus B (BCD hundreds, $10 = 1000),
#                          scenery S ($FF the city, $00 the mountains), best time T (BCD word, $0999 in the image)
#   End                    $9760: the end of a segment
#   Word $XXXX             any other word (the jump to the course switch after the last sector end)
# A line `# ...` is a comment (the segment numbers, the point letters); blank lines are ignored.
# ---------------------------------------------------------------------------------------------------------------
COMMANDS = {0x976C: 'Wait', 0x9775: 'Point', 0x97AD: 'Lights', 0x97C5: 'Rocks', 0x97E8: 'Craters', 0x97FF: 'Mines',
            0x9821: 'UfosA', 0x9827: 'UfosB', 0x982D: 'Spinners', 0x98AA: 'UfosLeave', 0x98BE: 'Tanks',
            0x98F3: 'LowFlyers', 0x9917: 'BouldersSmall', 0x991C: 'BouldersMedium', 0x9921: 'BouldersLarge',
            0x9955: 'Plants', 0xA4EE: 'SectorEnd', 0x9760: 'End'}
COMMAND_WORDS = {v: k for k, v in COMMANDS.items()}
LISTS = {'Rocks', 'Craters', 'Mines', 'UfosA', 'UfosB', 'Spinners', 'UfosLeave', 'Tanks', 'LowFlyers',
         'BouldersSmall', 'BouldersMedium', 'BouldersLarge', 'Plants'}


def letter(c):
    n = c & 0x1F
    return chr(0x40 + n + (1 if n >= 0x0F else 0))


def course_to_text(data):
    out, i, seg = ['# segment 1'], 0, 1
    while i < len(data):
        if i + 1 >= len(data):
            out.append('Byte $%02X' % data[i])
            break
        w = data[i] | data[i + 1] << 8
        name = COMMANDS.get(w)
        i += 2
        if name == 'Wait':
            out.append('Wait %d' % (data[i] | data[i + 1] << 8))
            i += 2
        elif name == 'Point':
            out.append('Point %d %d    # point %s' % (data[i], data[i + 1], letter(data[i + 1])))
            i += 2
        elif name == 'Lights':
            pairs = []
            while data[i] != 0xFF:
                pairs.append('%d:%d' % (data[i], data[i + 1]))
                i += 2
            i += 1
            out.append('Lights ' + ' '.join(pairs))
        elif name in LISTS:
            items = []
            while data[i] != 0xFF:
                items.append(str(data[i]))
                i += 1
            i += 1
            out.append(' '.join([name] + items))
        elif name in ('SectorEnd', 'End'):
            if name == 'SectorEnd':
                p, b, s, t = data[i:i + 2], data[i + 2], data[i + 3], data[i + 4:i + 6]
                out.append('SectorEnd $%02X%02X $%02X $%02X $%02X%02X' % (p[0], p[1], b, s, t[0], t[1]))
                i += 6
            else:
                out.append('End')
            if i < len(data):
                seg += 1
                out += ['', '# segment %d' % seg]
        else:
            out.append('Word $%04X' % w)
    return ('\n'.join(out) + '\n').encode('utf-8')


def num(t):
    return int(t[1:], 16) if t.startswith('$') else int(t)


def text_to_course(raw):
    out = bytearray()
    for line in raw.decode('utf-8').splitlines():
        line = line.split('#', 1)[0].split()
        if not line:
            continue
        cmd, args = line[0], line[1:]
        if cmd == 'Word':
            out += num(args[0]).to_bytes(2, 'little')
            continue
        if cmd == 'Byte':
            out.append(num(args[0]))
            continue
        out += COMMAND_WORDS[cmd].to_bytes(2, 'little')
        if cmd == 'Wait':
            out += num(args[0]).to_bytes(2, 'little')
        elif cmd == 'Point':
            out += bytes([num(args[0]), num(args[1])])
        elif cmd == 'Lights':
            for pr in args:
                d, s = pr.split(':')
                out += bytes([num(d), num(s)])
            out.append(0xFF)
        elif cmd in LISTS:
            out += bytes(num(a) for a in args) + b'\xff'
        elif cmd == 'SectorEnd':
            p, b, s, t = (num(a) for a in args)
            out += bytes([p >> 8, p & 0xFF, b, s, t >> 8, t & 0xFF])
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# TUNE: Tune $B4E6, one word every third interrupt (TunePlayer $7F47): one word a line, `$XXXX` the period for the
# ROM's BEEPER, `rest` for 0, `loop` for $FFFF (back to the start); `# ...` a comment.
# ---------------------------------------------------------------------------------------------------------------
def tune_to_text(data):
    out = ['# one word every third interrupt: the BEEPER period, rest, or loop (back to the start)']
    for i in range(0, len(data), 2):
        w = data[i] | data[i + 1] << 8
        out.append('rest' if w == 0 else 'loop' if w == 0xFFFF else '$%04X' % w)
    return ('\n'.join(out) + '\n').encode('utf-8')


def text_to_tune(raw):
    out = bytearray()
    for line in raw.decode('utf-8').splitlines():
        t = line.split('#', 1)[0].strip()
        if t:
            out += (0 if t == 'rest' else 0xFFFF if t == 'loop' else num(t)).to_bytes(2, 'little')
    return bytes(out)


EXTRA = {
    'courses/': ('.txt', lambda n, d: course_to_text(d), lambda n, d: text_to_course(d)),
    'tune/': ('.txt', lambda n, d: tune_to_text(d), lambda n, d: text_to_tune(d)),
}


def install(files):
    for name, data in files.items():
        fmt = editable(name)
        if fmt:
            suffix, to_ed, from_ed = fmt
            out = to_ed(name, data)
            if from_ed(name, out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            path = os.path.join(RES, os.path.splitext(name)[0] + suffix)
        else:
            path, out = os.path.join(RES, name), data
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(out)


def sources():
    """(src path, the .bin name it builds, its format or None) for every file of src/res"""
    for top, _dirs, files in os.walk(RES):
        for f in sorted(files):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            stem, ext = os.path.splitext(rel)
            name = stem + '.bin'
            fmt = editable(name) if ext != '.bin' else None
            if fmt and fmt[0] == ext:
                yield src, name, fmt
            else:
                yield src, rel, None


def build(out):
    for src, name, fmt in sources():
        data = open(src, 'rb').read()
        if fmt:
            data = fmt[2](name, data)
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(data)


def check(against=None):
    bad = count = 0
    for src, name, fmt in sources():
        if not fmt:
            continue
        count += 1
        ed = open(src, 'rb').read()
        data = fmt[2](name, ed)
        if fmt[2](name, fmt[1](name, data)) != data or fmt[1](name, data) != ed:
            print('res: %s does not round-trip' % src)
            bad += 1
        if against:
            ref = os.path.join(against, name)
            if os.path.exists(ref) and open(ref, 'rb').read() != data:
                print('res: %s differs from %s' % (src, ref))
                bad += 1
    print('res: %d editable files, %d bad' % (count, bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--against')
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    return check(args.against)


if __name__ == '__main__':
    sys.exit(main())

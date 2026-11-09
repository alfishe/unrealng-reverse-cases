#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- graphics/, fonts/: an indexed PNG sheet, frames left to right in rows, one grid pixel between frames; palette 0
  paper (black), 1 ink (white), 2 grid (grey). The PNG text chunk `vp-sheet` holds the layout (bytes across, bytes a
  frame, frames a row, frame count), so a sheet builds back on its own. SHEETS gives each file's layout.
- tables/: CSV with a header line naming the columns (TABLES below says what each column means); `#` lines are
  comments, not data.
- text/: the strings as UTF-8 text (TEXT below).
Any other file stays its bytes.
"""
import argparse
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

# ---------------------------------------------------------------------------------------------------------------
# PNG sheets
# ---------------------------------------------------------------------------------------------------------------
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128]

# the .bin name of the .ann's @res -> (bytes across, bytes a frame, frames a row)
SHEETS = {
    # the 56 ball sprites $D000: 3 bytes x 16 lines, frame = shift x 7 + ball (the cue ball, balls 1-6): one row a shift
    'graphics/BallSprites.bin': (3, 48, 7),
    # the font $DEF4: 8 x 8, the glyphs a-z then 0-9
    'fonts/Font.bin': (1, 8, 12),
}


def sheet_to_png(data, wbytes, fsize, cols):
    from PIL import Image, PngImagePlugin
    if len(data) % fsize:
        raise ValueError('%d bytes are not whole frames of %d' % (len(data), fsize))
    n = len(data) // fsize
    cols = max(1, min(cols, n))
    rows = (n + cols - 1) // cols
    fw, fh = wbytes * 8, fsize // wbytes
    img = Image.new('P', (cols * (fw + 1) + 1, rows * (fh + 1) + 1), 2)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            b = data[f * fsize + k]
            for bit in range(8):
                px[ox + (k % wbytes) * 8 + bit, oy + k // wbytes] = (b >> (7 - bit)) & 1
    info = PngImagePlugin.PngInfo()
    info.add_text('vp-sheet', '%d %d %d %d' % (wbytes, fsize, cols, n))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_sheet(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    wbytes, fsize, cols, n = (int(x) for x in img.text['vp-sheet'].split())
    px = img.load()
    fw, fh = wbytes * 8, fsize // wbytes
    out = bytearray(n * fsize)
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fh + 1)
        for k in range(fsize):
            b = 0
            for bit in range(8):
                b = b << 1 | (1 if px[ox + (k % wbytes) * 8 + bit, oy + k // wbytes] == 1 else 0)
            out[f * fsize + k] = b
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# CSV tables: the .bin name -> (bytes -> CSV, CSV -> bytes); the header comments say what each column means
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, columns, rows):
    lines = ['# ' + c for c in comments] + [','.join(columns)]
    lines += [','.join(str(v) for v in r) for r in rows]
    return ('\n'.join(lines) + '\n').encode()


def csv_in(raw):
    rows, header = [], None
    for line in raw.decode().split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if header is None:
            header = line.split(',')
            continue
        rows.append([c.strip() for c in line.split(',')])
    return header, rows


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


def grid_out(comments, cols, data, cell=str):
    rows = [[r] + [cell(data[r * cols + c]) for c in range(cols)] for r in range(len(data) // cols)]
    return csv_out(comments, ['row'] + ['c%d' % c for c in range(cols)], rows)


def grid_in(raw, cell=num):
    _h, rows = csv_in(raw)
    return bytes(cell(v) for r in rows for v in r[1:])


def contact_out(d, side):
    return grid_out(['row = |dy|, column cN = |dx| in whole pixels (centre to centre);',
                     '128 ($80) the balls overlap, 1-31 the contact ring cell (CollisionRecords record N), 0 apart'],
                    side, d)


def friction_cell(b):
    return '%d:%d' % (b >> 4, b & 15)


def friction_in(raw):
    return grid_in(raw, lambda v: int(v.split(':')[0]) << 4 | int(v.split(':')[1]))


def collision_out(d):
    rows = []
    for n in range(len(d) // 6):
        w = [d[n * 6 + k] | d[n * 6 + k + 1] << 8 for k in (0, 2, 4)]
        rows.append([n + 1] + w)
    return csv_out(['one record per contact ring cell N of ContactTable (dx, dy): three 8.8 words, $0100 = 1.0;',
                    'nxx = 256 dx*dx / 225, nyy = 256 dy*dy / 225, nxy = 256 |dx dy| / 225 (the distance taken as 15)'],
                   ['record', 'nxx', 'nyy', 'nxy'], rows)


def collision_in(raw):
    _h, rows = csv_in(raw)
    out = bytearray()
    for r in rows:
        for v in r[1:]:
            out += num(v).to_bytes(2, 'little')
    return bytes(out)


TABLES = {
    # $DBFA, 16 x 16: BallContacts $87EF reads 16 |dy| + |dx|
    'tables/ContactTable.bin': (lambda d: contact_out(d, 16), grid_in),
    # $DCFA, 8 x 8: PointJaw $8CF8 reads 8 |dy| + |dx| (a ball against a middle pocket's jaw point)
    'tables/Table8x8.bin': (lambda d: contact_out(d, 8), grid_in),
    # $DD3A, 16 x 16: FrictionSteps $90F5 reads 16 ny + nx; y:x the two nibbles
    'tables/FrictionTable.bin': (lambda d: grid_out(
        ['row = the |vy| nibble ny, column cN = the |vx| nibble nx;',
         'each cell y:x = the friction steps (high nibble the y step, low nibble the x step), 1/256 pixel a tick'],
        16, d, friction_cell), friction_in),
    # $DE3A, 31 records of 3 words: the ball-ball collision (BallCollide)
    'tables/CollisionRecords.bin': (collision_out, collision_in),
}

# ---------------------------------------------------------------------------------------------------------------
# Text: the print records and the pen script, as UTF-8 text
# ---------------------------------------------------------------------------------------------------------------
PRINT_HEAD = ['# The print records of PrintText $9E65, one a line: row column attribute "characters".',
              '# Attribute bit 7: double width. Characters: a-z and 0-9 the game font, \u00a9 is $7F (the copyright',
              '# glyph), other ASCII the ROM font; \\xNN any other byte, \\" and \\\\ escaped. The length byte is the',
              '# count of the characters.']


def print_out(d):
    lines, p = list(PRINT_HEAD), 0
    while p < len(d):
        row, col, attr, n = d[p], d[p + 1], d[p + 2], d[p + 3]
        if p + 4 + n > len(d):
            raise ValueError('a print record runs past the entry')
        t = ''
        for b in d[p + 4:p + 4 + n]:
            if b == 0x7F:
                t += '©'
            elif b in (0x22, 0x5C):
                t += '\\' + chr(b)
            elif 0x20 <= b < 0x7F:
                t += chr(b)
            else:
                t += '\\x%02x' % b
        lines.append('%d %d $%02X "%s"' % (row, col, attr, t))
        p += 4 + n
    return ('\n'.join(lines) + '\n').encode('utf-8')


def print_in(raw):
    out = bytearray()
    for line in raw.decode('utf-8').split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        head, t = line.split('"', 1)
        t = t[:t.rindex('"')]
        row, col, attr = (num(v) for v in head.split())
        chars, i = bytearray(), 0
        while i < len(t):
            c = t[i]
            if c == '\\':
                if t[i + 1] == 'x':
                    chars.append(int(t[i + 2:i + 4], 16))
                    i += 4
                    continue
                chars.append(ord(t[i + 1]))
                i += 2
                continue
            chars.append(0x7F if c == '©' else ord(c))
            i += 1
        out += bytes([row, col, attr, len(chars)]) + chars
    return bytes(out)


PEN_HEAD = ['# The pen script of SignatureCommand $BD23 ("written by" and the signature), one command a line:',
            '#   up / down        the pen up ($01) / down ($02)',
            '#   dot DX DY        one pixel at the pen + (DX, DY), signed bytes ($03 DX DY)',
            '#   move DX DY N     N steps (1-15) of DX, DY each in -2..1, one a frame, a pixel at (x, y - 1) per step',
            '#                    while the pen is down (one byte: DY bits 7-6, DX bits 5-4, N bits 3-0)',
            '#   end              the end ($00)',
            '# The pen starts at x 16, y 128 (set by the code, $BD18).']


def pen_out(d):
    lines, p = list(PEN_HEAD), 0
    s2 = lambda v: (v ^ 2) - 2
    sb = lambda v: v - 256 if v > 127 else v
    while p < len(d):
        b = d[p]
        if b == 0:
            lines.append('end')
            p += 1
        elif b == 1:
            lines.append('up')
            p += 1
        elif b == 2:
            lines.append('down')
            p += 1
        elif b == 3:
            lines.append('dot %d %d' % (sb(d[p + 1]), sb(d[p + 2])))
            p += 3
        elif b & 0xF0:
            lines.append('move %d %d %d' % (s2((b >> 4) & 3), s2(b >> 6), b & 15))
            p += 1
        else:
            raise ValueError('pen script byte $%02X at +%d' % (b, p))
    return ('\n'.join(lines) + '\n').encode()


def pen_in(raw):
    out = bytearray()
    for line in raw.decode().split('\n'):
        w = line.split()
        if not w or w[0].startswith('#'):
            continue
        k, v = w[0], [int(x) for x in w[1:]]
        if k in ('end', 'up', 'down'):
            out.append({'end': 0, 'up': 1, 'down': 2}[k])
        elif k == 'dot':
            out += bytes([3, v[0] & 255, v[1] & 255])
        elif k == 'move':
            out.append((v[1] & 3) << 6 | (v[0] & 3) << 4 | v[2])
        else:
            raise ValueError('pen script: %s' % line)
    return bytes(out)


PRINT_TEXTS = ['HudTexts', 'HudLastShot', 'GameOverTexts', 'FrameBanner', 'PlayerBannerTexts', 'FoulTexts',
               'ScoreBlank', 'HofTitle', 'PromptLeft', 'MenuTitle', 'KeysLine', 'VariationsTitle', 'PresentsTexts',
               'EditorTexts']
TEXT = {'text/%s.bin' % n: (print_out, print_in) for n in PRINT_TEXTS}
TEXT['text/SignatureScript.bin'] = (pen_out, pen_in)


def editable(name):
    if name in SHEETS:
        w, f, c = SHEETS[name]
        return '.png', lambda n, d: sheet_to_png(d, w, f, c), lambda n, d: png_to_sheet(d)
    if name in TABLES:
        to_ed, from_ed = TABLES[name]
        return '.csv', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    if name in TEXT:
        to_ed, from_ed = TEXT[name]
        return '.txt', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    return None


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

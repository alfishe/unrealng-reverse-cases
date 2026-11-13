#!/usr/bin/env python3
"""The loader's and the resident's resources (src/res/loader/, src/res/resident/): the formats tools/res_formats.py
loads (FORMATS below). Each folder's README.md gives every file's address, size and readers.

    NAME                                editable form       what
    loader/countdown-digits.bin         .png                the countdown's digits 0-9 (sl1 $FF80), 8x8 each
    resident/print-font.bin             .png                PrintFont $F880: 37 glyphs of a width mask and 7 rows
    resident/rom-font-leftover.bin      .png                $FF84-$FFFF: a copy of the ROM font's bytes, 8 pixels wide
    resident/text-NAME.bin              .txt                a Print string: column byte, bit, pixel row, the text
    resident/stages.bin                 .txt                StageTable $F0EA: the five stages' load data and titles
    resident/effects.bin                .csv                EffectData $F54D: the 13 AY effects
    resident/colour-cycle.bin           .csv                ColourCycle $F374: the 8 attributes of the title box
    resident/dissolve-masks.bin         .txt                DissolveMasks $F9CB: 6 sets of 8 masks, in binary
    resident/bit-reverse.bin            .txt                BitReverse $FA00: each byte and its mirror, in binary
    resident/screen-lines.bin           .csv                ScreenLineTable $FB00: the 192 pixel lines' addresses

**PNG files.** Indexed: 0 paper (black), 1 ink (white), 2 the grid (grey) between cells; print-font.png shows each
glyph's width mask as its top row in red (index 3), the 7 pixel rows under it. Cells are in a row, 1 pixel of grid
between them. A text chunk `tx-res` keeps the cell count (and, for a strip, its height).

**Texts.** text-NAME.txt: `column N`, `bit N`, `row N` (decimal) and `text "..."` (capital letters, digits and
spaces; the 0 after it is implied). stages.txt: per stage a `stage N` line, `load D E C H L B` (decimal) and two
`title COLUMN BIT ROW "TEXT"` lines.

**effects.csv.** One effect a line: `effect,channel,noise,volume,period,segments` with `segments` the segments as
`duration/period change/volume change` (signed, the volume in the driver's x 16 units) separated by spaces.
"""
import csv
import io
import json
import re

GREY, RED = 2, 3
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128, 215, 0, 0]


def _png(cells, h, meta, top_row_colour=None):
    """cells: lists of h bytes (8 pixels each), in a row with a 1-pixel grey grid"""
    from PIL import Image, PngImagePlugin
    n = len(cells)
    w = n * 9 + 1
    img = Image.new('P', (w, h + 2), GREY)
    img.putpalette(PALETTE + [0] * (768 - len(PALETTE)))
    px = img.load()
    for k, rows in enumerate(cells):
        for y, b in enumerate(rows):
            for x in range(8):
                on = (b >> (7 - x)) & 1
                px[1 + k * 9 + x, 1 + y] = (top_row_colour if y == 0 and top_row_colour else 1) if on else 0
    info = PngImagePlugin.PngInfo()
    info.add_text('tx-res', json.dumps(meta, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def _unpng(raw):
    from PIL import Image
    img = Image.open(io.BytesIO(raw))
    meta = json.loads(img.text['tx-res'])
    px = img.load()
    n, h = meta['cells'], meta['height']
    out = bytearray()
    for k in range(n):
        for y in range(h):
            b = 0
            for x in range(8):
                b = b << 1 | (1 if px[1 + k * 9 + x, 1 + y] not in (0, GREY) else 0)
            out.append(b)
    return bytes(out)


def glyphs_out(name, data):
    return _png([data[i:i + 8] for i in range(0, len(data), 8)], 8, {'cells': len(data) // 8, 'height': 8})


def font_out(name, data):
    return _png([data[i:i + 8] for i in range(0, len(data), 8)], 8, {'cells': len(data) // 8, 'height': 8}, RED)


def strip_out(name, data):
    return _png([data], len(data), {'cells': 1, 'height': len(data)})


def png_in(name, raw):
    return _unpng(raw)


def _lines(raw):
    return [l for l in raw.decode('utf-8').splitlines() if l.strip() and not l.startswith('#')]


def _quoted(s):
    m = re.match(r'^"(.*)"$', s.strip())
    if not m:
        raise SystemExit('res_resident: a text in quotes expected: %s' % s)
    return m.group(1).encode('ascii')


def text_out(name, data):
    assert data[-1] == 0
    return ('column %d\nbit %d\nrow %d\ntext "%s"\n' % (data[0], data[1], data[2], data[3:-1].decode('ascii'))).encode()


def text_in(name, raw):
    f = dict(l.split(' ', 1) for l in _lines(raw))
    return bytes([int(f['column']), int(f['bit']), int(f['row'])]) + _quoted(f['text']) + b'\0'


def stages_out(name, data):
    out, a, n = [], 0, 1
    while a < len(data):
        out.append('stage %d' % n)
        out.append('load %s' % ' '.join(str(b) for b in data[a:a + 6]))
        a += 6
        for _ in range(2):
            z = data.index(0, a + 3)
            out.append('title %d %d %d "%s"' % (data[a], data[a + 1], data[a + 2], data[a + 3:z].decode('ascii')))
            a = z + 1
        out.append('')
        n += 1
    return ('# D E C H L B: C the stage, the length 2 x (9B + H + L) pages; D and E not read\n'
            + '\n'.join(out)).encode()


def stages_in(name, raw):
    out = bytearray()
    for l in _lines(raw):
        k, rest = l.split(' ', 1)
        if k == 'load':
            out += bytes(int(x) for x in rest.split())
        elif k == 'title':
            c, b, r, t = rest.split(' ', 3)
            out += bytes([int(c), int(b), int(r)]) + _quoted(t) + b'\0'
    return bytes(out)


def _s8(b):
    return b - 256 if b > 127 else b


def effects_out(name, data):
    out = io.StringIO()
    w = csv.writer(out, lineterminator='\n')
    w.writerow(['effect', 'channel', 'noise', 'volume', 'period', 'segments'])
    a, n = 0, 0
    while a < len(data):
        ch, noise, k, vol = data[a:a + 4]
        period = data[a + 4] | data[a + 5] << 8
        segs = [data[a + 6 + 3 * i:a + 9 + 3 * i] for i in range(k)]
        w.writerow([n, ch, noise, vol, period, ' '.join('%d/%d/%d' % (s[0], _s8(s[1]), _s8(s[2])) for s in segs)])
        a += 6 + 3 * k
        n += 1
    return out.getvalue().encode()


def effects_in(name, raw):
    out = bytearray()
    for row in list(csv.DictReader(io.StringIO(raw.decode('utf-8')))):
        segs = row['segments'].split()
        p = int(row['period'])
        out += bytes([int(row['channel']), int(row['noise']), len(segs), int(row['volume']), p & 255, p >> 8])
        for s in segs:
            out += bytes(int(x) & 255 for x in s.split('/'))
    return bytes(out)


COLOURS = ['black', 'blue', 'red', 'magenta', 'green', 'cyan', 'yellow', 'white']


def attrs_out(name, data):
    out = io.StringIO()
    w = csv.writer(out, lineterminator='\n')
    w.writerow(['ink', 'paper', 'bright', 'flash'])
    for b in data:
        w.writerow([COLOURS[b & 7], COLOURS[b >> 3 & 7], b >> 6 & 1, b >> 7])
    return out.getvalue().encode()


def attrs_in(name, raw):
    return bytes(COLOURS.index(r['ink']) | COLOURS.index(r['paper']) << 3 | int(r['bright']) << 6 | int(r['flash']) << 7
                 for r in csv.DictReader(io.StringIO(raw.decode('utf-8'))))


def masks_out(name, data):
    out = ['# 8 masks a set, one set a block: the step 0-7 of a dissolve takes the set\'s mask of that step']
    for i in range(0, len(data), 8):
        out.append('set %d' % (i // 8))
        out += ['%08d' % int(bin(b)[2:]) for b in data[i:i + 8]]
    return ('\n'.join(out) + '\n').encode()


def masks_in(name, raw):
    return bytes(int(l, 2) for l in _lines(raw) if not l.startswith('set'))


def reverse_out(name, data):
    out = ['# byte, then the table\'s value for it (the byte with its bits mirrored), in binary']
    out += ['%s %s' % (format(i, '08b'), format(b, '08b')) for i, b in enumerate(data)]
    return ('\n'.join(out) + '\n').encode()


def reverse_in(name, raw):
    return bytes(int(l.split()[1], 2) for l in _lines(raw))


def lines_out(name, data):
    out = io.StringIO()
    w = csv.writer(out, lineterminator='\n')
    w.writerow(['line', 'address'])
    for i in range(0, len(data), 2):
        w.writerow([i // 2, '$%04X' % (data[i] | data[i + 1] << 8)])
    return out.getvalue().encode()


def lines_in(name, raw):
    out = bytearray()
    for r in csv.DictReader(io.StringIO(raw.decode('utf-8'))):
        a = int(r['address'].lstrip('$'), 16)
        out += bytes([a & 255, a >> 8])
    return bytes(out)


FORMATS = [
    (r'^loader/countdown-digits\.bin$', '.png', glyphs_out, png_in),
    (r'^resident/print-font\.bin$', '.png', font_out, png_in),
    (r'^resident/rom-font-leftover\.bin$', '.png', strip_out, png_in),
    (r'^resident/text-[a-z0-9-]+\.bin$', '.txt', text_out, text_in),
    (r'^resident/stages\.bin$', '.txt', stages_out, stages_in),
    (r'^resident/effects\.bin$', '.csv', effects_out, effects_in),
    (r'^resident/colour-cycle\.bin$', '.csv', attrs_out, attrs_in),
    (r'^resident/dissolve-masks\.bin$', '.txt', masks_out, masks_in),
    (r'^resident/bit-reverse\.bin$', '.txt', reverse_out, reverse_in),
    (r'^resident/screen-lines\.bin$', '.csv', lines_out, lines_in),
]

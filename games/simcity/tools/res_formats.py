#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the game's and the screen part's).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- screen/LoadingScreen.png: the 6912-byte screen as a 256 x 192 picture in the Spectrum's colours. The palette has 64
  entries, index = flash x 32 + ink x 16 + bright x 8 + colour, so each pixel says whether it is ink or paper and the
  bytes come back exactly. A cell whose 64 pixels are all paper (or all ink) cannot show its other colour; the PNG
  text chunk `simcity-hidden` keeps those cells' attributes (row, column, attribute in hex).
- graphics/Icons.png, Cells.png, Buildings.png: a tile set and its attribute table as one sheet, 16 tiles a row, in
  the same 64-colour palette (two .bin files each: the tiles and the attributes). Tiles without an attribute (the
  icon set's frame tiles, 56 and up) are white on black; `simcity-hidden` keeps the attribute of a tile that is all
  paper or all ink, `simcity-tiles` the tile and attribute counts.
- graphics/Pointer.png (the arrow, then its mask, 8 x 16), graphics/Movers.png (five 16 x 16 sprites side by side):
  two colours, white = a set bit.
- text/*.txt: bit-7-ended strings, one a line. text/menus/*.txt: a menu description, one item a line (MENU_HELP).
  text/inline/*.txt: PrintInline codes and letters (INLINE_HELP). Bytes outside the printable ASCII range, and
  { } ", are written {xx} in hex.
- tables/*.csv: a table with a header row; columns marked by '(label)' are made from the row number and ignored when
  read; '#' lines are comments.
Any other file stays its bytes.
"""
import argparse
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')


def num(t):
    t = t.strip()
    if t.startswith('$'):
        return int(t[1:], 16)
    if t.startswith('%'):
        return int(t[1:], 2)
    return int(t, 0)


# ---------------------------------------------------------------------------------------------------------------
# The Spectrum's 64-entry ink / paper palette
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


SCREEN_PALETTE = []
for _i in range(64):
    SCREEN_PALETTE += zx_rgb(_i & 7, (_i >> 3) & 1)


def pal_index(attr, ink):
    colour = attr & 7 if ink else (attr >> 3) & 7
    return (attr >> 7) * 32 + ink * 16 + ((attr >> 6) & 1) * 8 + colour


def cell_attr(ink, paper, where):
    if (ink & 0x28) != (paper & 0x28):
        raise ValueError('%s: ink and paper differ in flash or bright' % where)
    return (ink >> 5) << 7 | ((ink >> 3) & 1) << 6 | (paper & 7) << 3 | (ink & 7)


def png_bytes(img, texts):
    from PIL import PngImagePlugin
    info = PngImagePlugin.PngInfo()
    for k, v in texts.items():
        info.add_text(k, v)
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def pixel_addr(x, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)


def screen_to_png(d):
    from PIL import Image
    img = Image.new('P', (256, 192), 0)
    img.putpalette(SCREEN_PALETTE)
    px = img.load()
    attrs = d[6144:6912]
    hidden = []
    for y in range(192):
        for x in range(256):
            a = attrs[(y >> 3) * 32 + (x >> 3)]
            px[x, y] = pal_index(a, (d[pixel_addr(x, y)] >> (7 - (x & 7))) & 1)
    for r in range(24):
        for c in range(32):
            cell = [d[pixel_addr(c * 8, y)] for y in range(r * 8, r * 8 + 8)]
            if all(b == 0 for b in cell) or all(b == 255 for b in cell):
                hidden.append('%d,%d,%02X' % (r, c, attrs[r * 32 + c]))
    return png_bytes(img, {'simcity-hidden': ' '.join(hidden)})


def read_cells(px, x0, y0, rows=8):
    """8 x rows pixels at x0, y0: the bytes and the ink and paper palette indices seen"""
    ink = paper = None
    out = []
    for y in range(y0, y0 + rows):
        b = 0
        for x in range(x0, x0 + 8):
            i = px[x, y]
            b = b << 1 | ((i >> 4) & 1)
            if (i >> 4) & 1:
                ink = i
            else:
                paper = i
        out.append(b)
    return out, ink, paper


def png_to_screen(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    hidden = {}
    for t in img.text.get('simcity-hidden', '').split():
        r, c, a = t.split(',')
        hidden[int(r), int(c)] = int(a, 16)
    d = bytearray(6912)
    for r in range(24):
        for c in range(32):
            rows, ink, paper = read_cells(px, c * 8, r * 8)
            for k, b in enumerate(rows):
                d[pixel_addr(c * 8, r * 8 + k)] = b
            a = hidden[r, c] if (r, c) in hidden else cell_attr(ink, paper, 'cell %d,%d' % (r, c))
            d[6144 + r * 32 + c] = a
    return bytes(d)


# ---------------------------------------------------------------------------------------------------------------
# Tile sheets: a tile set and its attributes in one PNG
# ---------------------------------------------------------------------------------------------------------------
TILE_GROUPS = {  # sheet: (tiles .bin, attributes .bin)
    'graphics/Icons.png': ('graphics/IconTiles.bin', 'graphics/IconAttrs.bin'),
    'graphics/Cells.png': ('graphics/CellTiles.bin', 'graphics/CellAttrs.bin'),
    'graphics/Buildings.png': ('graphics/BuildingTiles.bin', 'graphics/BuildingAttrs.bin'),
}
PER_ROW = 16


def tiles_to_png(tiles, attrs):
    from PIL import Image
    n = len(tiles) // 8
    rows = (n + PER_ROW - 1) // PER_ROW
    img = Image.new('P', (PER_ROW * 8, rows * 8), 0)
    img.putpalette(SCREEN_PALETTE)
    px = img.load()
    hidden = []
    for t in range(n):
        a = attrs[t] if t < len(attrs) else 0x07
        x0, y0 = (t % PER_ROW) * 8, (t // PER_ROW) * 8
        for y in range(8):
            b = tiles[t * 8 + y]
            for x in range(8):
                px[x0 + x, y0 + y] = pal_index(a, (b >> (7 - x)) & 1)
        if t < len(attrs) and all(b == tiles[t * 8] for b in tiles[t * 8:t * 8 + 8]) and tiles[t * 8] in (0, 255):
            hidden.append('%d,%02X' % (t, a))
    return png_bytes(img, {'simcity-tiles': '%d %d' % (n, len(attrs)), 'simcity-hidden': ' '.join(hidden)})


def png_to_tiles(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    n, na = (int(v) for v in img.text['simcity-tiles'].split())
    hidden = {}
    for t in img.text.get('simcity-hidden', '').split():
        k, a = t.split(',')
        hidden[int(k)] = int(a, 16)
    tiles, attrs = bytearray(), bytearray()
    for t in range(n):
        rows, ink, paper = read_cells(px, (t % PER_ROW) * 8, (t // PER_ROW) * 8)
        tiles += bytes(rows)
        if t < na:
            attrs.append(hidden[t] if t in hidden else cell_attr(ink, paper, 'tile %d' % t))
    return bytes(tiles), bytes(attrs)


def mono_to_png(d, w, h, order):
    """1-bit picture: order(x, y) -> (byte index, bit)"""
    from PIL import Image
    img = Image.new('P', (w, h), 0)
    img.putpalette([0, 0, 0, 255, 255, 255])
    px = img.load()
    for y in range(h):
        for x in range(w):
            i, bit = order(x, y)
            px[x, y] = (d[i] >> bit) & 1
    return png_bytes(img, {})


def png_to_mono(png, size, order):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    d = bytearray(size)
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            i, bit = order(x, y)
            if px[x, y]:
                d[i] |= 1 << bit
    return bytes(d)


def pointer_order(x, y):     # 8 x 16: the arrow's 8 rows, then the mask's
    return y, 7 - x


def movers_order(x, y):      # 80 x 16: sprite x // 16, 2 bytes a row
    s, xx = divmod(x, 16)
    return s * 32 + y * 2 + xx // 8, 7 - (xx & 7)


# ---------------------------------------------------------------------------------------------------------------
# Texts
# ---------------------------------------------------------------------------------------------------------------
def esc(c):
    return chr(c) if 32 <= c < 127 and chr(c) not in '{}"' else '{%02x}' % c


def unesc(s):
    """the bytes of a text with {xx} escapes"""
    out = bytearray()
    i = 0
    while i < len(s):
        if s[i] == '{':
            j = s.index('}', i)
            out.append(int(s[i + 1:j], 16))
            i = j + 1
        else:
            out.append(ord(s[i]))
            i += 1
    return bytes(out)


def strings_to_txt(d, title):
    lines = ['# %s: one string a line, bit 7 set on its last letter by the build ({xx}: a byte in hex)' % title]
    s = ''
    for c in d:
        s += esc(c & 0x7F)
        if c & 0x80:
            lines.append(s)
            s = ''
    if s:
        lines.append('{tail}' + s)
    return ('\n'.join(lines) + '\n').encode('utf-8')


def txt_to_strings(t):
    out = bytearray()
    for line in t.decode('utf-8').split('\n'):
        if line.startswith('#') or line == '':
            continue
        if line.startswith('{tail}'):
            out += unesc(line[6:])
            continue
        b = bytearray(unesc(line))
        b[-1] |= 0x80
        out += b
    return bytes(out)


MENU_HELP = """# A menu description (DrawMenu $67C3): 'header N' (the first line's number), then one item a line:
#   text "..."  (kind 0)      number "..."  (kind 8, a selectable line with a number field)
#   action $ADDR "..."  (2)   toggle $FLAG "..."  (1, ON / OFF after it)   separator  (3)   end  (4)
# In the text: {tab} code $21 (to column 24); {byte F V M} code 7: field flag F, value V, maximum M (the value the
# player edits lives here); {word F V M} code 6 (16 bits); {long F V} code 5 (24 bits); bit 7 ends the text."""


def text_to_menu_str(d, i):
    s = ''
    while True:
        c = d[i]
        if c & 0x80:
            s += esc(c & 0x7F)
            return s, i + 1
        if c == 0x21:
            s += '{tab}'
            i += 1
        elif c == 7:
            s += '{byte %d %d %d}' % (d[i + 1], d[i + 2], d[i + 3])
            i += 4
        elif c == 6:
            s += '{word %d %d %d}' % (d[i + 1], d[i + 2] | d[i + 3] << 8, d[i + 4] | d[i + 5] << 8)
            i += 6
        elif c == 5:
            s += '{long %d %d}' % (d[i + 1], d[i + 2] | d[i + 3] << 8 | d[i + 4] << 16)
            i += 5
        else:
            s += esc(c)
            i += 1


def menu_str_to_text(s):
    out = bytearray()
    i = 0
    while i < len(s):
        if s[i] == '{':
            j = s.index('}', i)
            tok = s[i + 1:j].split()
            if tok[0] == 'tab':
                out.append(0x21)
            elif tok[0] == 'byte':
                out += bytes([7, int(tok[1]), int(tok[2]), int(tok[3])])
            elif tok[0] == 'word':
                v, m = int(tok[2]), int(tok[3])
                out += bytes([6, int(tok[1]), v & 255, v >> 8, m & 255, m >> 8])
            elif tok[0] == 'long':
                v = int(tok[2])
                out += bytes([5, int(tok[1]), v & 255, (v >> 8) & 255, v >> 16])
            else:
                out.append(int(tok[0], 16))
            i = j + 1
        else:
            out.append(ord(s[i]))
            i += 1
    out[-1] |= 0x80
    return bytes(out)


def menu_to_txt(d):
    lines = [MENU_HELP, 'header %d' % d[0]]
    i = 1
    while i < len(d):
        k = d[i]
        i += 1
        if k == 4:
            lines.append('end')
            break
        if k == 3:
            lines.append('separator')
            continue
        if k in (1, 2):
            a = d[i] | d[i + 1] << 8
            i += 2
        s, i = text_to_menu_str(d, i)
        name = {0: 'text', 8: 'number', 1: 'toggle $%04X' % a if k == 1 else '', 2: 'action $%04X' % a if k == 2 else ''}[k]
        lines.append('%s "%s"' % (name, s))
    if i != len(d):
        raise ValueError('menu: %d bytes after the end' % (len(d) - i))
    return ('\n'.join(lines) + '\n').encode('utf-8')


def txt_to_menu(t):
    out = bytearray()
    for line in t.decode('utf-8').split('\n'):
        if line.startswith('#') or not line.strip():
            continue
        w = line.split(' ', 1)
        if w[0] == 'header':
            out.append(int(w[1]))
        elif w[0] == 'end':
            out.append(4)
        elif w[0] == 'separator':
            out.append(3)
        else:
            head, s = line.split('"', 1)
            s = s[:s.rindex('"')]
            head = head.split()
            k = {'text': 0, 'number': 8, 'toggle': 1, 'action': 2}[head[0]]
            out.append(k)
            if k in (1, 2):
                a = num(head[1])
                out += bytes([a & 255, a >> 8])
            out += menu_str_to_text(s)
    return bytes(out)


INLINE_HELP = """# PrintInline codes (PrintInline $5DEF) and letters; line breaks are ignored:
#   {at R C} code $FF (row, column)   {attr $XX} $FB   {box R C W H} $FD (a frame)   {num N} $FC   {end} $FE
#   any other byte below $20 or above $7E, and { } ", as {xx} in hex"""
INLINE_ARGS = {0xFF: ('at', 2), 0xFB: ('attr', 1), 0xFD: ('box', 4), 0xFC: ('num', 1), 0xFE: ('end', 0)}


def inline_to_txt(d):
    s = ''
    i = 0
    while i < len(d):
        c = d[i]
        if c in INLINE_ARGS:
            name, n = INLINE_ARGS[c]
            args = d[i + 1:i + 1 + n]
            if name == 'attr':
                tok = '{attr $%02X}' % args[0]
            else:
                tok = '{%s}' % ' '.join([name] + [str(a) for a in args])
            s += ('\n' if name == 'at' and s else '') + tok
            i += 1 + n
        else:
            s += esc(c)
            i += 1
    return (INLINE_HELP + '\n' + s + '\n').encode('utf-8')


def txt_to_inline(t):
    names = {v[0]: k for k, v in INLINE_ARGS.items()}
    body = ''.join(l for l in t.decode('utf-8').split('\n') if not l.startswith('#'))
    out = bytearray()
    i = 0
    while i < len(body):
        if body[i] == '{':
            j = body.index('}', i)
            tok = body[i + 1:j].split()
            if tok[0] in names:
                out.append(names[tok[0]])
                out += bytes(num(a) for a in tok[1:])
            else:
                out.append(int(tok[0], 16))
            i = j + 1
        else:
            out.append(ord(body[i]))
            i += 1
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Tables as CSV
# ---------------------------------------------------------------------------------------------------------------
TOOLS = ['bulldozer', 'road', 'power line', 'rail', 'park', 'residential', 'commercial', 'industrial', 'police',
         'fire', 'stadium', 'power station', 'seaport', 'airport']
SPEEDS = ['fast', 'normal', 'slow', 'paused']
CATEGORIES = ['TOWN', 'CITY', 'CAPITAL', 'METROPOLIS', 'MEGALOPOLIS']
NETS = ['power over', 'road over', 'rail over']
ROUTINES = ['police', 'fire', 'church', 'hospital', 'stadium', 'coal', 'nuclear', 'seaport', 'airport',
            'R block', 'C building', 'I building']

# name: (comment, columns, record size, row count or None, tail bytes); a column is (title, offset, format) or
# (title, None, label function). Formats: u8, s8, h8 ($xx), b4 / b8 (binary), u16, u24.
TABLES = {
    'tables/ToolSizes.bin': ('ToolSizes $6DAF: the map box of each tool (ShowTool, CheckSite, PutBuilding)',
                             [('tool', None, lambda i: TOOLS[i]), ('width', 0, 'u8'), ('height', 1, 'u8')], 2),
    'tables/ToolPrices.bin': ('ToolPrices $6E1E: the price of each tool (ToolPrice, GreyUnaffordable, SelectTool)',
                              [('tool', None, lambda i: TOOLS[i]), ('price', 0, 'u16')], 2),
    'tables/NetworkShapes.bin': ('NetworkShapes $6ED3: the cell offset from the network kind by the neighbour mask '
                                 '(bits up, left, right, down; FixNetworkCell)',
                                 [('mask', None, lambda i: format(i, '04b')), ('offset', 0, 'u8')], 1),
    'tables/BridgeDirs.bin': ('BridgeDirs $71FF: the bridge direction (BridgeSteps row) by the neighbour mask',
                              [('mask', None, lambda i: format(i, '04b')), ('direction', 0, 'u8')], 1),
    'tables/BridgeSteps.bin': ('BridgeSteps $720F: per direction the row step, the column step and the bridge cell '
                               'offset from the kind (Bridge)',
                               [('direction', None, str), ('row step', 0, 's8'), ('column step', 1, 's8'),
                                ('offset', 2, 'u8')], 3),
    'tables/BulldozeCosts.bin': ('BulldozeCosts $7301: the price of clearing a building of each size',
                                 [('size', None, str), ('cost', 0, 'u8')], 1),
    'tables/CellFlags.bin': ('CellFlags $6F9C: the flags of each cell code (CellFlagsOf): bit 0 not reshaped, 1 rail, '
                             '2 road, 3 conducts power, 4 zone, 5 -, 6 developed, 7 flammable',
                             [('cell', None, lambda i: '$%02X' % i), ('flags', 0, 'b8')], 1),
    'tables/BuildingValues.bin': ('BuildingValues $7682: by building routine, the kind a trip looks for (9 R, 10 C, '
                                  '11 I; BuildingValue)',
                                  [('routine', None, lambda i: ROUTINES[i]), ('value', 0, 'u8')], 1),
    'tables/ComBuildings.bin': ('ComBuildings $8BBA: by ComLevel - 1, the commercial building variant',
                                [('level - 1', None, str), ('variant', 0, 'u8')], 1),
    'tables/SpeedTable.bin': ('SpeedTable $8F6C: per speed the growth tries, the I and C chance masks (Random AND '
                              'mask = 0 builds), a value no code reads, the month mask (SimPass AND mask = 0 ends a month)',
                              [('speed', None, lambda i: SPEEDS[i]), ('tries', 0, 'u8'), ('I mask', 1, 'h8'),
                               ('C mask', 2, 'h8'), ('unread', 3, 'h8'), ('month mask', 4, 'h8')], 5),
    'tables/CategoryLimits.bin': ('CategoryLimits $9750: the population (last year end) from which each category '
                                  'starts (CategoryOf; below 2000 VILLAGE)',
                                  [('category', None, lambda i: CATEGORIES[i]), ('population', 0, 'u24')], 3),
    'tables/DiscShapes.bin': ('DiscShapes $6AD3: the two shifts of the four disc shapes (Disc)',
                              [('shape', None, str), ('shift 1', 0, 'u8'), ('shift 2', 1, 'u8')], 2),
    'tables/ZoneFrame.bin': ('ZoneFrame $8A08: the eight cells round a zone centre and their empty frame cell '
                             '(PickFrameCell)',
                             [('cell', None, str), ('row step', 0, 's8'), ('column step', 1, 's8'),
                              ('frame cell', 2, 'h8')], 3),
    'tables/BuildingKinds.bin': ('BuildingKinds $8813: per building type (the first tile byte AND $3F) its routine '
                                 '(BuildingRoutines), level and density; the last row is the end mark',
                                 [('type', 0, 'h8'), ('routine', 1, 'u8'), ('level', 2, 'u8'), ('density', 3, 'u8')],
                                 4, None, 2),
}
GRIDS = {'tables/CoverKernel.bin': (5, 'CoverKernel $7BEF: the 5 x 5 police and fire coverage kernel, the shift of '
                                       'the strength at each cell (9: none)'),
         'tables/PollutionKernel.bin': (6, 'PollutionKernel $7C77: the 6 x 6 kernel of a source\'s pollution'),
         'tables/TrafficKernel.bin': (6, 'TrafficKernel $7C9B: the 6 x 6 kernel of the traffic\'s pollution')}
PARALLEL = {  # name: (comment, label column, [(title, start, count, format)])
    'tables/Crossings.bin': ('Crossings $7062: a network laid over another: the cell crossed and the crossing cell '
                             '(CrossNetwork)', None),
    'tables/Funding.bin': ('Funding $950A: by the share granted (funded / (cost / 8)) the roads\' and rails\' decay '
                           'mask (DecayMasks) and the police and fire strength (StrengthLevels; ApplyFunding)',
                           ('share', [('decay mask', 0, 16, 'h8'), ('strength', 16, 16, 'u8')])),
    'tables/Coast.bin': ('Coast $6B21: the 66 neighbour masks (row above, left and right, row below) a water cell '
                         'next to land may match, and the coast cell it becomes (MakeCoast)',
                         ('pattern', [('mask', 0, 66, 'b8'), ('cell', 66, 66, 'h8')])),
}


def fmt_val(d, i, f):
    if f == 'u8':
        return str(d[i])
    if f == 's8':
        return str(d[i] - 256 if d[i] > 127 else d[i])
    if f == 'h8':
        return '$%02X' % d[i]
    if f == 'b8':
        return '%' + format(d[i], '08b')
    if f == 'u16':
        return str(d[i] | d[i + 1] << 8)
    if f == 'u24':
        return str(d[i] | d[i + 1] << 8 | d[i + 2] << 16)
    raise ValueError(f)


def val_bytes(t, f):
    v = num(t)
    if f in ('u8', 'h8', 'b8'):
        return bytes([v])
    if f == 's8':
        return bytes([v & 255])
    if f == 'u16':
        return bytes([v & 255, v >> 8])
    if f == 'u24':
        return bytes([v & 255, (v >> 8) & 255, v >> 16])
    raise ValueError(f)


def csv_text(comment, header, rows):
    lines = ['# ' + comment, ','.join(header)] + [','.join(r) for r in rows]
    return ('\n'.join(lines) + '\n').encode('utf-8')


def csv_rows(t):
    lines = [l for l in t.decode('utf-8').split('\n') if l.strip() and not l.startswith('#')]
    return lines[0].split(','), [l.split(',') for l in lines[1:]]


def table_to_csv(name, d):
    if name in GRIDS:
        n, comment = GRIDS[name]
        return csv_text(comment, ['column %d' % c for c in range(n)],
                        [[str(d[r * n + c]) for c in range(n)] for r in range(n)])
    if name in PARALLEL:
        comment, spec = PARALLEL[name]
        if spec is None:  # Crossings: 3 groups of 6 cells and 6 results
            rows = [[NETS[g], '$%02X' % d[12 * g + i], '$%02X' % d[12 * g + 6 + i]] for g in range(3) for i in range(6)]
            return csv_text(comment, ['network (label)', 'cell', 'crossing'], rows)
        label, cols = spec
        n = cols[0][2]
        rows = [[str(i)] + [fmt_val(d, s + i, f) for _t, s, _n, f in cols] for i in range(n)]
        return csv_text(comment, [label + ' (label)'] + [c[0] for c in cols], rows)
    spec = TABLES[name]
    comment, cols, size = spec[:3]
    tail = spec[4] if len(spec) > 4 else 0
    n = (len(d) - tail) // size
    rows = []
    for r in range(n):
        rows.append([c[2](r) if c[1] is None else fmt_val(d, r * size + c[1], c[2]) for c in cols])
    if tail:
        rows.append(['end'] + ['$%02X' % b for b in d[len(d) - tail:]])
    header = [c[0] + (' (label)' if c[1] is None else '') for c in cols]
    return csv_text(comment, header, rows)


def csv_to_table(name, t):
    header, rows = csv_rows(t)
    out = bytearray()
    if name in GRIDS:
        for r in rows:
            out += bytes(num(v) for v in r)
        return bytes(out)
    if name in PARALLEL:
        comment, spec = PARALLEL[name]
        if spec is None:
            for g in range(3):
                grp = rows[6 * g:6 * g + 6]
                out += bytes(num(r[1]) for r in grp) + bytes(num(r[2]) for r in grp)
            return bytes(out)
        _label, cols = spec
        for k, (_t, _s, _n, f) in enumerate(cols):
            for r in rows:
                out += val_bytes(r[1 + k], f)
        return bytes(out)
    spec = TABLES[name]
    cols, size = spec[1], spec[2]
    for r in rows:
        if r[0] == 'end':
            out += bytes(num(v) for v in r[1:])
            continue
        rec = bytearray(size)
        for k, c in enumerate(cols):
            if c[1] is not None:
                b = val_bytes(r[k], c[2])
                rec[c[1]:c[1] + len(b)] = b
        out += rec
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# The table of formats, install, build and check
# ---------------------------------------------------------------------------------------------------------------
STRINGS = {'text/GameTexts.bin': 'GameTexts $5FC6 (FindText): the tools, levels, categories and messages',
           'text/MonthNames.bin': 'MonthNames $5F8A (PrintDate): the twelve months'}


def editable(name):
    """(suffix, to_editable(name, bytes), from_editable(name, data)) for a resource with an editable form"""
    if name == 'screen/LoadingScreen.bin':
        return '.png', lambda n, d: screen_to_png(d), lambda n, d: png_to_screen(d)
    if name == 'graphics/Pointer.bin':
        return '.png', lambda n, d: mono_to_png(d, 8, 16, pointer_order), \
            lambda n, d: png_to_mono(d, 16, pointer_order)
    if name == 'graphics/Movers.bin':
        return '.png', lambda n, d: mono_to_png(d, 80, 16, movers_order), \
            lambda n, d: png_to_mono(d, 160, movers_order)
    if name in STRINGS:
        return '.txt', lambda n, d: strings_to_txt(d, STRINGS[n]), lambda n, d: txt_to_strings(d)
    if name.startswith('text/menus/'):
        return '.txt', lambda n, d: menu_to_txt(d), lambda n, d: txt_to_menu(d)
    if name.startswith('text/inline/'):
        return '.txt', lambda n, d: inline_to_txt(d), lambda n, d: txt_to_inline(d)
    if name in TABLES or name in GRIDS or name in PARALLEL:
        return '.csv', table_to_csv, csv_to_table
    return None


def group_of(name):
    for sheet, (tiles, attrs) in TILE_GROUPS.items():
        if name in (tiles, attrs):
            return sheet, tiles, attrs
    return None


def write(rel, data):
    path = os.path.join(RES, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)


def remove_stale(name):
    stale = os.path.join(RES, name)
    if os.path.exists(stale):
        os.remove(stale)


def install(files):
    for name, data in files.items():
        g = group_of(name)
        if g:
            sheet, tiles, attrs = g
            if tiles in files and attrs in files and name == tiles:
                out = tiles_to_png(files[tiles], files[attrs])
                if png_to_tiles(out) != (files[tiles], files[attrs]):
                    raise SystemExit('res: %s does not convert back to its bytes' % sheet)
                write(sheet, out)
            remove_stale(name)
            continue
        fmt = editable(name)
        if fmt:
            suffix, to_ed, from_ed = fmt
            out = to_ed(name, data)
            if from_ed(name, out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            write(os.path.splitext(name)[0] + suffix, out)
            remove_stale(name)
        else:
            write(name, data)


def sources():
    """(src path, [the .bin names it builds], decoder or None) for every file of src/res"""
    for top, _dirs, files in os.walk(RES):
        for f in sorted(files):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            if rel in TILE_GROUPS:
                yield src, list(TILE_GROUPS[rel]), 'tiles'
                continue
            stem, ext = os.path.splitext(rel)
            name = stem + '.bin'
            fmt = editable(name) if ext != '.bin' else None
            if fmt and fmt[0] == ext:
                yield src, [name], fmt
            else:
                yield src, [rel], None


def decode(src, names, fmt):
    data = open(src, 'rb').read()
    if fmt == 'tiles':
        return dict(zip(names, png_to_tiles(data)))
    if fmt:
        return {names[0]: fmt[2](names[0], data)}
    return {names[0]: data}


def build(out):
    for src, names, fmt in sources():
        for name, data in decode(src, names, fmt).items():
            dst = os.path.join(out, name)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, 'wb').write(data)


def check(against=None):
    bad = count = 0
    for src, names, fmt in sources():
        if not fmt:
            continue
        count += 1
        ed = open(src, 'rb').read()
        got = decode(src, names, fmt)
        if fmt == 'tiles':
            again = tiles_to_png(got[names[0]], got[names[1]])
        else:
            again = fmt[1](names[0], got[names[0]])
        if again != ed:
            print('res: %s does not round-trip' % src)
            bad += 1
        if against:
            for name, data in got.items():
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

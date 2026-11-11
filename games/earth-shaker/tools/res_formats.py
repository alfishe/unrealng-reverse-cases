#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of src/game/game.ann.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN (and the .inc)
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- graphics/ cell graphics (36-byte records: 4 attributes top left, top right, bottom right, bottom left, then 32
  pixel bytes, even pixel lines left byte then right, odd lines right then left): a colour PNG of 16 x 16 tiles,
  8 a row, a grey line between them. The palette has 64 Spectrum entries, index = flash x 32 + ink x 16 + bright x 8
  + colour, and grey (64): each pixel shows its colour and says by its index whether it is ink or paper, so the
  bytes come back exactly. A quarter whose 64 pixels are all paper (or all ink) cannot show its other colour; the
  PNG text chunk `es-cells` keeps those quarters' attributes (tile, quarter, attribute) and the tile count.
- graphics/ 8 x 8 glyph sheets (the font, the map glyphs, the map frame): an indexed PNG, 0 paper (black), 1 ink
  (white), 2 grid (grey); the text chunk `es-sheet` holds the glyph count and the glyphs a row.
- graphics/logo.png: the logo's 2048 bytes (the layout of the screen's top third) as a 256 x 64 picture, the same
  palette as the glyph sheets.
- graphics/logo-attrs.txt, graphics/teleport-frames.txt, tables/bar-attrs.txt: attribute bytes as hex, 32 a line
  (a screen row), `#` lines comments.
- texts/: UTF-8, one quoted string a line, `#` lines comments; printable ASCII as itself, `\\xNN` any other byte,
  `\\"` and `\\\\` escaped. The build joins the strings.
- music/: a tune is one note a line `DRUM N1 N2 LENGTH` (decimal) and the end `end DRUM` (the record whose N1 is
  255); periods.txt one period a line `N PERIOD`; cave-tunes.txt the tune of each group of four caves by name (an
  `@res ... include`: the build writes cave-tunes.inc with DW lines, kit/resinc.py).
- caves/caves.txt: the 32 caves, each its 14 parameter bytes as named fields and 20 lines of 30 cells, one character
  a cell (the legend in the file's header).
- tables/*.csv: a header line naming the columns, `#` lines comments, numbers decimal or `$hex`, characters quoted.
Any other file (leftovers/) stays its bytes.
"""
import argparse
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))


def num(t):
    t = t.strip()
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


def lines_of(raw):
    return [ln for ln in raw.decode('utf-8').split('\n') if ln.strip() and not ln.startswith('#')]


def head(comments):
    return ['# ' + c if c else '#' for c in comments]


def text_file(lines):
    return ('\n'.join(lines) + '\n').encode('utf-8')


# ---------------------------------------------------------------------------------------------------------------
# Cell graphics: 36-byte records as colour tiles
# ---------------------------------------------------------------------------------------------------------------
def zx_rgb(colour, bright):
    v = 255 if bright else 215
    return ((colour >> 1) & 1) * v, ((colour >> 2) & 1) * v, (colour & 1) * v


SCREEN_PALETTE = []
for _i in range(64):
    SCREEN_PALETTE += zx_rgb(_i & 7, (_i >> 3) & 1)
GREY = 64
CELL_PALETTE = SCREEN_PALETTE + [128, 128, 128]
TILE, COLS = 16, 8
CELLS = {'graphics/cells-a.bin', 'graphics/cells-b.bin', 'graphics/extra-a.bin', 'graphics/extra-b.bin',
         'graphics/extra-c.bin', 'graphics/extra-d.bin', 'graphics/empty-frames.bin', 'graphics/blank.bin'}


def cell_pixel(k):
    """pixel byte k (0-31) of a record -> (pixel line, byte column)"""
    line = k // 2
    return line, (k % 2) if line % 2 == 0 else 1 - k % 2


def quarter(line, col):
    """the attribute of a pixel: 0 top left, 1 top right, 2 bottom right, 3 bottom left"""
    return (0 if col == 0 else 1) if line < 8 else (2 if col == 1 else 3)


def tile_xy(t):
    return 1 + (t % COLS) * (TILE + 1), 1 + (t // COLS) * (TILE + 1)


def cells_to_png(data):
    from PIL import Image, PngImagePlugin
    if len(data) % 36:
        raise ValueError('cell graphics: %d bytes is no whole number of 36-byte records' % len(data))
    n = len(data) // 36
    rows = (n + COLS - 1) // COLS
    img = Image.new('P', (1 + min(n, COLS) * (TILE + 1), 1 + rows * (TILE + 1)), GREY)
    img.putpalette(CELL_PALETTE + [0] * (768 - len(CELL_PALETTE)))
    px = img.load()
    hidden = []
    for t in range(n):
        rec = data[36 * t:36 * t + 36]
        attrs, pix = rec[:4], rec[4:]
        x0, y0 = tile_xy(t)
        seen = [set(), set(), set(), set()]
        for k in range(32):
            line, col = cell_pixel(k)
            q = quarter(line, col)
            a = attrs[q]
            for bit in range(8):
                ink = (pix[k] >> (7 - bit)) & 1
                seen[q].add(ink)
                colour = a & 7 if ink else (a >> 3) & 7
                px[x0 + col * 8 + bit, y0 + line] = (a >> 7) * 32 + ink * 16 + ((a >> 6) & 1) * 8 + colour
        hidden += [[t, q, attrs[q]] for q in range(4) if len(seen[q]) < 2]
    info = PngImagePlugin.PngInfo()
    info.add_text('es-cells', json.dumps({'tiles': n, 'hidden': hidden}, separators=(',', ':')))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_cells(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    meta = json.loads(img.text['es-cells'])
    hidden = {(t, q): a for t, q, a in meta['hidden']}
    out = bytearray()
    for t in range(meta['tiles']):
        x0, y0 = tile_xy(t)
        pix, parts = bytearray(32), [{}, {}, {}, {}]
        for k in range(32):
            line, col = cell_pixel(k)
            q = quarter(line, col)
            b = 0
            for bit in range(8):
                i = px[x0 + col * 8 + bit, y0 + line]
                if i >= 64:
                    raise ValueError('tile %d: a grey pixel inside the tile' % t)
                ink = (i >> 4) & 1
                b = b << 1 | ink
                fb = (i >> 5, (i >> 3) & 1)
                if parts[q].setdefault('fb', fb) != fb:
                    raise ValueError('tile %d quarter %d: two flash / bright values' % (t, q))
                if parts[q].setdefault(ink, i & 7) != i & 7:
                    raise ValueError('tile %d quarter %d: two %s colours' % (t, q, 'ink' if ink else 'paper'))
            pix[k] = b
        attrs = bytearray(4)
        for q in range(4):
            p = parts[q]
            attrs[q] = hidden[(t, q)] if (t, q) in hidden else p['fb'][0] << 7 | p['fb'][1] << 6 | p[0] << 3 | p[1]
        out += attrs + pix
    return bytes(out)


def read_cells(name):
    """the bytes of a cell graphics resource from its PNG in src/res (tools/fig_caves.py)"""
    return png_to_cells(open(os.path.join(RES, os.path.splitext(name)[0] + '.png'), 'rb').read())


# ---------------------------------------------------------------------------------------------------------------
# 8 x 8 glyph sheets and the logo: 1-bit pictures
# ---------------------------------------------------------------------------------------------------------------
MONO = [0, 0, 0, 255, 255, 255, 128, 128, 128]
GLYPHS = {'graphics/font.bin': 16, 'graphics/map-glyphs.bin': 16, 'graphics/map-frame.bin': 8}


def mono_png(width, height, meta, key):
    from PIL import Image, PngImagePlugin
    img = Image.new('P', (width, height), 2)
    img.putpalette(MONO + [0] * (768 - len(MONO)))
    info = PngImagePlugin.PngInfo()
    info.add_text(key, json.dumps(meta, separators=(',', ':')))
    return img, info


def save(img, info):
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def glyphs_to_png(name, data):
    n, cols = len(data) // 8, GLYPHS[name]
    rows = (n + cols - 1) // cols
    img, info = mono_png(1 + cols * 9, 1 + rows * 9, {'glyphs': n, 'cols': cols}, 'es-sheet')
    px = img.load()
    for g in range(n):
        x0, y0 = 1 + (g % cols) * 9, 1 + (g // cols) * 9
        for r in range(8):
            for bit in range(8):
                px[x0 + bit, y0 + r] = (data[8 * g + r] >> (7 - bit)) & 1
    return save(img, info)


def png_to_glyphs(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    meta = json.loads(img.text['es-sheet'])
    out = bytearray()
    for g in range(meta['glyphs']):
        x0, y0 = 1 + (g % meta['cols']) * 9, 1 + (g // meta['cols']) * 9
        for r in range(8):
            b = 0
            for bit in range(8):
                b = b << 1 | (1 if px[x0 + bit, y0 + r] == 1 else 0)
            out.append(b)
    return bytes(out)


def third_xy(o):
    """byte o of a screen third -> (x, y) of its first pixel"""
    return (o & 31) * 8, ((o >> 5) & 7) * 8 + (o >> 8)


def logo_to_png(data):
    img, info = mono_png(256, 64, {'bytes': len(data)}, 'es-logo')
    px = img.load()
    for o, b in enumerate(data):
        x, y = third_xy(o)
        for bit in range(8):
            px[x + bit, y] = (b >> (7 - bit)) & 1
    return save(img, info)


def png_to_logo(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    px = img.load()
    out = bytearray()
    for o in range(json.loads(img.text['es-logo'])['bytes']):
        x, y = third_xy(o)
        b = 0
        for bit in range(8):
            b = b << 1 | (1 if px[x + bit, y] == 1 else 0)
        out.append(b)
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Attribute bytes as hex rows
# ---------------------------------------------------------------------------------------------------------------
HEX_HEAD = {
    'graphics/logo-attrs.bin': ['LogoAttrs $FC00: the logo\'s attributes, 8 screen rows of 32 (ShowLogo $9091 copies',
                                'them to $5800).'],
    'graphics/teleport-frames.bin': ['TeleportFrames $7300: four attribute screens of 24 rows of 32, frame 0 first',
                                     '(TeleportFlashOut $9230 / TeleportFlashIn $924F copy frame AnimPhase to $5800).'],
    'tables/bar-attrs.bin': ['BarAttrs $BC92: the time bar\'s attributes, 2 rows of 32 (BarColours $9224).'],
}


def hex_out(name, d):
    lines = head(HEX_HEAD[name] + ['Hex bytes, 32 a line (one screen row); "frame N" lines only mark the frames.'])
    for r in range(0, len(d), 32):
        if name == 'graphics/teleport-frames.bin' and r % 768 == 0:
            lines.append('frame %d' % (r // 768))
        lines.append(' '.join('%02X' % b for b in d[r:r + 32]))
    return text_file(lines)


def hex_in(_name, raw):
    out = bytearray()
    for ln in lines_of(raw):
        if not ln.startswith('frame'):
            out += bytes(int(x, 16) for x in ln.split())
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Texts: quoted strings
# ---------------------------------------------------------------------------------------------------------------
def quote(bs):
    t = ''
    for b in bs:
        if b in (0x22, 0x5C):
            t += '\\' + chr(b)
        elif 0x20 <= b < 0x7F:
            t += chr(b)
        else:
            t += '\\x%02X' % b
    return '"' + t + '"'


def unquote(s):
    s = s.strip()
    if not (len(s) >= 2 and s.startswith('"') and s.endswith('"')):
        raise ValueError('not a quoted string: %s' % s)
    s, out, i = s[1:-1], bytearray(), 0
    while i < len(s):
        if s[i] == '\\':
            if s[i + 1] == 'x':
                out.append(int(s[i + 2:i + 4], 16))
                i += 4
            else:
                out.append(ord(s[i + 1]))
                i += 2
        else:
            if ord(s[i]) > 0x7E:
                raise ValueError('no game code for %r in %s' % (s[i], s))
            out.append(ord(s[i]))
            i += 1
    return bytes(out)


# the .bin name -> (header lines, the cut: a list of string offsets, or a number = a fixed length)
TEXTS = {
    'texts/scroller.bin': (['ScrollerText $6D42: the menu scroller (RunScroller $8AEB), printed one character at a',
                            'time at the right of the bottom line; the 0 ends it. Cut at 48 characters a line for',
                            'reading only.'], 48),
    'texts/cave-names.bin': (['CaveNames $9700: the 32 cave names, 20 characters each, space padded: the names',
                              'CaveIntro $92D4 shows and the passwords FindPassword $8E91 accepts. One cave a line.'],
                             20),
    'texts/password-prompt.bin': (['EnterPasswordText $9AE8: the password screen\'s line (ShowPasswordPrompt',
                                   '$8DFF); EnterPassword $8E2D prints one character of it from $9AED as the blank',
                                   'of a deleted character.'], [0]),
    'texts/menu.bin': (['MenuTexts $AB00: the menu\'s lines (ShowMenuTexts $8A3C): START GAME, REDEFINE KEYS, the',
                        '1988 DEMO MODE line (no longer printed), QUIT GAME and the copyright line.'],
                       [0, 0x12, 0x27, 0x38, 0x49]),
    'texts/win.bin': (['WinTexts $AB6A: the eight lines of the win screen (ShowWinTexts $A815).'],
                      [0, 0x1A, 0x39, 0x41, 0x61, 0x7D, 0x9D, 0xBB]),
    'texts/credits.bin': (['Credits $AC2E: the 1988 credit line, read by no code (a leftover).'], [0]),
    'texts/game-over.bin': (['GameOverTexts $AA4E: GAME OVER, YOU SCORED, AND REACHED LEVEL (ShowGameOver $8B7F).'],
                            [0, 9, 0x13]),
    'texts/hud-labels.bin': (['HudLabels $BB00: LEVEL, LIVES LEFT:, SCORE: of the cave intro',
                              '(ShowLevelLivesScore $89A7).'], [0, 5, 0x10]),
    'texts/hud-line.bin': (['HudLine $BCE0: the bottom line (ShowHudLine $836A); a-e are the HUD icons of the font',
                            '(IconGlyphs $BF08); ShowCounters / ShowScore overwrite the digits.'], [0]),
    'texts/key-prompts.bin': (['KeyPrompts $A978: the five prompts of RedefineKeys $8C30, 19 characters each.'], 19),
    'texts/control.bin': (['ControlTexts $EC95: the two control lines of the 1990 menu (ShowControlTexts $ECC5).'],
                          24),
}
QUOTE_HEAD = ['UTF-8, one quoted string a line: printable ASCII as itself, \\xNN any other byte, \\" and \\\\',
              'escaped. The build joins the strings.']


def text_out(name, d):
    comments, cut = TEXTS[name]
    starts = list(range(0, len(d), cut)) if isinstance(cut, int) else cut
    parts = [d[s:e] for s, e in zip(starts, starts[1:] + [len(d)])]
    return text_file(head(comments + QUOTE_HEAD) + [quote(p) for p in parts])


def text_in(_name, raw):
    return b''.join(unquote(ln) for ln in lines_of(raw))


# ---------------------------------------------------------------------------------------------------------------
# Music: tunes, the periods, the cave tune table
# ---------------------------------------------------------------------------------------------------------------
TUNES = {
    'music/win.bin': 'WinTune $6EF4: the win (WinGame $A8BF, PlayWinTune $A615).',
    'music/game-over.bin': 'GameOverTune $AA00: the game over (PlayGameOverTune $8B78).',
    'music/life.bin': 'LifeTune $AC5F: the extra life (PotionTune $91C1).',
    'music/title.bin': 'TitleTune $AD00: the title (PlayTitleTune $8A35); MenuKeys $8B29 knows its end $B269.',
    'music/map.bin': 'MapTune $E8E8: the map screen (PlayMapTune $E8E1).',
    'music/cave-1.bin': 'CaveTune1 $BB80: caves 1-4 (CaveTunes $EE24, PlayCaveTune $EE34).',
    'music/cave-2.bin': 'CaveTune2 $F100: caves 5-8.',
    'music/cave-3.bin': 'CaveTune3 $F1D0: caves 9-12.',
    'music/cave-4.bin': 'CaveTune4 $F212: caves 13-16.',
    'music/cave-5.bin': 'CaveTune5 $F302: caves 17-20.',
    'music/cave-6.bin': 'CaveTune6 $F398: caves 21-24.',
    'music/cave-7.bin': 'CaveTune7 $F298: caves 25-28.',
    'music/cave-8.bin': 'CaveTune8 $F152: caves 29-32.',
}
TUNE_HEAD = ['One note a line: DRUM N1 N2 LENGTH (decimal). PlayTune $88CE: DRUM 1 is a ROM BEEPER click with',
             'HL = $020B, DE = 3 before the note, 2 one with HL = $0106, DE = 5, other values none; N1 and N2 are the',
             'two voices\' periods NotePeriods[N] (music/periods.txt); LENGTH x 256 loop turns. "end DRUM" is the',
             'last record, its N1 255.']


def tune_out(name, d):
    lines, p = head([TUNES[name]] + TUNE_HEAD), 0
    while True:
        if p + 2 > len(d):
            raise ValueError('%s: no end record' % name)
        if d[p + 1] == 0xFF:
            lines.append('end %d' % d[p])
            p += 2
            break
        lines.append('%d %d %d %d' % tuple(d[p:p + 4]))
        p += 4
    if p != len(d):
        raise ValueError('%s: %d bytes after the end' % (name, len(d) - p))
    return text_file(lines)


def tune_in(_name, raw):
    out = bytearray()
    for ln in lines_of(raw):
        t = ln.split()
        out += bytes([num(t[1]), 0xFF]) if t[0] == 'end' else bytes(num(x) for x in t)
    return bytes(out)


def periods_out(_name, d):
    lines = head(['NotePeriods $BC00: the note periods, a big-endian word for note N at $BC00 + 2N (PlayTune $88CE',
                  'loads it into IX / IY: the loop turns between two toggles of the speaker). One note a line:',
                  'N PERIOD (decimal).'])
    lines += ['%d %d' % (n, d[2 * n] << 8 | d[2 * n + 1]) for n in range(len(d) // 2)]
    return text_file(lines)


def periods_in(_name, raw):
    out = bytearray()
    for n, ln in enumerate(lines_of(raw)):
        k, v = ln.split()
        if num(k) != n:
            raise ValueError('periods: note %s out of order' % k)
        out += bytes([num(v) >> 8, num(v) & 255])
    return bytes(out)


SYMS = None


def symbols():
    global SYMS
    if SYMS is None:
        import resinc
        SYMS = resinc.symbols(ROOT)
    return SYMS


def cavetunes_out(_name, d):
    names = symbols()[0]
    lines = head(['CaveTunes $EE24: the tune of each group of four caves, by name (PlayCaveTune $EE34 takes word',
                  '(CaveNumber - 1) / 4). An @res ... include: the build writes cave-tunes.inc with a DW line a',
                  'tune, so a moved tune is followed. One group a line: CAVES NAME.'])
    for g in range(len(d) // 2):
        w = d[2 * g] | d[2 * g + 1] << 8
        lines.append('%d-%d %s' % (4 * g + 1, 4 * g + 4, names.get(w, '$%04X' % w)))
    return text_file(lines)


def cavetunes_words(raw):
    return [ln.split()[1] for ln in lines_of(raw)]


def cavetunes_in(_name, raw):
    addrs = symbols()[1]
    out = bytearray()
    for w in cavetunes_words(raw):
        a = num(w) if w.startswith('$') else addrs[w]
        out += bytes([a & 255, a >> 8])
    return bytes(out)


def cavetunes_inc(raw):
    import resinc
    return resinc.lines([('w', w) for w in cavetunes_words(raw)],
                        ['cave-tunes.inc: written by tools/res_formats.py from src/res/music/cave-tunes.txt'])


# ---------------------------------------------------------------------------------------------------------------
# The caves
# ---------------------------------------------------------------------------------------------------------------
CAVE_W, CAVE_H, CAVE_CELLS, CAVE_SIZE = 30, 20, 300, 314
LEGEND = '.X0RL#:*TZAS+DOF'  # cell codes 0-15
LEGEND_NAMES = ['empty', 'exit', 'boulder', 'player facing right', 'player facing left', 'wall', 'earth', 'gem',
                'jelly bean', 'force field', 'anti-gravity arrow', 'switch box', 'potion (extra life)',
                'teleporter', 'bubble', 'fire']
PARAMS = [('gems_needed', 1), ('gem_value', 1), ('start', 2), ('gems_digits', 2), ('earth_graphic', 2),
          ('wall_graphic', 2), ('door_colour', 1), ('boulder_colour', 1), ('wall1_colour', 1), ('earth_colour', 1)]
CAVES_HEAD = [
    'CaveData $C000: the 32 caves, 314 bytes each (UnpackCave $82B6: cave N at $BEC6 + 314N). A cave here is its',
    '14 parameter bytes (copied to CaveParams $FD9A-$FDA7) as named fields, then 20 rows of 30 cells, one',
    'character a cell (the bytes hold the cells first, two a byte, the left cell in the low nibble):',
    ] + ['  %s  %X %s' % (LEGEND[k], k, LEGEND_NAMES[k]) for k in range(16)] + [
    'The parameters: gems_needed (GemsNeeded $FD9A: the count that opens the exit), gem_value (GemValue $FD9B:',
    'points a gem), start (PlayerIndex $FD9C: the player\'s cell, 30 x row + column), gems_digits',
    '(GemsNeededDigits $FD9E: gems_needed as the two HUD digits, tens first), earth_graphic and wall_graphic',
    '(EarthGraphic $FDA0 / WallGraphic $FDA2: the cell graphics of earth (6) and wall (5), written into',
    'CellGraphicsTable by CaveSetup $9313; earth $A450 GfxFallingEarth falls, SetEarthFalls $FB81), door_colour,',
    'boulder_colour, wall1_colour, earth_colour (the attributes CaveSetup writes into GfxExit $9B08, GfxBoulder',
    '$9B2C, GfxWall1 $9CB8 and GfxEarth $9B50: bright, plain, plain, bright). The two graphics are written by',
    'name (an @res ... include: the build writes caves.inc with a DW line each, so a moved graphic is followed).',
    'Numbers decimal or $hex; text after ; is a comment.']


def caves_out(_name, d):
    lines = head(CAVES_HEAD)
    for n in range(len(d) // CAVE_SIZE):
        c = d[CAVE_SIZE * n:CAVE_SIZE * (n + 1)]
        p, o = c[CAVE_CELLS:], 0
        lines += ['', 'cave %d' % (n + 1)]
        for field, size in PARAMS:
            v = p[o] if size == 1 else p[o] | p[o + 1] << 8
            if field == 'start':
                txt = '%d ; row %d, column %d' % (v, v // CAVE_W, v % CAVE_W)
            elif field == 'gems_digits':
                txt = '%d %d' % (p[o], p[o + 1])
            elif field.endswith('graphic'):
                txt = symbols()[0].get(v, '$%04X' % v)
            elif field.endswith('colour'):
                txt = '$%02X' % v
            else:
                txt = str(v)
            o += size
            lines.append('%s %s' % (field, txt))
        cells = [x for b in c[:CAVE_CELLS] for x in (b & 15, b >> 4)]
        lines += [''.join(LEGEND[x] for x in cells[CAVE_W * r:CAVE_W * (r + 1)]) for r in range(CAVE_H)]
    return text_file(lines)


def caves_in(_name, raw):
    out, cave = bytearray(), None

    def flush():
        if cave is None:
            return
        if len(cave['rows']) != CAVE_H:
            raise ValueError('cave %d: %d rows' % (cave['n'], len(cave['rows'])))
        cells = [LEGEND.index(ch) for r in cave['rows'] for ch in r]
        out.extend(cells[i] | cells[i + 1] << 4 for i in range(0, len(cells), 2))
        for field, size in PARAMS:
            v = cave['p'][field]
            if field == 'gems_digits':
                out.extend(v)
            elif size == 1:
                out.append(v)
            else:
                out.extend((v & 255, v >> 8))

    for ln in raw.decode('utf-8').split('\n'):
        if not ln.strip() or ln == '#' or ln.startswith('# '):  # a row may start with '#', a wall
            continue
        t = ln.split(';')[0].split()
        if t[0] == 'cave':
            flush()
            cave = {'n': int(t[1]), 'p': {}, 'rows': [], 'names': {}}
        elif t[0] in dict(PARAMS):
            if t[0] == 'gems_digits':
                cave['p'][t[0]] = [num(x) for x in t[1:3]]
            elif t[0].endswith('graphic'):
                cave['p'][t[0]] = num(t[1]) if t[1].startswith('$') else symbols()[1][t[1]]
                cave['names'][t[0]] = t[1]
            else:
                cave['p'][t[0]] = num(t[1])
        else:
            if len(ln) != CAVE_W:
                raise ValueError('cave %d: a row of %d cells' % (cave['n'], len(ln)))
            cave['rows'].append(ln)
    flush()
    return bytes(out)


def caves_inc(raw):
    """caves.inc: the cells and the byte parameters as DB, the two graphic words as DW lines by name (kit/resinc.py),
    so a moved graphic is followed"""
    import resinc
    marks = symbols()[2].get('caves/caves.bin', {})
    d = caves_in(None, raw)
    names = []
    for ln in raw.decode('utf-8').split('\n'):
        t = ln.split(';')[0].split()
        if t and t[0] in ('earth_graphic', 'wall_graphic') and not ln.startswith('#'):
            names.append(t[1])
    items, k = [], 0
    for n in range(len(d) // CAVE_SIZE):
        base = CAVE_SIZE * n
        o = 0
        for i in range(CAVE_CELLS + 6):  # cells, gems_needed, gem_value, start, gems_digits
            if base + i in marks:
                items.append(('label', marks[base + i]))
            items.append(('b', d[base + i]))
        for _ in range(2):  # earth_graphic, wall_graphic
            items.append(('w', names[k]))
            k += 1
        items += [('b', x) for x in d[base + CAVE_CELLS + 10:base + CAVE_SIZE]]
    return resinc.lines(items, ['caves.inc: written by tools/res_formats.py from src/res/caves/caves.txt'])


def read_caves(path=None):
    """the caves of src/res/caves/caves.txt: [(params {field: value}, 600 cell codes)] (tools/fig_caves.py)"""
    d = caves_in(None, open(path or os.path.join(RES, 'caves', 'caves.txt'), 'rb').read())
    caves = []
    for n in range(len(d) // CAVE_SIZE):
        c = d[CAVE_SIZE * n:CAVE_SIZE * (n + 1)]
        p, o, params = c[CAVE_CELLS:], 0, {}
        for field, size in PARAMS:
            params[field] = p[o] if size == 1 else p[o] | p[o + 1] << 8
            o += size
        caves.append((params, [x for b in c[:CAVE_CELLS] for x in (b & 15, b >> 4)]))
    return caves


# ---------------------------------------------------------------------------------------------------------------
# Tables: CSV
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, columns, rows):
    return text_file(head(comments) + [','.join(columns)] + [','.join(str(v) for v in r) for r in rows])


def csv_rows(raw):
    rows = [[c.strip() for c in line.split(',')] for line in lines_of(raw)]
    return rows[1:]


def keys_out(_name, d):
    rows = [['$%02X' % d[i], '$%02X' % d[i + 1], quote(d[i + 2:i + 3])] for i in range(0, len(d), 3)]
    return csv_out(['KeyTable $A900: the 40 keys WaitKey $8C1D scans, in its order: the half row (the high byte of',
                    'port $FE), the bit mask, the character printed (c CAPS SHIFT, s SYMBOL SHIFT, e ENTER).',
                    'RedefineKeys $8C30, EnterName $7F00 and EnterPassword $8E2D use them.'],
                   ['half_row', 'mask', 'char'], rows)


def keys_in(_name, raw):
    return bytes(b for r in csv_rows(raw) for b in (num(r[0]), num(r[1]), unquote(r[2])[0]))


def hiscores_out(_name, d):
    rows = [[''.join(str(x) for x in d[i:i + 6]), quote(d[i + 6:i + 15])] for i in range(0, len(d), 15)]
    return csv_out(['HiScoreTable $FD14: the high-score table as loaded (the defaults): 5 records, the score (6',
                    'digits, one byte each) and the name (9 characters).'], ['score', 'name'], rows)


def hiscores_in(_name, raw):
    out = bytearray()
    for score, name in csv_rows(raw):
        out += bytes(int(ch) for ch in score) + unquote(name)
    return bytes(out)


def mapattrs_out(_name, d):
    return csv_out(['MapAttrs $9A80: the map screen\'s attribute of each cell code 0-15 (MapCellAttr $EAB3).'],
                   ['code', 'cell', 'attr'], [[k, LEGEND_NAMES[k], '$%02X' % d[k]] for k in range(16)])


def mapattrs_in(_name, raw):
    return bytes(num(r[2]) for r in csv_rows(raw))


SITES = ['TryLeft $83C3', 'TryRight $8437', 'TryUp $84AD', 'TryDown $84F9', 'KeysStep $8759', 'FireLeft $876B',
         'FireRight $87C3', 'FireUp $881D', 'FireDown $8849']
CODE_HEAD = {
    'tables/kempston-code.bin': ['KempstonCode $EAC4: the joystick code JoystickControl $EC2E copies into the nine',
                                 'key sites: NOP x 4, IN A,($1F), AND mask, RET Z (JR NZ for the fire site).'],
    'tables/keyboard-code.bin': ['KeyboardCode $EB15: the keyboard code of the nine key sites as loaded (O, P, Q, A,',
                                 'M): LD A,row, OUT ($FF),A, IN A,($FE), AND mask, RET NZ (JR Z for the fire site).',
                                 'SaveKeyboardCode $EB66 copies the sites here, KeyboardControl $EBCA back.'],
}


def code_out(name, d):
    return csv_out(CODE_HEAD[name] + ['One site a line: the site, its 9 bytes in hex.'], ['site', 'bytes'],
                   [[SITES[i], ' '.join('%02X' % b for b in d[9 * i:9 * i + 9])] for i in range(len(d) // 9)])


def code_in(_name, raw):
    return bytes(int(x, 16) for r in csv_rows(raw) for x in r[1].split())


# ---------------------------------------------------------------------------------------------------------------
# The dispatch
# ---------------------------------------------------------------------------------------------------------------
def editable(name):
    if name in CELLS:
        return '.png', lambda n, d: cells_to_png(d), lambda n, d: png_to_cells(d)
    if name in GLYPHS:
        return '.png', glyphs_to_png, lambda n, d: png_to_glyphs(d)
    if name == 'graphics/logo.bin':
        return '.png', lambda n, d: logo_to_png(d), lambda n, d: png_to_logo(d)
    if name in HEX_HEAD:
        return '.txt', hex_out, hex_in
    if name in TEXTS:
        return '.txt', text_out, text_in
    if name in TUNES:
        return '.txt', tune_out, tune_in
    if name == 'music/periods.bin':
        return '.txt', periods_out, periods_in
    if name == 'music/cave-tunes.bin':
        return '.txt', cavetunes_out, cavetunes_in
    if name == 'caves/caves.bin':
        return '.txt', caves_out, caves_in
    if name == 'tables/keys.bin':
        return '.csv', keys_out, keys_in
    if name == 'tables/hiscores.bin':
        return '.csv', hiscores_out, hiscores_in
    if name == 'tables/map-attrs.bin':
        return '.csv', mapattrs_out, mapattrs_in
    if name in CODE_HEAD:
        return '.csv', code_out, code_in
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
            stale = os.path.join(RES, name)
            if os.path.exists(stale):
                os.remove(stale)
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


INCLUDES = {'music/cave-tunes.bin': lambda raw: cavetunes_inc(raw), 'caves/caves.bin': lambda raw: caves_inc(raw)}


def build(out):
    for src, name, fmt in sources():
        raw = open(src, 'rb').read()
        data = fmt[2](name, raw) if fmt else raw
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(data)
        if name in INCLUDES:
            open(os.path.splitext(dst)[0] + '.inc', 'w').write(INCLUDES[name](raw))


def check(against=None):
    bad = count = 0
    for src, name, fmt in sources():
        if not fmt:
            continue
        count += 1
        ed = open(src, 'rb').read()
        try:
            data = fmt[2](name, ed)
            ok = fmt[1](name, data) == ed and fmt[2](name, fmt[1](name, data)) == data
        except (ValueError, KeyError) as e:
            print('res: %s: %s' % (src, e))
            ok, data = False, None
        if not ok:
            print('res: %s does not round-trip' % src)
            bad += 1
        if against and data is not None:
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

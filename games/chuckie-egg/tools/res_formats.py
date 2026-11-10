#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the game's and the loader part's).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against work/mkgame/res   # ... and gives the bytes mkgame cut from the image

The formats (each folder's README.md lists its files):
- PNG sheets (graphics/, sprites/, loader/PictureGraphics): an indexed PNG, frames left to right in rows, one grid
  pixel between frames; palette 0 paper (black), 1 ink (white), 2 grid (grey). The PNG text chunk `ce-sheet` holds
  the layout (bytes across, bytes a frame, frames a row, frame count), so a sheet builds back on its own. Every
  graphic of the game is stored top row first (the draw routines go down the screen from the first byte, or up it
  from the last).
- maps/: one level a file, 21 rows of 32 cells, the top row first (the image stores row 0, the bottom, first); one
  character a cell (MAP_CELLS below; the file's header repeats the legend).
- tables/: CSV with a header line naming the columns; `#` lines are comments. Numbers are decimal or `$hex`.
- text/: one quoted string a line, `#` lines comments; printable ASCII as itself, `\\xNN` any other byte, `\\"` and
  `\\\\` escaped. A screen page (TEXT_PAGES) is one line a screen row, the top row first; the build restores the
  game's order (the title and the instructions page are stored bottom row first).
- text/SourceLeftover*.txt: the author's leftover assembler source, one editor line a file line: `NNNN "text"` (the
  line number, two BCD bytes), `- "text"` (a piece with no line number, cut off by the bytes before it), and `cut`
  at the end of a line whose closing `$0D` is under the bytes after it.
- text/KeySets.txt: the three key sets, one key a line, `type N direction KEY`.
- sound/Phrases.txt: the speech phrase table and the phrases (PHRASE_HEAD below).
- sound/*Tune.txt: one note a line, `duration pitch` (tenths of a second, semitones above middle C), `end`.
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
    return int(t[1:], 16) if t.startswith('$') else int(t, 0)


# ---------------------------------------------------------------------------------------------------------------
# PNG sheets
# ---------------------------------------------------------------------------------------------------------------
PALETTE = [0, 0, 0, 255, 255, 255, 128, 128, 128]

# the .bin name of the @res -> (bytes across, bytes a frame, frames a row)
SHEETS = {
    # the loading picture's 66 graphics $5CE3, character codes $60-$A1 (PrintPictureChar $5FC9)
    'loader/PictureGraphics.bin': (1, 8, 11),
    # the game's character set $84F0, codes 0-$9D: map cells 0-5, the HUD labels, the font, the title logo
    'graphics/CharacterSet.bin': (1, 8, 16),
    # codes $9E-$CB at $89E0: the HUD digits, the life icon, the A+F logo letters
    'graphics/HudCharacters.bin': (1, 8, 16),
    # $8DF0: Harry right 0-3, left 4-7, the duck 8-11, blank 12, Harry climbing 13-16 (DrawSprite $9A4C)
    'sprites/Sprites.bin': (2, 32, 17),
    # $9010: the hens' eight frames (DrawHen $929C)
    'sprites/HenSprites.bin': (2, 32, 8),
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
    info.add_text('ce-sheet', '%d %d %d %d' % (wbytes, fsize, cols, n))
    out = io.BytesIO()
    img.save(out, 'PNG', pnginfo=info)
    return out.getvalue()


def png_to_sheet(png):
    from PIL import Image
    img = Image.open(io.BytesIO(png))
    wbytes, fsize, cols, n = [int(x) for x in img.text['ce-sheet'].split()]
    px = img.load()
    fw = wbytes * 8
    out = bytearray(n * fsize)
    for f in range(n):
        ox, oy = 1 + (f % cols) * (fw + 1), 1 + (f // cols) * (fsize // wbytes + 1)
        for k in range(fsize):
            b = 0
            for bit in range(8):
                b = b << 1 | (1 if px[ox + (k % wbytes) * 8 + bit, oy + k // wbytes] == 1 else 0)
            out[f * fsize + k] = b
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Maps: the eight levels at LevelMaps $B3B0
# ---------------------------------------------------------------------------------------------------------------
MAP_CELLS = {0: '.', 1: '[', 2: ']', 3: 'o', 4: '*', 5: '='}
for _i in range(14):
    MAP_CELLS[0xA8 + _i] = 'abcdefghijklmn'[_i]
MAP_CODES = {v: k for k, v in MAP_CELLS.items()}
MAP_HEAD = ['# A level map of LevelMaps $B3B0: 21 rows of 32 cells, the top row (row 20) first; the image stores',
            '# row 0 (the bottom) first, 32 bytes a row. One character a cell:',
            '#   .  0 empty          [  1 a ladder\'s left column   ]  2 its right column',
            '#   o  3 an egg         *  4 grain                     =  5 a platform (brick)',
            '#   a-n  $A8-$B5: the duck\'s cage, drawn with the character set\'s codes $A8-$B5',
            '# Any other byte is written {NN} (hex).']


def map_out(d):
    lines = list(MAP_HEAD)
    for r in range(20, -1, -1):
        row = d[r * 32:r * 32 + 32]
        lines.append(''.join(MAP_CELLS.get(c, '{%02X}' % c) for c in row))
    return ('\n'.join(lines) + '\n').encode()


def map_in(raw):
    rows = []
    for line in raw.decode().split('\n'):
        if not line.strip() or line.startswith('#'):
            continue
        cells, i = [], 0
        while i < len(line):
            if line[i] == '{':
                cells.append(int(line[i + 1:i + 3], 16))
                i += 4
            else:
                cells.append(MAP_CODES[line[i]])
                i += 1
        if len(cells) != 32:
            raise ValueError('a map row of %d cells' % len(cells))
        rows.append(bytes(cells))
    if len(rows) != 21:
        raise ValueError('a map of %d rows' % len(rows))
    return b''.join(reversed(rows))


# ---------------------------------------------------------------------------------------------------------------
# CSV tables
# ---------------------------------------------------------------------------------------------------------------
def csv_out(comments, columns, rows):
    lines = ['# ' + c for c in comments] + [','.join(columns)]
    lines += [','.join(str(v) for v in r) for r in rows]
    return ('\n'.join(lines) + '\n').encode()


def csv_rows(raw):
    rows, header = [], None
    for line in raw.decode().split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if header is None:
            header = line.split(',')
            continue
        rows.append([c.strip() for c in line.split(',')])
    return rows


def hens_out(d):
    rows = []
    for n in range(len(d) // 21):
        r = d[n * 21:n * 21 + 21]
        rows.append([n] + list(r))
    cols = ['level', 'bytes'] + ['h%d%s' % (h, f) for h in range(1, 6) for f in ('x', 'y', 'state', 'pad')]
    return csv_out(['HenTable $945B: 21 bytes a level, read by SetupLevel $AE9C at $945B + 21 x ((level AND 7) + 1),',
                    'so row 0 is never read (its bytes are a leftover). bytes = how many of the next 20 bytes are',
                    'copied to the hen records $7357 (4 a hen); from level 25 on all 20 are. A hen: x, y (pixels,',
                    'y up from the bottom), state (1 walk left, 2 walk right, 3 climb down, 4 climb up, 7-8',
                    'peck left / right; MoveHen $911E), pad (never read).'],
                   cols, rows)


def flat_in(raw):
    return bytes(num(v) for r in csv_rows(raw) for v in r[1:])


def lifts_out(d):
    rows = []
    for n in range(len(d) // 4):
        r = d[n * 4:n * 4 + 4]
        rows.append(['current' if n == 0 else n, '$%04X' % (r[0] | r[1] << 8), r[2], r[3]])
    return csv_out(['LiftTable $9787: a lift record of 4 bytes a level at $9787 + 4 x ((level AND 7) + 1); row',
                    '"current" ($9787) is the working copy SetupLevel $AE9C writes for the level in play (the',
                    'image holds level 1\'s). address = the screen address of the lower platform\'s left byte at',
                    'its start, x = the lift\'s column in pixels ($FF: no lift on the level), row = the start',
                    'value of its count (MoveLifts $A014 counts it up to 166, then starts the platform again).'],
                   ['level', 'address', 'x', 'row'], rows)


def lifts_in(raw):
    out = bytearray()
    for r in csv_rows(raw):
        a = num(r[1])
        out += bytes([a & 255, a >> 8, num(r[2]), num(r[3])])
    return bytes(out)


def bytes_table(comments, column):
    def out(d):
        return csv_out(comments, ['n', column], [[i, b] for i, b in enumerate(d)])
    return out


TABLES = {
    'tables/HenTable.bin': (hens_out, flat_in),
    'tables/LiftTable.bin': (lifts_out, lifts_in),
    'tables/CellAttributes.bin': (bytes_table(
        ['CellAttributes $984F: the attribute of map cell codes 0-8 (codes 9 and up take 6), read by PaintCells',
         '$9538 and SetupLevel $AE9C: the ink in bits 0-2, black paper.'], 'attribute'), flat_in),
    'tables/LevelPhrases.bin': (bytes_table(
        ['LevelPhrases $B15F: LevelPhrase $B14F speaks one of these eight phrases (picked by R AND 7) when a',
         'level starts; phrase = the number in sound/Phrases.txt.'], 'phrase'), flat_in),
    'tables/DeathPhrases.bin': (bytes_table(
        ['DeathPhrases $ABEA: DeathPhrase $AAE4 speaks one of these eight phrases (R AND 7) when a life ends.'],
        'phrase'), flat_in),
    'tables/LiftPhrases.bin': (bytes_table(
        ['LiftPhrases $A399: LiftPhrase $A389 speaks one of these eight phrases (R AND 7) when Harry lands on a',
         'lift.'], 'phrase'), flat_in),
}

# ---------------------------------------------------------------------------------------------------------------
# Text
# ---------------------------------------------------------------------------------------------------------------
TEXT_HEAD = ['# UTF-8, one quoted string a line: printable ASCII as itself, \xb7 (U+00B7) the empty cell code 0,',
             '# \uff10-\uff19 (fullwidth digits) the HUD digits $9E-$A7, \\xNN any other byte (the game\'s own glyphs:',
             '# graphics/CharacterSet.png and HudCharacters.png by code), \\" and \\\\ escaped.']
PICTURE_HEAD = ['# One quoted string a line: printable ASCII as itself, \\xNN any other byte, \\" and \\\\ escaped.']

# the game's codes written as UTF-8 characters in text/ (never in loader/: there $60 and up are the picture's)
CHARMAP = {0: '\u00b7'}
for _i in range(10):
    CHARMAP[0x9E + _i] = chr(0xFF10 + _i)
CHARCODES = {v: k for k, v in CHARMAP.items()}


def quote(bs, cmap=None):
    cmap = CHARMAP if cmap is None else cmap
    t = ''
    for b in bs:
        if b in cmap:
            t += cmap[b]
        elif b in (0x22, 0x5C):
            t += '\\' + chr(b)
        elif 0x20 <= b < 0x7F:
            t += chr(b)
        else:
            t += '\\x%02X' % b
    return '"' + t + '"'


def unquote(s, cmap=None):
    codes = CHARCODES if cmap is None else {v: k for k, v in cmap.items()}
    s = s.strip()
    if not (s.startswith('"') and s.endswith('"')):
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
        elif s[i] in codes:
            out.append(codes[s[i]])
            i += 1
        else:
            if ord(s[i]) > 0x7E:
                raise ValueError('no game code for %r in %s' % (s[i], s))
            out.append(ord(s[i]))
            i += 1
    return bytes(out)


# a screen page: the .bin name -> (comments, the row width, stored bottom row first)
TEXT_PAGES = {
    'loader/PictureText.bin': (['PictureText $601C: the loading picture as 24 rows of 32 character codes, the top row',
                                'first (PrintPictureChar $5FC9: codes below $5F from the ROM font, $60 and up from',
                                'loader/PictureGraphics.png, frame = code - $60).'], 32, False),
    'text/InstructionsText.bin': (['InstructionsText $8390: the instructions page, 11 rows of 32 printed on every',
                                   'other screen row (InstructionsPage $A4C8); stored bottom row first, here top',
                                   'row first. RedefineKeys $AA49 writes the new keys into the "3" row.'], 32, True),
    'text/TitleText.bin': (['TitleText $9630: the title page\'s left half, 22 rows of 14 (TitlePage $A420);',
                            'stored bottom row first, here top row first; \\x80-\\x8A draw the big CHUCKIE EGG.'],
                           14, True),
    'text/Congratulations.bin': (['Congratulations $AD67: the name entry page, 11 rows of 15 printed on every',
                                  'other row from the top (EnterHiScore $A80C); GameOver $A7BC writes the',
                                  'player\'s digit into the first row ($AD72).'], 15, False),
}
# a list of strings: the .bin name -> (comments, the length of each string)
TEXT_SPLIT = {
    'text/HudText.bin': (['HudText $9764: the HUD rows SetupLevel $AE9C prints: 3 codes at the top row (the',
                          'SCORE label, \\x0B-\\x0D), then 32 at the third row: the PLAYER (\\x0E-\\x11), LEVEL',
                          '(\\x9B-\\x9D), BONUS (\\x1B-\\x1D) and TIME (\\x12-\\x14) labels and their digits. SetupLevel writes the digits at $976B (the player), $9772-$9773 (the level),',
                          '$977A (the bonus) and $9784 (the time); the image holds those of level 1.'], [3, 32]),
    'text/HiScoreTable.bin': (['HiScoreTable $97AF: ten entries of 16 bytes, the best first: a space, eight name',
                               'characters (\\x8F-\\x96 the "A+F" logo), a space, then six score digits;',
                               'EnterHiScore $A80C shifts the entries down and writes the new one.'], [10, 6] * 10),
    'text/MenuTexts.bin': (['MenuTexts $ABF2: the high score title (DrawHiScores $ABAD), the redefine prompt and',
                            'its five key labels (RedefineKeys $AA49), KeyNames (RedefineOne $AB19: 8 port rows of',
                            '5 keys, bit 0 first; \\x97 SPACE, \\x98 CAPS SHIFT, \\x99 SYMBOL SHIFT, \\x9A',
                            'ENTER), the two scroller texts (TitleLoop $A47D, InstructionsPage $A4C8), the',
                            'players prompt (StartGame $A59D) and the messages (Message $A9CE). The code writes',
                            '$AD50 (the player\'s digit) and $AD58-$AD59 (the level\'s digits).'],
                           [16, 32, 10, 10, 10, 10, 10, 5, 5, 5, 5, 5, 5, 5, 5, 78, 87, 29, 1, 9, 1, 8, 1, 6, 2,
                            13]),
    'text/MenuLeftover.bin': (['MenuLeftover $8336: three menu lines with zeros for spaces that no code reads (L1',
                               'of the eight builds: no read); the menu scrolls the lines in MenuTexts.txt.'],
                              [90]),
}


def page_out(name, d):
    comments, w, rev = TEXT_PAGES[name]
    rows = [d[i:i + w] for i in range(0, len(d), w)]
    if rev:
        rows.reverse()
    cmap, head = ({}, PICTURE_HEAD) if name.startswith('loader/') else (None, TEXT_HEAD)
    return ('\n'.join(['# ' + c for c in comments] + head + [quote(r, cmap) for r in rows]) + '\n').encode('utf-8')


def split_out(name, d):
    comments, lengths = TEXT_SPLIT[name]
    if sum(lengths) != len(d):
        raise ValueError('%s: the lengths give %d bytes, the entry has %d' % (name, sum(lengths), len(d)))
    lines, p = [], 0
    for n in lengths:
        lines.append(quote(d[p:p + n]))
        p += n
    return ('\n'.join(['# ' + c for c in comments] + TEXT_HEAD + lines) + '\n').encode('utf-8')


def text_lines(raw):
    return [line for line in raw.decode('utf-8').split('\n') if line.strip() and not line.startswith('#')]


def page_in(name, raw):
    cmap = {} if name.startswith('loader/') else None
    rows = [unquote(line, cmap) for line in text_lines(raw)]
    if TEXT_PAGES[name][2]:
        rows.reverse()
    return b''.join(rows)


def split_in(_name, raw):
    return b''.join(unquote(line) for line in text_lines(raw))


# The leftover assembler source: editor lines of two BCD bytes (the line number), the text and $0D
SOURCE_TEXT = {
    'text/SourceLeftoverB167.bin': '$B167-$B1FF, cut by the IM 2 vector table $B200',
    'text/SourceLeftoverB307.bin': '$B307-$B34B, cut by FallOffEdge $B34C',
    'text/SourceLeftoverB381.bin': '$B381-$B3AF, cut by LevelMaps $B3B0',
    'text/SourceLeftoverC8B0.bin': '$C8B0-$C8C7, cut by PhraseTable $C8C8',
}


def bcd(b):
    return (b >> 4) < 10 and (b & 15) < 10


def source_out(name, d):
    lines = ['# The author\'s assembler source left in the image at %s.' % SOURCE_TEXT[name],
             '# One editor line a file line: NNNN "text" (the two line-number bytes as BCD digits, else $hhhh),',
             '# - "text" a piece with no line number (its start is under the bytes before), "cut" at the end',
             '# of a line whose $0D is under the bytes after. No code reads these bytes.']
    p, first = 0, True
    while p < len(d):
        if first:
            head, first = '-', False
        else:
            if p + 2 > len(d):
                lines.append('bytes ' + ' '.join('$%02X' % b for b in d[p:]))
                break
            hi, lo = d[p], d[p + 1]
            head = ('%02X%02X' % (hi, lo)) if bcd(hi) and bcd(lo) else '$%02X%02X' % (hi, lo)
            p += 2
        e = d.find(b'\r', p)
        if e < 0:
            lines.append('%s %s cut' % (head, quote(d[p:])))
            break
        lines.append('%s %s' % (head, quote(d[p:e])))
        p = e + 1
    return ('\n'.join(lines) + '\n').encode()


def source_in(_name, raw):
    out = bytearray()
    for line in text_lines(raw):
        head, rest = line.split(' ', 1)
        if head == 'bytes':
            out += bytes(num(v) for v in rest.split())
            continue
        cut = rest.endswith(' cut')
        if cut:
            rest = rest[:-4]
        if head != '-':
            h = num(head) if head.startswith('$') else int(head, 16)
            out += bytes([h >> 8, h & 255])
        out += unquote(rest)
        if not cut:
            out.append(13)
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Key sets: KeySets $8250, three sets of six (mask, port row) pairs
# ---------------------------------------------------------------------------------------------------------------
ROWS = {0xFE: ['CAPS', 'Z', 'X', 'C', 'V'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
        0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xDF: ['P', 'O', 'I', 'U', 'Y'],
        0xBF: ['ENTER', 'L', 'K', 'J', 'H'], 0x7F: ['SPACE', 'SYM', 'M', 'N', 'B']}
KEYNAME = {(0x1F ^ (1 << bit), row): k for row, ks in ROWS.items() for bit, k in enumerate(ks)}
KEYCODE = {v: k for k, v in KEYNAME.items()}
DIRS = ['up', 'down', 'left', 'right', 'jump', 'jump']


def keys_out(d):
    lines = ['# KeySets $8250: three key sets of 12 bytes, six (mask, port row) pairs: up, down, left, right and',
             '# two jump keys. A key is down when (IN (row x 256 + $FE) AND $1F) OR mask is not $1F; the mask is',
             '# $1F with the key\'s bit clear. One key a line: type N direction KEY (a key name, or $mask/$row).',
             '# SetupLevel $AE9C copies set N (KeyType $732D) to KeyTable $732E; RedefineKeys $AA49 rewrites set 3.']
    for n in range(len(d) // 12):
        for k in range(6):
            mask, row = d[n * 12 + 2 * k], d[n * 12 + 2 * k + 1]
            key = KEYNAME.get((mask, row), '$%02X/$%02X' % (mask, row))
            lines.append('type %d %s %s' % (n + 1, DIRS[k], key))
    return ('\n'.join(lines) + '\n').encode()


def keys_in(raw):
    out = bytearray()
    for line in text_lines(raw):
        key = line.split()[3]
        if key.startswith('$'):
            m, r = key.split('/')
            out += bytes([num(m), num(r)])
        else:
            out += bytes(KEYCODE[key])
    return bytes(out)


# ---------------------------------------------------------------------------------------------------------------
# Sound: the speech phrases (port $9F) and the beeper tunes
# ---------------------------------------------------------------------------------------------------------------
# The SP0256-AL2's 64 allophones (codes 0-63). The phrases spell words with them: phrase 20, spoken on the title
# page, is "A and F software presents Chuckie Egg" (docs/09).
ALLOPHONES = ['PA1', 'PA2', 'PA3', 'PA4', 'PA5', 'OY', 'AY', 'EH', 'KK3', 'PP', 'JH', 'NN1', 'IH', 'TT2', 'RR1', 'AX',
              'MM', 'TT1', 'DH1', 'IY', 'EY', 'DD1', 'UW1', 'AO', 'AA', 'YY2', 'AE', 'HH1', 'BB1', 'TH', 'UH', 'UW2',
              'AW', 'DD2', 'GG3', 'VV', 'GG1', 'SH', 'ZH', 'RR2', 'FF', 'KK2', 'KK1', 'ZZ', 'NG', 'LL', 'WW', 'XR',
              'WH', 'YY1', 'CH', 'ER1', 'ER2', 'OW', 'DH2', 'SS', 'NN2', 'HH2', 'OR', 'AR', 'YR', 'GG2', 'EL', 'BB2']
PHRASE_ORG = 0xC8C8
PHRASE_HEAD = ['# PhraseTable $C8C8 and the phrases (sound/Phrases.bin, $C8C8-$CBC3). StartPhrase $9CEB takes phrase N',
               '# (1-32) from the word at $C8C6 + 2N; the interrupt (PhraseInterrupt $9CC2) sends one pair at a time:',
               '# OUT ($9F) the allophone, then it waits COUNT interrupts before the next pair; a count of $FF ends.',
               '# "table N" is the number of words, "pad N" the zero bytes after them, then each phrase in address',
               '# order: "phrase N [M ...]: COUNT ALLOPHONE, ..." (the table entries that point at it), "end $xx" the',
               '# closing pair ($FF and the byte after it, never read). An allophone is its SP0256-AL2 name or a',
               '# number.']


def phrases_out(d):
    words, p = [], 0
    while p + 1 < len(d) and (d[p] | d[p + 1] << 8):
        words.append(d[p] | d[p + 1] << 8)
        p += 2
    pad = 0
    while p < len(d) and d[p] == 0:
        pad += 1
        p += 1
    lines = list(PHRASE_HEAD) + ['table %d' % len(words), 'pad %d' % pad]
    starts = {}
    for i, w in enumerate(words):
        starts.setdefault(w - PHRASE_ORG, []).append(i + 1)
    if any(s < p or s >= len(d) for s in starts):
        raise ValueError('a phrase pointer outside the phrases')
    while p < len(d):
        if p not in starts:
            e = p
            while e < len(d) and e not in starts:
                e += 1
            lines.append('bytes ' + ' '.join('$%02X' % b for b in d[p:e]))
            p = e
            continue
        q, items = p, []
        while d[p] != 0xFF:
            items.append('%d %s' % (d[p], ALLOPHONES[d[p + 1]] if d[p + 1] < 64 else '$%02X' % d[p + 1]))
            p += 2
        lines.append('phrase %s: %s' % (' '.join(str(n) for n in starts[q]), ', '.join(items)))
        lines.append('end $%02X' % d[p + 1])
        p += 2
    return ('\n'.join(lines) + '\n').encode()


def phrases_in(raw):
    entries, body, pad, ntable = {}, bytearray(), 0, 0
    lines = text_lines(raw)
    for line in lines:
        w = line.split()
        if w[0] == 'table':
            ntable = int(w[1])
        elif w[0] == 'pad':
            pad = int(w[1])
    start = 2 * ntable + pad
    for line in lines:
        w = line.split(None, 1)
        if w[0] == 'phrase':
            nums, items = w[1].split(':', 1)
            for n in nums.split():
                entries[int(n)] = PHRASE_ORG + start + len(body)
            for it in items.split(','):
                c, a = it.split()
                body += bytes([int(c), num(a) if a[0] in '$0123456789' else ALLOPHONES.index(a)])
        elif w[0] == 'end':
            body += bytes([0xFF, num(w[1])])
        elif w[0] == 'bytes':
            body += bytes(num(v) for v in w[1].split())
    table = bytearray()
    for n in range(1, ntable + 1):
        table += entries[n].to_bytes(2, 'little')
    return bytes(table) + bytes(pad) + bytes(body)


NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
TUNE_HEAD = ['# A tune of PlayTune $AB60: one note a line, "duration pitch": the duration in tenths of a second (the',
             '# ROM calculator divides it by ten for BEEP), the pitch in semitones above middle C (BEEP\'s second',
             '# number); the name after "#" is a comment. "end" is the closing pair (0 0).']


def tune_out(d):
    lines, p = list(TUNE_HEAD), 0
    while p + 1 < len(d):
        dur, pitch = d[p], d[p + 1]
        if dur == 0:
            lines.append('end' if pitch == 0 else 'end %d' % pitch)
        else:
            lines.append('%d %d  # %s%d' % (dur, pitch, NOTE_NAMES[pitch % 12], 4 + pitch // 12))
        p += 2
    return ('\n'.join(lines) + '\n').encode()


def tune_in(raw):
    out = bytearray()
    for line in text_lines(raw):
        w = line.split('#')[0].split()
        if w[0] == 'end':
            out += bytes([0, int(w[1]) if len(w) > 1 else 0])
        else:
            out += bytes([int(w[0]), int(w[1])])
    return bytes(out)


def editable(name):
    if name in SHEETS:
        w, f, c = SHEETS[name]
        return '.png', lambda n, d: sheet_to_png(d, w, f, c), lambda n, d: png_to_sheet(d)
    if name.startswith('maps/Level'):
        return '.txt', lambda n, d: map_out(d), lambda n, d: map_in(d)
    if name in TABLES:
        to_ed, from_ed = TABLES[name]
        return '.csv', lambda n, d: to_ed(d), lambda n, d: from_ed(d)
    if name in TEXT_PAGES:
        return '.txt', page_out, page_in
    if name in TEXT_SPLIT:
        return '.txt', split_out, split_in
    if name in SOURCE_TEXT:
        return '.txt', source_out, source_in
    if name == 'text/KeySets.bin':
        return '.txt', lambda n, d: keys_out(d), lambda n, d: keys_in(d)
    if name == 'sound/Phrases.bin':
        return '.txt', lambda n, d: phrases_out(d), lambda n, d: phrases_in(d)
    if name.endswith('Tune.bin'):
        return '.txt', lambda n, d: tune_out(d), lambda n, d: tune_in(d)
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

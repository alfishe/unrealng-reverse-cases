#!/usr/bin/env python3
"""ATV Simulator's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install
calls install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build [--out build/res]   # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file -> bytes -> the same file again
    python3 tools/res_formats.py export [--from DIR]       # .bin files (DIR, default build/res) -> src/res

| @res name | Editable file(s) | Format |
| --- | --- | --- |
| `texts/NAME.bin` | `texts/NAME.txt` | UTF-8, one string a line: a line ending in `|` is a string with the game's end mark, a quoted line ("...") bytes with no end mark (the fixed-width trail names); `\\xNN` for a byte that is no printable character |
| `tables/panels.bin`, `tables/credits.bin` | `.csv` | the sprite lists (x, y, sprite) and attribute box lists (x1, y1, x2, y2, attr) of SpriteList / AttrBoxes, a row an item; a list ends where the next name starts (the `$FF` mark); `shows` names a sprite for the reader (not built) |
| `tables/menus.bin` | `tables/menus.csv` | the menus (MenuDefs): a menu row (x, y, height) and its item rows (text address, action address) |
| `sprites/game.bin`, `sprites/menu.bin` | `sprites/NAME.png`, `sprites/NAME.csv` | the sprite banks: every sprite's pixels at a place of its own in the PNG (index 0 paper, 1 ink, 2 no pixel), the CSV a row a piece in byte order (its numbers, place, size, header bytes; the menu bank's attribute blocks as hex) and `bytes` rows for the bytes no number reaches; the bank's header (count, length, offsets) is made from the rows |
| `trails/NAME.bin` | `trails/NAME.txt` | the trail records, the object lists and the animation records as text (TRAIL_HELP) |
| `sound/tunes.bin` | `sound/tunes.txt` | the note table, the tune table, the sequence lists and the channel and drum patterns as text (TUNE_HELP) |
| `tables/NAME.bin` (BYTE_TABLES) | `tables/NAME.txt` | a byte table of the game's rules or pictures (the ATV's and rider's frames, offsets, the fall and jump steps, the trails' inks): one row of `$XX` bytes per line, `#` comments; the rows' lengths are only for reading |
| `screens/loading.scr` | `screens/loading.scr`, `screens/loading.png` | the SCREEN$ is the source; the PNG a view check keeps up to date |
| anything else | the `.bin` itself | bytes |

Other tools read a resource with load('trails/trail5.bin'): the bytes built from its editable file.
"""
import argparse
import csv
import io
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
PALETTE = [(24, 24, 32), (230, 230, 230), (110, 40, 40)]
ZX = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205),
      (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
SHEET = 512  # the sprite sheets' width in pixels

# the list tables: (name, kind) in byte order; kind sprites (x, y, sprite; $FF), boxes (x1, y1, x2, y2, attr; $FF),
# bytes (the rest of the resource)
LISTS = {
    'tables/panels.bin': [('PanelP1Sprites', 'sprites'), ('PanelP2Sprites', 'sprites'), ('HudSprites', 'sprites'),
                          ('LoadIntroSprites', 'sprites'), ('LoadIntroBoxes', 'boxes'), ('PanelP2Boxes', 'boxes'),
                          ('PanelP1Boxes', 'boxes'), ('HudBoxes', 'boxes')],
    'tables/credits.bin': [('TrailIntroBoxes', 'boxes'), ('CreditBoxes', 'boxes'), ('CreditSprites1', 'sprites'),
                           ('CreditSprites2', 'sprites'), ('HiScorePage', 'bytes')],
}
MENUS = ['MenuDefs', 'MenuControls1', 'MenuControls2a', 'MenuControls2', 'MenuKeys1', 'MenuKeys2', 'MenuPlayerOne',
         'MenuPlayerTwo']
MENU_TEXTS = 0x70AA  # MenuTexts: the items' texts (shown in the CSV, not read by the build)
# the trail resources: base address (where the code finds them), number of records, the first trail's number
TRAILS = {'trails/trails14.bin': (0x7C9C, 4, 1), 'trails/trail5.bin': (0xEE84, 1, 5),
          'trails/trail6.bin': (0x60AC, 1, 6)}
TITLES = {1: 'Trails 1-4 (SAND DUNING, GRASSTRAKIN, ICEBERGS, PYRAMIDS): TrailRecords $7C9C-$807A',
          5: 'Trail 5 (TROPICANA): Trail5 $EE84-$F03B',
          6: 'Trail 6 (SWAMP): loaded at $F230 (Trail6Image), run from GameEntry\'s copy at $60AC'}
# the byte tables: name -> (address, the row length shown, what the rows are)
BYTE_TABLES = {
    'tables/trailinks.bin': (0x79D4, 6, 'TrailInks: the play window\'s attribute for trails 1-6'),
    'tables/tumbleoffsets.bin': (0xDC0D, 6, 'TumbleOffsets: the tumbling ATV\'s height offsets (AtvY)'),
    'tables/ridepose.bin': (0xDEEC, 4, 'RidePoses: the mounted rider\'s sprite for each ATV frame (RiderPoseY)'),
    'tables/riderjump.bin': (0xE312, 7, 'RiderJumpTable ($E312-$E318: the rider\'s jump steps) and FallSteps ($E319-$E31E:'
                                        ' the ATV\'s fall per pass by VSpeed)'),
    'tables/wheeloffsets.bin': (0xE61B, 2, 'WheelOffsets: the wheels\' x and y offsets for each ATV frame from $38 (pairs)'),
    'tables/slopeframes.bin': (0xE797, 12, 'SlopeFrames: the frame offset for each line of slope (0-$14)'),
    'tables/slopetable2.bin': (0xE7EF, 12, 'SlopeTable2: multiples of 3, read by no code'),
    'tables/tumbleframes.bin': (0xE86C, 12, 'TumbleFrames: the tumble\'s 24 frames ($7D-$87), then TumbleHeights $E884'),
}
TUNES_BASE = 0xFB72
INSTALLING = {}

TRAIL_HELP = """# {title}
# Blocks in byte order ('#' starts a comment):
#   record NAME A=LIST B=LIST length=$NNNN   a trail's record (SelectTrail reads it): list A (the ground and the
#                                            obstacles), list B (the scenery), the length (FinishDistance = length
#                                            less $48, shown as the comment)
#   list NAME                                a list: its items follow, the $FFFF end mark is written after them
#   DIST Y ADV sprite=$SS flags=$FF          an item: the distance along the trail, y (0: the sprite's own height),
#                                            the advance (0 in the image: InitListWidths fills it), the sprite, the
#                                            flags (bit 0 the menu bank's picture and its attributes, bit 1 drawn
#                                            before the ATV (DeferredB), bit 2 after it (DeferredA), bit 3 masked)
#   DIST Y ADV anim=NAME                     an item drawn from an animation record (AnimObject $8A49)
#   anim NAME sprite=$SS flags=$FF id=$II [motion=HEX]   an animation record: sprite, flags, id, then the motions
#                                            (+3/+4 the x period and counter, +5/+6 the y ones, +7 the x and y steps,
#                                            +8/+9 the frame's), the $FF end mark written after them
#   bytes HEX                                bytes no code reads as a trail
# Names of anims are their original addresses (Anim8042); a name no block of this file defines is that address in
# another resource (trail 5's items use trails 1-4's animation records).
"""

TUNE_HELP = """# The tunes (TunePlay $F852), in byte order ('#' starts a comment):
#   notes N ...                      NoteTable: the half-periods of notes 0-59
#   tune A=SEQ B=SEQ D=SEQ           TuneTable: a tune's sequence lists for channel A, channel B and the drums
#                                    (tune 0 the title, tune 1 the finish)
#   seq NAME PAT ...                 a sequence list: the patterns in turn; the 0 end mark is written after them
#                                    (NextSequenceA/B/D start the list again)
#   chan NAME TOKEN ...              a channel pattern: nN a note (NoteTable index, plus the transposition), len N
#                                    the note length (x 3, command $83), env N the envelope (command $82), mute
#                                    (command $81), tr N the transposition ($84), next (command $80: the next
#                                    pattern; it ends the pattern)
#   drum NAME TOKEN ...              a drum pattern, a byte every 12 interrupts (or as speed sets; Drums uses
#                                    the byte AND $7F, the tunes set bit 7): next ($80, ends the pattern), rest
#                                    ($81), d2 ($82, DrumUnused2), speed N ($83: N x 3 interrupts a byte), d4
#                                    ($84, DrumUnused), d5 ($85, nothing), noise ($86, DrumNoise), hit N ($87,
#                                    DrumHit, N its pitch); any other byte is written $XX
#   bytes HEX                        bytes no list reaches
"""


def word(d, o):
    return d[o] | d[o + 1] << 8


def le(v):
    return bytes([v & 255, v >> 8])


def kind(name):
    if name.startswith('texts/'):
        return 'text'
    if name in LISTS:
        return 'lists'
    if name == 'tables/menus.bin':
        return 'menus'
    if name in BYTE_TABLES:
        return 'table'
    if name in ('sprites/game.bin', 'sprites/menu.bin'):
        return 'sprites'
    if name in TRAILS:
        return 'trail'
    if name == 'sound/tunes.bin':
        return 'tunes'
    if name == 'screens/loading.scr':
        return 'screen'
    return 'bytes'


def stem(name):
    return os.path.splitext(name)[0]


# byte tables ----------------------------------------------------------------------------------------------------------

def table_export(name, data):
    addr, per, what = BYTE_TABLES[name]
    out = ['# %s' % what, '# %d bytes from $%04X; a row is %d bytes ($XX each), the comment its address' % (
        len(data), addr, per)]
    for o in range(0, len(data), per):
        out.append('%s  # $%04X' % (' '.join('$%02X' % b for b in data[o:o + per]), addr + o))
    return {stem(name) + '.txt': ('\n'.join(out) + '\n').encode()}


def table_build(files, name):
    out = bytearray()
    for line in files[stem(name) + '.txt'].decode().split('\n'):
        line = line.split('#')[0].split()
        out += bytes(int(t.lstrip('$'), 16) for t in line)
    return bytes(out)


# texts ----------------------------------------------------------------------------------------------------------------

def esc(bs):
    return ''.join(chr(b) if 32 <= b < 127 and b not in (0x5C, 0x22) else '\\x%02X' % b for b in bs)


def unesc(s):
    out, i = bytearray(), 0
    while i < len(s):
        if s[i] == '\\' and s[i + 1:i + 2] == 'x':
            out.append(int(s[i + 2:i + 4], 16))
            i += 4
        else:
            out.append(ord(s[i]))
            i += 1
    return bytes(out)


def text_export(name, data):
    lines, i = [], 0
    fixed = 11 if name == 'texts/trails.bin' else 0
    while i < len(data):
        j = data.find(b'|', i)
        if j < 0 or (fixed and len(lines) >= 2):
            n = fixed or len(data) - i
            lines.append('"%s"' % esc(data[i:i + n]))
            i += n
        else:
            lines.append(esc(data[i:j + 1]))
            i = j + 1
    return {stem(name) + '.txt': ('\n'.join(lines) + '\n').encode('utf-8')}


def text_build(files, name):
    out = bytearray()
    for line in files[stem(name) + '.txt'].decode('utf-8').split('\n'):
        if line:
            out += unesc(line[1:-1] if line.startswith('"') else line)
    return bytes(out)


# CSV helpers ------------------------------------------------------------------------------------------------------------

def csv_text(header, rows):
    f = io.StringIO()
    w = csv.writer(f, lineterminator='\n')
    w.writerow(header)
    w.writerows(rows)
    return f.getvalue().encode('utf-8')


def csv_rows(b):
    return list(csv.DictReader(io.StringIO(b.decode('utf-8'))))


def num(s):
    s = s.strip()
    return int(s[1:], 16) if s.startswith('$') else int(s)


def h(v, n=2):
    return '$%0*X' % (n, v)


# list tables ---------------------------------------------------------------------------------------------------------

# What the game sprites (game.png) of the panels' and the HUD's lists show, for the reader: the `shows` column (the
# build does not read it). The other lists draw menu pictures (LoadIntro, the credits) and are left blank.
LIST_SPRITES = {137: 'panel edge', 138: 'panel edge', 139: 'panel edge', 140: 'panel edge', 151: 'SPEED', 152: 'FUEL',
                163: 'clock', 164: 'max'}
GAME_SPRITE_LISTS = ('PanelP1Sprites', 'PanelP2Sprites', 'HudSprites')


def lists_export(name, data):
    rows, o = [], 0
    for lname, k in LISTS[name]:
        if k == 'bytes':
            rows.append([lname, '', '', '', '', '', '', data[o:].hex().upper(), ''])
            o = len(data)
            continue
        n = 3 if k == 'sprites' else 5
        while data[o] != 0xFF:
            it = data[o:o + n]
            if k == 'sprites':
                rows.append([lname, it[0], it[1], '', '', it[2], '', '',
                             LIST_SPRITES.get(it[2], '') if lname in GAME_SPRITE_LISTS else ''])
            else:
                rows.append([lname, it[0], it[1], it[2], it[3], '', h(it[4]), '', ''])
            o += n
        o += 1
    assert o == len(data), name
    return {stem(name) + '.csv': csv_text(['list', 'x', 'y', 'x2', 'y2', 'sprite', 'attr', 'bytes', 'shows'], rows)}


def lists_build(files, name):
    out, last, open_list = bytearray(), None, False
    for r in csv_rows(files[stem(name) + '.csv']):
        if r['list'] != last and open_list:
            out.append(0xFF)
        last, open_list = r['list'], not r['bytes']
        if r['bytes']:
            out += bytes.fromhex(r['bytes'])
        elif r['x2']:
            out += bytes([num(r['x']), num(r['y']), num(r['x2']), num(r['y2']), num(r['attr'])])
        else:
            out += bytes([num(r['x']), num(r['y']), num(r['sprite'])])
    if open_list:
        out.append(0xFF)
    return bytes(out)


# menus -----------------------------------------------------------------------------------------------------------

def menu_text(a):
    data = INSTALLING.get('texts/menu.bin')
    if data is None:
        try:
            data = build_one('texts/menu.bin')
        except (OSError, KeyError):
            return ''
    o = a - MENU_TEXTS
    if not 0 <= o < len(data):
        return ''
    e = data.find(b'|', o)
    return data[o + 2:e].decode('latin-1') if e > 0 else ''


def menus_export(name, data):
    rows, o = [], 0
    for m in MENUS:
        n = data[o]
        rows.append([m, data[o + 1], data[o + 2], data[o + 3], '', '', ''])
        o += 4
        for _ in range(n):
            t, a = word(data, o), word(data, o + 2)
            rows.append([m, '', '', '', h(t, 4), h(a, 4), menu_text(t)])
            o += 4
    assert o == len(data)
    return {'tables/menus.csv': csv_text(['menu', 'x', 'y', 'height', 'text', 'action', 'shows'], rows)}


def menus_build(files, name):
    menus = []
    for r in csv_rows(files['tables/menus.csv']):
        if r['x']:
            menus.append([bytes([num(r['x']), num(r['y']), num(r['height'])]), []])
        else:
            menus[-1][1].append((num(r['text']), num(r['action'])))
    out = bytearray()
    for head, items in menus:
        out += bytes([len(items)]) + head
        for t, a in items:
            out += le(t) + le(a)
    return bytes(out)


# sprite banks ----------------------------------------------------------------------------------------------------------

def bank_pieces(name, data):
    """the count, the length word and [(offset, kind, numbers, length)] in byte order"""
    count, menu = data[0], name == 'sprites/menu.bin'
    table = {}
    for i in range(count * (2 if menu else 1)):
        off = word(data, 4 + 2 * i)
        k = ('sprite' if i % 2 == 0 else 'attrs') if menu else 'sprite'
        table.setdefault((off, k), []).append(i // 2 if menu else i)
    pieces = []
    for (off, k), nums in sorted(table.items()):
        pieces.append((off, k, nums, (4 if k == 'sprite' else 2) + data[off] * data[off + 1]))
    return count, word(data, 1), pieces


def sprites_export(name, data):
    count, length, pieces = bank_pieces(name, data)
    o = 4 + 2 * count * (2 if name == 'sprites/menu.bin' else 1)
    rows, places, x, y, rowh = [], [], 0, 0, 0
    for off, k, nums, ln in pieces:
        assert off >= o, (name, hex(off))
        if off > o:
            rows.append(['bytes', h(o, 4), '', '', '', '', '', '', '', data[o:off].hex().upper()])
        w, hh = data[off], data[off + 1]
        ns = ' '.join(str(n) for n in nums)
        if k == 'sprite':
            if x + w * 8 > SHEET:
                x, y, rowh = 0, y + rowh + 2, 0
            places.append((x, y, data[off + 4:off + ln], w, hh))
            rows.append(['sprite', h(off, 4), ns, x, y, w, hh, data[off + 2], data[off + 3], ''])
            x += w * 8 + 2
            rowh = max(rowh, hh)
        else:
            rows.append(['attrs', h(off, 4), ns, '', '', w, hh, '', '', data[off + 2:off + ln].hex().upper()])
        o = off + ln
    assert o == length, (name, hex(o), hex(length))
    if o < len(data):
        rows.append(['bytes', h(o, 4), '', '', '', '', '', '', '', data[o:].hex().upper()])
    img = Image.new('P', (SHEET, max(1, y + rowh)), 2)
    img.putpalette(sum((list(c) for c in PALETTE), []))
    px = img.load()
    for x0, y0, bs, w, hh in places:
        for j in range(hh):
            for i in range(w):
                b = bs[j * w + i]
                for bit in range(8):
                    px[x0 + i * 8 + bit, y0 + j] = (b >> (7 - bit)) & 1
    f = io.BytesIO()
    img.save(f, 'PNG')
    header = ['kind', 'offset', 'numbers', 'x', 'y', 'width', 'height', 'advance', 'shift', 'bytes']
    return {stem(name) + '.png': f.getvalue(), stem(name) + '.csv': csv_text(header, rows)}


def sprites_build(files, name):
    menu = name == 'sprites/menu.bin'
    px = Image.open(io.BytesIO(files[stem(name) + '.png'])).load()
    rows = csv_rows(files[stem(name) + '.csv'])
    count = max(int(n) for r in rows if r['numbers'] for n in r['numbers'].split()) + 1
    first = 4 + 2 * count * (2 if menu else 1)
    body, table, end = bytearray(), {}, None
    for i, r in enumerate(rows):
        off = first + len(body)
        if r['kind'] == 'bytes':
            if i == len(rows) - 1:  # the bytes after the bank's end (the length word stops before them)
                end = off
            body += bytes.fromhex(r['bytes'])
            continue
        w, hh = num(r['width']), num(r['height'])
        if r['kind'] == 'sprite':
            x0, y0 = num(r['x']), num(r['y'])
            body += bytes([w, hh, num(r['advance']), num(r['shift'])])
            for j in range(hh):
                for c in range(w):
                    b = 0
                    for bit in range(8):
                        b = b << 1 | (px[x0 + c * 8 + bit, y0 + j] == 1)
                    body.append(b)
        else:
            body += bytes([w, hh]) + bytes.fromhex(r['bytes'])
        for n in r['numbers'].split():
            table[(int(n), r['kind'])] = off
    if end is None:
        end = first + len(body)
    head = bytearray([count]) + le(end) + b'\0'
    for n in range(count):
        for k in (('sprite', 'attrs') if menu else ('sprite',)):
            head += le(table[(n, k)])
    return bytes(head + body)


# trails ----------------------------------------------------------------------------------------------------------

def trail_parse(name, data):
    """the blocks in byte order and the lists' names by address"""
    base, n, first = TRAILS[name]
    lists, anims, blocks = {}, set(), []
    for i in range(n):
        a, b, ln = word(data, 6 * i), word(data, 6 * i + 2), word(data, 6 * i + 4)
        blocks.append(('record', 'Trail%d' % (first + i), a, b, ln))
        lists[a], lists[b] = 'A%d' % (first + i), 'B%d' % (first + i)
    o = 6 * n
    while base + o in lists:
        start, items = base + o, []
        while not (data[o] == 0xFF and data[o + 1] == 0xFF):
            it = bytes(data[o:o + 6])
            if it[5] & 0xF0:
                anims.add(word(it, 4))
            items.append(it)
            o += 6
        blocks.append(('list', start, items))
        o += 2
    while base + o in anims:
        e = data.index(0xFF, o + 3)
        blocks.append(('anim', base + o, bytes(data[o:e])))
        o = e + 1
    if o < len(data):
        blocks.append(('bytes', bytes(data[o:])))
    return blocks, lists


def trail_export(name, data):
    first = TRAILS[name][2]
    blocks, lists = trail_parse(name, data)
    out = [TRAIL_HELP.format(title=TITLES[first]).rstrip('\n')]

    def ref(a):
        return lists.get(a, 'Anim%04X' % a)
    for b in blocks:
        if b[0] == 'record':
            out.append('record %s A=%s B=%s length=$%04X   # finish $%04X' % (b[1], ref(b[2]), ref(b[3]), b[4],
                                                                              b[4] - 0x48))
        elif b[0] == 'list':
            out += ['', 'list %s' % lists[b[1]]]
            for it in b[2]:
                head = '$%04X %3d %d' % (word(it, 0), it[2], it[3])
                if it[5] & 0xF0:
                    out.append('%s anim=Anim%04X' % (head, word(it, 4)))
                else:
                    out.append('%s sprite=$%02X flags=$%02X' % (head, it[4], it[5]))
        elif b[0] == 'anim':
            d = b[2]
            line = 'anim Anim%04X sprite=$%02X flags=$%02X id=$%02X' % (b[1], d[0], d[1], d[2])
            if len(d) > 3:
                line += ' motion=' + d[3:].hex().upper()
            if not out[-1].startswith('anim'):
                out.append('')
            out.append(line)
        else:
            shown = ''.join(chr(c) if 32 <= c < 127 and c != 35 else '.' for c in b[1])
            out += ['', '# leftover bytes, as text: %s' % shown]
            out += ['bytes ' + b[1][i:i + 32].hex().upper() for i in range(0, len(b[1]), 32)]
    return {stem(name) + '.txt': ('\n'.join(out) + '\n').encode('utf-8')}


def trail_build(files, name):
    base = TRAILS[name][0]
    blocks = []
    for line in files[stem(name) + '.txt'].decode('utf-8').split('\n'):
        t = line.split('#')[0].split()
        if not t:
            continue
        f = dict(x.split('=', 1) for x in t[1:] if '=' in x)
        if t[0] == 'record':
            blocks.append(['record', t[1], f['A'], f['B'], num(f['length'])])
        elif t[0] == 'list':
            blocks.append(['list', t[1], []])
        elif t[0] == 'anim':
            blocks.append(['anim', t[1], bytes([num(f['sprite']), num(f['flags']), num(f['id'])]) +
                           bytes.fromhex(f.get('motion', ''))])
        elif t[0] == 'bytes':
            blocks.append(['bytes', bytes.fromhex(t[1])])
        else:
            blocks[-1][2].append((num(t[0]), num(t[1]), num(t[2]), f))
    addr, a = {}, base
    for b in blocks:
        if b[0] in ('list', 'anim'):
            addr[b[1]] = a
        a += {'record': 6, 'list': 6 * len(b[2]) + 2 if b[0] == 'list' else 0,
              'anim': len(b[2]) + 1 if b[0] == 'anim' else 0, 'bytes': len(b[1])}[b[0]]

    def at(s):
        return addr[s] if s in addr else int(s[-4:], 16)
    out = bytearray()
    for b in blocks:
        if b[0] == 'record':
            out += le(at(b[2])) + le(at(b[3])) + le(b[4])
        elif b[0] == 'list':
            for d, y, adv, f in b[2]:
                out += le(d) + bytes([y, adv])
                out += le(at(f['anim'])) if 'anim' in f else bytes([num(f['sprite']), num(f['flags'])])
            out += b'\xFF\xFF'
        elif b[0] == 'anim':
            out += b[2] + b'\xFF'
        else:
            out += b[1]
    return bytes(out)


# tunes ------------------------------------------------------------------------------------------------------------

CHAN = {0x80: 'next', 0x81: 'mute', 0x82: 'env', 0x83: 'len', 0x84: 'tr'}
CHAN_ARG = (0x82, 0x83, 0x84)
DRUM = ['next', 'rest', 'd2', 'speed', 'd4', 'd5', 'noise', 'hit']


def tunes_parse(data):
    b = TUNES_BASE
    tunes = [[word(data, 0x3C + 6 * t + 2 * c) for c in range(3)] for t in range(2)]
    seqkind, seqs, patkind = {}, {}, {}
    for t in tunes:
        for c, s in enumerate(t):
            seqkind[s] = 'drum' if c == 2 else 'chan'
    for s, k in seqkind.items():
        p, pats = s - b, []
        while word(data, p):
            pats.append(word(data, p))
            patkind[word(data, p)] = k
            p += 2
        seqs[s] = pats
    blocks, o, end = [], 0x48, len(data)
    while o < end:
        a = b + o
        if a in seqs:
            blocks.append(('seq', a, seqs[a]))
            o += 2 * len(seqs[a]) + 2
        elif a in patkind:
            toks, k = [], patkind[a]
            while True:
                c = data[o]
                o += 1
                if k == 'chan':
                    if c < 0x80:
                        toks.append('n%d' % c)
                    elif c in CHAN_ARG:
                        toks.append('%s %d' % (CHAN[c], data[o]))
                        o += 1
                    else:
                        toks.append(CHAN.get(c, '$%02X' % c))
                    if c == 0x80:
                        break
                else:
                    tk = DRUM[c & 0x7F] if 0x80 <= c < 0x88 else '$%02X' % c
                    if c & 0x7F in (3, 7):
                        tk += ' %d' % data[o]
                        o += 1
                    toks.append(tk)
                    if c & 0x7F == 0:
                        break
            blocks.append((k, a, toks))
        else:
            nxt = min([x - b for x in list(seqs) + list(patkind) if x - b > o] + [end])
            blocks.append(('bytes', bytes(data[o:nxt])))
            o = nxt
    return tunes, blocks


def tunes_export(name, data):
    tunes, blocks = tunes_parse(data)
    out = [TUNE_HELP.rstrip('\n'), 'notes ' + ' '.join(str(v) for v in data[:60])]
    out += ['tune A=Seq%04X B=Seq%04X D=Seq%04X' % tuple(t) for t in tunes]
    for bl in blocks:
        if bl[0] == 'seq':
            out.append('seq Seq%04X %s' % (bl[1], ' '.join('Pat%04X' % p for p in bl[2])))
        elif bl[0] == 'bytes':
            out.append('bytes ' + bl[1].hex().upper())
        else:
            out.append('%s Pat%04X %s' % (bl[0], bl[1], ' '.join(bl[2])))
    return {'sound/tunes.txt': ('\n'.join(out) + '\n').encode('utf-8')}


def pattern_bytes(k, toks):
    bs, i = bytearray(), 0
    names = {v: c for c, v in CHAN.items()}
    while i < len(toks):
        tk = toks[i]
        i += 1
        if k == 'chan' and tk[0] == 'n' and tk[1:].isdigit():
            bs.append(int(tk[1:]))
            continue
        c = int(tk[1:], 16) if tk.startswith('$') else (names[tk] if k == 'chan' else 0x80 | DRUM.index(tk))
        bs.append(c)
        if (k == 'chan' and c in CHAN_ARG) or (k == 'drum' and c & 0x7F in (3, 7)):
            bs.append(int(toks[i]))
            i += 1
    return bytes(bs)


def tunes_build(files, name):
    notes, tunes, enc, addr = b'', [], [], {}
    for line in files['sound/tunes.txt'].decode('utf-8').split('\n'):
        t = line.split('#')[0].split()
        if not t:
            continue
        if t[0] == 'notes':
            notes = bytes(int(v) for v in t[1:])
        elif t[0] == 'tune':
            tunes.append([x.split('=')[1] for x in t[1:]])
        elif t[0] == 'bytes':
            enc.append((None, bytes.fromhex(t[1])))
        elif t[0] == 'seq':
            enc.append((t[1], t[2:]))
        else:
            enc.append((t[1], pattern_bytes(t[0], t[2:])))
    a = TUNES_BASE + len(notes) + 6 * len(tunes)
    for nm, v in enc:
        if nm:
            addr[nm] = a
        a += len(v) if isinstance(v, bytes) else 2 * len(v) + 2
    out = bytearray(notes)
    for t in tunes:
        for s in t:
            out += le(addr[s])
    for nm, v in enc:
        if isinstance(v, bytes):
            out += v
        else:
            for p in v:
                out += le(addr[p])
            out += b'\0\0'
    return bytes(out)


# screens ---------------------------------------------------------------------------------------------------------

def screen_png(scr):
    img = Image.new('RGB', (256, 192))
    px = img.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for cx in range(32):
            b, at = scr[row + cx], scr[6144 + (y >> 3) * 32 + cx]
            bright = 8 if at & 64 else 0
            ink, paper = (at & 7) + bright, ((at >> 3) & 7) + bright
            for bit in range(8):
                px[cx * 8 + bit, y] = ZX[ink if b >> (7 - bit) & 1 else paper]
    f = io.BytesIO()
    img.save(f, 'PNG')
    return f.getvalue()


# the dispatch -------------------------------------------------------------------------------------------------------

EXPORTERS = {'table': table_export, 'text': text_export, 'lists': lists_export, 'menus': menus_export, 'sprites': sprites_export,
             'trail': trail_export, 'tunes': tunes_export}
BUILDERS = {'table': table_build, 'text': text_build, 'lists': lists_build, 'menus': menus_build, 'sprites': sprites_build,
            'trail': trail_build, 'tunes': tunes_build}
EDITABLE = {'table': ['.txt'], 'text': ['.txt'], 'lists': ['.csv'], 'menus': ['.csv'], 'sprites': ['.png', '.csv'],
            'trail': ['.txt'], 'tunes': ['.txt']}


def export(name, data):
    k = kind(name)
    if k in EXPORTERS:
        return EXPORTERS[k](name, data)
    if k == 'screen':
        return {name: data, stem(name) + '.png': screen_png(data)}
    return {name: data}


def build_one(name):
    k = kind(name)
    if k not in BUILDERS:
        return open(os.path.join(RES, name), 'rb').read()
    files = {stem(name) + s: open(os.path.join(RES, stem(name) + s), 'rb').read() for s in EDITABLE[k]}
    return BUILDERS[k](files, name)


def load(name):
    """a resource's bytes, built from its editable file"""
    return build_one(name)


def resources():
    """the @res names behind the files in src/res"""
    names = set()
    for top, _dirs, fs in os.walk(RES):
        for n in fs:
            rel = os.path.relpath(os.path.join(top, n), RES)
            base, ext = os.path.splitext(rel)
            if n == 'README.md' or n.startswith('.') or rel == 'screens/loading.png':
                continue
            if ext in ('.scr', '.bin'):
                names.add(rel)
            elif kind(base + '.bin') in EDITABLE and ext in EDITABLE[kind(base + '.bin')]:
                names.add(base + '.bin')
    return sorted(names)


def install(files):
    INSTALLING.clear()
    INSTALLING.update(files)
    for name in sorted(files):
        forms = export(name, files[name])
        for rel, b in forms.items():
            path = os.path.join(RES, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(b)
        if name not in forms and os.path.exists(os.path.join(RES, name)):
            os.remove(os.path.join(RES, name))
    INSTALLING.clear()


def build(out):
    for name in resources():
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(build_one(name))


def check():
    bad = 0
    names = resources()
    for name in names:
        for rel, b in export(name, build_one(name)).items():
            src = os.path.join(RES, rel)
            same = os.path.exists(src) and open(src, 'rb').read() == b
            if not same and rel.endswith('.png') and os.path.exists(src):  # a PNG compares by its pixels
                same = Image.open(src).convert('RGB').tobytes() == Image.open(io.BytesIO(b)).convert('RGB').tobytes()
            if not same:
                print('bad: %s does not come back unchanged' % rel)
                bad += 1
    print('res: %d resources, %d bad' % (len(names), bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check', 'export'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--from', dest='src', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    if args.command == 'export':
        files = {}
        for top, _dirs, names in os.walk(args.src):
            for n in names:
                rel = os.path.relpath(os.path.join(top, n), args.src)
                files[rel] = open(os.path.join(top, n), 'rb').read()
        install(files)
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

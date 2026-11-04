#!/usr/bin/env python3
"""The saved games of the editor tape (seven levels and the editor's own) as editable text, and back, byte for byte.

    python3 levels.py text  TAPE.tap OUTDIR      # the 2 + 9425-byte blocks of the tape -> OUTDIR/<slug>.txt
    python3 levels.py build IN.txt OUT.bin       # the text -> the 9425-byte block (OUT.bin) and its 2-byte sum (OUT.sum)
    python3 levels.py check TAPE.tap [DIR]       # every level: block -> text -> block, and the sum block, identical
    python3 levels.py render IN.txt OUT.png      # the map top-down with the buildings, capture points, robots, ship
    python3 levels.py sheet DIR OUT.png          # the eight maps on one sheet

The block is the memory $D92B-$FDFB as SaveGame ($C28D) leaves it (docs/03-build-and-load.md 3.6, docs/10):

    $D92B  45  SaveShots      Shots ($D7D3) staged: 5 records of 9 bytes
    $D958  168 SaveBuildings  Buildings ($FF01) staged: 56 records of 3 bytes
    $DA00  768 Robots         48 records of 16 bytes, slots 0-23 the player's, 24-47 the enemy's
    $DD00  8192 Map           16 rows of 512 cells
    $FD00  252 the variables  RandomSeed ... the capture points Warbases $FD70, Factories $FD84 (to $FDFB)

The 2-byte block is the 16-bit byte sum of the 9425 bytes (SaveChecksum $C30F), little-endian.

The text: `;` starts a comment. Sections in this order, each line one field or record:

    level NAME
    var NAME VALUE ...            a variable of $FD00-$FD6F in address order; VALUE decimal or $hex, one per byte, or
                                  one 16-bit word for the 2-byte names (PrintAddr, MapView, ...); `bytes $ADDR ...`
                                  for bytes no name covers
    point K X Y OWNER TYPE COUNT  capture point K (0-3 Warbases, 4-27 Factories): the door (X, Y), OWNER one of
                                  neutral / player / enemy / both, `+destroyed` for bit 7 ($80), TYPE warbase,
                                  electronics, nuclear, phasers, missiles, cannon, chassis; or `point K raw $.. x5`
    building K X Y TYPE           a used building record: pad, electronics ... chassis, flag-player, flag-enemy
    building K raw $LO $HI $T     a record as bytes (a free one keeping old bytes, or a cell off the map)
    robot K X Y key=value ...     a live robot record (2.7 of docs/07 of Nether Earth): course, steps, parts (names
                                  joined by +), facing, height, control, order, strength, ground, target, delay;
                                  `cell=$xxxx` when +$00/+$01 is not the cell of (X, Y)
    robot K raw $.. x16           a free slot that keeps bytes
    shot K raw $.. x9             a shot record that is not all zero
    map                           then 4 strips of 128 columns, 16 rows each (row 0 first), "RR " + 128 characters
    cell X Y $HH                  a map byte the characters and the derived marks do not give

Map characters: `.` empty ground (type 0), `A`-`Z` the anchor (bit 5 clear) of a block of type 1-26 (A = 1, so
B-E stones 2-5, F-G boulders / wrecks 6-7, H-K rocks 8-11, L-N trench 12-14, O low block 15, P tall block 16,
Q low block with a door 17, R tall block with a window 18, U the edge post 21), `a`-`z` the three other cells of a
block (bit 5 set). Bit 6 (an object's anchor) is derived from the live robots, the used buildings and the flying
shots; bit 7 (the ship) from ShipX / ShipY; anything else is a `cell` line.
"""
import os
import re
import sys

LEN = 9425
SHOTS, BUILDINGS, ROBOTS, MAP, VARS = 0, 45, 213, 981, 9173      # offsets in the block
BASE = 0xD92B
ROWS, COLS = 16, 512

SLUGS = [('enemy-at-the-gates', 'Enemy At The Gates'), ('break-through', 'Break Through'),
         ('fortifications', 'Fortifications'), ('the-chase', 'The Chase'), ('jungle-of-stone', 'Jungle Of Stone'),
         ('double-frontline', 'Double Frontline'), ('the-slogan', 'The Slogan'),
         ('editor-save', 'the editor tape\'s saved game')]
SUM_BLOCKS = [6, 8, 10, 12, 14, 16, 18, 26]          # TAP index of each one's 2-byte block (tzx_blocks.py's TAP)

# $FD00-$FD6F: (address, name, size, word) from Nether Earth's src/game/game.ann @equ
VARIABLES = [(0xFD00, 'RandomSeed', 4, False), (0xFD04, 'PrintAddr', 2, True), (0xFD06, 'MapView', 2, True),
             (0xFD08, 'SavedSP', 2, True), (0xFD0A, 'ViewX', 2, True), (0xFD0C, 'Input', 1, False),
             (0xFD0D, 'ShipY', 1, False), (0xFD0E, 'ShipX', 2, True), (0xFD10, 'Altitude', 1, False),
             (0xFD11, 'ShipDrawPos', 2, False), (0xFD13, 'PrintAttr', 1, False), (0xFD14, 'PrintAttrAddr', 2, True),
             (0xFD16, 'PrintHeight', 1, False), (0xFD17, 'PrintWidth', 1, False), (0xFD1A, 'RadarPhase', 1, False),
             (0xFD1B, 'RadarLeft', 1, False), (0xFD1C, 'RadarColumn', 2, True), (0xFD1E, 'RadarBlink', 1, False),
             (0xFD1F, 'MenuCursor', 2, False), (0xFD21, 'MenuParts', 1, False), (0xFD22, 'Resources', 7, False),
             (0xFD29, 'MenuResources', 7, False), (0xFD30, 'ClimbTurns', 1, False), (0xFD31, 'PrintColumn', 1, False),
             (0xFD32, 'PrintRow', 1, False), (0xFD33, 'TitleColourPhase', 1, False), (0xFD34, 'TurnFrames', 1, False),
             (0xFD35, 'Clock', 4, False), (0xFD39, 'PanelBusy', 1, False), (0xFD3A, 'PlayerBuildings', 7, False),
             (0xFD41, 'PlayerRobotCount', 1, False), (0xFD42, 'EnemyBuildings', 7, False),
             (0xFD49, 'EnemyRobotCount', 1, False), (0xFD4A, 'EnemyResources', 7, False), (0xFD51, 'Side', 1, False),
             (0xFD52, 'RadarDirty', 1, False), (0xFD53, 'SoundFx', 1, False), (0xFD54, 'BassReturnPos', 2, True),
             (0xFD56, 'LeadReturnPos', 2, True)]
POINTS = 0xFD70
OWNERS = {0x00: 'neutral', 0x20: 'enemy', 0x40: 'player', 0x60: 'both'}
POINT_TYPES = ['warbase', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis']
BUILDING_TYPES = ['pad', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis', 'flag-player',
                  'flag-enemy']
PARTS = ['bipod', 'tracks', 'antigrav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electronics']
ROBOT_FIELDS = [(5, 'course'), (6, 'steps'), (7, 'parts'), (8, 'facing'), (9, 'height'), (10, 'control'),
                (11, 'order'), (12, 'strength'), (13, 'ground'), (14, 'target'), (15, 'delay')]


def num(word):
    return int(word[1:], 16) if word.startswith('$') else int(word, 0)


def cell_address(x, y):
    return 0xDD00 + 0x200 * y + x


def cell_xy(address):
    return (address - 0xDD00) % 0x200, (address - 0xDD00) // 0x200


def on_map(address):
    return 0xDD00 <= address < 0xFD00


def hexes(data):
    return ' '.join('$%02X' % b for b in data)


def objects(d):
    """the cells bit 6 is derived for: live robots, used buildings, flying shots (as their records say)"""
    out = set()
    for k in range(48):
        r = d[ROBOTS + 16 * k:ROBOTS + 16 * k + 2]
        if r[1]:
            out.add(r[0] | r[1] << 8)
    for k in range(56):
        r = d[BUILDINGS + 3 * k:BUILDINGS + 3 * k + 2]
        if r[1]:
            out.add(r[0] | r[1] << 8)
    for k in range(5):
        r = d[SHOTS + 9 * k:SHOTS + 9 * k + 2]
        if r[1]:
            out.add(r[0] | r[1] << 8)
    return out


def var(d, address, n=1):
    return d[VARS + address - 0xFD00:VARS + address - 0xFD00 + n]


def ship_cell(d):
    x = var(d, 0xFD0E, 2)
    return cell_address(x[0] | x[1] << 8, var(d, 0xFD0D)[0])


def map_char(c):
    t, rest = c & 0x1F, c & 0x20
    if t == 0 and not rest:
        return '.'
    if 1 <= t <= 26:
        return chr((ord('a') if rest else ord('A')) + t - 1)
    return None


def char_value(ch):
    if ch == '.':
        return 0
    if 'A' <= ch <= 'Z':
        return ord(ch) - ord('A') + 1
    if 'a' <= ch <= 'z':
        return 0x20 | (ord(ch) - ord('a') + 1)
    raise ValueError(f'map character {ch!r}')


def marks(d, cells):
    """the map bytes the characters give, with bits 6 and 7 derived"""
    out = bytearray(cells)
    for a in objects(d):
        if on_map(a):
            out[a - 0xDD00] |= 0x40
    s = ship_cell(d)
    if on_map(s):
        out[s - 0xDD00] |= 0x80
    return out


# ---------------------------------------------------------------------------------------------------------------
# block -> text

def to_text(d, name, sum_bytes):
    assert len(d) == LEN
    o = [f'; Nether Earth saved game "{name}" (levels.py; the format: tools/levels.py, docs/10-gameplay-logic.md).',
         f'; The 2-byte block, the sum: ${sum_bytes[0] | sum_bytes[1] << 8:04X} (rebuilt from the bytes below).',
         f'level {name}', '', '; the variables $FD00-$FD6F']
    at = 0xFD00
    for address, nm, size, word in VARIABLES:
        if address > at:
            o.append(f'bytes ${at:04X} ' + hexes(var(d, at, address - at)))
        v = var(d, address, size)
        o.append(f'var {nm} ' + ('$%04X' % (v[0] | v[1] << 8) if word else ' '.join(str(b) for b in v)))
        at = address + size
    if at < POINTS:
        o.append(f'bytes ${at:04X} ' + hexes(var(d, at, POINTS - at)))
    o += ['', '; capture points $FD70: K X Y owner type count (0-3 the warbases, 4-27 the factories)']
    for k in range(28):
        p = var(d, POINTS + 5 * k, 5)
        own = p[3]
        if own & 0x18:
            o.append(f'point {k} raw ' + hexes(p))
            continue
        owner = OWNERS[own & 0x60] + ('+destroyed' if own & 0x80 else '')
        o.append(f'point {k:2} {p[0] | p[1] << 8:3} {p[2]:2} {owner} {POINT_TYPES[own & 7] if own & 7 < 7 else "type7"} {p[4]}')
    o += ['', '; buildings $FF01 (staged at $D958): K X Y type']
    for k in range(56):
        r = d[BUILDINGS + 3 * k:BUILDINGS + 3 * k + 3]
        a = r[0] | r[1] << 8
        if r[1] and on_map(a) and r[2] < len(BUILDING_TYPES):
            x, y = cell_xy(a)
            o.append(f'building {k:2} {x:3} {y:2} {BUILDING_TYPES[r[2]]}')
        elif any(r):
            o.append(f'building {k:2} raw ' + hexes(r))
    o += ['', '; robots $DA00: slots 0-23 the player\'s, 24-47 the enemy\'s']
    for k in range(48):
        r = d[ROBOTS + 16 * k:ROBOTS + 16 * k + 16]
        if not r[1]:
            if any(r):
                o.append(f'robot {k:2} raw ' + hexes(r))
            continue
        x, y = r[2] | r[3] << 8, r[4]
        words = [f'robot {k:2} {x:3} {y:2}']
        if (r[0] | r[1] << 8) != cell_address(x, y):
            words.append('cell=$%04X' % (r[0] | r[1] << 8))
        for off, nm in ROBOT_FIELDS:
            if nm == 'parts':
                words.append('parts=' + ('+'.join(PARTS[b] for b in range(8) if r[7] >> b & 1) or '0'))
            else:
                words.append(f'{nm}={r[off]}')
        o.append(' '.join(words))
    o += ['', '; shots $D7D3 (staged at $D92B)']
    for k in range(5):
        r = d[SHOTS + 9 * k:SHOTS + 9 * k + 9]
        if any(r):
            o.append(f'shot {k} raw ' + hexes(r))
    cells = d[MAP:MAP + 8192]
    chars = bytearray(8192)
    exceptions = []
    text_rows = []
    for i, c in enumerate(cells):
        ch = map_char(c & 0x3F)
        chars[i] = ord(ch) if ch else ord('.')
    derived = marks(d, bytes(char_value(chr(ch)) for ch in chars))
    for i, c in enumerate(cells):
        if derived[i] != c:
            exceptions.append(f'cell {i % 512:3} {i // 512:2} ${c:02X}')
    o += ['', '; the map $DD00: 16 rows of 512 cells, in four strips of 128 columns', 'map']
    for strip in range(4):
        o.append(f'; columns {strip * 128}-{strip * 128 + 127}')
        o.append('   ' + ''.join(str((strip * 128 + c) // 10 % 10) if c % 10 == 0 else ' ' for c in range(128)))
        for y in range(16):
            row = chars[y * 512 + strip * 128:y * 512 + strip * 128 + 128].decode()
            o.append(f'{y:02} {row}')
    if exceptions:
        o += ['', '; map bytes the characters and the derived marks do not give'] + exceptions
    return '\n'.join(o) + '\n'


# ---------------------------------------------------------------------------------------------------------------
# text -> block

def from_text(text):
    d = bytearray(LEN)
    name = None
    at = {a: (n, s, w) for a, n, s, w in VARIABLES}
    by_name = {n: (a, s, w) for a, n, s, w in VARIABLES}
    lines = text.splitlines()
    i = 0
    rows = []
    overrides = []

    def setvar(address, values):
        d[VARS + address - 0xFD00:VARS + address - 0xFD00 + len(values)] = bytes(values)

    while i < len(lines):
        line = lines[i].split(';', 1)[0].rstrip()
        i += 1
        if not line.strip():
            continue
        w = line.split()
        kind = w[0]
        if kind == 'level':
            name = line.split(None, 1)[1]
        elif kind == 'var':
            address, size, word = by_name[w[1]]
            if word:
                v = num(w[2])
                setvar(address, [v & 255, v >> 8])
            else:
                vals = [num(x) for x in w[2:]]
                assert len(vals) == size, line
                setvar(address, vals)
        elif kind == 'bytes':
            setvar(num(w[1]), [num(x) for x in w[2:]])
        elif kind == 'point':
            k = int(w[1])
            if w[2] == 'raw':
                p = [num(x) for x in w[3:8]]
            else:
                x, y = int(w[2]), int(w[3])
                owner = w[4].split('+')
                own = {v: k_ for k_, v in OWNERS.items()}[owner[0]] | (0x80 if 'destroyed' in owner[1:] else 0)
                own |= 7 if w[5] == 'type7' else POINT_TYPES.index(w[5])
                p = [x & 255, x >> 8, y, own, int(w[6])]
            setvar(POINTS + 5 * k, p)
        elif kind == 'building':
            k = int(w[1])
            if w[2] == 'raw':
                r = [num(x) for x in w[3:6]]
            else:
                a = cell_address(int(w[2]), int(w[3]))
                r = [a & 255, a >> 8, BUILDING_TYPES.index(w[4])]
            d[BUILDINGS + 3 * k:BUILDINGS + 3 * k + 3] = bytes(r)
        elif kind == 'robot':
            k = int(w[1])
            if w[2] == 'raw':
                r = [num(x) for x in w[3:19]]
            else:
                x, y = int(w[2]), int(w[3])
                fields = dict(f.split('=') for f in w[4:])
                a = num(fields['cell']) if 'cell' in fields else cell_address(x, y)
                r = [a & 255, a >> 8, x & 255, x >> 8, y] + [0] * 11
                for off, nm in ROBOT_FIELDS:
                    v = fields[nm]
                    if nm == 'parts':
                        v = 0 if v == '0' else sum(1 << PARTS.index(p) for p in v.split('+'))
                    else:
                        v = num(v)
                    r[off] = v
            d[ROBOTS + 16 * k:ROBOTS + 16 * k + 16] = bytes(r)
        elif kind == 'shot':
            k = int(w[1])
            d[SHOTS + 9 * k:SHOTS + 9 * k + 9] = bytes(num(x) for x in w[3:12])
        elif kind == 'map':
            while len(rows) < 64:
                raw = lines[i]
                i += 1
                if raw.startswith(';') or raw.startswith('   '):
                    continue
                rows.append(raw[3:])
        elif kind == 'cell':
            overrides.append((int(w[1]), int(w[2]), num(w[3])))
        else:
            raise ValueError(f'line {i}: {line}')
    cells = bytearray(8192)
    for n, row in enumerate(rows):
        strip, y = divmod(n, 16)
        assert len(row) == 128, f'strip {strip} row {y}: {len(row)} characters'
        for c, ch in enumerate(row):
            cells[y * 512 + strip * 128 + c] = char_value(ch)
    cells = marks(d, cells)
    for x, y, v in overrides:
        cells[y * 512 + x] = v
    d[MAP:MAP + 8192] = cells
    s = sum(d) & 0xFFFF
    return bytes(d), bytes([s & 255, s >> 8]), name


# ---------------------------------------------------------------------------------------------------------------
# the tape

def tap_blocks(path):
    data = open(path, 'rb').read()
    out, at = [], 0
    while at < len(data):
        n = data[at] | data[at + 1] << 8
        out.append(data[at + 2:at + 2 + n])
        at += 2 + n
    return out


def saved_games(tap):
    """(slug, name, sum bytes, 9425 bytes) from the tape's flag-0 pairs"""
    blocks = tap_blocks(tap)
    out = []
    for (slug, name), k in zip(SLUGS, SUM_BLOCKS):
        s, g = blocks[k], blocks[k + 1]
        assert s[0] == 0 and g[0] == 0 and len(s) == 4 and len(g) == LEN + 2
        out.append((slug, name, s[1:-1], g[1:-1]))
    return out


def cmd_text(tap, outdir):
    os.makedirs(outdir, exist_ok=True)
    for slug, name, s, g in saved_games(tap):
        with open(os.path.join(outdir, slug + '.txt'), 'w') as f:
            f.write(to_text(g, name, s))
        print(os.path.join(outdir, slug + '.txt'))


def cmd_build(src, out):
    d, s, _ = from_text(open(src).read())
    open(out, 'wb').write(d)
    open(os.path.splitext(out)[0] + '.sum', 'wb').write(s)


def cmd_check(tap, folder=None):
    bad = 0
    for slug, name, s, g in saved_games(tap):
        text = open(os.path.join(folder, slug + '.txt')).read() if folder else to_text(g, name, s)
        d, s2, _ = from_text(text)
        ok = d == g and s2 == s
        bad += not ok
        print(f'{slug:20} {"identical" if ok else "DIFFERENT"}  sum ${s[0] | s[1] << 8:04X}'
              f'  cells by exception {text.count(chr(10) + "cell ")}')
    if bad:
        raise SystemExit(f'{bad} differ')


# ---------------------------------------------------------------------------------------------------------------
# render (the map code of Nether Earth's tools/ill_render.py, map_strip, on the block)

def memory(d):
    """a 64 K image as LoadGameBlocks leaves it: the block at $D92B, the shots and buildings copied back"""
    m = bytearray(0x10000)
    m[BASE:BASE + LEN] = d
    m[0xD7D3:0xD7D3 + 45] = d[SHOTS:SHOTS + 45]
    m[0xFF01:0xFF01 + 168] = d[BUILDINGS:BUILDINGS + 168]
    return m


def render_map(d, title, cs=6):
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
    import kitlib as K
    from PIL import Image, ImageDraw
    OURS, THEIRS, NEUTRAL, SHIP = (90, 210, 110), (235, 85, 80), (200, 200, 210), (120, 200, 255)
    m = memory(d)

    def cell_colour(c):
        t = c & 0x1F
        for lo, hi, col in ((0, 1, (36, 36, 30)), (2, 5, (95, 85, 50)), (6, 7, (110, 70, 50)), (8, 11, (140, 125, 70)),
                            (12, 14, (40, 70, 110))):
            if lo <= t <= hi:
                return col
        return {15: (170, 170, 175), 17: (170, 170, 175), 16: (230, 230, 235), 18: (230, 230, 235),
                21: (200, 60, 200)}.get(t, (255, 0, 255))

    def owner_colour(own):
        return (110, 110, 110) if own & 0x80 else THEIRS if own & 0x20 else OURS if own & 0x40 else NEUTRAL

    tiny, f = K.font(11), K.font(14)
    n, L = 128, 34
    strip_h = 16 * cs + 18
    W, H = L + n * cs + 16, 34 + 4 * strip_h + 84
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d_ = ImageDraw.Draw(out)
    d_.text((L, 8), title, fill=K.TEXT, font=f)
    letters = 'BENPMCW'
    for k in range(4):
        x0, top = k * n, 30 + k * strip_h
        for y in range(16):
            for x in range(n):
                c = m[0xDD00 + 0x200 * y + x0 + x]
                d_.rectangle([L + x * cs, top + y * cs, L + x * cs + cs - 1, top + y * cs + cs - 1], fill=cell_colour(c))
        for y in range(16):
            for x in range(n):
                c = m[0xDD00 + 0x200 * y + x0 + x]
                if c & 0x1F and not c & 0x20 and c & 0x1F != 21:
                    d_.rectangle([L + x * cs, top + (y - 1) * cs, L + (x + 2) * cs - 1, top + (y + 1) * cs - 1],
                                 outline=(20, 20, 24))
        for i in range(56):
            r = m[0xFF01 + 3 * i:0xFF04 + 3 * i]
            if not r[1]:
                continue
            x, y = cell_xy(r[0] | r[1] << 8)
            if x0 <= x < x0 + n:
                X, Y = L + (x - x0) * cs, top + y * cs
                col = OURS if r[2] in (0, 7) else THEIRS if r[2] == 8 else (250, 210, 80)
                d_.polygon([(X + cs // 2, Y - 1), (X + cs, Y + cs // 2), (X + cs // 2, Y + cs), (X - 1, Y + cs // 2)],
                           fill=col, outline=(0, 0, 0))
        for i in range(28):
            p = m[POINTS + 5 * i:POINTS + 5 * i + 5]
            x, y, own = p[0] | p[1] << 8, p[2], p[3]
            if not x0 <= x < x0 + n:
                continue
            X, Y = L + (x - x0) * cs, top + y * cs
            col = owner_colour(own)
            d_.rectangle([X - 2, Y - 2, X + cs + 1, Y + cs + 1], outline=col, width=2)
            d_.text((X + cs + 3, Y - 3), 'x' if own & 0x80 else 'B' if i < 4 else letters[own & 7], fill=col, font=tiny, stroke_width=2,
                    stroke_fill=(0, 0, 0))
        for i in range(48):
            r = m[0xDA00 + 16 * i:0xDA10 + 16 * i]
            x, y = r[2] | r[3] << 8, r[4]
            if r[1] and x0 <= x < x0 + n:
                X = L + (x - x0) * cs
                d_.ellipse([X, top + (y - 1) * cs, X + 2 * cs - 1, top + (y + 1) * cs - 1],
                           fill=OURS if i < 24 else THEIRS, outline=(0, 0, 0))
        sx, sy = m[0xFD0E] | m[0xFD0F] << 8, m[0xFD0D]
        if x0 <= sx < x0 + n:
            X, Y = L + (sx - x0) * cs, top + sy * cs
            d_.line([X - cs, Y + cs // 2, X + 2 * cs, Y + cs // 2], fill=SHIP, width=2)
            d_.line([X + cs // 2, Y - cs, X + cs // 2, Y + 2 * cs], fill=SHIP, width=2)
        for c in range(0, n + 1, 16):
            d_.text((L + c * cs + 2, top + 16 * cs + 1), str(x0 + c), fill=K.DIM, font=tiny)
        d_.text((4, top + 2), '0', fill=K.DIM, font=tiny)
        d_.text((4, top + 15 * cs - 4), '15', fill=K.DIM, font=tiny)
    for k, line in enumerate(['terrain: dark ground, brown stones / wrecks, ochre rocks, blue trench,',
                              'grey low block, white tall block, magenta post',
                              'squares: capture points (B warbase, E N P M C W factories): green ours,',
                              'red the enemy\'s, white neutral, grey x out of play ($80)',
                              'diamonds: buildings (yellow roof, green pad / flag, red flag);',
                              'discs: robots; blue cross: the ship']):
        d_.text((L, H - 82 + 13 * k), line, fill=K.DIM, font=tiny)
    return out


def cmd_render(src, out):
    d, _, name = from_text(open(src).read())
    render_map(d, f'{name}: the map ({os.path.basename(src)})').save(out)
    print(out)


def cmd_sheet(folder, out):
    from PIL import Image
    pics = []
    for slug, name in SLUGS:
        d, _, nm = from_text(open(os.path.join(folder, slug + '.txt')).read())
        pics.append(render_map(d, f'{nm} (src/res/levels/{slug}.txt)', cs=4))
    w, h = pics[0].size
    sheet = Image.new('RGB', (2 * w, 4 * h))
    for k, p in enumerate(pics):
        sheet.paste(p, (k % 2 * w, k // 2 * h))
    sheet.save(out)
    print(out, sheet.size)


def main():
    a = sys.argv[1:]
    if a[:1] == ['text'] and len(a) == 3:
        cmd_text(a[1], a[2])
    elif a[:1] == ['build'] and len(a) == 3:
        cmd_build(a[1], a[2])
    elif a[:1] == ['check'] and len(a) in (2, 3):
        cmd_check(a[1], a[2] if len(a) == 3 else None)
    elif a[:1] == ['render'] and len(a) == 3:
        cmd_render(a[1], a[2])
    elif a[:1] == ['sheet'] and len(a) == 3:
        cmd_sheet(a[1], a[2])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

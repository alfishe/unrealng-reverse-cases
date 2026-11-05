#!/usr/bin/env python3
"""The level data $6800-$7E59 (src/res/levels/levels.bin) as text and back: the enemy paths, the waves, the enemy
kinds and their colours, the level table, the level scripts, the scenery patterns, scripts, groups and shapes.

Every section starts at a fixed address (the code reads the tables there) and must end where the next one starts.
Inside a section the bytes are a listing: labels ("name:") mark the entry points the tables name, the tokens of a line
decode the bytes in address order. A byte (or a run of them) that is no whole item before the next label, or whose
item would not encode back to the same bytes, is written as "db $xx": the round trip is exact for any bytes.
The formats are described in src/res/levels/README.md.

    python3 tools/res_levels.py decode levels.bin > levels.txt
    python3 tools/res_levels.py encode levels.txt > levels.bin
Copied from the 48K case (../zynaps/tools): the formats of the same bytes.
"""
import re
import sys

BASE, END = 0x6800, 0x7E5A
SECTIONS = [  # (name, address)
    ('path-starts', 0x6800), ('paths', 0x681C), ('wave-index', 0x6926), ('waves', 0x6943), ('kinds', 0x6A65),
    ('kind-colours', 0x6B15), ('levels', 0x6B2D), ('scripts', 0x6B8D), ('patterns', 0x72A9),
    ('scenery-scripts', 0x72E1), ('groups', 0x749A), ('shapes', 0x7783)]
SECTION_AT = dict((n, a) for n, a in SECTIONS)
PATHS, WAVES = 0x681C, 0x6943

# path bytecode (RunPath $94CB): commands 0-6 take a parameter P (bits 3-6), command 7 picks an extended op by P
PATH_OPS = ['accel', 'setloop', 'interval', 'bounce', 'homeplayer', 'direction', 'hometarget']
PATH_EXT = ['scroll', 'stop', 'randomdir', 'loop', 'driftmiddle', 'aimplayer', 'scrollalways', 'move', 'home',
            'tocentre', 'land', 'randomspeed', 'bouncearena', 'dive', 'movefragile', 'wait']
ACCEL = [('+x', 8), ('-x', 16), ('+y', 32), ('-y', 64)]
# level script (ScriptStep $AD66)
SCRIPT_OPS = {0: 'nop', 1: 'scrollresume', 2: 'scrolloff', 3: 'starson', 4: 'starsoff', 5: 'levelend', 6: 'nop6',
              13: 'return', 14: 'save', 15: 'clearrows', 16: 'escapefirst', 17: 'anyenemies'}
SCRIPT_ARGS = {7: ('poke', 2), 8: ('copy', 2), 9: ('dec', 1), 10: ('inc', 1), 11: ('test', 1), 12: ('add', 2)}
CONDS = ['', 'z', 'nz', 'c', 'nc', 'p', 'm']


def w(m, a):
    return m[a - BASE] | m[a - BASE + 1] << 8


class Labels:
    """The entry-point names: generated from the tables on decode"""

    def __init__(self):
        self.at = {}

    def add(self, address, name):
        self.at.setdefault(address, name)
        return self.at[address]

    def name(self, address):
        return self.at.get(address, '$%04X' % address)


def section_end(name):
    k = [n for n, _ in SECTIONS].index(name)
    return SECTIONS[k + 1][1] if k + 1 < len(SECTIONS) else END


def table(m, base, count=None):
    if count is None:
        count = (w(m, base) - base) // 2
    return [w(m, base + 2 * i) for i in range(count)]


def decode(data):
    m = data
    assert len(m) == END - BASE, 'levels: %d bytes, not %d' % (len(m), END - BASE)
    L = Labels()
    path_starts = [PATHS + 2 * m[i] for i in range(28)]
    for i, a in enumerate(path_starts):
        L.add(a, 'path%d' % i)
    wave_index = list(m[0x6926 - BASE:0x6943 - BASE])
    for i, e in enumerate(wave_index):
        L.add(WAVES + 2 * e, 'wave%d' % i)
    levels = [m[0x6B2D - BASE + 8 * k:0x6B35 - BASE + 8 * k] for k in range(12)]
    for k, rec in enumerate(levels):
        L.add(rec[1] | rec[2] << 8, 'level%d' % k)
    # jump targets of the level scripts: walk them
    todo = [rec[1] | rec[2] << 8 for rec in levels]
    seen = set()
    while todo:
        a = todo.pop()
        while 0x6B8D <= a < 0x72A9 - 1 and a not in seen:
            seen.add(a)
            op = m[a + 1 - BASE]
            if op < 0x40:
                a += 2 + 2 * SCRIPT_ARGS.get(op, ('', 0))[1]
                if op in (5, 13):
                    break
            elif op < 0x80 or op >= 0xC0:
                t = w(m, a + 2)
                L.add(t, 's%04X' % t)
                todo.append(t)
                if op == 0x40:
                    break
                a += 4
            else:
                a += 3
    # loop targets inside the paths
    a = PATHS
    while a < 0x6926:
        b = m[a - BASE]
        if b == 0x1F and a + 2 < 0x6926:
            t = w(m, a + 1)
            L.add(t, 'p%04X' % t)
            a += 3
        else:
            a += 1
    sc = table(m, 0x72E1)
    for i, a in enumerate(sc):
        L.add(a, 'scenery%d' % i)
    groups = table(m, 0x749A)
    for i, a in enumerate(groups):
        L.add(a, 'group%d' % i)
    shapes = table(m, 0x7783)
    for i, a in enumerate(shapes):
        L.add(a, 'shape%d' % i)

    out = ['# Zynaps: the level data $6800-$7E59 (tools/res_levels.py; the format: src/res/levels/README.md)', '']

    def listing(name, items):
        """items: a function (address, limit) -> (text, length) or None; labels cut the listing"""
        lo, hi = SECTION_AT[name], section_end(name)
        a = lo
        while a < hi:
            nxt = min([x for x in L.at if a < x < hi] + [hi])
            if a in L.at and lo <= a:
                out.append('%s:' % L.at[a])
            while a < nxt:
                got = items(a, nxt)
                if got is None:
                    out.append('    db $%02X' % m[a - BASE])
                    a += 1
                else:
                    text, n = got
                    out.append('    ' + text)
                    a += n

    # path starts
    out.append('section path-starts $6800  # path number -> its bytecode (28 bytes: (address - $681C) / 2)')
    for i in range(0, 28, 7):
        out.append('    ' + ' '.join(L.name(a) for a in path_starts[i:i + 7]))
    out.append('')

    out.append('section paths $681C  # the path bytecode: *N = the next command runs N frames (0 = for ever)')

    def path_item(a, lim):
        b = m[a - BASE]
        if b & 0x80:
            return '*%d' % (b & 0x7F), 1
        op, p = b & 7, b >> 3
        if op == 7 and p == 3:
            if a + 3 > lim:
                return None
            return 'loop %s' % L.name(w(m, a + 1)), 3
        if op == 7:
            return PATH_EXT[p], 1
        if op == 0:
            flags = ''.join(f for f, bit in ACCEL if b & bit)
            return 'accel' + flags, 1
        return '%s %d' % (PATH_OPS[op], p), 1

    lo, hi = PATHS, 0x6926
    a = lo
    while a < hi:
        nxt = min([x for x in L.at if a < x < hi] + [hi])
        if a in L.at:
            out.append('%s:' % L.at[a])
        toks = []
        while a < nxt:
            got = path_item(a, nxt)
            if got is None:
                toks.append('db $%02X' % m[a - BASE])
                a += 1
            else:
                toks.append(got[0])
                a += got[1]
        out.append('    ' + ', '.join(toks))
    out.append('')

    out.append('section wave-index $6926  # wave number (the script\'s "wave N") -> its definition')
    for i in range(0, 29, 8):
        out.append('    ' + ' '.join(L.name(WAVES + 2 * e) for e in wave_index[i:i + 8]))
    out.append('')

    out.append('section waves $6943  # bonus, kind, [path N], gap, then the enemies: x,y (y ? = random)')

    def wave_item(a, lim):
        b0, b1, n = m[a - BASE], m[a + 1 - BASE], m[a + 2 - BASE]
        size = 3 + (2 if b1 & 0x80 else 0) + 1 + 2 * n
        if a + size > lim:
            return None
        p = a + 3
        text = 'bonus $%02X kind %d' % (b0, b1 & 0x7F)
        if b1 & 0x80:
            path, skip = m[p - BASE], m[p + 1 - BASE]
            text += ' path %d' % path + ('' if skip == path else ' skip %d' % skip)
            p += 2
        text += ' gap %d :' % m[p - BASE]
        p += 1
        pos = []
        for i in range(n):
            x, y = m[p - BASE], m[p + 1 - BASE]
            pos.append('%d,%s' % (x, '?' if y == 0xFF else str(y)))
            p += 2
        if n == 0:
            pos = ['-']
        return text + ' ' + ' '.join(pos), size

    listing('waves', wave_item)
    out.append('')

    def rows(name, size, title, fmt):
        out.append('section %s $%04X  # %s' % (name, SECTION_AT[name], title))
        lo, hi = SECTION_AT[name], section_end(name)
        for k, a in enumerate(range(lo, hi, size)):
            out.append('    %s' % fmt(k, m[a - BASE:a - BASE + size]))
        out.append('')

    hexs = lambda bs: ' '.join('$%02X' % b for b in bs)  # noqa: E731
    rows('kinds', 8, 'kind: +$18 +$19/+$21 colour select, speeds +$0C/+$17, +$10 Ax, +$14 Ay, +$07 handler, '
         '+$25, +$0D', lambda k, bs: 'kind %d: %s' % (k, hexs(bs)))
    rows('kind-colours', 3, 'the colour sets ($80E9 + the kind\'s colour select) & $1C: +$19 +$20 +$22',
         lambda k, bs: 'colours %d: %s' % (k, hexs(bs)))
    rows('levels', 8, 'the level table (LevelStart $B062 copies a record to $81D7)',
         lambda k, bs: 'level %d: byte $%02X script %s flags $%02X scroll $%04X scenery %d speed %d'
         % (k, bs[0], L.name(bs[1] | bs[2] << 8), bs[3], bs[4] | bs[5] << 8, bs[6], bs[7]))

    out.append('section scripts $6B8D  # the level scripts: the frames to wait, then a command')

    def script_item(a, lim):
        if a + 2 > lim:
            return None
        t, op = m[a - BASE], m[a + 1 - BASE]
        if op < 0x40:
            if op in SCRIPT_OPS:
                return '%d %s' % (t, SCRIPT_OPS[op]), 2
            if op in SCRIPT_ARGS:
                name, n = SCRIPT_ARGS[op]
                if a + 2 + 2 * n > lim:
                    return None
                args = ' '.join('$%04X' % w(m, a + 2 + 2 * i) for i in range(n))
                return '%d %s %s' % (t, name, args), 2 + 2 * n
            return '%d op %d' % (t, op), 2
        if op < 0x80 or op >= 0xC0:
            if a + 4 > lim or (op & 0x3F) >= len(CONDS):
                return None
            word = 'jp' if op < 0x80 else 'call'
            cond = CONDS[op & 0x3F]
            return '%d %s %s%s' % (t, word, cond + ' ' if cond else '', L.name(w(m, a + 2))), 4
        if a + 3 > lim:
            return None
        return '%d wave %d y %d' % (t, op & 0x3F, m[a + 2 - BASE]), 3

    listing('scripts', script_item)
    out.append('')

    rows('patterns', 8, 'the colour patterns: 8 attributes to WorkCell $FFD8 (p0-p7 in the shapes)',
         lambda k, bs: 'pattern %d: %s' % (k, hexs(bs)))

    def table_lines(name, base, entries):
        out.append('section %s $%04X  # the table (%d entries), then the bodies' % (name, base, len(entries)))
        if base in L.at:
            out.append('%s:' % L.at[base])
        for i in range(0, len(entries), 8):
            out.append('    table ' + ' '.join(L.name(a) for a in entries[i:i + 8]))

    table_lines('scenery-scripts', 0x72E1, sc)

    def scenery_item(a, lim):
        b = m[a - BASE]
        if b < 0x80:
            return 'group %d' % b, 1
        if b == 0xFF:
            return 'end', 1
        if b == 0x80:
            if a + 2 > lim:
                return None
            return 'call %d' % m[a + 1 - BASE], 2
        if b & 0x20:
            if b != 0xE0 | (b & 0x0F) or b & 0x10:
                return None
            return 'mask $%02X' % ((b & 0x0F) << 4), 1
        if b != 0xC0 | (b & 7):
            return None
        return 'pattern %d' % (b & 7), 1

    listing_from(out, L, m, 0x72E1 + 2 * len(sc), 0x749A, scenery_item, join=True)
    out.append('')

    table_lines('groups', 0x749A, groups)

    def group_item(a, lim):
        b = m[a - BASE]
        if b == 0xFF:
            return 'end', 1
        if b & 0x80:
            if a + 2 > lim:
                return None
            return 'sub $%02X group %d' % (b, m[a + 1 - BASE]), 2
        if a + 3 > lim:
            return None
        mk, s = m[a + 1 - BASE], m[a + 2 - BASE]
        flags = (' hflip' if b & 0x40 else '') + (' vflip' if b & 0x20 else '')
        return 'put shape %d row %d col %d mask $%02X%s' % (s, b & 0x1F, mk & 0x0F, mk & 0xF0, flags), 3

    listing_from(out, L, m, 0x749A + 2 * len(groups), 0x7783, group_item)
    out.append('')

    table_lines('shapes', 0x7783, shapes)

    def shape_item(a, lim):
        h = m[a - BASE]
        p = a + 1
        lines = []
        for r in range(h):
            if p + 2 > lim:
                return None
            at, mk = m[p - BASE], m[p + 1 - BASE]
            n = bin(mk).count('1')
            if p + 2 + n > lim:
                return None
            tiles = list(m[p + 2 - BASE:p + 2 + n - BASE])
            cells = []
            for bit in range(7, -1, -1):
                cells.append('%02X' % tiles.pop(0) if mk >> bit & 1 else '..')
            if at & 1 and (at >> 1 | 0x80) in range(0xD8, 0xE0):
                attr = 'p%d' % ((at >> 1 | 0x80) - 0xD8)
            else:
                attr = '$%02X' % at
            lines.append('%-4s| %s' % (attr, ' '.join(cells)))
            p += 2 + n
        return 'rows %d\n' % h + '\n'.join('        ' + x for x in lines) if lines else 'rows 0', p - a

    listing_from(out, L, m, 0x7783 + 2 * len(shapes), END, shape_item)
    return ('\n'.join(out).rstrip() + '\n').encode()


def listing_from(out, L, m, lo, hi, items, join=False):
    a = lo
    while a < hi:
        nxt = min([x for x in L.at if a < x < hi] + [hi])
        if a in L.at:
            out.append('%s:' % L.at[a])
        toks = []
        while a < nxt:
            got = items(a, nxt)
            if got is None:
                toks.append('db $%02X' % m[a - BASE])
                a += 1
            else:
                toks.append(got[0])
                a += got[1]
        if join:
            out.append('    ' + ', '.join(toks))
        else:
            out += ['    ' + t for t in toks]


# ------------------------------------------------------------------------------------------------------------- encode

def num(s):
    s = s.strip()
    if s.startswith('$'):
        return int(s[1:], 16)
    return int(s)


def encode(text):
    text = text.decode() if isinstance(text, bytes) else text
    mem = {}
    labels = {}
    fix = []  # (address, size, label, line)
    a = None
    section = None
    pending_rows = None

    def emit(*bs):
        nonlocal a
        for b in bs:
            if a >= END:
                raise SystemExit('levels: the data runs past $%04X' % END)
            mem[a] = b & 0xFF
            a += 1

    def word_ref(tok, line):
        tok = tok.strip()
        if tok.startswith('$'):
            v = int(tok[1:], 16)
            emit(v & 0xFF, v >> 8)
        else:
            fix.append((a, 2, tok, line))
            emit(0, 0)

    sec_end = None
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.split('#', 1)[0].rstrip()
        if not line.strip():
            continue
        s = line.strip()
        if pending_rows is not None and pending_rows[0] > 0:
            mt = re.match(r'^(\S+)\s*\|\s*(.*)$', s)
            if not mt:
                raise SystemExit('levels:%d: a shape row expected' % number)
            attr = mt.group(1)
            if attr.startswith('p'):
                at = ((0xD8 + int(attr[1:])) & 0x7F) << 1 | 1
            else:
                at = num(attr)
            cells = mt.group(2).split()
            if len(cells) != 8:
                raise SystemExit('levels:%d: 8 cells a row' % number)
            mk, tiles = 0, []
            for c in cells:
                mk <<= 1
                if c != '..':
                    mk |= 1
                    tiles.append(int(c, 16))
            emit(at, mk, *tiles)
            pending_rows[0] -= 1
            continue
        if s.startswith('section '):
            parts = s.split()
            section = parts[1]
            if section not in SECTION_AT:
                raise SystemExit('levels:%d: no section %s' % (number, section))
            if a is not None and a != SECTION_AT[section]:
                raise SystemExit('levels:%d: the section before %s ends at $%04X, not $%04X'
                                 % (number, section, a, SECTION_AT[section]))
            a = SECTION_AT[section]
            continue
        if re.match(r'^[A-Za-z_]\w*:$', s):
            labels[s[:-1]] = a
            continue
        toks = [t.strip() for t in s.split(',')] if section in ('paths', 'scenery-scripts') and \
            not s.startswith('table') else [s]
        for t in toks:
            encode_item(section, t, number, emit, word_ref, labels, fix, lambda: a)
            if t.startswith('rows '):
                pending_rows = [int(t.split()[1])]
    if a != END:
        raise SystemExit('levels: the data ends at $%04X, not $%04X' % (a, END))
    for at, size, name, line in fix:
        if name.startswith('@path'):
            v = labels.get(name[5:])
            if v is None:
                raise SystemExit('levels:%d: no label %s' % (line, name[5:]))
            off = v - PATHS
            if off % 2 or not 0 <= off < 512:
                raise SystemExit('levels:%d: %s is not an even offset from $681C' % (line, name[5:]))
            mem[at] = off // 2
            continue
        if name.startswith('@wave'):
            v = labels.get(name[5:])
            if v is None:
                raise SystemExit('levels:%d: no label %s' % (line, name[5:]))
            off = v - WAVES
            if off % 2 or not 0 <= off < 512:
                raise SystemExit('levels:%d: %s is not an even offset from $6943' % (line, name[5:]))
            mem[at] = off // 2
            continue
        if name not in labels:
            raise SystemExit('levels:%d: no label %s' % (line, name))
        mem[at], mem[at + 1] = labels[name] & 0xFF, labels[name] >> 8
    return bytes(mem[x] for x in range(BASE, END))


def encode_item(section, t, number, emit, word_ref, labels, fix, here):
    p = t.split()
    if p[0] == 'db':
        emit(num(p[1]))
        return
    if section in ('path-starts', 'wave-index'):
        kind = '@path' if section == 'path-starts' else '@wave'
        for name in p:
            fix.append((here(), 1, kind + name, number))
            emit(0)
        return
    if section == 'paths':
        if p[0].startswith('*'):
            emit(0x80 | int(p[0][1:]))
        elif p[0] == 'loop':
            emit(0x1F)
            word_ref(p[1], number)
        elif p[0].startswith('accel'):
            b, rest = 0, p[0][5:]
            for f, bit in ACCEL:
                if f in rest:
                    b |= bit
                    rest = rest.replace(f, '', 1)
            if rest:
                raise SystemExit('levels:%d: accel flags +x -x +y -y' % number)
            emit(b)
        elif p[0] in PATH_EXT:
            emit(7 | PATH_EXT.index(p[0]) << 3)
        elif p[0] in PATH_OPS:
            emit(PATH_OPS.index(p[0]) | int(p[1]) << 3)
        else:
            raise SystemExit('levels:%d: no path command %s' % (number, p[0]))
        return
    if section == 'waves':
        mt = re.match(r'^bonus (\S+) kind (\d+)(?: path (\d+)(?: skip (\d+))?)? gap (\d+) :(.*)$', t)
        if not mt:
            raise SystemExit('levels:%d: cannot read the wave' % number)
        pos = [x for x in mt.group(6).split() if x != '-']
        path = mt.group(3)
        emit(num(mt.group(1)), int(mt.group(2)) | (0x80 if path is not None else 0), len(pos))
        if path is not None:
            emit(int(path), int(mt.group(4) if mt.group(4) is not None else path))
        emit(int(mt.group(5)))
        for xy in pos:
            x, y = xy.split(',')
            emit(int(x), 0xFF if y == '?' else int(y))
        return
    if section in ('kinds', 'kind-colours', 'patterns'):
        for v in t.split(':', 1)[1].split():
            emit(num(v))
        return
    if section == 'levels':
        mt = re.match(r'^level \d+: byte (\S+) script (\S+) flags (\S+) scroll (\S+) scenery (\d+) speed (\d+)$', t)
        if not mt:
            raise SystemExit('levels:%d: cannot read the level' % number)
        emit(num(mt.group(1)))
        word_ref(mt.group(2), number)
        v = num(mt.group(4))
        emit(num(mt.group(3)), v & 0xFF, v >> 8, int(mt.group(5)), int(mt.group(6)))
        return
    if section == 'scripts':
        wait = int(p[0])
        op = p[1]
        names = dict((v, k) for k, v in SCRIPT_OPS.items())
        args = dict((v[0], (k, v[1])) for k, v in SCRIPT_ARGS.items())
        if op in names:
            emit(wait, names[op])
        elif op in args:
            code, n = args[op]
            emit(wait, code)
            for x in p[2:2 + n]:
                word_ref(x, number)
        elif op == 'op':
            emit(wait, int(p[2]))
        elif op in ('jp', 'call'):
            cond = p[2] if len(p) == 4 else ''
            emit(wait, (0x40 if op == 'jp' else 0xC0) | CONDS.index(cond))
            word_ref(p[-1], number)
        elif op == 'wave':
            emit(wait, 0x80 | int(p[2]), int(p[4]))
        else:
            raise SystemExit('levels:%d: no script command %s' % (number, op))
        return
    if section in ('scenery-scripts', 'groups', 'shapes') and p[0] == 'table':
        for name in p[1:]:
            word_ref(name, number)
        return
    if section == 'scenery-scripts':
        if p[0] == 'group':
            emit(int(p[1]))
        elif p[0] == 'end':
            emit(0xFF)
        elif p[0] == 'call':
            emit(0x80, int(p[1]))
        elif p[0] == 'mask':
            emit(0xE0 | num(p[1]) >> 4)
        elif p[0] == 'pattern':
            emit(0xC0 | int(p[1]))
        else:
            raise SystemExit('levels:%d: no scenery command %s' % (number, p[0]))
        return
    if section == 'groups':
        if p[0] == 'end':
            emit(0xFF)
        elif p[0] == 'sub':
            emit(num(p[1]), int(p[3]))
        elif p[0] == 'put':
            mt = re.match(r'^put shape (\d+) row (\d+) col (\d+) mask (\S+)((?: hflip)?)((?: vflip)?)$', t)
            if not mt:
                raise SystemExit('levels:%d: cannot read the piece' % number)
            b = int(mt.group(2)) | (0x40 if mt.group(5) else 0) | (0x20 if mt.group(6) else 0)
            emit(b, num(mt.group(4)) | int(mt.group(3)), int(mt.group(1)))
        else:
            raise SystemExit('levels:%d: no group command %s' % (number, p[0]))
        return
    if section == 'shapes':
        if p[0] == 'rows':
            emit(int(p[1]))
            return
    raise SystemExit('levels:%d: cannot read: %s' % (number, t))


def to_editable(data, name):
    return decode(data)


def from_editable(data, name):
    return encode(data)


KINDS = [('levels/levels.bin', '.lev.txt', to_editable, from_editable)]


if __name__ == '__main__':
    if sys.argv[1] == 'decode':
        sys.stdout.buffer.write(decode(open(sys.argv[2], 'rb').read()))
    else:
        sys.stdout.buffer.write(encode(open(sys.argv[2], 'rb').read()))

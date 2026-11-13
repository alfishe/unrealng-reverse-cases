#!/usr/bin/env python3
"""The level data as text (tools/res_formats.py merges SINGLES and GROUPS; src/res/levels/README.md):

| Editable | Bytes | Address |
| --- | --- | --- |
| levels/levels.txt | levels/maps.bin, zones.bin, exits.bin, objects.bin | `$AF64`, `$D55C`, `$D64A`, `$D7FC` |
| levels/tiles.txt | levels/tiles.bin | `$C31C` |
| levels/kinds.txt | levels/kinds.bin, anims.bin, scripts.bin | `$D31C`, `$DF1D`, `$DF83` |

levels.txt, zone after zone in memory order (`level N` lines start a level):

    zone L1Z1 set 0                 # +0 the char set; +1-2, +3-4, +5-6 follow from the layout below
    map                             # rows of 8 tile numbers (hex)
      1E 19 1A 1D 28 2F 30 26
    exit left $18 -> end $20        # side, the map char row, the zone entered (or end), the row there
    exit right $38 -> L1Z2 $18
    obj $18 mark22 flags $00 x $08+0 q $08+0    # row, kind, flags, x + row offset, +4 (bits 3-7 + bits 0-2)
    obj $20 pic4 taken ...         # "taken": kind bit 7
    term $74 $65 $72 $6D            # the list's end: $FF and these 4 bytes ("term")

The map, exit and object pointers of a zone are where its block starts in each file: the blocks lie in zone order.
Kind names: picK (kinds 4-21, a graphic address in +2-3), markK (22, 23: no graphic, no script), actorK (24-70,
an animation list and a movement script), kindK (the empty kinds 0-3, 71). The names say what the bytes hold,
not what the player sees.
"""

MAPS, ZONES, EXITS, OBJECTS = 0xAF64, 0xD55C, 0xD64A, 0xD7FC
KINDS, ANIMS, SCRIPTS = 0xD31C, 0xDF1D, 0xDF83
ZONES_PER_LEVEL = (6, 7, 12, 9)       # the level table $E4AE: first zones $D55C, $D586, $D5B7, $D60B
SIDES = ('left', 'right')


def kind_name(k):
    if 4 <= k <= 21:
        return 'pic%d' % k
    if k in (22, 23):
        return 'mark%d' % k
    if 24 <= k <= 70:
        return 'actor%d' % k
    return 'kind%d' % k


def kind_number(name):
    for p in ('pic', 'mark', 'actor', 'kind'):
        if name.startswith(p):
            k = int(name[len(p):])
            if kind_name(k) != name:
                raise ValueError('kind %s: kind %d is %s' % (name, k, kind_name(k)))
            return k
    raise ValueError('not a kind: %s' % name)


def num(t):
    return int(t[1:], 16) if t.startswith('$') else int(t)


def w(b, o):
    return b[o] | b[o + 1] << 8


def zone_ids():
    return ['L%dZ%d' % (lv + 1, z + 1) for lv, n in enumerate(ZONES_PER_LEVEL) for z in range(n)]


# levels.txt -----------------------------------------------------------------------------------------------------

def levels_to_text(files):
    maps, zones, exits, objs = (files['levels/%s.bin' % n] for n in ('maps', 'zones', 'exits', 'objects'))
    ids = zone_ids()
    if len(zones) != 7 * len(ids):
        raise ValueError('zones.bin: %d bytes' % len(zones))
    rec = [zones[7 * i:7 * i + 7] for i in range(len(ids))]
    mp = [w(r, 1) - MAPS for r in rec] + [len(maps)]
    ep = [w(r, 3) - EXITS for r in rec] + [len(exits)]
    op = [w(r, 5) - OBJECTS for r in rec] + [len(objs)]
    for name, p in (('maps', mp), ('exits', ep), ('objects', op)):
        if p[0] != 0 or any(p[i] > p[i + 1] for i in range(len(ids))):
            raise ValueError('%s: the zones\' blocks are not in zone order' % name)
    out = ['# Rick Dangerous: the levels (tools/res_levels.py; src/res/levels/README.md)']
    for i, zid in enumerate(ids):
        if zid.endswith('Z1'):
            out += ['', 'level %s' % zid[1:zid.index('Z')]]
        out += ['', 'zone %s set %d' % (zid, rec[i][0]), 'map']
        m = maps[mp[i]:mp[i + 1]]
        if len(m) % 8:
            raise ValueError('%s: map of %d bytes' % (zid, len(m)))
        out += ['  ' + ' '.join('%02X' % b for b in m[r:r + 8]) for r in range(0, len(m), 8)]
        e = exits[ep[i]:ep[i + 1]]
        while e and e[0] != 0xFF:
            if e[0] > 1:
                raise ValueError('%s: exit side %d' % (zid, e[0]))
            t = w(e, 2)
            to = 'end' if t == 0xFFFF else ids[(t - ZONES) // 7]
            if t != 0xFFFF and (t - ZONES) % 7:
                raise ValueError('%s: exit into $%04X' % (zid, t))
            out.append('exit %s $%02X -> %s $%02X' % (SIDES[e[0]], e[1], to, e[4]))
            e = e[5:]
        if e != b'\xff':
            raise ValueError('%s: exit list tail %s' % (zid, e.hex()))
        o = objs[op[i]:op[i + 1]]
        while len(o) >= 5 and o[0] != 0xFF:
            k = o[1]
            out.append('obj $%02X %s%s flags $%02X x $%02X+%d q $%02X+%d' % (
                o[0], kind_name(k & 0x7F), ' taken' if k & 0x80 else '', o[2], o[3] & 0xF8, o[3] & 7,
                o[4] & 0xF8, o[4] & 7))
            o = o[5:]
        if len(o) != 5 or o[0] != 0xFF:
            raise ValueError('%s: object list tail %s' % (zid, o.hex()))
        out.append('term ' + ' '.join('$%02X' % b for b in o[1:]))
    return ('\n'.join(out) + '\n').encode('ascii')


def levels_from_text(raw):
    ids = zone_ids()
    maps, zones, exits, objs = bytearray(), [], bytearray(), bytearray()
    cur = None
    in_map = False
    pending = []                         # (offset in exits, target id)
    for n, line in enumerate(raw.decode('ascii').splitlines(), 1):
        line = line.split('#', 1)[0].rstrip()
        if not line:
            continue
        f = line.split()
        if line.startswith('  ') and in_map:
            row = bytes(int(x, 16) for x in f)
            if len(row) != 8:
                raise ValueError('line %d: a map row of %d tiles' % (n, len(row)))
            maps += row
            continue
        in_map = False
        if f[0] == 'level':
            continue
        if f[0] == 'zone':
            if f[1] != ids[len(zones)] or f[2] != 'set':
                raise ValueError('line %d: expected zone %s' % (n, ids[len(zones)]))
            cur = [num(f[3]), MAPS + len(maps), EXITS + len(exits), OBJECTS + len(objs)]
            zones.append(cur)
        elif f[0] == 'map':
            in_map = True
        elif f[0] == 'exit':
            if f[3] != '->':
                raise ValueError('line %d: exit SIDE ROW -> ZONE ROW' % n)
            pending.append((len(exits) + 2, f[4]))
            exits += bytes([SIDES.index(f[1]), num(f[2]), 0, 0, num(f[5])])
        elif f[0] == 'obj':
            k, rest = kind_number(f[2]), f[3:]
            if rest[0] == 'taken':
                k |= 0x80
                rest = rest[1:]
            if rest[0] != 'flags' or rest[2] != 'x' or rest[4] != 'q':
                raise ValueError('line %d: obj ROW KIND [taken] flags F x X+D q Q+D' % n)
            xs = [rest[3].split('+'), rest[5].split('+')]
            objs += bytes([num(f[1]), k, num(rest[1]), num(xs[0][0]) | int(xs[0][1]), num(xs[1][0]) | int(xs[1][1])])
        elif f[0] == 'term':
            exits.append(0xFF)
            objs += bytes([0xFF] + [num(x) for x in f[1:5]])
        else:
            raise ValueError('line %d: cannot read: %s' % (n, line))
    for off, to in pending:
        t = 0xFFFF if to == 'end' else ZONES + 7 * ids.index(to)
        exits[off:off + 2] = bytes([t & 0xFF, t >> 8])
    zb = bytearray()
    for s, m, e, o in zones:
        zb += bytes([s, m & 0xFF, m >> 8, e & 0xFF, e >> 8, o & 0xFF, o >> 8])
    return {'levels/maps.bin': bytes(maps), 'levels/zones.bin': bytes(zb), 'levels/exits.bin': bytes(exits),
            'levels/objects.bin': bytes(objs)}


# tiles.txt ------------------------------------------------------------------------------------------------------

def tiles_to_text(data):
    if len(data) != 4096:
        raise ValueError('tiles.bin: %d bytes' % len(data))
    out = ['# Rick Dangerous: 256 tiles of 4 x 4 char codes, the zone\'s char set (tools/res_levels.py)']
    for t in range(256):
        out.append('tile $%02X' % t)
        for r in range(4):
            out.append('  ' + ' '.join('%02X' % b for b in data[16 * t + 4 * r:16 * t + 4 * r + 4]))
    return ('\n'.join(out) + '\n').encode('ascii')


def tiles_from_text(raw):
    out = bytearray()
    for n, line in enumerate(raw.decode('ascii').splitlines(), 1):
        line = line.split('#', 1)[0].rstrip()
        if not line:
            continue
        if line.startswith('tile'):
            if num(line.split()[1]) != len(out) // 16 or len(out) % 16:
                raise ValueError('line %d: tile out of order' % n)
            continue
        row = bytes(int(x, 16) for x in line.split())
        if len(row) != 4:
            raise ValueError('line %d: a tile row of %d codes' % (n, len(row)))
        out += row
    return bytes(out)


# kinds.txt ------------------------------------------------------------------------------------------------------

def walk_lists(data, base, labels, step):
    """the items of a list region: ('label', name), ('item', bytes), ('end',), ('raw', byte)"""
    items, pos = [], 0
    starts = sorted(labels)
    while pos < len(data):
        if base + pos in labels:
            items.append(('label', labels[base + pos]))
        nxt = next((a - base for a in starts if a - base > pos), len(data))
        if data[pos] == 0xFF:
            items.append(('end',))
            pos += 1
        elif pos + step <= nxt:
            items.append(('item', data[pos:pos + step]))
            pos += step
        else:
            items.append(('raw', data[pos]))
            pos += 1
    return items


def kinds_to_text(files):
    kinds, anims, scripts = (files['levels/%s.bin' % n] for n in ('kinds', 'anims', 'scripts'))
    alab, slab = {}, {}
    for k in range(len(kinds) // 8):
        r = kinds[8 * k:8 * k + 8]
        if ANIMS <= w(r, 2) < ANIMS + len(anims):
            alab.setdefault(w(r, 2), 'A%d' % len(alab))
        if SCRIPTS <= w(r, 4) < SCRIPTS + len(scripts):
            slab.setdefault(w(r, 4), 'S%d' % len(slab))
    alab = {a: 'A%d' % i for i, a in enumerate(sorted(alab))}
    slab = {a: 'S%d' % i for i, a in enumerate(sorted(slab))}
    if ANIMS not in alab or SCRIPTS not in slab:
        raise ValueError('kinds: a list region starts with no kind pointing at it')

    def ref(v, lab):
        if v in lab:
            return lab[v]
        return '-' if v == 0 else '$%04X' % v

    out = ['# Rick Dangerous: object kinds, animation lists, movement scripts (tools/res_levels.py)',
           '# kind NAME a A b B gfx|anim G script S c C d D: the 8 bytes +0, +1, +2-3, +4-5, +6, +7', '']
    for k in range(len(kinds) // 8):
        r = kinds[8 * k:8 * k + 8]
        out.append('kind %s a $%02X b $%02X anim %s script %s c $%02X d $%02X' % (
            kind_name(k), r[0], r[1], ref(w(r, 2), alab), ref(w(r, 4), slab), r[6], r[7]))
    out += ['', '# anim NAME: frame bytes (bit 7 to slot +6, bits 0-6 the graphic), then $FF: back to the start']
    for it in walk_lists(anims, ANIMS, alab, 1):
        if it[0] == 'label':
            out.append('anim %s' % it[1])
        elif it[0] == 'item':
            out[-1] += ' %02X' % it[1][0]
        elif it[0] == 'end':
            out[-1] += ' end'
    out += ['', '# script NAME: steps FRAMES,DX,DY (signed), then end ($FF); raw XX: a byte outside the steps']

    def s8(b):
        return b - 256 if b > 127 else b
    for it in walk_lists(scripts, SCRIPTS, slab, 3):
        if it[0] == 'label':
            out.append('script %s' % it[1])
        elif it[0] == 'item':
            out[-1] += ' %d,%d,%d' % (it[1][0], s8(it[1][1]), s8(it[1][2]))
        elif it[0] == 'end':
            out[-1] += ' end'
        else:
            out[-1] += ' raw%02X' % it[1]
    return ('\n'.join(out) + '\n').encode('ascii')


def kinds_from_text(raw):
    kinds, anims, scripts = [], bytearray(), bytearray()
    alab, slab = {}, {}
    for n, line in enumerate(raw.decode('ascii').splitlines(), 1):
        line = line.split('#', 1)[0].rstrip()
        if not line:
            continue
        f = line.split()
        if f[0] == 'kind':
            if kind_number(f[1]) != len(kinds):
                raise ValueError('line %d: kind out of order' % n)
            kinds.append(f)
        elif f[0] == 'anim':
            alab[f[1]] = ANIMS + len(anims)
            for t in f[2:]:
                anims.append(0xFF if t == 'end' else int(t, 16))
        elif f[0] == 'script':
            slab[f[1]] = SCRIPTS + len(scripts)
            for t in f[2:]:
                if t == 'end':
                    scripts.append(0xFF)
                elif t.startswith('raw'):
                    scripts.append(int(t[3:], 16))
                else:
                    scripts += bytes(int(x) & 0xFF for x in t.split(','))
        else:
            raise ValueError('line %d: cannot read: %s' % (n, line))

    def val(t, lab):
        return 0 if t == '-' else lab[t] if t in lab else num(t)
    kb = bytearray()
    for f in kinds:
        d = dict(zip(f[2::2], f[3::2]))
        a, s = val(d['anim'], alab), val(d['script'], slab)
        kb += bytes([num(d['a']), num(d['b']), a & 0xFF, a >> 8, s & 0xFF, s >> 8, num(d['c']), num(d['d'])])
    return {'levels/kinds.bin': bytes(kb), 'levels/anims.bin': bytes(anims), 'levels/scripts.bin': bytes(scripts)}


SINGLES = {'levels/tiles.bin': ('.txt', tiles_to_text, tiles_from_text)}
GROUPS = {
    'levels/levels.txt': (['levels/maps.bin', 'levels/zones.bin', 'levels/exits.bin', 'levels/objects.bin'],
                          levels_to_text, levels_from_text),
    'levels/kinds.txt': (['levels/kinds.bin', 'levels/anims.bin', 'levels/scripts.bin'],
                         kinds_to_text, kinds_from_text),
}

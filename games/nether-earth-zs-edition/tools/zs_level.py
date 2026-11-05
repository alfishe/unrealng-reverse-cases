#!/usr/bin/env python3
"""Nether Earth ZS Edition levels as text: the 12 NELEV_xx.N map files of the '99 disk and the built-in level of the
'99 game block, with a radar-like PNG preview of each (src/res/maps/README.md).

A level is BuildMap's four lists (PlaceScenery `$BCD6`, PlaceBases `$BCF9`), laid one after the other from `$BDA9`
(the game block's own level sits there; LOAD MAP copies a file's first `$1F3` bytes over it). A NELEV file is 512
bytes: the lists from offset 0, zeros up to `$1F2`, then 13 tail bytes LOAD MAP writes into the game's operands:

| Offset | Size | Written to | Field (text) |
| --- | --- | --- | --- |
| `$1F3` | 1 | `$ADB4`, `$BB1F` | `points`: the capture points the turn and CountBases walk (the bases, 28 at most) |
| `$1F4` | 2 | `$BC8A` | the address of SceneryWest (always `$BDA9`) |
| `$1F6` | 2 | `$BC92` | the address of SceneryEast |
| `$1F8` | 2 | `$BCA2` | the address of BaseListWest |
| `$1FA` | 2 | `$BCAA` | the address of BaseListEast |
| `$1FC` | 2 | `$BC9B` | `factories`: the first factory's record, `$FD70` + 5 x the warbases |
| `$1FE` | 1 | `$BCB7`; + 1 to `$B3E6`, `$B817` | `enemy`: the enemy's warbases (all warbases but the first) |
| `$1FF` | 1 | `$A684` | `general`: the player's general resource at the start |

The text holds the four sections of the NE level text (src/res/README.md of Nether Earth, "Level text"):
`scenery SceneryWest`, `scenery SceneryEast`, `bases BaseListWest`, `bases BaseListEast`, then for a NELEV file a
`tail` section. Scenery: `block TILE x y` | `shape N x y` | `end`; bases: `warbase x y` | `factory T x y` | `end`.
A column x is 0-511 (the West lists 0-255, the East lists 256-511). Tail: `points N|auto`, `lists auto|$W $E $BW
$BE`, `factories auto|$xxxx`, `enemy auto|N`, `general N`; `auto` is the value the lists give (the bases counted,
the lists' addresses, `$FD70` + 5 x warbases, warbases - 1), which every file of the disk holds.

    python3 tools/zs_level.py build [--out build/maps]       # src/res/maps/NELEV_xx.txt -> NELEV_xx.N (+ builtin.bin)
    python3 tools/zs_level.py export --from DIR              # DIR/NELEV_xx.N (and builtin.bin) -> src/res/maps text
    python3 tools/zs_level.py preview                        # src/res/maps/png/*.png from the texts
    python3 tools/zs_level.py check                          # every text: built, written back, the same text

Other parts import it: `zs_level.parse(text, name) -> bytes`, `zs_level.render(data, title) -> text` (512 bytes
with the tail, or the `$1F3` bytes of the lists alone: no tail section), `zs_level.lists(data)`,
`zs_level.preview(data, shapes) -> PIL image`. The '98 game's built-in level has the same four lists at `$BDA9`.
"""
import argparse
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS = os.path.join(ROOT, 'src', 'res', 'maps')
ORG = 0xBDA9            # where the lists sit in the game (and where LOAD MAP copies a file's lists)
AREA = 0x1F3            # the lists' room: the built-in level's bytes, a file's bytes before the tail
FILE = 0x200            # a NELEV file: two sectors
RECORDS = 0xFD70        # the capture points' records, 5 bytes each, warbases first
SECTIONS = [('scenery', 'SceneryWest', 0), ('scenery', 'SceneryEast', 1), ('bases', 'BaseListWest', 0),
            ('bases', 'BaseListEast', 1)]
RESOURCE_NAMES = {1: 'electronics', 2: 'nuclear', 3: 'phasers', 4: 'missiles', 5: 'cannon', 6: 'chassis'}
SHAPE_NAMES = ['ShapeWarbase', 'ShapeFactory', 'ShapeLowTiles', 'ShapeMidTiles', 'ShapeTallWallV', 'ShapeTallWallH',
               'ShapeEdgeFence', 'ShapeFlatLineV', 'ShapeFlatLineH', 'ShapeLowWallH', 'ShapeMixedWallH']
BUILTIN = 'builtin'     # src/res/maps/builtin.txt: the game block's level, built to maps/builtin.bin


def fail(msg):
    raise SystemExit(msg)


def number(word, where):
    try:
        return int(word[1:], 16) if word.startswith('$') else int(word)
    except ValueError:
        fail(f'{where}: {word!r} is no number')


def lists(data):
    """the four lists of a level: [(kind, label, high, [(type, x, y), ...], offset)], and the bytes they use"""
    out, p = [], 0
    for kind, label, high in SECTIONS:
        end, recs, start = (0 if kind == 'scenery' else 0xFF), [], p
        while True:
            if p >= AREA:
                fail(f'{label}: no end byte inside the first ${AREA:X} bytes')
            if data[p] == end:
                p += 1
                break
            recs.append((data[p], data[p + 1] | high << 8, data[p + 2]))
            p += 3
        out.append((kind, label, high, recs, start))
    return out, p


def derived(data):
    """the tail the lists give: (points, [the four lists' addresses], first factory record, enemy warbases)"""
    ls, _ = lists(data)
    bases = [r for kind, _, _, recs, _ in ls if kind == 'bases' for r in recs]
    warbases = sum(1 for t, _, _ in bases if t == 0)
    return len(bases), [ORG + off for *_, off in ls], RECORDS + 5 * warbases, warbases - 1


def render(data, title=''):
    """a level as text: 512 bytes of a NELEV file (with the tail) or the AREA bytes of the lists"""
    if len(data) not in (AREA, FILE):
        fail(f'a level is {AREA} or {FILE} bytes, not {len(data)}')
    ls, used = lists(data)
    if any(data[used:AREA]):
        fail(f'the bytes after the lists (from ${used:03X}) are not all zero')
    out = [f'; {title}' if title else '; a Nether Earth ZS Edition level',
           '; tools/zs_level.py (format: its doc string, src/res/maps/README.md). Lists from $%04X, %d of the %d bytes'
           % (ORG, used, AREA) + ' of the lists\' room used, the rest zero.', '']
    for kind, label, high, recs, _ in ls:
        out.append(f'{kind} {label}')
        for t, x, y in recs:
            if kind == 'scenery':
                if t & 0x80:
                    n = t & 0x7F
                    out.append('  shape %-3d %3d %2d     ; %s' % (n, x, y, SHAPE_NAMES[n] if n < 11 else '?'))
                else:
                    out.append('  block $%02X %3d %2d' % (t, x, y))
            elif t == 0:
                out.append('  warbase   %3d %2d' % (x, y))
            else:
                out.append('  factory %d %3d %2d     ; %s' % (t, x, y, RESOURCE_NAMES.get(t, '?')))
        out.append('  end')
        out.append('')
    if len(data) == FILE:
        points, addrs, first, enemy = derived(data)
        t = data[AREA:]
        f_addrs = [t[1 + 2 * i] | t[2 + 2 * i] << 8 for i in range(4)]
        f_first = t[9] | t[10] << 8
        out.append('tail')
        out.append('  points %s' % ('auto' if t[0] == points else t[0]) + '        ; capture points: %d' % t[0])
        out.append('  lists %s' % ('auto' if f_addrs == addrs else ' '.join('$%04X' % a for a in f_addrs)) +
                   '        ; ' + ' '.join('$%04X' % a for a in f_addrs))
        out.append('  factories %s' % ('auto' if f_first == first else '$%04X' % f_first) +
                   '    ; the first factory record $%04X' % f_first)
        out.append('  enemy %s' % ('auto' if t[11] == enemy else t[11]) +
                   '        ; enemy warbases: %d of %d' % (t[11], enemy + 1))
        out.append('  general %d' % t[12])
        out.append('')
    return '\n'.join(out)


def parse(text, name='level'):
    """text -> bytes: FILE bytes when it has a tail section, else the AREA bytes of the lists"""
    sections, cur = [], None
    for no, raw in enumerate(text.splitlines(), 1):
        line = raw.split(';')[0].strip()
        if not line:
            continue
        words, where = line.split(), f'{name}:{no}'
        if not raw[0].isspace():
            cur = (words, where, [])
            sections.append(cur)
        elif cur is None:
            fail(f'{where}: a command before the first section')
        else:
            cur[2].append((words, where))
    heads = [tuple(w) for w, _, _ in sections]
    want = [(k, lb) for k, lb, _ in SECTIONS]
    if heads not in (want, want + [('tail',)]):
        fail(f'{name}: the sections must be ' + ', '.join(f'{k} {lb}' for k, lb in want) + ' [, tail]')
    data = bytearray()
    for (kind, label, high), (_, _, cmds) in zip(SECTIONS, sections):
        ended = False
        for words, where in cmds:
            op, rest = words[0], words[1:]
            if ended:
                fail(f'{where}: after end')

            def column(w):
                x = number(w, where)
                if not high * 256 <= x < high * 256 + 256:
                    fail(f'{where}: column {x} is not in {label} ({high * 256}-{high * 256 + 255})')
                return x & 0xFF

            def row(w):
                y = number(w, where)
                if not 0 <= y < 256:
                    fail(f'{where}: row {y}')
                return y
            if op == 'end' and not rest:
                data.append(0 if kind == 'scenery' else 0xFF)
                ended = True
            elif kind == 'scenery' and op == 'block' and len(rest) == 3:
                t = number(rest[0], where)
                if not 1 <= t < 0x80:
                    fail(f'{where}: a block tile is $01-$7F')
                data += bytes((t, column(rest[1]), row(rest[2])))
            elif kind == 'scenery' and op == 'shape' and len(rest) == 3:
                n = number(rest[0], where)
                if not 0 <= n < 0x80:
                    fail(f'{where}: a shape is 0-127')
                data += bytes((0x80 | n, column(rest[1]), row(rest[2])))
            elif kind == 'bases' and op == 'warbase' and len(rest) == 2:
                data += bytes((0, column(rest[0]), row(rest[1])))
            elif kind == 'bases' and op == 'factory' and len(rest) == 3:
                t = number(rest[0], where)
                if t not in RESOURCE_NAMES:
                    fail(f'{where}: a factory type is 1-6')
                data += bytes((t, column(rest[1]), row(rest[2])))
            else:
                fail(f'{where}: cannot read {" ".join(words)!r} in a {kind} section')
        if not ended:
            fail(f'{name}: {label} has no end')
    if len(data) > AREA:
        fail(f'{name}: the lists take {len(data)} bytes, the room is {AREA}')
    data += bytes(AREA - len(data))
    if len(sections) == 4:
        return bytes(data)
    points, addrs, first, enemy = derived(data)
    fields = {}
    for words, where in sections[4][2]:
        if words[0] in fields or words[0] not in ('points', 'lists', 'factories', 'enemy', 'general'):
            fail(f'{where}: {words[0]!r} unknown or twice')
        fields[words[0]] = (words[1:], where)
    if set(fields) != {'points', 'lists', 'factories', 'enemy', 'general'}:
        fail(f'{name}: the tail needs points, lists, factories, enemy, general')

    def value(key, auto, bits):
        words, where = fields[key]
        if words == ['auto']:
            return auto
        vals = [number(w, where) for w in words]
        if len(vals) != (len(auto) if isinstance(auto, list) else 1) or any(not 0 <= v < 1 << bits for v in vals):
            fail(f'{where}: {key} {" ".join(words)}')
        return vals if isinstance(auto, list) else vals[0]
    p = value('points', points, 8)
    if p > 28:
        fail(f'{name}: {p} capture points, the records hold 28')
    tail = bytearray((p,))
    for a in value('lists', addrs, 16):
        tail += bytes((a & 0xFF, a >> 8))
    f = value('factories', first, 16)
    tail += bytes((f & 0xFF, f >> 8, value('enemy', enemy, 8), value('general', None, 8)))
    return bytes(data + tail)


# ---------------------------------------------------------------------------------------------------- the preview

COLOURS = {'ground': (0, 0, 160), 'low': (0, 150, 200), 'high': (120, 220, 255), 'post': (255, 255, 255),
           'flat': (0, 90, 180), 'player': (0, 230, 0), 'enemy': (240, 220, 0), 'factory': (230, 90, 230)}


def shape_steps(shapes, n):
    """the (tile, dx, dy) steps of shape n of the game's ShapeTable (shapes: {address: byte} of the image)"""
    base, steps = shapes[0xBF9C + 2 * n] | shapes[0xBF9D + 2 * n] << 8, []
    while True:
        t, dx, dy = shapes[base], shapes[base + 1], shapes[base + 2]
        dx, dy = dx - 256 if dx > 127 else dx, dy - 256 if dy > 127 else dy
        steps.append((t, dx, dy))
        base += 3
        if dx == 0 and dy == 0:
            return steps


def cells(data, shapes):
    """{(x, y): kind} of the map BuildMap makes from the lists (blocks 2 x 2, from their bottom left cell)"""
    grid = {}

    def tile_kind(t):
        if t == 0x15:
            return 'post'
        if t in (0x10, 0x12):
            return 'high'
        if 0x0C <= t <= 0x0E:
            return 'flat'
        return 'low'

    def block(t, x, y, kind=None):
        for dy in (0, 1):
            for dx in (0, 1):
                if 0 <= x + dx < 512 and 0 <= y + dy < 16:
                    grid[x + dx, y + dy] = kind or tile_kind(t)

    def shape(n, x, y, kind=None):
        for t, dx, dy in shape_steps(shapes, n):
            if t:
                block(t, x, y, kind)
            x, y = x + dx, y + dy
    ls, _ = lists(data)
    warbase = 0
    for kind, _, _, recs, _ in ls:
        for t, x, y in recs:
            if kind == 'scenery':
                shape(t & 0x7F, x, y) if t & 0x80 else block(t, x, y)
            elif t == 0:
                shape(0, x, y, 'player' if warbase == 0 else 'enemy')
                warbase += 1
            else:
                shape(1, x, y, 'factory')
    return grid


def preview(data, shapes, scale=3):
    """a radar-like picture of the whole map (512 x 16 cells, 4 strips of 128 columns, the radar's width)"""
    from PIL import Image
    grid = cells(data, shapes)
    img = Image.new('RGB', (128 * scale, (16 * 4 + 3) * scale), (0, 0, 0))
    px = img.load()
    for strip in range(4):
        for cx in range(128):
            for cy in range(16):
                colour = COLOURS[grid.get((strip * 128 + cx, cy), 'ground')]
                top = (strip * 17 + cy) * scale
                for i in range(scale):
                    for j in range(scale):
                        px[cx * scale + i, top + j] = colour
    return img


def game_shapes():
    """{address: byte} of the game's shape table and shapes ($BF9C-$C08C), from the game block"""
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import game99_image
    game, _ = game99_image.blocks()
    return {a: game[a - game99_image.GAME_LO] for a in range(0xBF9C, 0xC08D)}


# ------------------------------------------------------------------------------------------------- files

def names(folder=MAPS):
    return sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(folder, '*.txt')))


def build(out, folder=MAPS):
    """every src/res/maps text into out: NELEV_xx.N (512 bytes) and builtin.bin (the lists' room)"""
    os.makedirs(out, exist_ok=True)
    built = {}
    for n in names(folder):
        data = parse(open(os.path.join(folder, n + '.txt'), encoding='utf-8').read(), n + '.txt')
        file = n + ('.bin' if n == BUILTIN else '.N')
        open(os.path.join(out, file), 'wb').write(data)
        built[file] = data
    return built


TITLES = {BUILTIN: "The '99 game block's own level at $BDA9-$BF9B (BuildMap's lists before any LOAD MAP)"}


def export_one(name, data, folder=MAPS):
    title = TITLES.get(name, f'{name}.N, a LOAD MAP file of the \'99 disk (512 bytes)')
    os.makedirs(folder, exist_ok=True)
    open(os.path.join(folder, name + '.txt'), 'w', encoding='utf-8').write(render(data, title))


def install(name, data):
    """game99_mkgame.py: a maps/ resource of the game block (maps/builtin.bin) as its text"""
    base = os.path.basename(name)
    if base != BUILTIN + '.bin':
        fail(f'zs_level.install: no text format for {name}')
    export_one(BUILTIN, data)


def write_previews(folder=MAPS):
    shapes = game_shapes()
    os.makedirs(os.path.join(folder, 'png'), exist_ok=True)
    for n in names(folder):
        data = parse(open(os.path.join(folder, n + '.txt'), encoding='utf-8').read(), n)
        preview(data[:AREA], shapes).save(os.path.join(folder, 'png', n + '.png'))
    return names(folder)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--maps', default=MAPS)
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', default=os.path.join(ROOT, 'build', 'maps'))
    e = sub.add_parser('export')
    e.add_argument('--from', dest='src', required=True)
    sub.add_parser('preview')
    sub.add_parser('check')
    a = p.parse_args()
    if a.cmd == 'build':
        print(f'maps: {len(build(a.out, a.maps))} files into {a.out}')
    elif a.cmd == 'export':
        for path in sorted(glob.glob(os.path.join(a.src, 'NELEV_*.N')) + glob.glob(os.path.join(a.src, '*.bin'))):
            name = os.path.basename(path).rsplit('.', 1)[0]
            export_one(name, open(path, 'rb').read(), a.maps)
            print('exported', name)
    elif a.cmd == 'preview':
        print('previews:', ', '.join(write_previews(a.maps)))
    else:
        bad = 0
        for n in names(a.maps):
            text = open(os.path.join(a.maps, n + '.txt'), encoding='utf-8').read()
            data = parse(text, n)
            again = render(data, text.splitlines()[0][2:])
            ok = parse(again, n) == data
            bad += not ok
            print(f'{n}: {"round trip exact" if ok else "ROUND TRIP DIFFERS"}' +
                  ('' if again == text else ' (the text differs from the exported one)'))
        sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()

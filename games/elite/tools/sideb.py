#!/usr/bin/env python3
"""Side B of the Firebird tape ("With Adder ship") as source: what differs from Side A (docs/03-build-and-load.md 3.12).

    python3 tools/sideb.py export      # src/sideb/ from the original Side B (tools/image.py --side B), once
    python3 tools/sideb.py res OUTDIR  # src/sideb/ships-b.txt -> OUTDIR/res/ships-b.bin (tools/build.sh calls it)

Side B's game image differs from Side A's in three places and nowhere else (3600 bytes):

- the blueprint table and the blueprints, `$6180-$6FF1`: blueprint 17 is an Adder (18 vertices, 29 edges, 15 faces)
  where Side A has the Krait, stored first at `$61CC`; every other blueprint is Side A's, byte for byte, moved up;
- slot 0's blueprint word at `$606B` (the station the title leaves there), which follows the Coriolis to its place;
- the mastering machine's system variables at `$5C02-$5D61` (another RAMTOP, FRAMES, a stack).

On the tape the filler chunks of TZX blocks 7 and 9 are all zeros: Side B has no plain loader; the chunk of blocks
28+29 carries a third copy of `$5C00-$6047` (src/sideb/master-memory-b.bin, 145 bytes unlike Side A's
src/res/tape/master-memory.bin; the last ROM block overwrites it), and six pauses and two pilot lengths differ. The code, the text,
the tables, the Lenslok and the loader are Side A's. src/sideb/sideb.asm therefore assembles Side B as Side A's
game.bin with these parts laid over it, the blueprints from src/sideb/ships-b.txt (the format of
src/res/ships/ships.txt), and src/sideb/elite-tzx-b.txt lists the blocks.
"""
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import res_formats as R  # noqa: E402

CASE = os.path.dirname(HERE)
SRC = os.path.join(CASE, 'src', 'sideb')
TABLE, SPARE_END = 0x6180, 0x6FF2          # the table, and the end of the blueprints' area (Side A's spare zeros)
NAMES_A = ['Coriolis', 'Missile', 'EscapePod', 'Plate', 'Canister', 'Splinter', 'Asteroid', 'RockHermit', 'Viper',
           'CobraTrader', 'PythonTrader', 'PythonPirate', 'CobraPirate', 'Asp', 'FerDeLance', 'Thargoid',
           'Sidewinder', 'Krait', 'Thargon']
SHAPE = {'CobraTrader': 'Cobra', 'CobraPirate': 'Cobra', 'PythonTrader': 'Python', 'PythonPirate': 'Python'}


def image_b():
    import image
    return image.build('B')


def parts(img, names):
    """(address, label, kind, blueprint number) of every header and shape part, in memory order"""
    seen, out = {}, []
    for n, name in enumerate(names):
        h = img[TABLE + 4 * n + 1] | img[TABLE + 4 * n + 2] << 8
        out.append((h, 'Ship' + name, 'Header', n))
        shape = SHAPE.get(name, name)
        for k, kind in ((0x0C, 'Vertices'), (0x0E, 'Edges'), (0x10, 'Faces')):
            a = h + (img[h + k] | img[h + k + 1] << 8)
            count = img[h + 3 + (k - 0x0C) // 2]
            if count == 0 or a in seen:
                continue
            seen[a] = True
            out.append((a, 'Ship' + shape + kind, kind, n))
    return sorted(out)


def export():
    img = image_b()
    names = list(NAMES_A)
    names[17] = 'Adder'
    ps = parts(img, names)
    # the Rock Hermit shares the asteroid's shape: label its parts after the asteroid, as Side A does
    ps = [(a, re.sub('ShipRockHermit(Vertices|Edges|Faces)', r'ShipAsteroid\1', lbl), k, n) for a, lbl, k, n in ps]
    base = ps[0][0]
    end = max(a for a, *_ in ps)
    # the last part's length: its count times the record size
    a, lbl, kind, n = ps[-1]
    h = img[TABLE + 4 * n + 1] | img[TABLE + 4 * n + 2] << 8
    size = {'Vertices': 6, 'Edges': 4, 'Faces': 4}[kind]
    count = img[h + {'Vertices': 3, 'Edges': 4, 'Faces': 5}[kind]]
    end = a + size * count
    data = img[base:end]
    lines = ['# Side B\'s ship blueprints, $%04X-$%04X, in memory order (tools/sideb.py; the format of' % (base, end - 1),
             '# src/res/ships/ships.txt). Blueprint 17 is the Adder; the rest are Side A\'s, moved.']
    for k, (a, lbl, kind, n) in enumerate(ps):
        nxt = ps[k + 1][0] if k + 1 < len(ps) else end
        part = data[a - base:nxt - base]
        lines.append('[%s %s]' % (lbl, kind.lower()))
        lines += part_lines(part, kind)
    os.makedirs(SRC, exist_ok=True)
    txt = '\n'.join(lines) + '\n'
    if R.ships_build(txt.encode()) != data:
        sys.exit('sideb: ships-b.txt does not round-trip')
    open(os.path.join(SRC, 'ships-b.txt'), 'w').write(txt)
    open(os.path.join(SRC, 'sideb.asm'), 'w').write(asm(img, names, ps, base, end))
    open(os.path.join(SRC, 'master-memory-b.bin'), 'wb').write(chunk_memory())
    print(f'sideb: {len(ps)} parts, ${base:04X}-${end - 1:04X}, spare {SPARE_END - end} bytes')


def chunk_memory():
    """$5C00-$6047 as the chunk of TZX blocks 28+29 carries it on Side B (plain: the decryptor starts at $6049)"""
    import tzxblocks as T
    import zipfile
    tzx = zipfile.ZipFile(os.path.join(CASE, 'orig', 'Elite.tzx.zip')).read('Elite - 48k - Side B.tzx')
    data = [x for x in T.parse(tzx) if x['index'] == 29][0]['data']
    rev = bytes(int(f'{v:08b}'[::-1], 2) for v in data[:0x448])
    return rev


def part_lines(part, kind):
    out = []
    if kind == 'Header':
        return [' '.join('%02X' % b for b in part)]
    size = 6 if kind == 'Vertices' else 4
    for i in range(0, len(part), size):
        r = part[i:i + size]
        if len(r) < size:
            out.append('bytes ' + ' '.join('%02X' % b for b in r))
        elif kind == 'Vertices':
            signs = ''.join('-' if r[3] >> (7 - j) & 1 else '+' for j in range(3))
            out.append('%3d %3d %3d %s %2d  %2d %2d %2d %2d' % (r[0], r[1], r[2], signs, r[3] & 31,
                                                              r[4] & 15, r[4] >> 4, r[5] & 15, r[5] >> 4))
        elif kind == 'Edges':
            out.append('%3d  %2d %2d  %2d %2d' % (r[0], r[1], r[2], r[3] & 15, r[3] >> 4))
        else:
            signs = ''.join('-' if r[3] >> (7 - j) & 1 else '+' for j in range(3))
            out.append('%s %2d  %3d %3d %3d' % (signs, r[3] & 31, r[0], r[1], r[2]))
    return out


def asm(img, names, ps, base, end):
    import image
    a = image.build('A')
    out = ['; Elite, Firebird / Torus 1985, Side B ("With Adder ship"): Side A\'s game image (game.bin, built from',
           '; src/game) with the three parts that differ laid over it (tools/sideb.py, docs/03-build-and-load.md',
           '; 3.12). Assembled by tools/build.sh into build/sideb/game.bin.',
           '  DEVICE ZXSPECTRUM48',
           '  ORG $5B00',
           '  INCBIN "game.bin"',
           '',
           '; 1. The mastering machine\'s system variables and stack (Side B\'s run: RAMTOP $6047, another FRAMES)']
    i = 0x5B00
    while i < 0x6048:
        if img[i] == a[i]:
            i += 1
            continue
        j = i
        while j < 0x6048 and (img[j] != a[j] or any(img[k] != a[k] for k in range(j + 1, min(j + 4, 0x6048)))):
            j += 1
        out.append('  ORG $%04X' % i)
        for k in range(i, j, 16):
            out.append('  DEFB ' + ','.join('$%02X' % b for b in img[k:min(k + 16, j)]))
        i = j
    out += ['',
            '; 2. Slot 0\'s blueprint word: the Coriolis, where Side B keeps it',
            '  ORG $606B',
            '  DEFW ShipCoriolis',
            '',
            '; 3. The blueprint table (19 entries: $C3, the blueprint, the class) and the blueprints',
            '  ORG $%04X' % TABLE,
            'Blueprints:']
    for n, name in enumerate(names):
        out.append('  DEFB $C3 : DEFW Ship%s : DEFB %d  ; %d %s' % (name, img[TABLE + 4 * n + 3], n, name))
    gap = ps[0][0] - (TABLE + 4 * 19)
    if gap:
        out.append('  DEFB ' + ','.join('$%02X' % b for b in img[TABLE + 76:ps[0][0]]))
    for k, (addr, lbl, kind, n) in enumerate(ps):
        nxt = ps[k + 1][0] if k + 1 < len(ps) else end
        out.append('%s:' % lbl)
        out.append('  INCBIN "res/ships-b.bin",$%04X,%d' % (addr - base, nxt - addr))
    out += ['BlueprintsSpare:', '  DEFS $%04X-$' % SPARE_END, '',
            '  SAVEBIN "game.bin",$5B00,$FFA8-$5B00', '']
    return '\n'.join(out)


def res(outdir):
    txt = open(os.path.join(SRC, 'ships-b.txt'), 'rb').read()
    os.makedirs(os.path.join(outdir, 'res', 'tape'), exist_ok=True)
    open(os.path.join(outdir, 'res', 'ships-b.bin'), 'wb').write(R.ships_build(txt))
    shutil.copy(os.path.join(SRC, 'master-memory-b.bin'), os.path.join(outdir, 'res', 'tape', 'master-memory.bin'))


if __name__ == '__main__':
    if sys.argv[1:2] == ['export']:
        export()
    elif sys.argv[1:2] == ['res']:
        res(sys.argv[2])
    else:
        sys.exit(__doc__)

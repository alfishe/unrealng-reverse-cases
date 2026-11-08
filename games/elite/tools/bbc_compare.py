#!/usr/bin/env python3
"""Elite on the Spectrum against BBC Elite's source, table by table (docs/bbc-comparison.md).

    python3 tools/bbc_compare.py BBC_DIR [--ships] [--market] [--equipment] [--galaxy] [--all]

BBC_DIR holds Mark Moxon's annotated sources, fetched once (they are not part of the case):

    BBC_DIR/elite-source.asm   github.com/markmoxon/elite-source-code-bbc-micro-cassette
                               1-source-files/main-sources/elite-source.asm (commit 6ba1c7f6)
    BBC_DIR/disc/*.asm         github.com/markmoxon/elite-source-code-bbc-micro-disc
                               1-source-files/main-sources/elite-ships-[a-p].asm, elite-missile.asm (commit 379deffe)

The Spectrum side is read from the case: the blueprints from src/res/ships/ships.txt, the tables from the game's
image (src/game, through elitelib's memory of the built game, work/d1/start.bin when present).

--ships compares each of the 19 blueprints with the BBC ship of the same shape: the vertices (as signed x, y, z with
their visibility and faces), the edges (vertex pairs with faces) and the face normals, then the header values the
two formats share (energy, speed, bounty, laser, missiles, the visibility distance, the canisters, the kill score).
--market compares the 17 goods (base price, economy factor, base quantity, mask, units), --equipment the
equipment prices, --galaxy the galaxy seeds and the twist on all 8 x 256 systems.
"""
import argparse
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The Spectrum blueprint -> the BBC ship of the same shape (the disc version has all of them)
SHAPES = {'Asp': 'ASP_MK_2', 'Asteroid': 'ASTEROID', 'RockHermit': 'ASTEROID', 'Canister': 'CANISTER',
          'CobraTrader': 'COBRA_MK_3', 'CobraPirate': 'COBRA_MK_3_P', 'EscapePod': 'ESCAPE_POD',
          'FerDeLance': 'FER_DE_LANCE', 'Missile': 'MISSILE', 'Plate': 'PLATE', 'PythonTrader': 'PYTHON',
          'PythonPirate': 'PYTHON_P', 'Sidewinder': 'SIDEWINDER', 'Coriolis': 'CORIOLIS', 'Splinter': 'SPLINTER',
          'Thargoid': 'THARGOID', 'Krait': 'KRAIT', 'Viper': 'VIPER', 'Thargon': 'THARGON'}
SHARED = {'CobraTrader': 'Cobra', 'CobraPirate': 'Cobra', 'PythonTrader': 'Python', 'PythonPirate': 'Python',
          'RockHermit': 'Asteroid'}


# --- the Spectrum side

def spectrum_ships():
    parts, cur = {}, None
    for line in open(os.path.join(CASE, 'src', 'res', 'ships', 'ships.txt')):
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        m = re.match(r'\[Ship(\w+?)(Vertices|Edges|Faces)? (\w+)\]', line)
        if m:
            cur = parts.setdefault(m.group(1), {})
            cur['_kind'] = m.group(3)
            cur[m.group(3)] = []
            continue
        cur[cur['_kind']].append(line.split())
    ships = {}
    for name, p in parts.items():
        if 'header' not in p:
            continue
        shape = parts[SHARED.get(name, name)]
        h = [int(x, 16) for x in p['header'][0]]
        verts = []
        for r in shape.get('vertices', []):
            x, y, z = (int(v) for v in r[0:3])
            s = r[3]
            verts.append(((-x if s[0] == '-' else x), (-y if s[1] == '-' else y), (-z if s[2] == '-' else z),
                          int(r[4]), tuple(sorted(set(int(f) for f in r[5:9])))))
        edges = [(int(r[0]), tuple(sorted((int(r[1]), int(r[2])))), tuple(sorted((int(r[3]), int(r[4])))))
                 for r in shape.get('edges', [])]
        faces = []
        for r in shape.get('faces', []):
            s, vis = r[0], int(r[1])
            x, y, z = (int(v) for v in r[2:5])
            faces.append(((-x if s[0] == '-' else x), (-y if s[1] == '-' else y), (-z if s[2] == '-' else z), vis))
        ships[name] = {'header': h, 'vertices': verts, 'edges': edges, 'faces': faces}
    return ships


# --- the BBC side

DISC_VARIANTS = {'_IB_DISC': 1, '_STH_DISC': 2, '_SRAM_DISC': 3}


def variant_lines(path, variant):
    """the file's lines as the disc variant assembles them: the column-0 IF / ELIF / ELSE / ENDIF on the _*_DISC
    flags (elite-missile.asm's faces 7-8 and VEC) are resolved; the indented IFs inside macros stay"""
    stack = []                                    # per level: (taking now, taken already)
    for line in open(path, encoding='latin-1'):
        m = re.match(r'^(IF|ELIF|ELSE|ENDIF)\b(.*)$', line.rstrip())
        if m and (m.group(1) in ('ELSE', 'ENDIF') or '_DISC' in m.group(2)):
            word, cond = m.group(1), m.group(2)
            truth = any(DISC_VARIANTS.get(f) == variant for f in re.findall(r'_[A-Z]+_DISC', cond))
            if word == 'IF':
                stack.append((truth, truth))
            elif word == 'ELIF':
                done = stack[-1][1]
                stack[-1] = (truth and not done, done or truth)
            elif word == 'ELSE':
                stack[-1] = (not stack[-1][1], True)
            else:
                stack.pop()
            continue
        if all(t for t, _d in stack):
            yield line


def bbc_ships(bbc, variant=2):
    """the disc's blueprints as variant assembles them (1 Ian Bell's, 2 Stairway to Hell's, the default build,
    3 the sideways RAM one)"""
    files = sorted(glob.glob(os.path.join(bbc, 'disc', '*.asm')))
    ships = {}
    for path in files:
        name, fresh = None, False
        for line in variant_lines(path, variant):
            m = re.match(r'^\.SHIP_([A-Z0-9_]+?)(_VERTICES|_EDGES|_FACES)?\s*$', line)
            if m:
                name = m.group(1)
                if not m.group(2):
                    fresh = name not in ships
                if not fresh:
                    name = None                   # the same ship again in another file
                    continue
                ships.setdefault(name, {'fields': {}, 'vertices': [], 'edges': [], 'faces': []})
                continue
            if name is None:
                continue
            s = ships[name]
            code = line.split('\\')[0].strip()
            m = re.match(r'(VERTEX|EDGE|FACE)\s+(.*)', code)
            if m:
                v = [int(x) for x in m.group(2).replace(' ', '').split(',')]
                if m.group(1) == 'VERTEX':
                    s['vertices'].append((v[0], v[1], v[2], v[7], tuple(sorted(set(v[3:7])))))
                elif m.group(1) == 'EDGE':
                    s['edges'].append((v[4], tuple(sorted(v[0:2])), tuple(sorted(v[2:4]))))
                else:
                    s['faces'].append((v[0], v[1], v[2], v[3]))
                continue
            m = re.search(r'LO\(SHIP_([A-Z0-9_]+)_EDGES - SHIP_[A-Z0-9_]+\)', code)
            if m and m.group(1) != name:
                s['edges from'] = m.group(1)      # the splinter and the Thargon reuse another ship's edges
            m = re.search(r'\\\s*([A-Za-z][A-Za-z. ]+?)\s*=\s*(.+)$', line)
            if m and not s['vertices']:
                s['fields'][m.group(1).strip()] = m.group(2).strip()
    for s in ships.values():
        if 'edges from' in s:
            s['edges'] = ships[s['edges from']]['edges'][:first_int(s['fields'].get('Number of edges'))]
    return ships


def first_int(text):
    m = re.search(r'-?\d+', text or '')
    return int(m.group()) if m else None


def last_int(text):
    m = re.findall(r'-?\d+', text or '')
    return int(m[-1]) if m else None


def compare_ships(bbc):
    zx, bb, sram = spectrum_ships(), bbc_ships(bbc), bbc_ships(bbc, 3)
    print('| Spectrum | BBC | vertices | edges | faces | energy | speed | bounty (tenths) | visibility | laser / '
          'missiles (BBC) | canisters (BBC) |')
    print('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |')
    same_shapes = 0
    for name in sorted(zx, key=lambda n: SHAPES[n]):
        z, b = zx[name], bb[SHAPES[name]]
        f = b['fields']
        h = z['header']

        def cmp(a, c):
            return 'same' if a == c else f'{len(a)} vs {len(c)}' if len(a) != len(c) else 'differs'
        v = cmp(sorted(z['vertices']), sorted(b['vertices']))
        if v == 'differs':
            # the coordinates alone
            zc = sorted(t[:3] for t in z['vertices'])
            bc = sorted(t[:3] for t in b['vertices'])
            v = 'same points, other faces/visibility' if zc == bc else 'differs'
        e = cmp(sorted(z['edges']), sorted(b['edges']))
        if e == 'differs' and sorted(t[1:] for t in z['edges']) == sorted(t[1:] for t in b['edges']):
            e = 'same pairs and faces, other visibility'
        elif e == 'differs':
            e = 'same pairs, other faces/visibility' if sorted(t[1] for t in z['edges']) == sorted(
                t[1] for t in b['edges']) else 'differs'
        fa = cmp(sorted(z['faces']), sorted(b['faces']))
        if fa == 'differs':
            fa = 'same normals, other visibility' if sorted(t[:3] for t in z['faces']) == sorted(
                t[:3] for t in b['faces']) else 'differs'
            if fa == 'differs' and sorted(z['faces']) == sorted(sram[SHAPES[name]]['faces']):
                fa = 'differs; same as the sideways RAM disc'
        same_shapes += v == 'same' and e == 'same' and fa == 'same'
        energy = (h[7], first_int(f.get('Max. energy')))
        speed = (h[6], first_int(f.get('Max. speed')))
        bounty = (h[8] | h[9] << 8, first_int(f.get('Bounty')))
        vis = (h[0x0B], first_int(f.get('Visibility distance')))
        laser = f"{h[2]} / {first_int(f.get('Laser power'))}, {first_int(f.get('Missiles'))}"
        cans = (h[0] >> 4, first_int(f.get('Max. canisters on demise')))

        def pair(p):
            return str(p[0]) if p[0] == p[1] else f'{p[0]} vs {p[1]}'
        print(f'| {name} | {SHAPES[name].replace("_", " ").title()} | {v} | {e} | {fa} | {pair(energy)} | '
              f'{pair(speed)} | {pair(bounty)} | {pair(vis)} | {laser} | {h[0] & 0x0F} / {cans[1]} |')
    print(f'\n{same_shapes} of {len(zx)} blueprints have the BBC shape exactly (vertices, edges, faces); the BBC '
          'side is the Stairway to Hell disc build, the default one')


# --- tables in the game's memory

def image():
    import galaxy
    return galaxy.image()


def bbc_lines(path, label):
    """The code lines (comments cut) after .label up to the next label"""
    out, on = [], False
    for line in open(path, encoding='latin-1'):
        if line.strip() == '.' + label:
            on = True
            continue
        if on:
            code = line.split('\\')[0].strip()
            if code.startswith('.'):
                break
            if code:
                out.append(code)
    return out


def compare_market(bbc):
    import galaxy
    img = image()
    rows = []
    for code in bbc_lines(os.path.join(bbc, 'elite-source.asm'), 'QQ23'):
        v = [x.strip() for x in code[4:].split(',')]
        price, factor, unit, qty, mask = int(v[0]), int(v[1]), v[2].strip("'"), int(v[3]), int(v[4][1:], 2)
        units = {'t': 0, 'k': 1, 'g': 2}[unit]
        rows.append(bytes([price, (0x80 if factor < 0 else 0) | units << 5 | abs(factor), qty, mask]))
    zx = galaxy.byte_range(img, galaxy.COMMODITIES, 17 * 4) if hasattr(galaxy, 'byte_range') else bytes(
        galaxy.byte(img, galaxy.COMMODITIES + i) for i in range(17 * 4))
    same = sum(zx[4 * i:4 * i + 4] == r for i, r in enumerate(rows))
    print(f'QQ23 (BBC cassette) against the Spectrum\'s commodity table ${galaxy.COMMODITIES:04X}: '
          f'{same} of 17 entries byte for byte')
    for i, r in enumerate(rows):
        if zx[4 * i:4 * i + 4] != r:
            print(f'  {galaxy.GOODS[i]}: BBC {r.hex(" ")}, Spectrum {zx[4 * i:4 * i + 4].hex(" ")}')


def compare_equipment(bbc):
    import galaxy
    img = image()
    prices = [int(c.split()[1]) for c in bbc_lines(os.path.join(bbc, 'disc', 'elite-source-docked.asm.txt'), 'PRXS')
              if c.startswith('EQUW')]
    names = ['fuel', 'missile', 'large cargo bay', 'E.C.M.', 'pulse laser', 'beam laser', 'fuel scoops',
             'escape pod', 'energy bomb', 'energy unit', 'docking computers', 'galactic hyperdrive',
             'military laser', 'mining laser']
    print('| Item | BBC disc PRXS (Cr) | Spectrum EquipPrices (Cr) |')
    print('| --- | ---: | ---: |')
    for i, n in enumerate(names):
        a = 0x705F + 3 * i
        k, t = galaxy.byte(img, a), galaxy.byte(img, a + 1) | galaxy.byte(img, a + 2) << 8
        z = k * 10000 + t
        b = prices[i] if i < len(prices) else None
        mark = '' if b == z or i == 0 else ' (differs)'
        print(f'| {n} | {b / 10:.1f} | {z / 10:.1f}{mark} |' if i else f'| {n} | per jump | per jump |')


def compare_galaxy(bbc):
    import galaxy
    seeds = galaxy.galaxy_seeds()
    print('Spectrum galaxy 1 seeds:', ' '.join(f'{x:04X}' for x in seeds) if isinstance(seeds[0], int) and
          max(seeds) > 255 else seeds)
    words = [c.split()[1] for c in bbc_lines(os.path.join(bbc, 'elite-source.asm'), 'NA%') if c.startswith('EQUW')]
    print('BBC commander file NA% (QQ0, QQ1 then the seeds): EQUW', ', '.join(words))


def compare_kills(bbc):
    """The Spectrum's combat score for a kill (header +$15, halved) in units of 256, against the BBC Master's
    fractional kill points (KWH%.KWL%); the cassette and disc versions add exactly one a kill (INC TALLY)"""
    zx = spectrum_ships()
    path = os.path.join(bbc, 'master', 'elite-data.asm')
    names, lo, hi = [], [], []
    for which, store in (('KWL%', lo), ('KWH%', hi)):
        on = False
        for line in open(path, encoding='latin-1'):
            if line.strip() == '.' + which:
                on = True
                continue
            if on and line.strip().startswith('EQUB'):
                if not line.split()[1].isdigit():
                    break
                store.append(int(line.split()[1]))
                if which == 'KWL%':
                    names.append(line.split('\\')[1].split('  ')[0].strip())
            elif on and line.strip().startswith('.'):
                break
    master = {n: hi[i] + lo[i] / 256 for i, n in enumerate(names)}
    pick = {'Asp': 'Asp Mk II', 'RockHermit': 'Rock hermit (asteroid)', 'Asteroid': 'Asteroid', 'Canister':
            'Cargo canister', 'CobraTrader': 'Cobra Mk III', 'CobraPirate': 'Cobra Mk III (pirate)', 'Coriolis':
            'Coriolis space station', 'EscapePod': 'Escape pod', 'FerDeLance': 'Fer-de-lance', 'Krait': 'Krait',
            'Missile': 'Missile', 'Plate': 'Alloy plate', 'PythonTrader': 'Python', 'PythonPirate':
            'Python (pirate)', 'Sidewinder': 'Sidewinder', 'Splinter': 'Splinter', 'Thargoid': 'Thargoid',
            'Thargon': 'Thargon', 'Viper': 'Viper'}
    print('| Blueprint | Spectrum score a kill | in kills (/ 256) | BBC Master kill points | ratio |')
    print('| --- | ---: | ---: | ---: | ---: |')
    for n in sorted(zx):
        h = zx[n]['header']
        score = (h[0x15] | h[0x16] << 8) >> 1
        m = master.get(pick[n])
        ratio = f'{score / 256 / m:.2f}' if m else '-'
        print(f'| {n} | {score} | {score / 256:.3f} | {m:.3f} | {ratio} |' if m is not None else
              f'| {n} | {score} | {score / 256:.3f} | - | - |')


def bbc_tokens(bbc):
    """The BBC disc's extended tokens (TKN1) as Moxon's comments spell them: {n: text}"""
    path = os.path.join(bbc, 'disc', 'elite-source-docked.asm.txt')
    out, on, cur, text, open_q = {}, False, None, '', False
    for line in open(path, encoding='latin-1'):
        if line.strip() == '.TKN1':
            on = True
            continue
        if line.strip() == '.RUTOK':
            break
        if not on or '\\' not in line:
            continue
        com = line.split('\\', 1)[1]
        m = re.match(r'\s*Token (\d+):\s*"(.*)', com)
        if m:
            cur, text = int(m.group(1)), m.group(2)
            open_q = not text.rstrip().endswith('"')
            if not open_q:
                out[cur] = text.rstrip()[:-1]
        elif open_q and cur is not None:
            part = com.strip()
            if part.startswith('Encoded as'):
                open_q = False
                continue
            if part.endswith('"'):
                text += part[:-1]
                out[cur] = text
                open_q = False
            else:
                text += part
    return out


def spectrum_tokens():
    """The Spectrum's description tokens (the other set at TokenTable $F11C) spelt like the BBC comments: the
    pairs of OtherPairs $FD99 written out, a fixed token's text put in, a random pick [row-row+4]"""
    import galaxy
    m = bytes(galaxy.BASE) + galaxy.image()
    a0 = m[0xF11C] | m[0xF11D] << 8
    starts, a = [a0], a0
    for _ in range(255):
        while m[a]:
            a += 1
        a += 1
        starts.append(a)

    def text(n, depth=0):
        a, out = starts[n - 1], ''
        while m[a]:
            b = m[a]
            if 0x20 <= b < 0x5B:
                out += chr(b)
            elif 0x5B <= b < 0x81:
                row = m[0xD5F5 + b - 0x5B]
                out += '[%d-%d]' % (row, row + 4)
            elif 0x81 <= b < 0xD7:
                out += text(b, depth + 1) if depth < 6 else '<%d>' % b
            elif b >= 0xD7:
                i = b - 0xD7
                pair = chr(m[0xFD99 + 2 * i]) + chr(m[0xFD99 + 2 * i + 1])
                out += pair.replace('?', '')
            a += 1
        return out
    return {n: text(n) for n in range(1, 256)}


def norm(t):
    t = re.sub(r'\{[^}]*\}', ' ', t.upper())
    return re.sub(r'\s+', ' ', t).strip()


def compare_tokens(bbc):
    """The planet-description words: every BBC disc token from 115 to 255 that the description grammar reaches,
    against the Spectrum's token of the same number"""
    b, z = bbc_tokens(bbc), spectrum_tokens()
    same = diff = 0
    rows = []
    for n in range(96, 256):
        if n not in b:
            continue
        bt, zt = norm(b[n]), norm(z[n])
        if bt == zt:
            same += 1
        else:
            diff += 1
            rows.append((n, b[n], z[n]))
    print(f'tokens 96-255: {same} the same, {diff} different')
    for n, bt, zt in rows:
        print(f'| {n} | {bt} | {zt} |')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('bbc')
    for o in ('ships', 'market', 'equipment', 'galaxy', 'kills', 'tokens', 'all'):
        p.add_argument('--' + o, action='store_true')
    a = p.parse_args()
    if a.ships or a.all:
        compare_ships(a.bbc)
    if a.market or a.all:
        compare_market(a.bbc)
    if a.equipment or a.all:
        compare_equipment(a.bbc)
    if a.galaxy or a.all:
        compare_galaxy(a.bbc)
    if a.kills or a.all:
        compare_kills(a.bbc)
    if a.tokens or a.all:
        compare_tokens(a.bbc)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The game's resources of Advanced Nether Earth against Nether Earth's, byte for byte: sprite by sprite, font glyph
by glyph, level record by record, map cell by cell, string by string, and the data tables both keep.

    python3 tools/diff_res.py [--section S ...] [--all] [--json OUT]

Run both cases' tools/build.sh first: the tool reads what the builds leave.

- NE's side: its game image `games/nether-earth/build/game.bin` (`$5B00-$FCE8`), its resource files `build/res/`
  and the entries of its `src/game/game.ann`.
- ANE's side: its game block `build/game/game-6731.bin` (`$6731-$D7D7`), its resource files `build/game/res/game/`
  and the entries of its `src/game/game.ann`.

An entry runs from its address to the next entry of its annotation (any kind), bounded by the image. Entries of the
two annotations are paired by name (both reverses use NE's names where the code is NE's); the resources that moved
are paired by hand (`PAIRS`: NE's Font is ANE's GameFont).

Sections (each line: status, name, NE address, ANE address, what differs):

  sprites   the 89 sprite blocks (header + rows), by file name; and the view edges
  font      the 64 glyphs, codes `$20-$5F`, with the letter ANE's font draws (tools/game_text.py)
  level     the level lists (scenery, bases: 3-byte records; the shape table and the shapes)
  map       the map `$DD00-$FCFF` each game's own BuildMap `$BC6F` builds, cell by cell, with the base records
            `$FD70-$FDC3` and the radar `$D800-$D8FF`: BuildMap run on SkoolKit's Simulator over each image (the
            `buildmap` command, run by the SkoolKit venv's Python when this one has no skoolkit)
  strings   every text entry (kind t): the text and the layout codes (position, attribute, size) apart
  orders    the nine order names, line by line
  tables    every other data entry (kinds b, w) both annotations name; and the data entries only one keeps, with
            what the other holds at that address

Statuses: same, changed, only-NE, only-ANE (for a moved resource: moved, with both addresses).

    python3 tools/diff_res.py buildmap --out work/diff/buildmap    # the two 64 K memories after BuildMap
"""
import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
NE = os.path.join(os.path.dirname(CASE), 'nether-earth')
sys.path.insert(0, HERE)
import game_text  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

VENV_PYTHON = (os.environ.get('SKOOLKIT_PYTHON')
               or toolpaths.skoolkit_python(toolpaths.skoolkit_venv(required=False) or ''))
ENTRY = re.compile(r'^\$([0-9A-F]{4})\s+([cbwts])\b(?:\s+([A-Za-z_]\w*))?(?:\s+\d+)?\s*(?:;\s*(.*))?$')
RES = re.compile(r'^@res\s+(\S+)')

SIDES = {
    'NE': dict(ann=os.path.join(NE, 'src', 'game', 'game.ann'), image=os.path.join(NE, 'build', 'game.bin'),
               org=0x5B00, res=os.path.join(NE, 'build', 'res'), prefix=''),
    'ANE': dict(ann=os.path.join(CASE, 'src', 'game', 'game.ann'),
                image=os.path.join(CASE, 'build', 'game', 'game-6731.bin'), org=0x6731,
                res=os.path.join(CASE, 'build', 'game', 'res', 'game'), prefix='game/'),
}
PAIRS = {'Font': 'GameFont'}          # NE name -> ANE name, for resources that moved
MAP, MAP_END, RADAR, BASES, BASES_END = 0xDD00, 0xFD00, 0xD800, 0xFD70, 0xFDC4
BUILDMAP, SHIP_Y, SHIP_X = 0xBC6F, 0xFD0D, 0xFD0E


class Side:
    """one case: its image, its annotation's entries and @res files"""

    def __init__(self, key):
        s = SIDES[key]
        self.key, self.org, self.resdir, self.prefix = key, s['org'], s['res'], s['prefix']
        self.image = open(s['image'], 'rb').read()
        self.end = self.org + len(self.image)
        self.entries, self.res = [], {}
        last = None
        for line in open(s['ann'], encoding='utf-8'):
            m = ENTRY.match(line.rstrip('\n'))
            if m:
                last = dict(addr=int(m.group(1), 16), kind=m.group(2), name=m.group(3) or '', title=m.group(4) or '')
                self.entries.append(last)
                continue
            m = RES.match(line)
            if m and last:
                last['res'] = m.group(1)[len(self.prefix):] if m.group(1).startswith(self.prefix) else m.group(1)
        starts = sorted({e['addr'] for e in self.entries})
        nxt = {a: b for a, b in zip(starts, starts[1:] + [0x10000])}
        for e in self.entries:
            e['end'] = min(nxt[e['addr']], self.end)
        self.by_name = {}
        for e in self.entries:
            if e['name'] and e['name'] not in self.by_name:
                self.by_name[e['name']] = e
        self.files = {}                 # res file -> (first address, bytes)
        for e in self.entries:
            if 'res' in e and e['res'] not in self.files:
                path = os.path.join(self.resdir, e['res'])
                self.files[e['res']] = (e['addr'], open(path, 'rb').read())

    def bytes(self, start, end):
        start, end = max(start, self.org), min(end, self.end)
        return self.image[start - self.org:end - self.org] if end > start else b''

    def entry_at(self, addr):
        """the entry (of any kind) that holds addr"""
        best = None
        for e in self.entries:
            if e['addr'] <= addr < e['end'] and (best is None or e['addr'] >= best['addr']):
                best = e
        return best


def h(a):
    return '$%04X' % a


def rng(a, n):
    return '%s-%s' % (h(a), h(a + n - 1)) if n else h(a)


def row(status, name, ne, ane, note=''):
    return dict(status=status, name=name, ne=ne, ane=ane, note=note)


# ------------------------------------------------------------------------------------------------- sprites, edges

def sec_sprites(n, a):
    out = []
    names = sorted(f for f in n.files if f.startswith('gfx/sprites/')) + ['gfx/view-edges.bin']
    for f in names:
        na, nb = n.files[f]
        if f not in a.files:
            out.append(row('only-NE', f, rng(na, len(nb)), '', ''))
            continue
        aa, ab = a.files[f]
        assert n.bytes(na, na + len(nb)) == nb and a.bytes(aa, aa + len(ab)) == ab, f
        if nb == ab:
            note = '%d bytes, %d x %d' % (len(nb), nb[0], nb[1]) if f.startswith('gfx/sprites/') else '%d bytes' % len(nb)
            out.append(row('same', f, rng(na, len(nb)), rng(aa, len(ab)), note))
        else:
            diff = sum(x != y for x, y in zip(nb, ab)) + abs(len(nb) - len(ab))
            out.append(row('changed', f, rng(na, len(nb)), rng(aa, len(ab)), '%d bytes differ' % diff))
    for f in sorted(a.files):
        if f.startswith('gfx/sprites/') and f not in n.files:
            aa, ab = a.files[f]
            out.append(row('only-ANE', f, '', rng(aa, len(ab))))
    return out


# ------------------------------------------------------------------------------------------------------- the font

def font_pair(n, a):
    ne, ane = n.by_name['Font'], a.by_name[PAIRS['Font']]
    return ne['addr'], n.bytes(ne['addr'], ne['addr'] + 512), ane['addr'], a.bytes(ane['addr'], ane['addr'] + 512)


def sec_font(n, a):
    na, nb, aa, ab = font_pair(n, a)
    out = []
    for g in range(64):
        code = 0x20 + g
        x, y = nb[8 * g:8 * g + 8], ab[8 * g:8 * g + 8]
        pixels = sum(bin(p ^ q).count('1') for p, q in zip(x, y))
        ne_char = {0x40: '(c)', 0x5E: 'up arrow', 0x5F: 'underline'}.get(code, chr(code))
        letter = game_text.GLYPHS.get(code, ne_char)
        status = 'same' if x == y else 'changed'
        out.append(row(status, 'code $%02X' % code, h(na + 8 * g), h(aa + 8 * g),
                       'NE %r, ANE %r, %d pixels differ' % (ne_char, letter, pixels)))
    return out


# ---------------------------------------------------------------------------------------------------- the level

def sec_level(n, a):
    out = []
    for f in sorted(x for x in n.files if x.startswith('map/')):
        na, nb = n.files[f]
        aa, ab = a.files.get(f, (None, None))
        if ab is None:
            out.append(row('only-NE', f, rng(na, len(nb)), ''))
            continue
        step = 3 if ('scenery' in f or 'bases' in f) else 1
        recs = (len(nb) + step - 1) // step
        bad = [i for i in range(recs) if nb[i * step:i * step + step] != ab[i * step:i * step + step]]
        unit = 'records' if step == 3 else 'bytes'
        status = 'same' if nb == ab else 'changed'
        note = '%d %s' % (recs, unit) + (', differ: %s' % bad[:12] if bad else '')
        out.append(row(status, f, rng(na, len(nb)), rng(aa, len(ab)), note))
    return out


# ------------------------------------------------------------------------------------------------------ the map

def buildmap_memory(side):
    """64 K after the side's own BuildMap ran over its image (SkoolKit's Simulator)"""
    from skoolkit.simulator import Simulator
    mem = bytearray(0x10000)
    mem[side.org:side.end] = side.image
    mem[SHIP_Y], mem[SHIP_X] = 10, 0x11          # as the new game set-up leaves them before BuildMap
    sp = 0x5F00
    mem[sp] = mem[sp + 1] = 0                     # BuildMap returns to $0000: the end of the run
    sim = Simulator(mem, {'PC': BUILDMAP, 'SP': sp})
    steps = 0
    while sim.registers[24] != 0:
        sim.run()
        steps += 1
        if steps > 2000000:
            sys.exit('%s: BuildMap did not return' % side.key)
    return bytes(sim.memory), steps


def cmd_buildmap(args):
    os.makedirs(args.out, exist_ok=True)
    for key in ('NE', 'ANE'):
        mem, steps = buildmap_memory(Side(key))
        path = os.path.join(args.out, key.lower() + '.bin')
        open(path, 'wb').write(mem)
        print('%s: BuildMap returned after %d instructions -> %s' % (key, steps, path))


def map_memories(out_dir):
    paths = [os.path.join(out_dir, k + '.bin') for k in ('ne', 'ane')]
    try:
        import skoolkit  # noqa: F401
        cmd_buildmap(argparse.Namespace(out=out_dir))
    except ImportError:
        if not os.path.exists(VENV_PYTHON):
            return None
        subprocess.run([VENV_PYTHON, os.path.abspath(__file__), 'buildmap', '--out', out_dir], check=True,
                       stdout=subprocess.DEVNULL)
    return [open(p, 'rb').read() for p in paths]


def sec_map(n, a, out_dir):
    mems = map_memories(out_dir)
    if mems is None:
        return [row('skipped', 'map', '', '', 'no SkoolKit: set SKOOLKIT_PYTHON to a Python that has it')]
    m1, m2 = mems
    out = []
    cells = [(i // 0x200, i % 0x200) for i in range(MAP_END - MAP) if m1[MAP + i] != m2[MAP + i]]
    used = sum(1 for i in range(MAP_END - MAP) if m1[MAP + i])
    out.append(row('same' if not cells else 'changed', 'map cells (16 rows x 512)', rng(MAP, MAP_END - MAP),
                   rng(MAP, MAP_END - MAP), '%d of 8192 cells differ; %d cells non-zero in NE' % (len(cells), used)
                   + ('; first: %s' % cells[:10] if cells else '')))
    for name, lo, hi in (('base records', BASES, BASES_END), ('radar bitmap', RADAR, RADAR + 0x100)):
        d = sum(m1[i] != m2[i] for i in range(lo, hi))
        out.append(row('same' if not d else 'changed', name, rng(lo, hi - lo), rng(lo, hi - lo),
                       '%d bytes differ' % d))
    return out


# ------------------------------------------------------------------------------------------------------ strings

def cut(data):
    """the string up to and with its end code (0), or all of it when it has none"""
    i = 0
    while i < len(data):
        if data[i] in (1, 2, 4):
            i += 3 if data[i] == 1 else 2
            continue
        if data[i] == 0:
            return data[:i + 1]
        i += 1
    return data


def tokens(data):
    """PrintInline's codes: ('at', y, x), ('attr', a), ('nl',), ('size', s), ('end',), ('text', bytes)"""
    out, i, run = [], 0, bytearray()

    def flush():
        if run:
            out.append(('text', bytes(run)))
            run.clear()
    while i < len(data):
        b = data[i]
        if b in (1, 2, 4) and i + (2 if b == 1 else 1) < len(data):
            flush()
            if b == 1:
                out.append(('at', data[i + 1], data[i + 2]))
                i += 3
            else:
                out.append(('attr' if b == 2 else 'size', data[i + 1]))
                i += 2
            continue
        if b in (0, 3):
            flush()
            out.append(('end',) if b == 0 else ('nl',))
            i += 1
            if b == 0:
                break
            continue
        run.append(b)
        i += 1
    flush()
    return out


def ane_text(data):
    """ANE's letters; code $33 is the letter З before a letter, else the digit 3 next to a digit, a dot or alone"""
    out = []
    for i, b in enumerate(data):
        if b == 0x33:
            near = [data[j] for j in (i - 1, i + 1) if 0 <= j < len(data)]
            nxt = data[i + 1] if i + 1 < len(data) else 0
            digit = nxt < 0x41 and (all(c < 0x41 for c in near) or any(0x30 <= c <= 0x39 or c == 0x2E for c in near))
            out.append('3' if digit else 'З')
        else:
            out.append(game_text.decode(bytes([b])))
    return ''.join(out)


def show(toks, side):
    parts = []
    for t in toks:
        if t[0] == 'text':
            s = ane_text(t[1]) if side == 'ANE' else ''.join(
                chr(c) if 0x20 <= c < 0x7F else '.' for c in t[1])
            parts.append('"%s"' % s)
        elif t[0] == 'at':
            parts.append('{at %d,%d}' % (t[1], t[2]))
        elif t[0] in ('attr', 'size'):
            parts.append('{%s $%02X}' % (t[0], t[1]))
        else:
            parts.append('{%s}' % t[0])
    return ' '.join(parts)


def layout(toks):
    return [t for t in toks if t[0] != 'text']


def sec_strings(n, a):
    out = []
    names = [e['name'] for e in n.entries if e['kind'] == 't' and e['name']]
    names += [e['name'] for e in a.entries if e['kind'] == 't' and e['name'] and e['name'] not in n.by_name]
    seen = set()
    for name in names:
        if name in seen:
            continue
        seen.add(name)
        ne, ane = n.by_name.get(name), a.by_name.get(name)
        if ne is None or ne['kind'] != 't':
            out.append(row('only-ANE', name, '', rng(ane['addr'], ane['end'] - ane['addr'])))
            continue
        nb = cut(n.bytes(ne['addr'], ne['end']))
        if ane is None or ane['kind'] != 't':
            held = a.entry_at(ne['addr'])
            note = 'NE: %s' % show(tokens(nb), 'NE')
            note += '; ANE there: %s %s' % (held['kind'], held['name'] or '') if held else '; outside ANE\'s image'
            out.append(row('only-NE', name, rng(ne['addr'], len(nb)), '', note))
            continue
        ab = cut(a.bytes(ane['addr'], ane['end']))
        tn, ta = tokens(nb), tokens(ab)
        if nb == ab:
            status, what = 'same', 'bytes equal'
        else:
            status = 'changed'
            what = 'text' + ('' if layout(tn) == layout(ta) else ' and layout')
            if len(nb) != len(ab):
                what += ', %d -> %d bytes' % (len(nb), len(ab))
        out.append(row(status, name, rng(ne['addr'], len(nb)), rng(ane['addr'], len(ab)),
                       '%s | NE: %s | ANE: %s' % (what, show(tn, 'NE'), show(ta, 'ANE'))))
    return out


def layout_changes(nb, ab):
    """the layout codes that differ, in order (a list of (NE code, ANE code))"""
    ln, la = layout(tokens(nb)), layout(tokens(ab))
    return [(x, y) for x, y in zip(ln, la) if x != y] + [(x, None) for x in ln[len(la):]] + \
        [(None, y) for y in la[len(ln):]]


def sec_orders(n, a):
    na, nb = n.files['text/order-names.bin']
    aa, ab = a.files['text/order-names.bin']
    out = []
    for k in range(9):
        x, y = nb[27 * k:27 * k + 27], ab[27 * k:27 * k + 27]
        ln = [x[i * 9:i * 9 + 8].decode('ascii') for i in range(3)]
        out.append(row('same' if x == y else 'changed', 'order %d' % k, rng(na + 27 * k, 27), rng(aa + 27 * k, 27),
                       'NE "%s" | ANE "%s"' % ('/'.join(ln), '/'.join(ane_text(y[i * 9:i * 9 + 8]) for i in range(3)))))
    return out


# ------------------------------------------------------------------------------------------------------- tables

def sec_tables(n, a):
    out = []
    covered = {e['name'] for e in n.entries if 'res' in e} | {e['name'] for e in a.entries if 'res' in e}
    for ne in n.entries:
        if ne['kind'] not in 'bw' or not ne['name'] or ne['name'] in covered or ne['name'] in PAIRS:
            continue
        if not (n.org <= ne['addr'] < n.end):
            continue
        nb = n.bytes(ne['addr'], ne['end'])
        ane = a.by_name.get(ne['name'])
        if ane is None:
            if a.org <= ne['addr'] < a.end:
                held = a.entry_at(ne['addr'])
                note = 'ANE there: %s %s' % (held['kind'], held['name']) if held else ''
                out.append(row('only-NE', ne['name'], rng(ne['addr'], len(nb)), '', note))
            else:
                out.append(row('only-NE', ne['name'], rng(ne['addr'], len(nb)), '', 'past ANE\'s game block'))
            continue
        ab = a.bytes(ane['addr'], ane['end'])
        if not ab:
            out.append(row('only-NE', ne['name'], rng(ne['addr'], len(nb)), h(ane['addr']),
                           'past ANE\'s game block'))
            continue
        if len(ab) > len(nb) and ane['end'] == a.end and a.entry_at(ne['end']) is ane:
            ab = ab[:len(nb)]           # ANE names nothing after it: the entry runs on to the block's end
        if nb == ab:
            out.append(row('same', ne['name'], rng(ne['addr'], len(nb)), rng(ane['addr'], len(ab)),
                           '%d bytes' % len(nb)))
        else:
            k = min(len(nb), len(ab))
            diffs = [i for i in range(k) if nb[i] != ab[i]]
            note = '%d of %d bytes differ' % (len(diffs) + abs(len(nb) - len(ab)), max(len(nb), len(ab)))
            if diffs:
                note += ', first at +%d: NE %s, ANE %s' % (diffs[0], nb[diffs[0]:diffs[0] + 8].hex(),
                                                          ab[diffs[0]:diffs[0] + 8].hex())
            out.append(row('changed', ne['name'], rng(ne['addr'], len(nb)), rng(ane['addr'], len(ab)), note))
    for f in sorted(n.files):
        if f not in a.files and n.by_name.get('Font', {}).get('res') != f:
            na, nb = n.files[f]
            held = a.entry_at(na)
            out.append(row('only-NE', f, rng(na, len(nb)), '', 'resource file; ANE there: %s %s'
                           % (held['kind'], held['name']) if held else 'resource file'))
    for ane in a.entries:
        if ane['kind'] in 'bw' and ane['name'] and ane['name'] not in n.by_name and ane['name'] not in covered \
                and ane['name'] not in PAIRS.values():
            held = n.entry_at(ane['addr'])
            note = 'NE there: %s %s' % (held['kind'], held['name']) if held else ''
            out.append(row('only-ANE', ane['name'], '', rng(ane['addr'], ane['end'] - ane['addr']), note))
    return out


SECTIONS = ['sprites', 'font', 'level', 'map', 'strings', 'orders', 'tables']


def collect(sections, out_dir):
    n, a = Side('NE'), Side('ANE')
    res = {}
    for s in sections:
        if s == 'map':
            res[s] = sec_map(n, a, out_dir)
        else:
            res[s] = globals()['sec_' + s](n, a)
    return res


def main():
    if len(sys.argv) > 1 and sys.argv[1] == 'buildmap':
        p = argparse.ArgumentParser()
        p.add_argument('cmd')
        p.add_argument('--out', default=os.path.join(CASE, 'work', 'diff', 'buildmap'))
        cmd_buildmap(p.parse_args())
        return
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--section', action='append', choices=SECTIONS, help='only these sections (default: all)')
    p.add_argument('--all', action='store_true', help='list the same entries too (default: a count of them)')
    p.add_argument('--json', help='write every row to this JSON file')
    p.add_argument('--map-dir', default=os.path.join(CASE, 'work', 'diff', 'buildmap'))
    args = p.parse_args()
    res = collect(args.section or SECTIONS, args.map_dir)
    for s, rows in res.items():
        counts = {}
        for r in rows:
            counts[r['status']] = counts.get(r['status'], 0) + 1
        print('== %s: %s' % (s, ', '.join('%d %s' % (v, k) for k, v in sorted(counts.items()))))
        for r in rows:
            if r['status'] == 'same' and not args.all and s not in ('map',):
                continue
            print('  %-8s %-34s NE %-13s ANE %-13s %s' % (r['status'], r['name'], r['ne'] or '-', r['ane'] or '-',
                                                          r['note']))
    if args.json:
        json.dump(res, open(args.json, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print('->', args.json)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The game image of Zynaps GS against Zynaps 48K's, byte by byte and entry by entry, from both cases' builds (doc 13).
Copied from nether-earth-gs's tools/diff_ne.py and moved onto this pair.

  diff_zy.py --summary                       the totals, the runs with both cases' names, the modules
  diff_zy.py --runs [--gap N]                every differing run: both entries, both listings side by side
  diff_zy.py --show NAME [NAME ...]          one entry of either case (a name or $ADDR), both listings side by side
  diff_zy.py --installer [--live BIN ...]    the installer's 31 places and stub areas: 48K, block 4, and live bytes
  diff_zy.py --json OUT.json                 the classes of every byte, the runs and the modules, for the figures

Reads only the builds (run each case's tools/build.sh first):
  GS   build/game.bin ($5C00-$FFFF as Trush block 4 carries it), build/game.lst, src/game/game.ann,
       src/disk/install.asm (the Site EQUs and the stubs' DISP addresses)
  Z48  games/zynaps/build/game.bin ($61A8-$FFFE as the Hewson loader leaves it), build/game.lst, src/game/game.ann

The two images are not the same moment of the game. The 48K's is the tape's: Start ($B6FF) has not run yet. Block 4
carries the memory after Start ran. So the 48K image is first put through Start's two steps (src/game/start.asm):
$BC00-$C7FF copied to $5C00-$67FF, $E000-$E747 and $F048-$F107 complemented. Then the bytes are compared address by
address; nothing is paired by name. Each byte of $5C00-$FFFF is in one class:

  same       the same byte (after Start)
  start      the same byte only after Start: the 48K tape holds it elsewhere or inverted
  differ     another byte: the GS conversion's edit
  cache      $C800-$DFFF, the glyph cache: block 4 does not carry it (zero in both images)
  gs-only    $FFFF: past the 48K image's end

The installer (src/disk/install.asm) writes its 31 places and its stubs at run time, after the block is unpacked;
--installer compares them with a live 64 K CPU view (default: work/zgsA/r1-play/start.bin, r1 frame 2951, in play,
bank 0 at $C000).
"""

import argparse
import json
import os
import re
import sys
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
GS = os.path.normpath(os.path.join(HERE, '..'))
Z48 = os.path.normpath(os.path.join(GS, '..', 'zynaps'))

CASES = {
    'Z48': dict(root=Z48, bin='build/game.bin', org=0x61A8, lst='build/game.lst', ann='src/game/game.ann'),
    'GS': dict(root=GS, bin='build/game.bin', org=0x5C00, lst='build/game.lst', ann='src/game/game.ann'),
}
LO, HI = 0x5C00, 0x10000
CACHE = range(0xC800, 0xE000)
START_COPY = (0xBC00, 0xC800, 0x5C00)          # Start: LDIR $BC00 -> $5C00, $0C00 bytes
START_INVERT = ((0xE000, 0xE748), (0xF048, 0xF108))

ENTRY = re.compile(r'^\$([0-9A-F]{4}) ([cbwts]) (\S+)(?:\s+\d+)?\s*(?:;\s*(.*))?$')
LST = re.compile(r'^\s*(\d+)\+?\s+([0-9A-F]{4})(?=\s|$)')


class Case:
    def __init__(self, tag):
        c = CASES[tag]
        self.tag = tag
        data = open(os.path.join(c['root'], c['bin']), 'rb').read()
        self.loaded = {c['org'] + i: b for i, b in enumerate(data)}
        self.mem = dict(self.loaded)
        if tag == 'Z48':
            src, end, dst = START_COPY
            for i in range(end - src):
                self.mem[dst + i] = self.loaded[src + i]
            for lo, hi in START_INVERT:
                for a in range(lo, hi):
                    self.mem[a] = self.loaded[a] ^ 0xFF
        self.lo, self.hi = min(self.mem), max(self.mem) + 1
        self.read_lst(os.path.join(c['root'], c['lst']))
        self.read_ann(os.path.join(c['root'], c['ann']))

    def read_lst(self, path):
        """addr -> [(line, bytes, source)] of the lines that assemble bytes there; label addr -> file"""
        self.lines, self.file_of, self.label_file, self.labels, files = {}, {}, {}, {}, ['game.asm']
        for n, raw in enumerate(open(path, encoding='utf-8', errors='replace'), 1):
            raw = raw.rstrip('\n')
            if raw.startswith('# file opened:'):
                files.append(raw.split(':', 1)[1].strip())
                continue
            if raw.startswith('# file closed:'):
                files.pop()
                continue
            m = LST.match(raw)
            if not m:
                continue
            addr = int(m.group(2), 16)
            rest = raw[m.end():]
            hexpart, src = rest[1:13], rest[14:]
            code = [int(x, 16) for x in hexpart.split()] if re.fullmatch(r'(?:[0-9A-F]{2} ?)*\s*', hexpart) else []
            self.file_of.setdefault(addr, files[-1])
            lab = re.match(r'([A-Za-z_]\w*):', src)
            if lab:
                self.label_file.setdefault(lab.group(1), files[-1])
                self.labels.setdefault(lab.group(1), addr)
            if code:
                self.file_of[addr] = files[-1]
                self.lines.setdefault(addr, []).append((n, code, src.strip()))

    def read_ann(self, path):
        self.entries = []
        for line in open(path, encoding='utf-8'):
            m = ENTRY.match(line.rstrip('\n'))
            if m:
                self.entries.append(dict(addr=int(m.group(1), 16), kind=m.group(2), name=m.group(3),
                                         title=(m.group(4) or '').strip()))
        self.entries.sort(key=lambda e: e['addr'])
        for i, e in enumerate(self.entries):
            nxt = self.entries[i + 1]['addr'] if i + 1 < len(self.entries) else 0x10000
            e['end'] = nxt
            e['module'] = self.label_file.get(e['name'], self.file_of.get(e['addr'], '?')).replace('.asm', '')
        self.by_name = {e['name']: e for e in self.entries}

    def entry_at(self, addr):
        best = None
        for e in self.entries:
            if e['addr'] <= addr < e['end']:
                best = e
        return best

    def instr_at(self, addr):
        for a in range(addr, max(addr - 4, 0) - 1, -1):
            for n, code, src in self.lines.get(a, []):
                if a <= addr < a + len(code):
                    return a, n, code, src
        return None


def classify(z, gs):
    cls = {}
    for a in range(LO, HI):
        if a in CACHE:
            cls[a] = 'cache'
        elif a in z.mem and a in gs.mem:
            if z.mem[a] == gs.mem[a]:
                cls[a] = 'same' if z.loaded.get(a) == gs.mem[a] else 'start'
            else:
                cls[a] = 'differ'
        elif a in gs.mem:
            cls[a] = 'gs-only'
        else:
            cls[a] = 'z48-only'
    return cls


def runs_of(a_mem, b_mem, lo, hi, gap):
    out = []
    for x in range(lo, hi):
        if x in CACHE:
            continue
        if x in a_mem and x in b_mem and a_mem[x] != b_mem[x]:
            if out and x - out[-1][1] <= gap:
                out[-1][1] = x + 1
            else:
                out.append([x, x + 1])
    return out


def side_by_side(z, gs, lo, hi, width=60):
    """both listings' instructions over lo..hi, aligned by address; '*' where the bytes differ"""
    addrs = sorted({s for c in (z, gs) for s, ls in c.lines.items() if lo <= s < hi} |
                   {i[0] for c in (z, gs) for i in [c.instr_at(lo)] if i})
    rows = []
    for a in addrs:
        left = z.lines.get(a, [])
        right = gs.lines.get(a, [])
        for k in range(max(len(left), len(right))):
            l = left[k] if k < len(left) else None
            r = right[k] if k < len(right) else None
            lb = bytes(l[1]) if l else b''
            rb = bytes(r[1]) if r else b''
            mark = ' ' if lb == rb else '*'

            def fmt(x):
                if not x:
                    return ''
                n, code, src = x
                src = src.split(';')[0].strip() if not src.lstrip().startswith(';') else ''
                return f"{n:5d} {a:04X} {' '.join(f'{b:02X}' for b in code[:4]):11s} {src}"[:width]
            rows.append(f'{fmt(l):{width}s} {mark} {fmt(r)}')
    return rows


def module_table(z, gs, cls):
    per = OrderedDict()
    for e in z.entries:
        d = per.setdefault(e['module'], Counter())
        for a in range(max(e['addr'], LO), min(e['end'], HI)):
            d[cls[a]] += 1
    gsmod = OrderedDict()
    for e in gs.entries:
        d = gsmod.setdefault(e['module'], Counter())
        for a in range(max(e['addr'], LO), min(e['end'], HI)):
            d[cls[a]] += 1
    return per, gsmod


def names_over(case, lo, hi):
    return [f"{e['name']} ${e['addr']:04X}" for e in case.entries if e['addr'] < hi and e['end'] > lo]


def summary(z, gs, cls, gap):
    n = Counter(cls.values())
    common = n['same'] + n['start'] + n['differ']
    print(f'$5C00-$FFFF: {HI - LO} bytes; glyph cache $C800-$DFFF not carried: {n["cache"]}; gs-only: {n["gs-only"]}')
    print(f'compared {common} bytes: {n["same"] + n["start"]} the same ({100 * (n["same"] + n["start"]) / common:.2f} %),'
          f' of them {n["start"]} only after Start; {n["differ"]} differ')
    loaded_diff = sum(1 for a in range(LO, HI) if a not in CACHE and a in z.loaded and a in gs.mem
                      and z.loaded[a] != gs.mem[a])
    print(f'against the tape image as loaded ($61A8-$FFFE, no Start): {loaded_diff} bytes differ')
    runs = runs_of(z.mem, gs.mem, LO, HI, gap)
    print(f'{len(runs)} runs (gap {gap}):')
    for s, e in runs:
        d = sum(1 for a in range(s, e) if z.mem[a] != gs.mem[a])
        print(f'  ${s:04X}-${e - 1:04X} {e - s:3d} bytes, {d:3d} differ | Z48: {", ".join(names_over(z, s, e))}'
              f' | GS: {", ".join(names_over(gs, s, e))}')
    print(f'entries: Z48 {len(z.entries)}, GS {len(gs.entries)}')
    per, gsmod = module_table(z, gs, cls)
    changed = [m for m, d in per.items() if d['differ']]
    print(f'Z48 modules: {len(per)}, {len(per) - len(changed)} without a differing byte; changed: '
          + ', '.join(f'{m} {per[m]["differ"]}' for m in changed))


def show_runs(z, gs, gap):
    for s, e in runs_of(z.mem, gs.mem, LO, HI, gap):
        print(f'=== ${s:04X}-${e - 1:04X}   Z48: {", ".join(names_over(z, s, e))}   GS: {", ".join(names_over(gs, s, e))}')
        print(f'{"Z48 line addr bytes":60s}   GS  line addr bytes')
        for row in side_by_side(z, gs, s, e):
            print(row)


def show(z, gs, names):
    for name in names:
        e = None
        for c in (z, gs):
            e = c.entry_at(int(name[1:], 16)) if name.startswith('$') else c.by_name.get(name)
            if e:
                break
        if not e:
            print('no entry', name)
            continue
        print(f'=== {name}: ${e["addr"]:04X}-${e["end"] - 1:04X}   Z48: {", ".join(names_over(z, e["addr"], e["end"]))}'
              f'   GS: {", ".join(names_over(gs, e["addr"], e["end"]))}')
        for row in side_by_side(z, gs, e['addr'], e['end']):
            print(row)


def installer_places():
    """the Site EQUs of install.asm (address, name, comment) and the stub areas (DISP address, label, length)"""
    src = open(os.path.join(GS, 'src/disk/install.asm'), encoding='utf-8').read().split('\n')
    sites = []
    for line in src:
        m = re.match(r'^(Site\w+)\s+EQU \$([0-9A-F]{4})\s*;\s*(.*)$', line)
        if m:
            sites.append((int(m.group(2), 16), m.group(1), m.group(3)))
    lst = os.path.join(GS, 'build/lst/install.lst')
    areas = []
    if os.path.exists(lst):
        cur = None
        for raw in open(lst, encoding='utf-8', errors='replace'):
            m = re.match(r'^\s*\d+\+?\s+([0-9A-F]{4})\s+((?:[0-9A-F]{2} ?)*)\s+(.*)$', raw.rstrip('\n'))
            if not m:
                continue
            body = m.group(3).strip()
            if body.startswith('DISP'):
                cur = [int(body.split('$')[1][:4], 16), None, 0]
                areas.append(cur)
                continue
            if body.startswith('ENT'):
                cur = None
                continue
            if cur is not None:
                if cur[1] is None and re.match(r'^[A-Za-z]\w*:', body):
                    cur[1] = body.split(':')[0]
                cur[2] += len(m.group(2).split())
    return sorted(sites), areas


def installer(z, gs, lives):
    sites, areas = installer_places()
    live = [(p, open(p, 'rb').read()) for p in lives]
    print(f'{len(sites)} sites (install.asm Site EQUs):')
    for a, name, note in sites:
        zb = ' '.join(f'{z.mem.get(a + i, 0):02X}' for i in range(4))
        gb = ' '.join(f'{gs.mem.get(a + i, 0):02X}' for i in range(4))
        lv = ' | '.join(' '.join(f'{d[a + i]:02X}' for i in range(4)) for _, d in live)
        e = gs.entry_at(a)
        print(f'  ${a:04X} {name:18s} Z48 {zb} | block {gb} | live {lv} | {e["name"] if e else ""} ; {note}')
    print('stub areas (install.lst DISP blocks):')
    for a, lab, n in areas:
        e = gs.entry_at(a)
        same = [sum(1 for i in range(n) if d[a + i] != gs.mem.get(a + i)) for _, d in live]
        print(f'  ${a:04X}-${a + n - 1:04X} {n:4d} bytes {lab or "":20s} over {e["name"] if e else "(below the image)"}'
              f'; live bytes that differ from the block: {same}')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--summary', action='store_true')
    p.add_argument('--runs', action='store_true')
    p.add_argument('--show', nargs='+')
    p.add_argument('--installer', action='store_true')
    p.add_argument('--live', nargs='+', default=[os.path.join(GS, 'work/zgsA/r1-play/start.bin')])
    p.add_argument('--gap', type=int, default=8)
    p.add_argument('--json')
    a = p.parse_args()
    z, gs = Case('Z48'), Case('GS')
    cls = classify(z, gs)
    if a.summary or not (a.runs or a.show or a.json or a.installer):
        summary(z, gs, cls, a.gap)
    if a.runs:
        show_runs(z, gs, a.gap)
    if a.show:
        show(z, gs, a.show)
    if a.installer:
        installer(z, gs, a.live)
    if a.json:
        per, gsmod = module_table(z, gs, cls)
        out = dict(classes={f'{k:04X}': v for k, v in cls.items()},
                   runs=[dict(lo=s, hi=e, z48=names_over(z, s, e), gs=names_over(gs, s, e),
                              z48_bytes=[z.mem[x] for x in range(s, e)], gs_bytes=[gs.mem[x] for x in range(s, e)])
                         for s, e in runs_of(z.mem, gs.mem, LO, HI, a.gap)],
                   z48_modules={m: dict(d) for m, d in per.items()},
                   gs_modules={m: dict(d) for m, d in gsmod.items()})
        os.makedirs(os.path.dirname(os.path.abspath(a.json)), exist_ok=True)
        json.dump(out, open(a.json, 'w'), indent=1)
        print('wrote', a.json)


if __name__ == '__main__':
    sys.exit(main())

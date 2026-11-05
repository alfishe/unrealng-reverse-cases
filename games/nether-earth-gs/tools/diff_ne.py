#!/usr/bin/env python3
"""The game image of Nether Earth GS against Nether Earth's, byte by byte and entry by entry, from both cases' builds
(doc 13).

  diff_ne.py --summary                       the totals, the runs with both cases' names, the modules
  diff_ne.py --runs [--gap N]                every differing run: both entries, both listings side by side
  diff_ne.py --show NAME [NAME ...]          one entry of either case (a name or $ADDR), both listings side by side
  diff_ne.py --tape                          the disk's neart001 against the tape's (the two targets)
  diff_ne.py --json OUT.json                 the classes of every byte, the runs and the modules, for the figures
  diff_ne.py --ne-sym OUT.sym                NE's labels from its listing, for tools/l1_table.py --sym on NE's L1

Reads only the builds (run each case's tools/build.sh first):
  GS  build/game/neart001-scl.bin ($6590-$FFFF), build/game/game-scl.lst, src/game/game.ann
      build/game/neart001-tap.bin, game-tap.lst for --tape
  NE  games/nether-earth/build/game.bin ($5B00-$FCE8), build/game.lst, src/game/game.ann

Both images put the game at the same addresses, so the bytes are compared address by address; nothing is masked
and nothing is paired by name. An entry is a game.ann line `$ADDR kind Name`; it runs to the next entry. Its module
is the listing file its label is defined in (`# file opened`). Each byte of $5B00-$FFFF is in one class:

  same       in both images, the same byte
  differ     in both images, another byte
  ne-only    in NE's image only ($5B00-$658F: the view buffer GS's file does not load; GS's loader lies there)
  gs-only    in GS's file only ($FCE9-$FFFF: GS's file carries the work space NE builds at run time)
"""

import argparse
import json
import os
import re
import sys
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
GS = os.path.normpath(os.path.join(HERE, '..'))
NE = os.path.normpath(os.path.join(GS, '..', 'nether-earth'))

CASES = {
    'NE': dict(root=NE, bin='build/game.bin', org=0x5B00, lst='build/game.lst', ann='src/game/game.ann'),
    'GS': dict(root=GS, bin='build/game/neart001-scl.bin', org=0x6590, lst='build/game/game-scl.lst',
               ann='src/game/game.ann'),
    'TAP': dict(root=GS, bin='build/game/neart001-tap.bin', org=0x6590, lst='build/game/game-tap.lst',
                ann='src/game/game.ann'),
}

ENTRY = re.compile(r'^\$([0-9A-F]{4}) ([cbwts]) (\S+)(?:\s+\d+)?\s*(?:;\s*(.*))?$')
LST = re.compile(r'^\s*(\d+)\+?\s+([0-9A-F]{4})(?=\s|$)')


class Case:
    def __init__(self, tag):
        c = CASES[tag]
        self.tag = tag
        self.org = c['org']
        data = open(os.path.join(c['root'], c['bin']), 'rb').read()
        self.mem = {self.org + i: b for i, b in enumerate(data)}
        self.lo, self.hi = self.org, self.org + len(data)
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
        """the listing line whose bytes cover addr: (start, line, bytes, source)"""
        for a in range(addr, max(addr - 4, 0) - 1, -1):
            for n, code, src in self.lines.get(a, []):
                if a <= addr < a + len(code):
                    return a, n, code, src
        return None


def classify(ne, gs):
    cls = {}
    for a in range(0x5B00, 0x10000):
        inn, ing = a in ne.mem, a in gs.mem
        if inn and ing:
            cls[a] = 'same' if ne.mem[a] == gs.mem[a] else 'differ'
        elif inn:
            cls[a] = 'ne-only'
        elif ing:
            cls[a] = 'gs-only'
    return cls


def runs_of(a_mem, b_mem, lo, hi, gap):
    out = []
    for x in range(lo, hi):
        if x in a_mem and x in b_mem and a_mem[x] != b_mem[x]:
            if out and x - out[-1][1] <= gap:
                out[-1][1] = x + 1
            else:
                out.append([x, x + 1])
    return out


def side_by_side(ne, gs, lo, hi, width=60):
    """both listings' instructions over lo..hi, aligned by address; '*' where the bytes differ"""
    addrs = sorted({s for c in (ne, gs) for s, ls in c.lines.items() if lo <= s < hi} |
                   {i[0] for c in (ne, gs) for i in [c.instr_at(lo)] if i})
    rows = []
    for a in addrs:
        left = [(n, code, src) for n, code, src in ne.lines.get(a, [])]
        right = [(n, code, src) for n, code, src in gs.lines.get(a, [])]
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


def module_table(ne, gs, cls):
    """bytes of each NE module (its entries inside both images) by class, and the GS-only entries by GS module"""
    per = OrderedDict()
    for e in ne.entries:
        d = per.setdefault(e['module'], Counter())
        for a in range(e['addr'], min(e['end'], 0x10000)):
            if a in ne.mem:
                d[cls[a]] += 1
    gsmod = OrderedDict()
    for e in gs.entries:
        d = gsmod.setdefault(e['module'], Counter())
        for a in range(e['addr'], min(e['end'], 0x10000)):
            if a in gs.mem:
                d[cls[a]] += 1
    return per, gsmod


def entry_status(ne, gs):
    """each entry of either case at its address: same / changed / ne-only / gs-only, with its differing bytes"""
    rows = []
    gs_at = {e['addr']: e for e in gs.entries}
    ne_at = {e['addr']: e for e in ne.entries}
    for e in ne.entries:
        x = gs_at.get(e['addr'])
        rng = [a for a in range(e['addr'], e['end']) if a in ne.mem and a in gs.mem]
        diff = sum(1 for a in rng if ne.mem[a] != gs.mem[a])
        if not rng:
            st = 'ne-only'
        elif x and x['end'] == e['end']:
            st = 'same' if not diff else 'changed'
        else:
            st = 'same' if not diff else 'changed'
            st += '/split' if x is None or x['end'] != e['end'] else ''
        rows.append(dict(ne=e['name'], gs=x['name'] if x else None, addr=e['addr'], end=e['end'], status=st,
                         diff=diff, module=e['module']))
    for x in gs.entries:
        if x['addr'] not in ne_at:
            rng = [a for a in range(x['addr'], x['end']) if a in ne.mem and a in gs.mem]
            diff = sum(1 for a in rng if ne.mem[a] != gs.mem[a])
            st = 'gs-only' if not rng else ('gs-split' + ('' if not diff else '/changed'))
            rows.append(dict(ne=None, gs=x['name'], addr=x['addr'], end=x['end'], status=st, diff=diff,
                             module=x['module']))
    return sorted(rows, key=lambda r: (r['addr'], r['ne'] is None))


def names_over(case, lo, hi):
    out = []
    for e in case.entries:
        if e['addr'] < hi and e['end'] > lo:
            out.append(f"{e['name']} ${e['addr']:04X}")
    return out


def summary(ne, gs, cls, gap):
    lo, hi = max(ne.lo, gs.lo), min(ne.hi, gs.hi)
    common = hi - lo
    n = Counter(cls[a] for a in range(lo, hi))
    print(f'common range ${lo:04X}-${hi - 1:04X}: {common} bytes, {n["same"]} the same ({100 * n["same"] / common:.2f} %),'
          f' {n["differ"]} differ')
    allc = Counter(cls.values())
    print(f'NE image ${ne.lo:04X}-${ne.hi - 1:04X} ({ne.hi - ne.lo} bytes): {allc["ne-only"]} not in the GS file')
    print(f'GS file  ${gs.lo:04X}-${gs.hi - 1:04X} ({gs.hi - gs.lo} bytes): {allc["gs-only"]} not in the NE image')
    runs = runs_of(ne.mem, gs.mem, lo, hi, gap)
    print(f'{len(runs)} runs (gap {gap}):')
    for s, e in runs:
        d = sum(1 for a in range(s, e) if ne.mem[a] != gs.mem[a])
        print(f'  ${s:04X}-${e - 1:04X} {e - s:3d} bytes, {d:3d} differ | NE: {", ".join(names_over(ne, s, e))}'
              f' | GS: {", ".join(names_over(gs, s, e))}')
    st = entry_status(ne, gs)
    c = Counter(r['status'] for r in st)
    print(f'entries: NE {len(ne.entries)}, GS {len(gs.entries)}; status {dict(c)}')
    for r in st:
        if r['status'] != 'same':
            print(f"  {r['status']:16s} ${r['addr']:04X}-${r['end'] - 1:04X} NE {r['ne']} / GS {r['gs']} "
                  f"({r['diff']} bytes differ) [{r['module']}]")
    per, gsmod = module_table(ne, gs, cls)
    print('NE modules (bytes of their entries in each class):')
    for m, d in per.items():
        print(f'  {m:13s} {sum(d.values()):6d}  ' + ', '.join(f'{k} {v}' for k, v in sorted(d.items())))
    print('GS modules:')
    for m, d in gsmod.items():
        print(f'  {m:13s} {sum(d.values()):6d}  ' + ', '.join(f'{k} {v}' for k, v in sorted(d.items())))


def show_runs(ne, gs, gap):
    lo, hi = max(ne.lo, gs.lo), min(ne.hi, gs.hi)
    for s, e in runs_of(ne.mem, gs.mem, lo, hi, gap):
        print(f'=== ${s:04X}-${e - 1:04X}   NE: {", ".join(names_over(ne, s, e))}   GS: {", ".join(names_over(gs, s, e))}')
        print(f'{"NE  line addr bytes":60s}   GS  line addr bytes')
        for row in side_by_side(ne, gs, s, e):
            print(row)


def show(ne, gs, names):
    for name in names:
        e = None
        for c in (ne, gs):
            if name.startswith('$'):
                e = c.entry_at(int(name[1:], 16))
            else:
                e = c.by_name.get(name)
            if e:
                break
        if not e:
            print('no entry', name)
            continue
        print(f'=== {name}: ${e["addr"]:04X}-${e["end"] - 1:04X}   NE: {", ".join(names_over(ne, e["addr"], e["end"]))}'
              f'   GS: {", ".join(names_over(gs, e["addr"], e["end"]))}')
        for row in side_by_side(ne, gs, e['addr'], e['end']):
            print(row)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--summary', action='store_true')
    p.add_argument('--runs', action='store_true')
    p.add_argument('--show', nargs='+')
    p.add_argument('--tape', action='store_true')
    p.add_argument('--gap', type=int, default=8)
    p.add_argument('--json')
    p.add_argument('--ne-sym', help='write NE\'s labels from its listing as a .sym (Name: EQU 0xADDR) and stop')
    a = p.parse_args()
    if a.ne_sym:
        ne = Case('NE')
        os.makedirs(os.path.dirname(os.path.abspath(a.ne_sym)), exist_ok=True)
        with open(a.ne_sym, 'w') as f:
            for name, addr in sorted(ne.labels.items(), key=lambda kv: (kv[1], kv[0])):
                f.write(f'{name}: EQU 0x{addr:04X}\n')
        print('wrote', a.ne_sym, len(ne.labels), 'labels')
        return
    if a.tape:
        disk, tape = Case('GS'), Case('TAP')
        for s, e in runs_of(disk.mem, tape.mem, disk.lo, disk.hi, 0):
            print(f'=== ${s:04X}: {", ".join(names_over(disk, s, e))}')
            for row in side_by_side(disk, tape, s, e):
                print(row)
        return
    ne, gs = Case('NE'), Case('GS')
    cls = classify(ne, gs)
    if a.summary or not (a.runs or a.show or a.json):
        summary(ne, gs, cls, a.gap)
    if a.runs:
        show_runs(ne, gs, a.gap)
    if a.show:
        show(ne, gs, a.show)
    if a.json:
        lo, hi = max(ne.lo, gs.lo), min(ne.hi, gs.hi)
        per, gsmod = module_table(ne, gs, cls)
        out = dict(classes={f'{k:04X}': v for k, v in cls.items()},
                   runs=[dict(lo=s, hi=e, ne=names_over(ne, s, e), gs=names_over(gs, s, e),
                              ne_bytes=[ne.mem[x] for x in range(s, e)], gs_bytes=[gs.mem[x] for x in range(s, e)])
                         for s, e in runs_of(ne.mem, gs.mem, lo, hi, a.gap)],
                   ne_modules={m: dict(d) for m, d in per.items()},
                   gs_modules={m: dict(d) for m, d in gsmod.items()},
                   entries=entry_status(ne, gs))
        os.makedirs(os.path.dirname(os.path.abspath(a.json)), exist_ok=True)
        json.dump(out, open(a.json, 'w'), indent=1)
        print('wrote', a.json)


if __name__ == '__main__':
    sys.exit(main())

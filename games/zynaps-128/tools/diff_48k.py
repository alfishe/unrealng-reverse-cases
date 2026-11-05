#!/usr/bin/env python3
"""The game image of Zynaps 2 in 1 against the 48K Zynaps's, byte by byte and entry by entry, from both cases' builds
(docs/13-differences-from-zynaps-48k.md). Adapted from games/nether-earth-gs/tools/diff_ne.py.

  diff_48k.py --summary                  the totals, the 11 changed places with both cases' names, the modules
  diff_48k.py --runs                     every changed place, both listings side by side
  diff_48k.py --patches                  what block 2's set-up writes into the game at load (the 128K path, options
                                         off): the game at its entry against the image as moved
  diff_48k.py --show NAME [NAME ...]     one entry (a name or $ADDR), both listings side by side
  diff_48k.py --json OUT.json            the classes of every byte, the places and the patches, for the figures

Reads:
  48K  ../zynaps/build/game.bin ($61A8-$FFFE), build/game.lst, src/game/game.ann (run its tools/build.sh first)
  128  build/obj/game.bin ($6800-$FFFF: the game as block 2's set-up moves it), build/lst/game.lst,
       src/game/game.ann; for --patches work/images/game-entry-cpu.bin (c1 at JP $8000, tools/ttd_dump.py) and
       src/game/setup.ann (the names of the patched sites)

Both images put the game at the same addresses, so the bytes are compared address by address. Each byte of
$61A8-$FFFF is in one class:

  same       in both images, the same byte
  changed    in both images, another byte (the 2018 edit: keys, delays)
  zeroed     in both images, a leftover of the 48K tape that the 2 in 1 holds as 0 (the IF1 routine, the font rest)
  48k-only   in the 48K image only ($61A8-$67FF: zeros the 48K's Start fills; block 2 does not carry them)
  128-only   in the 2 in 1 only ($FFFF: past the 48K tape's last byte)
"""

import argparse
import json
import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.normpath(os.path.join(HERE, '..'))
Z48 = os.path.normpath(os.path.join(C, '..', 'zynaps'))

CASES = {
    '48K': dict(root=Z48, bin='build/game.bin', org=0x61A8, lst='build/game.lst', ann='src/game/game.ann'),
    '128': dict(root=C, bin='build/obj/game.bin', org=0x6800, lst='build/lst/game.lst', ann='src/game/game.ann'),
}
ENTRY_IMAGE = os.path.join(C, 'work/images/game-entry-cpu.bin')
SETUP_ANN = os.path.join(C, 'src/game/setup.ann')
GLUE_ANN = os.path.join(C, 'src/game/glue.ann')

ENTRY = re.compile(r'^\$([0-9A-F]{4}) ([cbwts]) (\S+)(?:\s+\d+)?\s*(?:;\s*(.*))?$')
LABEL = re.compile(r'^\$([0-9A-F]{4}) (?![cbwts] )(\w+)\s*(?:;\s*(.*))?$')
LST = re.compile(r'^\s*(\d+)\+?\s+([0-9A-F]{4})(?=\s|$)')

# the eleven places, in address order, with what they are (both .ann agree on the names; the text is the 2018 edit)
PLACES = [
    (0x8188, 0x8191, 'KeyTable', 'the default keys: P L SS A S -> SPACE Q A O P'),
    (0x86B7, 0x86B7, 'RowStar (RowPadGlyph)', 'the row padding per missing glyph: 10 -> 12 DJNZ'),
    (0x8C15, 0x8C15, 'ScrollStep (ScrollPad)', 'the scroll step padding: $13 -> $14 DJNZ'),
    (0xA538, 0xA538, 'MenuRasterInterrupt', 'the wait for the beam: $3D -> $4D rounds'),
    (0xA545, 0xA545, 'MenuRasterInterrupt', 'and a little more: $10 -> $17 DJNZ'),
    (0xA568, 0xA570, 'MenuRasterInterrupt', 'the line loop: 12 T longer (LD B,(HL) x 2, NOP x 2, JR NZ)'),
    (0xAA68, 0xAA68, 'PlayInterrupt', 'phase 1 wait: 2 -> $0B rounds (scroll on; $26 -> $2F off)'),
    (0xAA7B, 0xAA7B, 'PlayInterrupt (PlayInterruptPhase)', 'phases 2-4 wait: 5 -> $10 rounds'),
    (0xAA8D, 0xAA8D, 'PlayInterrupt', 'the wait before the playfield: $10 -> $77 DJNZ'),
    (0xFDE8, 0xFE4A, 'ScriptStack / VectorTable', 'the IF1 RS-232 download routine of the mastering machine: zeroed'),
    (0xFFD9, 0xFFFF, 'WorkGlyph / ColumnFlags', "the ROM font's 'Q'-'U' left by the 48K load: zeroed ($FFFF: $73)"),
]


class Case:
    def __init__(self, tag, data=None):
        c = CASES[tag]
        self.tag = tag
        self.org = c['org']
        if data is None:
            data = open(os.path.join(c['root'], c['bin']), 'rb').read()
        self.mem = {self.org + i: b for i, b in enumerate(data)}
        self.lo, self.hi = self.org, self.org + len(data)
        self.read_lst(os.path.join(c['root'], c['lst']))
        self.read_ann(os.path.join(c['root'], c['ann']))

    def read_lst(self, path):
        self.lines, self.file_of, self.label_file, files = {}, {}, {}, ['game.asm']
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
            lab = re.match(r'([A-Za-z_]\w*):', src)
            if lab:
                self.label_file.setdefault(lab.group(1), os.path.basename(files[-1]))
            if code:
                self.file_of[addr] = os.path.basename(files[-1])
                self.lines.setdefault(addr, []).append((n, code, src.strip()))

    def read_ann(self, path):
        self.entries, self.labels = [], {}
        for line in open(path, encoding='utf-8'):
            line = line.rstrip('\n')
            m = ENTRY.match(line)
            if m:
                self.entries.append(dict(addr=int(m.group(1), 16), kind=m.group(2), name=m.group(3),
                                         title=(m.group(4) or '').strip()))
                continue
            m = LABEL.match(line)
            if m:
                self.labels[int(m.group(1), 16)] = m.group(2)
        self.entries.sort(key=lambda e: e['addr'])
        for i, e in enumerate(self.entries):
            e['end'] = self.entries[i + 1]['addr'] if i + 1 < len(self.entries) else 0x10000
            e['module'] = self.label_file.get(e['name'], '?').replace('.asm', '')
        self.by_name = {e['name']: e for e in self.entries}

    def entry_at(self, addr):
        for e in self.entries:
            if e['addr'] <= addr < e['end']:
                return e
        return None

    def instr_at(self, addr):
        for a in range(addr, max(addr - 4, 0) - 1, -1):
            for n, code, src in self.lines.get(a, []):
                if a <= addr < a + len(code):
                    return a, n, code, src
        return None


def classify(a48, a128):
    cls = {}
    zeroed = [(lo, hi) for lo, hi, _, what in PLACES if 'zeroed' in what]
    for a in range(0x61A8, 0x10000):
        i48, i128 = a in a48.mem, a in a128.mem
        if i48 and i128:
            if a48.mem[a] == a128.mem[a]:
                cls[a] = 'same'
            else:
                cls[a] = 'zeroed' if any(lo <= a <= hi for lo, hi in zeroed) else 'changed'
        elif i48:
            cls[a] = '48k-only'
        elif i128:
            cls[a] = '128-only'
    return cls


def place_of(a):
    for i, (lo, hi, _, _) in enumerate(PLACES):
        if lo <= a <= hi:
            return i
    return None


def check_places(a48, a128):
    """every differing byte is inside one of the eleven places, and every place holds one"""
    stray = [a for a in range(0x6800, a48.hi) if a48.mem[a] != a128.mem[a] and place_of(a) is None]
    if stray:
        raise SystemExit('bytes outside the places: ' + ' '.join(f'${a:04X}' for a in stray))
    for lo, hi, name, _ in PLACES:
        if not any(a48.mem.get(a, 0) != a128.mem[a] for a in range(lo, hi + 1)):
            raise SystemExit(f'place ${lo:04X} {name}: no byte differs')


def listing_rows(case, lo, hi):
    """the listing lines assembling bytes in lo..hi (whole instructions)"""
    rows, a = [], lo
    first = case.instr_at(lo)
    if first:
        a = first[0]
    while a <= hi:
        got = case.lines.get(a)
        if not got:
            a += 1
            continue
        n, code, src = got[0]
        rows.append((a, code, src))
        a += len(code)
    return rows


def side_by_side(a48, a128, lo, hi, width=58):
    left = listing_rows(a48, lo, hi)
    right = listing_rows(a128, lo, hi)
    out = []
    for k in range(max(len(left), len(right))):
        cells = []
        for rows in (left, right):
            if k < len(rows):
                a, code, src = rows[k]
                src = re.sub(r'\s+;.*$', '', src)
                cells.append(f'${a:04X} {" ".join(f"{b:02X}" for b in code):<11} {src}'[:width])
            else:
                cells.append('')
        mark = ' ' if cells[0][6:17] == cells[1][6:17] else '|'
        out.append(f'{cells[0]:<{width}} {mark} {cells[1]}')
    return out


def patches(a128):
    """the bytes block 2's set-up changed in the game between the move and JP $8000 (c1, options off)"""
    img = open(ENTRY_IMAGE, 'rb').read()
    consts = {}
    for path in (SETUP_ANN, GLUE_ANN):
        for line in open(path, encoding='utf-8'):
            m = (re.match(r'@const (\w+) \$([0-9A-F]{4})\s*;\s*(.*)', line) or
                 re.match(r'@equ \$([0-9A-F]{4}) (\w+)(?: \d+)?\s*;\s*(.*)', line))
            if m:
                name, addr = (m.group(1), m.group(2)) if line.startswith('@const') else (m.group(2), m.group(1))
                consts.setdefault(int(addr, 16), (name, m.group(3)))
    runs = []
    for a in range(0x6800, 0x10000):
        if img[a] != a128.mem[a]:
            if runs and a - runs[-1][1] <= 2:
                runs[-1][1] = a
            else:
                runs.append([a, a])
    out = []
    for lo, hi in runs:
        site = next(((n, t) for c, (n, t) in consts.items() if c - 1 <= lo <= c + 2 or lo <= c <= hi), ('', ''))
        e = a128.entry_at(lo)
        out.append(dict(lo=lo, hi=hi, n=sum(img[a] != a128.mem[a] for a in range(lo, hi + 1)), old=bytes(a128.mem[a] for a in range(lo, hi + 1)).hex(' ').upper(),
                        new=img[lo:hi + 1].hex(' ').upper(), entry=e['name'] if e else '', site=site[0],
                        what=site[1]))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--summary', action='store_true')
    ap.add_argument('--runs', action='store_true')
    ap.add_argument('--patches', action='store_true')
    ap.add_argument('--show', nargs='+')
    ap.add_argument('--json')
    a = ap.parse_args()
    a48, a128 = Case('48K'), Case('128')
    check_places(a48, a128)
    cls = classify(a48, a128)
    n = Counter(cls.values())
    common = n['same'] + n['changed'] + n['zeroed']
    if a.summary or not (a.runs or a.patches or a.show or a.json):
        print(f'48K image ${a48.lo:04X}-${a48.hi - 1:04X} ({a48.hi - a48.lo} bytes), '
              f'2 in 1 ${a128.lo:04X}-${a128.hi - 1:04X} ({a128.hi - a128.lo} bytes)')
        print(f'common ${a128.lo:04X}-${a48.hi - 1:04X}: {common} bytes, same {n["same"]} '
              f'({100 * n["same"] / common:.2f} %), changed {n["changed"]}, zeroed {n["zeroed"]}; '
              f'48K only {n["48k-only"]}, 2 in 1 only {n["128-only"]} ($FFFF = ${a128.mem[0xFFFF]:02X})')
        print()
        print('| # | Where | 48K entry | 2 in 1 entry | Module | Bytes | What |')
        print('| ---: | --- | --- | --- | --- | ---: | --- |')
        for i, (lo, hi, name, what) in enumerate(PLACES, 1):
            e48, e128 = a48.entry_at(lo), a128.entry_at(lo)
            nb = sum(a48.mem.get(x) != a128.mem[x] for x in range(lo, hi + 1))
            where = f'`${lo:04X}`' + (f'-`${hi:04X}`' if hi != lo else '')
            print(f'| {i} | {where} | {e48["name"]} | {e128["name"]} | {e128["module"]} | {nb} | {what} |')
        mods = Counter(a128.entry_at(x)['module'] for x in range(0x6800, 0x10000)
                       if cls.get(x) in ('changed', 'zeroed', '128-only'))
        allmods = sorted({e['module'] for e in a128.entries})
        print(f'\nmodules with a changed byte: {len(mods)} of {len(allmods)}: '
              + ', '.join(f'{m} {k}' for m, k in sorted(mods.items())))
    if a.runs:
        for i, (lo, hi, name, what) in enumerate(PLACES, 1):
            print(f'\n{i}. ${lo:04X}-${hi:04X} {name}: {what}')
            if hi - lo > 16:
                print(f'   48K: {bytes(a48.mem[x] for x in range(lo, min(hi, a48.hi - 1) + 1))[:24].hex(" ").upper()} ...')
                print(f'   128: {bytes(a128.mem[x] for x in range(lo, hi + 1))[:24].hex(" ").upper()} ...')
                continue
            print(f'{"48K (../zynaps build/game.lst)":<58}   2 in 1 (build/lst/game.lst)')
            for row in side_by_side(a48, a128, lo, hi):
                print(row)
    if a.patches:
        p = patches(a128)
        print(f'{sum(x["n"] for x in p)} bytes in {len(p)} runs written by the set-up (c1, options off)')
        print('| Where | Entry | Was | Now | Site (setup.ann, glue.ann) |')
        print('| --- | --- | --- | --- | --- |')
        for x in p:
            if x['lo'] == 0xB30C:
                x['site'] = 'BeeperPlay; HookSound and the 15 hooks from $B30D'
            old = x['old'] if len(x['old']) <= 36 else x['old'][:33] + '...'
            new = x['new'] if len(x['new']) <= 36 else x['new'][:33] + '...'
            print(f'| `${x["lo"]:04X}` | {x["entry"]} | `{old}` | `{new}` | {x["site"]} |')
    if a.show:
        for name in a.show:
            e = (a128.by_name.get(name) or a48.by_name.get(name) or
                 a128.entry_at(int(name.lstrip('$'), 16)))
            print(f'\n{e["name"]} ${e["addr"]:04X}-${e["end"] - 1:04X}')
            for row in side_by_side(a48, a128, e['addr'], e['end'] - 1):
                print(row)
    if a.json:
        json.dump(dict(classes={f'{k:04X}': v for k, v in cls.items() if v != 'same'}, counts=dict(n),
                       places=[dict(lo=lo, hi=hi, name=nm, what=w) for lo, hi, nm, w in PLACES],
                       patches=patches(a128) if os.path.exists(ENTRY_IMAGE) else []),
                  open(a.json, 'w'), indent=1)
        print('wrote', a.json)


if __name__ == '__main__':
    main()

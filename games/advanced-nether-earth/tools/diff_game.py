#!/usr/bin/env python3
"""The game image of Advanced Nether Earth against Nether Earth's, entry by entry, from both cases' builds.

  diff_game.py [--tsv OUT.tsv] [--json OUT.json] [--summary]     the whole table
  diff_game.py --show NAME [NAME ...] [--context N]                two versions side by side

Reads only the two builds (run each case's tools/build.sh first):
  ANE  build/game/game-6731.bin ($6731-$D7D7), build/game/game.lst, src/game/game.ann
  NE   games/nether-earth/build/game.bin ($5B00-$FCE8), build/game.lst, src/game/game.ann

An entry is a game.ann line `$ADDR kind Name`; it runs to the next entry (or the image's end). The listing gives
each instruction's address, bytes and source text. Masking: a 16-bit operand (JP / CALL / LD rr,nn / LD (nn),r and
their prefixed forms, a DEFW word) is replaced by `nn` when the source writes it as a label expression, so code that
refers to moved data matches; a constant written as a number stays. JR / DJNZ offsets are relative and stay.

Each NE entry is paired with an ANE entry: the one that starts at the same address, else the one of the same name,
else the ANE entry whose masked bytes equal NE's anywhere in ANE's image. Status of a pair:

  same      same address, the same bytes
  operands  same address, the same masked bytes: only absolute operands differ (they point at moved things)
  moved     another address, the same masked bytes
  changed   paired, the masked bytes differ (diff = differing bytes at the same offsets, sim = difflib ratio over the
            masked instructions)
  ne-only   NE's entry has no counterpart in ANE's image (gone, or outside ANE's block: then `runtime` if ANE names
            the same address as an @equ variable)
  ane-only  ANE's entry pairs with no NE entry (new code or data)

--show prints, for each NAME (either case's name, or $ADDR), NE's and ANE's listing lines aligned on the masked
instructions: ` ` the same, `~` the same instruction with other absolute operands, `*` different, `-` / `+` only in
NE / ANE.
"""

import argparse
import difflib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ANE = os.path.normpath(os.path.join(HERE, '..'))
NE = os.path.normpath(os.path.join(ANE, '..', 'nether-earth'))

CASES = {
    'ANE': dict(root=ANE, bin='build/game/game-6731.bin', org=0x6731, lst='build/game/game.lst',
                ann='src/game/game.ann'),
    'NE': dict(root=NE, bin='build/game.bin', org=0x5B00, lst='build/game.lst', ann='src/game/game.ann'),
}

REGS = {'A', 'B', 'C', 'D', 'E', 'H', 'L', 'I', 'R', 'AF', "AF'", 'BC', 'DE', 'HL', 'SP', 'IX', 'IY', 'IXH', 'IXL',
        'IYH', 'IYL', 'NZ', 'Z', 'NC', 'PO', 'PE', 'P', 'M', 'HIGH', 'LOW'}
NN_PLAIN = {0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD} | {0xC2 + 8 * i for i in range(8)} | \
    {0xC4 + 8 * i for i in range(8)}
NN_ED = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}
NN_XY = {0x21, 0x22, 0x2A}
DATA = ('DEFB', 'DEFW', 'DEFS', 'DEFM', 'DB', 'DW', 'DS', 'DM', 'INCBIN', 'BLOCK', 'BYTE', 'WORD')


def nn_offset(code):
    """Where an instruction's 16-bit operand starts, or None"""
    if not code:
        return None
    op = code[0]
    if op in (0xDD, 0xFD) and len(code) >= 4 and code[1] in NN_XY:
        return 2
    if op == 0xED and len(code) >= 4 and code[1] in NN_ED:
        return 2
    if op in NN_PLAIN and len(code) >= 3:
        return 1
    return None


NUMBER = re.compile(r"\$[0-9A-Fa-f]+|#[0-9A-Fa-f]+|0x[0-9A-Fa-f]+|%[01]+|\b[0-9][0-9A-Fa-f]*[hH]?\b")


def has_label(operands):
    operands = re.sub(r'"[^"]*"|\'[^\']*\'', '', operands)
    operands = NUMBER.sub('', operands)
    for tok in re.findall(r"[A-Za-z_][A-Za-z0-9_']*", operands):
        if tok.upper() not in REGS:
            return True
    return False


def split_args(text):
    out, depth, cur, quote = [], 0, '', None
    for ch in text:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
        elif ch in '"\'':
            quote = ch
            cur += ch
        elif ch == '(':
            depth += 1
            cur += ch
        elif ch == ')':
            depth -= 1
            cur += ch
        elif ch == ',' and depth == 0:
            out.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def strip_comment(text):
    quote = None
    for i, ch in enumerate(text):
        if quote:
            if ch == quote:
                quote = None
        elif ch in '"\'':
            quote = ch
        elif ch == ';':
            return text[:i].rstrip(), text[i + 1:].strip()
    return text.rstrip(), ''


class Case:
    def __init__(self, tag):
        c = CASES[tag]
        self.tag = tag
        self.root = c['root']
        self.org = c['org']
        data = open(os.path.join(c['root'], c['bin']), 'rb').read()
        self.mem = {self.org + i: b for i, b in enumerate(data)}
        self.lo, self.hi = self.org, self.org + len(data)
        self.read_ann(os.path.join(c['root'], c['ann']))
        self.read_lst(os.path.join(c['root'], c['lst']))
        self.cut_entries()

    def read_ann(self, path):
        self.entries, self.equ, mod = [], {}, None
        for line in open(path, encoding='utf-8'):
            m = re.match(r'@module (\S+)', line)
            if m:
                mod = m.group(1)
            m = re.match(r'@equ \$([0-9A-Fa-f]{4}) (\S+)', line)
            if m:
                self.equ[int(m.group(1), 16)] = m.group(2)
            m = re.match(r'\$([0-9A-Fa-f]{4}) ([cbwts]) (\S+)(?:\s+\d+)?\s*(?:;\s*(.*))?$', line.rstrip('\n'))
            if m:
                self.entries.append(dict(addr=int(m.group(1), 16), kind=m.group(2), name=m.group(3), module=mod,
                                         title=(m.group(4) or '').strip()))
        self.entries.sort(key=lambda e: e['addr'])

    def read_lst(self, path):
        """Listing items: (addr, length, source text, file, line) for each line that emits bytes"""
        self.items, self.labels, self.label_file = [], {}, {}
        cur_file, last = None, None
        pat = re.compile(r'^\s*(\d+)(\+*)\s+([0-9A-F]{4}) ((?:[0-9A-F]{2}[ .]{1,3}){0,4})\s*(.*)$')
        for lst_line, raw in enumerate(open(path, encoding='utf-8', errors='replace'), 1):
            raw = raw.rstrip('\n')
            m = re.match(r'# file opened: (\S+)', raw)
            if m:
                cur_file = m.group(1)
                continue
            m = pat.match(raw)
            if not m:
                continue
            lineno, addr = int(m.group(1)), int(m.group(3), 16)
            col = m.end(3) + 1  # the bytes column: 12 characters after the address
            hexes, text = raw[col:col + 12], raw[col + 12:].strip()
            lm = re.match(r'([A-Za-z_][A-Za-z0-9_]*):', text)
            if lm:
                self.labels.setdefault(lm.group(1), addr)
                self.label_file.setdefault(lm.group(1), cur_file)
            n = len(re.findall(r'[0-9A-F]{2}', hexes))
            if not n and not re.match(r'INCBIN\b', text, re.I):
                continue
            if last and last['line'] == lineno and last['file'] == cur_file and not text:
                continue  # a continuation line of the same statement
            last = dict(addr=addr, text=text, file=cur_file, line=lineno, lst=lst_line)
            self.items.append(last)
        self.items.sort(key=lambda x: x['addr'])
        for i, it in enumerate(self.items):
            end = self.items[i + 1]['addr'] if i + 1 < len(self.items) else self.hi
            it['len'] = max(0, min(end, self.hi) - it['addr'])
            it['bytes'] = bytes(self.mem.get(a, 0) for a in range(it['addr'], it['addr'] + it['len']))
            it['mask'] = self.mask_of(it)

    def mask_of(self, it):
        """Byte offsets inside the item whose value is an absolute (label) operand"""
        code, (src, _) = it['bytes'], strip_comment(it['text'])
        word = src.split(None, 1)
        if not word:
            return set()
        mnem, ops = word[0].upper(), (word[1] if len(word) > 1 else '')
        if mnem in ('DEFW', 'DW', 'WORD'):
            out = set()
            for i, arg in enumerate(split_args(ops)):
                if has_label(arg):
                    out |= {2 * i, 2 * i + 1}
            return out
        if mnem in DATA:
            return set()
        k = nn_offset(code)
        if k is not None and has_label(ops):
            return {k, k + 1}
        return set()

    def cut_entries(self):
        es = [e for e in self.entries if self.lo <= e['addr'] < self.hi]
        stops = sorted({e['addr'] for e in es} | {a for a in self.equ if self.lo <= a < self.hi} | {self.hi})
        for e in es:
            e['end'] = next(a for a in stops if a > e['addr'])  # the next entry or @equ variable
            e['size'] = e['end'] - e['addr']
        for e in es:  # the module is the file the listing puts the entry's label in
            f = self.label_file.get(e['name'])
            if f:
                e['module'] = os.path.splitext(os.path.basename(f))[0]
        self.entries = es
        self.by_addr = {e['addr']: e for e in es}
        self.by_name = {e['name']: e for e in es}
        for e in es:
            e['items'] = [it for it in self.items if e['addr'] <= it['addr'] < e['end']]
            e['raw'] = bytes(self.mem[a] for a in range(e['addr'], e['end']))
            e['masked'] = masked(e)

    def entry_at(self, addr):
        for e in self.entries:
            if e['addr'] <= addr < e['end']:
                return e
        return None


def masked(e):
    """The entry's bytes with label operands as None"""
    flat = []
    for a in range(e['addr'], e['end']):
        it = next((x for x in e['items'] if x['addr'] <= a < x['addr'] + x['len']), None)
        flat.append(None if it and (a - it['addr']) in it['mask'] else e['raw'][a - e['addr']])
    return tuple(flat)


def key(it):
    """An instruction's shape: its bytes with any 16-bit operand blanked (for the alignment)"""
    k = nn_offset(it['bytes'])
    src = strip_comment(it['text'])[0].split(None, 1)
    if src and src[0].upper() in ('DEFW', 'DW'):
        return ('DW', len(it['bytes']))
    if k is None:
        return tuple(it['bytes'])
    return tuple(None if i in (k, k + 1) else b for i, b in enumerate(it['bytes']))


# NE's variables past its image that ANE moved, by the code that uses them: NE name -> ANE name. Witnesses: NE's Start
# ($A611 LD ($FDFD),A / $A617 LD (Handler),HL) and ANE's Restart ($A611 LD (ImJump),A / $A617 LD (ImHandler),HL) write
# the JP and its operand of the IM 2 jump in the same order at the same addresses.
ALIASES = {'Handler': 'ImHandler', 'Start': 'Restart'}


class Pairs:
    def __init__(self, ne, ane):
        self.ne, self.ane, self.map = ne, ane, dict(ALIASES)

    def resolve(self, case, v):
        for name, a in case.labels.items():
            if a == v and (name in case.by_name or name in case.equ.values()):
                return name, 0
        if v in case.equ:
            return case.equ[v], 0
        e = case.entry_at(v)
        if e:
            return e['name'], v - e['addr']
        for name, a in case.labels.items():
            if a == v:
                return name, 0
        return f'${v:04X}', 0

    def target(self, case, it):
        k = nn_offset(it['bytes'])
        if k is None:
            return None
        v = it['bytes'][k] | it['bytes'][k + 1] << 8
        n, off = self.resolve(case, v)
        return (n + (f'+{off}' if off else '')), n, off

    def correspond(self, x, y):
        tx, ty = self.target(self.ne, x), self.target(self.ane, y)
        if not tx or not ty:
            return False
        return tx[0] == ty[0] or (self.map.get(tx[1]) == ty[1] and tx[2] == ty[2])


def item_class(pairs, x, y):
    """same / relocated (a label operand, the corresponding target) / retargeted (another target) / different"""
    if x['bytes'] == y['bytes']:
        return 'same'
    if len(x['bytes']) != len(y['bytes']):
        return 'different'
    for k in range(len(x['bytes'])):
        if x['bytes'][k] != y['bytes'][k] and not (k in x['mask'] and k in y['mask']):
            return 'different'
    return 'relocated' if pairs.correspond(x, y) else 'retargeted'


def entry_class(pairs, e, a):
    """Two entries item by item: same / operands / retargeted / changed"""
    if e['raw'] == a['raw'] and e['addr'] == a['addr']:
        return 'same'
    if e['size'] != a['size'] or len(e['items']) != len(a['items']) or not e['items']:
        return 'changed'
    worst = 'same'
    for x, y in zip(e['items'], a['items']):
        c = item_class(pairs, x, y)
        if c == 'different':
            return 'changed'
        if c == 'retargeted' or (c == 'relocated' and worst == 'same'):
            worst = c
    return {'same': 'same' if e['addr'] == a['addr'] else 'moved', 'relocated': 'operands',
            'retargeted': 'retargeted'}[worst] if e['addr'] == a['addr'] or worst != 'retargeted' else 'changed'


def similarity(a, b):
    if a['kind'] != 'c' or b['kind'] != 'c' or not a['items'] or not b['items']:
        sa, sb = list(a['raw']), list(b['raw'])
    else:
        sa, sb = [repr(key(t)) for t in a['items']], [repr(key(t)) for t in b['items']]
    return difflib.SequenceMatcher(None, sa, sb, autojunk=False).ratio()


def compare(ne, ane):
    pairs = Pairs(ne, ane)
    rows, used = [], set()
    for e in ne.entries:
        a = ane.by_addr.get(e['addr'])
        if a is not None and a['name'] != e['name'] and (
                a['kind'] != e['kind'] or min(a['size'], e['size']) < max(a['size'], e['size']) / 4):
            a = None  # another kind of thing, or a sliver of it, now starts here
        if a is None and e['name'] in ane.by_name:
            a = ane.by_name[e['name']]
        if a is None and e['size'] >= 8:
            hits = [x for x in ane.entries if x['addr'] not in used and x['size'] == e['size']
                    and entry_class(pairs, e, x) in ('moved', 'operands')]
            a = hits[0] if hits else None
        if a is None:
            st = 'runtime' if e['addr'] in ane.equ or not (ane.lo <= e['addr'] < ane.hi) else 'ne-only'
            rows.append(dict(ne=e, ane=None, status=st, diff=e['size'], sim=0.0))
            continue
        used.add(a['addr'])
        rows.append(dict(ne=e, ane=a))
    # an NE routine left over against an ANE routine left over that overlaps it: the same place, rewritten
    for r in rows:
        e = r['ne']
        if r['ane'] is not None or r['status'] == 'runtime' or e['kind'] != 'c':
            continue
        cands = [a for a in ane.entries if a['addr'] not in used and a['kind'] == 'c'
                 and a['addr'] < e['end'] and e['addr'] < a['end']]
        best = max(cands, key=lambda a: similarity(e, a), default=None)
        if best is not None and similarity(e, best) >= 0.3:
            used.add(best['addr'])
            r['ane'] = best
            del r['status']
    for r in rows:
        if r['ane'] is not None:
            pairs.map.setdefault(r['ne']['name'], r['ane']['name'])
    for r in rows:
        if 'status' in r:
            continue
        e, a = r['ne'], r['ane']
        st = entry_class(pairs, e, a)
        if e['addr'] == a['addr']:
            diff = sum(1 for k in range(max(e['size'], a['size'])) if e['raw'][k:k + 1] != a['raw'][k:k + 1])
        else:
            diff = 0 if st == 'moved' else max(e['size'], a['size'])
        r.update(status=st, diff=diff if st != 'same' else 0,
                 sim=1.0 if st in ('same', 'operands', 'moved', 'retargeted') else similarity(e, a))
    for a in ane.entries:
        if a['addr'] not in used:
            rows.append(dict(ne=None, ane=a, status='ane-only', diff=a['size'], sim=0.0))
    rows.sort(key=lambda r: (r['ne'] or r['ane'])['addr'])
    compare.pairs = pairs
    return rows


def byte_map(ne, ane, rows):
    """Per CPU address $5B00-$FFFF: the class of the byte (for the figures)"""
    cls = {}
    for a in range(0x5B00, 0x10000):
        inn, ina = a in ne.mem, a in ane.mem
        if inn and ina:
            cls[a] = 'same' if ne.mem[a] == ane.mem[a] else 'changed'
        elif inn:
            cls[a] = 'ne-only'
        elif ina:
            cls[a] = 'ane-only'
    for r in rows:
        e, x = r['ne'], r['ane']
        if r['status'] in ('operands', 'retargeted'):
            for k in range(e['size']):
                if e['raw'][k] != x['raw'][k]:
                    cls[e['addr'] + k] = 'operand'
        elif r['status'] == 'ane-only' and x['addr'] not in ne.by_addr:
            for k in range(x['size']):
                if ne.mem.get(x['addr'] + k) != x['raw'][k]:
                    cls[x['addr'] + k] = 'new'
        elif r['status'] == 'runtime':
            for k in range(e['size']):
                if e['addr'] + k not in ane.mem:
                    cls[e['addr'] + k] = 'runtime'
    return cls


def name2(r):
    e, a = r['ne'], r['ane']
    n1 = e['name'] if e else '-'
    n2 = a['name'] if a else '-'
    return n1 if n1 == n2 else f'{n1} / {n2}'


def write_tsv(rows, path):
    with open(path, 'w') as f:
        f.write('ne_addr\tne_name\tne_module\tne_size\tane_addr\tane_name\tane_module\tane_size\tstatus\tdiff_bytes\tsim\n')
        for r in rows:
            e, a = r['ne'], r['ane']
            f.write('\t'.join([
                f"${e['addr']:04X}" if e else '', e['name'] if e else '', e['module'] if e else '',
                str(e['size']) if e else '',
                f"${a['addr']:04X}" if a else '', a['name'] if a else '', a['module'] if a else '',
                str(a['size']) if a else '', r['status'], str(r['diff']), f"{r['sim']:.2f}"]) + '\n')


def summary(rows, ne, ane, cls):
    from collections import Counter
    st = Counter(r['status'] for r in rows)
    print('entries:', len(ne.entries), 'NE,', len(ane.entries), 'ANE')
    for k in ('same', 'operands', 'retargeted', 'moved', 'changed', 'ne-only', 'runtime', 'ane-only'):
        print(f'  {k:9s} {st.get(k, 0):4d}')
    bc = Counter(cls.values())
    print('bytes $5B00-$FFFF:', dict(sorted(bc.items())))
    print('changed / moved / ne-only / ane-only entries:')
    for r in rows:
        if r['status'] in ('same', 'runtime'):
            continue
        e, a = r['ne'], r['ane']
        print(f"  {r['status']:8s} NE {('$%04X' % e['addr']) if e else '     '} {e['size'] if e else '':>5}"
              f"  ANE {('$%04X' % a['addr']) if a else '     '} {a['size'] if a else '':>5}"
              f"  diff {r['diff']:5d} sim {r['sim']:.2f}  {name2(r)}")


def module_bytes(rows, ne):
    """Per NE module: bytes in same / operand / changed / gone entries (NE's bytes)"""
    out = {}
    for r in rows:
        e = r['ne']
        if not e:
            continue
        d = out.setdefault(e['module'], dict(same=0, operand=0, moved=0, changed=0, gone=0, runtime=0))
        if r['status'] == 'same':
            d['same'] += e['size']
        elif r['status'] in ('operands', 'retargeted'):
            d['operand'] += r['diff']
            d['same'] += e['size'] - r['diff']
        elif r['status'] == 'moved':
            d['moved'] += e['size']
        elif r['status'] == 'changed':
            a = r['ane']
            n = min(e['size'], a['size'])
            same = sum(1 for k in range(n) if e['raw'][k] == a['raw'][k]) if a['addr'] == e['addr'] else 0
            d['same'] += same
            d['changed'] += e['size'] - same
        elif r['status'] == 'runtime':
            d['runtime'] += e['size']
        else:
            d['gone'] += e['size']
    return out


def show(ne, ane, rows, names, context):
    for name in names:
        hit = None
        for r in rows:
            for side in ('ne', 'ane'):
                x = r[side]
                if x and (x['name'] == name or name.upper() == f"${x['addr']:04X}"):
                    hit = r
                    break
            if hit:
                break
        if not hit:
            print(f'{name}: no such entry', file=sys.stderr)
            continue
        e, a = hit['ne'], hit['ane']
        print(f"== {name2(hit)}: {hit['status']}  NE {('$%04X' % e['addr'] + ' ' + e['module']) if e else '-'}"
              f"  ANE {('$%04X' % a['addr'] + ' ' + a['module']) if a else '-'}  diff {hit['diff']} sim {hit['sim']:.2f}")
        ti = e['items'] if e else []
        ui = a['items'] if a else []
        if e and a and e['addr'] == a['addr'] and e['end'] != a['end']:
            hi = max(e['end'], a['end'])  # one case cut the place into more entries: show the whole place
            ti = [it for it in ne.items if e['addr'] <= it['addr'] < hi]
            ui = [it for it in ane.items if a['addr'] <= it['addr'] < hi]
        sm = difflib.SequenceMatcher(None, [repr(key(t)) for t in ti], [repr(key(t)) for t in ui], autojunk=False)
        pairs = compare.pairs
        marks = {'same': ' ', 'relocated': '~', 'retargeted': '>', 'different': '*'}

        def fmt(it):
            src, com = strip_comment(it['text'])
            hx = ' '.join(f'{b:02X}' for b in it['bytes'][:4]) + (' ..' if it['len'] > 4 else '')
            return f"{it['lst']:5d} {it['addr']:04X} {hx:14s} {src[:32]:32s}"

        lines = []
        for op, i1, i2, j1, j2 in sm.get_opcodes():
            n = max(i2 - i1, j2 - j1)
            for k in range(n):
                x = ti[i1 + k] if i1 + k < i2 else None
                y = ui[j1 + k] if j1 + k < j2 else None
                if x and y:
                    mark = marks[item_class(pairs, x, y)]
                else:
                    mark = '-' if x else '+'
                lines.append((mark, fmt(x) if x else '', fmt(y) if y else ''))
        keep = set()
        for i, (m, _, _) in enumerate(lines):
            if m != ' ':
                keep |= set(range(i - context, i + context + 1))
        if context < 0:
            keep = set(range(len(lines)))
        last = -2
        print(f"  {'NE':60s}   ANE")
        for i, (m, l, r) in enumerate(lines):
            if i not in keep:
                continue
            if i != last + 1:
                print('  ...')
            print(f'{m} {l:60s} | {r}')
            last = i


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--tsv')
    p.add_argument('--json', help='per-byte classes and per-module byte counts, for the figures')
    p.add_argument('--summary', action='store_true')
    p.add_argument('--show', nargs='+')
    p.add_argument('--context', type=int, default=2, help='lines round each difference in --show (-1: all)')
    args = p.parse_args()
    ne, ane = Case('NE'), Case('ANE')
    rows = compare(ne, ane)
    if args.tsv:
        write_tsv(rows, args.tsv)
    cls = byte_map(ne, ane, rows)
    if args.json:
        runs, prev, start = [], None, None
        for a in range(0x5B00, 0x10001):
            c = cls.get(a, 'none') if a < 0x10000 else None
            if c != prev:
                if prev is not None:
                    runs.append([start, a - start, prev])
                prev, start = c, a
        json.dump(dict(runs=runs, modules=module_bytes(rows, ne),
                       ane_modules={m: sum(x['size'] for x in ane.entries if x['module'] == m)
                                    for m in dict.fromkeys(x['module'] for x in ane.entries)},
                       entries=[dict(ne=(r['ne']['addr'], r['ne']['name'], r['ne']['module'], r['ne']['size'])
                                     if r['ne'] else None,
                                     ane=(r['ane']['addr'], r['ane']['name'], r['ane']['module'], r['ane']['size'])
                                     if r['ane'] else None, status=r['status'], diff=r['diff'])
                                for r in rows]),
                  open(args.json, 'w'), indent=0)
    if args.summary:
        summary(rows, ne, ane, cls)
    if args.show:
        show(ne, ane, rows, args.show, args.context)


if __name__ == '__main__':
    main()

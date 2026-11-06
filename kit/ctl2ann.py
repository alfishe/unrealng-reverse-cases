#!/usr/bin/env python3
"""A first .ann from unreal-ng's L2 draft: the SkoolKit control file `re_session.py export` writes (draft/draft.ctl).

    python3 kit/ctl2ann.py work/<build>/draft [--out src/game/game.ann] [--lo ADDR --hi ADDR] [--module NAME]
                           [--names drop|keep|pascal] [--fields] [--force] [--case CASE [--config FILE]]

The argument is the draft folder or its draft.ctl. What the draft says becomes the .ann's lines
(docs/ann-format.md 1-2):

| draft.ctl | .ann |
| --- | --- |
| `c $ADDR title` (`b`, `t`, `w`, `s` alike; `g` and `u` as `b`, a `g` holding a `W` as `w`; `i` dropped) | `$ADDR c Name ; title` |
| `D $ADDR text` | `> text` under the entry |
| `@ $ADDR label=NAME` inside an entry | `$ADDR NAME` (an inner name; a dropped generic name is a cut only with --fields) |
| `N $ADDR text`, an instruction comment ` $ADDR,N text` | `$ADDR ; text` |
| `B $ADDR,N` sub-blocks of one entry, all N long | the entry's row width `N`; with --fields every sub-block start is also a cut `$ADDR` |
| `records of N bytes` in the title, sub-blocks of mixed length | the row width `N` |

--names: the draft's generic names (`data_5B00`, `sub_8000`, `L5B20`, `records_5B60`: a word, `_`, the address, or
L and the address) are dropped by default, so the generator names the entries by address until a person names them;
`keep` keeps them as they are, `pascal` writes them as `Data5B00`. A name the draft gives from evidence (any other) is
always kept. --lo / --hi keep only the entries inside the range (the game image of case.json; hex, --hi exclusive).
--module puts one `@module` (default `main`) before the first entry: split it into modules by hand.

--case reads the case's game the way kit/mkgame.py does (case.json: the image, lo..hi, the read_builds and
code_builds recordings, the walk) and makes a draft data entry `c` where that code starts: the draft comes from one
build, the case's code from all of them, and mkgame refuses an .ann whose data entry starts on code it ran. The output is a
start for the annotators: every name, title and description is the draft's guess until checked (recipes/05-source.md).
Without --out the .ann goes to stdout; an existing --out is not overwritten without --force.
"""
import argparse
import os
import re
import sys

ENTRY = re.compile(r'^([bcgistuw]) \$([0-9A-Fa-f]{4})(?:\s+(.*))?$')
SUB = re.compile(r'^([BCSTW]) \$([0-9A-Fa-f]{4}),(\d+)(?::\S+)?(?:\s+(.*))?$')
LABEL = re.compile(r'^@ \$([0-9A-Fa-f]{4}) label=(\S+)$')
TEXT = re.compile(r'^([DN]) \$([0-9A-Fa-f]{4})\s*(.*)$')
COMMENT = re.compile(r'^\s+\$([0-9A-Fa-f]{4}),\d+\s+(.*)$')
GENERIC = re.compile(r'^(?:[A-Za-z]+_[0-9A-Fa-f]{4}|[Ll][0-9A-Fa-f]{4})$')
KIND = {'c': 'c', 'b': 'b', 't': 't', 'w': 'w', 's': 's', 'g': 'b', 'u': 'b'}


def read_ctl(path):
    entries = {}     # address: {'kind', 'title', 'desc': [], 'subs': [(a, n, kind)]}
    labels, notes = {}, {}
    current = None
    skipped = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith(';') or line.startswith('#'):
            continue
        m = ENTRY.match(line)
        if m:
            kind, a = m.group(1), int(m.group(2), 16)
            if kind == 'i':
                current = None
                continue
            current = a
            entries[a] = {'kind': KIND[kind], 'draft_kind': kind, 'title': (m.group(3) or '').strip(), 'desc': [],
                          'subs': []}
            continue
        m = LABEL.match(line)
        if m:
            labels[int(m.group(1), 16)] = m.group(2)
            continue
        m = TEXT.match(line)
        if m:
            a = int(m.group(2), 16)
            if m.group(1) == 'D' and a in entries:
                entries[a]['desc'].append(m.group(3).strip())
            elif m.group(3).strip():
                notes.setdefault(a, []).append(m.group(3).strip())
            continue
        m = SUB.match(line)
        if m:
            if current is not None:
                entries[current]['subs'].append((int(m.group(2), 16), int(m.group(3)), m.group(1)))
            if m.group(4):
                notes.setdefault(int(m.group(2), 16), []).append(m.group(4).strip())
            continue
        m = COMMENT.match(line)
        if m:
            notes.setdefault(int(m.group(1), 16), []).append(m.group(2).strip())
            continue
        if line.startswith('@'):
            continue  # start, org, other asm directives: the generator writes its own
        skipped[line.split()[0]] = skipped.get(line.split()[0], 0) + 1
    return entries, labels, notes, skipped


def name_of(label, mode):
    if not label:
        return None
    if not GENERIC.match(label):
        return label
    if mode == 'keep':
        return label
    if mode == 'pascal':
        word, _, hexa = label.rpartition('_')
        return (word[:1].upper() + word[1:] + hexa.upper()) if word else 'L' + label[1:].upper()
    return None


def comment_text(parts):
    return ' '.join(p.replace(';', ',') for p in parts)


def convert(entries, labels, notes, lo, hi, names, fields, module):
    starts = sorted(a for a in entries if lo <= a < hi)
    out = []
    used = set()

    def unique(name):
        if not name or name in used:
            return None
        used.add(name)
        return name

    for i, a in enumerate(starts):
        e = entries[a]
        end = starts[i + 1] if i + 1 < len(starts) else hi
        if module and i == 0:
            out += ['@module %s' % module, '']
        kind = e['kind']
        subs = [s for s in e['subs'] if a <= s[0] < end]
        if e['draft_kind'] == 'g' and subs and all(s[2] == 'W' for s in subs):
            kind = 'w'
        width = None
        if kind == 'b' and subs:
            lengths = {n for _, n, _ in subs}
            if len(lengths) == 1 and 1 < next(iter(lengths)) <= 32:
                width = next(iter(lengths))
            else:
                m = re.search(r'records of (\d+) bytes', e['title'])
                if m and 1 < int(m.group(1)) <= 32:
                    width = int(m.group(1))
        name = unique(name_of(labels.get(a), names))
        if module and i == 0 and not name:  # a module starts at a named entry
            name = unique(name_of(labels.get(a), 'pascal') or 'Entry%04X' % a)
        line = '$%04X %s' % (a, kind)
        if name:
            line += ' ' + name
        if width:
            line += ' %d' % width
        if e['title']:
            line += ' ; ' + e['title']
        out.append(line)
        for d in e['desc']:
            out.append('> ' + d)
        inner = {}
        for x, n in labels.items():
            if a < x < end and (name_of(n, names) or fields):
                inner.setdefault(x, [None, []])[0] = unique(name_of(n, names))
        for x, texts in notes.items():
            if a <= x < end:
                inner.setdefault(x, [None, []])[1] += texts
        if fields:
            for x, _, _ in subs:
                if x != a:
                    inner.setdefault(x, [None, []])
        for x in sorted(inner):
            n, texts = inner[x]
            if x == a:
                if texts:  # a note on the entry's first byte: one more description line
                    out.append('> ' + comment_text(texts))
                continue
            row = '$%04X' % x + (' ' + n if n else '')
            if texts:
                row += ' ; ' + comment_text(texts)
            out.append(row)
        out.append('')
    return out, len(starts)


def with_case_code(entries, case, config_path):
    """the case's lo, hi; every draft data entry that starts on the case's code becomes a code entry"""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import mkgame as mk
    config = mk.load_case(case, config_path)
    mem = mk.original_image(config)
    sources = [mk.Source.parse(s, mk.ROOT, mk.READ_BUILDS) for s in mk.case_builds(config)]
    starts, _, reads = mk.read_sources(sources, mem, mk.LO, mk.HI, mk.BASES)
    while True:
        seeds = [a for a, e in entries.items() if e['kind'] == 'c' and mk.LO <= a < mk.HI]
        code = mk.walk(mem, starts, reads, seeds)[0]
        turned = [a for a, e in entries.items() if e['kind'] != 'c' and a in code]
        if not turned:
            return mk.LO, mk.HI
        for a in turned:
            e = entries[a]
            e['kind'], e['subs'] = 'c', []
            e['title'] = 'Code (the draft said: %s)' % e['title'] if e['title'] else 'Code'
        print(f'ctl2ann: {len(turned)} draft data entries start on the case\'s code: made code', file=sys.stderr)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('draft', help='the draft folder (re_session.py export) or its draft.ctl')
    p.add_argument('--out', help='the .ann to write (default: stdout)')
    p.add_argument('--lo', default='0000')
    p.add_argument('--hi', default='10000')
    p.add_argument('--module', default='main', help="the first @module's name ('' for none)")
    p.add_argument('--names', choices=('drop', 'keep', 'pascal'), default='drop')
    p.add_argument('--fields', action='store_true', help='cut the data rows at every sub-block of the draft')
    p.add_argument('--force', action='store_true', help='overwrite an existing --out')
    p.add_argument('--case', help="a case: its range, and its recordings' code wins over the draft's data")
    p.add_argument('--config', help='the case.json (default CASE/case.json)')
    args = p.parse_args()
    ctl = os.path.join(args.draft, 'draft.ctl') if os.path.isdir(args.draft) else args.draft
    entries, labels, notes, skipped = read_ctl(ctl)
    lo, hi = int(args.lo.lstrip('$'), 16), int(args.hi.lstrip('$'), 16)
    if args.case:
        lo, hi = with_case_code(entries, args.case, args.config)
    lines, count = convert(entries, labels, notes, lo, hi, args.names, args.fields, args.module)
    head = ['# A first .ann from %s (kit/ctl2ann.py): the L2 draft\'s entries, kinds, titles and descriptions.' % ctl,
            '# Every name, title and description below is the draft\'s guess until a recording or the code proves it.',
            '']
    text = '\n'.join(head + lines).rstrip() + '\n'
    if args.out:
        if os.path.exists(args.out) and not args.force:
            sys.exit(f'{args.out} exists: --force to overwrite it')
        open(args.out, 'w').write(text)
    else:
        sys.stdout.write(text)
    codes = sum(1 for a in entries if lo <= a < hi and entries[a]['kind'] == 'c')
    print(f'ctl2ann: {count} entries ({codes} code) from {ctl}'
          + ('; not read: ' + ', '.join(f'{k} x{n}' for k, n in sorted(skipped.items())) if skipped else ''),
          file=sys.stderr)


if __name__ == '__main__':
    main()

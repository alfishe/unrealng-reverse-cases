#!/usr/bin/env python3
"""Write docs/11-data-reference.md and docs/12-routine-reference.md from the source and the recordings.

    python3 tools/refdocs.py

Every entry of the game (work/mkgame/game.ctl, written by tools/mkgame.py) with its name, title and description from
src/game/game.ann; for code, what the recordings saw it do (work/p2/l1.json, the bot's game; work/game/l1.json, the
first recording from frame 2613 with the menu, the demo and a game): callers, callees, runs, own time, the memory it
reads and writes, its ports. For data, the routines that read and write it.
"""
import bisect
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import mkgame  # noqa: E402

BUILDS = [('p2', 'the bot game'), ('game', 'the first recording')]
LO, HI = mkgame.LO, mkgame.HI


def entries_of(ctl):
    """[(address, kind, label, title)] in address order"""
    out, label = [], {}
    for line in open(ctl):
        m = re.match(r'@ \$([0-9A-F]{4}) label=(\w+)', line)
        if m:
            label[int(m.group(1), 16)] = m.group(2)
            continue
        m = re.match(r'([cb]) \$([0-9A-F]{4}) (.*)', line)
        if m:
            a = int(m.group(2), 16)
            out.append((a, m.group(1), label.get(a, '$%04X' % a), m.group(3).strip()))
    return out


class Build:
    def __init__(self, key):
        doc = json.load(open(os.path.join(ROOT, 'work', key, 'l1.json')))
        self.total = doc['replay']['tstates']
        self.frames = (doc['replay']['first_frame'], doc['replay']['last_frame'])
        self.routines = [r for r in doc['routines'] if r['page'] in (0, 2, 5)]
        self.index = {i: r for i, r in enumerate(doc['routines'])}
        self.calls = doc['calls']


def ranges(items):
    return [(int(x['from'][1:], 16), int(x['to'][1:], 16), x['bytes']) for x in items if x['page'] in (0, 2, 5)]


def md(text):
    """Prose for GitHub: hex addresses in code spans (a bare $..$ pair is math there)"""
    parts = re.split(r'(`[^`]*`)', text)
    return ''.join(p if p.startswith('`') else re.sub(r'(\$[0-9A-Fa-f]{2,4}(?:-\$[0-9A-Fa-f]{2,4})?)', r'`\1`', p)
                   for p in parts)


def main():
    ctl = os.path.join(ROOT, 'work', 'mkgame', 'game.ctl')
    if not os.path.exists(ctl):
        sys.exit('run tools/mkgame.py first (it writes work/mkgame/game.ctl)')
    ann = mkgame.Annotations(os.path.join(ROOT, 'src', 'game', 'game.ann'))
    entries = entries_of(ctl)
    starts = [e[0] for e in entries]
    ends = {e[0]: (entries[i + 1][0] if i + 1 < len(entries) else HI) - 1 for i, e in enumerate(entries)}
    modules = sorted(ann.modules)
    mstarts = [m[0] for m in modules]

    def owner(a):
        i = bisect.bisect_right(starts, a) - 1
        return entries[i] if i >= 0 and LO <= a < HI else None

    def module(a):
        i = bisect.bisect_right(mstarts, a) - 1
        return modules[i][1] if i >= 0 else 'buffers'

    def ref(a):
        e = owner(a)
        if not e:
            return '`$%04X`' % a
        off = a - e[0]
        return '`%s`%s (`$%04X`)' % (e[2], ('+%d' % off) if off else '', a)

    def span(lo, hi):
        """A memory range as the entries it covers"""
        if hi < LO:
            area = 'screen' if 0x4000 <= lo < 0x5B00 else 'system'
            return '`$%04X`-`$%04X` (%s)' % (lo, hi, area)
        names = []
        a = max(lo, LO)
        while a <= hi:
            e = owner(a)
            names.append(e[2])
            a = ends[e[0]] + 1
        shown = ', '.join('`%s`' % n for n in names[:4]) + (' and %d more' % (len(names) - 4) if len(names) > 4 else '')
        return '`$%04X`-`$%04X` (%s)' % (lo, hi, shown)

    builds = {key: Build(key) for key, _ in BUILDS}
    # Per routine entry of the game: what each build saw
    seen = {}
    users = {}  # data entry -> {'reads': set(names), 'writes': set(names)}
    for key, _ in BUILDS:
        b = builds[key]
        for i, r in b.index.items():
            if r['page'] not in (0, 2, 5):
                continue
            a = int(r['entry'][1:], 16)
            e = owner(a)
            if not e or e[1] != 'c':
                continue
            s = seen.setdefault(e[0], {'callers': {}, 'callees': {}, 'runs': {}, 'reads': [], 'writes': [],
                                       'ports_in': set(), 'ports_out': set()})
            p = r['profile']
            runs = s['runs'].setdefault(key, [0, 0])
            runs[0] += p['entries'] if a == e[0] else 0
            runs[1] += p['tstates']
            s['reads'] += ranges(p['reads'])
            s['writes'] += ranges(p['writes'])
            s['ports_in'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_in'])
            s['ports_out'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_out'])
        for c in b.calls:
            ca, ce = b.index.get(c['caller']), b.index.get(c['callee'])
            if not ca or not ce or ca['page'] not in (0, 2, 5) or ce['page'] not in (0, 2, 5):
                continue
            oa, oe = owner(int(ca['entry'][1:], 16)), owner(int(ce['entry'][1:], 16))
            if not oa or not oe or oa[0] == oe[0]:
                continue
            seen.setdefault(oa[0], {'callers': {}, 'callees': {}, 'runs': {}, 'reads': [], 'writes': [],
                                    'ports_in': set(), 'ports_out': set()})
            seen.setdefault(oe[0], {'callers': {}, 'callees': {}, 'runs': {}, 'reads': [], 'writes': [],
                                    'ports_in': set(), 'ports_out': set()})
            seen[oa[0]]['callees'][oe[0]] = c['kind']
            seen[oe[0]]['callers'][oa[0]] = c['kind']
    for a, s in seen.items():
        name = owner(a)[2]
        for kind in ('reads', 'writes'):
            for lo, hi, _ in s[kind]:
                x = max(lo, LO)
                while x <= hi and x < HI:
                    e = owner(x)
                    if e[1] == 'b':
                        users.setdefault(e[0], {'reads': set(), 'writes': set()})[kind].add(name)
                    x = ends[e[0]] + 1

    def merged(rs):
        rs = sorted((lo, hi) for lo, hi, _ in rs)
        out = []
        for lo, hi in rs:
            if out and lo <= out[-1][1] + 16:
                out[-1][1] = max(out[-1][1], hi)
            else:
                out.append([lo, hi])
        return out

    def description(a):
        return '\n\n'.join(md(t) for t in ann.descriptions.get(a, []))

    # Doc 12: the routines
    out = ['# 12. Routine reference', '',
           'Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and',
           'the description are the source\'s (`src/game/game.ann`); the rest is what the recordings saw: '
           + ', '.join(f'`work/{k}` ({t})' for k, t in BUILDS) + '.',
           'Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share',
           'of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.',
           'Written by `tools/refdocs.py`; edit `src/game/game.ann`, then run `tools/mkgame.py --install` and',
           '`tools/refdocs.py`.', '']
    out.append('| Module | Entries | Code entries |')
    out.append('| --- | --- | --- |')
    for k, (start, name) in enumerate(modules):
        end = modules[k + 1][0] if k + 1 < len(modules) else HI
        inside = [e for e in entries if start <= e[0] < end]
        out.append(f'| [`{name}`](#{name}) | `${start:04X}`-`${end - 1:04X}` | '
                   f'{sum(1 for e in inside if e[1] == "c")} of {len(inside)} |')
    out.append('')
    current = None
    for a, kind, label, title in entries:
        if kind != 'c':
            continue
        m = module(a)
        if m != current:
            current = m
            out += [f'## {m}', '', f'`src/game/{m}.asm`', '']
        out += [f'### `{label}` (`${a:04X}`)', '', f'**{md(title)}**', '']
        if description(a):
            out += [description(a), '']
        s = seen.get(a)
        rows = []
        if not s:
            rows.append(('Runs', 'not reached in the recordings'))
        else:
            for key, text in BUILDS:
                if key in s['runs']:
                    calls, t = s['runs'][key]
                    share = 100 * t / builds[key].total
                    called = f'{calls:,} calls' if calls else 'run into, not called'
                    rows.append((f'Runs ({text})', f'{called}, {t:,} t-states own ({share:.2f} %)'))
            if s['callers']:
                rows.append(('Called from', ', '.join(f'`{owner(c)[2]}`' + (' (tail)' if k == 'tail' else '')
                                                       for c, k in sorted(s['callers'].items()))))
            if s['callees']:
                rows.append(('Calls', ', '.join(f'`{owner(c)[2]}`' + (' (tail)' if k == 'tail' else '')
                                                for c, k in sorted(s['callees'].items()))))
            for kind in ('reads', 'writes'):
                spans = merged(s[kind])
                if spans:
                    shown = [span(lo, hi) for lo, hi in spans[:6]]
                    more = f'; {len(spans) - 6} more ranges' if len(spans) > 6 else ''
                    rows.append(('Reads' if kind == 'reads' else 'Writes', '; '.join(shown) + more))
            if s['ports_in']:
                rows.append(('Ports in', ', '.join(f'`{p}`' for p in sorted(s['ports_in']))))
            if s['ports_out']:
                rows.append(('Ports out', ', '.join(f'`{p}`' for p in sorted(s['ports_out']))))
        out += ['| | |', '| --- | --- |'] + [f'| {k} | {v} |' for k, v in rows] + ['']
    open(os.path.join(ROOT, 'docs', '12-routine-reference.md'), 'w').write('\n'.join(out))

    # Doc 11: the data
    out = ['# 11. Data reference', '',
           'Every data entry of the game image `$5FB4`-`$FFFF`, in address order by module (`src/game/<module>.asm`):',
           'tables, buffers, records, variables, graphics, text. The name, the title and the description are the',
           'source\'s (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it',
           '(' + ', '.join(f'`work/{k}`' for k, _ in BUILDS) + '). The object records are laid out in',
           '[7. Objects](07-objects.md), the course data in [6. Rendering](06-rendering.md).',
           'Written by `tools/refdocs.py`.', '']
    current = None
    rows = []

    def flush():
        nonlocal rows
        if rows:
            out.extend(['| Address | Name | Bytes | What | Read by | Written by |',
                        '| --- | --- | --- | --- | --- | --- |'] + rows + [''])
            rows = []

    for a, kind, label, title in entries:
        if kind != 'b':
            continue
        m = module(a)
        if m != current:
            flush()
            current = m
            out += [f'## {m}', '']
        u = users.get(a, {'reads': set(), 'writes': set()})
        size = ends[a] - a + 1
        what = md(title).replace('|', '\\|')
        if description(a):
            what += '. ' + description(a).replace('\n\n', ' ').replace('|', '\\|')
        fmt = lambda names: ', '.join(f'`{n}`' for n in sorted(names)[:5]) + (
            f' +{len(names) - 5}' if len(names) > 5 else '') if names else '-'
        rows.append(f'| `${a:04X}` | `{label}` | {size} | {what} | {fmt(u["reads"])} | {fmt(u["writes"])} |')
    flush()
    open(os.path.join(ROOT, 'docs', '11-data-reference.md'), 'w').write('\n'.join(out))
    print(f'routines {sum(1 for e in entries if e[1] == "c")}, data entries {sum(1 for e in entries if e[1] == "b")}')


if __name__ == '__main__':
    main()

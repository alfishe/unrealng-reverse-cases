#!/usr/bin/env python3
"""Doc 11: every data entry of the game in play, with the routines that read and write it in recording r2.

    python3 tools/fig_dataref.py [--out docs/11-data-reference.md]

The entries: the game's annotations (src/game/game.ann once it exists; until then aneG's working seed
work/stage3/aneg/seed.ann with its newer parts work/stage3/aneg/ann/*.ann taking precedence): every `b`, `w`, `t`,
`s` entry (its extent runs to the next entry) and every `@equ` variable past the image (its size given, else 1).
The readers and writers: work/stage3/r2/l1.json, the routines entered from GameEntry's frame (4753) on, whose
profile reads or writes overlap the entry in its page (`$4000-$7FFF` bank 5, `$8000-$BFFF` bank 2, `$C000-$FFFF`
bank 0), named by the annotations' code entries (another bank's routine is "bank N `$XXXX`"). The other banks'
regions come from tools/fig_banks.txt. Once kit/refdocs.py can run on the case (game.ctl from kit/mkgame.py) it
replaces this script.
"""
import argparse
import glob
import json
import os
import re
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
PLAY_FROM = 4753  # r2: GameEntry
TOP = 0x10000


def page_of(a):
    return 5 if a < 0x8000 else 2 if a < 0xC000 else 0


def ann_files():
    final = os.path.join(CASE, 'src/game/game.ann')
    if os.path.exists(final):
        return [final], 'src/game/game.ann'
    seed = os.path.join(CASE, 'work/stage3/aneg/seed.ann')
    return [seed] + sorted(glob.glob(os.path.join(CASE, 'work/stage3/aneg/ann/*.ann'))), \
        'work/stage3/aneg/seed.ann + ann/*.ann (aneG, in progress)'


def parse():
    entries, code, module = {}, {}, {}
    files, src = ann_files()
    for path in files:
        mod = None
        for line in open(path):
            m = re.match(r'@module (\w+) ; (.*)', line)
            if m:
                mod = (m.group(1), m.group(2).strip())
                continue
            m = re.match(r'\$([0-9A-F]{4}) ([cbwts]) (\w+)(?: (\d+))? ; (.*)', line)
            if m:
                a = int(m.group(1), 16)
                entries[a] = (m.group(2), m.group(3), m.group(5).strip(), None)
                module[a] = mod
                if m.group(2) == 'c':
                    code[a] = m.group(3)
                continue
            m = re.match(r'@equ \$([0-9A-F]{4}) (\w+)(?: (\d+))? ; (.*)', line)
            if m:
                a = int(m.group(1), 16)
                entries[a] = ('v', m.group(2), m.group(4).strip(), int(m.group(3) or 1))
                module[a] = ('variables', 'the variables past the image')
    return entries, code, module, src


def extents(entries):
    keys = sorted(entries)
    out = []
    for i, a in enumerate(keys):
        kind, name, title, size = entries[a]
        if kind == 'c':
            continue
        if size is None:
            nxt = next((b for b in keys[i + 1:] if b > a), TOP)
            size = nxt - a
        out.append((a, a + size - 1, kind, name, title))
    return out


def accessors(code):
    l1 = json.load(open(os.path.join(CASE, 'work/stage3/r2/l1.json')))
    out = []
    for r in l1['routines']:
        p = r['profile']
        if p.get('last_frame', 0) < PLAY_FROM:
            continue
        a, pg = int(r['entry'][1:], 16), r['page']
        if pg in (0, 2, 5) and page_of(a) == pg and a in code:
            name = code[a]
        elif pg in (1, 3, 4, 6, 7):
            name = 'bank %d `$%04X`' % (pg, a)
        elif pg >= 256:
            continue  # the ROMs: TR-DOS's buffers, not the game's data
        elif p.get('first_frame', 0) < PLAY_FROM:
            continue  # unnamed and running before the game: the boot's code (the depacker, the game starter)
        else:
            name = '`$%04X`' % a  # code the annotations do not name (the disk module at $4000)
        # the IM 2 vector fetch: Pentagon's bus reads $FF, so every interrupt reads $68FF-$6900 in the name of
        # the routine it interrupts; not a data read of that routine
        rng = lambda key: [(int(x['from'][1:], 16), int(x['to'][1:], 16), x['page']) for x in p.get(key) or []
                           if not (key == 'reads' and x['page'] == 5 and x['from'] == '$68FF' and x['to'] == '$6900')]
        out.append((name, rng('reads'), rng('writes')))
    return out


def who(acc, lo, hi, key):
    pg = page_of(lo)
    names = OrderedDict()
    for name, reads, writes in acc:
        for a, b, p in (reads if key == 'r' else writes):
            if p == pg and a <= hi and b >= lo:
                names[name] = 1
    n = list(names)
    return ', '.join(n[:8]) + (' and %d more' % (len(n) - 8) if len(n) > 8 else '') if n else 'none seen'


def banks_table():
    rows = []
    for line in open(os.path.join(HERE, 'fig_banks.txt')):
        if not line.startswith('play '):
            continue
        _st, bank, lo, hi, kind, name = line.split(None, 5)
        if bank in ('1', '3', '4', '6', '7') and kind != 'free':
            rows.append('| %s | `$%s-$%s` | %d | %s | %s |' % (bank, lo, hi, int(hi, 16) - int(lo, 16) + 1, kind,
                                                              esc(name.strip())))
    return rows


def esc(s):
    """Markdown: hex in code spans (bare $ pairs render as math on GitHub), pipes escaped"""
    s = s.replace('|', '\\|')
    return re.sub(r'(?<!`)(\$[0-9A-F]{2,4}(?:-\$[0-9A-F]{2,4})?)(?!`)', r'`\1`', s)


def main():
    a = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    a.add_argument('--out', default=os.path.join(CASE, 'docs/11-data-reference.md'))
    args = a.parse_args()
    entries, code, module, src = parse()
    ext = extents(entries)
    acc = accessors(code)
    kinds = {'b': 'bytes', 'w': 'words', 't': 'text', 's': 'space', 'v': 'variable'}
    lines = ['# 11. Data reference', '',
             'Every data entry of the game in play, in address order and grouped by module, with the routines that '
             'read and write it in recording `r2` (from `GameEntry`, frame 4753, to its end: the game menu, play, a '
             'save, two loads). Generated by `python3 tools/fig_dataref.py`; do not edit by hand.', '',
             '- **Entries**: %s. Each runs to the next entry; a variable past the image has the size its '
             'annotation gives.' % esc(src),
             '- **Read by / Written by**: the routines of `r2` whose L1 profile (`work/stage3/r2/l1.json`) reads or '
             'writes a byte of the entry in its bank. "none seen" means `r2` did not touch it in play; it is not a '
             'claim that nothing does. Routines in another bank are named by bank and address; `$4000`-range '
             'addresses are the disk module\'s copy.',
             '- **Left out**: the IM 2 vector fetch. Pentagon\'s data bus reads `$FF` during the acknowledge, so '
             'every interrupt reads `$68FF-$6900` of `ImTable`; L1 counts that read to the interrupted routine. '
             'Also left out: the boot\'s code before `GameEntry` (the depacker that writes the whole image).',
             '- **The other banks** (1, 3, 4, 6, 7) are listed last as regions; their parts\' own entries come with '
             'their modules (doc 02, 2.6).', '']
    cur = None
    count = 0
    for lo, hi, kind, name, title in ext:
        mod = module.get(lo)
        if mod != cur:
            cur = mod
            lines += ['', '## %s: %s' % (mod[0], esc(mod[1])) if mod else '## (no module)', '',
                      '| Address | Name | Bytes | Kind | What | Read by | Written by |',
                      '| --- | --- | ---: | --- | --- | --- | --- |']
        lines.append('| `$%04X` | `%s` | %d | %s | %s | %s | %s |' % (
            lo, name, hi - lo + 1, kinds[kind], esc(title), who(acc, lo, hi, 'r'), who(acc, lo, hi, 'w')))
        count += 1
    lines += ['', '## The other banks', '',
              'From `tools/fig_banks.txt` (doc 02, 2.2): what banks 1, 3, 4, 6 and 7 hold in play.', '',
              '| Bank | Range | Bytes | Kind | What |', '| --- | --- | ---: | --- | --- |'] + banks_table()
    open(args.out, 'w').write('\n'.join(lines) + '\n')
    print(args.out, count, 'entries')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Write docs/11-data-reference.md and docs/12-routine-reference.md from the source and the recordings.

    python3 kit/refdocs.py --case CASE

Every entry of the game (CASE/work/mkgame/game.ctl, written by kit/mkgame.py) with its name, title and description
from src/game/game.ann; for code, what the recordings saw it do (the builds of case.json "ref_builds": work/<key>/
l1.json): callers, callees, runs, own time, the memory it reads and writes, its ports, and a link to each of its
animations, docs/img/routines/<Label>.gif and <Label>-<what>.gif (kit/routine_anim.py, kit/memanim.py). A routine no
ref build reached gets the calls the case's other recordings (read_builds, code_builds) saw. For data, the routines
that read and write it (the recordings', and the LD through (nn) of the code), each inner label a row of its own.

Memory ranges name the label at or below their first byte, inner labels included (Label+offset). The interrupt's
acceptance (the IM 2 vector read, the return address pushed), which L1 books to the instruction it interrupted, is
the handler's: the routine the vector leads to (the L1 "interrupt" edge's callee), not the interrupted routine's.

case.json keys read here (beside mkgame.py's):

    "ref_builds": [["p2", "the bot game"], ["game", "the first recording's game window"]],
    "overlay": {"lo": "8000", "hi": "BFFF", "name": "the playfield buffer",
                "why": "laid over the title player and the start-up"},     a buffer laid over code (optional)
    "data_note": "The object records are laid out in [7. Objects](07-objects.md)."   (optional, doc 11)
"""
import bisect
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mkgame  # noqa: E402

ROOT = None
BUILDS = []
LO, HI = 0, 0x10000
# A buffer laid over code once play starts: the accesses there of code outside it are the buffer's, not the entries
# of the code it covers. None: no overlay
BUFFER_LO, BUFFER_HI = 0x10000, 0x10000
OVERLAY_NAME, OVERLAY_WHY = '', ''


def in_buffer(a):
    return BUFFER_LO <= a <= BUFFER_HI


def outside_buffer(rs):
    """Ranges with the buffer cut out, and the buffer's part as one range (or None)"""
    rest, inside = [], []
    for lo, hi, n in rs:
        if hi < BUFFER_LO or lo > BUFFER_HI:
            rest.append((lo, hi, n))
            continue
        if lo < BUFFER_LO:
            rest.append((lo, BUFFER_LO - 1, n))
        if hi > BUFFER_HI:
            rest.append((BUFFER_HI + 1, hi, n))
        inside.append((max(lo, BUFFER_LO), min(hi, BUFFER_HI)))
    return rest, ((min(x[0] for x in inside), max(x[1] for x in inside)) if inside else None)


def entries_of(ctl):
    """[(address, kind, label, title)] in address order, and {address: label} of every label (inner ones too)"""
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
    return out, label


# use flags of L1's byte_use (unreal-ng l1model.h): the stack's own accesses
STACK_READ, STACK_WRITE, CODE = 1 << 2, 1 << 3, 1 << 6 | 1 << 7


class Build:
    def __init__(self, key, full=True):
        doc = json.load(open(os.path.join(ROOT, 'work', key, 'l1.json')))
        self.total = doc['replay']['tstates']
        self.frames = (doc['replay']['first_frame'], doc['replay']['last_frame'])
        self.routines = [r for r in doc['routines'] if r['page'] in mkgame.BASES]
        self.index = {i: r for i, r in enumerate(doc['routines'])}
        self.calls = doc['calls']
        # the interrupted routines: routine index -> the handlers (routine indexes) the interrupt entered from it
        self.interrupted = {}
        for c in self.calls:
            if c['kind'] == 'interrupt':
                self.interrupted.setdefault(c['caller'], set()).add(c['callee'])
        # the stack's slots, pushed and popped and never run (PUSH / CALL / an interrupt, POP / RET): where an
        # interrupt's return address goes. A byte only pushed to (an SP walk over data), code, or neither is no slot
        self.stack = set()
        if full and self.interrupted:
            for page, offset, length, flags, *_ in doc.get('byte_use', ()):
                if flags & STACK_READ and flags & STACK_WRITE and not flags & CODE and page in mkgame.BASES:
                    base = mkgame.BASES[page]
                    self.stack.update(range(base + offset, base + offset + length))


def ranges(items):
    return [(int(x['from'][1:], 16), int(x['to'][1:], 16), x['bytes']) for x in items if x['page'] in mkgame.BASES]


def split(rs, take):
    """(ranges without the bytes for which take(address) is true, the ranges of those bytes)"""
    kept, taken = [], []
    for lo, hi, _ in rs:
        if not any(take(a) for a in range(lo, hi + 1)):
            kept.append((lo, hi, hi - lo + 1))
            continue
        for a in range(lo, hi + 1):
            out = taken if take(a) else kept
            if out and out[-1][1] == a - 1:
                out[-1] = (out[-1][0], a, out[-1][2] + 1)
            else:
                out.append((a, a, 1))
    return kept, taken


# LD through memory: LD r,(nn) reads, LD (nn),r writes (1 byte with A, 2 with a register pair)
LD_READ = re.compile(r'^LD (A|BC|DE|HL|SP|IX|IY),\(\$([0-9A-F]{4})\)$')
LD_WRITE = re.compile(r'^LD \(\$([0-9A-F]{4})\),(A|BC|DE|HL|SP|IX|IY)$')


def static_accesses(skool):
    """[(instruction address, 'reads' | 'writes', lo, hi)] of the LDs through (nn) in mkgame's skool file"""
    out = []
    for line in open(skool):
        m = re.match(r'^[ c*]\$([0-9A-F]{4}) ([^;]*?)\s*(?:;.*)?$', line.rstrip('\n'))
        if not m:
            continue
        at, text = int(m.group(1), 16), m.group(2)
        r, w = LD_READ.match(text), LD_WRITE.match(text)
        if r:
            a = int(r.group(2), 16)
            out.append((at, 'reads', a, a + (r.group(1) != 'A')))
        elif w:
            a = int(w.group(1), 16)
            out.append((at, 'writes', a, a + (w.group(2) != 'A')))
    return out


def md(text):
    """Prose for GitHub: hex addresses in code spans (a bare $..$ pair is math there)"""
    parts = re.split(r'(`[^`]*`)', text)
    return ''.join(p if p.startswith('`') else re.sub(r'(\$[0-9A-Fa-f]{1,4}(?:-\$[0-9A-Fa-f]{1,4})?)', r'`\1`', p)
                   for p in parts)


def main():
    global ROOT, BUILDS, LO, HI, BUFFER_LO, BUFFER_HI, OVERLAY_NAME, OVERLAY_WHY
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument('--case', required=True)
    p.add_argument('--docs', help='where 11-data-reference.md and 12-routine-reference.md go (CASE/docs)')
    args = p.parse_args()
    config = mkgame.load_case(args.case)
    ROOT, LO, HI = mkgame.ROOT, mkgame.LO, mkgame.HI
    BUILDS = [tuple(b) for b in config.get('ref_builds', [])]
    if not BUILDS:
        sys.exit('case.json: no "ref_builds"')
    overlay = config.get('overlay')
    if overlay:
        BUFFER_LO, BUFFER_HI = int(overlay['lo'], 16), int(overlay['hi'], 16)
        OVERLAY_NAME, OVERLAY_WHY = overlay.get('name', 'the buffer'), overlay.get('why', 'laid over code')
    docs = args.docs or os.path.join(ROOT, 'docs')
    os.makedirs(docs, exist_ok=True)
    ctl = os.path.join(ROOT, 'work', 'mkgame', 'game.ctl')
    if not os.path.exists(ctl):
        sys.exit('run kit/mkgame.py first (it writes work/mkgame/game.ctl)')
    ann = mkgame.Annotations(os.path.join(ROOT, 'src', 'game', 'game.ann'))
    entries, labels = entries_of(ctl)
    starts = [e[0] for e in entries]
    ends = {e[0]: (entries[i + 1][0] if i + 1 < len(entries) else HI) - 1 for i, e in enumerate(entries)}
    entry_at = {e[0]: e for e in entries}
    modules = sorted(ann.modules)
    mstarts = [m[0] for m in modules]
    # every label of the image, inner ones too, in address order
    lstarts = sorted(a for a in labels if LO <= a < HI)
    # the image (the vector's words): mkgame's copy from LO, else case.json's 64 K image; none in a scratch case
    image, image_at = b'', LO
    image_path = os.path.join(ROOT, 'work', 'mkgame', 'game-image.bin')
    if os.path.exists(image_path):
        image = open(image_path, 'rb').read()
    elif config.get('image') and os.path.exists(os.path.join(ROOT, config['image'])):
        image, image_at = open(os.path.join(ROOT, config['image']), 'rb').read(), 0

    def word(a):
        """the image's word at a (None outside it)"""
        k = a - image_at
        return image[k] | image[k + 1] << 8 if 0 <= k and k + 1 < len(image) and LO <= a < HI else None

    def owner(a):
        i = bisect.bisect_right(starts, a) - 1
        return entries[i] if i >= 0 and LO <= a < HI else None

    def module(a):
        i = bisect.bisect_right(mstarts, a) - 1
        return modules[i][1] if i >= 0 else 'buffers'

    def inner_name(a):
        """the label at or below a inside a's entry, inner labels included: Label or Label+offset"""
        e = owner(a)
        if not e:
            return None
        i = bisect.bisect_right(lstarts, a) - 1
        at = lstarts[i] if i >= 0 and lstarts[i] >= e[0] else e[0]
        name = labels.get(at, e[2])
        return name if at == a else '%s+%d' % (name, a - at)

    def span(lo, hi):
        """A memory range as the labels it covers: the one at or below its first byte (inner labels included,
        Label+offset), then the entries it runs into, or within one entry its inner labels"""
        if hi < LO:
            area = 'screen' if 0x4000 <= lo < 0x5B00 else 'system'
            return ('`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)) + ' (%s)' % area
        names = []
        a = max(lo, LO)
        first = owner(a)
        if first:
            names.append(inner_name(a))
            if ends[first[0]] >= hi:  # within one entry: its inner labels after the first byte
                i = bisect.bisect_right(lstarts, a)
                while i < len(lstarts) and lstarts[i] <= hi:
                    names.append(labels[lstarts[i]])
                    i += 1
            a = ends[first[0]] + 1
        while a <= hi:
            e = owner(a)
            if not e:  # past the image: the work space above it (its EQUs)
                names.append('work space $%04X+' % a)
                break
            names.append(e[2])
            a = ends[e[0]] + 1
        shown = ', '.join('`%s`' % n for n in names[:4]) + (' and %d more' % (len(names) - 4) if len(names) > 4 else '')
        return ('`$%04X`' % lo if lo == hi else '`$%04X`-`$%04X`' % (lo, hi)) + ' (%s)' % shown

    def new_seen():
        return {'callers': {}, 'callees': {}, 'runs': {}, 'reads': [], 'writes': [], 'ports_in': set(),
                'ports_out': set(), 'interrupts': {}}

    builds = {key: Build(key) for key, _ in BUILDS}
    # Per routine entry of the game: what each build saw
    seen = {}
    users = {}  # data entry or inner label -> {'reads': set(names), 'writes': set(names)}
    for key, _ in BUILDS:
        b = builds[key]
        # the interrupt's acceptance, booked by L1 to the interrupted instruction: the vector read (a word that
        # holds the handler's address) and the return address pushed (bytes the stack uses) go to the handler
        moved = {}  # handler routine index -> {'reads': [...], 'writes': [...]}
        # the vector: words holding an IM 2 handler's address in the page I selects, the page where the most
        # interrupted routines read such a word (a graphic's bytes may equal the address elsewhere)
        handlers_at = {int(b.index[h]['entry'][1:], 16) for hs in b.interrupted.values() for h in hs} - {0x38, 0x66}
        pages = {}
        for i in b.interrupted:
            hit = set()
            for lo, hi, _ in ranges(b.index[i]['profile']['reads']):
                hit.update(x >> 8 for x in range(lo, hi) if word(x) in handlers_at)
            for page in hit:
                pages[page] = pages.get(page, 0) + 1
        vector_page = max(pages, key=lambda k: (pages[k], k)) if pages else None
        # without the image: the word pairs at least half the interrupted routines (3 or more) read
        common = set()
        if not image and handlers_at:
            pairs = {}
            for i in b.interrupted:
                read = {x for lo, hi, _ in ranges(b.index[i]['profile']['reads']) for x in range(lo, hi + 1)}
                for x in read:
                    if x + 1 in read:
                        pairs[x] = pairs.get(x, 0) + 1
            need = max(3, (len(b.interrupted) + 1) // 2)
            common = {x for x, n in pairs.items() if n >= need}
        for i, handlers in b.interrupted.items():
            r = b.index[i]
            entries_ = {int(b.index[h]['entry'][1:], 16) for h in handlers}
            p = r['profile']

            def vector(a, entries_=entries_):
                if not entries_ - {0x38, 0x66}:
                    return False
                if not image:
                    return a in common or a - 1 in common
                return any(word(x) in entries_ and x >> 8 == vector_page for x in (a, a - 1)
                           if word(x) is not None)
            reads, vread = split(ranges(p['reads']), vector)
            writes, pushed = split(ranges(p['writes']), b.stack.__contains__)
            r['_reads'], r['_writes'] = reads, writes
            to = min(handlers)
            m = moved.setdefault(to, {'reads': [], 'writes': []})
            m['reads'] += vread
            m['writes'] += pushed
        for i, r in b.index.items():
            if r['page'] not in (0, 2, 5):
                continue
            a = int(r['entry'][1:], 16)
            e = owner(a)
            if not e or e[1] != 'c':
                continue
            s = seen.setdefault(e[0], new_seen())
            p = r['profile']
            runs = s['runs'].setdefault(key, [0, 0])
            runs[0] += p['entries'] if a == e[0] else 0
            runs[1] += p['tstates']
            s['reads'] += r.get('_reads', ranges(p['reads'])) + moved.get(i, {}).get('reads', [])
            s['writes'] += r.get('_writes', ranges(p['writes'])) + moved.get(i, {}).get('writes', [])
            s['ports_in'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_in'])
            s['ports_out'].update(x if isinstance(x, str) else x.get('port', str(x)) for x in p['ports_out'])
        for c in b.calls:
            ca, ce = b.index.get(c['caller']), b.index.get(c['callee'])
            if not ca or not ce or ca['page'] not in (0, 2, 5) or ce['page'] not in (0, 2, 5):
                continue
            oa, oe = owner(int(ca['entry'][1:], 16)), owner(int(ce['entry'][1:], 16))
            if not oa or not oe or oa[0] == oe[0]:
                continue
            seen.setdefault(oa[0], new_seen())
            seen.setdefault(oe[0], new_seen())
            if c['kind'] == 'interrupt':  # no call: the handler is entered by the interrupt, in these routines
                seen[oe[0]]['interrupts'][oa[0]] = seen[oe[0]]['interrupts'].get(oa[0], 0) + c['count']
                continue
            seen[oa[0]]['callees'][oe[0]] = c['kind']
            seen[oe[0]]['callers'][oa[0]] = c['kind']

    def touch(kind, lo, hi, name, static=False):
        """name reads / writes lo..hi: each data entry and inner label it covers"""
        x = max(lo, LO)
        while x <= hi and x < HI:
            e = owner(x)
            if e[1] == 'b':
                users.setdefault(e[0], {'reads': set(), 'writes': set()})[kind].add((name, static))
                i = bisect.bisect_right(lstarts, x) - 1
                at = lstarts[i] if i >= 0 and lstarts[i] > e[0] else None
                if at is not None:
                    users.setdefault(at, {'reads': set(), 'writes': set()})[kind].add((name, static))
                k = bisect.bisect_right(lstarts, hi)
                inner = [y for y in lstarts[bisect.bisect_right(lstarts, x):k] if y <= ends[e[0]]]
                for y in inner:
                    users.setdefault(y, {'reads': set(), 'writes': set()})[kind].add((name, static))
            x = ends[e[0]] + 1

    for a, s in seen.items():
        name = owner(a)[2]
        for kind in ('reads', 'writes'):
            rs = s[kind] if in_buffer(a) else outside_buffer(s[kind])[0]
            for lo, hi, _ in rs:
                touch(kind, lo, hi, name)
    # the code's LD through (nn): a reader or writer the recordings may not have seen
    skool = os.path.join(ROOT, 'work', 'mkgame', 'game.skool')
    if os.path.exists(skool):
        for at, kind, lo, hi in static_accesses(skool):
            e = owner(at)
            if e and e[1] == 'c' and owner(lo):
                touch(kind, lo, hi, e[2], True)

    # The routines no ref build reached: the calls the case's other recordings saw
    other_keys = [b for b in list(config.get('read_builds', ())) + list(config.get('code_builds', ()))
                  if b not in builds]
    other = {}  # entry -> {build key: calls}
    missing = {e[0] for e in entries if e[1] == 'c' and e[0] not in seen}
    if missing:
        for key in dict.fromkeys(other_keys):
            if not os.path.exists(os.path.join(ROOT, 'work', key, 'l1.json')):
                continue
            b = Build(key, full=False)
            for r in b.routines:
                a = int(r['entry'][1:], 16)
                if a in missing:
                    runs = other.setdefault(a, {}).setdefault(key, [0, 0])
                    runs[0] += r['profile']['entries']
                    runs[1] += r['profile']['tstates']

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

    def animations(label):
        """docs/img/routines/<label>.gif, then <label>-<what>.gif: a second animation of one routine (another
        document's) has a file of its own"""
        folder = os.path.join(ROOT, 'docs', 'img', 'routines')
        names = sorted(n for n in os.listdir(folder) if n.startswith(label + '-') and n.endswith('.gif')) \
            if os.path.isdir(folder) else []
        return ([label + '.gif'] if os.path.exists(os.path.join(folder, label + '.gif')) else []) + names

    ref_names = ', '.join(f'`{k}`' for k, _ in BUILDS)
    # Doc 12: the routines
    out = ['# 12. Routine reference', '',
           'Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and',
           'the description are the source\'s (`src/game/game.ann`); the rest is what the recordings saw: '
           + ', '.join(f'`work/{k}` ({t})' for k, t in BUILDS) + '. They are local, not in the repository; the WALKTHROUGH\'s commands rebuild them.',
           'Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share',
           'of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)',
           'and the entries they cover'
           + (f'; in `${BUFFER_LO:04X}-${BUFFER_HI:04X}` the accesses of code outside it are {OVERLAY_NAME}\'s, {OVERLAY_WHY}'
              if OVERLAY_NAME else '') + '. The interrupt\'s acceptance (the vector read, the return address pushed) is',
           'the handler\'s, not the interrupted routine\'s. An entry no recording reached says so; one the case\'s other',
           'recordings ran gives their calls.',
           'Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`',
           '(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.', '']
    out.append('| Module | Entries | Code entries |')
    out.append('| --- | --- | --- |')
    # a module may hold several stretches of addresses (@module NAME again): one row and one section each module
    order = list(dict.fromkeys(name for _, name in modules))
    stretches = {}
    for k, (start, name) in enumerate(modules):
        end = modules[k + 1][0] if k + 1 < len(modules) else HI
        stretches.setdefault(name, []).append((start, end))
    for name in order:
        inside = [e for e in entries if any(s <= e[0] < t for s, t in stretches[name])]
        # a module with code has its heading here; one of data only, in doc 11 (GitHub's slug: lower case)
        if any(e[1] == 'c' for e in inside):
            link = f'[`{name}`](#{name.lower()})'
        elif any(e[1] == 'b' for e in inside):
            link = f'[`{name}`](11-data-reference.md#{name.lower()})'
        else:
            link = f'`{name}`'
        where = ', '.join(f'`${s:04X}`-`${t - 1:04X}`' for s, t in stretches[name])
        out.append(f'| {link} | {where} | '
                   f'{sum(1 for e in inside if e[1] == "c")} of {len(inside)} |')
    out.append('')
    rank = {name: k for k, name in enumerate(order)}

    def by_module(kind):
        """the entries of a kind, module by module (a module's stretches together), in address order"""
        picked = [e for e in entries if e[1] == kind]
        return sorted(picked, key=lambda e: (rank.get(module(e[0]), -1), e[0]))

    current = None
    for a, kind, label, title in by_module('c'):
        m = module(a)
        if m != current:
            current = m
            out += [f'## {m}', '', f'`src/game/{m}.asm`', '']
        out += [f'### `{label}` (`${a:04X}`)', '', f'**{md(title)}**', '']
        if description(a):
            out += [description(a), '']
        for gif in animations(label):
            what = gif[len(label) + 1:-4].replace('-', ' ')
            out += [f'[Animation: `{label}` at work{", " + what if what else ""}](img/routines/{gif})', '']
        s = seen.get(a)
        rows = []
        if not s:
            runs = other.get(a)
            if runs:
                ranked = sorted(runs.items(), key=lambda x: (-x[1][0], -x[1][1], x[0]))
                calls = sum(n for n, _ in runs.values())
                called = f'{calls:,} call{"" if calls == 1 else "s"}' if calls else 'run into, not called'
                shown = ', '.join(f'`{k}`' + (f' {n:,}' if calls else '') for k, (n, _) in ranked[:3]) + \
                    (f' and {len(ranked) - 3} more' if len(ranked) > 3 else '')
                rows.append(('Runs', f'not reached in {ref_names}; in the other recordings {called} ({shown})'))
            else:
                rows.append(('Runs', 'not reached in the recordings'))
        else:
            for key, text in BUILDS:
                if key in s['runs']:
                    calls, t = s['runs'][key]
                    share = 100 * t / builds[key].total
                    called = f'{calls:,} call{"" if calls == 1 else "s"}' if calls else 'run into, not called'
                    rows.append((f'Runs ({text})', f'{called}, {t:,} t-states own ({share:.2f} %)'))
            if s['interrupts']:
                n = sum(s['interrupts'].values())
                rows.append(('Entered by', f'the interrupt, {n:,} time{"" if n == 1 else "s"} in '
                                           f'{len(s["interrupts"])} routine{"" if len(s["interrupts"]) == 1 else "s"}'))
            if s['callers']:
                rows.append(('Called from', ', '.join(f'`{owner(c)[2]}`' + (' (tail)' if k == 'tail' else '')
                                                       for c, k in sorted(s['callers'].items()))))
            if s['callees']:
                rows.append(('Calls', ', '.join(f'`{owner(c)[2]}`' + (' (tail)' if k == 'tail' else '')
                                                for c, k in sorted(s['callees'].items()))))
            for kind in ('reads', 'writes'):
                rs, buffer = (s[kind], None) if in_buffer(a) else outside_buffer(s[kind])
                spans = merged(rs)
                if buffer:
                    spans = sorted(spans + [list(buffer)])
                if spans:
                    shown = [('`$%04X`-`$%04X` (%s)' % (x[0], x[1], OVERLAY_NAME)) if buffer and tuple(x) == buffer
                             else span(*x) for x in spans[:6]]
                    more = f'; {len(spans) - 6} more ranges' if len(spans) > 6 else ''
                    rows.append(('Reads' if kind == 'reads' else 'Writes', '; '.join(shown) + more))
            if s['ports_in']:
                rows.append(('Ports in', ', '.join(f'`{p}`' for p in sorted(s['ports_in']))))
            if s['ports_out']:
                rows.append(('Ports out', ', '.join(f'`{p}`' for p in sorted(s['ports_out']))))
        out += ['| | |', '| --- | --- |'] + [f'| {k} | {v} |' for k, v in rows] + ['']
    open(os.path.join(docs, '12-routine-reference.md'), 'w').write('\n'.join(out))

    # Doc 11: the data
    out = ['# 11. Data reference', '',
           f'Every data entry of the game image `${LO:04X}`-`${HI - 1:04X}`, in address order by module (`src/game/<module>.asm`):',
           'tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under',
           'its entry, its size up to the next label. The name, the title and the description are the',
           'source\'s (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it',
           '(' + ', '.join(f'`work/{k}`' for k, _ in BUILDS) + ', local and not in the repository'
           + (f'; {OVERLAY_NAME}\'s accesses are not counted as theirs' if OVERLAY_NAME else '') + '), and, marked',
           '"(code)", the routines whose `LD` through `(nn)` reads or writes it where the recordings did not see them do so.'
           + (' ' + config['data_note'] if config.get('data_note') else ''),
           'Written by `kit/refdocs.py`.', '']
    current = None
    rows = []

    def flush():
        nonlocal rows
        if rows:
            out.extend(['| Address | Name | Bytes | What | Read by | Written by |',
                        '| --- | --- | --- | --- | --- | --- |'] + rows + [''])
            rows = []

    def fmt(found):
        """the recordings' names, then the code's (marked)"""
        run = {n for n, static in found if not static}
        names = [f'`{n}`' for n in sorted(run)] + \
            [f'`{n}` (code)' for n in sorted({n for n, static in found if static} - run)]
        return ', '.join(names[:5]) + (f' +{len(names) - 5}' if len(names) > 5 else '') if names else '-'

    nothing = {'reads': set(), 'writes': set()}
    for a, kind, label, title in by_module('b'):
        m = module(a)
        if m != current:
            flush()
            current = m
            out += [f'## {m}', '']
        u = users.get(a, nothing)
        size = ends[a] - a + 1
        what = md(title).replace('|', '\\|')
        if description(a):
            what += '. ' + description(a).replace('\n\n', ' ').replace('|', '\\|')
        rows.append(f'| `${a:04X}` | `{label}` | {size} | {what} | {fmt(u["reads"])} | {fmt(u["writes"])} |')
        inner = [x for x in lstarts if a < x <= ends[a]]
        for k, x in enumerate(inner):
            u = users.get(x, nothing)
            nxt = inner[k + 1] if k + 1 < len(inner) else ends[a] + 1
            comment = md((ann.inline.get(x, (None, None))[1] or '').replace('|', '\\|')) or '-'
            rows.append(f'| `${x:04X}` | `{labels[x]}` (`{label}`+{x - a}) | {nxt - x} | {comment} | '
                        f'{fmt(u["reads"])} | {fmt(u["writes"])} |')
    flush()
    open(os.path.join(docs, '11-data-reference.md'), 'w').write('\n'.join(out))
    print(f'routines {sum(1 for e in entries if e[1] == "c")}, data entries {sum(1 for e in entries if e[1] == "b")}')


if __name__ == '__main__':
    main()

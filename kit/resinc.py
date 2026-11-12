#!/usr/bin/env python3
"""A resource assembled from source lines, not INCBIN: the editable text stays the source, the build writes a .inc.

    @res text/menus/System.bin include      (game.ann: the entry's lines become INCLUDE "res/text/menus/System.inc")

An INCBIN takes the bytes as they are: an address inside them stays a number, so a label that moves leaves the
resource pointing at the old place, and the name cannot be written in the editable form at all. A resource marked
`include` is instead an INCLUDE of NAME.inc (NAME.bin with the suffix .inc): DB / DW lines in which a word may be a
label's name, resolved by sjasmplus (its second pass, so a label defined later is fine), and the entry's inner labels
as labels between them. The case's res tool (tools/res_formats.py, the build step) writes the .inc from the editable
form with `lines()`; kit/mkgame.py writes a numeric one (`numeric()`, the image's bytes and the inner labels at their
offsets) to check its own assembly, and installs it beside the bytes only for a case without a res hook.

    import resinc
    names, addrs, marks = resinc.symbols(case_root)   # the .ann's names: {addr: name}, {name: addr}, inner labels
    text = resinc.lines([('label', 'Menu'), ('b', 8), ('w', 'AboutWindow'), ('b', 0xC1)])

Items of lines(): ('b', byte), ('w', number or label expression), ('label', NAME). Bytes go 16 to a DB line, a word
on a DW line of its own (the name readable), a label on a line of its own.

A resource the case's own tool assembles (a script format with addresses inside, not a .inc) writes and reads names
through Symbols: the names of one or more .ann files, each over the window of addresses it names (a bank's .ann at
`$C000`, the game's below it), so a word that is a label's address is written `Label`, one inside an entry
`Label+N` (the label at or below it in that entry), and read back to the number; a name nobody defines fails.

    sym = resinc.Symbols(case_root).add('src/game/game.ann', hi=0xC000).add('src/bank3/bank3.ann', lo=0xC000)
    sym.label(0xAB7B)        # 'BoxRect'; sym.label(0xCCDA) 'SharedModels+591'; None: no entry holds it
    sym.value('SharedModels+591'), sym.value('$CCDA')   # 0xCCDA both
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def inc_name(name):
    """The .inc file of resource NAME (System.bin -> System.inc)"""
    return os.path.splitext(name)[0] + '.inc'


def lines(items, header=None):
    """The source of a resource: DB lines of 16 bytes, a DW line per word, a label line per label"""
    out = ['; ' + h for h in (header or [])]
    run = []

    def flush():
        if run:
            out.append('  DB ' + ','.join('$%02X' % b for b in run))
            run.clear()

    for kind, value in items:
        if kind == 'b':
            if not 0 <= value <= 255:
                raise ValueError('resinc: byte %r out of range' % value)
            run.append(value)
            if len(run) == 16:
                flush()
        elif kind == 'w':
            flush()
            out.append('  DW ' + ('$%04X' % value if isinstance(value, int) else value))
        elif kind == 'label':
            flush()
            out.append(value + ':')
        else:
            raise ValueError('resinc: unknown item %r' % (kind,))
    flush()
    return '\n'.join(out) + '\n'


def numeric(data, marks=None, header=None):
    """The source of the bytes data as they are, the labels of marks ({offset: NAME}) before their bytes"""
    marks = marks or {}
    bad = [k for k in marks if not 0 <= k < len(data)]
    if bad:
        raise ValueError('resinc: label %s outside the resource' % marks[bad[0]])
    items = []
    for i, b in enumerate(data):
        if i in marks:
            items.append(('label', marks[i]))
        items.append(('b', b))
    return lines(items, header)


def symbols(case_root, ann_path=None):
    """The names of the case's annotations (the main part's src/<main>/<main>.ann unless ann_path): ({address: name}, {name: address},
    {resource file: {offset: inner label}}), the inner labels of every @res entry by their offset in its file"""
    sys.path.insert(0, HERE)
    import mkgame
    mkgame.load_case(case_root)  # LO, HI: an @equ inside the image is refused
    main = mkgame.main_name()
    ann = mkgame.Annotations(ann_path or os.path.join(case_root, 'src', main, main + '.ann'))
    names = {}
    for a in set(ann.entries) | set(ann.inline):
        n = ann.name(a)
        if n:
            names[a] = n
    addrs = {n: a for a, n in names.items()}
    starts = sorted(ann.entries)
    marks = {}
    for a, res in ann.resources.items():
        nxt = next((s for s in starts if s > a), 0x10000)
        lo = min(x for x, r in ann.resources.items() if r == res)
        for i, (n, _) in ann.inline.items():
            if n and a <= i < nxt and n != ann.entries[a][1]:
                marks.setdefault(res, {})[i - lo] = n
    return names, addrs, marks


ENTRY = re.compile(r'^\$([0-9A-Fa-f]{4})(?:\s+([cbwts])\b)?(?:\s+([A-Za-z_]\w*))?')
EXPR = re.compile(r'^([A-Za-z_]\w*)(?:([+-])(\$[0-9A-Fa-f]+|\d+))?$')


class Symbols:
    """Names of .ann files for a resource's words: label(address) writes one, value(text) reads it back"""

    def __init__(self, root='.'):
        self.root = root
        self.names = {}  # address: name (an entry's own name before an inner label on its address)
        self.addrs = {}  # name: address
        self.entries = []  # (start, end, [(address, name)] of its labels in order), in address order

    def add(self, path, lo=0, hi=0x10000):
        """the entries and labels of the .ann at path (relative to the root) with addresses lo..hi-1"""
        entries, inner = {}, {}
        for line in open(os.path.join(self.root, path), encoding='utf-8'):
            m = ENTRY.match(line.strip())
            if not m:
                continue
            a = int(m.group(1), 16)
            if m.group(2):
                entries[a] = m.group(3)
            elif m.group(3):
                inner.setdefault(a, m.group(3))
        for a, name in list(inner.items()) + [(a, n) for a, n in entries.items() if n]:
            if name in self.addrs and self.addrs[name] != a:
                raise ValueError('resinc: %s names $%04X and $%04X' % (name, self.addrs[name], a))
            self.addrs[name] = a
            if lo <= a < hi and (a not in self.names or a in entries):
                self.names[a] = name
        starts = sorted(entries)
        for k, a in enumerate(starts):
            end = starts[k + 1] if k + 1 < len(starts) else hi
            if lo <= a < hi:
                labels = sorted((x, self.names[x]) for x in self.names if a <= x < min(end, hi))
                self.entries.append((a, min(end, hi), labels))
        self.entries.sort()
        return self

    def label(self, value):
        """'Label' for a label's address, 'Label+N' inside an entry (the label at or below), else None"""
        if value in self.names:
            return self.names[value]
        for start, end, labels in self.entries:
            if start <= value < end:
                below = [(x, n) for x, n in labels if x <= value]
                if below:
                    x, n = below[-1]
                    return '%s+%d' % (n, value - x)
        return None

    def word(self, value):
        """the text of a word: its label, else $XXXX"""
        return self.label(value) or '$%04X' % value

    def value(self, text):
        """the number of '$XXXX', a decimal number, 'Label', 'Label+N' or 'Label-N' (N decimal or $hex)"""
        if text.startswith('$'):
            return int(text[1:], 16)
        if text.isdigit():
            return int(text)
        m = EXPR.match(text)
        if not m or m.group(1) not in self.addrs:
            raise ValueError('resinc: no label %s' % text)
        n = 0
        if m.group(3):
            n = int(m.group(3)[1:], 16) if m.group(3).startswith('$') else int(m.group(3))
        return (self.addrs[m.group(1)] + (n if m.group(2) == '+' else -n)) & 0xFFFF

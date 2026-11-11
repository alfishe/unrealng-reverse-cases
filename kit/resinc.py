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
"""
import os
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
    """The names of the case's annotations (src/game/game.ann unless ann_path): ({address: name}, {name: address},
    {resource file: {offset: inner label}}), the inner labels of every @res entry by their offset in its file"""
    sys.path.insert(0, HERE)
    import mkgame
    mkgame.load_case(case_root)  # LO, HI: an @equ inside the image is refused
    ann = mkgame.Annotations(ann_path or os.path.join(case_root, 'src', 'game', 'game.ann'))
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

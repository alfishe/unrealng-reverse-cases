#!/usr/bin/env python3
"""Write the SCL from a layout (src/media/scl.txt): the files, and what lies in every byte of their sectors.

    python3 tools/mkscl.py LAYOUT OUT.scl

Adapted from advanced-nether-earth/tools/mkdisk.py (the same layout lines; names may be quoted, a FROM / COUNT may
be $hex; tools/mktrd.py reads the same layout through read_layout):

    file NAME TYPE START LENGTH SECTORS     a catalogue entry (8-character name, type letter, the two words, the
                                           length in sectors); its sectors follow
    at SECTOR+OFFSET PATH [FROM [COUNT]]   the bytes of PATH at the file's sector SECTOR, byte OFFSET
    zero SECTOR+OFFSET COUNT               COUNT zero bytes

Sector numbers count from the file's first sector. Every byte of a file's sectors must come from a line (no hole,
no overlap). Paths are relative to the case; $GAME_DIR in a path is the game image's folder (default build/game),
$TRD_DIR the TRD extras' folder (default build/trd); a test may point them at stubs. SCL: "SINCLAIR", the file count, a 14-byte entry a file, the files'
sectors one after the other, a 4-byte sum of every byte before it.
"""
import os
import shlex
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def path(p):
    """a layout path: $GAME_DIR / $TRD_DIR expanded (default build/game, build/trd), relative to the case"""
    os.environ.setdefault('GAME_DIR', 'build/game')
    os.environ.setdefault('TRD_DIR', 'build/trd')
    return os.path.join(ROOT, os.path.expandvars(p))


def number(s):
    return int(s[1:], 16) if s.startswith('$') else int(s)


def read_layout(layout, extra=None):
    """[(name, type, start, length, sectors, bytes of its sectors)]; lines the caller handles go to extra(words)"""
    files, pieces, total = [], [], 0
    for n, line in enumerate(open(layout, encoding='utf-8'), 1):
        w = shlex.split(line, comments=True)
        if not w:
            continue
        where = '%s:%d' % (layout, n)
        if w[0] == 'file':
            files.append([w[1], w[2], number(w[3]), number(w[4]), number(w[5]), total])
            total += number(w[5])
            continue
        if w[0] in ('at', 'zero'):
            s, o = w[1].split('+')
            at = files[-1][5] * 256 + number(s) * 256 + number(o)
            if w[0] == 'zero':
                data = bytes(number(w[2]))
            else:
                data = open(path(w[2]), 'rb').read()
                if len(w) > 3:
                    frm = number(w[3])
                    data = data[frm:frm + number(w[4])] if len(w) > 4 else data[frm:]
            pieces.append((at, data, where))
            continue
        if extra is None or not extra(w, where):
            sys.exit('%s: cannot read: %s' % (where, line.strip()))
    disk = bytearray(total * 256)
    owner = [None] * len(disk)
    for at, data, where in pieces:
        for i in range(len(data)):
            if owner[at + i] is not None:
                sys.exit('%s: byte %d also from %s' % (where, at + i, owner[at + i]))
            owner[at + i] = where
        disk[at:at + len(data)] = data
    holes = [i for i, x in enumerate(owner) if x is None]
    if holes:
        sys.exit('%s: hole at disk byte %d (%d bytes unfilled)' % (layout, holes[0], len(holes)))
    return [(name, typ, start, length, sectors, bytes(disk[first * 256:(first + sectors) * 256]))
            for name, typ, start, length, sectors, first in files]


def entry(name, typ, start, length, sectors):
    return (name.ljust(8).encode('ascii') + typ.encode('ascii') + start.to_bytes(2, 'little') +
            length.to_bytes(2, 'little') + bytes([sectors]))


def main():
    layout, out = sys.argv[1], sys.argv[2]
    files = read_layout(layout)
    scl = bytearray(b'SINCLAIR') + bytes([len(files)])
    for name, typ, start, length, sectors, _ in files:
        scl += entry(name, typ, start, length, sectors)
    for f in files:
        scl += f[5]
    scl += (sum(scl) & 0xFFFFFFFF).to_bytes(4, 'little')
    open(out, 'wb').write(scl)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Write the SCL from src/disk.txt (the files, and what lies in every byte of their sectors).

    python3 tools/mkdisk.py LAYOUT OUT.scl

Paths in the layout are relative to the case. SCL: "SINCLAIR", the file count, a 14-byte catalogue entry a file
(name 8, type 1, start 2, length 2, sectors 1), the files' sectors one after the other, a 4-byte sum of all the
bytes before it. Every byte of a file's sectors must come from the layout (no hole, no overlap).
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def number(s):
    return int(s[1:], 16) if s.startswith('$') else int(s)


def main():
    layout, out = sys.argv[1], sys.argv[2]
    files = []          # [name, type, start, length, sectors, first]
    total = 0
    pieces = []         # (absolute byte, bytes, where)
    for n, line in enumerate(open(layout, encoding='utf-8'), 1):
        w = line.split()
        if not w or w[0].startswith('#'):
            continue
        where = '%s:%d' % (layout, n)
        if w[0] == 'file':
            name, typ, start, length, sectors = w[1], w[2], number(w[3]), number(w[4]), number(w[5])
            files.append((name, typ, start, length, sectors, total))
            total += sectors
            continue
        s, o = w[1].split('+')
        at = number(s) * 256 + number(o)
        if w[0] == 'zero':
            data = bytes(number(w[2]))
        elif w[0] == 'text':
            text = open(os.path.join(ROOT, w[2]), encoding='utf-8').read()
            data = text.replace('\n', '\r\n').encode('cp866')
        else:
            data = open(os.path.join(ROOT, w[2]), 'rb').read()
            if len(w) > 3:
                frm = number(w[3])
                data = data[frm:frm + number(w[4])] if len(w) > 4 else data[frm:]
        pieces.append((at, data, where))
    disk = bytearray(total * 256)
    owner = [None] * len(disk)
    for at, data, where in pieces:
        for i in range(len(data)):
            if owner[at + i] is not None:
                sys.exit('%s: byte %d+%d also from %s' % (where, (at + i) // 256, (at + i) % 256, owner[at + i]))
            owner[at + i] = where
        disk[at:at + len(data)] = data
    holes = [i for i, x in enumerate(owner) if x is None]
    if holes:
        sys.exit('hole at %d+%d (%d bytes unfilled)' % (holes[0] // 256, holes[0] % 256, len(holes)))
    scl = bytearray(b'SINCLAIR') + bytes([len(files)])
    for name, typ, start, length, sectors, _first in files:
        scl += name.ljust(8).encode('ascii') + typ.encode('ascii') + start.to_bytes(2, 'little') + \
            length.to_bytes(2, 'little') + bytes([sectors])
    scl += disk
    scl += (sum(scl) & 0xFFFFFFFF).to_bytes(4, 'little')
    open(out, 'wb').write(scl)


if __name__ == '__main__':
    main()

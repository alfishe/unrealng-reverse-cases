#!/usr/bin/env python3
"""The test disks of the recordings: the original boot (orig/boot.scl) plus files that exercise the menu.

    python3 tools/mktestdisk.py            # writes tests/disks/many.scl and tests/disks/noexe.scl

many.scl:  boot, then 30 BASIC programs T01 ... T30 (one page holds 24, so two pages), a CODE file of 192 sectors
           (a "magic" snapshot by its size, listed in yellow) and a plain CODE file (not listed).
           Each BASIC program is  10 BORDER n: PRINT "TEST nn": PAUSE 0  with autostart line 10, so the file the
           launcher ran is seen on the screen and in its border.
noexe.scl: boot and two CODE files: no executable file, so the menu says NO EXE FILES !
deep.scl:  boot, 52 BASIC programs T01 ... T52 of which T05 is a deleted entry (first byte 1 in its name), then the
           192-sector CODE file magic: 52 names listed, so three pages (24, 24, 4), a deleted entry the list skips,
           and a snapshot on page 3 to run with GO TO "magic" CODE.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import disk  # noqa: E402


def number(n):
    return str(n).encode() + bytes([0x0E, 0, 0, n & 255, n >> 8, 0])


def program(i):
    line = (bytes([0xE7]) + number(i % 8) + b':' + bytes([0xF5]) + b'"TEST %02d"' % i + b':' + bytes([0xF2])
            + number(0) + b'\r')
    prog = struct.pack('>H', 10) + struct.pack('<H', len(line)) + line
    return prog


def scl(entries):
    head, bodies = [], []
    for name, typ, start, length, body in entries:
        body = body + bytes(-len(body) % 256)
        head.append(name.ljust(8).encode('latin-1') + typ.encode() + struct.pack('<HHB', start, length,
                                                                                  len(body) // 256))
        bodies.append(body)
    d = b'SINCLAIR' + bytes([len(entries)]) + b''.join(head) + b''.join(bodies)
    return d + struct.pack('<I', sum(d) & 0xFFFFFFFF)


def main():
    boot = disk.read(os.path.join(ROOT, 'orig', 'boot.scl'))[0][0]
    bootentry = (boot['name'], boot['type'], boot['start'], boot['length'], boot['body'])
    many = [bootentry]
    for i in range(1, 31):
        p = program(i)
        many.append(('T%02d' % i, 'B', len(p), len(p), p + b'\x80\xAA' + struct.pack('<H', 10)))
    many.append(('magic', 'C', 0x4000, 0xC000, bytes(0xC000)))
    many.append(('data', 'C', 0x8000, 300, bytes(range(256)) + bytes(44)))
    deep = [bootentry]
    for i in range(1, 53):
        p = program(i)
        name = 'T%02d' % i
        deep.append(('\x01' + name[1:] if i == 5 else name, 'B', len(p), len(p),
                     p + b'\x80\xAA' + struct.pack('<H', 10)))
    deep.append(('magic', 'C', 0x4000, 0xC000, bytes(0xC000)))
    noexe = [bootentry, ('screen', 'C', 0x4000, 6912, bytes(6912)), ('data', 'C', 0x8000, 300, bytes(300))]
    out = os.path.join(ROOT, 'tests', 'disks')
    os.makedirs(out, exist_ok=True)
    for name, ents in (('many', many), ('noexe', noexe), ('deep', deep)):
        path = os.path.join(out, name + '.scl')
        open(path, 'wb').write(scl(ents))
        print(path, len(ents), 'files')


if __name__ == '__main__':
    main()

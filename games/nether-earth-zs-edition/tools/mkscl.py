#!/usr/bin/env python3
"""Writes an SCL image from a disk description (src/disk98.txt, src/disk99.txt).

    python3 tools/mkscl.py DESCRIPTION OUT.scl [--root DIR]

The description, one directive a line (# starts a comment; paths are relative to --root, the case by default):

    file NAME TYPE START LENGTH      a catalogue entry: name (up to 8 characters, padded with spaces), type letter, the two words
                                     TR-DOS keeps (for a BASIC file: the program length twice; for code: the address
                                     and the length); the file's body follows
    part PATH                        bytes of the body (a part's build output)
    slack PATH                       the bytes after the body's last part up to the end of its sector, which no
                                     program reads (tools/build.sh derives them: a packed block's sector holds its
                                     own image after it); cut or zero-padded to fit, so an edited part still gives
                                     a whole sector

A body that does not end on a sector boundary is an error unless a `slack` closes it. SCL: "SINCLAIR", the file
count, 14 bytes a file (name, type, the two words, the sector count), the bodies, a 32-bit sum of all bytes before it.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(path, root):
    files, cur = [], None
    for number, line in enumerate(open(path, encoding='utf-8'), 1):
        text = line.split('#', 1)[0].split()
        if not text:
            continue
        what = text[0]
        if what == 'file':
            name, typ, start, length = text[1], text[2], int(text[3], 0), int(text[4], 0)
            cur = dict(name=name.ljust(8)[:8], type=typ, start=start, length=length, body=bytearray())
            files.append(cur)
        elif what == 'part':
            cur['body'] += open(os.path.join(root, text[1]), 'rb').read()
        elif what == 'slack':
            data = open(os.path.join(root, text[1]), 'rb').read()
            need = -len(cur['body']) % 256
            if need != len(data):
                print(f'{path}:{number}: slack {text[1]}: {len(data)} bytes, the sector needs {need}', file=sys.stderr)
            cur['body'] += (data + bytes(need))[:need]
        else:
            sys.exit(f'{path}:{number}: cannot read: {line.rstrip()}')
    for f in files:
        if len(f['body']) % 256:
            sys.exit(f"{f['name']}: {len(f['body'])} bytes, not whole sectors")
    return files


def scl(files):
    out = bytearray(b'SINCLAIR') + bytes([len(files)])
    for f in files:
        out += f['name'].encode('latin-1') + f['type'].encode('latin-1')
        out += f['start'].to_bytes(2, 'little') + f['length'].to_bytes(2, 'little') + bytes([len(f['body']) // 256])
    for f in files:
        out += f['body']
    return bytes(out + (sum(out) & 0xFFFFFFFF).to_bytes(4, 'little'))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('description')
    p.add_argument('out')
    p.add_argument('--root', default=ROOT)
    a = p.parse_args()
    open(a.out, 'wb').write(scl(read(a.description, a.root)))


if __name__ == '__main__':
    main()

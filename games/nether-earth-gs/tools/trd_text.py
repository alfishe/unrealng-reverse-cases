#!/usr/bin/env python3
"""The texts of the TRD extras: a UTF-8 copy (src/res/text/trd-*.txt) <-> the bytes the files hold.

    python3 tools/trd_text.py encode SRC.txt OUT.bin       the text file -> the exact bytes
    python3 tools/trd_text.py check SRC.txt BIN [OFFSET]    the bytes the text gives equal BIN's (at OFFSET)

The text file:

    #codec cp866               the first line: how a character becomes a byte (cp866, ascii)
    # a comment                any line starting with '#'
    text|                      a piece of the text: the line up to its last '|' (spaces before it count); the pieces
                               are joined with nothing between them, so a long line can be cut anywhere
    \\xNN \\\\                     inside a piece: a byte by its hex code (a control code, an end mark), a backslash

So the texts keep their layout for a reader (a scroller's 2000 characters cut into lines at word ends, a menu's
strings one a line with their padding visible before the '|'), and the build gets every byte back.
"""
import argparse
import re
import sys

ESCAPE = re.compile(r'\\(x[0-9A-Fa-f]{2}|\\)')


def encode(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    m = re.match(r'^#codec (\S+)$', lines[0])
    if not m:
        sys.exit(f'{path}:1: the first line must be #codec NAME')
    codec, out = m.group(1), bytearray()
    for number, line in enumerate(lines[1:], 2):
        if not line or line.startswith('#'):
            continue
        if not line.endswith('|'):
            sys.exit(f'{path}:{number}: a text line ends with |')
        piece = line[:-1]
        k = 0
        for e in ESCAPE.finditer(piece):
            out += piece[k:e.start()].encode(codec)
            out += b'\\' if e.group(1) == '\\' else bytes([int(e.group(1)[1:], 16)])
            k = e.end()
        out += piece[k:].encode(codec)
    return bytes(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    e = s.add_parser('encode')
    e.add_argument('src')
    e.add_argument('dst')
    c = s.add_parser('check')
    c.add_argument('src')
    c.add_argument('bin')
    c.add_argument('offset', nargs='?', default='0')
    a = p.parse_args()
    data = encode(a.src)
    if a.cmd == 'encode':
        open(a.dst, 'wb').write(data)
        return 0
    ref = open(a.bin, 'rb').read()
    at = int(a.offset, 0)
    if ref[at:at + len(data)] != data:
        diff = next((i for i in range(len(data)) if at + i >= len(ref) or ref[at + i] != data[i]), None)
        print(f'{a.src}: differs at byte {diff}')
        return 1
    print(f'{a.src}: {len(data)} bytes identical')
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Write the TAP from a layout (src/media/tap.txt), with the kit's block writer (kit/tap.py).

    python3 tools/mktap.py LAYOUT OUT.tap

Lines (names may be quoted, numbers may be $hex; $GAME_DIR in a path as in tools/mkscl.py):

    basic NAME LINE PATH             a PROGRAM header (autostart LINE, param 2 = the length: no variables) + data
    code NAME ADDRESS PATH [PARAM2]  a CODE header (PARAM2 defaults to 32768, as the ROM's SAVE writes it) + data

Every block is a standard ROM block: flag $00 header / $FF data, the XOR checksum after it.
"""
import os
import shlex
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import mkscl  # noqa: E402
import tap  # noqa: E402  (kit/tap.py)


def main():
    layout, out = sys.argv[1], sys.argv[2]
    tape = bytearray()
    for n, line in enumerate(open(layout, encoding='utf-8'), 1):
        w = shlex.split(line, comments=True)
        if not w:
            continue
        if w[0] not in ('basic', 'code'):
            sys.exit('%s:%d: cannot read: %s' % (layout, n, line.strip()))
        data = open(mkscl.path(w[3]), 'rb').read()
        if w[0] == 'basic':
            tape += tap.block(0, tap.header(0, w[1], len(data), mkscl.number(w[2]), len(data)))
        else:
            param2 = mkscl.number(w[4]) if len(w) > 4 else 32768
            tape += tap.block(0, tap.header(3, w[1], len(data), mkscl.number(w[2]), param2))
        tape += tap.block(0xFF, data)
    open(out, 'wb').write(tape)


if __name__ == '__main__':
    main()

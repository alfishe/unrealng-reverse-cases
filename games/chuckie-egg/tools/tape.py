#!/usr/bin/env python3
"""The tape's four data blocks as a TAP file, from the built parts or from the original.

    python3 tools/tape.py OUT.tap loader.bin errsp.bin game.bin    # the build: blocks 1-4 from the sources
    python3 tools/tape.py --orig OUT.tap                           # the original's blocks 1-4 (TZX blocks 1-4)

Block 1 is the header "CHUCKIE": type 0 (program), length 1624, LINE 10 and parameter 2 = 18, the length of the
program without its variables (line 10 alone; the array a$ that carries the loader follows it). kit/tap.py's `basic`
writes parameter 2 = the whole length, so this script writes the header itself with kit/tap.py's block() and
header(). Blocks 2-4 are flag `$FF` data blocks with their XOR checksums (kit/tap.py block()). The TZX's pilot,
sync and bit timings and its pauses are not data and are not rebuilt (docs/03-build-and-load.md 3.1).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import tap  # noqa: E402  kit/tap.py

PROGRAM_LENGTH = 18  # line 10: RANDOMIZE USR 24307


def build(out, loader, errsp, game):
    basic = open(loader, 'rb').read()
    data = tap.block(0, tap.header(0, 'CHUCKIE', len(basic), 10, PROGRAM_LENGTH))
    data += tap.block(0xFF, basic)
    data += tap.block(0xFF, open(errsp, 'rb').read())
    data += tap.block(0xFF, open(game, 'rb').read())
    open(out, 'wb').write(data)


def orig(out):
    sys.path.insert(0, HERE)
    import image
    data = bytearray()
    for b in image.blocks():
        data += len(b['data']).to_bytes(2, 'little') + b['data']
    open(out, 'wb').write(data)


if __name__ == '__main__':
    if sys.argv[1] == '--orig':
        orig(sys.argv[2])
    else:
        build(*sys.argv[1:5])

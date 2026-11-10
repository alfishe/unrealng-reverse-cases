#!/usr/bin/env python3
"""The original tape's four data blocks as a TAP file, for the build's cmp (tools/build.sh).

    python3 tools/tape.py --orig OUT.tap      # the original's blocks 1-4 (TZX blocks 1-4)

The build writes its own tape with kit/tap.py (basic:CHUCKIE:10:loader.bin and three data blocks): block 1, the header
"CHUCKIE" with LINE 10 and parameter 2 = 18, the program without its variables (line 10 alone; the array a$ that
carries the loader follows it). The TZX's pilot, sync and bit timings and its pauses are not data and are not rebuilt
(docs/03-build-and-load.md 3.1).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def orig(out):
    sys.path.insert(0, HERE)
    import image
    data = bytearray()
    for b in image.blocks():
        data += len(b['data']).to_bytes(2, 'little') + b['data']
    open(out, 'wb').write(data)


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] != '--orig':
        sys.exit(__doc__)
    orig(sys.argv[2])

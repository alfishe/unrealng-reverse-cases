#!/usr/bin/env python3
"""The original tape's five data blocks as a TAP file, for the build's cmp (tools/build.sh).

    python3 tools/tape.py --orig OUT.tap      # TZX blocks 1-5 of orig/Tujad.tzx.zip, each as a TAP block

The build writes its own tape with kit/tap.py: the BASIC header "TUJAD" (LINE 10, program length 88) and block 2, the
CODE header "TUJAD" (6944 bytes at 32768, parameter 2 32768) and block 4, then block 5 headerless. The TZX's archive
info, its pilot, sync and bit timings and its pauses are not data and are not rebuilt (docs/03-build-and-load.md 3.1).
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

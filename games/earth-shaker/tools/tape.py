#!/usr/bin/env python3
"""The original tape's four Earth Shaker blocks as a TAP file, for the build's cmp (tools/build.sh).

    python3 tools/tape.py --orig OUT.tap      # TZX blocks 10-13 of Side 1 of orig/YSIssue63-SixPack.tzx.zip

The side holds six programs one after another (Biggles, Timewarp, two headerless blocks, Earth Shaker, the
Switchblade demo). tools/image.py picks Earth Shaker's four blocks by the BASIC header "EARTH" (flag $00, type 0,
the name "EARTH" padded to ten characters) and the three standard blocks after it: TZX blocks 10-13. The rest of the
side is not ours and is not rebuilt. The build writes its own tape with kit/tap.py: the BASIC header "EARTH" (LINE 1,
program length 107) and block 11, the CODE header "EARTH" (37 566 bytes at 27970, parameter 2 32768) and block 13.
The TZX's text block 9, its pilot, sync and bit timings and its pauses are not data and are not rebuilt
(docs/03-build-and-load.md 3.1).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def orig(out):
    sys.path.insert(0, HERE)
    import image
    data = bytearray()
    for _, b in image.game_blocks():
        data += len(b).to_bytes(2, 'little') + b
    open(out, 'wb').write(data)


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] != '--orig':
        sys.exit(__doc__)
    orig(sys.argv[2])

#!/usr/bin/env python3
"""The data blocks of the original tape (`Video Pool.tzx` in orig/VideoPool.tzx.zip, TZX blocks 1-5) as a TAP file:
each block's bytes (flag, data, checksum) behind its 16-bit length. tools/build.sh compares the built tape with it,
so the check covers the two headers, the BASIC, the turbo loader and the turbo block's flag and XOR checksum; the
TZX's timings and pauses are not data (docs/03-build-and-load.md 3.1).

    python3 tools/origtap.py OUT.tap
"""
import sys

import image


def main():
    out = bytearray()
    for b in image.blocks()[1:6]:
        d = b['data']
        out += len(d).to_bytes(2, 'little') + d
    open(sys.argv[1], 'wb').write(out)


if __name__ == '__main__':
    main()

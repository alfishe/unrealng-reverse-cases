#!/usr/bin/env python3
"""A first sprite sheet of ATV Simulator from the data: every graphic the sprite entry `$865F` was given in the play
recordings (the L1 `patterns` record of `$865F`: HL's bases), drawn from the image as the loader leaves it.

    python3 tools/sprite_sheet.py IMAGE.bin OUT.png L1 [L1 ...]

A graphic is a header and its lines (`$865F`): +0 the width in bytes (`$80F2`), +1 the height in lines (`$80F3`), +2 a
byte kept in `$80F6`, +3 the pixel shift the data is in now (`$80F4` points at it: `$8759` / `$8777` shift the data
in place to the shift the drawing needs, so the image as loaded holds each graphic at its first shift), +4 the bytes,
width × height, a line at a time; `$8D53` ORs them into the play buffer (22 bytes a line). Each graphic is drawn at
2x with its address; headers outside 1-8 bytes wide or 1-96 lines high are left out (bases that are not headers).

A wrapper of kit/pattern_sheet.py (`--routine 865F --width-at 0 --height-at 1 --data-at 4`), which draws the same
picture and prints each base with its L1s and header bytes.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import pattern_sheet  # noqa: E402


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    return pattern_sheet.main(['--routine', '865F', '--width-at', '0', '--height-at', '1', '--data-at', '4',
                               '--image', sys.argv[1], '--out', sys.argv[2]] + sys.argv[3:])


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The tape's data blocks as files, for the static pass (docs/03-build-and-load.md 3.1):

    python3 tools/tape_files.py work/media      # exolon.bas, loader.bin, block6.bin (picy), block8.bin (code)
"""
import os
import sys

import image

NAMES = {2: 'exolon.bas', 4: 'loader.bin', 6: 'block6.bin', 8: 'block8.bin'}

if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    blocks = image.blocks()
    for k, name in NAMES.items():
        open(os.path.join(out, name), 'wb').write(blocks[k]['data'][1:-1])
        print('wrote', os.path.join(out, name), len(blocks[k]['data']) - 2)

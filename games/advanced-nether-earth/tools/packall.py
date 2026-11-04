#!/usr/bin/env python3
"""Pack images with HRUM 3.5 (tools/hrum.py) for the block sources: one stream a NAME, and their lengths for sjasmplus.

    python3 tools/packall.py OUTDIR NAME=IMAGE ...

Writes OUTDIR/NAME.hrm (the stream) and appends `PK_NAME EQU length` to OUTDIR/sizes.inc (the macro HRUM_SFX of
src/sfx/hrum35.asm needs the stream's length for its LDDR and its LD SP; sjasmplus has no file-size function).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hrum  # noqa: E402


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    sizes = os.path.join(out, 'sizes.inc')
    with open(sizes, 'a') as inc:
        for arg in sys.argv[2:]:
            name, image = arg.split('=', 1)
            stream, _tail = hrum.pack(open(image, 'rb').read())
            open(os.path.join(out, name + '.hrm'), 'wb').write(stream)
            inc.write('PK_%s EQU %d\n' % (name, len(stream)))


if __name__ == '__main__':
    main()

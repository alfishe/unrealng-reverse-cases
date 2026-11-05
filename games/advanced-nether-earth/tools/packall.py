#!/usr/bin/env python3
"""Pack images with HRUM 3.5 (tools/hrum.py) for the block sources: one stream a NAME, and their lengths for sjasmplus.

    python3 tools/packall.py OUTDIR NAME=IMAGE ...

Writes OUTDIR/NAME.hrm (the stream), OUTDIR/NAME.img (the image, whose last 5 bytes the block keeps in the
depacker's tail) and appends `PK_NAME EQU` the stream's length and `UN_NAME EQU` the image's to OUTDIR/sizes.inc (the
macro HRUM_SFX of src/sfx/hrum35.asm needs them for its LDDR and its LD SP; sjasmplus has no file-size function).
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
            data = open(image, 'rb').read()
            stream, _tail = hrum.pack(data)
            open(os.path.join(out, name + '.hrm'), 'wb').write(stream)
            open(os.path.join(out, name + '.img'), 'wb').write(data)
            inc.write('PK_%s EQU %d\nUN_%s EQU %d\n' % (name, len(stream), name, len(data)))


if __name__ == '__main__':
    main()

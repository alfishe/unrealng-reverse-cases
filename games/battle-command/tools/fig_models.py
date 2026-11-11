#!/usr/bin/env python3
"""Write the 3D model listings and figures of src/res/models from the mission texts and the bank 3 part.

    python3 tools/fig_models.py            # src/res/models/NN-NAME.txt and .png, bank3-shared.txt and .png

The listings are a view of bytes kept elsewhere (the mission texts' `bytes` lines, bank 3 `SharedModels` `$CA8B`);
tools/models3d.py reads the scripts (the opcodes are in its docstring and src/res/models/README.md).
"""
import glob
import io
import os
import sys
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import models3d  # noqa: E402

CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'src/res/models')


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in sorted(glob.glob(os.path.join(CASE, 'src/res/missions/[0-9][0-9]-*.txt'))):
        name = os.path.basename(f)[:-4]
        buf = io.StringIO()
        with redirect_stdout(buf):
            sys.argv = ['models3d', 'mission', f]
            models3d.main()
        open(os.path.join(OUT, name + '.txt'), 'w').write(buf.getvalue())
        d, ms = models3d.mission_models(open(f).read())
        models3d.figure(d, 0xDBC5, 0, 0, os.path.join(OUT, name + '.png'), name, ms)
        print('%s: %d models' % (name, len(ms)))
    b3 = open(os.path.join(CASE, 'work/parts/bank3-c000.bin'), 'rb').read()
    lib = models3d.library(b3, 0xC000, 0xCA8B, 0xCFCD)
    with open(os.path.join(OUT, 'bank3-shared.txt'), 'w') as o:
        o.write('# bank 3 SharedModels $CA8B-$CFCC (tools/models3d.py list work/parts/bank3-c000.bin C000 CA8B CFCD)\n')
        for m, lines in lib:
            o.write('model $%04X\n' % m + ''.join('  $%04X %s\n' % x for x in lines) + '\n')
    models3d.figure(b3, 0xC000, 0xCA8B, 0xCFCD, os.path.join(OUT, 'bank3-shared.png'), 'bank 3 SharedModels')
    print('bank3-shared: %d models' % len(lib))
    return 0


if __name__ == '__main__':
    sys.exit(main())

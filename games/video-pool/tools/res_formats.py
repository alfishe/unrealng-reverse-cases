#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every file round-trips to the original bytes

Start with every resource as bytes (the default here); give a kind its editable format (PNG for graphics, text for a
tune or a level) one at a time, each with check proving it. H.A.T.E.'s tools/res_formats.py is a full example.
"""
import argparse
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')

# name pattern -> (to_editable(bytes) -> (suffix, data), from_editable(data) -> bytes); none yet
FORMATS = []


def install(files):
    for name, data in files.items():
        path = os.path.join(RES, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(data)


def build(out):
    for top, _dirs, names in os.walk(RES):
        for n in names:
            if n == 'README.md':
                continue
            src = os.path.join(top, n)
            dst = os.path.join(out, os.path.relpath(src, RES))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(src, dst)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
    else:
        print('res: every file is its bytes (no editable formats yet)')
    return 0


if __name__ == '__main__':
    sys.exit(main())

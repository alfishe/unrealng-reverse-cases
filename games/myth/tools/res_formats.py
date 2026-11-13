#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file goes to bytes and back unchanged

The formats live in the modules tools/res_*.py, one module a kind of data (res_graphics.py, res_rooms.py, ...). Each
module has a list FORMATS of (PATTERN, SUFFIX, to_editable, from_editable):

    PATTERN        a regular expression on the resource's name as the .ann gives it (`stage1/tiles.bin`)
    SUFFIX         the editable file's suffix that replaces `.bin` (`.png`, `.txt`)
    to_editable    f(name, bytes) -> the editable file's bytes
    from_editable  f(name, the editable file's bytes) -> the original bytes

The first module (in name order) whose pattern matches wins. A resource no pattern matches stays its bytes
(`NAME.bin`); src/res/README.md says why for each. The build (tools/build.sh) proves the bytes: it rebuilds the tape
from build/res and compares it with the original.
"""
import argparse
import glob
import importlib
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, HERE)


def formats():
    out = []
    for path in sorted(glob.glob(os.path.join(HERE, 'res_*.py'))):
        name = os.path.basename(path)[:-3]
        if name == 'res_formats':
            continue
        out += [(re.compile(p), s, t, f) for p, s, t, f in importlib.import_module(name).FORMATS]
    return out


def match(name, fmts):
    for f in fmts:
        if f[0].search(name):
            return f
    return None


def install(files):
    fmts = formats()
    for name, data in files.items():
        f = match(name, fmts)
        path = os.path.join(RES, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if f:
            path = path[:-len('.bin')] + f[1] if path.endswith('.bin') else path + f[1]
            data = f[2](name, data)
        open(path, 'wb').write(data)


def editables():
    """(the file under src/res, the resource name, its format or None) for every file under src/res"""
    fmts = formats()
    for top, _dirs, names in os.walk(RES):
        for n in sorted(names):
            if n == 'README.md' or n.startswith('.'):
                continue
            src = os.path.join(top, n)
            rel = os.path.relpath(src, RES)
            base, suffix = os.path.splitext(rel)
            f = match(base + '.bin', fmts)
            if f and f[1] == suffix:
                yield src, base + '.bin', f
            else:
                yield src, rel, None


def build(out):
    for src, name, f in editables():
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if f:
            open(dst, 'wb').write(f[3](name, open(src, 'rb').read()))
        else:
            shutil.copyfile(src, dst)


def check():
    bad = n = 0
    for src, name, f in editables():
        if not f:
            continue
        n += 1
        data = open(src, 'rb').read()
        if f[2](name, f[3](name, data)) != data:
            bad += 1
            print('res: %s does not come back unchanged through its bytes' % os.path.relpath(src, ROOT))
    print('res: %d editable files, %d bad' % (n, bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

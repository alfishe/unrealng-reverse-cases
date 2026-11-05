#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of src/game/game.ann.

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the source INCBINs
    python3 tools/res_formats.py check                     # every editable file both ways: to bytes and back the same

The formats live in the plugins tools/res_*.py: each has KINDS, a list of (pattern, suffix, to_editable, from_editable)
where pattern is an fnmatch of the resource's name under src/res (as game.ann's @res names it, ending .bin), suffix
replaces .bin in the editable file's name, to_editable(bytes, name) -> bytes and from_editable(bytes, name) -> bytes.
A resource no pattern matches stays as its bytes. Other files under src/res (a .scr, a README, previews *.preview.png)
are copied as they are, previews and READMEs left out.
"""
import argparse
import fnmatch
import glob
import importlib
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, HERE)


def kinds():
    out = []
    for path in sorted(glob.glob(os.path.join(HERE, 'res_*.py'))):
        name = os.path.splitext(os.path.basename(path))[0]
        if name == 'res_formats':
            continue
        out += importlib.import_module(name).KINDS
    return out


def kind_of(name):
    for k in kinds():
        if fnmatch.fnmatch(name, k[0]):
            return k
    return None


def install(files):
    """The @res entries' bytes as their editable files under src/res; each proved both ways"""
    for name, data in files.items():
        k = kind_of(name)
        path = os.path.join(RES, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if k is None:
            open(path, 'wb').write(data)
            continue
        edit = k[2](data, name)
        if k[3](edit, name) != data:
            sys.exit(f'res: {name}: the editable form does not give the bytes back')
        if os.path.exists(path):
            os.remove(path)
        open(path[:-4] + k[1], 'wb').write(edit)


def sources():
    """(path under src/res, the resource name it builds, kind or None) of every source file"""
    suffixes = {k[1]: k for k in kinds()}
    for top, _dirs, names in os.walk(RES):
        for n in sorted(names):
            if n == 'README.md' or n.endswith('.preview.png') or n.startswith('.'):
                continue
            rel = os.path.relpath(os.path.join(top, n), RES)
            hit = None
            for suffix, k in suffixes.items():
                if rel.endswith(suffix) and fnmatch.fnmatch(rel[:-len(suffix)] + '.bin', k[0]):
                    hit = k
                    break
            yield rel, (rel[:-len(hit[1])] + '.bin') if hit else rel, hit


def build(out):
    for rel, name, k in sources():
        src = os.path.join(RES, rel)
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if k is None:
            shutil.copyfile(src, dst)
        else:
            open(dst, 'wb').write(k[3](open(src, 'rb').read(), name))


def check():
    bad = n = 0
    for rel, name, k in sources():
        if k is None:
            continue
        n += 1
        edit = open(os.path.join(RES, rel), 'rb').read()
        data = k[3](edit, name)
        again = k[2](data, name)
        if again != edit:
            bad += 1
            print(f'res: {rel}: bytes -> editable is not the file')
    print(f'res: {n} editable files, ' + ('every one both ways' if not bad else f'{bad} FAIL'))
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

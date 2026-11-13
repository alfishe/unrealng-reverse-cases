#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry of a part (the game, the loader, the music).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py check --against DIR       # ... and gives the bytes of DIR/<name>

The formats live in the format modules tools/res_*.py, each with two tables:
- SINGLES {bin name: (suffix, to_editable(bytes) -> bytes, from_editable(bytes) -> bytes)}: one resource, one file
  (src/res/screens/loading.png for screens/loading.scr);
- GROUPS {editable name: ([bin names], to_editable({bin: bytes}) -> bytes, from_editable(bytes) -> {bin: bytes})}:
  several resources in one file (a level's map, zones and objects in one text).
Each folder's README.md lists its files, addresses, formats and readers. A file no module claims stays its bytes.
"""
import argparse
import glob
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, HERE)

SINGLES, GROUPS = {}, {}
for _path in sorted(glob.glob(os.path.join(HERE, 'res_*.py'))):
    _name = os.path.splitext(os.path.basename(_path))[0]
    if _name == 'res_formats':
        continue
    _mod = importlib.import_module(_name)
    SINGLES.update(getattr(_mod, 'SINGLES', {}))
    GROUPS.update(getattr(_mod, 'GROUPS', {}))


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if not os.path.exists(path) or open(path, 'rb').read() != data:
        open(path, 'wb').write(data)


def group_of(name):
    return next((ed for ed, (bins, _a, _b) in GROUPS.items() if name in bins), None)


def install(files):
    # case.json "built": resources a build step makes (the second stage, the AY player): never installed as bytes
    import json
    built = json.load(open(os.path.join(ROOT, 'case.json'))).get('built', {})
    files = {k: v for k, v in files.items() if k not in built}
    done = set()
    for ed, (bins, to_ed, from_ed) in GROUPS.items():
        if not all(b in files for b in bins):
            continue
        part = {b: files[b] for b in bins}
        out = to_ed(part)
        if from_ed(out) != part:
            raise SystemExit('res: %s does not convert back to its bytes' % ed)
        write(os.path.join(RES, ed), out)
        done |= set(bins)
    for name, data in files.items():
        if name in done:
            continue
        if group_of(name):
            raise SystemExit('res: %s is part of %s, whose other resources were not given' % (name, group_of(name)))
        if name in SINGLES:
            suffix, to_ed, from_ed = SINGLES[name]
            out = to_ed(data)
            if from_ed(out) != data:
                raise SystemExit('res: %s does not convert back to its bytes' % name)
            write(os.path.join(RES, os.path.splitext(name)[0] + suffix), out)
        else:
            write(os.path.join(RES, name), data)


def sources():
    """(src path, rel, kind) for every file of src/res: kind 'group', 'single' or None (bytes)"""
    singles = {os.path.splitext(n)[0] + s: n for n, (s, _a, _b) in SINGLES.items()}
    for top, _dirs, names in sorted(os.walk(RES)):
        for f in sorted(names):
            if f == 'README.md' or f.startswith('.'):
                continue
            src = os.path.join(top, f)
            rel = os.path.relpath(src, RES)
            if rel in GROUPS:
                yield src, rel, 'group'
            elif rel in singles:
                yield src, rel, 'single'
            else:
                yield src, rel, None


def to_bytes(rel, kind, raw):
    """{bin name: bytes} of one src/res file"""
    if kind == 'group':
        return GROUPS[rel][2](raw)
    if kind == 'single':
        name = next(n for n, (s, _a, _b) in SINGLES.items() if os.path.splitext(n)[0] + s == rel)
        return {name: SINGLES[name][2](raw)}
    return {rel: raw}


def build(out):
    for src, rel, kind in sources():
        for name, data in to_bytes(rel, kind, open(src, 'rb').read()).items():
            write(os.path.join(out, name), data)


def check(against=None):
    bad = count = 0
    for src, rel, kind in sources():
        raw = open(src, 'rb').read()
        data = {}
        if kind:
            count += 1
            try:
                data = to_bytes(rel, kind, raw)
                if kind == 'group':
                    again = GROUPS[rel][1](data)
                else:
                    (name, d), = data.items()
                    again = SINGLES[name][1](d)
                ok = again == raw and to_bytes(rel, kind, again) == data
            except (ValueError, KeyError, IndexError) as e:
                print('res: %s: %s' % (src, e))
                ok = False
            if not ok:
                print('res: %s does not round-trip' % os.path.relpath(src, ROOT))
                bad += 1
        else:
            data = {rel: raw}
        for name, d in data.items():
            ref = os.path.join(against, name) if against else None
            if ref and os.path.exists(ref) and open(ref, 'rb').read() != d:
                print('res: %s differs from %s' % (os.path.relpath(src, ROOT), ref))
                bad += 1
    print('res: %d editable files, %d bad' % (count, bad))
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--against')
    args = p.parse_args()
    if args.command == 'build':
        build(args.out)
        return 0
    return check(args.against)


if __name__ == '__main__':
    sys.exit(main())

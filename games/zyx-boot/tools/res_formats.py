#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the menu's src/game, the music's src/music, the BASIC's src/basic).

    python3 tools/res_formats.py build --out build/res     # src/res -> the bytes the sources INCBIN
    python3 tools/res_formats.py check                     # every editable file converts to bytes and back unchanged
    python3 tools/res_formats.py build --src DIR --out DIR  # another tree of editable files (a variant, tools/variants.py)

A resource NAME.bin of a kind with an editable form is kept only in that form (NAME.png, NAME.txt); the converters
live in their own modules, one a kind, each with to_editable(name, bytes) -> (suffix, data) and from_editable(name,
data) -> bytes:
- tools/res_gfx.py: the font (graphics/font.png), the logo letters and the rhombus (graphics/*.png), the twinkle
  frames, as indexed PNG sheets;
- tools/res_tables.py: the star tables, the attribute and fade colours, the key table and the other tables, as text;
- tools/res_text.py: the menu's strings (texts/*.txt, UTF-8);
- tools/res_music.py: the ASC Sound Master tune (music/*.txt).
Each folder's README.md lists its files. A kind whose module is missing stays its bytes.
"""
import argparse
import importlib
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
sys.path.insert(0, os.path.join(ROOT, 'tools'))

# folder of the resource -> the converter module
KINDS = {'graphics': 'res_gfx', 'tables': 'res_tables', 'texts': 'res_text', 'music': 'res_music'}


def converter(name):
    kind = name.split('/')[0]
    mod = KINDS.get(kind)
    if not mod:
        return None
    try:
        m = importlib.import_module(mod)
    except ModuleNotFoundError as e:
        if e.name == mod:
            return None
        raise
    return m if m.handles(name) else None


def install(files):
    for name, data in files.items():
        m = converter(name)
        path = os.path.join(RES, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if m:
            suffix, out = m.to_editable(name, data)
            open(path[:-4] + suffix, 'wb').write(out)
            if os.path.exists(path):
                os.remove(path)
        else:
            open(path, 'wb').write(data)


def sources(res=RES):
    """(the .bin name, the source file, the converter or None) of every resource in res (src/res)"""
    for top, _dirs, names in os.walk(res):
        for n in sorted(names):
            if n.endswith('.md') or n.startswith('.'):
                continue
            src = os.path.join(top, n)
            rel = os.path.relpath(src, res)
            name = os.path.splitext(rel)[0] + '.bin'
            m = converter(name) if not n.endswith('.bin') else None
            yield name, src, m


def build(out, res=RES):
    for name, src, m in sources(res):
        dst = os.path.join(out, name)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if m:
            open(dst, 'wb').write(m.from_editable(name, open(src, 'rb').read()))
        else:
            shutil.copyfile(src, dst)


def check():
    bad = n = 0
    for name, src, m in sources():
        if not m:
            continue
        n += 1
        data = m.from_editable(name, open(src, 'rb').read())
        suffix, again = m.to_editable(name, data)
        back = m.from_editable(name, again)
        if back != data or again != open(src, 'rb').read():
            print(f'res: {os.path.relpath(src, ROOT)} does not round-trip')
            bad += 1
    print(f'res: {n} editable files round-trip' if not bad else f'res: {bad} of {n} files fail')
    return 1 if bad else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['build', 'check'])
    p.add_argument('--out', default=os.path.join(ROOT, 'build', 'res'))
    p.add_argument('--src', default=RES, help='the editable files (src/res; tools/variants.py passes a variant\'s overlay)')
    args = p.parse_args()
    if args.command == 'build':
        build(args.out, args.src)
        return 0
    return check()


if __name__ == '__main__':
    sys.exit(main())

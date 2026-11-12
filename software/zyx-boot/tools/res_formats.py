#!/usr/bin/env python3
"""The case's resources in editable formats (src/res) and back to bytes (build/res); kit/mkgame.py --install calls
install(files) with the bytes of each @res entry (the menu's src/main, the music's src/music, the BASIC's src/basic).

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
- tools/res_basic.py: the BASIC sector's program lines (basic/launch-lines.txt, basic/line-ten.txt) as a listing;
- tools/res_music.py: the ASC Sound Master tunes (music/disco.txt, a variant's music/asc.txt);
- tools/res_stc.py, tools/res_fuxoft.py: a variant's Sound Tracker and Fuxoft tunes (music/stc.txt, music/fuxoft.txt);
- tools/res_rip.py: the tunes of five one-off game-rip players (music/hydrofool.txt, megaapoc, ziutek, awbt, fp3bt);
- tools/res_whittaker.py, tools/res_sheridan.py, tools/res_daglish.py: the tunes of the game rips' drivers (David
  Whittaker, Ian Sheridan, Ben Daglish: a variant's music/whittaker.txt, sheridan.txt, daglish.txt);
- tools/res_variants.py: the resources only a variant's own parts have (zyxskybt's picture, Cyrillic font, scroll text).
Each folder's README.md lists its files. A kind whose module is missing stays its bytes. `check` also runs over every
variant's tree (variants/NAME: its resources, its music and its BASIC listing basic.txt, tools/res_basic.py).
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
KINDS = {'graphics': ['res_variants', 'res_screens', 'res_gfx'], 'tables': ['res_variants', 'res_tables'],
         'texts': ['res_variants', 'res_text'], 'basic': ['res_basic'],
         'music': ['res_music', 'res_stc', 'res_fuxoft', 'res_whittaker', 'res_sheridan', 'res_daglish', 'res_rip']}


def converter(name):
    kind = name.split('/')[0]
    mods = KINDS.get(kind)
    for mod in [mods] if isinstance(mods, str) else mods or []:
        try:
            m = importlib.import_module(mod)
        except ModuleNotFoundError as e:
            if e.name == mod:
                continue
            raise
        if m.handles(name):
            return m
    return None


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


def round_trip(name, src, m):
    if hasattr(m, 'round_trip_text'):   # a BASIC listing: its fill lines are bytes only the build puts in
        return m.round_trip_text(open(src).read())
    data = m.from_editable(name, open(src, 'rb').read())
    suffix, again = m.to_editable(name, data)
    back = m.from_editable(name, again)
    return back == data and again == open(src, 'rb').read()


def variant_sources():
    """(the .bin name, the source file, the converter) of every editable file of every variant (variants/NAME)"""
    import res_basic
    var = os.path.join(ROOT, 'variants')
    for v in sorted(os.listdir(var)):
        vdir = os.path.join(var, v)
        if v == 'players' or not os.path.isfile(os.path.join(vdir, 'variant.json')):
            continue
        for name, src, m in sources(vdir):
            if name.split('/')[0] in KINDS and m:
                yield name, src, m
        if os.path.exists(os.path.join(vdir, 'basic.txt')):
            yield 'basic.bin', os.path.join(vdir, 'basic.txt'), res_basic


def check():
    bad, n, nv, vs = 0, 0, 0, set()
    files = [(name, src, m, False) for name, src, m in sources() if m]
    files += [(name, src, m, True) for name, src, m in variant_sources()]
    for name, src, m, in_variant in files:
        n += 1
        if in_variant:
            nv += 1
            vs.add(os.path.relpath(src, os.path.join(ROOT, 'variants')).split(os.sep)[0])
        try:
            ok = round_trip(name, src, m)
        except Exception as e:      # a file that does not read back is a failure, not a crash of the check
            ok = False
            print(f'res: {os.path.relpath(src, ROOT)}: {e}')
        if not ok:
            print(f'res: {os.path.relpath(src, ROOT)} does not round-trip')
            bad += 1
    print(f'res: {n} editable files round-trip ({n - nv} in src/res, {nv} in {len(vs)} variants)' if not bad
          else f'res: {bad} of {n} files fail')
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

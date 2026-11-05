#!/usr/bin/env python3
"""The '98 game's source from src/game98/game.ann: kit/mkgame.py with this part's own config.

    python3 tools/game98_mkgame.py [--install] [--venv VENV] [--sjasmplus BIN]

The image is tools/game98_image.py's (the file's sectors 44-156 at `$6780-$D87F`, from orig/). kit/mkgame.py writes
the modules into work/stage2/game98/mk and assembles them against that image. With --install, once the bytes are
identical, the modules go to src/game98 with the top file game98.asm (kit's game.asm renamed, its SAVEBIN naming
game98.bin), and the resources (@res names under `game98/`) to src/res/game98 through tools/game98_res.py. Unlike
mkgame's own --install it removes no other file of src/game98.

What it changes in kit/mkgame.py:

- The config is CONFIG below, not C/case.json (the lead's file).
- Only this part's windows are read (WINDOWS: the L1 builds in work/stage2/game98/<window>/l1.json, each from the
  game's arrival on), each clamped to the game's range; never every work/*/l1.json.
"""
import argparse
import importlib.util
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit', 'mkgame.py')
WORK = os.path.join(ROOT, 'work', 'stage2', 'game98')
OUT = os.path.join(WORK, 'mk')
ANN = os.path.join(ROOT, 'src', 'game98', 'game.ann')
DEST = os.path.join(ROOT, 'src', 'game98')
VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
SJASMPLUS = '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'

LO, HI = 0x6780, 0xD880
CONFIG = {
    'image': os.path.join(OUT, 'original.bin'),
    'device': 'ZXSPECTRUM48',
    'bases': {5: 0x4000, 2: 0x8000, 0: 0xC000},
    'header': ["; Nether Earth ZS Edition '98 (ZS, 23.12.1998): the game, the file NEZSEd.B's sectors 44-156 as the REM",
               "; loader reads them to $6780-$D87F (28928 bytes, not packed); entered at Start $A600."],
}
# (window, reads count): the L1 builds this part reads (STATE-game98.md says how each was made)
WINDOWS = [
    ('play', True),        # r98 frames 4500-5903: the menu, START GAME, play
    ('key5menu', True),    # key5 frames 0-414: the menu, key 5 (LOAD NEW LEVEL), the menu again, key 0, set-up
    ('deep', True),        # deep: NE's bot playing the '98 for many game days (robots built, orders, fights)
]


def load_kit():
    spec = importlib.util.spec_from_file_location('mkgame', KIT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--install', action='store_true')
    p.add_argument('--venv', default=VENV)
    p.add_argument('--sjasmplus', default=SJASMPLUS)
    p.add_argument('--ann', default=ANN)
    a = p.parse_args()
    shutil.rmtree(OUT, ignore_errors=True)   # no resource or module of an earlier run left behind
    os.makedirs(OUT)
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import game98_image  # noqa: E402
    sys.argv = ['game98_image.py', '--out', OUT]
    game98_image.main()
    kit = load_kit()

    def own_case(case):
        kit.ROOT = ROOT
        kit.LO, kit.HI = LO, HI
        kit.BASES = dict(CONFIG['bases'])
        return dict(CONFIG)
    kit.load_case = own_case

    def own_l1(paths, mem):
        """this part's windows, clamped to the game's range"""
        starts, entries, reads = set(), set(), [0] * 0x10000
        for name, count_reads in WINDOWS:
            path = os.path.join(WORK, name, 'l1.json')
            if not os.path.exists(path):
                continue
            doc = json.load(open(path))
            for z80, page, code, *_ in doc['instructions']:
                at = int(z80[1:], 16)
                raw = bytes.fromhex(code)
                if page not in kit.BASES or not LO <= at or at + len(raw) > HI:
                    continue
                if kit.decode(mem, at)[0] == len(raw) and mem[at] == raw[0]:
                    starts.add(at)
            for r in doc['routines']:
                at = int(r['entry'][1:], 16)
                # 'root' alone: where the window began, mid-routine (the menu snapshot's PC), no routine's entry
                if r['kinds'] != 'root' and r['page'] in kit.BASES and LO <= at < HI:
                    entries.add(at)
            if count_reads:
                for pg in doc.get('byte_counts', []):
                    base = kit.BASES.get(pg['page'])
                    if base is None:
                        continue
                    for i, n in enumerate(pg['reads']):
                        if n and LO <= base + i < HI:
                            reads[base + i] += n
        return starts, entries, reads
    kit.load_l1 = own_l1

    header = kit.header

    def own_header(config):
        return header(config).replace('from src/game/game.ann', 'from src/game98/game.ann (tools/game98_mkgame.py)') \
                             .replace('edit game.ann', 'edit src/game98/game.ann')
    kit.header = own_header

    sys.argv = [KIT, '--case', ROOT, '--venv', a.venv, '--sjasmplus', a.sjasmplus, '--out', OUT, '--ann', a.ann]
    status = kit.main()
    if status or not a.install:
        return status
    modules = [m for _, m in kit.Annotations(a.ann).modules]
    os.makedirs(DEST, exist_ok=True)
    for name in modules:
        shutil.copyfile(os.path.join(OUT, name + '.asm'), os.path.join(DEST, name + '.asm'))
    top = open(os.path.join(OUT, 'game.asm')).read().replace('SAVEBIN "game.bin"', 'SAVEBIN "game98.bin"')
    open(os.path.join(DEST, 'game98.asm'), 'w').write(top)
    import game98_res  # noqa: E402
    res = os.path.join(OUT, 'res')
    files = {}
    for folder, _, fs in os.walk(res):
        for f in sorted(fs):
            rel = os.path.relpath(os.path.join(folder, f), res).replace(os.sep, '/')
            if not rel.startswith(game98_res.PREFIX):
                sys.exit(f'game98_mkgame: resource {rel} is not under {game98_res.PREFIX}')
            files[rel[len(game98_res.PREFIX):]] = open(os.path.join(folder, f), 'rb').read()
    game98_res.install(files)
    print(f'installed {len(modules) + 1} files in src/game98, {len(files)} resources in src/res/game98')
    return 0


if __name__ == '__main__':
    sys.exit(main())

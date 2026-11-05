#!/usr/bin/env python3
"""The '98 intro block ($C000-$E9FF) as source from src/intro98/intro.ann: kit/mkgame.py with this part's own config.

    python3 tools/intro98_mkgame.py [--install] [--venv VENV] [--sjasmplus BIN] [--out DIR]

The intro block is the '98 file's sectors 2-43 as the REM loader reads them to $C000 (work/media/98/intro.bin,
written by tools/zs_media.py from orig/). kit/mkgame.py takes its config from a case.json; this part does not use
the case's: the config is CONFIG below (the image, $C000-$E9FF, the page at $C000, the recordings). The code is
what the intro window of recording r98 ran (frames 2048 to 4500: the intro entered at $D88F at 2048, the game at
$A600 at 4500; work/stage2/intro98/w-intro/l1.json, built by re_session.py build, see work/stage2/STATE-intro98.md)
widened by the kit's walk. Only that window's l1.json is read, never every work/*/l1.json.

kit/mkgame.py writes the modules into --out (work/stage2/intro98/mkgame) and assembles them against the block. With
--install, once the bytes are identical, the modules and the top file (intro98.asm) go to src/intro98 and the
resources through tools/intro98_res.py install to src/res/intro98 (the tune as .pt3, the scroller text as UTF-8,
the logo, the robot and the font as PNG, the leftovers as bytes). Nothing else of src/intro98 is removed.
"""
import argparse
import glob
import importlib.util
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit', 'mkgame.py')
ANN = os.path.join(ROOT, 'src', 'intro98', 'intro.ann')
OUT = os.path.join(ROOT, 'work', 'stage2', 'intro98', 'mkgame')
DEST = os.path.join(ROOT, 'src', 'intro98')
VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
SJASMPLUS = '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'
TOP = 'intro98'

CONFIG = {
    'block': 'work/media/98/intro.bin',       # sectors 2-43 of NEZSEd.B (tools/zs_media.py)
    'org': 0xC000,
    'device': 'ZXSPECTRUM128',
    'bases': {0: 0xC000},                     # the intro runs with page 0 at $C000 ($7FFD = $10)
    # the recordings: l1.json of the intro window (r98 frames 2048-4500); their data reads count too
    'l1': ['work/stage2/intro98/w-intro/l1.json'],
    'header': [
        "; Nether Earth ZS Edition '98 (ZS, 23.12.1998): the intro block, $C000-$E9FF, as the REM loader reads it",
        "; (NEZSEd.B sectors 2-43). PT 3 Player v1.0 by Nick of GDC + \"COOL WINTER\" (KLIM/OHG '97) at $C000-$D88E,",
        "; the intro (entered at $D88F by CALL from the REM loader) and its data at $D88F-$E9FF.",
    ],
}


def load_kit():
    spec = importlib.util.spec_from_file_location('mkgame', KIT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def image():
    """the 64 K image the kit works on: the block at $C000, zero elsewhere"""
    path = os.path.join(ROOT, CONFIG['block'])
    if not os.path.exists(path):
        import subprocess
        subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'zs_media.py')], check=True, cwd=ROOT)
    block = open(path, 'rb').read()
    assert len(block) == 0x2A00, f'{path}: {len(block)} bytes, not 42 sectors'
    mem = bytearray(0x10000)
    mem[CONFIG['org']:CONFIG['org'] + len(block)] = block
    return bytes(mem), len(block)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--install', action='store_true')
    p.add_argument('--venv', default=VENV)
    p.add_argument('--sjasmplus', default=SJASMPLUS)
    p.add_argument('--ann', default=ANN)
    p.add_argument('--out', default=OUT)
    a = p.parse_args()
    kit = load_kit()
    mem, size = image()

    def load_case(case):
        kit.ROOT = ROOT
        kit.LO, kit.HI = CONFIG['org'], CONFIG['org'] + size
        kit.BASES = dict(CONFIG['bases'])
        kit.READ_BUILDS = tuple(os.path.basename(os.path.dirname(q)) for q in CONFIG['l1'])
        return {'device': CONFIG['device'], 'header': CONFIG['header']}
    kit.load_case = load_case
    kit.original_image = lambda config: mem

    load_l1 = kit.load_l1
    kit.load_l1 = lambda paths, m: load_l1([os.path.join(ROOT, q) for q in CONFIG['l1']], m)

    def header(config):
        return '\n'.join(config['header']) + """
; Written by tools/intro98_mkgame.py (kit/mkgame.py) from src/intro98/intro.ann; edit the .ann, not the .asm.

  DEVICE %s
""" % config['device']
    kit.header = header

    shutil.rmtree(a.out, ignore_errors=True)
    sys.argv = [KIT, '--case', ROOT, '--venv', a.venv, '--sjasmplus', a.sjasmplus, '--out', a.out, '--ann', a.ann]
    status = kit.main()
    if status:
        return status
    # the top file under its own name; its SAVEBIN writes intro-c000.bin
    top = open(os.path.join(a.out, 'game.asm')).read().replace('SAVEBIN "game.bin"', 'SAVEBIN "intro-c000.bin"')
    open(os.path.join(a.out, TOP + '.asm'), 'w').write(top)
    if not a.install:
        return 0
    modules = [m for _, m in kit.Annotations(a.ann).modules]
    os.makedirs(DEST, exist_ok=True)
    for name in modules + [TOP]:
        shutil.copyfile(os.path.join(a.out, name + '.asm'), os.path.join(DEST, name + '.asm'))
    stale = {os.path.basename(f)[:-4] for f in glob.glob(os.path.join(DEST, '*.asm'))} - set(modules) - {TOP}
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import intro98_res  # noqa: E402
    res = os.path.join(a.out, 'res')
    files = {}
    for folder, _, fs in os.walk(res):
        for f in sorted(fs):
            rel = os.path.relpath(os.path.join(folder, f), res).replace(os.sep, '/')
            files[rel] = open(os.path.join(folder, f), 'rb').read()
    intro98_res.install(files)
    print(f'installed {len(modules) + 1} files in src/intro98, {len(files)} resources in src/res/intro98'
          + (f' (stale in src/intro98: {", ".join(sorted(stale))})' if stale else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The '99 game block's and patches block's source from their annotations: kit/mkgame.py with this part's own
configuration (not case.json), its own recordings and, for the patches, one run per piece.

    python3 tools/game99_mkgame.py [game|patches|all] [--install] [--venv VENV] [--sjasmplus BIN]

- game: src/game99/game.ann over tools/game99_image.py's game/original.bin, `$6780-$D7D2`, into
  work/stage2/game99/mkgame/out-game; with --install the modules and game.asm go to src/game99 and the resources
  to src/res/game99 (tools/game99_res.py) and src/res/maps (tools/zs_level.py, the built-in level).
- patches: src/patches99/patches.ann holds the eight pieces of the patches block, each after a line
  `# @piece NAME`; the pieces and their run addresses are tools/game99_image.py PIECES. Each piece is one kit run
  over its set's image (patches-disk / patches-tape) with lo-hi = its run range; its module text is then placed in
  src/patches99/patches.asm inside `DISP run` at its offset of the block, which assembles the block's `$D800`
  layout. The lines before the first piece (@equ) hold for every piece.

The code comes from the windows of the case's recordings listed in L1 below (instruction starts whose bytes are the
image's), less the starts in the ranges stage 3 overwrites in the game block (the patches run there, not the
block's own bytes). The tape and one-page pieces never ran in any recording: their code is the annotation's entries
walked statically.
"""
import argparse
import glob
import importlib.util
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import game99_image  # noqa: E402

KIT = os.path.join(ROOT, '..', '..', 'kit', 'mkgame.py')
WORK = os.path.join(ROOT, 'work', 'stage2', 'game99')
MK = os.path.join(WORK, 'mkgame')
VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
SJASMPLUS = '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'
GAME_ANN = os.path.join(ROOT, 'src', 'game99', 'game.ann')
PATCH_ANN = os.path.join(ROOT, 'src', 'patches99', 'patches.ann')

# The L1 windows (work/stage2/game99/<name>/l1.json) whose instruction starts and data reads count: each from the
# start-up menu's first frame (page 0 then holds the game and the patches at their run addresses) to the end.
L1 = ['r99-play', 'crit-play', 'loadmap-menu']
# The game block's ranges stage 3 overwrites with pieces of the patches block (their code ran there, not the block's)
OVERWRITTEN = [(0xA56A, 0xA5D6), (0xC100, 0xC17F), (0xC1FD, 0xC333)]
GAME_HEADER = ["; Nether Earth ZS Edition '99 (ZS, 1999): the game block as it unpacks, $6780-$D7D2 (page 0 at $C000).",
               "; Stage 3 then copies pieces of the patches block (src/patches99) over $A56A-$A5D5, $C100-$C17E and",
               "; $C1FD-$C332, and the start-up menu and LOAD MAP patch operands (game.ann says where). Entry Start $A600."]


def load_kit():
    spec = importlib.util.spec_from_file_location('mkgame', KIT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_kit(ann, image, lo, hi, out, header, skip=(), l1=True, venv=VENV, sjasmplus=SJASMPLUS):
    """one kit/mkgame.py run with this configuration; returns (status, kit module)"""
    kit = load_kit()
    config = {'image': image, 'lo': '%04X' % lo, 'hi': '%04X' % hi, 'device': 'ZXSPECTRUM48',
              'bases': {'5': '4000', '2': '8000', '0': 'C000'}, 'read_builds': L1, 'header': header}

    def load_case(case):
        kit.ROOT = ROOT
        kit.LO, kit.HI = lo, hi
        kit.BASES = {5: 0x4000, 2: 0x8000, 0: 0xC000}
        kit.READ_BUILDS = tuple(L1)
        return config
    kit.load_case = load_case
    kit.original_image = lambda cfg: open(image, 'rb').read()
    load_l1 = kit.load_l1

    def own_l1(paths, mem):
        mine = [os.path.join(WORK, n, 'l1.json') for n in L1] if l1 else []
        starts, entries, reads = load_l1([q for q in mine if os.path.exists(q)], mem)
        drop = {a for a in starts if any(s <= a < e for s, e in skip)}
        for s, e in skip:  # the walk stops there: the block's bytes are no code (the CALL $C100 of Start)
            for b in range(s, e):
                reads[b] = max(reads[b], 1)
        return starts - drop, {a for a in entries if not any(s <= a < e for s, e in skip)}, reads
    kit.load_l1 = own_l1
    shutil.rmtree(out, ignore_errors=True)
    sys.argv = [KIT, '--case', ROOT, '--venv', venv, '--sjasmplus', sjasmplus, '--out', out, '--ann', ann]
    return kit.main(), kit


def resources(out):
    res = os.path.join(out, 'res')
    files = {}
    for folder, _, fs in os.walk(res):
        for f in sorted(fs):
            rel = os.path.relpath(os.path.join(folder, f), res).replace(os.sep, '/')
            files[rel] = open(os.path.join(folder, f), 'rb').read()
    return files


def do_game(a):
    out = os.path.join(MK, 'out-game')
    status, kit = run_kit(a.ann or GAME_ANN, os.path.join(MK, 'game', 'original.bin'), game99_image.GAME_LO,
                          game99_image.GAME_HI, out, GAME_HEADER, OVERWRITTEN, venv=a.venv, sjasmplus=a.sjasmplus)
    if status or not a.install:
        return status
    dest = os.path.join(ROOT, 'src', 'game99')
    modules = [m for _, m in kit.Annotations(a.ann or GAME_ANN).modules]
    for old in glob.glob(os.path.join(dest, '*.asm')):
        os.remove(old)
    for name in modules + ['game']:
        shutil.copyfile(os.path.join(out, name + '.asm'), os.path.join(dest, name + '.asm'))
    import game99_res  # noqa: E402
    import zs_level  # noqa: E402
    files = resources(out)
    game99_res.install({k: v for k, v in files.items() if not k.startswith('maps/')})
    for k, v in files.items():
        if k.startswith('maps/'):
            zs_level.install(k, v)
    print(f'installed {len(modules) + 1} files in src/game99, {len(files)} resources')
    return 0


# ------------------------------------------------------------------------------------------------- the patches

PIECE = re.compile(r'^#\s*@piece\s+(\w+)\s*$')


def split_pieces(path):
    """(common lines, {piece: lines}) of patches.ann"""
    common, pieces, cur = [], {}, None
    for line in open(path, encoding='utf-8'):
        m = PIECE.match(line.strip())
        if m:
            cur = m.group(1)
            pieces[cur] = []
            continue
        (pieces[cur] if cur else common).append(line)
    return common, pieces


def do_patches(a):
    path = a.ann or PATCH_ANN
    common, pieces = split_pieces(path)
    defs = {p[0]: p for p in game99_image.PIECES}
    if set(pieces) != set(defs):
        sys.exit(f'{path}: the pieces must be {sorted(defs)}, found {sorted(pieces)}')
    bodies, equs, labels = {}, {}, set()
    for name, group, off, n, run in game99_image.PIECES:
        out = os.path.join(MK, 'out-' + name)
        os.makedirs(out, exist_ok=True)
        ann = os.path.join(out + '.ann')
        keep = []
        for line in common:  # an @equ inside this piece's own range is a label here, not an EQU
            m = re.match(r'^@equ\s+\$([0-9A-Fa-f]{4})\b', line.strip())
            if m and run <= int(m.group(1), 16) < run + n:
                continue
            keep.append(line)
        open(ann, 'w', encoding='utf-8').write(''.join(keep + pieces[name]))
        header = [f'; patches block piece {name}: $%04X-$%04X of the block, run at $%04X-$%04X' %
                  (0xD800 + off, 0xD800 + off + n - 1, run, run + n - 1)]
        status, kit = run_kit(ann, os.path.join(MK, 'patches-' + group, 'original.bin'), run, run + n, out, header,
                              l1=(group == 'disk'), venv=a.venv, sjasmplus=a.sjasmplus)
        if status:
            print(f'piece {name}: not identical')
            return status
        mods = [m for _, m in kit.Annotations(ann).modules]
        if len(mods) != 1:
            sys.exit(f'piece {name}: one @module a piece, found {mods}')
        bodies[name] = (mods[0], open(os.path.join(out, mods[0] + '.asm')).read())
        for line in open(os.path.join(out, 'game.asm')):
            m = re.match(r'^(\w+)\s+EQU\s+\$([0-9A-F]{4})(.*)$', line)
            if m:
                equs[m.group(1)] = line.rstrip()
        labels |= set(re.findall(r'^([A-Za-z_]\w*):$', bodies[name][1], re.M))
    lines = ["; Nether Earth ZS Edition '99: the patches block as it unpacks, $D800-$DB6F (880 bytes).",
             "; Written by tools/game99_mkgame.py from src/patches99/patches.ann and the recordings; edit the .ann.",
             "; Eight pieces that stage 3 copies to their run addresses (two sets: TR-DOS + 128 K, tape / one page);",
             "; each is assembled with DISP at the address it runs at, laid at its offset of the block.", '',
             '  DEVICE ZXSPECTRUM48', '']
    lines += ['; The addresses the pieces use outside themselves (game99 labels, ROM entries, menu99 labels)']
    lines += [v for k, v in sorted(equs.items(), key=lambda kv: kv[1].split('$')[1]) if k not in labels]
    lines += ['', '  ORG $D800']
    for name, group, off, n, run in game99_image.PIECES:
        mod = bodies[name][0]
        open(os.path.join(MK, 'out-' + name, mod + '.asm'), 'w').write(bodies[name][1])
        lines += ['', f'; ${0xD800 + off:04X}: {name} ({group} set), {n} bytes, run at ${run:04X}',
                  f'  DISP ${run:04X}', f'  INCLUDE "{mod}.asm"', '  ENT']
    lines += ['', '  SAVEBIN "patches.bin",$D800,$%04X' % (0xDB70 - 0xD800), '']
    top = os.path.join(MK, 'out-patches')
    shutil.rmtree(top, ignore_errors=True)
    os.makedirs(top)
    open(os.path.join(top, 'patches.asm'), 'w').write('\n'.join(lines))
    for name, _, _, _, _ in game99_image.PIECES:
        mod = bodies[name][0]
        shutil.copyfile(os.path.join(MK, 'out-' + name, mod + '.asm'), os.path.join(top, mod + '.asm'))
    import subprocess
    r = subprocess.run([a.sjasmplus, '--nologo', '--msg=war', 'patches.asm'], cwd=top, capture_output=True, text=True)
    if r.returncode or r.stdout.strip() or r.stderr.strip():
        print(r.stdout, r.stderr)
        if r.returncode:
            return 1
    built = open(os.path.join(top, 'patches.bin'), 'rb').read()
    want = open(os.path.join(MK, 'patches-out.bin'), 'rb').read()
    same = built == want
    print('patches: ' + ('identical to the patches block\'s output' if same else 'DIFFERENT'))
    if not same or not a.install:
        return 0 if same else 1
    dest = os.path.join(ROOT, 'src', 'patches99')
    for old in glob.glob(os.path.join(dest, '*.asm')):
        os.remove(old)
    for f in glob.glob(os.path.join(top, '*.asm')):
        shutil.copyfile(f, os.path.join(dest, os.path.basename(f)))
    print(f'installed {len(bodies) + 1} files in src/patches99')
    return 0


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('part', nargs='?', default='all', choices=['game', 'patches', 'all'])
    p.add_argument('--install', action='store_true')
    p.add_argument('--venv', default=VENV)
    p.add_argument('--sjasmplus', default=SJASMPLUS)
    p.add_argument('--ann')
    a = p.parse_args()
    saved, sys.argv = sys.argv, ['game99_image.py', '--out', MK]
    game99_image.main()
    sys.argv = saved
    status = 0
    if a.part in ('game', 'all'):
        status |= do_game(a) or 0
    if a.part in ('patches', 'all'):
        status |= do_patches(a) or 0
    return status


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The game image's source from src/game/game.ann: kit/mkgame.py with the three things this image needs on top.

    python3 tools/game_mkgame.py [--install] [--venv VENV] [--sjasmplus BIN]

kit/mkgame.py writes the modules into work/mkgame/main and assembles them against the original image
(tools/game_image.py). With --install, once the bytes are identical, the modules and game.asm go to src/game and
the resources (game/...) to src/res/game through tools/game_res.py. Unlike mkgame's own --install it removes no
other file of src/game.

What it adds to kit/mkgame.py, for the banks the game pages over $C000-$FFFF:

- `# @bank $ADDR NAME BANK ; comment` lines of game.ann: an address in another bank (the player's entries in bank 1,
  the disk module in bank 4, Dead End and the picture code in bank 3, the Final Cut block). They become EQU lines of
  game.asm; the instructions that use them name them through @isub. An @equ cannot do it: some of them lie inside
  the image's range ($C000 is also the level data of bank 0), and one address stands for different things.
- The jumps and calls to such an address are not followed by the code walk (it would read bank 0's bytes there as
  code), and the disassembler's entry-point mark on bank 0's byte there is dropped (no label inside the level data).
- Only the case's own recordings (case.json read_builds) are read, not every work/*/l1.json.
"""
import argparse
import glob
import importlib.util
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit', 'mkgame.py')
OUT = os.path.join(ROOT, 'work', 'mkgame', 'main')
ANN = os.path.join(ROOT, 'src', 'game', 'game.ann')
VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
SJASMPLUS = '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'
BANK = re.compile(r'^#\s*@bank\s+\$([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)\s+(\d)\s*(?:;\s*(.*))?$')


def bank_names(path):
    """[(address, name, bank, comment)] from the `# @bank` lines of game.ann"""
    out = []
    for line in open(path, encoding='utf-8'):
        m = BANK.match(line.strip())
        if m:
            out.append((int(m.group(1), 16), m.group(2), int(m.group(3)), m.group(4) or ''))
    return out


def cross_bank_instructions(path, names):
    """the addresses of the @isub instructions that name a bank address"""
    words = {n for _, n, _, _ in names}
    out = set()
    for line in open(path, encoding='utf-8'):
        parts = line.split(None, 2)
        if len(parts) == 3 and parts[0] == '@isub' and set(re.findall(r'[A-Za-z_]\w*', parts[2])) & words:
            out.add(int(parts[1][1:], 16))
    return out


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
    p.add_argument('--out', default=OUT)
    a = p.parse_args()
    names = bank_names(a.ann)
    skip = cross_bank_instructions(a.ann, names)
    targets = {addr for addr, _, _, _ in names}
    kit = load_kit()

    decode = kit.decode

    def bank_decode(mem, at):
        n, tg, falls, call = decode(mem, at)
        if at in skip:
            tg = [t for t in tg if t not in targets]
        return n, tg, falls, call
    kit.decode = bank_decode

    load_l1 = kit.load_l1

    def own_l1(paths, mem):
        keep = {os.path.join(kit.ROOT, 'work', b, 'l1.json') for b in kit.READ_BUILDS}
        return load_l1([q for q in paths if q in keep], mem)
    kit.load_l1 = own_l1

    run = kit.run

    def bank_run(cmd, **kw):
        res = run(cmd, **kw)
        if os.path.basename(cmd[1]) == 'sna2skool.py':
            marks = '|'.join('%04X' % t for t in targets)
            res.stdout = re.sub(r'^\*\$(%s) ' % marks, r' $\1 ', res.stdout, flags=re.M)
        return res
    kit.run = bank_run

    equates = kit.equates

    def bank_equates(equ):
        text = equates(equ)
        lines = ['', '; Addresses in the other banks the game pages at $C000 (game.ann # @bank)']
        for addr, name, bank, comment in sorted(names, key=lambda x: (x[2], x[0])):
            lines.append('%-14s EQU $%04X  ; bank %d%s' % (name, addr, bank, (': ' + comment) if comment else ''))
        return text + '\n'.join(lines) + '\n'
    kit.equates = bank_equates

    shutil.rmtree(a.out, ignore_errors=True)   # no resource or module of an earlier run left behind
    sys.argv = [KIT, '--case', ROOT, '--venv', a.venv, '--sjasmplus', a.sjasmplus, '--out', a.out, '--ann', a.ann]
    status = kit.main()
    if status or not a.install:
        return status
    dest = os.path.join(ROOT, 'src', 'game')
    modules = [m for _, m in kit.Annotations(a.ann).modules]
    for name in modules + ['game']:
        shutil.copyfile(os.path.join(a.out, name + '.asm'), os.path.join(dest, name + '.asm'))
    stale = {os.path.basename(f)[:-4] for f in glob.glob(os.path.join(a.out, '*.asm'))} - set(modules) - {'game'}
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import game_res  # noqa: E402
    res = os.path.join(a.out, 'res')
    files = {}
    for folder, _, fs in os.walk(res):
        for f in sorted(fs):
            rel = os.path.relpath(os.path.join(folder, f), res).replace(os.sep, '/')
            files[rel] = open(os.path.join(folder, f), 'rb').read()
    game_res.install(dict(sorted(files.items(), key=lambda kv: order_of(kv[0], a.ann))))
    print(f'installed {len(modules) + 1} files in src/game, {len(files)} resources in src/res/game'
          + (f' (stale in {a.out}: {", ".join(sorted(stale))})' if stale else ''))
    return 0


def order_of(name, ann):
    """a resource's place: the address of the first entry that names it in game.ann"""
    at, last = None, None
    for line in open(ann, encoding='utf-8'):
        m = re.match(r'^\$([0-9A-F]{4}) [bwts]\b', line)
        if m:
            last = int(m.group(1), 16)
        elif line.startswith('@res ') and line.split()[1] == name and at is None:
            at = last
    return at if at is not None else 0x10000


if __name__ == '__main__':
    sys.exit(main())

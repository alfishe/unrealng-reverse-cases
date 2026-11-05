#!/usr/bin/env python3
"""The game's source from src/game/game.ann: kit/mkgame.py with what this image needs on top.

    python3 tools/game_mkgame.py [--install] [--venv VENV] [--sjasmplus BIN]

kit/mkgame.py writes the modules into work/mkgame/main and assembles them against the original image
(tools/game_image.py: neart001 at $6590-$FFFF). With --install, once the bytes are identical, the modules and
game.asm go to src/game and the resources to src/res through tools/res_formats.py (mkgame's own --install).

The bank logic is adapted from ../advanced-nether-earth/tools/game_mkgame.py (copied, not imported: the cases stay
apart). What it adds to kit/mkgame.py:

- `# @bank $ADDR NAME PAGE ; comment`: an address in the RAM page the game pages at $C000 (the GS driver). It becomes
  an EQU line; the calls to it are not followed by the code walk (it would read bank 0's level data there as code),
  and the disassembler's entry mark on bank 0's byte there is dropped.
- `# @var $ADDR NAME [N] ; comment`: a variable of the work space $FCE9-$FFFF. In Nether Earth these lie past the
  game block (an @equ); here the file holds them (its last 791 bytes, leftovers of a memory dump), so each is a label
  inside the work space's data entries, and every instruction operand $ADDR+1..$ADDR+N-1 is written NAME+k.
- `# @alias NAME EXPR ; comment`: an EQU for a name that cannot be a label (Handler, the operand of the JP at
  $FDFD): NAME EQU EXPR; the instructions name it through @isub.
- Only the recordings case.json read_builds names are read (work/<build>/l1.json, folders below work/).
"""
import argparse
import importlib.util
import json
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
BANK = re.compile(r'^#\s*@bank\s+\$([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)\s+(\w+)\s*(?:;\s*(.*))?$')
VAR = re.compile(r'^#\s*@var\s+\$([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)(?:\s+(\d+))?\s*(?:;\s*(.*))?$')
ALIAS = re.compile(r'^#\s*@alias\s+([A-Za-z_]\w*)\s+(\S+)\s*(?:;\s*(.*))?$')


def read_directives(path):
    banks, variables, aliases = [], [], []
    for line in open(path, encoding='utf-8'):
        t = line.strip()
        m = BANK.match(t)
        if m:
            banks.append((int(m.group(1), 16), m.group(2), m.group(3), m.group(4) or ''))
        m = VAR.match(t)
        if m:
            variables.append((int(m.group(1), 16), m.group(2), int(m.group(3) or 1), m.group(4) or ''))
        m = ALIAS.match(t)
        if m:
            aliases.append((m.group(1), m.group(2), m.group(3) or ''))
    return banks, variables, aliases


def cross_bank_instructions(path, names):
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
    banks, variables, aliases = read_directives(a.ann)
    skip = cross_bank_instructions(a.ann, banks)
    targets = {addr for addr, _, _, _ in banks}
    builds = json.load(open(os.path.join(ROOT, 'case.json'))).get('read_builds', [])

    # The annotations kit/mkgame.py reads: game.ann plus the variables as labels inside their data entries
    os.makedirs(a.out, exist_ok=True)
    shutil.rmtree(a.out, ignore_errors=True)   # no resource or module of an earlier run left behind
    os.makedirs(a.out)
    ann = os.path.join(a.out, 'game.ann')
    with open(ann, 'w', encoding='utf-8') as f:
        f.write(open(a.ann, encoding='utf-8').read().rstrip('\n') + '\n\n# tools/game_mkgame.py: the @var labels\n')
        for addr, name, _, comment in variables:
            f.write('$%04X %s%s\n' % (addr, name, (' ; ' + comment) if comment else ''))

    kit = load_kit()
    decode = kit.decode

    def bank_decode(mem, at):
        n, tg, falls, call = decode(mem, at)
        if at in skip:
            tg = [t for t in tg if t not in targets]
        return n, tg, falls, call
    kit.decode = bank_decode

    load_l1 = kit.load_l1

    def own_l1(_paths, mem):
        paths = [os.path.join(kit.ROOT, 'work', b, 'l1.json') for b in builds]
        missing = [q for q in paths if not os.path.exists(q)]
        if missing:
            sys.exit('game_mkgame: no recording ' + ', '.join(missing) + ' (WALKTHROUGH 6 makes it)')
        kit.READ_BUILDS = tuple(os.path.basename(b) for b in builds)
        return load_l1(paths, mem)
    kit.load_l1 = own_l1

    run = kit.run

    def bank_run(cmd, **kw):
        res = run(cmd, **kw)
        if os.path.basename(cmd[1]) == 'sna2skool.py' and targets:
            marks = '|'.join('%04X' % t for t in targets)
            res.stdout = re.sub(r'^\*\$(%s) ' % marks, r' $\1 ', res.stdout, flags=re.M)
        return res
    kit.run = bank_run

    names = {}
    for addr, name, size, _ in variables:
        for k in range(1, size):
            names[addr + k] = '%s+%d' % (name, k)
    name_variables = kit.name_variables

    def own_names(text, equ):
        text = name_variables(text, equ)
        out = []
        for line in text.splitlines(True):
            code, semi, comment = line.partition(';')
            if re.match(r'^  [A-Z]', code) and not re.match(r'^  DEF[BWMS]', code):
                code = re.sub(r'\$([0-9A-F]{4})\b', lambda m: names.get(int(m.group(1), 16), m.group(0)), code)
            out.append(code + semi + comment)
        return ''.join(out)
    kit.name_variables = own_names

    equates = kit.equates

    def own_equates(equ):
        text = equates(equ)
        lines = []
        if banks:
            lines += ['', '; Addresses in the RAM page the game pages at $C000 (game.ann # @bank)']
            for addr, name, page, comment in banks:
                lines.append('%-14s EQU $%04X  ; page %s%s' % (name, addr, page, (': ' + comment) if comment else ''))
        if aliases:
            lines += ['', '; Names that cannot be labels (game.ann # @alias)']
            for name, expr, comment in aliases:
                lines.append('%-14s EQU %s%s' % (name, expr, ('  ; ' + comment) if comment else ''))
        return text + '\n'.join(lines) + '\n'
    kit.equates = own_equates

    sys.argv = [KIT, '--case', ROOT, '--venv', a.venv, '--sjasmplus', a.sjasmplus, '--out', a.out, '--ann', ann] + \
        (['--install'] if a.install else [])
    return kit.main()


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""Write src/bootmenu/*.asm (the boot program $6060-$F6D4: the boot menu and the help) from src/bootmenu/bootmenu.ann.

    python3 tools/bootmenu_mkasm.py --venv VENV [--sjasmplus BIN] [--out DIR] [--install]

kit/mkgame.py's pipeline (its functions, imported) on this part instead of a case's game image: the image is
src/res/img/d05-6060.bin at $6060 (the bytes the boot program's HRUM block unpacks to), the code is what the traces
of tools/bootmenu_sim.py ran (work/stage3/bootmenu/*/trace.json: the instruction starts, the CALL targets, the data
reads), widened by mkgame's static walk; entries, names, comments and descriptions come from the annotation file
(the format is mkgame.Annotations, plus @const NAME VALUE ; comment: an EQU in the top file). The resources (@res) go through tools/bootmenu_res.py: PNG for the pictures and
the font, UTF-8 text for the help pages. --install writes src/bootmenu/*.asm and src/res/bootmenu/ only when
sjasmplus gives the image's bytes.

mkgame itself cannot do this part: it takes one 64 K image named by case.json, the recordings' l1.json and installs
into src/game (a kit gap noted for the lead); this wrapper supplies the image, the code and the destinations.
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import mkgame as mg  # noqa: E402

IMAGE = os.path.join(CASE, 'src', 'res', 'img', 'd05-6060.bin')
LO = 0x6060
TOP = 'bootmenu'


def load_traces(mem, paths):
    starts, entries, reads = set(), set(), [0] * 0x10000
    for path in paths:
        t = json.load(open(path))
        for a, n in t['starts'].items():
            a = int(a, 16)
            if mg.decode(mem, a)[0] == n:
                starts.add(a)
        entries |= {int(a, 16) for a in t['entries']}
        for a, n in t['reads'].items():
            reads[int(a, 16)] += n
    return starts, entries, reads


CONST = re.compile(r'^@const\s+([A-Za-z_]\w*)\s+(\$[0-9A-Fa-f]+|\d+)\s*(?:;\s*(.*))?$')


def read_ann(path, out):
    """mkgame.Annotations of the file, and its @const lines: NAME VALUE ; comment, an EQU in the top file for an
    operand the image's own addresses must not name (a routine in another bank at $C000, the game's entry); @isub
    lines write the instructions with them. mkgame does not know @const: the lines are taken out first"""
    consts, keep = [], []
    for number, line in enumerate(open(path) if os.path.exists(path) else [], 1):
        m = CONST.match(line.strip())
        if line.strip().startswith('@const'):
            if not m:
                sys.exit(f'{path}:{number}: cannot read: {line.rstrip()}')
            consts.append((m.group(1), m.group(2), m.group(3) or ''))
            keep.append('#\n')
        else:
            keep.append(line)
    tmp = os.path.join(out, 'bootmenu.ann')
    open(tmp, 'w').write(''.join(keep))
    return mg.Annotations(tmp), consts


def decimal_isubs(text, isubs):
    """skool2asm -H writes every number of an @isub instruction in hex (LD DE,1*256+30 as
    LD DE,$0001*$0100+$001E): the instructions as the .ann writes them again"""
    for isub in set(isubs):
        parts = re.split(r'(?<![$\w])(\d+)(?!\w)', isub)
        if len(parts) == 1:
            continue
        pattern = ''.join(r'\$0*%X(?![0-9A-F])' % int(p) if k % 2 else re.escape(p) for k, p in enumerate(parts))
        text = re.sub(r'^  %s(?:\s+(;.*))?$' % pattern, lambda m: ('%-26s%s' % ('  ' + isub, m.group(m.lastindex))).rstrip()
                      if m.lastindex and m.group(m.lastindex) else '  ' + isub, text, flags=re.M)
    return text


def constants(consts):
    if not consts:
        return ''
    lines = ['', '; Constants: addresses outside this image or in another bank (bootmenu.ann @const)']
    for name, value, comment in consts:
        lines.append('%-18s EQU %s%s' % (name, value, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--venv', default='/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    p.add_argument('--sjasmplus', default=os.environ.get(
        'SJASMPLUS', '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'))
    p.add_argument('--out', default=os.path.join(CASE, 'work', 'stage3', 'bootmenu', 'mkasm'))
    p.add_argument('--ann', default=os.path.join(CASE, 'src', 'bootmenu', 'bootmenu.ann'))
    p.add_argument('--traces', default=os.path.join(CASE, 'work', 'stage3', 'bootmenu', '*', 'trace.json'))
    p.add_argument('--install', action='store_true')
    args = p.parse_args()
    image = open(IMAGE, 'rb').read()
    mg.LO, mg.HI = LO, LO + len(image)
    mem = bytes(LO) + image + bytes(0x10000 - LO - len(image))
    os.makedirs(args.out, exist_ok=True)
    starts, entries, reads = load_traces(mem, sorted(glob.glob(args.traces)))
    ann, consts = read_ann(args.ann, args.out)
    # a data entry of the annotations stops the static walk (a CALL into another bank's $C000, a jump table's
    # neighbour): the walk breaks at bytes read as data
    for a, e in ann.entries.items():
        if e[0] != 'c' and a not in starts:
            reads[a] += 1
    if TOP in ann.module_info:
        sys.exit('bootmenu.ann: @module %s is taken by the top file' % TOP)
    code, targets, calls = mg.walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'],
                                   ann.inline_data)
    # a CALL the traces saw into code that is no longer this image's (the game starter at $9C40, run after the
    # copy over the pictures) is no entry point of it
    entries = {a for a in entries if a in code}
    ctl = os.path.join(args.out, 'bootmenu.ctl')
    extents = mg.write_ctl(mem, code, targets, calls, entries, ann, ctl)
    binpath = os.path.join(args.out, 'image.bin')
    open(binpath, 'wb').write(mem[LO:])
    py = os.path.join(args.venv, 'bin', 'python')
    out = mg.run([py, os.path.join(args.venv, 'bin', 'sna2skool.py'), '-H', '-c', ctl, '-o', str(LO), binpath]).stdout
    # sna2skool marks every operand's address as a reference (*); inside data that is only an operand the source
    # writes with a constant (CALL STARTER: $9C40 inside ProgrammingPicture), no label for skool2asm to make
    out = re.sub(r'^\*(\$[0-9A-F]{4} DEF)', r' \1', out, flags=re.M)
    written = dict(ann.isub)
    out, inner = mg.label_inner_addresses(out, written)
    if written:
        sys.exit('bootmenu.ann: @isub on no instruction: ' + ', '.join('$%04X' % a for a in sorted(written)))
    open(os.path.join(args.out, 'bootmenu.skool'), 'w').write(out)
    text = mg.run([py, os.path.join(args.venv, 'bin', 'skool2asm.py'), '-H',
                   os.path.join(args.out, 'bootmenu.skool')]).stdout
    for half in ('IXl', 'IXh', 'IYl', 'IYh'):
        text = text.replace(half, half.upper())
    text = mg.name_variables(text, ann.equ)
    text = decimal_isubs(text, ann.isub.values())
    text = re.sub(r'^(  DEF[BWMS] .*?)\s+;$', r'\1', text, flags=re.M)
    text, resources = mg.write_resources(text, mem, extents, ann, args.out)
    modules, head = mg.split_modules(text, ann)
    for name, body in modules:
        open(os.path.join(args.out, name + '.asm'), 'w').write(body)
    top = ('; Advanced Nether Earth (Eternity Industry 1998): the boot program $6060-$F6D4, the boot menu and the help,\n'
           '; as its HRUM block unpacks it (src/sfx/blocks.asm, Block05; entry $61A8).\n'
           '; Written by tools/bootmenu_mkasm.py from src/bootmenu/bootmenu.ann and the traces; edit the .ann, not the .asm.\n'
           '\n  DEVICE ZXSPECTRUM128\n')
    top += constants(consts) + mg.equates(ann.equ) + head
    top += ''.join('  INCLUDE "%s.asm"%s\n' % (name, ('  ; ' + ann.module_info[name][0])
                                               if ann.module_info.get(name, [''])[0] else '') for name, _ in modules)
    top += '\n  SAVEBIN "d05-6060.bin",$%04X,$%04X\n' % (LO, len(image))
    open(os.path.join(args.out, TOP + '.asm'), 'w').write(top)
    mg.run([args.sjasmplus, '--nologo', '--msg=war', TOP + '.asm'], cwd=args.out)
    built = open(os.path.join(args.out, 'd05-6060.bin'), 'rb').read()
    diff = next((LO + i for i in range(len(image)) if built[i] != image[i]), None)
    print(f'resources {len(resources)} files, {sum(hi - lo for lo, hi in resources.values())} bytes')
    print(f'code bytes {sum(code.values())} ({len(code)} instructions, {len(starts)} ran), '
          f'entries {sum(1 for l in open(ctl) if l[:2] in ("c ", "b "))}, modules {len(modules)}, '
          f'addresses inside entries as Label+offset {inner}')
    print('assembled: identical to d05-6060.bin' if diff is None else
          'assembled: first difference at $%04X: %02X, image %02X' % (diff, built[diff - LO], image[diff - LO]))
    if diff is None and args.install:
        dest = os.path.join(CASE, 'src', 'bootmenu')
        for old in glob.glob(os.path.join(dest, '*.asm')):
            os.remove(old)
        for name in [n for n, _ in modules] + [TOP]:
            open(os.path.join(dest, name + '.asm'), 'w').write(open(os.path.join(args.out, name + '.asm')).read())
        import bootmenu_res
        bootmenu_res.install({name: open(os.path.join(args.out, 'res', name), 'rb').read() for name in resources})
        print(f'installed {len(modules) + 1} files in src/bootmenu, {len(resources)} resources in src/res/bootmenu')
    return 0 if diff is None else 1


if __name__ == '__main__':
    sys.exit(main())

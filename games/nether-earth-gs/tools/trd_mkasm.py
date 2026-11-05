#!/usr/bin/env python3
"""Write the annotated source of one code image of the TRD extras (src/trd/...) from its .ann file.

    python3 tools/trd_mkasm.py --image BIN --org ADDR --ann FILE.ann --top NAME --dest DIR --res DIR
                               [--l1 L1.json ...] [--title TEXT] [--venv VENV] [--sjasmplus BIN] [--install]

kit/mkgame.py's pipeline (its functions, imported) on an image that is not the case's game: adapted from
../advanced-nether-earth/tools/bootmenu_mkasm.py (copied, not imported: the cases stay apart). The image is BIN at
ADDR; the code is the instructions an analysis recording ran there (--l1, the unreal-ng L1 json of
work/stage2/trd/rA: only instructions whose bytes equal the image's, in RAM pages 5 and 2, count), widened by
mkgame's static walk from the .ann's code entries. Entries, names, comments and descriptions come from the .ann (the
format is mkgame.Annotations, plus `@const NAME VALUE ; comment`: an EQU in the top file). The recording's data reads
are not used: the HRUM depacker read its packed stream where the menu later lies, so they say nothing; the .ann's
data entries stop the walk instead.

The modules and TOP.asm are written to the work folder (work/stage2/trd/mkasm/TOP) and assembled there; TOP.asm
SAVEBINs TOP.bin. --install copies the .asm files to DEST and the resources (@res) to RES only when sjasmplus gives
the image's bytes back; the INCBIN lines then name the resource folder relative to DEST. A resource the build makes
(--built NAME=PATH: a text converted from its UTF-8 copy) is not installed: its INCBIN names PATH as given (found
through sjasmplus -I). --save sets the installed top file's SAVEBIN path.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import mkgame as mg  # noqa: E402

CONST = re.compile(r'^@const\s+([A-Za-z_]\w*)\s+(\$[0-9A-Fa-f]+|\d+)\s*(?:;\s*(.*))?$')
PAGES = {5: 0x4000, 2: 0x8000}


def load_l1(mem, paths, lo, hi):
    """instruction starts of the recordings' basic blocks whose every instruction has the image's bytes: other
    programs ran at these addresses later in the same recording, and a lone instruction of theirs can equal a byte
    of this image (a $67 LD H,A inside an LD (nn),A here); a whole block of them cannot"""
    starts = set()
    for path in paths:
        doc = json.load(open(path))
        ran = {}
        for z80, page, code, *_ in doc['instructions']:
            if page in PAGES:
                ran[(page, int(z80[1:], 16))] = bytes.fromhex(code)
        for b in doc['blocks']:
            first, last = int(b['start'][1:], 16), int(b['end'][1:], 16)
            if b['page'] not in PAGES or first < lo or last >= hi:
                continue
            a, block = first, []
            while a <= last:
                raw = ran.get((b['page'], a))
                if raw is None or mem[a:a + len(raw)] != raw or mg.decode(mem, a)[0] != len(raw):
                    break
                block.append(a)
                a += len(raw)
            if a == last + 1:
                starts.update(block)
    return starts


def read_ann(path, out, top):
    consts, keep = [], []
    for number, line in enumerate(open(path, encoding='utf-8'), 1):
        if line.strip().startswith('@const'):
            m = CONST.match(line.strip())
            if not m:
                sys.exit(f'{path}:{number}: cannot read: {line.rstrip()}')
            consts.append((m.group(1), m.group(2), m.group(3) or ''))
            keep.append('#\n')
        else:
            keep.append(line)
    tmp = os.path.join(out, top + '.ann')
    open(tmp, 'w', encoding='utf-8').write(''.join(keep))
    return mg.Annotations(tmp), consts


def decimal_isubs(text, isubs):
    """skool2asm -H writes every number of an @isub in hex: the instructions as the .ann writes them again"""
    for isub in set(isubs):
        parts = re.split(r'(?<![$\w])(\d+)(?!\w)', isub)
        if len(parts) == 1:
            continue
        pattern = ''.join(r'\$0*%X(?![0-9A-F])' % int(p) if k % 2 else re.escape(p) for k, p in enumerate(parts))
        text = re.sub(r'^  %s(?:\s+(;.*))?$' % pattern,
                      lambda m: ('%-26s%s' % ('  ' + isub, m.group(m.lastindex))).rstrip()
                      if m.lastindex and m.group(m.lastindex) else '  ' + isub, text, flags=re.M)
    return text


def constants(consts):
    if not consts:
        return ''
    lines = ['', '; Constants: addresses outside this image, ROM entries, ports (@const)']
    for name, value, comment in consts:
        lines.append('%-18s EQU %s%s' % (name, value, ('  ; ' + comment) if comment else ''))
    return '\n'.join(lines) + '\n'


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--image', required=True)
    p.add_argument('--org', required=True)
    p.add_argument('--ann', required=True)
    p.add_argument('--top', required=True)
    p.add_argument('--dest', required=True)
    p.add_argument('--res', required=True)
    p.add_argument('--l1', action='append', default=[])
    p.add_argument('--title', default='')
    p.add_argument('--out')
    p.add_argument('--venv', default='/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    p.add_argument('--sjasmplus', default=os.environ.get(
        'SJASMPLUS', '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'))
    p.add_argument('--built', action='append', default=[], metavar='NAME=PATH',
                   help='the resource NAME is made by the build (a text from src/res/text): INCBIN PATH, not installed')
    p.add_argument('--save', help='the SAVEBIN path of the installed top file (from the folder sjasmplus runs in)')
    p.add_argument('--install', action='store_true')
    args = p.parse_args()
    lo = int(args.org.lstrip('$'), 16) if args.org.startswith('$') else int(args.org, 0)
    image = open(args.image, 'rb').read()
    hi = lo + len(image)
    mg.LO, mg.HI = lo, hi
    mem = bytes(lo) + image + bytes(0x10000 - hi)
    out = args.out or os.path.join(CASE, 'work', 'stage2', 'trd', 'mkasm', args.top)
    os.makedirs(out, exist_ok=True)
    starts = load_l1(mem, args.l1, lo, hi)
    ann, consts = read_ann(args.ann, out, args.top)
    reads = [0] * 0x10000
    # a data entry of the .ann is data to the next entry: its bytes stop the walk, and an instruction the recording
    # ran there (a lone NOP equal to a zero of the font) is no code of this image
    bounds = sorted(ann.entries) + [hi]
    for k, a in enumerate(bounds[:-1]):
        if ann.entries[a][0] != 'c':
            for b in range(a, bounds[k + 1]):
                reads[b] += 1
                starts.discard(b)
    seeds = [a for a, e in ann.entries.items() if e[0] == 'c']
    code, targets, calls = mg.walk(mem, starts, reads, seeds, ann.inline_data)
    ctl = os.path.join(out, args.top + '.ctl')
    extents = mg.write_ctl(mem, code, targets, calls, set(), ann, ctl)
    binpath = os.path.join(out, 'image.bin')
    open(binpath, 'wb').write(mem[lo:])
    py = os.path.join(args.venv, 'bin', 'python')
    sk = mg.run([py, os.path.join(args.venv, 'bin', 'sna2skool.py'), '-H', '-c', ctl, '-o', str(lo), binpath]).stdout
    sk = re.sub(r'^\*(\$[0-9A-F]{4} DEF)', r' \1', sk, flags=re.M)
    written = dict(ann.isub)
    sk, inner = mg.label_inner_addresses(sk, written)
    if written:
        sys.exit('%s: @isub on no instruction: %s' % (args.ann, ', '.join('$%04X' % a for a in sorted(written))))
    open(os.path.join(out, args.top + '.skool'), 'w').write(sk)
    text = mg.run([py, os.path.join(args.venv, 'bin', 'skool2asm.py'), '-H',
                   os.path.join(out, args.top + '.skool')]).stdout
    for half in ('IXl', 'IXh', 'IYl', 'IYh'):
        text = text.replace(half, half.upper())
    text = mg.name_variables(text, ann.equ)
    text = decimal_isubs(text, ann.isub.values())
    text = re.sub(r'^(  DEF[BWMS] .*?)\s+;$', r'\1', text, flags=re.M)
    text, resources = mg.write_resources(text, mem, extents, ann, out)
    modules, head = mg.split_modules(text, ann)
    for name, body in modules:
        open(os.path.join(out, name + '.asm'), 'w').write(body)
    top = ('; %s\n; Written by tools/trd_mkasm.py from %s; edit the .ann, not the .asm.\n\n  DEVICE ZXSPECTRUM128\n'
           % (args.title or args.top, os.path.relpath(args.ann, CASE)))
    top += constants(consts) + mg.equates(ann.equ) + head
    top += ''.join('  INCLUDE "%s.asm"%s\n' % (name, ('  ; ' + ann.module_info[name][0])
                                               if ann.module_info.get(name, [''])[0] else '') for name, _ in modules)
    top += '\n  SAVEBIN "%s.bin",$%04X,$%04X\n' % (args.top, lo, len(image))
    open(os.path.join(out, args.top + '.asm'), 'w').write(top)
    mg.run([args.sjasmplus, '--nologo', '--msg=war', args.top + '.asm'], cwd=out)
    built = open(os.path.join(out, args.top + '.bin'), 'rb').read()
    diff = next((lo + i for i in range(len(image)) if built[i] != image[i]), None)
    print(f'{args.top}: code bytes {sum(code.values())} ({len(code)} instructions, {len(starts)} ran), '
          f'entries {sum(1 for l in open(ctl) if l[:2] in ("c ", "b ", "t ", "w ", "s "))}, modules {len(modules)}, '
          f'resources {len(resources)}, Label+offset {inner}')
    print('assembled: identical' if diff is None else
          'assembled: first difference at $%04X: %02X, image %02X' % (diff, built[diff - lo], image[diff - lo]))
    if diff is None and args.install:
        os.makedirs(args.dest, exist_ok=True)
        prefix = os.path.relpath(args.res, args.dest) + '/'
        built = dict(b.split('=', 1) for b in args.built)
        for name in [n for n, _ in modules] + [args.top]:
            body = open(os.path.join(out, name + '.asm')).read()
            for res, path in built.items():
                body = body.replace('INCBIN "res/%s"' % res, 'INCBIN "%s"' % path)
            body = body.replace('INCBIN "res/', 'INCBIN "' + prefix)
            if args.save:
                body = body.replace('SAVEBIN "%s.bin"' % args.top, 'SAVEBIN "%s"' % args.save)
            open(os.path.join(args.dest, name + '.asm'), 'w').write(body)
        for name in [r for r in resources if r not in built]:
            path = os.path.join(args.res, name)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'wb').write(open(os.path.join(out, 'res', name), 'rb').read())
        print(f'installed {len(modules) + 1} files in {os.path.relpath(args.dest, CASE)}, '
              f'{len(resources)} resources in {os.path.relpath(args.res, CASE)}')
    return 0 if diff is None else 1


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""The '99 stage 3 and the '99 start-up menu from their annotations: kit/mkgame.py with this part's own config.

    python3 tools/menu99_mkgame.py stage3|menu [--install] [--venv VENV] [--sjasmplus BIN]

The two images are the unpacked blocks as tools/zs_media.py writes them (work/media/99/stage3-out.bin at $61A8,
work/media/99/menu-out.bin at $D800 of page 1), each placed in a 64 K image. kit/mkgame.py writes the modules into
work/stage2/menu99/mk-<part> and assembles them against that image. With --install, once the bytes are identical,
the modules go to src/stage3 or src/menu99 with the top file stage3.asm / menu.asm (kit's game.asm renamed, its
SAVEBIN naming the part's own output). Unlike mkgame's own --install it removes no other file of the folder.

What it changes in kit/mkgame.py:

- The config is PARTS below, not C/case.json (the lead's file).
- Only the windows listed for the part are read, each clamped to an address range: the recordings of the '99 overlap
  in memory (stage 2 and the game at $6780 over stage 3; the game's page 0 at $C000 vs the menu's page 1), so a
  window counts only for the bytes that held this part's code while it ran. The windows are the L1 builds of
  work/stage2/menu99/<window>/l1.json (re_session.py build --from-frame --to-frame, see STATE-menu99.md).- `# @over $ADDR ; why` in the .ann (a comment line to kit): a branch target that holds other bytes when the branch
  runs (stage 3 CALLs the game block at $6780, loaded over its own strings): the walk does not follow it.
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
WORK = os.path.join(ROOT, 'work', 'stage2', 'menu99')
VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
SJASMPLUS = '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'

PARTS = {
    'stage3': {
        'block': 'work/media/99/stage3-out.bin', 'lo': 0x61A8, 'bases': {5: 0x4000},
        'ann': 'src/stage3/stage3.ann', 'dest': 'src/stage3', 'top': 'stage3', 'bin': 'stage3-61a8.bin',
        # (window, lo, hi, reads count): the game block overwrites $6780- from frame 2299 on (and runs there)
        'windows': [('r99-s3a', 0x61A8, 0x6780, True), ('r99-s3b', 0x61A8, 0x6780, True),
                    ('r48-s3', 0x61A8, 0x6780, True), ('s99-s3', 0x61A8, 0x6780, True)],
        'header': ["; Nether Earth ZS Edition '99, stage 3: \"System checking\", the memory test, the loads ($61A8-$67EB).",
                   "; Unpacked by the block of sectors 45-50 (read to $8000); entered at Stage3Entry $61A8."],
    },
    'menu': {
        'block': 'work/media/99/menu-out.bin', 'lo': 0xD800, 'bases': {0: 0xC000},
        'ann': 'src/menu99/menu.ann', 'dest': 'src/menu99', 'top': 'menu', 'bin': 'menu-d800.bin',
        'windows': [('r99-menu', 0xD800, 0xE6F4, False), ('s99-menu', 0xD800, 0xE6F4, False), ('m99-menu1', 0xD800, 0xE6F4, False), ('m99-menu2', 0xD800, 0xE6F4, False),
                    ('m99-menu3', 0xD800, 0xE6F4, False), ('m99-menu4', 0xD800, 0xE6F4, False)],
        'header': ["; Nether Earth ZS Edition '99, the 128 K start-up menu in page 1 ($D800-$E6F3).",
                   "; Unpacked by the block of sectors 123-132 (read to $E800 of page 1); entered at MenuEntry $D800."],
    },
}


def load_kit():
    spec = importlib.util.spec_from_file_location('mkgame', KIT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def write_image(part, path):
    data = open(os.path.join(ROOT, part['block']), 'rb').read()
    mem = bytearray(0x10000)
    mem[part['lo']:part['lo'] + len(data)] = data
    open(path, 'wb').write(mem)
    return part['lo'] + len(data)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('part', choices=sorted(PARTS))
    p.add_argument('--install', action='store_true')
    p.add_argument('--venv', default=VENV)
    p.add_argument('--sjasmplus', default=SJASMPLUS)
    a = p.parse_args()
    part = PARTS[a.part]
    out = os.path.join(WORK, 'mk-' + a.part)
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    image = os.path.join(out, 'original.bin')
    hi = write_image(part, image)
    kit = load_kit()

    def own_case(case):
        kit.ROOT = ROOT
        kit.LO, kit.HI = part['lo'], hi
        kit.BASES = dict(part['bases'])
        return {'image': image, 'device': 'ZXSPECTRUM48', 'header': part['header']}
    kit.load_case = own_case

    def own_l1(paths, mem):
        """the part's windows, each clamped to its range (kit's load_l1 over the whole image otherwise)"""
        starts, entries, reads = set(), set(), [0] * 0x10000
        for name, lo, hi_w, count_reads in part['windows']:
            path = os.path.join(WORK, name, 'l1.json')
            if not os.path.exists(path):
                continue
            doc = json.load(open(path))
            for z80, page, code, *_ in doc['instructions']:
                at = int(z80[1:], 16)
                raw = bytes.fromhex(code)
                if page not in kit.BASES or not lo <= at or at + len(raw) > hi_w:
                    continue
                if kit.decode(mem, at)[0] == len(raw) and mem[at] == raw[0]:
                    starts.add(at)
            for r in doc['routines']:
                at = int(r['entry'][1:], 16)
                if r['page'] in kit.BASES and lo <= at < hi_w:
                    entries.add(at)
            if count_reads:
                for pg in doc.get('byte_counts', []):
                    base = kit.BASES.get(pg['page'])
                    if base is None:
                        continue
                    for i, n in enumerate(pg['reads']):
                        if n and lo <= base + i < hi_w:
                            reads[base + i] += n
        return starts, entries, reads
    kit.load_l1 = own_l1

    header = kit.header

    def own_header(config):
        text = header(config)
        return text.replace('from src/game/game.ann', 'from %s (tools/menu99_mkgame.py %s)' % (part['ann'], a.part)) \
                   .replace('edit game.ann', 'edit %s' % os.path.basename(part['ann']))
    kit.header = own_header

    ann = os.path.join(ROOT, part['ann'])
    over = set()
    if os.path.exists(ann):
        for line in open(ann):
            m = re.match(r'^#\s*@over\s+\$([0-9A-Fa-f]{4})\b', line.strip())
            if m:
                over.add(int(m.group(1), 16))
    decode = kit.decode

    def own_decode(mem, at):
        n, targets, falls, call = decode(mem, at)
        return n, [t for t in targets if t not in over], falls, call
    kit.decode = own_decode
    sys.argv = [KIT, '--case', ROOT, '--venv', a.venv, '--sjasmplus', a.sjasmplus, '--out', out, '--ann', ann]
    status = kit.main()
    if status or not a.install:
        return status
    dest = os.path.join(ROOT, part['dest'])
    modules = [m for _, m in kit.Annotations(ann).modules]
    for name in modules:
        shutil.copyfile(os.path.join(out, name + '.asm'), os.path.join(dest, name + '.asm'))
    top = open(os.path.join(out, 'game.asm')).read().replace('SAVEBIN "game.bin"', 'SAVEBIN "%s"' % part['bin'])
    open(os.path.join(dest, part['top'] + '.asm'), 'w').write(top)
    files = {}
    for base, _, names in os.walk(os.path.join(out, 'res')):
        for name in names:
            path = os.path.join(base, name)
            files[os.path.relpath(path, os.path.join(out, 'res'))] = open(path, 'rb').read()
    if files:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import menu99_res  # noqa: E402
        menu99_res.install(files)
    print(f'installed {len(modules) + 1} files in {part["dest"]}, {len(files)} resources')
    return 0


if __name__ == '__main__':
    sys.exit(main())

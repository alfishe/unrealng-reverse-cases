#!/usr/bin/env python3
"""NE's code entries next to the bytes ANE holds at a given address: the instructions that differ, side by side.

  entry_diff.py --ane IMAGE64K NAME[@ANEADDR] ... [--context 1]

NAME is an entry of NE's game.ann (games/nether-earth/src/game/game.ann); ANEADDR (hex) is where ANE holds it,
NE's own address by default. Both sides are disassembled with z80dasm (on PATH) and aligned with difflib, so an
inserted or removed instruction shows as such. Marks: * a different instruction, ~ the same instruction with
another 16-bit operand. ANE may run longer than NE's entry: --extra N bytes more on ANE's side.
"""

import argparse
import difflib
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ne_match  # noqa: E402


def disassemble(data, org):
    scratch = os.path.join(HERE, '..', 'work', 'tmp')  # the case's own scratch, not the shared /tmp
    os.makedirs(scratch, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False, dir=scratch) as f:
        f.write(data)
        path = f.name
    try:
        out = subprocess.run(['z80dasm', '-a', '-g', hex(org), path], capture_output=True, text=True).stdout
    finally:
        os.remove(path)
    rows = []
    for line in out.splitlines():
        m = re.match(r'\t(.+?)\s*;([0-9a-f]{4})', line)
        if m:
            rows.append((int(m.group(2), 16), re.sub(r'\s+', ' ', m.group(1)).strip()))
    return rows


def normal(text):
    """An instruction with its 16-bit operands written as nn: relocation does not count as a change"""
    return re.sub(r'\b0?[0-9a-f]{4}h\b', 'nn', text)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ane', required=True)
    p.add_argument('--ne-image', default=os.path.join(ne_match.NE, 'work', 'mkgame', 'original.bin'))
    p.add_argument('--ann', default=os.path.join(ne_match.NE, 'src', 'game', 'game.ann'))
    p.add_argument('--extra', type=int, default=0)
    p.add_argument('--all', action='store_true', help='print every instruction, not only the differences')
    p.add_argument('names', nargs='+')
    args = p.parse_args()
    ne = open(args.ne_image, 'rb').read()
    ane = open(args.ane, 'rb').read()
    entries = {name: (start, end, kind) for start, end, kind, name in ne_match.read_entries(args.ann)}
    for spec in args.names:
        name, _, at = spec.partition('@')
        start, end, kind = entries[name]
        where = int(at, 16) if at else start
        left = disassemble(ne[start:end], start)
        right = disassemble(ane[where:where + end - start + args.extra], where)
        print(f'== {name} NE ${start:04X}-${end - 1:04X}  ANE ${where:04X}')
        sm = difflib.SequenceMatcher(a=[normal(t) for _, t in left], b=[normal(t) for _, t in right], autojunk=False)
        for op, a0, a1, b0, b1 in sm.get_opcodes():
            n = max(a1 - a0, b1 - b0)
            for k in range(n):
                l = left[a0 + k] if a0 + k < a1 else None
                r = right[b0 + k] if b0 + k < b1 else None
                mark = '*'
                if op == 'equal':
                    mark = '~' if l[1] != r[1] else ' '  # ~: only a 16-bit operand differs
                    if mark == ' ' and not args.all:
                        continue
                print(f"{mark} {'%04X %-28s' % l if l else ' ' * 33} | {'%04X %s' % r if r else ''}")


if __name__ == '__main__':
    main()

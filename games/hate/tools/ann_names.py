#!/usr/bin/env python3
"""Name labels inside entries of src/game/game.ann (the l_XXXX labels of the generated source).

    python3 tools/ann_names.py CF65=SetRestart CF8A=FreeRecordsLoop ...

An address with a comment line ("$CF65 ; text") gets the name on that line; otherwise a line "$ADDR Name" goes in
after the annotation line of the nearest address below it. A name already used, or an address that is an entry, is
refused. Then run kit/mkgame.py --install (it checks the source still assembles to the original image).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANN = os.path.join(ROOT, 'src', 'game', 'game.ann')
LINE = re.compile(r'\$([0-9A-F]{4})(\s+[cbwts])?(?:\s+(\w+))?')


def main():
    pairs = []
    for arg in sys.argv[1:]:
        a, name = arg.split('=')
        pairs.append((int(a.lstrip('$'), 16), name))
    lines = open(ANN).read().split('\n')
    used = set()
    for line in lines:
        m = LINE.match(line)
        if m and m.group(3):
            used.add(m.group(3))
    for a, name in pairs:
        if name in used:
            sys.exit(f'{name} is already a name')
        if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', name):
            sys.exit(f'{name}: PascalCase, letters and digits')
        best, best_x = None, -1
        for i, line in enumerate(lines):
            m = LINE.match(line)
            if not m:
                continue
            x = int(m.group(1), 16)
            if x == a:
                if m.group(2):
                    sys.exit(f'${a:04X} is an entry: rename it there')
                if m.group(3):
                    sys.exit(f'${a:04X} already has the name {m.group(3)}')
                lines[i] = f'${a:04X} {name}' + line[5:]
                best = None
                break
            if best_x <= x < a:
                best, best_x = i, x
        else:
            if best is None:
                sys.exit(f'${a:04X}: no annotation below it')
            lines.insert(best + 1, f'${a:04X} {name}')
        used.add(name)
    open(ANN, 'w').write('\n'.join(lines))
    print(f'named {len(pairs)}')


if __name__ == '__main__':
    main()

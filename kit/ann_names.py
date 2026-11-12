#!/usr/bin/env python3
"""Name labels inside entries of an .ann (the l_XXXX labels of the generated source).

    python3 kit/ann_names.py --case CASE [--ann FILE] CF65=SetRestart $cf8a=FreeRecordsLoop ...

--ann defaults to the main part's CASE/src/<main>/<main>.ann (case.json "main"; src/game/game.ann in a game; a part's
.ann is given relative to the case). Addresses in either case,
with or without the $. The lines are read with kit/mkgame.py's grammar (docs/ann-format.md 1): a kind is a lone
lower-case c, b, w, t or s; a one-letter name (X, Y) is a name, never a kind; the width of a data entry is not a name.

An address with a comment line ("$CF65 ; text") gets the name on that line; otherwise a line "$ADDR Name" goes in
after the annotation line of the nearest address below it. A name already used, or an address that is an entry, is
refused. Then run kit/mkgame.py --case CASE --install (it checks the source still assembles to the original image).
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mkgame import ANNOTATION as LINE, main_name  # noqa: E402  (address, kind, name, width, comment)

ANN = None


def main():
    global ANN
    argv = sys.argv[1:]
    if argv[:1] != ['--case'] or len(argv) < 3:
        sys.exit(__doc__)
    config = os.path.join(argv[1], 'case.json')
    main = main_name(json.load(open(config)) if os.path.exists(config) else {})
    ANN = os.path.join(argv[1], 'src', main, main + '.ann')
    rest = argv[2:]
    if rest[:1] == ['--ann']:
        if len(rest) < 3:
            sys.exit(__doc__)
        ANN = os.path.join(argv[1], rest[1])
        rest = rest[2:]
    pairs = []
    for arg in rest:
        a, name = arg.split('=')
        pairs.append((int(a.lstrip('$'), 16), name))
    lines = open(ANN).read().split('\n')
    used = set()
    for line in lines:
        m = LINE.match(line.strip())
        if m and m.group(3):
            used.add(m.group(3))
    for a, name in pairs:
        if name in used:
            sys.exit(f'{name} is already a name')
        if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', name):
            sys.exit(f'{name}: PascalCase, letters and digits')
        best, best_x = None, -1
        for i, line in enumerate(lines):
            m = LINE.match(line.strip()) if line.startswith('$') else None
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

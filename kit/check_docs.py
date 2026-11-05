#!/usr/bin/env python3
"""Check the documentation: every mermaid diagram renders (mmdc), every relative link and image exists, and no $
is left in prose (GitHub reads a pair of them as LaTeX math; code_addresses.py fixes addresses).

    python3 kit/check_docs.py [--case CASE] [FILE.md ...]   # default: CASE's WALKTHROUGH.md, README.md, docs/*.md

Also lists a figure in docs/img or docs/img/routines that no document links (GUIDE.md 4.2); docs/img/res holds the resource previews.
"""
import glob
import os
import re
import subprocess
import sys
import tempfile

import code_addresses

here = os.getcwd()


def main():
    global here
    argv = sys.argv[1:]
    if argv[:1] == ['--case']:
        here, argv = os.path.abspath(argv[1]), argv[2:]
    files = argv or [os.path.join(here, 'WALKTHROUGH.md'), os.path.join(here, 'README.md')] + sorted(
        glob.glob(os.path.join(here, 'docs', '*.md')))
    bad = 0
    linked = set()
    with tempfile.TemporaryDirectory() as tmp:
        for path in files:
            text = open(path).read()
            for n, block in enumerate(re.findall(r'```mermaid\n(.*?)```', text, re.S)):
                # GitHub decodes HTML entities before mermaid parses the block, so &quot; becomes a bare quote
                # that ends the label; mmdc accepts it. Mermaid's own escapes are #quot; #amp; #lt; #gt; #NN;.
                for ent in re.findall(r'&(?:[a-z]+|#\d+);', block):
                    bad += 1
                    print(f'{os.path.relpath(path, here)}: mermaid diagram {n + 1}: HTML entity {ent} '
                          f'(GitHub breaks on it; write #{ent[1:]})')
                src = os.path.join(tmp, f'd{n}.mmd')
                open(src, 'w').write(block)
                r = subprocess.run(['mmdc', '-q', '-i', src, '-o', os.path.join(tmp, f'd{n}.svg')],
                                   capture_output=True, text=True)
                if r.returncode != 0:
                    bad += 1
                    print(f'{os.path.relpath(path, here)}: mermaid diagram {n + 1}: {r.stderr.strip()[:400]}')
            for target in re.findall(r'\]\(([^)#\s]+)', text):
                if '://' in target:
                    continue
                linked.add(os.path.normpath(os.path.join(os.path.dirname(path), target)))
                if not os.path.exists(os.path.join(os.path.dirname(path), target)):
                    bad += 1
                    print(f'{os.path.relpath(path, here)}: missing {target}')
            for n in code_addresses.bare_dollars(text):
                bad += 1
                print(f'{os.path.relpath(path, here)}:{n}: $ in prose renders as math on GitHub (code_addresses.py)')
    if not argv:
        for figure in sorted(glob.glob(os.path.join(here, 'docs', 'img', '*.*')) + glob.glob(os.path.join(here, 'docs', 'img', 'routines', '*.*'))):
            if figure.endswith(('.png', '.gif', '.svg')) and os.path.normpath(figure) not in linked:
                print(f'{os.path.relpath(figure, here)}: no document links this figure')
    print('docs: ok' if not bad else f'docs: {bad} problem(s)')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()

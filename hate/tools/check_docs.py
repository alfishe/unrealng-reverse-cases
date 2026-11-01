#!/usr/bin/env python3
"""Check the documentation: every mermaid diagram renders (mmdc), every relative link and image exists, and no $
is left in prose (GitHub reads a pair of them as LaTeX math; code_addresses.py fixes addresses).

    python3 check_docs.py [docs/*.md WALKTHROUGH.md ...]      # default: WALKTHROUGH.md, README.md, docs/*.md
"""
import glob
import os
import re
import subprocess
import sys
import tempfile

import code_addresses

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    files = sys.argv[1:] or [os.path.join(here, 'WALKTHROUGH.md'), os.path.join(here, 'README.md')] + sorted(
        glob.glob(os.path.join(here, 'docs', '*.md')))
    bad = 0
    with tempfile.TemporaryDirectory() as tmp:
        for path in files:
            text = open(path).read()
            for n, block in enumerate(re.findall(r'```mermaid\n(.*?)```', text, re.S)):
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
                if not os.path.exists(os.path.join(os.path.dirname(path), target)):
                    bad += 1
                    print(f'{os.path.relpath(path, here)}: missing {target}')
            for n in code_addresses.bare_dollars(text):
                bad += 1
                print(f'{os.path.relpath(path, here)}:{n}: $ in prose renders as math on GitHub (code_addresses.py)')
    print('docs: ok' if not bad else f'docs: {bad} problem(s)')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()

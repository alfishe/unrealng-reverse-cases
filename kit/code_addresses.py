#!/usr/bin/env python3
"""Put hex addresses in Markdown prose into code spans: `$C2B1-$F2E1`.

GitHub reads a pair of $ in text as LaTeX math, so "$C2B1-$F2E1" renders as an italic formula. Text inside code
spans, fenced blocks and mermaid diagrams is left alone. check_docs.py reports any $ left in prose.

    python3 code_addresses.py FILE.md ...
"""
import re
import sys

ADDRESS = re.compile(r'\$[0-9A-Fa-f]{2,4}(?:(?:-|\.\.)\$[0-9A-Fa-f]{2,4})?(?:\+\$?[0-9A-Fa-f]+)?')


def prose_parts(line):
    """Split a line into (is_code, text) parts by code spans."""
    parts, pos = [], 0
    for m in re.finditer(r'`+[^`]*`+', line):
        parts.append((False, line[pos:m.start()]))
        parts.append((True, m.group()))
        pos = m.end()
    parts.append((False, line[pos:]))
    return parts


def convert(text):
    out, fence = [], False
    for line in text.split('\n'):
        if line.lstrip().startswith('```'):
            fence = not fence
            out.append(line)
            continue
        if fence:
            out.append(line)
            continue
        out.append(''.join(t if code else ADDRESS.sub(lambda m: f'`{m.group()}`', t) for code, t in prose_parts(line)))
    return '\n'.join(out)


def bare_dollars(text):
    """Lines of prose that still hold a $ outside code: GitHub may read them as math."""
    found, fence = [], False
    for n, line in enumerate(text.split('\n'), 1):
        if line.lstrip().startswith('```'):
            fence = not fence
            continue
        if not fence and any('$' in t for code, t in prose_parts(line) if not code):
            found.append(n)
    return found


if __name__ == '__main__':
    for path in sys.argv[1:]:
        text = open(path).read()
        new = convert(text)
        if new != text:
            open(path, 'w').write(new)
            print(f'{path}: converted')
        for n in bare_dollars(new):
            print(f'{path}:{n}: $ left in prose')

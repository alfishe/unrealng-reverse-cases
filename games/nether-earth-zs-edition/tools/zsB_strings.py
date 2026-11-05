#!/usr/bin/env python3
"""Doc 08's string tables: every text entry (kind t) of a game's .ann, decoded from the built bytes with PrintInline's
codes (0 end, 1 Y X position, 2 A attribute, 3 the next row, 4 N size; $20-$5F a glyph of the font).

    python3 tools/zsB_strings.py --ann src/game99/game.ann --bin build/game99/game-6780.bin --at 6780 [--md OUT]

One row an entry: its address, its label, the strings as printed (each run of glyphs with the position and the
attribute in force when it starts). The entry ends where the next entry of the .ann starts.
"""
import argparse
import re

ATTR_NAMES = {0: 'black', 1: 'blue', 2: 'red', 3: 'magenta', 4: 'green', 5: 'cyan', 6: 'yellow', 7: 'white'}


def attr_text(a):
    s = f'ink {ATTR_NAMES[a & 7]}, paper {ATTR_NAMES[(a >> 3) & 7]}'
    if a & 64:
        s += ', bright'
    return s


def entries(ann):
    out = []
    for line in open(ann):
        m = re.match(r'^\$([0-9A-F]{4}) ([a-z]) (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2), m.group(3)))
    out.sort()
    return out


def decode(data):
    """[(row, col, attr, size, text)] of the glyph runs; positions as the codes set them (None: carried on)"""
    runs, i = [], 0
    row = col = attr = size = None
    cur = None
    while i < len(data):
        b = data[i]
        if b == 0:
            break
        if b >= 0x20:
            if cur is None:
                cur = [row, col, attr, size, '']
                runs.append(cur)
            cur[4] += chr(b) if b < 0x60 else '?'
            i += 1
            continue
        cur = None
        if b == 1 and i + 2 < len(data):
            row, col = data[i + 1], data[i + 2]
            i += 3
        elif b == 2 and i + 1 < len(data):
            attr = data[i + 1]
            i += 2
        elif b == 3:
            row = row + 1 if row is not None else None
            i += 1
        elif b == 4 and i + 1 < len(data):
            size = data[i + 1]
            i += 2
        else:
            i += 1
    return runs


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ann', required=True)
    p.add_argument('--bin', required=True)
    p.add_argument('--at', required=True)
    p.add_argument('--md')
    a = p.parse_args()
    base = int(a.at, 16)
    mem = open(a.bin, 'rb').read()
    es = entries(a.ann)
    rows = ['| Address | Entry | Printed (row, column; attribute; size) |', '| --- | --- | --- |']
    for k, (addr, kind, label) in enumerate(es):
        if kind != 't':
            continue
        end = es[k + 1][0] if k + 1 < len(es) else base + len(mem)
        data = mem[addr - base:end - base]
        runs = decode(data)
        parts = []
        for r, c, at, sz, text in runs:
            where = f'({r},{c})' if r is not None else '(on)'
            extra = []
            if at is not None:
                extra.append(f'`${at:02X}`')
            if sz:
                extra.append(f'size `${sz:02X}`')
            parts.append(f'`{text.replace("`", "")}` {where}' + (' ' + ', '.join(extra) if extra else ''))
        rows.append(f'| `${addr:04X}` | `{label}` | ' + ('; '.join(parts) or '(no glyphs: codes only)') + ' |')
    text = '\n'.join(rows) + '\n'
    if a.md:
        open(a.md, 'w').write(text)
    print(text)


if __name__ == '__main__':
    main()

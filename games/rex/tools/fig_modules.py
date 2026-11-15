#!/usr/bin/env python3
"""The module map of the three parts: each byte of REX 1, REX 2 and DEMO coloured by the source module that
assembles it, read from the build's sjasmplus listings.

    python3 tools/fig_modules.py [--table] [--out docs/img/arch/modules.png]

A byte belongs to the module whose line emits it: a line with bytes, an INCBIN (its length) or a DS / DEFS. The bars
run from `$6000` to `$FFFF`, one a part; a module of several stretches is drawn in each. --table prints every
module's stretches and its size, a part after the other.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

C = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
R = os.path.normpath(os.path.join(C, '..', '..'))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402

PARTS = [('REX 1', 'build/game.lst', 0x6018), ('REX 2', 'build/rex2.lst', 0x61A8), ('DEMO', 'build/demo.lst', 0x61A8)]
LINE = re.compile(r'^\s*\d+\+?\s+([0-9A-F]{4})\s((?:[0-9A-F]{2}\s)*)\s*(.*)$')
INCBIN = re.compile(r'INCBIN\s+"[^"]+"\s*,\s*\$?([0-9A-Fa-f]+)\s*,\s*(\$?[0-9A-Fa-f]+)')
# one colour a module, the same in every part
COLOURS = {
    'graphics': (120, 120, 140), 'entry': (230, 80, 80), 'mainloop': (255, 40, 40), 'rex': (240, 140, 60),
    'bomb': (250, 200, 60), 'score': (220, 220, 80), 'death': (180, 60, 120), 'cells': (150, 200, 90),
    'variables': (250, 250, 250), 'hud': (90, 200, 200), 'controls': (60, 140, 250), 'grid': (120, 90, 220),
    'weapons': (230, 110, 200), 'codepanel': (255, 160, 160), 'attract': (255, 160, 160), 'tutor': (255, 160, 160),
    'tables': (170, 150, 110), 'render': (60, 220, 120), 'objects': (200, 120, 60), 'rooms': (100, 160, 120),
    'panels': (160, 200, 240), 'rexmove': (250, 170, 110), 'collisions': (190, 90, 90), 'sound': (240, 230, 160),
    'menu': (140, 110, 170)}


def module_bytes(path):
    """{address: module} for every byte the listing emits"""
    owner = {}
    module = None
    for raw in open(path, encoding='latin-1'):
        if raw.startswith('# file opened:'):
            module = os.path.basename(raw.split(':', 1)[1].strip()).rsplit('.', 1)[0]
            continue
        m = LINE.match(raw)
        if not m or module in (None, 'game', 'rex2', 'demo'):
            continue
        address = int(m.group(1), 16)
        count = len(m.group(2).split())
        text = m.group(3)
        inc = INCBIN.search(text)
        if inc:
            count = int(inc.group(2).lstrip('$'), 16 if inc.group(2).startswith('$') else 10)
        elif count and '...' in raw:
            pass  # sjasmplus shows the first bytes only; the next line's address closes the run below
        if count:
            for a in range(address, address + count):
                owner[a & 0xFFFF] = module
    return owner


def fill_gaps(owner, lo, hi):
    """a byte no line showed (a DB longer than the listing's byte column) is the module of the byte before it"""
    last = None
    for a in range(lo, hi):
        if a in owner:
            last = owner[a]
        elif last:
            owner[a] = last
    return owner


def stretches(owner, lo, hi):
    out = []
    for a in range(lo, hi):
        m = owner.get(a)
        if out and out[-1][2] == m and out[-1][1] == a:
            out[-1][1] = a + 1
        else:
            out.append([a, a + 1, m])
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(C, 'docs/img/arch/modules.png'))
    p.add_argument('--table', action='store_true')
    a = p.parse_args()
    width, left, bar, gap, top = 1050, 70, 60, 80, 70
    font = K.font(15)
    small = K.font(13)
    image = Image.new('RGB', (width, top + len(PARTS) * (bar + gap) + 150), (24, 24, 30))
    d = ImageDraw.Draw(image)
    d.text((left, 12), 'The module map: every byte of the three code blocks by its source module, $6000-$FFFF',
           fill=(240, 240, 240), font=font)
    span = 0x10000 - 0x6000
    scale = (width - left - 20) / span
    for k in range(0x6000, 0x10001, 0x1000):
        x = left + (k - 0x6000) * scale
        d.line((x, top - 6, x, top + len(PARTS) * (bar + gap) - gap + 4), fill=(70, 70, 80))
        d.text((x - 16, top - 26), f'{k:04X}' if k < 0x10000 else 'FFFF', fill=(200, 200, 200), font=small)
    used = []
    for i, (name, path, lo) in enumerate(PARTS):
        owner = fill_gaps(module_bytes(os.path.join(C, path)), lo, 0xFFFA)
        y = top + i * (bar + gap)
        d.text((6, y + bar // 2 - 9), name, fill=(240, 240, 240), font=font)
        rows = stretches(owner, lo, 0xFFFA)
        for s0, s1, m in rows:
            colour = COLOURS.get(m, (60, 60, 60))
            d.rectangle((left + (s0 - 0x6000) * scale, y, left + (s1 - 0x6000) * scale, y + bar), fill=colour)
            if m and m not in used:
                used.append(m)
        # label the long stretches under the bar
        lane = 0
        for s0, s1, m in rows:
            if m and (s1 - s0) * scale > 30:
                x = left + (s0 - 0x6000) * scale + 2
                d.text((x, y + bar + 3 + 18 * lane), m, fill=(220, 220, 220), font=small)
                lane = 1 - lane
        if a.table:
            print(f'## {name}')
            total = {}
            for s0, s1, m in rows:
                total[m] = total.get(m, 0) + s1 - s0
                print(f'{m}\t${s0:04X}-${s1 - 1:04X}\t{s1 - s0}')
            for m, n in sorted(total.items(), key=lambda kv: -kv[1]):
                print(f'  {m}\t{n}')
    # the key
    y = top + len(PARTS) * (bar + gap) - 20
    x = left
    for m in used:
        w = d.textlength(m, font=small) + 30
        if x + w > width - 10:
            x, y = left, y + 22
        d.rectangle((x, y + 3, x + 14, y + 15), fill=COLOURS.get(m, (60, 60, 60)))
        d.text((x + 18, y), m, fill=(220, 220, 220), font=small)
        x += w
    image = image.crop((0, 0, width, y + 30))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    image.save(a.out)
    print(a.out)


if __name__ == '__main__':
    sys.exit(main())

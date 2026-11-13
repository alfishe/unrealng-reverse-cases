#!/usr/bin/env python3
"""Doc 02's figures: the memory map in its three states, and the parts cut by module.

    python3 tools/fig_arch.py memmap docs/img/arch/memmap.png
    python3 tools/fig_arch.py modules docs/img/arch/modules.png
    python3 tools/fig_arch.py coverage docs/img/arch/coverage.png

memmap: the 48 KB of RAM ($4000-$FFFF) as a ribbon for each state of the game (the front's load, the front, a stage
in play), then the resident part $F000-$FFFF magnified. The regions come from the parts' .ann files (src/*/*.ann:
each entry's module, the entries' extents) and from the loader's notes (work/stage2/notes-loader.md).

modules: each part's bytes along its addresses (the front and the five stage blocks over $6C3F-$F03E, the resident
over $F000-$FFFF), coloured by the module of each entry, as kit/mkgame.py assigns them (the last @module line before
the entry in the .ann). The bars on the right sum each part's bytes by module.

coverage: the code of each part along its addresses, each byte of a code entry green when an instruction over it ran
in one of the part's recordings (their L1 builds, listed in COVERAGE), red when none did: the code known only from
the code. Data entries are grey.
"""
import json
import re
import sys

from figmyth import P, W, F, TEXT, DIM, HI, PANEL, COLOURS, canvas, save  # noqa: F401

ENTRY = re.compile(r'^\$([0-9A-Fa-f]{4}) ([cbwts]) (\w+)')


def entries(part, end):
    """[(address, size, type, name, module)] of src/PART/PART.ann, each entry up to the next."""
    cur, found = None, []
    for line in open(P('src', part, part + '.ann'), encoding='utf-8'):
        if line.startswith('@module '):
            cur = line.split()[1]
        m = ENTRY.match(line)
        if m:
            found.append((int(m.group(1), 16), m.group(2), m.group(3), cur))
    found.sort()
    out = []
    for i, (a, t, n, mod) in enumerate(found):
        b = found[i + 1][0] if i + 1 < len(found) else end + 1
        out.append((a, b - a, t, n, mod))
    return out


def runs(part, end):
    """Adjacent entries of one module merged: [(start, size, module, first entry's name)]."""
    out = []
    for a, size, t, n, mod in entries(part, end):
        if out and out[-1][2] == mod and out[-1][0] + out[-1][1] == a:
            out[-1][1] += size
        else:
            out.append([a, size, mod, n])
    return out


MODULE_COLOUR = {}


def colour_of(mod):
    if mod not in MODULE_COLOUR:
        MODULE_COLOUR[mod] = COLOURS[len(MODULE_COLOUR) % len(COLOURS)]
    return MODULE_COLOUR[mod]


# The fixed colours of the memory map's kinds of region
KIND = {'screen': (90, 140, 220), 'buffer': (70, 110, 170), 'work': (200, 160, 70), 'code': (220, 90, 80),
        'data': (110, 180, 110), 'resident': (170, 110, 210), 'free': (60, 60, 72), 'stack': (240, 220, 90),
        'loader': (220, 130, 60), 'table': (100, 200, 200)}


def ribbon(d, x0, x1, y, h, lo, hi, regions, label_below=True):
    """Draw regions [(start, end, kind, label)] over lo-hi; labels alternate in two rows below."""
    span = hi - lo + 1
    px = lambda a: x0 + (a - lo) * (x1 - x0) / span  # noqa: E731
    d.rectangle((x0, y, x1, y + h), fill=KIND['free'])
    for k, (a, b, kind, label) in enumerate(regions):
        d.rectangle((px(a), y, max(px(b + 1) - 1, px(a) + 1), y + h), fill=KIND[kind], outline=(20, 20, 26))
    lanes = [x0 - 1000] * 4
    for a, b, kind, label in regions:
        if not label:
            continue
        cx = (px(a) + px(b + 1)) / 2
        text = label
        tw = d.textlength(text, font=F(13))
        lx = min(max(cx - tw / 2, x0), x1 - tw)
        lane = next((i for i in range(4) if lanes[i] < lx), 3)
        lanes[lane] = lx + tw + 8
        ly = y + h + 6 + lane * 18
        d.line((cx, y + h, cx, ly + 2), fill=DIM)
        d.text((lx, ly + 2), text, font=F(13), fill=TEXT)
    for a in range(lo, hi + 1, 0x1000 if span > 0x2000 else 0x400):
        d.text((px(a) - 16, y - 18), f'${a:04X}', font=F(13), fill=DIM)
        d.line((px(a), y - 3, px(a), y), fill=DIM)


def memmap(out):
    im, d, y = canvas(1120, 'The memory map: the 48 KB of RAM in three states, and the resident part magnified',
                      'Each ribbon spans $4000-$FFFF (the resident row $F000-$FFFF). Regions from the parts\' .ann '
                      'files (src/*/*.ann)\nand the loader\'s notes. The front and each stage block load over the '
                      'same $6C3F-$F03E;\nthe resident part $F03F-$FFFF stays from the first load to the end.')
    x0, x1 = 16, W - 16
    rows = [
        ('1. the front loading (c1 frames 5166-7826)', [
            (0x4000, 0x57FF, 'screen', 'loading screen'), (0x5800, 0x5AFF, 'screen', 'attrs'),
            (0x6C3F, 0xA83E, 'loader', 'the front arriving (block 37)'),
            (0xF03F, 0xFDFF, 'resident', 'resident code'), (0xFE90, 0xFF83, 'loader', 'turbo loader'),
        ]),
        ('2. the front running (c1 frames 7826-8726): logo, credits, menu', [
            (0x4000, 0x5AFF, 'screen', 'screen'), (0x6C3F, 0x77FF, 'work', 'front work space'),
            (0x7800, 0x79DA, 'code', 'code'), (0x79DB, 0x94DA, 'data', 'the logo picture'),
            (0x94DB, 0xA1C0, 'code', 'credits, menu, keys, fonts'), (0xA1C1, 0xA83E, 'work', 'zeros'),
            (0xF03F, 0xFFFF, 'resident', 'resident'),
        ]),
        ('3. a stage in play (stage 1, c1 frame 15476)', [
            (0x4000, 0x57FF, 'screen', 'screen'), (0x5800, 0x5AFF, 'screen', 'attrs'),
            (0x5B00, 0x6CFF, 'buffer', 'play buffer'), (0x6D00, 0x6FFF, 'work', 'shadow attrs'),
            (0x7000, 0x77FF, 'work', 'records, spans'), (0x7800, 0xB4B1, 'code', 'stage code $7800'),
            (0xB4B2, 0xC2B0, 'data', 'packed map'), (0xC2B1, 0xF03E, 'data', 'sprites and pictures'),
            (0xF03F, 0xFCFF, 'resident', 'resident (row 4)'), (0xFD00, 0xFE00, 'table', ''),
            (0xFE01, 0xFE8F, 'work', ''), (0xFE90, 0xFF83, 'loader', ''), (0xFFD5, 0xFFFF, 'stack', ''),
        ]),
    ]
    for title, regions in rows:
        d.text((x0, y), title, font=F(15), fill=HI)
        y += 42
        ribbon(d, x0, x1, y, 34, 0x4000, 0xFFFF, regions)
        y += 34 + 6 + 4 * 18 + 16
    d.text((x0, y), '4. the resident part $F000-$FFFF by module (src/resident/resident.ann)', font=F(15), fill=HI)
    y += 42
    regions = []
    kind_of = {'init': 'code', 'game': 'code', 'print': 'code', 'ay': 'code', 'stageload': 'loader',
               'im2': 'table', 'font': 'data', 'vars': 'work', 'score': 'work', 'tables': 'data', 'keys': 'code',
               'turbo': 'loader'}
    for a, size, mod, name in runs('resident', 0xFFFF):
        regions.append((a, a + size - 1, kind_of[mod], mod if size >= 60 else ''))
    ribbon(d, x0, x1, y, 34, 0xF000, 0xFFFF, regions)
    y += 34 + 6 + 4 * 18 + 10
    for line in ['$F000-$F03E: ResidentInit, overwritten by every stage block (the blocks end at $F03E).',
                 '$FD00-$FE00 the IM 2 table; $FE01-$FE8F the stage\'s work space (vars); $FE90-$FF83 the turbo '
                 'loader and LoadBlock;',
                 'the stack grows down from $FFFF over the font leftover: its lowest byte over every recording is '
                 '$FFD5.']:
        d.text((x0, y), line, font=F(13), fill=DIM)
        y += 20
    y += 6
    lx = x0
    for kind, name in [('screen', 'screen'), ('buffer', 'play buffer'), ('work', 'work space'), ('code', 'code'),
                       ('data', 'data'), ('resident', 'resident'), ('table', 'IM 2 table'),
                       ('loader', 'loaders'), ('stack', 'stack'), ('free', 'not used')]:
        d.rectangle((lx, y + 3, lx + 12, y + 15), fill=KIND[kind])
        d.text((lx + 18, y), name, font=F(13), fill=TEXT)
        lx += 30 + d.textlength(name, font=F(13))
    save(im.crop((0, 0, W, y + 30)), out)


PARTS = [('front', 0x6C3F, 0xA83E), ('stage1', 0x6C3F, 0xF03E), ('stage2', 0x6C3F, 0xF03E),
         ('stage3', 0x6C3F, 0xF03E), ('stage4', 0x6C3F, 0xF03E), ('stage5', 0x6C3F, 0xF03E),
         ('resident', 0xF000, 0xFFFF)]


PALETTE = [(230, 90, 80), (90, 190, 110), (100, 150, 240), (240, 200, 70), (200, 110, 230), (70, 200, 210),
           (245, 150, 60), (160, 220, 80), (240, 130, 190), (150, 150, 250), (210, 175, 120), (120, 225, 190),
           (250, 250, 250), (170, 120, 90), (180, 60, 80), (60, 130, 90), (90, 90, 200)]


def group_of(part):
    return 'stage' if part.startswith('stage') else part


def modules(out):
    im, d, y = canvas(1100, 'The parts cut by module: where each module\'s bytes lie, and how many',
                      'Left: each part along its addresses ($6C3F-$F03E for the front and the stages, $F000-$FFFF '
                      'for the resident),\nan entry coloured by its module; a white line under the code entries. '
                      'Right: the part\'s bytes summed by module.\nFrom src/*/*.ann: the module of an entry is the '
                      'last @module line before it.')
    colours = {}
    for group in ('stage', 'front', 'resident'):
        totals = {}
        for part, lo, hi in PARTS:
            if group_of(part) == group:
                for a, size, t, n, mod in entries(part, hi):
                    totals[mod] = totals.get(mod, 0) + size
        for k, (mod, _) in enumerate(sorted(totals.items(), key=lambda kv: -kv[1])):
            colours[group, mod] = PALETTE[k % len(PALETTE)]
    x0, x1 = 100, 680
    bx0, bx1 = 710, W - 16
    for part, lo, hi in PARTS:
        g = group_of(part)
        d.text((16, y + 8), part, font=F(14), fill=HI)
        span = 0xF03E - 0x6C3F + 1 if part != 'resident' else 0x1000
        px = lambda a: x0 + (a - lo) * (x1 - x0) / span  # noqa: E731
        d.rectangle((x0, y, x1, y + 30), fill=PANEL)
        code = 0
        for a, size, t, n, mod in entries(part, hi):
            if a < lo:
                continue
            d.rectangle((px(a), y, max(px(a + size) - 1, px(a)), y + 30), fill=colours[g, mod])
            if t == 'c':
                code += size
                d.line((px(a), y + 32, max(px(a + size) - 1, px(a)), y + 32), fill=TEXT, width=2)
        d.text((x0, y + 36), f'${lo:04X}', font=F(13), fill=DIM)
        end = f'${hi:04X}'
        ex = px(hi + 1) - d.textlength(end, font=F(13))
        d.text((ex, y + 36), end, font=F(13), fill=DIM)
        info = f'{hi - lo + 1} bytes; code entries {code}'
        ix = x0 + 60 if ex > x0 + 60 + d.textlength(info, font=F(13)) + 10 else px(hi + 1) + 12
        d.text((ix, y + 36), info, font=F(13), fill=DIM)
        sums = {}
        for a, size, t, n, mod in entries(part, hi):
            sums[mod] = sums.get(mod, 0) + size
        bx = bx0
        total = sum(sums.values())
        for mod, size in sorted(sums.items(), key=lambda kv: -kv[1]):
            w = (bx1 - bx0) * size / total
            d.rectangle((bx, y, bx + w - 1, y + 30), fill=colours[g, mod])
            if w > 60:
                d.text((bx + 3, y + 8), mod, font=F(13), fill=(20, 20, 26))
            bx += w
        y += 70
    for group, title in (('stage', 'stage modules'), ('front', 'front modules'), ('resident', 'resident modules')):
        lx, ly = 16, y
        d.text((lx, ly), title + ':', font=F(13), fill=HI)
        lx += 140
        for (g, mod), c in colours.items():
            if g != group:
                continue
            tw = d.textlength(mod, font=F(13))
            if lx + tw + 30 > W - 16:
                lx, ly = 156, ly + 20
            d.rectangle((lx, ly + 3, lx + 12, ly + 15), fill=c)
            d.text((lx + 18, ly), mod, font=F(13), fill=TEXT)
            lx += 30 + tw
        y = ly + 24
    save(im.crop((0, 0, W, y + 6)), out)

# The L1 builds that witness each part (the recordings of WALKTHROUGH 6.0 and work/stage2/notes-rec.md)
COVERAGE = [
    ('front', 0x7800, 0xA1C0, ['work/stage1/c1/l1.json', 'work/stage1/rec/menu/l1.json',
                               'work/stage2/rec/joystick/l1.json', 'work/stage2/rec/rzx-r0/l1.json']),
    ('stage1', 0x7800, 0xB4B1, ['work/stage1/c1o/l1.json', 'work/stage1/rec/deaths/l1.json',
                                'work/stage1/rec/s1-idle/l1.json', 'work/stage1/rec/s1-right/l1.json',
                                'work/stage2/rec/rzx-r1/l1.json']),
    ('stage2', 0x7800, 0xB7D4, ['work/stage1/rec/s2-right/l1.json', 'work/stage2/rec/rzx-r2/l1.json']),
    ('stage3', 0x7800, 0xB555, ['work/stage1/rec/s3-right/l1.json', 'work/stage2/rec/rzx-r3/l1.json']),
    ('stage4', 0x7800, 0xB77E, ['work/stage1/rec/s4-right/l1.json', 'work/stage2/rec/rzx-r4/l1.json']),
    ('stage5', 0x7800, 0xA366, ['work/stage1/rec/s5-right/l1.json', 'work/stage2/rec/rzx-r5/l1.json',
                                'work/stage2/rec/ending/l1.json']),
    ('resident', 0xF03F, 0xFFFF, ['work/stage1/c1/l1.json', 'work/stage2/rec/rzx-r1/l1.json',
                                  'work/stage2/rec/rzx-r2/l1.json', 'work/stage2/rec/rzx-r3/l1.json',
                                  'work/stage2/rec/rzx-r4/l1.json', 'work/stage2/rec/rzx-r5/l1.json']),
]


def executed(paths, lo, hi):
    """The set of addresses lo-hi covered by an instruction that ran in any of the builds."""
    ran = set()
    for path in paths:
        for ins in json.load(open(P(path)))['instructions']:
            a = int(ins[0].lstrip('$'), 16)
            if lo <= a <= hi and ins[4]:
                ran.update(range(a, a + len(ins[2]) // 2))
    return ran


def coverage(out):
    im, d, y = canvas(900, 'The code that ran: each part\'s code entries against its recordings',
                      'Green: a byte of a code entry under an instruction that ran in a recording; red: a code '
                      'byte no recording ran (known only\nfrom the code); grey: data entries. Each row spans the '
                      'part\'s code extent; the recordings are named under it.')
    x0, x1 = 100, W - 16
    rows = []
    for part, lo, hi, paths in COVERAGE:
        ran = executed(paths, lo, hi)
        span = hi - lo + 1
        px = lambda a: x0 + (a - lo) * (x1 - x0) / span  # noqa: E731
        d.text((16, y + 8), part, font=F(14), fill=HI)
        d.rectangle((x0, y, x1, y + 30), fill=PANEL)
        code_bytes = ran_bytes = 0
        for a, size, t, n, mod in entries(part, 0xFFFF):
            if a + size <= lo or a > hi:
                continue
            for b in range(max(a, lo), min(a + size, hi + 1)):
                if t == 'c':
                    code_bytes += 1
                    ok = b in ran
                    ran_bytes += ok
                    c = (90, 190, 110) if ok else (230, 80, 70)
                else:
                    c = (95, 95, 110)
                d.line((px(b), y, px(b), y + 30), fill=c)
        d.text((x0, y + 36), f'${lo:04X}', font=F(13), fill=DIM)
        end = f'${hi:04X}'
        d.text((x1 - d.textlength(end, font=F(13)), y + 36), end, font=F(13), fill=DIM)
        pct = 100.0 * ran_bytes / code_bytes
        d.text((x0 + 60, y + 36), f'code {code_bytes} bytes, ran {ran_bytes} ({pct:.1f} %); '
               + ', '.join(p.split('/')[-2] for p in paths), font=F(13), fill=DIM)
        rows.append((part, code_bytes, ran_bytes))
        print(part, code_bytes, ran_bytes, f'{pct:.1f}')
        y += 70
    save(im.crop((0, 0, W, y + 4)), out)


if __name__ == '__main__':
    cmd, out = sys.argv[1], sys.argv[2]
    {'memmap': memmap, 'modules': modules, 'coverage': coverage}[cmd](out)

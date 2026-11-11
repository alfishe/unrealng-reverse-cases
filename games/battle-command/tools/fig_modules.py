#!/usr/bin/env python3
"""Doc 02 figure: the module map of every bank, from the source's annotations.

    python3 tools/fig_modules.py docs/img/arch/modules.png

Each bank is one strip of 16 K. A module runs from its @module line's first entry to the next module's first entry
(as kit/mkgame.py cuts the source); the last entry of a part ends where the part's binary ends (build/*.bin, made by
tools/build.sh). src/game/game.ann covers banks 5, 2 and 0 ($5B00-$FFFF as the game sees them at the entry), the
others cover their bank at $C000. Bank 0's mission block ($DBC5-$FB3E, side 2) and bank 1 (the staging copy) are
drawn as their own spans; what no part covers stays dark.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
from kitlib import font  # noqa: E402

W, X0, X1 = 1050, 70, 1030
PALETTE = ['#e6194b', '#3cb44b', '#4363d8', '#f58231', '#911eb4', '#46a0a0', '#d0409a', '#9aa020', '#c08080',
           '#2a8a8a', '#a07ad0', '#9a6324', '#a0a000', '#800000', '#5aa05a', '#808000', '#d07050', '#000075',
           '#707070', '#4a7bd0', '#b05a8a', '#e0a030', '#30a0c0', '#6a8fd0', '#c07a3a', '#8a6fc0', '#3d8f8f',
           '#d03030', '#5a5ad0', '#a0a040', '#60a060', '#c0a060']
ENTRY = re.compile(r'^\$([0-9A-Fa-f]{4})\s')


def hue(i):
    import colorsys
    r, g, b = colorsys.hsv_to_rgb((i * 0.618034) % 1, 0.55, 0.8)
    return '#%02x%02x%02x' % (int(r * 255), int(g * 255), int(b * 255))


def spans(ann, end):
    """[(start, end, module)] of an .ann, cut at module boundaries."""
    out, mod, pending = [], None, None
    starts = []
    for line in open(ann):
        if line.startswith('@module'):
            pending = line.split()[1]
            continue
        m = ENTRY.match(line)
        if m:
            a = int(m.group(1), 16)
            if pending:
                mod, pending = pending, None
            starts.append((a, mod))
    starts.sort()
    for i, (a, mod) in enumerate(starts):
        b = starts[i + 1][0] if i + 1 < len(starts) else end
        if out and out[-1][2] == mod and out[-1][1] == a:
            out[-1] = (out[-1][0], b, mod)
        else:
            out.append((a, b, mod))
    return out


def main():
    game_end = 0x5B00 + os.path.getsize(os.path.join(ROOT, 'build', 'game.bin'))
    game = spans(os.path.join(ROOT, 'src', 'game', 'game.ann'), min(game_end, 0xDBC5))
    rows = []  # (title, base, [(start, end, label)])
    rows.append(('bank 5', 0x4000, [(0x4000, 0x5B00, 'screen')] + [s for s in game if s[0] < 0x8000]))
    rows.append(('bank 2', 0x8000, [s for s in game if 0x8000 <= s[0] < 0xC000]))
    rows.append(('bank 0', 0xC000, [s for s in game if s[0] >= 0xC000] + [(0xDBC5, 0xFB3F, 'mission block')]))
    rows.append(('bank 1', 0xC000, [(0xC301, 0x10000, 'staged $8301-$BFFF')]))
    for n in (3, 4, 6, 7):
        end = 0xC000 + os.path.getsize(os.path.join(ROOT, 'build', f'bank{n}.bin'))
        rows.append((f'bank {n}', 0xC000, spans(os.path.join(ROOT, 'src', f'bank{n}', f'bank{n}.ann'), end)))
    names = []
    for _t, _b, ss in rows:
        for s in ss:
            if s[2] and s[2] not in names:
                names.append(s[2])
    colour = {n: (PALETTE[i] if i < len(PALETTE) else hue(i)) for i, n in enumerate(names)}
    colour['screen'] = '#b0b0b0'
    colour['mission block'] = '#d8d8d8'
    colour['staged $8301-$BFFF'] = '#c8c8e8'
    H = 60 + len(rows) * 70 + 150
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    d.text((X0, 8), 'Battle Command: the modules of each 128K bank (src/*/*.ann, cut as kit/mkgame.py cuts them)',
           font=font(14), fill='black')
    f11 = font(11)
    for r, (title, base, ss) in enumerate(rows):
        y = 44 + r * 70

        def x(a):
            return X0 + (a - base) * (X1 - X0) / 0x4000
        d.text((4, y + 8), title, font=font(12), fill='black')
        d.rectangle([X0, y, X1, y + 28], fill='#202020')
        for a, b, mod in ss:
            d.rectangle([x(a), y, max(x(a) + 1, x(b) - 1), y + 28], fill=colour.get(mod, '#202020'))
        # labels under the strip for wide spans, alternating two lines
        k = 0
        for a, b, mod in ss:
            if mod and x(b) - x(a) > 40:
                d.text((x(a) + 2, y + 31 + (k % 2) * 13), mod, font=f11, fill='black')
                k += 1
        for a in range(base, base + 0x4001, 0x1000):
            d.line([x(a), y + 28, x(a), y + 31], fill='black')
        d.text((X1 - 40, y - 13), f'${base + 0x3FFF:04X}', font=f11, fill='#555')
        d.text((X0, y - 13), f'${base:04X}', font=f11, fill='#555')
    ly = 44 + len(rows) * 70 + 4
    d.text((X0, ly), 'modules:', font=font(12), fill='black')
    ly += 18
    cx = X0
    for n in names:
        w = d.textlength(n, font=f11) + 26
        if cx + w > X1:
            cx, ly = X0, ly + 18
        d.rectangle([cx, ly + 1, cx + 14, ly + 13], fill=colour[n])
        d.text((cx + 18, ly), n, font=f11, fill='black')
        cx += w + 6
    im = im.crop((0, 0, W, ly + 26))
    os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True)
    im.save(sys.argv[1])


if __name__ == '__main__':
    main()

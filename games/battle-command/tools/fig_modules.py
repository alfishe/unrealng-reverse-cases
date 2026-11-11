#!/usr/bin/env python3
"""Doc 02 figure: the module map of every bank, from the source's annotations.

    python3 tools/fig_modules.py docs/img/arch/modules.png
    python3 tools/fig_modules.py stages docs/img/arch/memory-stages.png

stages: the 64 K the CPU sees at three moments of c1 side by side: the load (frame 2484, the loader running), the
title (24508) and play (32999). The ranges are the source's (src/loader/*.ann, src/game/game.ann); the thin strip
left of each column is the bytes that changed since the column before, per 256-byte row, from the bank dumps of
work/stage1/img/ (entry against title, title against play; the load column has no dump: the chain is plain only
inside the simulator, doc 3).

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


STAGES = [
    ('the load, c1 2484', 'the bank each block loads', None, [
        (0x0000, 0x4000, 'ROM', '#d8d8d8'),
        (0x4000, 0x5800, 'loading screen, bitmap', '#b0b0b0'),
        (0x5800, 0x5B00, 'attributes (from AttrBuffer)', '#909090'),
        (0x5B00, 0x5D00, 'system variables', '#c8c8c8'),
        (0x5D00, 0x7F00, 'BASIC (wiped); block 23: bank 5 XOR $AD', '#f0c080'),
        (0x7F00, 0x8000, 'stack: SP = $8000, down', '#f8e0e0'),
        (0x8000, 0x8300, 'AttrBuffer $8000 (block 15)', '#e6194b'),
        (0x8300, 0x9000, '(not used by the loader)', '#f4f4f4'),
        (0x9000, 0x9100, 'TimeBuffer $9000', '#f58231'),
        (0x9100, 0xAC38, '(not used by the loader)', '#f4f4f4'),
        (0xAC38, 0xB8F9, 'chain: 103 layers (wiped)', '#911eb4'),
        (0xB8F9, 0xBF0D, 'LoaderStart .. LoaderMain', '#4363d8'),
        (0xBF0D, 0xC000, 'stage 2, BlockTable, CountdownFont', '#3cb44b'),
        (0xC000, 0x10000, 'banks 0, 1, 3, 4, 6, 7 in turn', '#c8c8e8'),
    ]),
    ('the title, c1 24508', 'bank 6; 3 or 7 for a moment', ('entry', 'f24508', 6), None),
    ('play, c1 32999', 'bank 0', ('f24508', 'f32999', 0), None),
]
GAME = [
    (0x0000, 0x4000, 'ROM 0 (unused)', '#d8d8d8'),
    (0x4000, 0x5B00, 'screen', '#b0b0b0'),
    (0x5B00, 0x6798, 'tables: logs, sines, rows', '#9aa020'),
    (0x6798, 0x68F4, 'variables, ApiVectors', '#f58231'),
    (0x68F4, 0x72F4, 'PlayLoop, text, paging', '#e6194b'),
    (0x72F4, 0x7C59, 'panel, objects $75F0, int stack', '#46a0a0'),
    (0x7C59, 0x8000, 'small font, interrupt jobs', '#d0409a'),
    (0x8000, 0x8383, 'stack, IM 2 table, armour', '#c08080'),
    (0x8383, 0x898B, 'handler, mission load, tape', '#911eb4'),
    (0x898B, 0x96F1, 'view blits, back buffer $8AF1', '#4363d8'),
    (0x96F1, 0xAD45, '3D engine', '#3cb44b'),
    (0xAD45, 0xC000, 'world, objects, player, enemies', '#2a8a8a'),
]
SLOT = {
    6: [(0xC000, 0xD9B2, 'bank 6: menus, stores, panel jobs', '#a07ad0'),
        (0xD9B2, 0xF5E4, 'bank 6: maps, models, graphics', '#c0a0e0'),
        (0xF5E4, 0x10000, 'bank 6: font, options', '#d8c8f0')],
    0: [(0xC000, 0xDBC5, 'bank 0: play code, sound', '#9a6324'),
        (0xDBC5, 0xFB3F, 'bank 0: mission block (side 2)', '#e0a030'),
        (0xFB3F, 0x10000, 'bank 0: work rows', '#f0d8a0')],
}


def changed_rows(a, b, slot):
    """Per 256-byte row of $4000-$FFFF: the bytes that differ between two dumps of work/stage1/img."""
    img = os.path.join(ROOT, 'work', 'stage1', 'img')

    def view(tag):
        data = b''
        for bank in (5, 2, slot):
            data += open(os.path.join(img, f'{tag}-bank{bank}.bin'), 'rb').read()
        return data
    va, vb = view(a), view(b)
    return {0x4000 + r * 256: sum(x != y for x, y in zip(va[r * 256:r * 256 + 256], vb[r * 256:r * 256 + 256]))
            for r in range(len(va) // 256)}


def stages(out):
    H, Y0, Y1 = 900, 60, 850
    colw = (W - 20) // 3
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'Battle Command: the 64 K the CPU sees at three moments of c1 (ranges from the source)',
           font=font(14), fill='black')
    f11, f12 = font(11), font(12)

    def y(a):
        return Y0 + a * (Y1 - Y0) / 0x10000
    for c, (title, slot_text, diff, regions) in enumerate(STAGES):
        x0 = 10 + c * colw + 50
        x1 = x0 + 34
        d.text((x0 - 44, 30), title, font=f12, fill='black')
        d.text((x0 - 44, 44), '$C000: ' + slot_text, font=f11, fill='#444')
        if regions is None:
            regions = GAME + SLOT[diff[2]]
        last = -100
        for a, b, label, col in regions:
            d.rectangle([x0, y(a), x1, y(b) - 1], fill=col, outline='#606060')
            ly = max((y(a) + y(b)) / 2 - 6, last + 13)
            if ly > (y(a) + y(b)) / 2 - 4:
                d.line([x1, (y(a) + y(b)) / 2, x1 + 5, ly + 6], fill='#808080')
            d.text((x1 + 7, ly), label, font=f11, fill='black')
            last = ly
        for a in range(0, 0x10001, 0x4000):
            d.line([x0 - 4, y(a), x0, y(a)], fill='black')
            d.text((x0 - 44, y(a) - 6), f'${min(a, 0xFFFF):04X}', font=f11, fill='#555')
        if diff:
            rows = changed_rows(diff[0], diff[1], diff[2])
            for a, n in rows.items():
                if n:
                    v = min(255, 60 + n * 3)
                    d.rectangle([x0 - 10, y(a), x0 - 3, y(a + 256)], fill=(v, 0, 0))
    d.text((10, Y1 + 14), 'Red strip: bytes changed since the column before, per 256-byte row (the entry dump against the '
           'title,', font=f11, fill='#444')
    d.text((10, Y1 + 28), 'the title against play; brighter = more bytes). The load column is drawn from src/loader '
           '(no dump).', font=f11, fill='#444')
    im.save(out)


if __name__ == '__main__':
    if sys.argv[1] == 'stages':
        stages(sys.argv[2])
    else:
        main()

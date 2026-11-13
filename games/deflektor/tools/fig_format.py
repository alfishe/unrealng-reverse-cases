#!/usr/bin/env python3
"""Doc 07's data sheets, drawn from the image (work/mkgame/original.bin with src/res put back).

    python3 tools/fig_format.py level SLOT OUT     # a level slot byte by byte against the level drawn
    python3 tools/fig_format.py codes OUT          # the cell code space $00-$FF by kind, each code drawn

level: the 135 bytes of LevelData $B000 + $87 x SLOT as 9 rows of 15 hex bytes, each coloured by its kind, with the
row addresses; beside it the level as BuildLevel $891A and RenderGrid draw it; under it the slot's LevelSettings
$8385 pair and its counts.

codes: a 16 x 16 table of the codes $00-$FF, each cell the code drawn through CellTable (bit 7 aside) and tinted by
its kind; codes no level holds are dimmed.
"""
import sys

from PIL import Image, ImageDraw

import figlib

KINDS = [  # (test, name, colour)
    (lambda v: v == 0, 'empty', (70, 70, 80)),
    (lambda v: 1 <= v <= 0x10, 'mirror 01-10', (80, 200, 100)),
    (lambda v: 0x11 <= v <= 0x18, 'cyan polariser 11-18', (60, 200, 220)),
    (lambda v: 0x19 <= v <= 0x20, 'yellow polariser 19-20', (230, 220, 60)),
    (lambda v: 0x21 <= v <= 0x2F, 'absorbing wall 21-2F', (220, 70, 70)),
    (lambda v: 0x30 <= v <= 0x3E, 'reflecting wall 30-3E', (240, 150, 50)),
    (lambda v: v == 0x40, 'cell 40', (240, 90, 240)),
    (lambda v: v == 0x41, 'mine 41', (180, 120, 255)),
    (lambda v: v == 0x42, 'prism 42', (255, 120, 160)),
    (lambda v: 0x47 <= v <= 0x4A, 'laser 47-4A', (255, 255, 255)),
    (lambda v: 0x4B <= v <= 0x4E, 'receiver 4B-4E', (200, 200, 255)),
    (lambda v: 0x50 <= v <= 0x57, 'fibre end 50-57', (120, 160, 255)),
    (lambda v: 0x58 <= v <= 0x5C, 'explosion 58-5C (run time)', (255, 200, 120)),
]


def kind(code):
    v = code & 0x7F
    for i, (t, n, c) in enumerate(KINDS):
        if t(v):
            return i
    return None


def level(slot, out):
    img = figlib.image()
    codes = figlib.level_bytes(img, slot)
    base = 0xB000 + 0x87 * slot
    W = 1050
    o = Image.new('RGB', (W, 520), figlib.BG)
    d = ImageDraw.Draw(o)
    name = 'level %d' % (slot + 1) if slot < 60 else 'slot %d' % slot
    figlib.text(d, (10, 8), 'LevelData: %s, 135 bytes at $%04X, as BuildLevel copies them into LevelGrid $FD23'
                % (name, base), 17, figlib.ACCENT)
    cw, ch = 30, 26
    x0, y0 = 70, 60
    for c in range(15):
        figlib.text(d, (x0 + c * cw + 6, y0 - 20), '%X' % c if c < 16 else '', 12, figlib.DIM)
    for r in range(9):
        figlib.text(d, (8, y0 + r * ch + 4), '$%04X' % (base + 15 * r), 12, figlib.DIM)
        for c in range(15):
            v = codes[15 * r + c]
            k = kind(v)
            col = KINDS[k][2] if k is not None else (120, 120, 120)
            x, y = x0 + c * cw, y0 + r * ch
            if v:
                d.rectangle([x, y, x + cw - 3, y + ch - 3], fill=tuple(int(q * 0.35) for q in col), outline=col)
            figlib.text(d, (x + 4, y + 5), '%02X' % v, 13, col if v else (90, 90, 100))
            if v & 0x80:
                d.line([x + 2, y + ch - 5, x + cw - 5, y + ch - 5], fill=(255, 255, 255))
    pic, _ = figlib.play_area(img, slot)
    pic = pic.resize((512, 320), Image.NEAREST)
    o.paste(pic, (W - 512 - 12, 52))
    figlib.text(d, (W - 512 - 12, 378), 'the same slot drawn by the game (rows 1-18, columns 1-30 hold the cells)',
                12, figlib.DIM)
    rate, grem = figlib.settings(img, slot)
    k = figlib.counts(codes)
    y = 300
    figlib.text(d, (10, y), 'LevelSettings $%04X: energy rate %d, gremlins %d' % (0x8385 + 2 * slot, rate, grem),
                14, figlib.FG)
    figlib.text(d, (10, y + 22), 'cells %d, mirrors %d, turning %d, walls %d + %d, polarisers %d + %d' % (
        k['cells'], k['mirrors'], k['turning'], k['absorbing'], k['reflecting'], k['cyan'], k['yellow']), 13,
        figlib.DIM)
    figlib.text(d, (10, y + 42), 'underlined: bit 7 set, the element turns by itself', 13, figlib.DIM)
    used = sorted({kind(v) for v in codes if kind(v) is not None})
    yy = 410
    xx = 10
    for i in used:
        t, n, c = KINDS[i]
        d.rectangle([xx, yy + 2, xx + 12, yy + 14], fill=c)
        figlib.text(d, (xx + 18, yy), n, 13, figlib.FG)
        xx += 18 + 9 * len(n) + 20
        if xx > W - 200:
            xx, yy = 10, yy + 22
    o = o.crop((0, 0, W, yy + 40))
    o.save(out)


def codes(out):
    img = figlib.image()
    seen = set()
    for s in range(63):
        seen.update(figlib.level_bytes(img, s))
    W = 1050
    cs = 56
    x0, y0 = 60, 70
    o = Image.new('RGB', (W, y0 + 16 * (cs + 4) + 120), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'The cell codes $00-$FF: each drawn through CellTable $8200, tinted by kind', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 32), 'Bright: some level slot 0-62 holds the code; dim: none does. Row = high digit, column '
                '= low digit; $80-$FF are the turning forms (bit 7)', 12, figlib.DIM)
    for c in range(16):
        figlib.text(d, (x0 + c * (cs + 4) + 20, y0 - 18), '%X' % c, 12, figlib.DIM)
    for code in range(256):
        r, c = divmod(code, 16)
        x, y = x0 + c * (cs + 4), y0 + r * (cs + 4)
        if c == 0:
            figlib.text(d, (14, y + 18), '$%X0' % r, 12, figlib.DIM)
        k = kind(code)
        if k is None or (code & 0x7F) > 0x5C:
            d.rectangle([x, y, x + cs, y + cs], outline=(45, 45, 52))
            continue
        cell = figlib.cell_image(img, code & 0x7F, 3)
        if code not in seen:
            cell = Image.blend(cell, Image.new('RGB', cell.size, figlib.BG), 0.75)
        o.paste(cell, (x + 4, y + 4))
        col = KINDS[k][2] if code in seen else tuple(q // 3 for q in KINDS[k][2])
        d.rectangle([x, y, x + cs, y + cs], outline=col, width=2 if code in seen else 1)
    yy = y0 + 16 * (cs + 4) + 10
    xx = 10
    for t, n, c in KINDS[1:]:
        d.rectangle([xx, yy + 2, xx + 12, yy + 14], fill=c)
        figlib.text(d, (xx + 18, yy), n, 12, figlib.FG)
        xx += 18 + 8 * len(n) + 18
        if xx > W - 220:
            xx, yy = 10, yy + 22
    o = o.crop((0, 0, W, yy + 34))
    o.save(out)


if __name__ == '__main__':
    if sys.argv[1] == 'level':
        level(int(sys.argv[2]), sys.argv[3])
    else:
        codes(sys.argv[2])

#!/usr/bin/env python3
"""The graphics the editions changed (docs/img/diff/gfx-diff.png): the game font of Nether Earth (the '98 keeps it
byte for byte) against the '99's, and the four sprite blocks with a changed byte, NE / '98 / '99.

    python3 tools/fig_diff_gfx.py [--out PNG]

The bytes come from the three builds through tools/diff_game.py (the entries `Font` `$6780` and `Spr*Rows`).
Font: 64 glyphs of 8 x 8, codes `$20-$5F`, 16 a row; a glyph the '99 changes has a red frame, and in the '99 sheet
the pixels it adds to NE's glyph are red and the ones it
removes dark red. Sprites: rows of (mask, graphic) byte pairs, bottom line first, drawn as
DrawSprite lays them over a grey background (mask 1 + graphic 0: the background shows; else the graphic bit: ink
black, paper yellow); a byte that differs from NE's has a red frame round its 8 pixels.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import diff_game as D  # noqa: E402
from fig_common import font  # noqa: E402

BG, FG, DIM = (21, 22, 27), (230, 230, 230), (150, 154, 166)
INK, PAPER, SEE, RED = (0, 0, 0), (215, 215, 0), (110, 110, 120), (240, 60, 50)
SPRITES = [('SprCannonYmRows', 3, 'the cannon facing Y-'), ('SprElectronicsXmRows', 3, 'electronics facing X-'),
           ('SprTrenchEndYRows', 3, 'a trench end, Y'), ('SprBlockDottedRows', 4, 'the dotted block')]


def raw(case, name):
    e = case.by_name[name]
    return bytes(case.mem[a] for a in range(e['addr'], e['end'])), e['addr']


def font_sheet(data, ref, scale):
    img = Image.new('RGB', (16 * 9 * scale + scale, 4 * 9 * scale + scale), BG)
    d = ImageDraw.Draw(img)
    for g in range(64):
        gx, gy = (g % 16) * 9 * scale + scale, (g // 16) * 9 * scale + scale
        changed = data[8 * g:8 * g + 8] != ref[8 * g:8 * g + 8]
        for row in range(8):
            b, r = data[8 * g + row], ref[8 * g + row]
            for bit in range(8):
                on, was = b >> (7 - bit) & 1, r >> (7 - bit) & 1
                colour = FG if on and was else RED if on else (95, 40, 40) if was else (40, 42, 50)
                x, y = gx + bit * scale, gy + row * scale
                d.rectangle((x, y, x + scale - 1, y + scale - 1), fill=colour)
        if changed and data is not ref:
            d.rectangle((gx - 1, gy - 1, gx + 8 * scale, gy + 8 * scale), outline=RED)
    return img


def sprite(data, ref, pairs, scale):
    rows = len(data) // (2 * pairs)
    img = Image.new('RGB', (pairs * 8 * scale, rows * scale), BG)
    d = ImageDraw.Draw(img)
    for r in range(rows):
        y = (rows - 1 - r) * scale  # bottom line first
        for p in range(pairs):
            m, g = data[2 * (r * pairs + p)], data[2 * (r * pairs + p) + 1]
            for bit in range(8):
                mb, gb = m >> (7 - bit) & 1, g >> (7 - bit) & 1
                colour = SEE if mb and not gb else INK if gb else PAPER
                x = (p * 8 + bit) * scale
                d.rectangle((x, y, x + scale - 1, y + scale - 1), fill=colour)
    for i in range(len(data)):
        if data[i] != ref[i]:
            r, p = divmod(i // 2, pairs)
            y, x = (rows - 1 - r) * scale, p * 8 * scale
            d.rectangle((x, y, x + 8 * scale - 1, y + scale - 1), outline=RED, width=max(1, scale // 3))
    return img


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default=os.path.join(os.path.dirname(HERE), 'docs',
                                                  'img', 'diff', 'gfx-diff.png'))
    a = ap.parse_args()
    ne, z98, z99 = D.Case('NE'), D.Case('Z98'), D.Case('Z99')
    f_ne, f98, f99 = raw(ne, 'Font')[0], raw(z98, 'Font')[0], raw(z99, 'Font')[0]
    glyphs = sum(1 for g in range(64) if f99[8 * g:8 * g + 8] != f_ne[8 * g:8 * g + 8])
    print(f"font: '98 = NE {f98 == f_ne}; '99 differs in {sum(x != y for x, y in zip(f_ne, f99))} of 512 bytes, "
          f'{glyphs} of 64 glyphs')
    t, s = font(13), font(11)
    scale_f, scale_s = 3, 4
    fa, fb = font_sheet(f_ne, f_ne, scale_f), font_sheet(f99, f_ne, scale_f)
    sprites = []
    for name, pairs, what in SPRITES:
        r_ne = raw(ne, name)
        imgs = []
        for tag, c in (('NE', ne), ("'98", z98), ("'99", z99)):
            data, addr = raw(c, name)
            diff = [f'${addr + i:04X}' for i in range(len(data)) if data[i] != r_ne[0][i]]
            imgs.append((tag, sprite(data, r_ne[0], pairs, scale_s), diff))
            if tag != 'NE':
                print(f"{name} {tag}: {len(diff)} bytes differ from NE {' '.join(diff[:12])}"
                      f"{' ...' if len(diff) > 12 else ''}")
        sprites.append((name, what, imgs))
    pad = 16
    sw = sum(3 * im.width + 4 * pad for _, _, ims in sprites for im in [ims[0][1]]) + pad
    width = max(fa.width * 2 + 3 * pad, sw)
    sh = max(ims[0][1].height for _, _, ims in sprites)
    sheet = Image.new('RGB', (width, 40 + fa.height + 30 + 24 + 34 + sh + 30), BG)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 10), f"The game font: NE's (the '98 keeps it byte for byte) and the '99's, {glyphs} of 64 glyphs "
           'redrawn (red: pixels added to NE\'s glyph, dark red: removed)', fill=FG, font=t)
    d.text((pad, 34), "NE and '98", fill=DIM, font=s)
    sheet.paste(fa, (pad, 50))
    d.text((2 * pad + fa.width, 34), "'99", fill=DIM, font=s)
    sheet.paste(fb, (2 * pad + fa.width, 50))
    y = 50 + fa.height + 24
    d.text((pad, y), 'The sprite blocks with a changed byte: NE / \'98 / \'99, a red frame round each byte that differs '
           'from NE (grey: see-through)', fill=FG, font=t)
    x, y = pad, y + 30
    for name, what, ims in sprites:
        d.text((x, y), f'{name}: {what}', fill=DIM, font=s)
        for i, (tag, im, diff) in enumerate(ims):
            xx = x + i * (im.width + pad)
            d.text((xx, y + 16), f"{tag}" + (f': {len(diff)} B' if tag != 'NE' else ''), fill=FG, font=s)
            sheet.paste(im, (xx, y + 34))
        x += 3 * ims[0][1].width + 4 * pad
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    sheet.save(a.out)
    print('wrote', a.out)


if __name__ == '__main__':
    main()

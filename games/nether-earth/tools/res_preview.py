#!/usr/bin/env python3
"""Figures of the graphics in src/res: every sprite block on one sheet and the font, scaled, with labels.

    python3 tools/res_preview.py [--ann src/game/game.ann] [--out docs/img] [--scale 3]

docs/img/sprites-all.png: the 89 sprite blocks in address order, each labelled with its entry (from the @res lines
of the annotations), its address, its lines x bytes and its sprite id (SpriteTable index / 2). Colours as in the
PNG sources: teal see-through (mask 1), white paper (mask 0, graphic 0), black ink (graphic 1), amber ink over the
background (mask 1 and graphic 1: three bytes, in the cannon sprites). docs/img/font.png: the 64 glyphs, codes
$20-$5F, a row of 16 glyphs a line of the table.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
import kitlib  # noqa: E402
import res_formats  # noqa: E402

SPRITE_TABLE, SPRITE_IDS = 0xD6E8, 51


def resources(ann):
    """[(address, label, file)] of the @res lines that follow an entry"""
    out, last = [], None
    for line in open(ann):
        m = re.match(r'^\$([0-9A-Fa-f]{4})\s+[bwts]\s+(\w+)', line)
        if m:
            last = (int(m.group(1), 16), m.group(2))
        elif line.startswith('@res') and last:
            out.append(last + (line.split(None, 1)[1].strip(),))
    return out


def sprite_ids(image):
    """{block address: [table indices]} from SpriteTable in the original image"""
    ids = {}
    for i in range(2 * SPRITE_IDS):
        a = image[SPRITE_TABLE + 2 * i] | image[SPRITE_TABLE + 2 * i + 1] << 8
        ids.setdefault(a, []).append(i)
    return ids


def sprite_sheet(blocks, ids, scale, width=1500):
    font = kitlib.font(12)
    small = kitlib.font(11)
    pad, label_h = 10, 34
    cells = []
    for address, label, name in blocks:
        image = res_formats.sprite_to_png(res_formats.load(name), name).convert('RGB')
        image = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
        index = ids.get(address, [])
        idtext = 'id ' + ', '.join('%d%s' % (i // 2, 'o' if i & 1 else 'e') for i in index) if index else 'no id'
        lines = [label[3:], '$%04X  %dx%d  %s' % (address, image.height // scale, image.width // scale // 8, idtext)]
        w = max(image.width, max(int(font.getlength(t)) for t in lines))
        cells.append((image, lines, w))
    rows, row, x = [], [], pad
    for cell in cells:
        if row and x + cell[2] > width - pad:
            rows.append(row)
            row, x = [], pad
        row.append(cell)
        x += cell[2] + pad * 2
    rows.append(row)
    title_h = 50
    heights = [max(c[0].height for c in r) + label_h + pad for r in rows]
    sheet = Image.new('RGB', (width, title_h + sum(heights) + pad), kitlib.BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((pad, 8), 'Nether Earth: the %d sprite blocks $6980-$A569 (src/res/gfx/sprites), x%d, upright' %
              (len(blocks), scale), fill=kitlib.TEXT, font=kitlib.font(14))
    legend = [(res_formats.SPRITE_PALETTE[0], 'see-through (mask 1)'),
              (res_formats.SPRITE_PALETTE[1], 'paper (mask 0, graphic 0)'),
              (res_formats.SPRITE_PALETTE[2], 'ink (mask 0, graphic 1)'),
              (res_formats.SPRITE_PALETTE[3], 'ink over the background (mask 1, graphic 1)')]
    lx = pad
    for colour, text in legend:
        draw.rectangle((lx, 30, lx + 10, 40), fill=colour, outline=kitlib.DIM)
        draw.text((lx + 14, 28), text, fill=kitlib.DIM, font=small)
        lx += 24 + int(small.getlength(text))
    draw.text((lx + 10, 28), 'id N e / o: sprite id N, the even / odd half-byte column (SpriteTable 2N / 2N+1)',
              fill=kitlib.DIM, font=small)
    y = title_h
    for r, h in zip(rows, heights):
        x = pad
        for image, lines, w in r:
            sheet.paste(image, (x, y + h - label_h - pad - image.height))
            draw.text((x, y + h - label_h - pad + 3), lines[0], fill=kitlib.TEXT, font=font)
            draw.text((x, y + h - label_h - pad + 17), lines[1], fill=kitlib.DIM, font=small)
            x += w + pad * 2
        y += h
    return sheet


def font_sheet(data, scale):
    font = kitlib.font(12)
    left, top, gap = 44, 46, 6
    cell = 8 * scale
    count = len(data) // 8
    rows = (count + 15) // 16
    sheet = Image.new('RGB', (left + 16 * (cell + gap) + 10, top + rows * (cell + gap + 14) + 10), kitlib.BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((10, 8), 'Nether Earth: the font $6780-$697F (src/res/gfx/font.png), codes $20-$5F, x%d' % scale,
              fill=kitlib.TEXT, font=kitlib.font(14))
    for c in range(16):
        draw.text((left + c * (cell + gap) + cell // 2 - 4, top - 16), '%X' % c, fill=kitlib.DIM, font=font)
    glyph_img = res_formats.font_to_png(data).convert('RGB')
    for g in range(count):
        r, c = divmod(g, 16)
        x, y = left + c * (cell + gap), top + r * (cell + gap + 14)
        if c == 0:
            draw.text((6, y + cell // 2 - 7), '$%02X' % (0x20 + g), fill=kitlib.DIM, font=font)
        glyph = glyph_img.crop((c * 8, r * 8, c * 8 + 8, r * 8 + 8)).resize((cell, cell), Image.NEAREST)
        sheet.paste(glyph, (x, y))
        draw.rectangle((x - 1, y - 1, x + cell, y + cell), outline=kitlib.PANEL)
        draw.text((x + cell // 2 - 4, y + cell + 1), '$%02X' % (0x20 + g), fill=kitlib.DIM, font=kitlib.font(9))
    return sheet


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--ann', default=os.path.join(ROOT, 'src', 'game', 'game.ann'))
    p.add_argument('--image', default=os.path.join(ROOT, 'work', 'mkgame', 'original.bin'),
                   help='the 64 K original image (kit/mkgame.py writes it): SpriteTable for the ids')
    p.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img'))
    p.add_argument('--scale', type=int, default=3)
    args = p.parse_args()
    res = resources(args.ann)
    blocks, seen = [], set()
    for address, label, name in res:
        if name.startswith('gfx/sprites/') and name not in seen:
            seen.add(name)
            blocks.append((address, label, name))
    if not blocks:
        sys.exit(f'{args.ann}: no @res gfx/sprites/... lines')
    image = open(args.image, 'rb').read()
    os.makedirs(args.out, exist_ok=True)
    sprite_sheet(blocks, sprite_ids(image), args.scale).save(os.path.join(args.out, 'sprites-all.png'))
    font_sheet(res_formats.load('gfx/font.bin'), 4).save(os.path.join(args.out, 'font.png'))
    print(f'{len(blocks)} sprites -> {args.out}/sprites-all.png, font -> {args.out}/font.png')


if __name__ == '__main__':
    main()

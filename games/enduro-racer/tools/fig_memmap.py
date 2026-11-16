#!/usr/bin/env python3
"""The 48K memory in play as a map, 4 KB a row, each range coloured by what it holds (doc 02, 2.2).

    python3 tools/fig_memmap.py [--out docs/img/arch/memmap.png]

The ranges are the module and data entries of src/game/game.ann (their first and last address as the listing
build/game.lst gives them) grouped by kind; the names are the .ann's. No recording is read: the classes in play
come from the heatmap (docs/img/arch/heatmap-play.png) and are stated in doc 02's table.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

KINDS = {
    'screen': (120, 170, 230), 'code': (230, 90, 80), 'work': (250, 210, 90), 'table': (150, 210, 120),
    'graphics': (190, 140, 230), 'buffer': (110, 200, 200), 'stack': (240, 150, 60), 'leftover': (190, 190, 190),
    'im2': (250, 120, 200),
}
RANGES = [
    (0x4000, 0x57FF, 'screen', 'the screen'), (0x5800, 0x5AFF, 'screen', 'attrs'),
    (0x5B00, 0x5B7F, 'work', 'RowList'), (0x5B80, 0x5CFF, 'work', 'hills, lines, riders'),
    (0x5D00, 0x5DFF, 'table', 'ReverseTable'), (0x5E00, 0x5E7F, 'work', 'records, players'),
    (0x5E80, 0x642F, 'table', 'stage list, track (copy of $EB00)'),
    (0x6430, 0x643B, 'work', ''), (0x643C, 0x6587, 'code', 'Interrupt'), (0x6588, 0x690E, 'code', 'sound'),
    (0x690F, 0x6BE7, 'leftover', 'leftover'), (0x6BE8, 0x75AF, 'graphics', 'object sprites'),
    (0x75B0, 0x7607, 'table', ''), (0x7608, 0x77FF, 'graphics', 'font'),
    (0x7800, 0x7BFF, 'table', 'perspective, edges, curve'), (0x7C00, 0x7C53, 'work', 'vars'),
    (0x7C54, 0x7D7F, 'graphics', 'digits'), (0x7D80, 0x7FFF, 'table', 'hills, row scale'),
    (0x8000, 0x80B7, 'buffer', 'line buffer'), (0x80B8, 0x810B, 'code', 'Init'),
    (0x810C, 0x8E7C, 'code', 'menu, flow (texts inside)'), (0x8E7D, 0x910A, 'code', 'render'),
    (0x910B, 0x9210, 'table', 'riders, poses'), (0x9211, 0x931D, 'code', 'horizon'),
    (0x931E, 0x9614, 'code', 'road'), (0x9615, 0xA142, 'code', 'objects, road, horizon, render'),
    (0xA143, 0xB11C, 'code', 'race, bike, track, hills'), (0xB11D, 0xB1FF, 'leftover', 'old code'),
    (0xB200, 0xB300, 'im2', 'IM 2 table'), (0xB301, 0xB305, 'leftover', ''),
    (0xB306, 0xE2BF, 'graphics', 'sprites: objects, riders, trucks, bike, splash, dust'),
    (0xE2C0, 0xEAFF, 'graphics', 'horizons'),
    (0xEB00, 0xFDFF, 'buffer', 'back buffer (track tables there at load)'),
    (0xFE00, 0xFF7F, 'table', 'RowTable'), (0xFF80, 0xFFFF, 'stack', 'stack'),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'arch', 'memmap.png'))
    a = ap.parse_args()
    width, left, rowh, gap, top = 1050, 70, 46, 8, 50
    span = 0x1000
    barw = width - left - 10
    rows = 12
    im = Image.new('RGB', (width, top + rows * (rowh + gap) + 70), (255, 255, 255))
    d = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(13), kitlib.font(18), kitlib.font(12)
    d.text((8, 8), 'The 48K in play: what lives where (4 KB a row, names from game.ann)', font=fb, fill=(0, 0, 0))
    for r in range(rows):
        base = 0x4000 + r * span
        y = top + r * (rowh + gap)
        d.text((6, y + rowh // 2 - 8), '$%04X' % base, font=f, fill=(0, 0, 0))
        for lo, hi, kind, name in RANGES:
            s, e = max(lo, base), min(hi, base + span - 1)
            if s > e:
                continue
            x0 = left + (s - base) * barw // span
            x1 = left + (e + 1 - base) * barw // span - 1
            d.rectangle([x0, y, x1, y + rowh], fill=KINDS[kind], outline=(60, 60, 60))
            if name and x1 - x0 > 40:
                text = name
                while text and d.textlength(text, font=fs) > x1 - x0 - 6:
                    text = text[:-1]
                d.text((x0 + 3, y + 4), text, font=fs, fill=(0, 0, 0))
                if lo >= base and x1 - x0 > 60:
                    d.text((x0 + 3, y + 24), '$%04X' % lo, font=fs, fill=(50, 50, 50))
        for k in range(1, 4):
            x = left + k * barw // 4
            d.line([x, y + rowh, x, y + rowh + 3], fill=(0, 0, 0))
    y = top + rows * (rowh + gap) + 8
    x = 8
    for kind, col in KINDS.items():
        d.rectangle([x, y + 2, x + 14, y + 14], fill=col, outline=(60, 60, 60))
        label = {'im2': 'IM 2 table', 'work': 'variables, work'}.get(kind, kind)
        d.text((x + 20, y), label, font=f, fill=(0, 0, 0))
        x += 30 + int(d.textlength(label, font=f)) + 10
    d.text((8, y + 26), 'ticks under each row every 1 KB; a range starting in the row shows its first address',
           font=fs, fill=(60, 60, 60))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

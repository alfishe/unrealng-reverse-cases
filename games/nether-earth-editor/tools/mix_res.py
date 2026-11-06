#!/usr/bin/env python3
"""nee.mix's resources as PNG (src/res/mix) and back to the bytes the source INCBINs.

    python3 tools/mix_res.py export BINDIR          # BINDIR/mix/*.bin -> src/res/mix/*.png
    python3 tools/mix_res.py build OUTDIR           # src/res/mix/*.png -> OUTDIR/res/mix/*.bin
    python3 tools/mix_res.py check                  # every PNG built, exported, built again: the same bytes
    python3 tools/mix_res.py preview OUTDIR         # the three sheets x 3 with their numbers (docs/img/editor)

| Source | Bytes | Format |
| --- | --- | --- |
| `mix/tiles.png` | `Tiles` $C4F3, 768 | 24 tiles of 16 x 16 (2 x 2 characters), 8 a row: blocks 2-18, then the odd-row variants of 12-18 |
| `mix/building-tiles.png` | `BuildingTiles` $C7F3, 288 | 9 tiles of 16 x 16 in a row: SaveBuildings types 0-8 |
| `mix/font.png` | `Font` $C914, 768 | 96 glyphs of 8 x 8 from code $20, 16 a row |

A tile's 32 bytes are four characters, 8 bytes each, top line first: top left, top right, bottom left, bottom right
(the characters $20-$23 DrawMap prints, UDGs A-D for nee.bas). Two colours: index 0 paper, 1 ink.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'src', 'res', 'mix')
PALETTE = [(230, 230, 230), (24, 24, 32)]  # paper, ink: black on white, as the editor's map shows them
# name: (cell width, cell height in characters, cells a row, bytes)
FORMATS = {'tiles': (2, 2, 8, 768), 'building-tiles': (2, 2, 9, 288), 'font': (1, 1, 16, 768)}


def to_png(data, cw, ch, per_row):
    size = cw * ch * 8
    cells = len(data) // size
    rows = (cells + per_row - 1) // per_row
    image = Image.new('P', (per_row * cw * 8, rows * ch * 8))
    image.putpalette([v for c in PALETTE for v in c])
    px = image.load()
    for k in range(cells):
        x0, y0 = (k % per_row) * cw * 8, (k // per_row) * ch * 8
        for c in range(cw * ch):
            for line in range(8):
                byte = data[k * size + c * 8 + line]
                for bit in range(8):
                    px[x0 + (c % cw) * 8 + bit, y0 + (c // cw) * 8 + line] = 1 if byte & (0x80 >> bit) else 0
    return image


def from_png(image, cw, ch, per_row, length):
    if image.mode != 'P':
        rgb = image.convert('RGB')
        image = Image.new('P', rgb.size)
        image.putdata([PALETTE.index(p) for p in rgb.getdata()])
    px = image.load()
    size = cw * ch * 8
    out = bytearray()
    for k in range(length // size):
        x0, y0 = (k % per_row) * cw * 8, (k // per_row) * ch * 8
        for c in range(cw * ch):
            for line in range(8):
                byte = 0
                for bit in range(8):
                    if px[x0 + (c % cw) * 8 + bit, y0 + (c // cw) * 8 + line]:
                        byte |= 0x80 >> bit
                out.append(byte)
    return bytes(out)


def build(out):
    os.makedirs(os.path.join(out, 'res', 'mix'), exist_ok=True)
    for name, (cw, ch, per_row, length) in FORMATS.items():
        data = from_png(Image.open(os.path.join(SRC, name + '.png')), cw, ch, per_row, length)
        open(os.path.join(out, 'res', 'mix', name + '.bin'), 'wb').write(data)


def preview(out, scale=3):
    """Each sheet x scale, a 1-pixel grey gap between cells, the cell's number above it (block / type / code)"""
    from PIL import ImageDraw
    first = {'tiles': None, 'building-tiles': 0, 'font': 0x20}
    os.makedirs(out, exist_ok=True)
    for name, (cw, ch, per_row, length) in FORMATS.items():
        src = Image.open(os.path.join(SRC, name + '.png')).convert('RGB')
        w, h = cw * 8 * scale, ch * 8 * scale
        cells = length // (cw * ch * 8)
        rows = (cells + per_row - 1) // per_row
        label = 12
        sheet = Image.new('RGB', (per_row * (w + 4) + 4, rows * (h + label + 4) + 4), (60, 60, 70))
        draw = ImageDraw.Draw(sheet)
        for k in range(cells):
            cell = src.crop(((k % per_row) * cw * 8, (k // per_row) * ch * 8,
                             (k % per_row + 1) * cw * 8, (k // per_row + 1) * ch * 8)).resize((w, h), Image.NEAREST)
            x, y = 4 + (k % per_row) * (w + 4), 4 + (k // per_row) * (h + label + 4)
            if name == 'tiles':
                text = str(k + 2) if k < 17 else '%d odd' % (k - 17 + 12)
            elif name == 'font':
                text = '%02X' % (first['font'] + k)
            else:
                text = str(k)
            draw.text((x, y), text, fill=(240, 200, 80))
            sheet.paste(cell, (x, y + label))
        sheet.save(os.path.join(out, 'mix-' + name + '.png'))


def install(files):
    """kit/mkgame.py --install (src/mix/case.json res_install): {'mix/NAME.bin': bytes} -> src/res/mix/NAME.png"""
    os.makedirs(SRC, exist_ok=True)
    for name, (cw, ch, per_row, length) in FORMATS.items():
        data = files['mix/%s.bin' % name]
        assert len(data) == length, name
        to_png(data, cw, ch, per_row).save(os.path.join(SRC, name + '.png'))


def main():
    cmd = sys.argv[1]
    if cmd == 'export':
        install({'mix/%s.bin' % name: open(os.path.join(sys.argv[2], 'mix', name + '.bin'), 'rb').read()
                 for name in FORMATS})
    elif cmd == 'build':
        build(sys.argv[2])
    elif cmd == 'check':
        for name, (cw, ch, per_row, length) in FORMATS.items():
            data = from_png(Image.open(os.path.join(SRC, name + '.png')), cw, ch, per_row, length)
            again = from_png(to_png(data, cw, ch, per_row), cw, ch, per_row, length)
            assert data == again, name
        print('mix resources: ok')
    elif cmd == 'preview':
        preview(sys.argv[2])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The eight level-map figures, drawn from the resources: python3 tools/fig_maps.py [OUT_DIR]

Reads src/res/maps/LevelN.txt (res_formats.map_in), the glyphs of src/res/graphics/CharacterSet.png (codes 0-$9D)
and HudCharacters.png (codes $9E-$CB, the duck's cage $A8-$B5) and the inks of src/res/tables/CellAttributes.csv
(codes 9 and up take 6, as PaintCells $9538 does). Each cell is drawn as PrintChar $9C40 draws it: the glyph's eight
bytes top row first, ink on black paper. The map's row 20 is the top of the figure. Writes docs/img/maps/LevelN.png
(scale 2) by default.
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import res_formats as rf  # noqa: E402

INK = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0),
       (215, 215, 215)]
SCALE = 2


def load():
    def rd(p):
        with open(os.path.join(rf.RES, p), 'rb') as f:
            return f.read()
    glyphs = rf.png_to_sheet(rd('graphics/CharacterSet.png')) + rf.png_to_sheet(rd('graphics/HudCharacters.png'))
    attrs = {int(r[0]): int(r[1]) for r in rf.csv_rows(rd('tables/CellAttributes.csv'))}
    return rd, glyphs, attrs


def draw(cells, glyphs, attrs):
    img = Image.new('RGB', (256, 168))
    px = img.load()
    for r in range(21):
        for c in range(32):
            code = cells[r * 32 + c]
            ink = INK[attrs.get(code, 6) & 7]
            g = glyphs[code * 8:code * 8 + 8]
            for k in range(8):
                for bit in range(8):
                    if g[k] >> (7 - bit) & 1:
                        px[c * 8 + bit, (20 - r) * 8 + k] = ink
    return img.resize((256 * SCALE, 168 * SCALE), Image.NEAREST)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(rf.ROOT, 'docs', 'img', 'maps')
    os.makedirs(out, exist_ok=True)
    rd, glyphs, attrs = load()
    for n in range(1, 9):
        cells = rf.map_in(rd('maps/Level%d.txt' % n))
        path = os.path.join(out, 'Level%d.png' % n)
        draw(cells, glyphs, attrs).save(path)
        print(path)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Doc 10's rule sheet: BeamMirror $8FFB's answer for every mirror code and incoming direction.

    python3 tools/fig_logic.py mirror OUT

The new direction is (16 - direction + code - 1 + 8) AND 15 (the listing's BeamMirror). The answer equal to the
reverse of the incoming direction sends the beam back along itself: BeamVertex $906E sees the reversal and calls
BeamBackToLaser (OVERLOAD). Each mirror code is drawn through CellTable as the game draws it.
"""
import sys

from PIL import Image, ImageDraw

import figlib

ARROW = {0: (1, 0), 4: (0, 1), 8: (-1, 0), 12: (0, -1)}


def mirror(out):
    img = figlib.image()
    W = 1050
    cw, ch = 56, 34
    x0, y0 = 120, 120
    o = Image.new('RGB', (W, y0 + 16 * ch + 70), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'BeamMirror $8FFB: the direction out of a mirror, for each code and incoming direction', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 32), 'out = (16 - in + code - 1 + 8) AND 15. Directions 0-15 clockwise from east (4 south, 8 '
                'west, 12 north). Red: out = in + 8, the beam goes back: OVERLOAD', 12, figlib.DIM)
    for k in range(16):
        code = k + 1
        x = x0 + k * cw
        o.paste(figlib.cell_image(img, code, 2), (x + 12, 52))
        figlib.text(d, (x + 14, 88), '$%02X' % code, 12, figlib.FG)
    figlib.text(d, (10, 92), 'in \\ code', 12, figlib.DIM)
    for din in range(16):
        y = y0 + din * ch
        figlib.text(d, (20, y + 9), 'in %2d' % din, 13, figlib.FG)
        for k in range(16):
            out_dir = (16 - din + k + 8) & 15
            x = x0 + k * cw
            back = out_dir == (din + 8) & 15
            fill = (150, 40, 40) if back else (36, 36, 46)
            d.rectangle([x + 2, y + 2, x + cw - 3, y + ch - 3], fill=fill)
            figlib.text(d, (x + 18, y + 9), '%2d' % out_dir, 13, figlib.FG)
    figlib.text(d, (10, y0 + 16 * ch + 12), 'Each column: one of the 16 mirror codes, drawn by the game; each row an '
                'incoming direction. Only the odd codes have red cells: two beams hit them square on.', 12,
                figlib.DIM)
    figlib.text(d, (10, y0 + 16 * ch + 32), 'Example (L01 frame 1514): in 8 (west) on $0F gives 14; in 14 on $08 gives '
                '1; in 1 on $02 gives 8, and the beam runs west into the receiver.', 12, figlib.DIM)
    o.save(out)


if __name__ == '__main__':
    {'mirror': mirror}[sys.argv[1]](sys.argv[2])

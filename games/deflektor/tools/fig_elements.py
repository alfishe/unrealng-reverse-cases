#!/usr/bin/env python3
"""Every element of a level as the game draws it: each cell code through CellTable $8200 (four characters a code),
CellGraphics $D700 and CellColours $DF00 (tools/figlib.cell_image), one row a kind, with its codes and its rule.

    python3 tools/fig_elements.py docs/img/design/elements.png [--scale 2]
"""
import argparse
import os

from PIL import Image, ImageDraw

import figlib

KINDS = [
    ('$00 empty', 'the beam crosses it', [0x00]),
    ('$01-$10 mirror, 16 angles', 'reflects; the player turns it (fire + left / right)', list(range(0x01, 0x11))),
    ('$11-$18 cyan polariser', 'passes a beam along its axis, absorbs it across', list(range(0x11, 0x19))),
    ('$19-$20 yellow polariser', 'passes a beam along its axis, reflects it across', list(range(0x19, 0x21))),
    ('$21-$2F absorbing wall', 'stops the beam; fills some of its four quarters',
     list(range(0x21, 0x30))),
    ('$30-$3E reflecting wall', 'the same shapes; reflects the beam', list(range(0x30, 0x3F))),
    ('$40 cell, $41 mine, $42 prism', 'burns / overloads the laser / scatters the beam', [0x40, 0x41, 0x42]),
    ('$47-$4A laser E S W N', 'the beam starts in front of it', [0x47, 0x48, 0x49, 0x4A]),
    ('$4B-$4E receiver E S W N', 'the beam into its open side ends the level', [0x4B, 0x4C, 0x4D, 0x4E]),
    ('$50-$57 fibre-optic ends', 'pairs $50/$51 ... $56/$57: in at one, out of the other', list(range(0x50, 0x58))),
    ('$58-$5C explosion', 'a burning cell, one frame a pass, then empty', list(range(0x58, 0x5D))),
    ('$43-$46: no level holds them', 'CellTable draws them as cyan lasers; never read', [0x43, 0x44, 0x45, 0x46]),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=2)
    a = ap.parse_args()
    img = figlib.image()
    s = a.scale
    cw = 16 * s + 2
    lw = 1050 - 16 * cw - 20
    rh = 16 * s + 22
    top = 40
    out = Image.new('RGB', (1050, top + len(KINDS) * rh + 50), figlib.BG)
    d = ImageDraw.Draw(out)
    figlib.text(d, (10, 8), 'The elements: each cell code drawn from CellTable $8200, CellGraphics $D700, CellColours $DF00',
                17, figlib.ACCENT)
    for i, (name, rule, codes) in enumerate(KINDS):
        y = top + i * rh
        figlib.text(d, (10, y + 2), name, 14, figlib.FG)
        figlib.text(d, (10, y + 20), rule, 12, figlib.DIM)
        for j, c in enumerate(codes):
            x = 10 + lw + j * cw
            out.paste(figlib.cell_image(img, c, s), (x, y + 2))
            figlib.text(d, (x, y + 16 * s + 4), f'{c:02X}', 11, figlib.DIM)
    figlib.text(d, (10, top + len(KINDS) * rh + 8),
                'Bit 7 of a code (lower case in levels.txt): the element turns by itself, one step a pass. '
                'Below each picture: the code in hex.', 12, figlib.DIM)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    out.save(a.out)
    print(a.out, out.size)


if __name__ == '__main__':
    main()

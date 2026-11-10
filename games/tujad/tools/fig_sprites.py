#!/usr/bin/env python3
"""Doc 02: a first sprite sheet. The sprites are the ones the main loop put in the interrupt's sprite list
(`$FF01` on, 8 bytes an entry: the graphic, the address of a collision flag, the width in bytes, the height in
character rows, the screen address; drawn with XOR by the handler at `$95DB-$963F`), collected from the lists left
in memory in every saved state (work/stage1/sprites-found.json). The graphic is width x height x 8 bytes, row by
row. A graphic in the image (`$9CB8` on) is drawn from the image as loaded; one in RAM the game fills at run time
(`$65DD`, `$668C`, `$6708-$6887`: pre-shifted copies) is drawn from the state named on it.

    python3 tools/fig_sprites.py work/mkgame/original.bin work/stage1/sprites-found.json STATE.szx docs/img/sprites/sprites.png
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import szx  # noqa: E402

BG, INK, PAPER, TEXT = (24, 24, 30), (235, 235, 235), (0, 0, 0), (200, 200, 120)


def font(size):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    image = open(sys.argv[1], 'rb').read()
    found = json.load(open(sys.argv[2]))
    state_path = sys.argv[3]
    state, _ = szx.read(state_path)
    out = sys.argv[4]
    scale, pad, cols = 3, 14, 6
    f = font(15)
    cells = []
    for ptr, w, h, _flags in found:
        if ptr == 0x668C and w == 2:
            continue  # the same buffer as the 3-byte-wide entry, drawn narrower
        mem, src = (image, 'image') if ptr >= 0x9000 else (state, 'RAM')
        rows = h * 8
        im = Image.new('RGB', (w * 8, rows), PAPER)
        px = im.load()
        for y in range(rows):
            for x in range(w):
                b = mem[ptr + y * w + x]
                for bit in range(8):
                    if b & (0x80 >> bit):
                        px[x * 8 + bit, y] = INK
        cells.append((im.resize((w * 8 * scale, rows * scale), Image.NEAREST),
                      f'${ptr:04X} {w}x{h}', src))
    cw = max(c[0].width for c in cells) + 2 * pad
    ch = max(c[0].height for c in cells) + 2 * pad + 40
    W, H = cw * cols, ch * ((len(cells) + cols - 1) // cols) + 60
    sheet = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 8), 'The interrupt\'s sprite list: graphic address, width in bytes x rows of 8',
           fill=TEXT, font=f)
    d.text((pad, 28), f'image: as loaded; RAM: from {os.path.basename(state_path)} (the RZX after 43 000 frames)',
           fill=TEXT, font=f)
    for i, (im, label, src) in enumerate(cells):
        x, y = (i % cols) * cw + pad, (i // cols) * ch + 60
        sheet.paste(im, (x, y))
        d.text((x, y + im.height + 6), label, fill=INK, font=f)
        d.text((x, y + im.height + 22), src, fill=(150, 150, 160), font=f)
    sheet.save(out)
    print(out, sheet.size, len(cells))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The editor tape as a picture: every data block at ROM speed (with the TZX pauses), coloured by part.

    python3 tools/fig_tape.py [OUT.png]          # default docs/img/tape-blocks.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
from tapblocks import rom_seconds  # noqa: E402


def tzx(path):
    """(text above, pause ms, flag, data) for each $10 block, texts carried to the next block"""
    d = open(path, 'rb').read()
    i, text, out = 10, '', []
    while i < len(d):
        t = d[i]
        i += 1
        if t == 0x30:
            text = d[i + 1:i + 1 + d[i]].decode('latin-1')
            i += 1 + d[i]
        elif t == 0x10:
            pause, n = d[i] | d[i + 1] << 8, d[i + 2] | d[i + 3] << 8
            body = d[i + 4:i + 4 + n]
            out.append((text, pause, body[0], body[1:-1], body[-1]))
            text = ''
            i += 4 + n
        else:
            raise SystemExit(f'block ${t:02X}')
    return out


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'docs', 'img', 'tape-blocks.png')
    blocks = tzx(os.path.join(CASE, 'orig', 'NETHER.TZX'))
    parts = [(0, 6, 'the game edition: BASIC + 4 headerless blocks (a snapshot of the menu)', (90, 160, 230)),
             (6, 20, 'seven levels: saved games, 2 + 9425 bytes each, flag $00', (235, 170, 60)),
             (20, 26, 'the editor: BASIC "NE Editor", "nee.mix", "nee.bas"', (120, 200, 120)),
             (26, 28, 'the editor\'s saved game', (235, 120, 90))]
    times, t = [], 0.0
    for text, pause, flag, data, cs in blocks:
        s = rom_seconds(flag, data, cs)
        times.append((t, s))
        t += s + pause / 1000
    W, L, scale = 1500, 20, (1500 - 40) / t
    im = Image.new('RGB', (W, 264), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, tiny = K.font(14), K.font(11)
    d.text((L, 8), f'orig/NETHER.TZX: 28 standard blocks, {t:.0f} s at ROM speed with the pauses '
           f'({round(t * 50)} frames)', fill=K.TEXT, font=f)
    y, nlabel = 54, 0
    for k, (start, s) in enumerate(times):
        colour = next(c for a, b, _, c in parts if a <= k < b)
        x0, x1 = L + start * scale, L + (start + s) * scale
        header = blocks[k][2] == 0 and len(blocks[k][3]) == 17
        d.rectangle([x0, y + (12 if header else 0), max(x1, x0 + 1), y + 40], fill=colour, outline=(0, 0, 0))
        if s > 20:
            d.text((x0 + 3, y + 44), f'{k}: {len(blocks[k][3])}', fill=K.DIM, font=tiny)
        if blocks[k][0]:
            d.text((x0, y - 13 - 13 * (nlabel % 2)), blocks[k][0][:40], fill=K.DIM, font=tiny)
            nlabel += 1
    for m in range(0, int(t) + 1, 60):
        d.line([L + m * scale, y + 60, L + m * scale, y + 66], fill=K.DIM)
        d.text((L + m * scale + 2, y + 66), f'{m // 60} min', fill=K.DIM, font=tiny)
    yy = 154
    for a, b, label, colour in parts:
        d.rectangle([L, yy + 3, L + 12, yy + 13], fill=colour)
        d.text((L + 18, yy), f'blocks {a}-{b - 1}: {label}', fill=K.TEXT, font=tiny)
        yy += 18
    d.text((L, yy + 6), 'block numbers count the data blocks only (the TAP numbering, the TZX text blocks not '
           'counted); low bars are 17-byte headers; the label over a block is the TZX text before it',
           fill=K.DIM, font=tiny)
    d.text((L, yy + 22), 'python3 tools/fig_tape.py', fill=K.DIM, font=tiny)
    im.save(out_path)
    print(out_path, f'{t:.1f} s')


if __name__ == '__main__':
    main()

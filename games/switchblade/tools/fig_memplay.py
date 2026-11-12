#!/usr/bin/env python3
"""The memory at the load against the memory in play, side by side: $5B00-$FFFF, 256 bytes a row. Left: the image after
the bootstrap's copies, as the sources build it (build/game.bin, `$5C00-$FFFF`; a file shorter than 64 K ends at
`$FFFF`; Im2Table is filled at run time), each byte grey by its value (black for 0). Right: c1's state in play (work/stage1/c1/end.szx, frame 18 627, room 4), grey where the byte is
unchanged, orange where play has written another value. The regions of doc 2.3 are labelled at the right.

    python3 tools/fig_memplay.py build/game.bin work/stage1/c1/end.szx docs/img/arch/memory-load-play.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for d in os.listdir(os.path.join(V, 'lib')):
    sys.path.insert(0, os.path.join(V, 'lib', d, 'site-packages'))
from skoolkit.snapshot import Snapshot  # noqa: E402

REGIONS = [  # doc 2.3: (first, last, at the load, in play)
    (0x5B00, 0x5BFF, '', 'RoomObjectList, ColumnValues, the stack'),
    (0x5C00, 0x5D06, 'setup', 'the same'),
    (0x5D07, 0x65FF, 'Intro48, its texts, menu code', 'nine actor pages'),
    (0x6600, 0x66FF, 'menu code, intro glyphs', 'weapon page, globals'),
    (0x6700, 0x6CFF, 'menu code, ControlMenu', 'the six cell planes'),
    (0x6D00, 0x6EFF, 'vars templates', 'kept room states'),
    (0x6F00, 0x7047, 'templates', 'OutlineMask, RowBase'),
    (0x7048, 0x7BE4, 'rooms, tables', 'the same'),
    (0x7BE5, 0xA927, 'code, font, strings', 'the same'),
    (0xA928, 0xD0F8, 'the room records', 'the same'),
    (0xD104, 0xFD97, 'tiles, sprites, pictures', 'the same'),
    (0xFDFD, 0xFF00, 'zeros', 'Im2Jump, Im2Table (SetVectors)'),
    (0xFF01, 0xFFFE, 'the panel code', 'the same'),
]


def main():
    load = open(sys.argv[1], 'rb').read()
    load = bytes(0x10000 - len(load)) + load
    snap = Snapshot.get(sys.argv[2])
    ram = bytes(snap.ram(-1))
    if len(ram) > 0xC000:     # 128K: all eight banks; $4000 = bank 5, $8000 = bank 2, $C000 = the paged bank
        bank = lambda n: ram[n * 0x4000:(n + 1) * 0x4000]  # noqa: E731
        play = bytes(0x4000) + bank(5) + bank(2) + bank(snap.out7ffd & 7)
    else:
        play = bytes(0x4000) + ram
    out = sys.argv[3]
    lo, rows, rh, cw = 0x5B00, (0x10000 - 0x5B00) // 256, 4, 256
    top, gap, lab = 40, 24, 560
    W = 60 + cw * 2 + gap + lab
    im = Image.new('RGB', (W, top + rows * rh + 40), (16, 16, 20))
    px = im.load()
    d = ImageDraw.Draw(im)
    f12, f14 = K.font(12), K.font(14)
    x0, x1 = 60, 60 + cw + gap
    changed = 0
    for r in range(rows):
        for c in range(256):
            a = lo + r * 256 + c
            v = load[a]
            g = 40 + v * 200 // 255 if v else 0
            p = play[a]
            if p == v:
                q = (g, g, g)
            else:
                q = (255, 140 + p * 100 // 255 // 2, 30)
                changed += 1
            for y in range(rh):
                px[x0 + c, top + r * rh + y] = (g, g, g)
                px[x1 + c, top + r * rh + y] = q
        if r % 16 == 0:
            d.text((4, top + r * rh - 6), f'${lo + r * 256:04X}', fill=(200, 200, 200), font=f12)
    d.text((8, 6), f'The memory at the load (left) and in play (right, orange: {changed} bytes changed), '
                   '$5B00-$FFFF, 256 bytes a row', fill='white', font=f14)
    d.text((x0, top - 16), 'at the load (build/game.bin)', fill=(200, 200, 200), font=f12)
    d.text((x1, top - 16), 'c1 in play, frame 18627', fill=(200, 200, 200), font=f12)
    xl = x1 + cw + 10
    want = []
    for a, b, at_load, in_play in REGIONS:
        y0, y1 = top + (a - lo) // 256 * rh, top + ((b - lo) // 256 + 1) * rh - 1
        d.line([(xl, y0), (xl + 4, y0), (xl + 4, y1), (xl, y1)], fill=(230, 210, 120))
        if in_play == 'the same':
            text = f'{at_load} (the same)'
        elif not at_load:
            text = in_play
        else:
            text = f'{at_load} -> {in_play}'
        want.append([(y0 + y1) // 2, f'${a:04X}-${b:04X} {text}'])
    y = 0
    for w in want:          # spread the labels 15 px apart, keep each joined to its bracket
        ly = max(w[0] - 7, y)
        d.line([(xl + 5, w[0]), (xl + 30, ly + 7)], fill=(150, 140, 90))
        d.text((xl + 34, ly), w[1], fill=(230, 210, 120), font=f12)
        y = ly + 15
    im.save(out)
    print(out, im.size, 'changed', changed)


if __name__ == '__main__':
    main()

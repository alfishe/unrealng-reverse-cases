#!/usr/bin/env python3
"""The first map of the Undercity: the room grid from the image's own tables, each room drawn as the RZX run last
saw it (tools/rzx_trace.py), then the rooms of further folders (the rooms recording's screens, outlined in green), the
rooms no recording entered left as numbered grey cells.

The tables (`$95F9`): for map row R (0-19) `$70C7+R` holds how many rooms the row has and `$70DB+R` where its
columns start in the list at `$7048`; the room number is the index in that list plus one (`$6BDD`). Hiro's map row
and column are `$69DF` and `$69E0`.

    python3 tools/fig_map.py work/mkgame/original.bin work/stage1/rzxtrace docs/img/maps/map-rzx.png [MORE_DIR ...]
"""
import os
import sys

from PIL import Image, ImageDraw

CW, CH = 64, 44          # a room: the play area (pixel rows 8-183) at a quarter
ROWS, COLS = 20, 30


def rooms(img):
    out = {}
    for r in range(ROWS):
        cnt, start = img[0x70C7 + r], img[0x70DB + r]
        for i in range(cnt):
            out[start + i + 1] = (r, img[0x7048 + start + i])
    return out


def main():
    img = open(sys.argv[1], 'rb').read()
    shots, out, more = os.path.join(sys.argv[2], 'rooms'), sys.argv[3], [os.path.join(d, 'rooms') for d in sys.argv[4:]]
    grid = rooms(img)
    pad = 18
    im = Image.new('RGB', (COLS * CW + pad, ROWS * CH + pad), (24, 24, 24))
    d = ImageDraw.Draw(im)
    for c in range(COLS):
        d.text((pad + c * CW + 26, 3), str(c), fill=(200, 200, 200))
    for r in range(ROWS):
        d.text((2, pad + r * CH + 16), str(r), fill=(200, 200, 200))
    for room, (r, c) in grid.items():
        x, y = pad + c * CW, pad + r * CH
        p = os.path.join(shots, f'{room:03d}.png')
        edge = (0, 140, 255)
        if not os.path.exists(p) or room == 2:
            for m in more:
                if os.path.exists(os.path.join(m, f'{room:03d}.png')):
                    p, edge = os.path.join(m, f'{room:03d}.png'), (0, 220, 0)
        if os.path.exists(p) and (room != 2 or edge != (0, 140, 255)):
            s = Image.open(p).crop((0, 8, 256, 184)).resize((CW, CH), Image.LANCZOS)
            im.paste(s, (x, y))
            fg = (255, 255, 0)
        else:
            d.rectangle((x, y, x + CW - 1, y + CH - 1), fill=(90, 90, 90))
            fg = (255, 255, 255)
        d.rectangle((x, y, x + CW - 1, y + CH - 1), outline=edge)
        d.rectangle((x + 1, y + 1, x + 22, y + 11), fill=(0, 0, 0))
        d.text((x + 2, y + 1), str(room), fill=fg)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out)
    print(len(grid), 'rooms')


if __name__ == '__main__':
    main()

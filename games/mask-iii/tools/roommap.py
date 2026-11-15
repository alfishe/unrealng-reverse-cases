#!/usr/bin/env python3
"""Draw MASK III's rooms from the game's data (stage 1, a first map).

    python3 tools/roommap.py MEM64K.bin ROOM SCREEN OUT.png      # one screen of a room
    python3 tools/roommap.py --map DUMP_DIR FIRST LAST OUT.png  # rooms FIRST-LAST, 6 screens each (a strip), from an RZX dump

The data (WALKTHROUGH 6.3): the room table at `$953B`, 12 bytes a room (exits left, right, and the third
exit taken at `$B6B3`; byte 4 the zone); the room maps at `$7600 + 240 * room`, 48 blocks across and 5 down, six
screens of 8 blocks side by side (`$950D` = 8 * the screen, the map column of the screen's left edge); a block is 16 bytes at `$8500 + 16 * block`, 4 x 4 characters; the live zone's 256 characters at `$E000`
(8 bytes each) and their attributes at `$EF00` (`$A198` swaps a zone's `$900` bytes in from `$5B00`, `$6400` or
`$6D00`). The screen shows the lower 18 of the 20 character rows drawn. The map bytes come from the given memory, so a room's pick-ups show as the game has them then.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import zxscreen  # noqa: E402
import kitlib  # noqa: E402


def colour(ink_or_paper, bright):
    return zxscreen.palette(ink_or_paper, bright)


def draw_screen(mem, room, screen, scale=1):
    im = Image.new('RGB', (256, 160))
    px = im.load()
    base = 0x7600 + 240 * room + 8 * screen
    for by in range(5):
        for bx in range(8):
            blk = mem[base + by * 48 + bx]
            for cy in range(4):
                for cx in range(4):
                    ch = mem[0x8500 + 16 * blk + cy * 4 + cx]
                    attr = mem[0xEF00 + ch]
                    br = bool(attr & 0x40)
                    ink, paper = colour(attr & 7, br), colour((attr >> 3) & 7, br)
                    for y in range(8):
                        b = mem[0xE000 + 8 * ch + y]
                        for x in range(8):
                            px[(bx * 4 + cx) * 8 + x, (by * 4 + cy) * 8 + y] = ink if b & (0x80 >> x) else paper
    im = im.crop((0, 16, 256, 160))  # the screen shows character rows 2-19 (RZX frame 4000 against this drawing)
    return im.resize((256 * scale, 144 * scale), Image.NEAREST) if scale != 1 else im


def main():
    if sys.argv[1] == '--map':
        dump, first, last, out = sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
        idx = json.load(open(os.path.join(dump, 'index.json')))
        raw = open(os.path.join(dump, 'mem.bin'), 'rb').read()
        mems = [raw[i * 65536:(i + 1) * 65536] for i in range(len(idx['mem_frames']))]
        pick = {}
        for f, m in zip(idx['mem_frames'], mems):
            if f and m[0x950B] and m[0x950A] not in pick:
                pick[m[0x950A]] = (f, m)
        rooms = [r for r in sorted(pick) if first <= r <= last]
        big, small = kitlib.font(30), kitlib.font(26)
        cw, ch = 6 * 256 + 16, 144 + 56
        sheet = Image.new('RGB', (cw, len(rooms) * ch), (24, 24, 30))
        d = ImageDraw.Draw(sheet)
        for i, r in enumerate(rooms):
            f, m = pick[r]
            x0, y0 = 8, i * ch + 46
            rec = m[0x953B + 12 * r:0x953B + 12 * r + 12]
            ex = ' '.join('--' if e == 0xFF else f'{e:02d}' for e in rec[:3])
            d.text((x0, y0 - 40), f'room {r}: map ${0x7600 + 240 * r:04X}, record ${0x953B + 12 * r:04X}, zone {rec[4]}', fill=(230, 230, 230), font=big)
            d.text((x0 + 900, y0 - 38), f'exits left/right/third: {ex}', fill=(190, 190, 190), font=small)
            for s in range(6):
                sheet.paste(draw_screen(m, r, s), (x0 + s * 256, y0))
        sheet.save(out)
        print(out, sheet.size, 'rooms', rooms, 'RZX frames', [pick[r][0] for r in rooms])
        return
    mem = open(sys.argv[1], 'rb').read()
    draw_screen(mem, int(sys.argv[2]), int(sys.argv[3]), 2).save(sys.argv[4])


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Every room the recordings reach, one screen each, from the RZX segment recordings (work/stage1/rzx/rNNNNN, each
replayed from tools/rzx_dump.py's snap-NNNNN.z80). The room at each 250-frame sample comes from the RZX run's
system-variable dump (vars.bin, room `$5C01`); the picture is our recording's screen at that frame
(rNNNNN/screens/KKKKKK.scr), kept only where it matches the RZX's own screen (under 3 % of the bitmap bytes differ).

    python3 tools/fig_rooms_reached.py work/stage1/rzx docs/img/play/rooms-reached-1.png docs/img/play/rooms-reached-2.png
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402


def main():
    d, outs = sys.argv[1], sys.argv[2:]
    rzx_scr = open(os.path.join(d, 'screens.bin'), 'rb').read()
    var = open(os.path.join(d, 'vars.bin'), 'rb').read()
    segs = sorted(int(n[1:]) for n in os.listdir(d) if n.startswith('r') and n[1:].isdigit())
    first = {}
    for i in range(1, len(var) // 512):
        f, room = i * 250, var[i * 512 + 0x101]
        if room in first or var[i * 512 + 0x97] == 0:   # lives 0: not in play
            continue
        for a in sorted((s for s in segs if s < f), reverse=True):
            p = os.path.join(d, f'r{a:05d}', 'screens', f'{f - a:06d}.scr')
            if not os.path.exists(p):
                continue
            ours = open(p, 'rb').read()[:6912]
            ref = rzx_scr[i * 6912:i * 6912 + 6144]
            if sum(x != y for x, y in zip(ours[:6144], ref)) < 0.03 * 6144:
                first[room] = (f, a, ours)
                break
    rooms = sorted(first)
    print(len(rooms), 'rooms:', ' '.join(f'{r:02X}' for r in rooms))
    half = (len(rooms) + 1) // 2
    for out, part in zip(outs, (rooms[:half], rooms[half:])):
        cols, w, h, lab = 6, 256, 192, 26
        o = Image.new('RGB', (cols * (w + 6), 40 + ((len(part) + cols - 1) // cols) * (h + lab + 6)), (24, 24, 28))
        dr = ImageDraw.Draw(o)
        dr.text((4, 6), 'Rooms reached: room (hex), recording and its frame (RZX frame = start + frame)', font=K.font(22),
                fill=(235, 235, 235))
        for k, r in enumerate(part):
            f, a, scr = first[r]
            x, y = (k % cols) * (w + 6), 40 + (k // cols) * (h + lab + 6)
            o.paste(zxscreen.render(scr, 1), (x, y + lab))
            dr.text((x + 2, y + 2), f'{r:02X}  rzx{a:05d} @{f - a}', font=K.font(18), fill=(255, 220, 90))
        o.save(out)


if __name__ == '__main__':
    main()

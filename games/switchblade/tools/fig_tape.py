#!/usr/bin/env python3
"""The tape as a picture: the TZX blocks along the tape's time at ROM speed (each block with its pause after it),
and below, where each block lands in memory, with the c1 frame at which its loader was called.

    python3 tools/fig_tape.py work/stage1/media/switchblade.tzx docs/img/load/tape.png
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import tzxblocks as T  # noqa: E402

# block -> (what, loaded by, [(machine, lo, hi, label)], c1 frame of the load's start)
DEST = {
    1: ('header "( Switch )"', 'ROM', [], 'ROM LOAD'),
    2: ('BASIC + loader code', 'ROM', [('64K', 0x5CCB, 0x5E34, 'PROG')], 'ROM LOAD'),
    3: ('stage 2', 'LoadBytes $FF02', [('64K', 0x609C, 0x68A8, 'stage 2')], 'c1 713'),
    4: ('the game', 'LoadBytes', [('64K', 0x6B5C, 0xFDFD, 'game $6B5C-$FDFC')], 'c1 1345'),
    5: ('bootstrap + copies', 'LoadBytes', [('64K', 0x4000, 0x5191, 'bootstrap in the screen')], 'ends before c1 13070'),
    6: ('bank 4 (128K only)', 'LoadBytes via swap', [('bank4', 0xC000, 0xE0F9, 'bank 4')], 'after the paging test at c1 13070'),
}
COL = {1: (150, 150, 150), 2: (120, 170, 230), 3: (230, 180, 60), 4: (90, 190, 110), 5: (220, 90, 90),
       6: (190, 110, 220)}


def main():
    src, out = sys.argv[1], sys.argv[2]
    blocks = [b for b in T.parse(open(src, 'rb').read()) if b['kind'] == 'standard']
    W, H = 1050, 470
    img = Image.new('RGB', (W, H), (16, 16, 20))
    d = ImageDraw.Draw(img)
    f, fs, fb = K.font(12), K.font(11), K.font(14)
    d.text((10, 6), 'The tape: one ROM header, five headerless blocks at ROM speed, 336 s; where each block goes',
           fill='white', font=fb)
    # time lane
    x0, x1, ty = 20, W - 20, 60
    total = sum(T.seconds(b) + b['pause'] / 1000 for b in blocks)
    sx = (x1 - x0) / total
    t = 0.0
    centres = {}
    for b in blocks:
        n = b['index']
        dur = T.seconds(b)
        a, z = x0 + t * sx, x0 + (t + dur) * sx
        d.rectangle([a, ty, max(a + 2, z), ty + 30], fill=COL[n])
        centres[n] = ((a + z) / 2, ty + 30)
        lab = f'{n}'
        d.text((a + 2, ty + 8), lab, fill='black', font=f)
        t += dur + b['pause'] / 1000
    for s in range(0, int(total) + 1, 30):
        x = x0 + s * sx
        d.line([x, ty + 32, x, ty + 37], fill=(150, 150, 150))
        d.text((x - 8, ty + 38), f'{s}s', fill=(150, 150, 150), font=fs)
    d.text((x0, ty - 18), 'tape time at ROM speed (data and pauses); the gaps are the pauses after each block',
           fill=(200, 200, 200), font=f)
    # table of blocks (drawn under the memory lane)
    yy = ty + 62 + 120
    for b in blocks:
        n = b['index']
        what, by, dest, frm = DEST[n]
        ln = len(b['data']) - 2
        d.rectangle([x0, yy + 2, x0 + 10, yy + 12], fill=COL[n])
        d.text((x0 + 16, yy), f'block {n}: {ln} bytes, {T.seconds(b):.2f} s + pause {b["pause"]} ms; {what}; '
                              f'read by {by}; {frm}', fill='white', font=f)
        yy += 18
    # memory lane
    my = ty + 110
    mx0, mx1 = 20, 760
    msx = (mx1 - mx0) / 0x10000
    d.text((mx0, my - 18), 'the 64 K view (banks 5, 2, 0) as the load leaves it', fill=(200, 200, 200), font=f)
    d.rectangle([mx0, my, mx1, my + 40], outline=(120, 120, 120))
    d.rectangle([mx0, my, mx0 + 0x4000 * msx, my + 40], fill=(50, 50, 60))
    d.text((mx0 + 4, my + 12), 'ROM', fill=(200, 200, 200), font=f)
    for k in range(0, 0x10001, 0x2000):
        x = mx0 + k * msx
        d.line([x, my + 40, x, my + 45], fill=(150, 150, 150))
        d.text((x - 14, my + 46), f'${min(k, 0xFFFF):04X}', fill=(150, 150, 150), font=fs)
    bx0, bx1 = 800, 1030
    bsx = (bx1 - bx0) / 0x4000
    d.text((bx0, my - 18), 'bank 4 at $C000 (128K)', fill=(200, 200, 200), font=f)
    d.rectangle([bx0, my, bx1, my + 40], outline=(120, 120, 120))
    d.text((bx0 - 2, my + 46), '$C000', fill=(150, 150, 150), font=fs)
    d.text((bx1 - 30, my + 46), '$FFFF', fill=(150, 150, 150), font=fs)
    for b in blocks:
        n = b['index']
        for mach, lo, hi, lab in DEST[n][2]:
            if mach == '64K':
                a, z = mx0 + lo * msx, mx0 + hi * msx
            else:
                a, z = bx0 + (lo - 0xC000) * bsx, bx0 + (hi - 0xC000) * bsx
            d.rectangle([a, my + 2, z, my + 38], fill=COL[n])
            cx, cy = centres[n]
            d.line([cx, cy, (a + z) / 2, my], fill=COL[n], width=1)
    # the copies the bootstrap makes
    cy = yy + 10
    notes = [
        'Block 5 lands at $4000 (the screen): the bootstrap (326 bytes) runs there; it copies its second part to $5C00-$6B4C',
        '(3917 bytes, over the system variables and the BASIC) and its third to $FF01-$FFFE (254 bytes, over the loader).',
        'Block 6 is read only on a 128K: stage 2 swaps $8000-$A0F8 with bank 4, loads the block at $8000, swaps back.',
        'Block 2 holds the BASIC line 0 and 253 bytes of machine code after it, copied to $FF00 (the loader LoadBytes).',
        'c1 frames: frames from power-on of the 128K c1 recording (Tape Loader at frame 200, signal speed).',
    ]
    for i, s in enumerate(notes):
        d.text((mx0, cy + 16 * i), s, fill=(200, 200, 200), font=f)
    img.save(out)
    print(out, img.size)


if __name__ == '__main__':
    main()

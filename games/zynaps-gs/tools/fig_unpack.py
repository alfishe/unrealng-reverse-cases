#!/usr/bin/env python3
"""Doc 03 figure: Trush block 4 unpacking itself at boot, from the recording r1 (memory sampled once a frame).

    python3 tools/fig_unpack.py --work work/zgsA/r1 --out docs/img/load/trush-unpack.gif

The moments come from r1 (time_travel find_event exec): the boot runs the block at $607C at frame 684 T 10107; the
copied depacker starts at $607C at 691:8835; its Done (LD SP,IX at $613C) at 735:5717; the boot's menu ($6D60) at
812:4769. Between those, one sample a frame (71680 T, the Pentagon's frame), the 64 K view through time_travel
memory_at (cached in W/mem).

The grid is $4000-$FFFF, one row 256 bytes, $4000 at the top. A byte's grey is its value. A byte that changed since
the last picture is yellow, then fades through red; once it settles it keeps the colour of the phase that wrote it
last: blue the packed stream moved up (LDDR), green the depacker's output, bright green the output after the last
move. The bar on the right is the phase; the counters are the bytes each phase changed so far.
"""
import argparse
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
FT = 71680
T0, T_DEP, T_DONE, T_MENU = 684 * FT + 10107, 691 * FT + 8835, 735 * FT + 5717, 749 * FT
PHASES = [(T0, T_DEP, 'the head moves the packed stream\nup to end at $FFFF (LDDR), then\ncopies the depacker over itself',
           (80, 140, 255)),
          (T_DEP, T_DONE, 'the depacker writes the game\nupward from $614A, popping\nbits and bytes through SP',
           (60, 170, 90)),
          (T_DONE, T_MENU, 'Done: LDDR moves the output\nup by $5E so it ends at $FFFF', (140, 255, 120))]
FADE = [(255, 255, 120), (255, 200, 60), (240, 120, 40), (190, 60, 40)]
CELL = 2
LO = 0x4000


def phase_at(t):
    for i, (a, b, _, _) in enumerate(PHASES):
        if a <= t < b:
            return i
    return len(PHASES) - 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--work', required=True)
    ap.add_argument('--out', default=Z.out('load', 'trush-unpack.gif'))
    a = ap.parse_args()
    times = sorted(set(list(range(T0, T_MENU + 1, FT)) + [T_DEP, T_DONE]))
    font, small = K.font(14), K.font(12)
    prev, prev_t, age, owner, changed = None, T0, {}, {}, [0, 0, 0]
    pics, durs = [], []
    W, H = 256 * CELL, (0x10000 - LO) // 256 * CELL
    for t in times:
        f, tf = divmod(t, FT)
        m = Z.cached(a.work, f, 0, 0x10000, tf)
        ph = phase_at(t)
        wrote = phase_at(prev_t) if prev is not None else ph  # the interval (prev_t, t] lies in prev_t's phase
        prev_t = t
        if prev is not None:
            for k in list(age):
                age[k] += 1
                if age[k] >= len(FADE):
                    del age[k]
            for x in range(LO, 0x10000):
                if m[x] != prev[x]:
                    age[x] = 0
                    owner[x] = wrote
                    changed[wrote] += 1
        prev = m
        img = Image.new("RGB", (W + 370, H + 90), K.BACKGROUND)
        px = img.load()
        for x in range(LO, 0x10000):
            r, c = divmod(x - LO, 256)
            v = m[x]
            if x in age:
                col = FADE[age[x]]
            elif x in owner:
                base = PHASES[owner[x]][3]
                k = 0.45 + 0.55 * v / 255
                col = tuple(int(q * k) for q in base)
            else:
                g = 30 + v // 3
                col = (g, g, g + 6)
            for dy in range(CELL):
                for dx in range(CELL):
                    px[c * CELL + dx, 40 + r * CELL + dy] = col
        d = ImageDraw.Draw(img)
        d.text((8, 6), 'Trush block 4 unpacks Zynaps, the installer and the GS driver into $61A8-$FFFF', fill=K.TEXT,
               font=font)
        for addr in range(LO, 0x10001, 0x2000):
            y = 40 + (addr - LO) // 256 * CELL
            d.line([(W, y), (W + 8, y)], fill=K.DIM)
            d.text((W + 12, y - 7), f'${addr:04X}' if addr < 0x10000 else '$FFFF', fill=K.DIM, font=small)
        x0 = W + 80
        d.text((x0, 44), f'frame {f}  T {tf}', fill=K.TEXT, font=font)
        d.text((x0, 64), f'{(t - T0) / FT:5.1f} frames since the block ran', fill=K.DIM, font=small)
        y = 100
        for i, (pa, pb, label, colour) in enumerate(PHASES):
            on = i == ph and t < T_MENU
            d.rectangle([x0, y, x0 + 14, y + 14], fill=colour, outline=K.TEXT if on else None)
            d.text((x0 + 22, y - 2), f'{i + 1}. {(pb - pa) / FT:.1f} frames', fill=K.TEXT if on else K.DIM,
                   font=small)
            d.multiline_text((x0 + 22, y + 14), label, fill=K.TEXT if on else K.DIM, font=small)
            d.text((x0 + 22, y + 62), f'{changed[i]} bytes changed', fill=K.TEXT if on else K.DIM, font=small)
            y += 100
        d.rectangle([x0, y, x0 + 14, y + 14], fill=FADE[0])
        d.text((x0 + 22, y), 'changed since the last frame', fill=K.DIM, font=small)
        if t >= T_MENU - FT:
            d.text((x0, y + 30), 'next: the boot fades the screen\nand runs the options menu', fill=K.TEXT,
                   font=small)
        pics.append(img)
        durs.append(1500 if t == T0 else 90)
    durs[-1] = 3000
    K.save_gif(a.out, pics, durs)
    print(a.out, len(pics), 'pictures', changed)


if __name__ == '__main__':
    main()

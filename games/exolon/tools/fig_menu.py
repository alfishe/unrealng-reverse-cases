#!/usr/bin/env python3
"""Doc 04 figure: the menu's twelve star slots over a stretch of a recording, as a GIF.

    python3 tools/fig_menu.py --work work/docs/fillL/c1 --from 12826 --to 12890 --out docs/img/loop/menu-stars.gif

Each picture is one frame of the recording (TTD memory_at at the end of the frame):

- left, the screen (x2), with a box around each slot's 16 x 16 star place and the slot's number;
- right, the twelve slots of SparkleSlots `$6F5E` (3 bytes each: x in 2-pixel units, y in pixels, frames left), the
  sprite the next step draws (SparkleFrames `$6F4E`, indexed by the frames left) and a bar of the frames left;
- a slot with 0 frames left is free: the next pass draws a random cell for it, and keeps it only if the four
  CellTypes `$6100` bytes under it are 0.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import exlib  # noqa: E402

K = exlib.K
SLOTS, FRAMES = 0x6F5E, 0x6F4E


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=1)
    p.add_argument('--out', required=True)
    a = p.parse_args()
    s = exlib.session(a.work)
    W, H = 1050, 470
    f, fb, fs = K.font(14), K.font(17), K.font(13)
    pictures, durations = [], []
    table = exlib.read(s, a.start, FRAMES, 16)
    for fr in range(a.start, a.end + 1, a.step):
        scr = exlib.read(s, fr, 0x4000, 0x1B00)
        slots = exlib.read(s, fr, SLOTS, 36)
        mem = bytearray(0x10000)
        mem[0x4000:0x5B00] = scr
        im = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        d.text((12, 8), f'The menu stars: twelve slots, a random free place, 16 steps each (c1 frame {fr})',
               fill=K.TEXT, font=fb)
        screen = K.render_screen(bytes(mem)).resize((512, 384), Image.NEAREST)
        im.paste(screen, (12, 40))
        x0 = 548
        d.text((x0, 40), 'slot  x   y   left  next sprite', fill=K.TEXT, font=f)
        for k in range(12):
            x, y, left = slots[3 * k], slots[3 * k + 1], slots[3 * k + 2]
            yy = 64 + 26 * k
            col = (255, 220, 90) if left else (130, 130, 140)
            spr = table[left - 1] if left else None
            nxt = (f'${spr:02X}' + (' (blank: erase)' if spr == 0 else '')) if left else 'free: try a place'
            d.text((x0, yy), f'{k:>3}  ${x:02X} ${y:02X}  {left:>3}   {nxt}', fill=col, font=f)
            d.rectangle((x0 + 330, yy + 4, x0 + 330 + 8 * 16, yy + 14), outline=(90, 90, 100))
            if left:
                d.rectangle((x0 + 330, yy + 4, x0 + 330 + 8 * left, yy + 14), fill=col)
                px, py = 12 + 2 * (2 * x), 40 + 2 * y
                d.rectangle((px - 1, py - 1, px + 32, py + 32), outline=col)
                d.text((px + 2, py - 16 if py > 56 else py + 34), str(k), fill=col, font=fs)
        d.text((x0, 64 + 26 * 12 + 4), 'x: 2-pixel units (x 4 = column x 8); y: pixels',
               fill=K.DIM, font=fs)
        d.text((x0, 64 + 26 * 12 + 22), 'one step a pass (about 1.8 frames); bar: steps left of 16',
               fill=K.DIM, font=fs)
        d.text((12, 432), 'a box = a slot\'s 16 x 16 place on the screen (its number above it); grey rows = free slots',
               fill=K.DIM, font=fs)
        pictures.append(im)
        durations.append(160)
    durations[-1] = 2000
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    K.save_gif(a.out, pictures, durations)
    print(a.out, len(pictures), 'pictures', pictures[0].size)


if __name__ == '__main__':
    main()

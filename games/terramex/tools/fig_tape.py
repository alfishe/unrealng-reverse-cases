#!/usr/bin/env python3
"""Doc 03's tape picture: the five blocks of the tape in time, and where each lands in memory.

    python3 tools/fig_tape.py docs/img/load/tape.png

The blocks, their lengths, durations and pauses are those of tools/tzxblocks.py over the original TZX (doc 3, 3.1,
src/tape/tape.txt); the parts of block 4 are the .ann files' (src/music, src/select, src/explorers); the c1 frames are
the L1 arrivals of the loader `$5D08`, the set-up `$7200` and GameEntry `$8F00` (WALKTHROUGH 1). The top band is the
tape in seconds at ROM speed, pauses included; the bottom band is the 64 K with each block's landing place, and the
128K pages block 4's parts are copied to.
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

BG, TEXT, DIM = (20, 20, 26), (235, 235, 235), (175, 175, 185)
COL = {1: (150, 150, 150), 2: (250, 200, 80), 3: (90, 210, 210), 4: (200, 140, 230), 5: (235, 120, 100)}
# block, bytes with flag and checksum, seconds, pause ms, label
BLOCKS = [(1, 19, 5.09, 989, 'header "TERRAMEX"'), (2, 304, 3.66, 1703, 'BASIC + loader'),
          (3, 6914, 35.80, 1150, 'screen'), (4, 38650, 187.91, 7777, 'music, selector, 5 sets'),
          (5, 36354, 197.66, 22475, 'the game')]


def main():
    out = sys.argv[1]
    W = 1050
    f, fs, fb, fl = kitlib.font(14), kitlib.font(13), kitlib.font(19), kitlib.font(15)
    img = Image.new('RGB', (W, 720), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 14), 'The tape of Terramex: five standard blocks, 464 s at ROM speed, and where each one lands',
           font=fb, fill=TEXT)
    left, right = 30, 30
    total = sum(s + p / 1000 for _, _, s, p, _ in BLOCKS)
    scale = (W - left - right) / total
    y0 = 70
    d.text((left, y0 - 2), 'The tape in time (s); a gap is the pause after a block', font=fl, fill=TEXT)
    y0 += 26
    t = 0.0
    xs = {}
    for b, n, s, p, lab in BLOCKS:
        xa, xb = left + t * scale, left + (t + s) * scale
        d.rectangle([xa, y0, max(xb - 1, xa + 2), y0 + 40], fill=COL[b])
        xs[b] = (xa, xb)
        if xb - xa > 90:
            d.text((xa + 5, y0 + 4), f'block {b}', font=f, fill=(0, 0, 0))
            d.text((xa + 5, y0 + 22), f'{n:,} B, {s:.0f} s'.replace(',', ' '), font=fs, fill=(0, 0, 0))
        t += s + p / 1000
    # small blocks labelled above
    for b in (1, 2, 3):
        xa, xb = xs[b]
        d.line([(xa + 1, y0 - 2), (xa + 1, y0 - 8)], fill=COL[b])
    d.text((left, y0 + 46), 'block 1: header, 19 B, 5 s   block 2: BASIC, 304 B, 4 s   block 3: screen, 6 914 B, 36 s',
           font=fs, fill=DIM)
    for sec in range(0, int(total) + 1, 50):
        x = left + sec * scale
        d.line([(x, y0 + 66), (x, y0 + 72)], fill=DIM)
        d.text((x - 8, y0 + 74), f'{sec}', font=fs, fill=DIM)
    # c1 marks (frames of 70 908 T at 3.5469 MHz: 50.02 per second); the tape starts about 3 s after power-on
    y1 = y0 + 100
    d.text((left, y1), 'c1 (128K, ROM speed): the L1 arrivals', font=fl, fill=TEXT)
    y1 += 24
    marks = [(696, 'loader $5D08: fr 696'), (11841, 'set-up $7200: fr 11841'), (21597, 'GameEntry $8F00: fr 21597')]
    for fr, lab in marks:
        sec = fr / 50.02
        x = left + (sec - (696 / 50.02 - (5.09 + 0.989 + 3.66))) * scale
        d.line([(x, y1), (x, y1 + 26)], fill=TEXT, width=2)
        tw = d.textlength(lab, font=fs)
        d.text((x + 6 if x + 6 + tw < W - right else x - 6 - tw, y1 + 6), lab, font=fs, fill=TEXT)
    # memory
    y2 = y1 + 62
    d.text((left, y2), 'Where they land: the 64 K ($4000-$FFFF) and the 128K pages', font=fl, fill=TEXT)
    y2 += 26
    mx0, mw = left + 70, W - left - right - 70
    def mx(a):
        return mx0 + (a - 0x4000) * mw / 0xC000
    rows = [
        ('block 3', [(0x4000, 0x5AFF, 3, 'screen')]),
        ('block 4', [(0x6000, 0x71FF, 4, 'music'), (0x7200, 0x9CF7, 4, 'selector + set-up'),
                     (0x9CF8, 0xF6F7, 4, 'five explorer sets, $1200 each')]),
        ('block 5', [(0x7200, 0xFFFF, 5, 'the game $7200-$FFFF: over block 4 from $7200')]),
    ]
    for name, regs in rows:
        d.text((left, y2 + 8), name, font=f, fill=TEXT)
        d.rectangle([mx0, y2, mx0 + mw, y2 + 30], outline=(70, 70, 80))
        for a, b, c, lab in regs:
            d.rectangle([mx(a), y2, mx(b + 1) - 2, y2 + 30], fill=COL[c])
            d.text((mx(a) + 4, y2 + 7), lab, font=fs, fill=(0, 0, 0))
        y2 += 38
    for a in range(0x4000, 0x10001, 0x2000):
        x = mx(a)
        d.line([(x, y2 - 4), (x, y2 + 2)], fill=DIM)
        d.text((x - 20, y2 + 4), f'${a:04X}' if a < 0x10000 else '', font=fs, fill=DIM)
    y2 += 30
    d.text((left, y2), 'On a 128K the set-up at $7200 copies block 4 away before block 5 loads over it:', font=f,
           fill=TEXT)
    y2 += 24
    copies = [('$6000-$71FF music', 'RAM 6 at $C000', 0x6000, 0x71FF),
              ('$7200-$9CF7 selector', 'RAM 1 at $C000 (relocated)', 0x7200, 0x9CF7),
              ('$9CF8-$D2F7 sets 0-2', 'RAM 4 at $C000, $D200, $E400', 0x9CF8, 0xD2F7),
              ('$D2F8-$F6F7 sets 3-4', 'RAM 3 at $C000, $D200', 0xD2F8, 0xF6F7)]
    for src, dst, a, b in copies:
        xa, xb = mx(a), mx(b + 1) - 2
        d.rectangle([xa, y2 + 2, xb, y2 + 14], fill=COL[4])
        t = f'{src}  ->  {dst}'
        tw = d.textlength(t, font=fs)
        d.text((xb + 8 if xb + 8 + tw < W - right else xa - 8 - tw, y2), t, font=fs, fill=TEXT)
        y2 += 20
    y2 += 8
    d.text((left, y2), 'On a 48K the tape stops after block 4, the selector runs at $7200 and copies one set to $6000; '
           'block 5 then loads over the rest.', font=fs, fill=DIM)
    img.crop((0, 0, W, y2 + 30)).save(out)
    print(out)


if __name__ == '__main__':
    main()

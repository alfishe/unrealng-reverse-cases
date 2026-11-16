#!/usr/bin/env python3
"""Doc 03's tape figure: the eight blocks of the original TZX in time (signal and pause, at ROM speed) and where
each data block lands in the 64 K, from kit/tapblocks.py's reading of the file.

    python3 tools/fig_tape.py "work/media/ATV Simulator.tzx" docs/img/load/tape.png
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import tapblocks  # noqa: E402

# what each block is and where the loader puts it (doc 3.1); None: not loaded anywhere
WHAT = [('header "ATV" LINE 10', None), ('BASIC loader, 44 bytes', (0x5CCB, 44)),
        ('header 34 at 65500', None), ('loader, 34 bytes', (0xFFDC, 34)),
        ('header 6912 at 50000: skipped', None), ('loading screen, 6912', (0x4000, 6912)),
        ('header 40000 at 25400: skipped', None), ('the game, 40000', (0x6338, 40000))]
COLOURS = [(150, 150, 160), (240, 200, 80), (150, 150, 160), (250, 140, 60), (110, 110, 120), (120, 190, 250),
           (110, 110, 120), (120, 220, 130)]


def font(n):
    try:
        return ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', n)
    except OSError:
        return ImageFont.load_default()


def main():
    path, out = sys.argv[1], sys.argv[2]
    data = open(path, 'rb').read()
    times = [(tapblocks.tzx_seconds(b), b.get('pause', 0) / 1000) for b in tapblocks.parse_tzx(data)]
    big, small = font(15), font(12)
    W, H = 1050, 560
    im = Image.new('RGB', (W, H), (22, 22, 30))
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The tape: eight standard ROM blocks, 281.9 s at ROM speed; the loader skips the two headers before the data',
           fill=(240, 240, 240), font=small)
    # time line
    x0, y0, tw = 20, 60, 1010
    total = sum(s + p for s, p in times)
    t = 0.0
    for i, ((s, p), (what, dest)) in enumerate(zip(times, WHAT)):
        xa = x0 + int(tw * t / total)
        xb = x0 + int(tw * (t + s) / total)
        xc = x0 + int(tw * (t + s + p) / total)
        d.rectangle([xa, y0, max(xb, xa + 2), y0 + 40], fill=COLOURS[i])
        d.rectangle([xb, y0 + 16, xc, y0 + 24], fill=(60, 60, 70))
        lab = '%d' % i
        d.text((xa + 2, y0 + 44), lab, fill=(230, 230, 230), font=small)
        t += s + p
    for sec in range(0, 290, 30):
        x = x0 + int(tw * sec / total)
        d.line([x, y0 + 62, x, y0 + 66], fill=(160, 160, 160))
        d.text((x - 8, y0 + 68), '%d s' % sec, fill=(160, 160, 160), font=small)
    # legend rows
    ly = y0 + 96
    t = 0.0
    for i, ((s, p), (what, dest)) in enumerate(zip(times, WHAT)):
        d.rectangle([20, ly + 3, 32, ly + 15], fill=COLOURS[i])
        d.text((40, ly), '%d  %-32s %6.2f s + pause %4.2f s, starts at %6.2f s' % (i, what, s, p, t),
               fill=(220, 220, 220), font=small)
        t += s + p
        ly += 19
    # memory bar
    my, mh = ly + 30, 46
    mx0, mw = 20, 1010
    d.text((mx0, my - 20), 'where the data blocks land in the 64 K (the ROM at 0000-3FFF)', fill=(220, 220, 220), font=small)
    d.rectangle([mx0, my, mx0 + mw, my + mh], outline=(120, 120, 130), fill=(35, 35, 45))
    d.rectangle([mx0, my, mx0 + mw // 4, my + mh], fill=(70, 70, 80))
    d.text((mx0 + 8, my + 16), 'ROM', fill=(220, 220, 220), font=small)
    for i, (what, dest) in enumerate(WHAT):
        if not dest:
            continue
        a, n = dest
        xa = mx0 + mw * a // 65536
        xb = max(xa + 3, mx0 + mw * (a + n) // 65536)
        d.rectangle([xa, my + 2, xb, my + mh - 2], fill=COLOURS[i])
        d.text((min(xa + 2, W - 70), my + mh + 4 + (14 if i in (1, 3) else 0)), '%d: %04X' % (i, a), fill=COLOURS[i], font=small)
    for a in range(0, 0x10001, 0x2000):
        x = mx0 + mw * a // 65536
        d.text((x - 14, my + mh + 36), '%04X' % min(a, 0xFFFF), fill=(150, 150, 150), font=small)
    im = im.crop((0, 0, W, my + mh + 56))
    im.save(out)
    print(out, im.size)


if __name__ == '__main__':
    main()

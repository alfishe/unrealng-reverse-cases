#!/usr/bin/env python3
"""Doc 03 figure: when each 128K bank is filled during the load of side 1 in c1 (signal speed, play at frame 208).

    python3 tools/fig_load_timeline.py work/stage1/loadscan.json docs/img/load/load-timeline.png
    python3 tools/fig_load_timeline.py countdown docs/img/load/countdown-font.png

countdown: the ten digits of CountdownFont ($BF80, 8 bytes each, from build/stage2.bin, the stage at $BF0D) enlarged,
and the four digit pointers of WaitTask's countdown ($BCEE-$BCF1, from build/chain.bin) as the countdown starts.

loadscan.json: [frame, bank, bytes changed, first offset, last offset] per 250-frame sample (work/stage1/loadscan.py,
time_travel memory_at of every bank of c1). The tape blocks of side 1 are drawn above at their times from the TZX
timings (tools/tzxblocks.py), so a bank's bar sits under the block that fills it.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402

PLAY = 208
W, H, X0, X1 = 900, 330, 70, 880
F0, F1 = 0, 24500


def x(f):
    return X0 + (f - F0) * (X1 - X0) / (F1 - F0)


def main():
    scan = json.load(open(sys.argv[1]))
    tzx = open(os.path.join(HERE, '..', 'work', 'stage1', 'media', 'side1.tzx'), 'rb').read()
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    d.text((X0, 4), 'Side 1 in c1: tape blocks (top) and the bytes each bank gains per 250 frames (bars)', fill='black')
    t = 0.0
    for b in tzxblocks.parse(tzx):
        s = tzxblocks.seconds(b) or 0
        data = b.get('data')
        if data is not None and len(data) > 100:
            f0, f1 = PLAY + t * 50, PLAY + (t + s) * 50
            d.rectangle([x(f0), 24, x(f1), 44], outline='black', fill='#cde')
            label = str(len(data))
            if x(f1) - x(f0) > 30:
                d.text((x(f0) + 3, 28), label, fill='black')
        t += s
    d.text((4, 28), 'blocks', fill='black')
    for n in range(8):
        y = 60 + n * 30
        d.text((4, y + 6), f'bank {n}', fill='black')
        d.line([X0, y + 24, X1, y + 24], fill='#ccc')
        for f, bank, count, _a, _b in scan:
            if bank != n or count < 50:
                continue
            h = min(22, 22 * count / 1100)
            d.rectangle([x(f - 250), y + 24 - h, x(f), y + 24], fill='#c33' if f >= 23974 else '#36a')
    for f in range(0, F1 + 1, 2000):
        d.line([x(f), 300, x(f), 304], fill='black')
        d.text((x(f) - 12, 306), str(f), fill='black')
    d.text((X0, 318), 'frame of c1; red: the bootstrap at $8000 (frame 23974) copies bank 1 to $8301-$BFFF and the loader rewrites $5C3C-$7FFF', fill='#c33')
    os.makedirs(os.path.dirname(sys.argv[2]), exist_ok=True)
    im.save(sys.argv[2])


def countdown(out):
    root = os.path.join(HERE, '..')
    stage = open(os.path.join(root, 'build', 'stage2.bin'), 'rb').read()
    chain = open(os.path.join(root, 'build', 'chain.bin'), 'rb').read()
    font = stage[0xBF80 - 0xBF0D:0xBF80 - 0xBF0D + 80]
    ptrs = chain[0xBCEE - 0xAC38:0xBCEE - 0xAC38 + 4]
    k, gap = 7, 18
    im = Image.new('RGB', (900, 262), 'white')
    d = ImageDraw.Draw(im)
    sys.path.insert(0, os.path.join(root, '..', '..', 'kit'))
    from kitlib import font as kfont
    f = kfont(13)
    d.text((10, 6), 'CountdownFont $BF80: digits 0-9, 8 bytes each (build/stage2.bin)', fill='black', font=f)
    for n in range(10):
        x0 = 10 + n * (8 * k + gap)
        for r in range(8):
            for b in range(8):
                if font[8 * n + r] & (0x80 >> b):
                    d.rectangle([x0 + b * k, 30 + r * k, x0 + b * k + k - 1, 30 + r * k + k - 1], fill='#202060')
        d.rectangle([x0 - 1, 29, x0 + 8 * k, 30 + 8 * k], outline='#a0a0a0')
        d.text((x0, 30 + 8 * k + 4), f'{n}: ${0xBF80 + 8 * n:04X}', fill='black', font=f)
    y = 130
    d.text((10, y), 'The four digit pointers at $BCEE-$BCF1 (low bytes into page $BF) as the countdown starts:', fill='black', font=f)
    names = ['minutes', 'tens of seconds', 'seconds', 'tenths']
    for i, p in enumerate(ptrs):
        x0 = 10 + i * 220
        digit = (p - 0x80) // 8
        d.text((x0, y + 20), f'${0xBCEE + i:04X} = ${p:02X}: digit {digit}', fill='black', font=f)
        d.text((x0, y + 34), names[i], fill='#555', font=f)
        for r in range(8):
            for b in range(8):
                if font[8 * digit + r] & (0x80 >> b):
                    d.rectangle([x0 + b * 5, y + 52 + r * 5, x0 + b * 5 + 4, y + 52 + r * 5 + 4], fill='#202060')
    d.text((10, y + 100), 'Each tenth: the tenths pointer - 8; from 0 it wraps to $C8 (9) and borrows from the seconds,', fill='#444', font=f)
    d.text((10, y + 116), 'the seconds the same, the tens of seconds wrap to $A8 (5), the minutes only count down.', fill='#444', font=f)
    im.save(out)


if __name__ == '__main__':
    if sys.argv[1] == 'countdown':
        countdown(sys.argv[2])
    else:
        main()

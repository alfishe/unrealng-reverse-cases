#!/usr/bin/env python3
"""The tape as a picture: python3 tools/fig_tape.py [TZX] [OUT.png]

Top: the blocks of the TZX on a time line (tools/tzxblocks.py parse and seconds): each block's pilot tone, its data
and the pause after it, with the c1 frames at which the loader met blocks 3 and 4 (blocks 1 and 2 went through the
ROM's fast LD-BYTES trap, so they take no frames in c1). Bottom: the 48K's memory, and where each block lands. Writes
docs/img/load/tape.png by default.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import tzxblocks as tz  # noqa: E402

WIDTH = 1050
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
COLOURS = [(240, 200, 70), (90, 200, 120), (230, 90, 80), (90, 150, 250)]
# where each data block lands (tape block index: (first, last, what)), from the loader (src/loader/loader.ann)
LANDS = {1: None, 2: (0x5CCB, 0x6322, 'BASIC + loader + picture'), 3: (0x5C3D, 0x5C3E, 'ERR_SP = 1'),
         4: (0x8214, 0xCBE7, 'the game')}
NAMES = {1: 'header "CHUCKIE"', 2: 'BASIC block, 1624 bytes', 3: '2 bytes', 4: 'the game, 18 900 bytes'}
C1 = {2: 'c1: fast trap, by frame 246', 3: 'c1: frames 262-361', 4: 'c1: frames 361-5292'}


def fmt(n):
    return f'{n:,}'.replace(',', ' ')


def main():
    tzx = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'work', 'media', 'tzx6194', 'Chuckie Egg.tzx')
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(CASE, 'docs', 'img', 'load', 'tape.png')
    blocks = [b for b in tz.parse(open(tzx, 'rb').read()) if b['id'] == 0x10]
    f = K.font
    im = Image.new('RGB', (WIDTH, 640), BG)
    d = ImageDraw.Draw(im)
    d.text((12, 10), 'The tape: four standard ROM blocks, 115 s of signal, and where each block lands', fill=TEXT,
           font=f(20))
    d.text((12, 38), 'Time across (the pause after the last block left out). Dark: the pilot tone; bright: the bytes.',
           fill=DIM, font=f(14))
    left, right = 40, WIDTH - 30
    span = sum(tz.seconds(b) for b in blocks) + sum(b['pause'] for b in blocks[:-1]) / 1000
    sx = (right - left) / span
    y0, h = 92, 44
    t = 0.0
    spans = {}
    for k, b in enumerate(blocks, 1):
        sec = tz.seconds(b)
        tm = b['timing']
        pilot = tm['pilot'] * tm['pilot_pulses'] / 3.5e6
        c = COLOURS[k - 1]
        dark = tuple(v // 3 for v in c)
        x0, x1, x2 = left + t * sx, left + (t + pilot) * sx, left + (t + sec) * sx
        d.rectangle([x0, y0, x1, y0 + h], fill=dark)
        d.rectangle([x1, y0, max(x1 + 1, x2), y0 + h], fill=c)
        spans[k] = (x0, x2)
        d.text(((x0 + x2) / 2 - 4, y0 + 12), str(k), fill=BG if k == 4 else TEXT, font=f(16))
        t += sec + (b['pause'] / 1000 if k < len(blocks) else 0)
    for s_ in range(0, int(span) + 1, 10):
        x = left + s_ * sx
        d.line([x, y0 + h, x, y0 + h + 6], fill=DIM)
        d.text((x - 8, y0 + h + 8), f'{s_} s', fill=DIM, font=f(12))
    ly = y0 + h + 34
    colw = (right - left) / 4
    for k, b in enumerate(blocks, 1):
        x = left + (k - 1) * colw
        c = COLOURS[k - 1]
        d.rectangle([x, ly + 3, x + 12, ly + 15], fill=c)
        d.text((x + 18, ly), f'{k}: {NAMES[k]}', fill=TEXT, font=f(14))
        d.text((x + 18, ly + 20), f'{tz.seconds(b):.2f} s + {b["pause"]} ms pause', fill=DIM, font=f(13))
        d.text((x + 18, ly + 38), C1.get(k, 'c1: fast trap'), fill=DIM, font=f(13))
    # memory strip
    my, mh = 330, 40
    d.text((12, my - 56), 'Where the bytes land in the 48K (the ROM and the screen shown for scale)', fill=TEXT,
           font=f(16))
    ms = (right - left) / 0x10000
    d.rectangle([left, my, right, my + mh], fill=PANEL)
    for lo, hi, name, c in ((0x0000, 0x3FFF, 'ROM', (60, 60, 75)), (0x4000, 0x5AFF, 'screen', (70, 70, 90))):
        d.rectangle([left + lo * ms, my, left + hi * ms, my + mh], fill=c)
        d.text((left + lo * ms + 6, my + 12), name, fill=TEXT, font=f(13))
    for k, land in LANDS.items():
        if not land:
            continue
        lo, hi, what = land
        c = COLOURS[k - 1]
        x0, x1 = left + lo * ms, max(left + lo * ms + 3, left + hi * ms)
        d.rectangle([x0, my, x1, my + mh], fill=c)
        bx = (spans[k][0] + spans[k][1]) / 2
        d.line([bx, y0 + h, bx, y0 + h + 4], fill=c, width=2)
        d.line([(x0 + x1) / 2, my - 10, (x0 + x1) / 2, my], fill=c, width=2)
        d.text(((x0 + x1) / 2 - 4 + (-10 if k == 3 else 6 if k == 2 else 0), my - 28), str(k), fill=c, font=f(15))
    for a_ in range(0, 0x10001, 0x4000):
        x = left + a_ * ms
        d.line([x, my + mh, x, my + mh + 6], fill=DIM)
        d.text((x - 18 if a_ else x, my + mh + 8), f'${min(a_, 0xFFFF):04X}', fill=DIM, font=f(12))
    ly = my + mh + 40
    colw = (right - left) / 3
    for i, k in enumerate((3, 2, 4)):
        lo, hi, what = LANDS[k]
        x = left + i * colw
        c = COLOURS[k - 1]
        d.rectangle([x, ly + 3, x + 12, ly + 15], fill=c)
        d.text((x + 18, ly), f'block {k}: ${lo:04X}-${hi:04X}', fill=TEXT, font=f(14))
        d.text((x + 18, ly + 20), what, fill=DIM, font=f(13))
    lines = [f'Block 4 carries 18 900 bytes in 97.47 s: {18900 / 97.47:.0f} bytes a second, the ROM\'s speed '
             '(a zero bit 2 x 855 T, a one 2 x 1710 T).',
             'In c1 the BASIC blocks went through the ROM\'s fast LD-BYTES trap; blocks 3 and 4 loaded at signal',
             'speed through the loader\'s own CALL $0556. No turbo block, no packer, no cipher.',
             'python3 tools/fig_tape.py']
    for i, line in enumerate(lines):
        d.text((12, ly + 60 + i * 22), line, fill=DIM if line.startswith('python3') else TEXT, font=f(14))
    im = im.crop((0, 0, WIDTH, ly + 60 + len(lines) * 22 + 10))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out)
    print(out, im.size)


if __name__ == '__main__':
    main()

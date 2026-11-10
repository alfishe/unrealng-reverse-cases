#!/usr/bin/env python3
"""Doc 02 2.3: the three memory images side by side, `$4000-$FFFF`, one pixel a byte, one row a 256-byte page.

The images: as loaded (`c1` at the start of frame 16 279, the frame the mover `$5000` runs in), at the entry (`c1`
at frame 16 281, after the mover and the entry's first frame) and in play (city2's end, 1935: tools/szx.py on
work/stage1/rec/city2/end.szx). The `c1` images come from its session.ttd (tools/ttdmem.py, work/stage1/c1-*.bin).
Each byte is grey by its value (zero black); a byte that differs from the image to its left is drawn in colour
(orange from loaded to entry, red from entry to play). The left axis names the regions of doc 2.2.

    python3 tools/fig_images.py docs/img/memory-images.png
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import szx  # noqa: E402

BG, TEXT, DIM = (24, 24, 30), (235, 235, 235), (170, 170, 180)
ROW_H, AXIS, GAP, TOP = 3, 235, 14, 70
CHANGE = [None, (255, 150, 30), (255, 50, 50)]
REGIONS = [
    (0x4000, 0x5B00, 'the screen'),
    (0x5B00, 0x5FC6, 'keys, code'),
    (0x5FC6, 0x6305, 'messages'),
    (0x6305, 0xA882, 'code, state, texts'),
    (0xA930, 0xA950, 'save block'),
    (0xA950, 0xC450, 'work arrays'),
    (0xC450, 0xE850, 'the city map'),
    (0xE850, 0xEA68, 'data'),
    (0xEA68, 0xF478, 'tiles'),
    (0xF530, 0xF672, 'tile attributes'),
    (0xF6A4, 0xF70B, 'two stacks'),
    (0xF70B, 0xF7BB, 'interrupt, input'),
    (0xFCFC, 0xFE01, 'IM 2 table'),
    (0xFE01, 0x10000, 'loader leftover'),
]


def images():
    def c1(frame):
        return bytes(0x4000) + open(os.path.join(CASE, f'work/stage1/c1-{frame}.bin'), 'rb').read()
    play = bytes(szx.read(os.path.join(CASE, 'work/stage1/rec/city2/end.szx'))[0])
    return [('as loaded', 'c1, frame 16 279', c1(16279)),
            ('at the entry', 'c1, frame 16 281', c1(16281)),
            ('in play', 'city2, end (1935)', play)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    a = ap.parse_args()
    imgs = images()
    pages = (0x10000 - 0x4000) // 256
    w = AXIS + len(imgs) * (256 + GAP) + 30
    h = TOP + pages * ROW_H + 100
    out = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(out)
    f, fs = K.font(15), K.font(12)
    d.text((10, 8), 'The 48K memory in three images: what the setup and play change', font=K.font(17), fill=TEXT)
    for k, (name, src, mem) in enumerate(imgs):
        x0 = AXIS + k * (256 + GAP)
        prev = imgs[k - 1][2] if k else None
        changed = 0
        for page in range(pages):
            y = TOP + page * ROW_H
            for col in range(256):
                addr = 0x4000 + page * 256 + col
                v = mem[addr]
                if prev is not None and prev[addr] != v:
                    colour = CHANGE[k]
                    changed += 1
                else:
                    g = 0 if v == 0 else 60 + v * 150 // 255
                    colour = (g, g, g)
                d.line([(x0 + col, y), (x0 + col, y + ROW_H - 1)], fill=colour)
        d.text((x0, 32), name, font=f, fill=TEXT)
        label = src if prev is None else '%s; %d bytes differ' % (src, changed)
        d.text((x0, 50), label, font=fs, fill=DIM)
    ty = 0
    for lo, hi, name in REGIONS:
        y0 = TOP + (lo - 0x4000) // 256 * ROW_H
        d.line([(AXIS - 20, y0), (w - GAP, y0)], fill=(90, 90, 120))
        ty = max(y0 - 6, ty + 15)          # small regions: the labels stacked, a leader to the boundary
        d.line([(AXIS - 40, ty + 7), (AXIS - 20, y0)], fill=(90, 90, 120))
        d.text((8, ty), '$%04X %s' % (lo, name), font=fs, fill=DIM)
    d.text((8, h - 22), 'grey: the byte value (black = 0); orange: changed from loaded to entry; red: changed from '
           'entry to play', font=fs, fill=DIM)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    out.save(a.out, optimize=True)
    print('%s: %d x %d' % (a.out, out.width, out.height))


if __name__ == '__main__':
    main()

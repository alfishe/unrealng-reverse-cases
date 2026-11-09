#!/usr/bin/env python3
"""The memory map of doc 02 as one figure: $4000-$FFFF, one row per 256 bytes (192 rows), each byte a square
coloured by what the recordings did with it (union of their L1 builds): executed green, read as data blue,
written yellow, written and read orange, untouched dark. The regions of tools/memmap-regions.txt as labelled
brackets on the right.

    python3 tools/fig_memmap.py --out docs/img/arch/memmap.png work/game/l1.json work/runs/*/l1.json
    python3 tools/fig_memmap.py stages [--out docs/img/arch/stages.png]

`stages` draws the three images of doc 02 2.3 side by side (as loaded work/mkgame/original.bin, at the entry
work/snaps/entry.z80, in play work/images/w1-1060.z80), each $4000-$FFFF at one pixel a byte, with the bytes that
differ from the image before marked (tools/szxmem.py's diff).
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

import l1map
import szxmem

HERE = os.path.dirname(os.path.abspath(__file__))
COL = {'X': (60, 200, 80), 'XR': (60, 200, 80), 'XW': (230, 60, 60), 'R': (70, 120, 230), 'W': (240, 220, 60),
       'WR': (245, 150, 40), '-': (28, 28, 34)}
NAMES = [('X', 'executed'), ('R', 'read as data'), ('WR', 'written and read'), ('W', 'written only'),
         ('XW', 'executed and written'), ('-', 'untouched')]


def font(size):
    for f in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


STAGES = [('as loaded', 'work/mkgame/original.bin', 'the tape: $8000-$E1A7, $F000-$F0FF'),
          ('at the entry', 'work/snaps/entry.z80', 'c1 frame 5556, PC $8000'),
          ('in play', 'work/images/w1-1060.z80', 'w1 frame 1060, the first aim')]
LABELS = [(0xFE00, 0xFF00, 'IM 2 vectors'), (0xFCFC, 0xFCFF, 'EI; JP $80F0'), (0xCFDC, 0xCFFF, 'the stack'),
          (0xB668, 0xBD0B, 'key names, flags'), (0x9B30, 0x9F66, 'player variables'),
          (0x91DF, 0x91FE, 'task slots'), (0x869E, 0x8B49, 'balls, draw list'),
          (0x5C04, 0x5C79, 'ROM variables')]


def stages(out):
    case = os.path.dirname(HERE)
    mems = [szxmem.memory(os.path.join(case, pth)) for _n, pth, _d in STAGES]
    c, left, top, gap = 1, 62, 92, 22
    pw, ph = 256 * c, 192 * 2 * c
    W, H = 1050, top + ph + 110
    img = Image.new('RGB', (W, H), (16, 16, 20))
    d = ImageDraw.Draw(img)
    f, fb, fs = font(14), font(18), font(12)
    d.text((10, 10), 'Video Pool: the three images of $4000-$FFFF and what changes between them', font=fb,
           fill=(240, 240, 240))
    d.text((10, 36), 'One row = 256 bytes, one pixel a byte. Grey: non-zero, dark: zero. Marked: the bytes that differ '
           'from the image to the left.', font=fs, fill=(170, 170, 170))
    counts = []
    for i, (name, _pth, desc) in enumerate(STAGES):
        x0 = left + i * (pw + gap)
        m = mems[i]
        prev = mems[i - 1] if i else None
        changed = []
        for a in range(0x4000, 0x10000):
            r, col = (a - 0x4000) // 256, a % 256
            x, y = x0 + col * c, top + r * 2 * c
            v = m[a]
            if 0x4000 <= a < 0x5B00:
                fill = (70, 90, 120) if v else (30, 34, 44)
            else:
                fill = (125, 125, 130) if v else (34, 34, 40)
            d.rectangle([x, y, x + c - 1, y + 2 * c - 1], fill=fill)
            if prev is not None and a >= 0x5B00 and prev[a] != v:
                changed.append((a, x, y))
        colour = (245, 150, 40) if i == 1 else (240, 60, 60)
        for a, x, y in changed:
            d.rectangle([x - 1, y - 1, x + c, y + 2 * c], fill=colour)
        counts.append(len(changed))
        d.text((x0, top - 40), name, font=f, fill=(235, 235, 235))
        d.text((x0, top - 22), desc, font=fs, fill=(170, 170, 170))
        for r in range(0, 192, 32):
            if i == 0:
                d.text((8, top + r * 2 * c - 2), '$%04X' % (0x4000 + r * 256), font=fs, fill=(200, 200, 200))
    # labels for the play image's changes, to its right
    x3 = left + 2 * (pw + gap) + pw
    last = -100
    for lo, hi, name in sorted(LABELS, key=lambda t: t[0]):
        ym = top + ((lo + hi) // 2 - 0x4000) // 256 * 2 * c
        ty = max(ym - 7, last + 16)
        d.line([x3 + 4, ym, x3 + 14, ty + 7], fill=(150, 150, 150))
        d.text((x3 + 18, ty), name, font=fs, fill=(235, 235, 235))
        last = ty
    ly = top + ph + 14
    d.rectangle([left, ly, left + 14, ly + 14], fill=(245, 150, 40))
    d.text((left + 20, ly), f'entry vs loaded, $5B00 up: {counts[1]} bytes, all the ROM\'s (system variables, the '
           'BASIC\'s stack, $FF18 up);', font=fs, fill=(220, 220, 220))
    d.text((left + 20, ly + 16), 'none in the game ($8000-$E1A7) or the loader ($F000-$F0FF)', font=fs,
           fill=(220, 220, 220))
    d.rectangle([left, ly + 38, left + 14, ly + 52], fill=(240, 60, 60))
    d.text((left + 20, ly + 38), f'play vs entry, $5B00 up: {counts[2]} bytes, all state (18 runs); the screen '
           '(blue) is not compared', font=fs, fill=(220, 220, 220))
    d.text((left, ly + 66), 'python3 tools/fig_memmap.py stages  (tools/szxmem.py diff gives the runs)', font=fs,
           fill=(170, 170, 170))
    img.save(out)
    print(out, img.size, counts)


def main():
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'stages':
        out = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else os.path.join(
            os.path.dirname(HERE), 'docs', 'img', 'arch', 'stages.png')
        return stages(out)
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', required=True)
    p.add_argument('--regions', default=os.path.join(HERE, 'memmap-regions.txt'))
    p.add_argument('--cell', type=int, default=2)
    p.add_argument('l1', nargs='+')
    args = p.parse_args()
    ex, rd, wr = l1map.load(args.l1)
    c = args.cell
    rows = 0xC0
    left, top = 70, 50
    mapw, maph = 256 * c, rows * c * 2
    W, H = left + mapw + 380, top + maph + 150
    img = Image.new('RGB', (W, H), (16, 16, 20))
    d = ImageDraw.Draw(img)
    f, fb, fs = font(15), font(18), font(13)
    d.text((10, 10), 'Video Pool: what the recordings did with each byte of $4000-$FFFF', font=fb,
           fill=(240, 240, 240))
    for r in range(rows):
        for col in range(256):
            a = 0x4000 + r * 256 + col
            k = l1map.klass(ex[a], rd[a], wr[a])
            x, y = left + col * c, top + r * c * 2
            d.rectangle([x, y, x + c - 1, y + 2 * c - 1], fill=COL[k])
        if r % 16 == 0:
            d.text((8, top + r * c * 2 - 2), '$%04X' % (0x4000 + r * 256), font=fs, fill=(200, 200, 200))
    # regions
    regs = [l.split(None, 2) for l in open(args.regions) if l.strip() and not l.startswith('#')]
    last_y = -100
    for lo, hi, name in regs:
        lo, hi = int(lo, 16), int(hi, 16)
        y0 = top + ((lo - 0x4000) // 256) * c * 2
        y1 = top + ((hi - 0x4000) // 256 + 1) * c * 2 - 1
        x = left + mapw + 8
        d.line([x, y0, x + 6, y0, x + 6, y1, x, y1], fill=(220, 220, 220))
        ty = max((y0 + y1) // 2 - 8, last_y + 16)
        d.line([x + 6, (y0 + y1) // 2, x + 16, ty + 8], fill=(150, 150, 150))
        d.text((x + 20, ty), '$%04X-$%04X %s' % (lo, hi, name.strip()), font=f, fill=(235, 235, 235))
        last_y = ty
    ly = max(top + maph, last_y + 16) + 20
    x = left
    for k, n in NAMES:
        d.rectangle([x, ly, x + 14, ly + 14], fill=COL[k])
        d.text((x + 20, ly - 1), n, font=f, fill=(220, 220, 220))
        x += 30 + int(d.textlength(n, font=f))
    d.text((left, ly + 28), 'one row = 256 bytes; recordings: ' + ' '.join(
        os.path.basename(os.path.dirname(pth)) for pth in args.l1) + ' (from the entry snapshot)', font=fs,
        fill=(170, 170, 170))
    img.save(args.out)
    print(args.out, img.size)


if __name__ == '__main__':
    main()

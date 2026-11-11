#!/usr/bin/env python3
"""Doc 02's figures: the memory map of the 128K in play, the heatmap at the figure width, the twelve unused sprites.

    python3 tools/fig_arch.py memmap docs/img/arch/memmap.png
    python3 tools/fig_arch.py heatmap work/stage1/l1-all.json docs/img/arch/heatmap.png
    python3 tools/fig_arch.py leftovers docs/img/arch/leftover-sprites.png

memmap draws the 64 K the CPU sees in play (ROM 1, RAM 5, RAM 2, RAM 0) and the four pages paged in at `$C000` at
other times (RAM 1 the selector, RAM 3 and RAM 4 the explorer sets, RAM 6 the music), one bar a page, the regions
from the six .ann files' modules and entries (src/*/*.ann). heatmap runs tools/fig_heatmap.py (kit/heatmap.py's
counts and colours) and scales the result to 1050 px. leftovers draws the twelve 24 x 24 sprites at `$E930-$EC8F` of
src/res/leftovers/back-buffer-tape.bin (the tape's bytes of BackBufferLeftover `$E900`), 72 bytes a sprite as three
columns of 24 bytes, the layout of the sprite space `$6000`.
"""
import argparse
import os
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

BG, TEXT, DIM = (20, 20, 26), (235, 235, 235), (175, 175, 185)
C_CODE, C_DATA, C_GFX, C_BUF, C_SYS, C_FREE, C_ROM, C_SCR = ((235, 120, 100), (110, 170, 250), (200, 140, 230),
                                                            (120, 200, 120), (250, 200, 80), (60, 60, 70),
                                                            (130, 130, 130), (90, 210, 210))

# (start, end inclusive, label, colour); from the .ann modules (work/docs/tmA/modranges.py) and entries
PLAY = [
    (0x0000, 0x3FFF, 'ROM 1 (48K BASIC): LD-BYTES during the load', C_ROM),
    (0x4000, 0x5AFF, 'screen: play window + panel', C_SCR),
    (0x5B00, 0x5DFF, 'variables $5B04-$5C8D, BASIC, stack to $5DDE', C_SYS),
    (0x5E00, 0x5FFF, 'vector $5F5F, stub $5FE6, flags $5FE5-$5FFF', C_SYS),
    (0x6000, 0x71FF, 'explorer set (frames $00-$3F)', C_GFX),
    (0x7200, 0x8CFF, 'creature frames $40-$7F, items $80-$9F', C_GFX),
    (0x8D00, 0x8EFF, 'leftover, IM 2 table (to $8F00)', C_FREE),
    (0x8F00, 0xC57F, 'game code $8F00-$C57F (19 modules) and its tables', C_CODE),
    (0xC580, 0xDFFF, 'tile attrs, back-tiles $C600, rooms $D600', C_DATA),
    (0xE000, 0xEFFF, 'back buffer $E000', C_BUF),
    (0xF000, 0xF7FF, 'tiles $F000', C_DATA),
    (0xF800, 0xF9FF, 'tile map', C_BUF),
    (0xFA00, 0xFDFF, 'alt tiles $FA00', C_DATA),
    (0xFE00, 0xFFFF, 'BitReverse', C_DATA),
]
PAGES = [
    ('RAM 1', 'the selector (block 4 $7200-$9CF7, relocated)', [
        (0xC000, 0xC0D1, 'set-up, relocation', C_CODE),
        (0xC0D2, 0xC535, 'selector, input, stub, print', C_CODE),
        (0xC536, 0xCD8E, 'Help pages', C_DATA),
        (0xCD8F, 0xEA0E, 'selector picture and data', C_GFX),
        (0xEA0F, 0xEAF7, 'RelocTable, leftover', C_DATA),
        (0xEAF8, 0xFFFF, 'not used', C_FREE)]),
    ('RAM 3', 'explorer sets 3-4 (block 4 $D2F8-$F6F7)', [
        (0xC000, 0xD1FF, 'set 3 Big John Caine', C_GFX),
        (0xD200, 0xE3FF, 'set 4 Wu Pong', C_GFX),
        (0xE400, 0xFFFF, 'not used', C_FREE)]),
    ('RAM 4', 'explorer sets 0-2 (block 4 $9CF8-$D2F7)', [
        (0xC000, 0xD1FF, 'set 0 Fortisque-Smithe', C_GFX),
        (0xD200, 0xE3FF, 'set 1 Herr Krusche', C_GFX),
        (0xE400, 0xF5FF, 'set 2 Henri Beaucoup', C_GFX),
        (0xF600, 0xFFFF, 'not used', C_FREE)]),
    ('RAM 6', 'the music (block 4 $6000-$71FF)', [
        (0xC000, 0xC82C, 'player', C_CODE),
        (0xC82D, 0xD1FF, 'tunes', C_DATA),
        (0xD200, 0xFFFF, 'not used', C_FREE)]),
]


def bar(d, x0, y0, w, h, lo, hi, regions, f, min_label):
    span = hi - lo + 1
    for a, b, label, colour in regions:
        xa = x0 + (a - lo) * w / span
        xb = x0 + (b + 1 - lo) * w / span
        d.rectangle([xa, y0, xb - 1, y0 + h], fill=colour, outline=BG)
        if xb - xa >= min_label:
            d.text((xa + 4, y0 + 4), f'${a:04X}', font=f, fill=(0, 0, 0))


def memmap(args):
    W = 1050
    f, fs, fb, fl = kitlib.font(14), kitlib.font(13), kitlib.font(19), kitlib.font(15)
    img = Image.new('RGB', (W, 1400), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 14), 'Terramex on the 128K: the 64 K in play and the pages paged in at $C000', font=fb, fill=TEXT)
    d.text((20, 42), 'From the six .ann files (src/*/*.ann); the stack and the variables from the L1 of every play '
           'recording.', font=fs, fill=DIM)
    left, right = 20, 20
    # the play map, as four 16 K rows so that labels fit
    y = 80
    d.text((left, y), 'In play: ROM 1, RAM 5, RAM 2, RAM 0 ($7FFD = $10)', font=fl, fill=TEXT)
    y += 28
    for q in range(4):
        lo, hi = q * 0x4000, q * 0x4000 + 0x3FFF
        regs = [(max(a, lo), min(b, hi), lab, c) for a, b, lab, c in PLAY if b >= lo and a <= hi]
        d.text((left, y + 10), f'${lo:04X}', font=f, fill=DIM)
        bx, bw = left + 64, W - left - right - 64
        bar(d, bx, y, bw, 34, lo, hi, regs, fs, 52)
        y += 40
        # labels under the bar, one line each, with a leader
        ly = y
        for a, b, lab, c in regs:
            xa = bx + (a - lo) * bw / 0x4000
            t = f'${a:04X}-${b:04X} {lab}'
            tx = min(xa + 1, W - right - 16 - d.textlength(t, font=fs))
            d.rectangle([tx, ly + 3, tx + 10, ly + 13], fill=c)
            d.text((tx + 15, ly), t, font=fs, fill=TEXT)
            ly += 19
        y = ly + 16
    y += 6
    d.text((left, y), 'Paged in at $C000 at other times (each bar is $C000-$FFFF of its page)', font=fl, fill=TEXT)
    y += 28
    for name, what, regs in PAGES:
        d.text((left, y), name, font=fl, fill=TEXT)
        d.text((left + 64, y), what, font=fs, fill=DIM)
        y += 22
        bx, bw = left + 64, W - left - right - 64
        bar(d, bx, y, bw, 30, 0xC000, 0xFFFF, regs, fs, 52)
        y += 36
        x = bx
        for a, b, lab, c in regs:
            t = f'${a:04X}-${b:04X} {lab}'
            tw = d.textlength(t, font=fs) + 30
            if x + tw > W - right:
                x, y = bx, y + 19
            d.rectangle([x, y + 3, x + 10, y + 13], fill=c)
            d.text((x + 15, y), t, font=fs, fill=TEXT)
            x += tw
        y += 30
    y += 4
    x = left
    for lab, c in [('code', C_CODE), ('data', C_DATA), ('graphics', C_GFX), ('buffers', C_BUF),
                   ('variables', C_SYS), ('screen', C_SCR), ('ROM', C_ROM), ('free or leftover', C_FREE)]:
        d.rectangle([x, y + 3, x + 14, y + 17], fill=c)
        d.text((x + 20, y), lab, font=f, fill=TEXT)
        x += 40 + d.textlength(lab, font=f)
    y += 30
    d.text((left, y), 'RAM 7 is not used. The selector is paged with $7FFD = $11 (RunSelector $8F4A), the music '
           'with $16 (Im2Handler $9491).', font=fs, fill=DIM)
    img.crop((0, 0, W, y + 28)).save(args.out)
    print(args.out)


def heatmap(args):
    tmp = os.path.join(CASE, 'work', 'docs', 'tmA', 'heatmap-full.png')
    subprocess.run([sys.executable, os.path.join(HERE, 'fig_heatmap.py'), args.l1, tmp], check=True)
    im = Image.open(tmp)
    w, h = im.size
    im.resize((1050, round(h * 1050 / w)), Image.LANCZOS).save(args.out)
    print(args.out)


def leftovers(args):
    data = open(os.path.join(CASE, 'src', 'res', 'leftovers', 'back-buffer-tape.bin'), 'rb').read()
    scale, n = 5, 12
    cols = 6
    cw, ch = 24 * scale + 40, 24 * scale + 44
    W = 1050
    gx = (W - cols * cw) // 2
    f, fb = kitlib.font(14), kitlib.font(18)
    H = 60 + 2 * ch + 40
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((20, 14), 'The twelve unused sprites at $E930-$EC8F (the tape\'s bytes of the back buffer)', font=fb,
           fill=TEXT)
    for i in range(n):
        a = 0xE930 + 72 * i
        off = a - 0xE900
        spr = data[off:off + 72]
        x0, y0 = gx + (i % cols) * cw + 20, 56 + (i // cols) * ch
        d.rectangle([x0 - 2, y0 - 2, x0 + 24 * scale + 1, y0 + 24 * scale + 1], fill=(0, 0, 0))
        for col in range(3):
            for row in range(24):
                byte = spr[col * 24 + row]
                for bit in range(8):
                    if byte & (0x80 >> bit):
                        px, py = x0 + (col * 8 + bit) * scale, y0 + row * scale
                        d.rectangle([px, py, px + scale - 1, py + scale - 1], fill=(240, 240, 240))
        d.text((x0, y0 + 24 * scale + 6), f'${a:04X}', font=f, fill=DIM)
    d.text((20, H - 30), 'No frame number reaches them: the sprite space $6000 + 72 x F ends at $A7B8 (F = $FF), below $E930.',
           font=f, fill=DIM)
    img.save(args.out)
    print(args.out)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    m = sub.add_parser('memmap')
    m.add_argument('out')
    h = sub.add_parser('heatmap')
    h.add_argument('l1')
    h.add_argument('out')
    lo = sub.add_parser('leftovers')
    lo.add_argument('out')
    a = ap.parse_args()
    {'memmap': memmap, 'heatmap': heatmap, 'leftovers': leftovers}[a.cmd](a)


if __name__ == '__main__':
    main()

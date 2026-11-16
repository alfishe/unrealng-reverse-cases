#!/usr/bin/env python3
"""IM 2 in Enduro Racer: the vector table and what the handler does with the two bytes its interrupt pushed,
by where SP pointed (doc 04, 4.2-4.4).

    python3 tools/fig_im2.py [--out docs/img/loop/im2-repair.png]

Drawn from the code (src/game/entry.asm Init, src/game/interrupt.asm): no recording is read. Top: the vector, I =
$B2 and any byte on the bus read a word of the table $B200-$B300 (257 bytes of $64), so the CPU jumps to $6464,
IntVector, JR Interrupt. Bottom: the 64 KB as one band; each region is coloured by what IntRepair does to the
return address the CPU pushed there, and the routines that move SP into that region are named under it.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

REGIONS = [
    (0x0000, 0x3FFF, (230, 90, 80), 'ROM: the push is lost', 'the JP returns to the word the ROM holds'),
    (0x4000, 0xFDFF, (250, 210, 90), 'RAM: IntZeroBytes', 'the two bytes become 0, 0'),
    (0xFE00, 0xFF81, (110, 200, 120), 'RowTable: RowEntry', 'the entry gets its row address again'),
    (0xFF82, 0xFFFF, (120, 170, 230), 'the real stack', 'left alone'),
]
USERS = [
    (0x0000, 0x3FFF, 'DrawRoad when RoadTopRow passes $FF (stage 3 reset)'),
    (0xEB00, 0xFDFF, 'DrawHorizon pushes zeros; BlitRows pops'),
    (0xFE00, 0xFF81, 'DrawRoad pops row addresses'),
    (0xFF82, 0xFFFF, 'the game\'s own CALLs'),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'loop', 'im2-repair.png'))
    a = ap.parse_args()
    W = 1050
    im = Image.new('RGB', (W, 470), (255, 255, 255))
    d = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(14), kitlib.font(18), kitlib.font(13)
    d.text((10, 8), 'IM 2: any interrupt reaches $643C; the handler repairs the word its push wrote, unless SP was '
           'in the ROM', font=fb, fill=(0, 0, 0))
    # the vector chain
    y = 50
    boxes = [('I = $B2, bus byte any (48K: $FF)', (230, 230, 230)),
             ('table $B200-$B300: 257 x $64', (250, 120, 200)),
             ('vector $6464: IntVector', (230, 230, 230)),
             ('JR $643C: Interrupt', (230, 90, 80))]
    x = 10
    bw = (W - 20 - 3 * 30) // 4
    for i, (t, col) in enumerate(boxes):
        d.rectangle([x, y, x + bw, y + 50], fill=col, outline=(0, 0, 0))
        d.text((x + 8, y + 16), t, font=fs, fill=(0, 0, 0))
        if i < 3:
            d.line([x + bw + 2, y + 25, x + bw + 28, y + 25], fill=(0, 0, 0), width=2)
            d.polygon([(x + bw + 28, y + 19), (x + bw + 28, y + 31), (x + bw + 34, y + 25)], fill=(0, 0, 0))
        x += bw + 30
    d.text((10, y + 58), 'the CPU reads the word at I x 256 + bus byte: $B2FF and $B300 are both $64, as is every '
           'other pair, so no bus value misses', font=fs, fill=(60, 60, 60))
    # the address band
    by, bh = 170, 60
    d.text((10, by - 26), 'where SP pointed when the interrupt came: what the push did and what IntRepair does',
           font=f, fill=(0, 0, 0))
    left, width = 10, W - 20

    def X(addr):
        return left + addr * width // 0x10000
    for lo, hi, col, name, what in REGIONS:
        d.rectangle([X(lo), by, X(hi + 1) - 1, by + bh], fill=col, outline=(0, 0, 0))
    for addr in (0x0000, 0x4000, 0x8000, 0xC000, 0xFE00):
        d.line([X(addr), by + bh, X(addr), by + bh + 6], fill=(0, 0, 0))
        d.text((X(addr) - (40 if addr == 0xFE00 else 0) + 2, by + bh + 8), '$%04X' % addr, font=fs, fill=(0, 0, 0))
    # the top 512 bytes magnified
    zy = by + bh + 50
    d.text((10, zy - 22), '$FE00-$FFFF magnified', font=f, fill=(0, 0, 0))

    def Z(addr):
        return left + (addr - 0xFE00) * width // 0x200
    for lo, hi, col, name, what in REGIONS[2:]:
        d.rectangle([Z(lo), zy, Z(hi + 1) - 1, zy + bh], fill=col, outline=(0, 0, 0))
    d.rectangle([Z(0xFE00), zy, Z(0xFE00) + 2, zy + bh], fill=(0, 0, 0))
    for addr in (0xFE00, 0xFE50, 0xFF00, 0xFF82, 0xFFE4):
        d.line([Z(addr), zy + bh, Z(addr), zy + bh + 6], fill=(0, 0, 0))
        d.text((Z(addr) + 2, zy + bh + 8), '$%04X' % addr, font=fs, fill=(0, 0, 0))
    d.line([X(0xFE00), by + bh, Z(0xFE00), zy], fill=(120, 120, 120))
    d.line([X(0xFFFF) + 1, by + bh, Z(0x10000) - 1, zy], fill=(120, 120, 120))
    # legend
    ly = zy + bh + 40
    for lo, hi, col, name, what in REGIONS:
        users = [u for ulo, uhi, u in USERS if ulo >= lo and uhi <= hi]
        d.rectangle([10, ly + 2, 26, ly + 18], fill=col, outline=(0, 0, 0))
        d.text((34, ly), '$%04X-$%04X  %s: %s' % (lo, hi, name, what), font=fs, fill=(0, 0, 0))
        d.text((34, ly + 18), 'SP there: ' + '; '.join(users), font=fs, fill=(80, 80, 80))
        ly += 42
    im = im.crop((0, 0, W, ly + 4))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

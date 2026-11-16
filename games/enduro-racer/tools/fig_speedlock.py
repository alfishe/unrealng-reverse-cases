#!/usr/bin/env python3
"""SpeedLock 2's signal: the start of the stream and a block boundary, pulse by pulse (doc 03, 3.5).

    python3 tools/fig_speedlock.py [--tzx "work/media/Enduro Racer.tzx"] [--out docs/img/load/speedlock-signal.png]

Reads the TZX with tools/tzxblocks.py's parser and draws the EAR level as the pulses toggle it, in T-states:
  1. the end of the leader of data block 6 (the loading screen): the last tone pulses (2 100 T), a sync pair
     (1 163 / 711 T), the long pair 3 150 / 3 150 and the 6-bit mark %111010 ($3A), then the first byte $6C;
  2. a block boundary, data blocks 6 to 7: the last byte of block 6 ($B5), the 21-bit end mark (875 T pairs for 0,
     1 750 T pairs for 1: 5 zeros, 11 ones, 5 zeros, so the middle 7 bits are $7F) and block 7's first byte.
A bit is two pulses of equal length: 565 T for 0 and 1 130 T for 1 in the data, most significant bit first. Each bit
is labelled under its two pulses.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import tzxblocks  # noqa: E402


def data_pulses(data, zero, one, nbytes, from_end=False):
    sel = data[-nbytes:] if from_end else data[:nbytes]
    out = []
    for b in sel:
        for k in range(8):
            bit = (b >> (7 - k)) & 1
            p = one if bit else zero
            out += [(p, str(bit), '$%02X' % b if k == 0 else None), (p, None, None)]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--tzx', default=os.path.join(CASE, 'work', 'media', 'Enduro Racer.tzx'))
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'speedlock-signal.png'))
    a = ap.parse_args()
    blocks = tzxblocks.parse(open(a.tzx, 'rb').read())
    by = {b['index']: b for b in blocks}
    # panel 1: the last tone pulses of block 134, the pair of 133 is before it; 135 the mark; 136 the data
    p1 = [(by[134]['timing']['pulse'], None, None)] * 6
    p1 += [(p, None, None) for p in by[133]['timing']['pulses']][:0]
    mark = by[135]['timing']['pulses']
    p1 += [(mark[0], 'sync', None), (mark[1], None, None)]
    bits = mark[2:]
    for k in range(0, len(bits), 2):
        p1 += [(bits[k], '1' if bits[k] > 800 else '0', None), (bits[k + 1], None, None)]
    p1 += data_pulses(by[136]['data'], 565, 1130, 1)
    # panel 2: the last byte of block 136, the end mark 137, the first byte of 138
    p2 = data_pulses(by[136]['data'], 565, 1130, 1, from_end=True)
    em = by[137]['timing']['pulses']
    for k in range(0, len(em), 2):
        p2 += [(em[k], '1' if em[k] > 1200 else '0', None), (em[k + 1], None, None)]
    p2 += data_pulses(by[138]['data'], 565, 1130, 1)

    W = 1050
    im = Image.new('RGB', (W, 520), (255, 255, 255))
    d = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(13), kitlib.font(18), kitlib.font(12)
    d.text((10, 8), 'SpeedLock 2 on tape: one leader, then every block in one stream joined by a 21-bit mark',
           font=fb, fill=(0, 0, 0))

    def panel(y, pulses, title, spans):
        total = sum(p for p, _, _ in pulses)
        left, width = 20, W - 40
        d.text((left, y), title, font=f, fill=(0, 0, 0))
        y0 = y + 50
        x, level = left, 1
        for p, bit, byte in pulses:
            x1 = left + (sum_before := x - left) + p * width / total
            ylev = y0 if level else y0 + 40
            d.line([x, ylev, x1, ylev], fill=(30, 30, 30), width=2)
            d.line([x1, y0, x1, y0 + 40], fill=(30, 30, 30), width=1)
            if bit:
                d.text((x + 2, y0 + 46), bit if bit != 'sync' else '', font=fs, fill=(200, 40, 40))
            if byte:
                d.line([x, y0 - 14, x, y0 - 2], fill=(40, 90, 200), width=2)
                d.text((x + 3, y0 - 18), byte, font=fs, fill=(40, 90, 200))
            level ^= 1
            x = x1
            del sum_before
        # spans: (from pulse index, to index, label)
        acc = [left]
        for p, _, _ in pulses:
            acc.append(acc[-1] + p * width / total)
        for i0, i1, label in spans:
            xa, xb = acc[i0], acc[i1]
            d.line([xa, y0 + 70, xb, y0 + 70], fill=(0, 120, 0), width=2)
            d.line([xa, y0 + 64, xa, y0 + 76], fill=(0, 120, 0), width=2)
            d.line([xb, y0 + 64, xb, y0 + 76], fill=(0, 120, 0), width=2)
            d.text((xa + 3, y0 + 78), label, font=fs, fill=(0, 100, 0))
        d.text((left, y0 + 100), '%d T across (%.1f ms at 3.5 MHz)' % (total, total / 3500), font=fs,
               fill=(90, 90, 90))
    n_mark = 2 + len(bits)
    panel(44, p1, '1. The end of the leader of block 6 (TZX blocks 134-136): tone, the long pair, the mark, '
          'the first byte',
          [(0, 6, 'tone, 2 100 T'), (6, 8, '3 150 x 2'), (8, n_mark + 6, 'mark 111010 = $3A'),
           (n_mark + 6, n_mark + 22, 'first byte: $6C, stored as $FF')])
    panel(244, p2, '2. Blocks 6 to 7 (TZX blocks 136-138): the last byte, the end mark, the next block\'s '
          'first byte',
          [(0, 16, 'last byte $B5'), (16, 26, '5 x 0'), (26, 48, '11 x 1: middle 7 bits $7F'),
           (48, 58, '5 x 0'), (58, 74, 'block 7: first byte')])
    d.text((20, 470), 'A bit is two equal pulses: data 565 T = 0, 1 130 T = 1; mark 875 T = 0, 1 750 T = 1. Red: the '
           'bits; blue: each byte\'s first bit.', font=fs, fill=(60, 60, 60))
    d.text((20, 488), 'Read from the TZX by tools/tzxblocks.py\'s parser; the stored values by Store: ((t XOR $98) '
           '+ $0B) AND 255.', font=fs, fill=(60, 60, 60))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

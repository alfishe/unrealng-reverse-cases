#!/usr/bin/env python3
"""Doc 02 figure: the memory heatmap of a window of r1 at about 900 px: the 64 K view as play has it (bank 5 at
$4000, bank 2 at $8000, bank 0 at $C000) large, with the regions named, and the other RAM banks small below it.
(Adapted from the 48K case's tools/fig_heatmap.py: the banks are kept apart, an instruction counts in the bank it
ran in.)

    python3 tools/fig_heatmap.py work/zgsA/r1-play/l1.json docs/img/arch/heatmap-play.png \
        --regions tools/heatmap-regions.txt --title T

The grid is the address space $4000-$FFFF, 192 rows of 256 bytes, $4000 at the top left; the banks below are
$C000-$FFFF each, 64 rows. Colours are log2 of the count over the window (kit/heatmap.py scale()): red written,
green read, blue executed. l1.json's byte_counts are per physical page (RAM 0-7); its instructions carry their page.
"""
import argparse
import importlib.util
import json
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, '..', '..', '..', 'kit')
VIEW = {5: 0x4000, 2: 0x8000, 0: 0xC000}


def kit_module(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(KIT, name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load(path):
    """per RAM page: executes, reads, writes (16 K each)"""
    doc = json.load(open(path))
    pages = {p: ([0] * 0x4000, [0] * 0x4000, [0] * 0x4000) for p in range(8)}
    for z80, page, code, _cls, count, *_ in doc['instructions']:
        if page not in pages:
            continue
        a = int(z80[1:], 16) & 0x3FFF
        for i in range(len(code) // 2):
            if a + i < 0x4000:
                pages[page][0][a + i] += count
    for p in doc['byte_counts']:
        if p['page'] in pages:
            pages[p['page']][1][:] = p['reads']
            pages[p['page']][2][:] = p['writes']
    return pages, doc['replay']


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('l1')
    ap.add_argument('png')
    ap.add_argument('--regions', required=True)
    ap.add_argument('--title', required=True)
    ap.add_argument('--banks', default='1,3,4,6,7', help='the RAM banks drawn small below')
    ap.add_argument('--bank-notes', default='', help='"1=the GS driver;7=..." under each small bank')
    args = ap.parse_args()
    H = kit_module('heatmap')
    K = kit_module('kitlib')
    pages, replay = load(args.l1)
    ex, rd, wr = [0] * 0x10000, [0] * 0x10000, [0] * 0x10000
    for p, base in VIEW.items():
        for i in range(0x4000):
            ex[base + i], rd[base + i], wr[base + i] = pages[p][0][i], pages[p][1][i], pages[p][2][i]
    lo, hi = 0x4000, 0xFFFF
    fx, tx = H.scale(ex, lo, hi)
    fr, tr = H.scale(rd, lo, hi)
    fw, tw = H.scale(wr, lo, hi)
    big = H.panel(lo, hi, 2, lambda a: (int(255 * fw(a)), int(255 * fr(a)), int(255 * fx(a))))
    banks = [int(b) for b in args.banks.split(',') if b]
    notes = dict(n.split('=', 1) for n in args.bank_notes.split(';') if n)
    small = []
    for b in banks:
        e2, r2, w2 = [0] * 0x10000, [0] * 0x10000, [0] * 0x10000
        for i in range(0x4000):
            e2[0xC000 + i], r2[0xC000 + i], w2[0xC000 + i] = pages[b][0][i], pages[b][1][i], pages[b][2][i]
        f2x, _ = H.scale(e2, 0xC000, 0xFFFF)
        f2r, _ = H.scale(r2, 0xC000, 0xFFFF)
        f2w, _ = H.scale(w2, 0xC000, 0xFFFF)
        im = H.panel(0xC000, 0xFFFF, 1, lambda a: (int(255 * f2w(a)), int(255 * f2r(a)), int(255 * f2x(a))))
        touched = sum(1 for i in range(0x4000) if pages[b][0][i] or pages[b][1][i] or pages[b][2][i])
        small.append((b, im, touched, notes.get(str(b), '')))
    f, fb = K.font(12), K.font(15)
    W = 900
    top, left = 52, 54
    out = Image.new('RGB', (W, top + big.height + 600), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), f'red = written, green = read, blue = executed (log2 of the count over '
                     f'{replay["frames"]} frames); one row = 256 bytes', fill=K.DIM, font=f)
    out.paste(big, (left, top))
    for a in range(lo, hi + 1, 0x1000):
        y = top + ((a - lo) >> 8) * 2
        d.text((8, y - 7), f'${a:04X}', fill=K.DIM, font=f)
        d.line([(left - 6, y), (left - 2, y)], fill=K.DIM)
    rx = left + big.width + 6
    regions = []
    for line in open(args.regions):
        parts = line.split(None, 2)
        if len(parts) < 3 or line.startswith('#'):
            continue
        a, b = int(parts[0], 16), int(parts[1], 16)
        y0, y1 = top + ((a - lo) >> 8) * 2, top + ((b - lo) >> 8) * 2 + 1
        name = parts[2].strip()
        name = name if len(name) <= 36 else name[:35] + '.'
        regions.append((y0, y1, f'${a:04X} ' + name))
    last_y = -100
    for y0, y1, text in regions:
        y = max((y0 + y1) // 2 - 7, last_y + 15)
        last_y = y
        d.line([(rx, y0), (rx + 5, y0), (rx + 5, y1), (rx, y1)], fill=(220, 220, 140))
        d.line([(rx + 5, (y0 + y1) // 2), (rx + 14, y + 7)], fill=(150, 150, 110))
        d.text((rx + 16, y), text, fill=(230, 230, 170), font=f)
    y = max(top + big.height, last_y + 16) + 14
    drawn = [b for b in small if b[2]]
    idle = [b for b in small if not b[2]]
    d.text((10, y), f'max on one byte above: executed {tx:,}, read {tr:,}, written {tw:,}', fill=K.DIM, font=f)
    y += 18
    d.text((10, y), 'the other RAM banks, $C000-$FFFF each when paged (1 px a byte):', fill=K.TEXT, font=f)
    x = 10
    for b, im, touched, note in drawn:
        out.paste(im, (x, y + 22))
        d.text((x, y + 26 + im.height), f'bank {b}: {touched:,} bytes touched', fill=K.DIM, font=f)
        if note:
            d.text((x, y + 42 + im.height), note, fill=K.TEXT, font=f)
        x += im.width + 30
        if x + im.width > W:
            x = 10
            y += 22 + im.height + 44
    if drawn and x > 10:
        y += 22 + drawn[0][1].height + 44
    for b, _im, _t, note in idle:
        d.text((10, y), f'bank {b}: not touched' + (f' ({note})' if note else ''), fill=K.DIM, font=f)
        y += 16
    out = out.crop((0, 0, W, y + 10))
    out.save(args.png)
    print(args.png, out.size, replay.get('frames'), 'frames', 'max x/r/w', tx, tr, tw)


if __name__ == '__main__':
    main()

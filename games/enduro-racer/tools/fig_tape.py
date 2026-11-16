#!/usr/bin/env python3
"""The tape as a picture: the 17 data blocks along the 232 s of the tape, and where each lands in memory (doc 03, 3.1).

    python3 tools/fig_tape.py [--tzx "work/media/Enduro Racer.tzx"] [--out docs/img/load/tape.png]

The times come from tools/tzxblocks.py's list of the TZX (each block's play time, pauses included); the
destinations from src/tape/tape.txt (the `sl` blocks' DEST and length, the BlockTable rows). The top band is the
time axis, one colour a kind of block; the bottom band is the memory $4000-$FFFF with each block drawn where the
loader stores it and a line from the block to its place.
"""
import argparse
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402

KIND_COL = {'rom': (120, 170, 230), 'decoy': (190, 190, 190), 'screen': (250, 200, 80), 'game': (230, 90, 80),
            'key': (200, 60, 200), 'tail': (60, 160, 90), 'mover': (40, 40, 40), 'lead': (225, 225, 225)}
# data block number, kind, short label, destination, length stored
BLOCKS = [
    (1, 'rom', 'header enduro', None, 0), (2, 'rom', 'BASIC enduro', 0x5CCB, 205),
    (3, 'rom', 'header end2', None, 0), (4, 'rom', 'BASIC end2 + loader', 0x5CCB, 1770),
    (5, 'decoy', 'decoy', 0xA000, 17), (6, 'screen', 'loading screen', 0x4000, 6912),
    (7, 'game', 'game', 0x70C8, 4608), (8, 'game', 'game', 0xA0C8, 4096), (9, 'key', 'Store key', 0xFE04, 2),
    (10, 'key', 'StoreLast key', 0xFE3C, 4), (11, 'game', 'game', 0x5BC8, 5376), (12, 'tail', 'tail', 0xFF63, 23),
    (13, 'game', 'game', 0xB0C8, 18776), (14, 'tail', 'new end', 0xFF7A, 13), (15, 'mover', 'Mover', 0x5B00, 64),
    (16, 'game', 'game', 0x82C8, 4096), (17, 'game', 'game', 0x92C8, 3584),
]


def block_times(tzx):
    out = subprocess.run([sys.executable, os.path.join(HERE, 'tzxblocks.py'), 'list', tzx], capture_output=True,
                         text=True).stdout
    t, data_ends, starts, cur_start = 0.0, [], [], 0.0
    for line in out.splitlines():
        m = re.search(r'\| ([0-9.]+) s$', line)
        if ' id 10 ' in line or ' id 14 ' in line:
            secs = float(m.group(1))
            pause = re.search(r'pause (\d+) ms', line)
            p = int(pause.group(1)) / 1000 if pause else 0
            starts.append((cur_start, t + secs))
            data_ends.append((t, t + secs))
            t += secs + p
            cur_start = t
        elif m:
            t += float(m.group(1))
        tot = re.match(r'total ([0-9.]+) s', line)
        if tot:
            t = float(tot.group(1))
    return data_ends, starts, t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--tzx', default=os.path.join(CASE, 'work', 'media', 'Enduro Racer.tzx'))
    ap.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'tape.png'))
    a = ap.parse_args()
    spans, lead, total = block_times(a.tzx)
    width, left, right = 1050, 20, 20
    w = width - left - right
    im = Image.new('RGB', (width, 520), (255, 255, 255))
    d = ImageDraw.Draw(im)
    f, fb, fs = kitlib.font(13), kitlib.font(18), kitlib.font(12)
    d.text((8, 6), 'The tape: 4 ROM blocks, then 13 SpeedLock 2 blocks in one stream; where each one lands',
           font=fb, fill=(0, 0, 0))
    ty = 70
    d.text((left, ty - 22), 'time at signal speed (s)', font=f, fill=(0, 0, 0))

    def tx(t):
        return left + int(t * w / total)
    d.rectangle([tx(0), ty, tx(total), ty + 34], fill=KIND_COL['lead'], outline=(120, 120, 120))
    for (n, kind, label, dest, length), (t0, t1), (l0, _l1) in zip(BLOCKS, spans, lead):
        d.rectangle([tx(t0), ty, max(tx(t1), tx(t0) + 2), ty + 34], fill=KIND_COL[kind], outline=(0, 0, 0))
        if tx(t1) - tx(t0) > 18:
            d.text((tx(t0) + 3, ty + 10), str(n), font=fs, fill=(255, 255, 255) if kind in ('game', 'mover') else (0, 0, 0))
    for s in range(0, int(total) + 1, 20):
        d.line([tx(s), ty + 34, tx(s), ty + 40], fill=(0, 0, 0))
        d.text((tx(s) - 8, ty + 42), str(s), font=fs, fill=(0, 0, 0))
    # the short blocks 9-12, 14, 15 labelled above
    small = [(n, t0) for (n, kind, label, dest, length), (t0, t1) in zip(BLOCKS, spans) if t1 - t0 < 1.0 and n > 4]
    for k, (n, t0) in enumerate(small):
        x = tx(t0)
        y = ty - 4 - 14 * (k % 2) - 12
        d.line([x, ty, x, y + 12], fill=(0, 0, 0))
    labels = ', '.join(str(n) for n, _ in small)
    d.text((tx(132), ty - 22), 'short blocks %s (keys, tail, Mover): ticks above' % labels, font=fs, fill=(60, 60, 60))
    # memory band
    my = 230
    d.text((left + 120, my + 62), 'memory $4000-$FFFF: where the loader stores each block', font=f, fill=(0, 0, 0))

    def mx(addr):
        return left + int((addr - 0x4000) * w / 0xC000)
    d.rectangle([mx(0x4000), my, mx(0x10000), my + 40], fill=(245, 245, 245), outline=(120, 120, 120))
    for (n, kind, label, dest, length), (t0, t1) in zip(BLOCKS, spans):
        if dest is None or dest < 0x4000:
            continue
        x0, x1 = mx(dest), max(mx(dest + length), mx(dest) + 2)
        d.rectangle([x0, my, x1, my + 40], fill=KIND_COL[kind], outline=(0, 0, 0))
        d.line([(tx(t0) + tx(t1)) // 2, ty + 58, (x0 + x1) // 2, my - 4], fill=KIND_COL[kind], width=2)
        if x1 - x0 > 30:
            d.text((x0 + 3, my + 4), str(n), font=fs, fill=(255, 255, 255) if kind in ('game', 'mover') else (0, 0, 0))
            d.text((x0 + 3, my + 22), '$%04X' % dest, font=fs, fill=(255, 255, 255) if kind == 'game' else (0, 0, 0))
    for addr in range(0x4000, 0x10001, 0x2000):
        d.line([mx(addr), my + 40, mx(addr), my + 46], fill=(0, 0, 0))
        d.text((mx(addr) - 18, my + 48), '$%04X' % (addr & 0xFFFF if addr < 0x10000 else 0xFFFF), font=fs,
               fill=(0, 0, 0))
    # after Mover
    ay = 350
    d.text((left, ay - 22), 'after Mover ($5B09 LDDR, BC = 40 540): the game image $5B00-$FFFF as it runs',
           font=f, fill=(0, 0, 0))
    d.rectangle([mx(0x4000), ay, mx(0x10000), ay + 40], fill=(245, 245, 245), outline=(120, 120, 120))
    d.rectangle([mx(0x4000), ay, mx(0x5B00), ay + 40], fill=KIND_COL['screen'], outline=(0, 0, 0))
    d.rectangle([mx(0x61A4), ay, mx(0x10000), ay + 40], fill=KIND_COL['game'], outline=(0, 0, 0))
    d.rectangle([mx(0x5B00), ay, mx(0x61A4), ay + 40], fill=(200, 200, 200), outline=(0, 0, 0))
    d.text((mx(0x5B00) + 2, ay + 44), '$5B00-$61A3: Mover, then work space', font=fs, fill=(0, 0, 0))
    d.text((mx(0x61A4) + 60, ay + 12), '$61A4-$FFFF: the moved block (was $5BC4-$FA1F)', font=f, fill=(255, 255, 255))
    for (lo, hi) in [(0x5BC4, 0xFA1F)]:
        d.line([mx(lo), my + 46 + 14, mx(lo + 0x5E0), ay - 2], fill=(0, 0, 0), width=1)
        d.line([mx(hi), my + 46 + 14, mx(hi + 0x5E0), ay - 2], fill=(0, 0, 0), width=1)
    # legend
    ly = 440
    x = left
    names = {'rom': 'ROM block (LD-BYTES)', 'decoy': 'decoy (ROM bytes)', 'screen': 'loading screen',
             'game': 'game code and data', 'key': 'new loader keys', 'tail': "loader's new end", 'mover': 'Mover',
             'lead': 'leaders, marks, pauses'}
    for kind, col in KIND_COL.items():
        label = names[kind]
        tw = int(d.textlength(label, font=f))
        if x + 22 + tw > width - 10:
            x, ly = left, ly + 22
        d.rectangle([x, ly + 2, x + 14, ly + 14], fill=col, outline=(0, 0, 0))
        d.text((x + 20, ly), label, font=f, fill=(0, 0, 0))
        x += 34 + tw
    d.text((left, ly + 30), 'total %.1f s = %d frames at 50 Hz; numbers are the data blocks of doc 03 3.1' %
           (total, round(total * 50)), font=fs, fill=(60, 60, 60))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    im = im.crop((0, 0, width, ly + 52))
    im.save(a.out)
    print(a.out, im.size)


if __name__ == '__main__':
    main()

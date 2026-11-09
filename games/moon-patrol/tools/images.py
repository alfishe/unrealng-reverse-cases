#!/usr/bin/env python3
"""The three images of the game, read from the power-on recording c1 (fast load) as 64 K files (the ROM included):
the image as loaded (frame 252 T 0: the tape block has landed, the BASIC's CLEAR 49999 not yet run), the image at
the game's entry (frame 256 T 58497, the first instruction of $8000) and a play-time image (default frame 8000 T 0,
Beginner course play). Then the byte ranges that differ between them, over the game's bytes $60F8-$FFFF.

    python3 tools/images.py --work work/stage1/c1x --out work/images [--play 8000]
"""
import argparse
import os

import mplib as M


def ranges(a, b, lo=0x60F8, hi=0x10000):
    out, start = [], None
    for i in range(lo, hi):
        if a[i] != b[i]:
            if start is None:
                start = i
        elif start is not None:
            out.append((start, i - 1))
            start = None
    if start is not None:
        out.append((start, hi - 1))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--play', default='8000:0')
    args = p.parse_args()
    s = M.session(args.work)
    os.makedirs(args.out, exist_ok=True)
    moments = {'loaded': (252, 0), 'entry': (256, 58497), 'play': tuple(int(x) for x in args.play.split(':'))}
    imgs = {}
    for name, (f, t) in moments.items():
        imgs[name] = M.read(s, f, 0, 0x10000, t)
        path = os.path.join(args.out, '%s-%d-%d.bin' % (name, f, t))
        open(path, 'wb').write(imgs[name])
        print('wrote', path)
    for x, y in (('loaded', 'entry'), ('entry', 'play')):
        rs = ranges(imgs[x], imgs[y])
        print('%s -> %s: %d bytes in %d ranges' % (x, y, sum(b - a + 1 for a, b in rs), len(rs)))
        for a, b in rs:
            print('  $%04X-$%04X %5d' % (a, b, b - a + 1))


if __name__ == '__main__':
    main()

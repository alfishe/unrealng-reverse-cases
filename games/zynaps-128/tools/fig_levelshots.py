#!/usr/bin/env python3
"""Doc 01 figures: the level counter over a recording, and one screenshot of each of the 12 levels with a sheet.

    python3 tools/fig_levelshots.py scan --work work/z128A/r3 --to 76000 [--every 250] > work/z128A/r3-levels.tsv
    python3 tools/fig_levelshots.py shots --work work/z128A/r3 --frames F1,F2,...,F12 --out-dir docs/img/design

scan: the player 1 record (`$7F9C`: +0-+3 score BCD, +4 lives, +6 the level counter) and LevelOrder (`$8003`) every
--every frames, then the exact first frame of each new counter value (a binary search between two samples).
shots: for each frame the screen and the record of that same frame, so the label's level is the one the game
played (LevelOrder[counter]), not assumed; writes level-NN-L.png (2x, NN the play order 01-12, L the level) and
levels-sheet.png (all twelve, labelled).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_lib as Z  # noqa: E402

K = Z.K


def counter_at(s, f):
    return Z.read(s, f, Z.P1 + 6, 1)[0]


def scan(args):
    s = Z.session(args.work)
    prev, prev_f = None, None
    print('counter\tlevel\tfirst_frame\tscore\tlives\tdeaths')
    for f in range(args.start, args.to + 1, args.every):
        c = counter_at(s, f)
        if c != prev:
            lo, hi = (prev_f, f) if prev_f is not None else (f, f)
            while hi - lo > 1:
                mid = (lo + hi) // 2
                if counter_at(s, mid) == c:
                    hi = mid
                else:
                    lo = mid
            st = Z.state(s, hi)
            print(f"{c}\t{st['level']}\t{hi}\t{st['score']}\t{st['lives']}\t{st['deaths']}", flush=True)
            prev = c
        prev_f = f


def shots(args):
    s = Z.session(args.work)
    os.makedirs(args.out_dir, exist_ok=True)
    frames = [int(x) for x in args.frames.split(',')]
    f, fb = K.font(13), K.font(16)
    cols, cw, ch = 3, 288, 216 + 22
    sheet = Image.new('RGB', (10 + cols * (cw + 10), 64 + 4 * (ch + 8)), K.BACKGROUND)
    d = ImageDraw.Draw(sheet)
    order = Z.state(s, frames[0])['order']
    d.text((10, 8), 'All 12 levels in r3\'s order: 0 1 2, ' + ' '.join(map(str, order[3:9])) +
           ' (LevelOrder $8003 slots 3-8), 9 10 11', fill=K.TEXT, font=fb)
    d.text((10, 32), 'each label: #play order, level (LevelOrder[counter]), r3 frame, score; Pentagon 128, 0 deaths',
           fill=K.DIM, font=f)
    for i, fr in enumerate(frames):
        st = Z.state(s, fr)
        sc = Z.screen(s, fr)
        name = f"level-{st['counter'] + 1:02d}-{st['level']}.png"
        sc.resize((512, 384), Image.NEAREST).save(os.path.join(args.out_dir, name))
        x, y = 10 + (i % cols) * (cw + 10), 58 + (i // cols) * (ch + 8)
        sheet.paste(sc.resize((cw, 216), Image.NEAREST), (x, y + 20))
        d.text((x, y + 2), f"#{st['counter'] + 1} level {st['level']}  frame {fr}  score {st['score']}",
               fill=K.TEXT, font=f)
        print(name, fr, st)
    sheet.save(os.path.join(args.out_dir, 'levels-sheet.png'))
    print(os.path.join(args.out_dir, 'levels-sheet.png'), sheet.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('scan')
    a.add_argument('--work', required=True)
    a.add_argument('--start', type=int, default=200)
    a.add_argument('--to', type=int, required=True)
    a.add_argument('--every', type=int, default=250)
    b = sub.add_parser('shots')
    b.add_argument('--work', required=True)
    b.add_argument('--frames', required=True)
    b.add_argument('--out-dir', required=True)
    args = p.parse_args()
    scan(args) if args.cmd == 'scan' else shots(args)


if __name__ == '__main__':
    main()

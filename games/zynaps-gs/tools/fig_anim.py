#!/usr/bin/env python3
"""Docs 01, 03, 05, 06: a GIF of the screen over a stretch of a recording, with a title and a readout of the game's
state under each picture, read from the same frame's memory.

    python3 tools/fig_anim.py --work work/zgsA/r1 --from 2990 --to 3390 --step 2 --info play \
        --title T --out docs/img/render/play-level1.gif
    python3 tools/fig_anim.py --dir work/zgsA/tour/L05 --info play --title T --out docs/img/render/play-level5.gif

--work: frames of a TTD recording (time_travel memory_at, cached in W/mem). --dir: a live capture of
tools/cap_tour.py (NNNNNN.scr the screen, NNNNNN.var the bytes $7F00-$80FF of the same frame).
--info play: player 1's record $7F9C (+0..+3 score in BCD, +4 lives, +6 the level counter) and LevelOrder $8003
(the level the counter names); --info none: the frame only.
"""
import argparse
import glob
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K


def frames_of(args):
    if args.dir:
        out = []
        for path in sorted(glob.glob(os.path.join(args.dir, '*.scr'))):
            n = int(os.path.basename(path)[:-4])
            if args.start is not None and not args.start <= n <= args.end:
                continue
            var = path[:-4] + '.var'
            out.append((n, open(path, 'rb').read(), open(var, 'rb').read() if os.path.exists(var) else None))
        return out[::args.step]
    out = []
    for f in range(args.start, args.end + 1, args.step):
        scr = Z.cached(args.work, f)
        var = Z.cached(args.work, f, 0x7F00, 0x200) if args.info == 'play' else None
        out.append((f, scr, var))
    return out


def info(var):
    rec = var[0x9C:0xAC]
    order = var[0x103:0x10F]
    counter = rec[6]
    level = order[counter] + 1 if counter < 12 else '?'
    return f'level counter {counter} = level {level}   score {rec[0:4].hex()}   lives {rec[4]}'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work')
    p.add_argument('--dir')
    p.add_argument('--from', dest='start', type=int)
    p.add_argument('--to', dest='end', type=int)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--info', choices=['play', 'none'], default='none')
    p.add_argument('--title', required=True)
    p.add_argument('--note', default='', help='a second title line')
    p.add_argument('--label', default=None, help='the recording\'s name under the picture')
    p.add_argument('--delay', type=int, default=60)
    p.add_argument('--scale', type=int, default=2)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    f, fb = K.font(12), K.font(15)
    pictures = []
    label = args.label or os.path.basename(os.path.normpath(args.work or args.dir))
    W, H = 256 * args.scale, 192 * args.scale
    top = 34 + (18 if args.note else 0)
    for n, scr, var in frames_of(args):
        im = Image.new('RGB', (W + 20, top + H + 44), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        d.text((10, 8), args.title, fill=K.TEXT, font=fb)
        if args.note:
            d.text((10, 28), args.note, fill=K.DIM, font=f)
        im.paste(Z.render(scr, args.scale), (10, top))
        y = top + H + 6
        d.text((10, y), f'{label} frame {n}', fill=K.DIM, font=f)
        if args.info == 'play' and var:
            d.text((10, y + 16), info(var), fill=K.TEXT, font=f)
        pictures.append(im)
    durations = [args.delay] * len(pictures)
    durations[0] = 1000
    durations[-1] = 2000
    K.save_gif(args.out, pictures, durations)
    print(args.out, len(pictures), pictures[0].size, os.path.getsize(args.out))


if __name__ == '__main__':
    main()

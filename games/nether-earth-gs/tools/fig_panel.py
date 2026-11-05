#!/usr/bin/env python3
"""Doc 08 figure: the status panel through a whole game, one crop every two game days (docs/img/hud/panel-days.png).

    python3 tools/fig_panel.py --cache work/gsB/cache/rT30.npz --out docs/img/hud/panel-days.png [--every 2]

The cache is `tools/fig_events.py sample` ($4000-$FFFF at each sampled frame). For each game day 0, 2, 4 ... the
first sample of that day where `PanelBusy` (`$FD39`) is 0 is taken, so no robot menu covers the panel. Each crop is
screen columns 22-31, all 24 rows, at 2x; under it the day, the frame and the counts read from `$FD3A` (ours) and
`$FD42` (the enemy's), which the panel prints.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

S = 2


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--cache', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--every', type=int, default=2)
    args = p.parse_args()
    z = np.load(args.cache, allow_pickle=True)
    frames, mems = list(z['frames']), z['mems']

    picks, seen = [], set()
    for i, f in enumerate(frames):
        m = bytes(0x4000) + bytes(mems[i])
        day = m[0xFD37] | m[0xFD38] << 8
        if day % args.every or day in seen or m[0xFD39]:
            continue
        seen.add(day)
        picks.append((f, day, m))
    m = bytes(0x4000) + bytes(mems[-1])
    picks.append((frames[-1], m[0xFD37] | m[0xFD38] << 8, m))

    cw, ch, gap = 80 * S, 192 * S, 14
    top, foot = 70, 74
    W = gap + len(picks) * (cw + gap)
    H = top + ch + foot + 70
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, small = K.font(16), K.font(11)
    last = picks[-1][2]
    top_ours = max(sum(m[0xFD3B:0xFD41]) for _, _, m in picks)
    d.text((gap, 8), f'The panel through the game: the enemy (left digits) climbs to {sum(last[0xFD43:0xFD49])} '
           f'factories, ours never pass {top_ours}', fill=K.TEXT, font=big)
    d.text((gap, 32), f'{os.path.basename(os.path.dirname(args.cache))}/{os.path.basename(args.cache)}: screen '
           f'columns 22-31 at {S}x, the first sample of every {args.every} game days with PanelBusy ($FD39) = 0, '
           'and the last sample', fill=K.DIM, font=small)
    d.text((gap, 48), 'left digit column: the enemy (INSG); right: ours (HUMN); the resources at the bottom are ours '
           'only', fill=K.DIM, font=small)
    for k, (f, day, m) in enumerate(picks):
        x = gap + k * (cw + gap)
        crop = K.render_screen(m).crop((22 * 8, 0, 256, 192)).resize((cw, ch), Image.NEAREST)
        im.paste(crop, (x, top))
        ours, theirs = m[0xFD3A:0xFD42], m[0xFD42:0xFD4A]
        lines = [f'day {day}  {m[0xFD36]:02d}:{m[0xFD35]:02d}', f'frame {f}',
                 f'wb {ours[0]}:{theirs[0]}', f'fact {sum(ours[1:7])}:{sum(theirs[1:7])}',
                 f'robots {ours[7]}:{theirs[7]}', f'general {m[0xFD22]}']
        for j, t in enumerate(lines):
            d.text((x, top + ch + 4 + 12 * j), t, fill=K.TEXT if j == 0 else K.DIM, font=small)
    cmd = (f'python3 tools/fig_panel.py --cache {os.path.relpath(args.cache, os.path.join(HERE, ".."))} '
           f'--out {os.path.relpath(args.out, os.path.join(HERE, ".."))}')
    d.text((gap, H - 40), 'under each crop: the clock, the frame, warbases / factories / robots ours:enemy from '
           '$FD3A / $FD42, our general ($FD22)', fill=K.DIM, font=small)
    d.text((gap, H - 22), cmd, fill=K.DIM, font=small)
    im.save(args.out)
    print(args.out, im.size, [(f, day) for f, day, _ in picks])


if __name__ == '__main__':
    sys.exit(main())

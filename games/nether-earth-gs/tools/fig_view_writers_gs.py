#!/usr/bin/env python3
"""Doc 06 figure: who drew each byte of the view buffer in one DrawView (docs/img/writers-view.png).

    python3 tools/fig_view_writers_gs.py --trace work/gsA/deep/traces/2502_17000-2510_0.uatr \
        --listing work/gsA/game.lst --out docs/img/render/writers-view.png

Left: the view buffer `$5B00` at the end of the call, in the screen's colours. Right: the same 160 x 160 pixels, each
byte (8 pixels) coloured by the stage of DrawView that wrote it last: the clear, the corner fill, the edge strips or
a sprite. The trace is kit/routine_anim.py's cache of the call (no emulator needed).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

VIEW, WIDTH, LINES = 0x5B00, 20, 160
STAGES = [  # routine of the writing loop, colour, what it means
    ('ClearPushLoop', '#6a6e80', 'cleared only: nothing drawn over it (paper)'),
    ('CornerByteLoop', '#5c8fd6', 'the corner fill: outside the map, top left'),
    ('StripRowLoop', '#d9a441', 'the edge strips: the map\'s staircase edge'),
    ('SpriteByteLoop', '#4caf50', 'a sprite: blocks, buildings, robots, shadow'),
]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--listing', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--unreal')
    args = p.parse_args()
    trace = K.access_trace(args.unreal).load(args.trace)
    lst = K.listing(args.listing)
    last = {}
    writes = {name: 0 for name, _, _ in STAGES}
    value = {}
    for x in trace.instructions:
        for c in x.cycles:
            if c.tag == 'W' and VIEW <= c.address < VIEW + WIDTH * LINES:
                r = lst.routine(x.pc)
                last[c.address] = r
                value[c.address] = c.value
                if r in writes:
                    writes[r] += 1
    index = {name: k for k, (name, _, _) in enumerate(STAGES)}
    stage = np.zeros((LINES, WIDTH * 8), dtype=int)
    pixels = np.zeros((LINES, WIDTH * 8, 3))
    paper, ink = np.array(K.ink_colour(6, True)) / 255, np.zeros(3)
    counts = {name: 0 for name, _, _ in STAGES}
    for line in range(LINES):
        for b in range(WIDTH):
            a = VIEW + WIDTH * line + b
            name = last.get(a)
            if name in counts:
                counts[name] += 1
            stage[line, 8 * b:8 * b + 8] = index.get(name, 0)
            v = value.get(a, 0)
            for bit in range(8):
                pixels[line, 8 * b + bit] = ink if v & (0x80 >> bit) else paper
    total = sum(counts.values())
    print('last writer', counts, 'writes', writes, 'bytes', total)

    colours = np.array([matplotlib.colors.to_rgb(c) for _, c, _ in STAGES])
    coloured = colours[stage]
    ink_mask = pixels.sum(axis=2) == 0
    coloured[ink_mask] = coloured[ink_mask] * 0.5

    fig = plt.figure(figsize=(10.5, 6.0), dpi=100)
    fig.patch.set_facecolor('#15161b')
    ax = fig.add_axes([0.02, 0.2, 0.40, 0.68])
    bx = fig.add_axes([0.45, 0.2, 0.40, 0.68])
    for a, im, label in ((ax, pixels, 'the view as the call left it'),
                         (bx, coloured, 'the stage that wrote each byte last (ink darker)')):
        a.imshow(im, interpolation='nearest')
        a.set_xticks([])
        a.set_yticks([])
        for s in a.spines.values():
            s.set_color('#444')
        a.set_xlabel(label, color='#b8bcc8', fontsize=10)
    handles = [Patch(color=c, label=f'{text}: {counts[name]} bytes') for name, c, text in STAGES]
    fig.legend(handles=handles, loc='lower left', bbox_to_anchor=(0.02, 0.0), ncol=2, fontsize=9.5, frameon=False,
               labelcolor='#d6d8e0')
    fig.text(0.02, 0.95, f'One DrawView: all {total} bytes are cleared first; '
             f'{counts["SpriteByteLoop"]} of them are then drawn over by sprites', color='#e8e8ee', fontsize=12.5)
    fig.text(0.02, 0.91, f'the clear wrote {writes["ClearPushLoop"]} times (every byte once), the sprites '
             f'{writes["SpriteByteLoop"]} times (overlapping sprites write a byte again); work/gsA/deep frames 2502-2509',
             color='#b8bcc8', fontsize=9.5)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor())


if __name__ == '__main__':
    sys.exit(main())

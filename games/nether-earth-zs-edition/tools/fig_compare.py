#!/usr/bin/env python3
"""Nether Earth, ZS'98 and ZS'99 side by side at the same moment: docs/img/compare/*.png.

    python3 tools/fig_compare.py [--port-base 16530]

Three panels a figure, real frames of the recordings (tools/fig_common.py: our own unreal-qt, time_travel seek, the
WebAPI screen capture), 1x, a short title over each panel, nothing drawn over the pictures. Nether Earth's frames are
from the nether-earth case's recording work/play (48K, the tape load, the menu and play); the ZS ones from stage 1's
r98 and r99 (Pentagon 128 + TR-DOS). No recording reaches an end screen (a won or lost game), so there is no end
figure.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_common as F  # noqa: E402

OUT = os.path.join(F.ROOT, 'docs', 'img', 'compare')

# name: [(recording, frame, title), ...]
FIGURES = {
    'loading': [('ne-play', 5000, 'Nether Earth: the tape loads'),
                ('r98', 3000, "ZS'98: the intro"),
                ('r99', 1002, "ZS'99: the intro, loading")],
    'menu': [('ne-play', 12750, 'Nether Earth: the menu'),
             ('r98', 4703, "ZS'98: the menu"),
             ('r99', 3002, "ZS'99: the start-up menu")],
    'play': [('ne-play', 12900, 'Nether Earth: play'),
             ('r98', 5000, "ZS'98: play"),
             ('r99', 6150, "ZS'99: play (NELEV_00)")],
}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--port-base', type=int, default=16530)
    args = p.parse_args()
    os.makedirs(OUT, exist_ok=True)
    with F.Recordings(args.port_base) as rec:
        for name, panels in FIGURES.items():
            images = [rec.frame(r, f) for r, f, _t in panels]
            path = os.path.join(OUT, name + '.png')
            F.titled_row(images, [t for _r, _f, t in panels]).save(path)
            print(path, [(r, f) for r, f, _t in panels])


if __name__ == '__main__':
    main()

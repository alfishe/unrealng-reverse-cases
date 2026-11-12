#!/usr/bin/env python3
"""A recording's screen at a sampled frame as a PNG (the capture keeps screens/NNNNNN.scr every 250 frames), or a
frame of an RZX log's screens.bin (work/stage1/rzx/lN, one screen every 25 frames) with --rzx.

    python3 tools/shot.py work/stage1/REC FRAME docs/img/play/NAME.png [--scale 2]
    python3 tools/shot.py --rzx work/stage1/rzx/l5 FRAME docs/img/play/NAME.png
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import zxscreen  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rec')
    ap.add_argument('frame', type=int)
    ap.add_argument('out')
    ap.add_argument('--scale', type=int, default=2)
    ap.add_argument('--rzx', action='store_true')
    a = ap.parse_args()
    if a.rzx:
        with open(os.path.join(a.rec, 'screens.bin'), 'rb') as f:
            f.seek(a.frame // 25 * 6912)
            scr = f.read(6912)
    else:
        scr = open(os.path.join(a.rec, 'screens', f'{a.frame:06d}.scr'), 'rb').read()
    zxscreen.render(scr, a.scale).save(a.out)


if __name__ == '__main__':
    main()

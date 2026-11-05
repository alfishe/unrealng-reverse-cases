#!/usr/bin/env python3
"""Single screens of the GS conversion for docs/img/screens/: real emulator frames from tools/fig_capture.py, the whole
352 x 288 frame (the border shows the loaders), scaled 2x with nearest neighbour, nothing drawn on them.

    python3 tools/fig_capture.py                 # the frames, into work/stage2/shots (a few minutes)
    python3 tools/fig_screens.py [--shots work/stage2/shots] [--out docs/img/screens]

The frame names (OUT/a/...) and the moments they stand for are in fig_capture.py; the docs captions name them.
"""
import argparse
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCALE = 2

# output name: (frame under --shots, what it shows)
SCREENS = {
    'scl-loading.png': ('a/scl-c-loading.png', 'SCL, RUN "neart GS": the loading screen (neart000) while the files load'),
    'trd-boot-menu.png': ('a/trd-b-boot.png', 'TRD, RUN: the HRUM boot menu (0-boot, 1-neart GS, 2-Neart481, 3-Neart482)'),
    'trd-loading-gs512.png': ('a/trd-gs-a.png', 'TRD, entry 1: the loading screen with the GS-512 label'),
    'trd-neart482.png': ('a/n482-c.png', 'TRD, entry 3 (Neart482): the RAPEWARE CORP intro, scroller and level bars'),
    'trd-neart481.png': ('a/n481-d.png', 'TRD, entry 2 (Neart481): the loading screen of a cracked build; it stops here'),
    'tap-tape-loader.png': ('a/tl-a.png', 'TAP from the 128 menu\'s Tape Loader: "Program: NetherE GS"'),
    'tap-music-choice.png': ('a/tl-b.png', 'TAP: the music ON / OFF choice of Hood\'s loader'),
    'tap-usr0.png': ('a/u-d.png', 'TAP, the way that works on a 128K: 128 BASIC, PRINT USR 0, then LOAD ""'),
    'tap-loading.png': ('a/u-f.png', 'TAP: the loading screen with GS-512 arriving from tape'),
    'tap-hang.png': ('a/tl-hang.png', 'TAP from the Tape Loader: frozen on the warbase pad at the first sound in play'),
}


def frame(shots, name):
    """a captured frame, RGB, 2x nearest neighbour"""
    im = Image.open(os.path.join(shots, name)).convert('RGB')
    return im.resize((im.width * SCALE, im.height * SCALE), Image.NEAREST)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--shots', default=os.path.join(ROOT, 'work', 'stage2', 'shots'))
    ap.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'screens'))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for out, (src, what) in SCREENS.items():
        frame(a.shots, src).save(os.path.join(a.out, out), optimize=True)
        print('%-24s %-22s %s' % (out, src, what))


if __name__ == '__main__':
    main()

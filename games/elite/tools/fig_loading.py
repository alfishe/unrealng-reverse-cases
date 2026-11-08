#!/usr/bin/env python3
"""Doc 03 figure: the loading screens of both sides, decoded straight from the tape (no emulator).

    python3 tools/fig_loading.py [--out docs/img/loading-screen.png]

The screen is the first 6912 bytes of the Softlock turbo block after its flag, each TZX byte bit-reversed
(tools/softlock.py). Side A and Side B carry the same screen; the figure shows Side A at 2x and says whether B differs.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import softlock as S  # noqa: E402
import elitelib as E  # noqa: E402,F401
from kitlib import render_screen  # noqa: E402


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(E.CASE, 'docs', 'img', 'loading-screen.png'))
    a = p.parse_args()
    sa, sb = S.screen('A'), S.screen('B')
    m = bytearray(0x10000)
    m[0x4000:0x4000 + 6912] = sa
    img = render_screen(m)
    img = img.resize((512, 384))
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    img.save(a.out)
    print(a.out, 'side B same screen' if sa == sb else 'side B differs')


if __name__ == '__main__':
    sys.exit(main())

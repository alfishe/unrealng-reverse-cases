#!/usr/bin/env python3
"""Two or more screenshots side by side with labels, a title and notes (1050 px wide).

    python3 tools/fig_pair.py OUT.png --title T [--note N ...] A.png "label A" B.png "label B" ...
"""
import argparse

import figlib


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--title', default='')
    ap.add_argument('--note', action='append', default=[])
    ap.add_argument('--cols', type=int, default=2)
    ap.add_argument('items', nargs='+')
    a = ap.parse_args()
    it = a.items
    pics = [(figlib.screen_png(it[i]), it[i + 1].split('|')) for i in range(0, len(it), 2)]
    cw = (1050 - 20 - (a.cols - 1) * 10) // a.cols
    ch = int(cw * pics[0][0].height / pics[0][0].width)
    figlib.sheet(pics, a.cols, cw, ch, title=a.title, label_h=40, gap=10, notes=a.note).save(a.out)
    print(a.out)


if __name__ == '__main__':
    main()

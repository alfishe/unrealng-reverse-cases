#!/usr/bin/env python3
"""Cut a wide figure into two at column X, so that each half reads at 900 px (e.g. kit/heatmap.py's four panels:
executed and read on the left, written and the composite on the right).

    python3 tools/fig_split.py IN.png X LEFT.png RIGHT.png
"""
import sys

from PIL import Image

src, x, left, right = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
im = Image.open(src)
im.crop((0, 0, x, im.size[1])).save(left)
im.crop((x, 0, im.size[0], im.size[1])).save(right)
print(left, x, right, im.size[0] - x)

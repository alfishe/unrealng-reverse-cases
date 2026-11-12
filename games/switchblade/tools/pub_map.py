#!/usr/bin/env python3
"""Compare a published screenshot map (30 x 20 rooms of 240 x 176) with the game's map tables ($70C7 counts, $70DB
starts, $7048 columns in build/game.bin, origin $5C00): which rooms the published map shows and which it lacks.

    python3 -I tools/pub_map.py build/game.bin work/review/fixA/dl/Switchblade_3.png (from spectrumcomputing.co.uk/pub/sinclair/games-maps/s/)
"""
import sys

from PIL import Image

b = open(sys.argv[1], 'rb').read()
m = lambda a: b[a - 0x5C00]  # noqa: E731
pos = {}
for row in range(20):
    for i in range(m(0x70C7 + row)):
        k = m(0x70DB + row) + i
        pos[k + 1] = (row, m(0x7048 + k))
im = Image.open(sys.argv[2]).convert('L')
W, H = im.size[0] / 30, im.size[1] / 20
lit = set()
for r in range(20):
    for c in range(30):
        box = im.crop((int(c * W), int(r * H), int((c + 1) * W), int((r + 1) * H))).resize((24, 17))
        if sum(1 for p in box.getdata() if p > 40) > 20:
            lit.add((r, c))
ours = set(pos.values())
print(f'{sys.argv[2]}: {len(lit)} lit cells; {len(lit & ours)} of the 127 rooms shown;',
      'rooms missing:', sorted(r for r, p in pos.items() if p not in lit),
      '; lit cells with no room (labels):', sorted(lit - ours))

#!/usr/bin/env python3
"""The "Presents" animation's frames (src/intro/presents, PresentsFrames $669D-$D49C) as one PNG, both ways.

    python3 tools/intro_presents.py to-png FRAMES.bin OUT.png
    python3 tools/intro_presents.py to-bin IN.png OUT.bin

FRAMES.bin: 16 frames of 1760 bytes, each 80 pixel lines of 22 bytes, top line first, bytes left to right, bit 7 the
leftmost pixel (the order PresentsShow's POPs take them: 11 words a line, low byte left). The PNG: 176 x 1280,
indexed, 2 colours (0 paper black, 1 ink bright green, the part's attribute $44), the 16 frames one under another
in play order. Any 2-entry indexed PNG of that size converts back; the sheet's size is fixed by the code (80 lines
of 22 bytes, PresentsBuildShow) and by the 16 entries of PresentsFrameTable.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from intro_screen import png_read, png_write  # noqa: E402

WIDTH, LINES, FRAMES = 22, 80, 16


def to_png(data, path):
    if len(data) != WIDTH * LINES * FRAMES:
        sys.exit('frames: %d bytes, not %d' % (len(data), WIDTH * LINES * FRAMES))
    rows = []
    for y in range(LINES * FRAMES):
        line = data[y * WIDTH:(y + 1) * WIDTH]
        rows.append([b >> (7 - bit) & 1 for b in line for bit in range(8)])
    png_write(path, WIDTH * 8, LINES * FRAMES, rows, [(0, 0, 0), (0, 0xFF, 0)], {})


def to_bin(path):
    width, height, rows, _ = png_read(path)
    if (width, height) != (WIDTH * 8, LINES * FRAMES):
        sys.exit('%s: %d x %d, not %d x %d' % (path, width, height, WIDTH * 8, LINES * FRAMES))
    out = bytearray()
    for y, row in enumerate(rows):
        for x in range(0, width, 8):
            b = 0
            for bit in range(8):
                v = row[x + bit]
                if v > 1:
                    sys.exit('%s: pixel (%d, %d) has index %d, not 0 or 1' % (path, x + bit, y, v))
                b |= v << (7 - bit)
            out.append(b)
    return bytes(out)


def main():
    if len(sys.argv) != 4 or sys.argv[1] not in ('to-png', 'to-bin'):
        sys.exit(__doc__)
    if sys.argv[1] == 'to-png':
        to_png(open(sys.argv[2], 'rb').read(), sys.argv[3])
    else:
        open(sys.argv[3], 'wb').write(to_bin(sys.argv[2]))


if __name__ == '__main__':
    main()

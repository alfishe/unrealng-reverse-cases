#!/usr/bin/env python3
"""The two course scripts of the image, segment by segment: the Beginner course from $B7E8, the Champion course
from $BB24, up to the object list at $BEF8. A segment is the run of commands the interpreter at $9751 reads in one
go (it stops at the command $9760); a point segment holds the command $9775 with the point number (letter: n AND
$1F, 'A' + n - 1, skipping O); a sector end is the command $A4EE (the bonus screen) with its data.

    python3 tools/course.py [--image work/media/game.bin]
"""
import argparse
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def letter(n):
    n &= 0x1F
    return chr(0x40 + n + (1 if n >= 0x0F else 0))


def segments(img):
    starts = [0xB7E8, 0xBB24]
    for a in range(0xB7E8, 0xBEF8):
        if img[a] == 0x60 and img[a + 1] == 0x97 and a + 2 not in starts:
            starts.append(a + 2)
    starts.sort()
    out = []
    for s in starts:
        e = min([x for x in starts if x > s] + [0xBEF8])
        course = 1 if s < 0xBB24 else 2
        pts = [letter(img[a + 3]) for a in range(s, e - 3) if img[a] == 0x75 and img[a + 1] == 0x97]
        kind = 'sector end' if img[s:s + 2] == bytes([0xEE, 0xA4]) else ('point ' + pts[0] if pts else 'start')
        out.append((course, s, e - 1, kind))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--image', default=os.path.join(HERE, '..', 'work', 'media', 'game.bin'))
    args = p.parse_args()
    g = open(args.image, 'rb').read()
    img = bytes(0x60F8) + g
    for course, s, e, kind in segments(img):
        print('%d $%04X-$%04X %s' % (course, s, e, kind))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Screens of a recording kept on disk for the figures: the Spectrum screen ($4000-$5AFF) at the start of each
frame asked, read with TTD memory_at from the unreal-ng instance that holds the recording (re_session.py open), into
work/<rec>/frames/FFFFFF.scr. The figure scripts then read the files and need no emulator.

    python3 tools/grab.py --work work/view REC FIRST:LAST:STEP [FRAME ...]

A frame already on disk is not read again.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import elitelib as E  # noqa: E402


def path(rec, frame):
    return os.path.join(E.CASE, 'work', rec, 'frames', '%06d.scr' % frame)


def load(rec, frame):
    return open(path(rec, frame), 'rb').read()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('rec')
    p.add_argument('frames', nargs='+')
    a = p.parse_args()
    s = E.session(a.work)
    want = []
    for f in a.frames:
        if ':' in f:
            lo, hi, st = map(int, f.split(':'))
            want += list(range(lo, hi + 1, st))
        else:
            want.append(int(f))
    os.makedirs(os.path.dirname(path(a.rec, 0)), exist_ok=True)
    n = 0
    for f in want:
        if os.path.isfile(path(a.rec, f)):
            continue
        open(path(a.rec, f), 'wb').write(bytes(E.read(s, f, 0x4000, 0x1B00, 0)))
        n += 1
    print('%s: %d screens read, %d asked' % (a.rec, n, len(want)))


if __name__ == '__main__':
    main()

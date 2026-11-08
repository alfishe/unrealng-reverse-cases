#!/usr/bin/env python3
"""The eight ship slots of a recording kept on disk for the figures: ShipSlots $6048-$617F (8 x 39 bytes) at the
start of each frame asked, read with TTD memory_at from the unreal-ng instance that holds the recording
(re_session.py open), into work/<rec>/slots/FFFFFF.bin. tools/fig_slots_anim.py reads them and needs no emulator.

    python3 tools/grab_slots.py --work work/view REC FIRST:LAST:STEP

A frame already on disk is not read again.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import elitelib as E  # noqa: E402

BASE, SIZE = 0x6048, 8 * 39


def path(rec, frame):
    return os.path.join(E.CASE, 'work', rec, 'slots', '%06d.bin' % frame)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', required=True)
    p.add_argument('rec')
    p.add_argument('frames')
    a = p.parse_args()
    s = E.session(a.work)
    lo, hi, st = map(int, a.frames.split(':'))
    os.makedirs(os.path.dirname(path(a.rec, 0)), exist_ok=True)
    n = 0
    for f in range(lo, hi + 1, st):
        if not os.path.isfile(path(a.rec, f)):
            open(path(a.rec, f), 'wb').write(bytes(E.read(s, f, BASE, SIZE, 0)))
            n += 1
    print('%s: %d slot blocks read' % (a.rec, n))


if __name__ == '__main__':
    main()

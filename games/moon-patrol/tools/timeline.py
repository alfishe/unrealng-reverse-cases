#!/usr/bin/env python3
"""The game's own variables over a recording, every STEP frames (memory_at at each frame's start): the menu choices
$B257 players / $B258 course / $B259 control, the current player record at $B271 (player, score $B272-$B275 BCD,
course script pointer $B27A, course base $B27C, lives $B284, time $B285-$B286 BCD seconds, $B288 flags: bit 7 tune),
the buggy state $B216 ($FF alive, 0-8 dying) and the interrupt mode seen through I ($3A in play: IM 2).

    python3 tools/timeline.py --work work/runs/m1 [--step 250] [--from 0] [--to N]
"""
import argparse
import sys
import os

import mplib as M
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from course import segments  # noqa: E402

G = open(os.path.join(M.CASE, 'work', 'media', 'game.bin'), 'rb').read()
SEG = {s: (c, k) for c, s, e, k in segments(bytes(0x60F8) + G)}


def seg_name(ptr):
    best = None
    for s in sorted(SEG):
        if s <= ptr:
            best = s
    if best is None or ptr >= 0xBEF8:
        return '-'
    c, k = SEG[best]
    return '%d:%s' % (c, k.replace('point ', ''))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--step', type=int, default=250)
    p.add_argument('--from', dest='lo', type=int, default=0)
    p.add_argument('--to', type=int)
    args = p.parse_args()
    s = M.session(args.work)
    st = s.call('time_travel', {'action': 'status'}, ok=False).structured or {}
    hi = args.to or st.get('last_frame') or st.get('end_frame') or 20000
    print('frame  opt   pl score    seg        ptr   base lives time  flags B216')
    for f in range(args.lo, hi, args.step):
        try:
            m = M.read(s, f, 0xB210, 0x80)
        except RuntimeError:
            break
        v = lambda a: m[a - 0xB210]
        ptr = v(0xB27A) | v(0xB27B) << 8
        print('%6d %d%d%d %3d %02X%02X%02X%02X %-11s %04X %02X %4d %02X%02X  %02X    %02X' % (
            f, v(0xB257), v(0xB258), v(0xB259), v(0xB271), v(0xB272), v(0xB273), v(0xB274), v(0xB275),
            seg_name(ptr), ptr, v(0xB27C), v(0xB284), v(0xB285), v(0xB286), v(0xB288), v(0xB216)))


if __name__ == '__main__':
    main()

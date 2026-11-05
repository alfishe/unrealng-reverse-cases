#!/usr/bin/env python3
"""The R register the GS driver reads to pick an effect: every `LD A,R` of RandomFxKill (`$C069`) and RandomFxShot
(`$C0A8`) in a recording, from access traces (docs/09-sound.md 9.5).

    python3 tools/gs_rreg.py --work work/gsB/rT --plays work/gsB/an/rT-plays.json --out work/gsB/an/r-values.json

--plays is tools/gs_ports.py's list of the effects the host played. For each play of effect 3, 4, 6 or 7 (the
choices by R) the frame is traced (kit access trace on the instance that holds the recording, kept in W/traces/),
and the instruction after the `LD A,R` gives A = R as read. Written: one record per call with the frame, the PC of
the LD A,R, R, the effect the window gives and the effect the host sent.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

LD_A_R = {0xC069: 'kill', 0xC0A8: 'shot'}


def window_effect(kind, r):
    """The driver's three windows (src/disk/driver.asm): C counts down from $50, $A0, $FF; no match: the first"""
    first, second, third = (3, 4, 2) if kind == 'kill' else (6, 7, 8)
    if 0x01 <= r <= 0x50:
        return first
    if 0x51 <= r <= 0xA0:
        return second
    if 0xA1 <= r <= 0xFF:
        return third
    return first


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--work', required=True)
    ap.add_argument('--plays', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--unreal')
    a = ap.parse_args()
    plays = [p for p in json.load(open(a.plays)) if p['effect'] in (3, 4, 6, 7)]
    out = []
    for p in plays:
        args = argparse.Namespace(trace=None, work=a.work, window=f"{p['frame']}:0-{p['frame'] + 1}:0",
                                  max_cycles=None, unreal=a.unreal)
        t = kitlib.load_trace(args)
        xs = t.instructions
        for i, x in enumerate(xs[:-1]):
            if x.pc in LD_A_R and xs[i + 1].pc == x.pc + 2:
                r = xs[i + 1].af >> 8
                kind = LD_A_R[x.pc]
                rec = {'frame': x.frame, 'pc': x.pc, 'kind': kind, 'r': r, 'window_effect': window_effect(kind, r),
                       'played': p['effect']}
                out.append(rec)
                print(rec)
    json.dump(out, open(a.out, 'w'), indent=0)
    agree = sum(1 for r in out if r['window_effect'] == r['played'])
    print(f'{len(out)} LD A,R; R ${min(r["r"] for r in out):02X}-${max(r["r"] for r in out):02X}; '
          f'{agree} agree with the effect the host sent')


if __name__ == '__main__':
    main()

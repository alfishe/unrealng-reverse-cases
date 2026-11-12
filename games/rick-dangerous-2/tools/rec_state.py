#!/usr/bin/env python3
"""The state variables of recordings at their sampled frames (the capture keeps snapshots/NNNNNN/ram-N.bin every
250 frames; RAM 5, 2, 0 make the 64 K the game sees): the level `$7EF1`, the section `$9B93`, the lives `$8B3B`, the
ammunition `$8B3C`, the detonators `$8B3D`, the score `$7F1D-$7F22`, the control method `$7252`. With --summary one
line per recording: the levels and sections seen, the lowest lives, the highest score.

    python3 tools/rec_state.py [--summary] work/stage1/REC ...
"""
import argparse
import glob
import os


def state(d):
    m = bytes(16384) + b''.join(open(os.path.join(d, f'ram-{n}.bin'), 'rb').read() for n in (5, 2, 0))
    return dict(level=m[0x7EF1], section=m[0x9B93], lives=m[0x8B3B], ammo=m[0x8B3C], det=m[0x8B3D],
                score=int(''.join(str(b) for b in m[0x7F1D:0x7F23])), method=m[0x7252])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('recs', nargs='+')
    ap.add_argument('--summary', action='store_true')
    a = ap.parse_args()
    for r in a.recs:
        rows = [(int(os.path.basename(d)), state(d)) for d in sorted(glob.glob(os.path.join(r, 'snapshots', '[0-9]*')))]
        if not rows:
            continue
        if a.summary:
            secs = sorted({(s['level'], s['section']) for _, s in rows})
            by = {}
            for lv, sc in secs:
                by.setdefault(lv, []).append(sc)
            print(f"{r}: {len(rows)} samples; sections " + '; '.join(f'L{lv}: {",".join(map(str, v))}' for lv, v in by.items())
                  + f"; lives min {min(s['lives'] for _, s in rows)}; score max {max(s['score'] for _, s in rows)}")
        else:
            for f, s in rows:
                print(r, f, ' '.join(f'{k}={v}' for k, v in s.items()))


if __name__ == '__main__':
    main()

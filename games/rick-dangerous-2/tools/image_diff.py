#!/usr/bin/env python3
"""What changes from the image to play, per level: the image `tools/image.py` writes for the level (side A with side
B's block N at `$A800`, the maps decrypted when --decrypted) against the 64 K the Z80 sees in the RZX run's level N at
a sample (work/stage1/rzx/lN/mem.bin, one 64 K every 250 frames; `tools/rzx_log.py`). Prints the differing ranges
(gaps under --join bytes joined) and their byte counts, from --from to --to.

    python3 tools/image_diff.py LEVEL [--sample 1] [--decrypted] [--from 5B00] [--to FFFF] [--join 16]
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import image  # noqa: E402

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', type=int)
    ap.add_argument('--sample', type=int, default=1)
    ap.add_argument('--decrypted', action='store_true')
    ap.add_argument('--from', dest='lo', default='5B00')
    ap.add_argument('--to', dest='hi', default='FFFF')
    ap.add_argument('--join', type=int, default=16)
    a = ap.parse_args()
    img = bytearray(image.image(None if a.level == 1 else a.level))
    if a.decrypted and a.level != 1:
        img = bytearray(image.decrypt_maps(img))
    with open(os.path.join(CASE, f'work/stage1/rzx/l{a.level}/mem.bin'), 'rb') as f:
        f.seek(a.sample * 65536)
        mem = f.read(65536)
    lo, hi = int(a.lo, 16), int(a.hi, 16)
    diff = [i for i in range(lo, hi + 1) if img[i] != mem[i]]
    runs = []
    for i in diff:
        if runs and i - runs[-1][1] <= a.join:
            runs[-1][1] = i
            runs[-1][2] += 1
        else:
            runs.append([i, i, 1])
    print(f'level {a.level}, RZX frame {a.sample * 250}: {len(diff)} bytes differ in ${lo:04X}-${hi:04X}')
    for s, e, n in runs:
        print(f'  ${s:04X}-${e:04X}  {n}')


if __name__ == '__main__':
    main()

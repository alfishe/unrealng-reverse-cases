#!/usr/bin/env python3
"""The RZX playthrough's keys aligned to unreal-ng's own frames, checked frame by frame: an input script that replays
the play without the RZX (so the TTD records it), and the proof that it does.

    python3 tools/rzx_align.py --log work/stage1/rzx --from 1000 --out work/stage1/rzx-chunks [--port-base 36910]

From the state `log` saved after sample N (at<N>.szx), each frame is run with the keys the game read in the sample
it should reach (tools/rzx_keys.py keys_of), then the game's variables `$6300-$63FF` are compared with that sample.
An RZX frame is not always one video frame: where they part (the RZX's start, a frame the game spends with the
interrupt masked), the replay is one frame behind or ahead; then the next video frame is compared with the same
sample (behind) or the frame with the next sample (ahead), and the offset is kept. The script holds, for each
video frame, the keys of its sample; work/.../align.json lists every offset change and any frame that matched no
sample: that ends the chunk, and the next one starts from the next saved state (at<N>.szx every 1000 samples).
Each chunk is a script, rzx-<start>.txt, and chunks.json lists them with the rooms each one passes.

A sample is taken at a frame's end, which can fall inside a pass: work variables the main loop is changing at
that moment (`$63AE`, the scratch word of `$8E0C-$8F04`, and the like) may then differ while the game is the same. A
frame matches when every key variable is equal (the player `$6359-$635B`, the room `$6363`, `$636C`, the lives
`$636D`, the energy `$636E`, the random number `$63A4-$63A7`) and at most 8 others differ; such frames are counted.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab  # noqa: E402
from rzx_keys import keys_of, NVARS, VARS  # noqa: E402


KEY = (0x59, 0x5A, 0x5B, 0x63, 0x6C, 0x6D, 0x6E, 0xA4, 0xA5, 0xA6, 0xA7)


def same(v, w):
    if v == w:
        return 2
    if any(v[i] != w[i] for i in KEY):
        return 0
    return 1 if sum(1 for i in range(NVARS) if v[i] != w[i]) <= 8 else 0


def write_script(path, rows, start, end):
    with open(path, 'w') as out:
        out.write(f'# rzx-{start:06d}: the keys of zxdb/tujad.rzx ("Recorded by Rafal") from its sample {start} '
                  f'(work/stage1/rzx/at{start:06d}.szx) to {end}, aligned to unreal-ng frames by tools/rzx_align.py\n')
        held = None
        for i, k in enumerate(rows):
            if k != held:
                out.write(f"{i} {' '.join(k) if k else '-'}\n")
                held = k
        out.write(f'{len(rows)} -\n{len(rows) + 1} END\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--log', required=True)
    ap.add_argument('--from', dest='start', type=int, required=True)
    ap.add_argument('--to', type=int, default=80680)
    ap.add_argument('--out', required=True, help='a folder: one script a chunk, rzx-<start>.txt')
    ap.add_argument('--port-base', type=int, default=36910)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    ref = open(os.path.join(args.log, 'frames.bin'), 'rb').read()
    total = len(ref) // NVARS
    sample = lambda i: ref[i * NVARS:(i + 1) * NVARS]  # noqa: E731
    keys_at = lambda i: keys_of(sample(i)[0xC2], not (sample(i)[0x69] & 1))  # noqa: E731
    lab = Lab(args.port_base)
    chunks = []
    try:
        n = args.start
        while n < args.to:
            lab.load(os.path.join(args.log, f'at{n:06d}.szx'))
            rows, changes, failure, near = [], [], None, 0
            s, f = n, 0
            while s < min(total, args.to):
                k = keys_at(s)
                lab.keys(k)
                lab.run(1)
                f += 1
                rows.append(k)
                v = lab.read(VARS, NVARS)
                m = same(v, sample(s))
                if m:
                    near += m == 1
                    s += 1
                elif s + 1 < total and same(v, sample(s + 1)):
                    changes.append(dict(frame=f, sample=s, change='ahead: one sample skipped'))
                    s += 2
                elif s > 0 and same(v, sample(s - 1)):
                    changes.append(dict(frame=f, sample=s, change='behind: the frame repeated the previous sample'))
                else:
                    diff = [f'${VARS + i:04X} {v[i]:02X} (RZX {sample(s)[i]:02X})' for i in range(NVARS)
                            if v[i] != sample(s)[i]]
                    failure = dict(frame=f, sample=s, differ=diff[:16], count=len(diff), keys=k)
                    rows.pop()
                    break
            lab.keys([])
            rooms = sorted({sample(i)[0x63] for i in range(n, s)})
            chunk = dict(start=n, end=s, frames=len(rows), near_frames=near, changes=changes, failure=failure,
                         rooms=rooms)
            chunks.append(chunk)
            write_script(os.path.join(args.out, f'rzx-{n:06d}.txt'), rows, n, s)
            print(n, '->', s, 'rooms', len(rooms), 'failure', failure and failure['differ'][:3], flush=True)
            n = (s // 1000 + 1) * 1000
    finally:
        lab.close()
    json.dump(chunks, open(os.path.join(args.out, 'chunks.json'), 'w'), indent=1)


if __name__ == '__main__':
    main()

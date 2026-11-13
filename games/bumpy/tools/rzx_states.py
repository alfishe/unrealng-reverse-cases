#!/usr/bin/env python3
"""The ball's state at every frame of the RZX run (SkoolKit's rzxplay, no per-instruction trace: the state is sampled
when each frame's input block starts). One line a frame: the RZX frame, the level `$AB00`, the ball's state `$AA00`
(0 bounce in place, 1 left, 2 right, 3 up, 4 down, 5 stopped, 6 burst, 7 lost below, 8 level end), the step
`$A9FF`, the cell `$AA44`, the spring flag `$AA13`, the platform under the ball `$AB1C`, the prizes left `$AA45`,
the lives `$AB01`, the timer `$AB04` (a word: 1000 at a life's start, one down each main-loop pass, so it numbers
the passes). tools/record.py events (plan_events) takes each lost level's moves from it.

    python3 tools/rzx_states.py work/candidates/zxdb-extra/bumpy.rzx work/stage2/rzx-states.tsv
"""
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402

FIELDS = (('level', 0xAB00), ('state', 0xAA00), ('step', 0xA9FF), ('cell', 0xAA44), ('spring', 0xAA13),
          ('platform', 0xAB1C), ('prizes', 0xAA45), ('lives', 0xAB01), ('timer', 0xAB04), ('timer_hi', 0xAB05))
ROWS = []


def main():
    rzx, out = sys.argv[1], sys.argv[2]
    orig_next = rzxplay.RZXTracer.next_frame

    def next_frame(self):
        mem = self.simulator.memory
        ROWS.append((self.context.frame_count,) + tuple(mem[a] for _, a in FIELDS))
        return orig_next(self)
    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.main([rzx, '--quiet', '--no-screen'] + sys.argv[3:])
    with open(out, 'w') as f:
        f.write('frame\t' + '\t'.join(n for n, _ in FIELDS) + '\n')
        for r in ROWS:
            f.write('\t'.join(map(str, r)) + '\n')
    print(out, len(ROWS), 'frames')


if __name__ == '__main__':
    main()

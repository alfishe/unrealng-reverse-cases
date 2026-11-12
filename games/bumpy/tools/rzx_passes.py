#!/usr/bin/env python3
"""The main loop's passes in the RZX run, SkoolKit's rzxplay with a per-instruction hook (slow: use --stop). The
loop (`$ACC8`) waits for the frame once a pass: `$AD0C` calls `$B87E`, which calls the frame wait `$B6E4`
(`EI` at `$B6E9`, `HALT`). Every fetch of `$B6E9` (the wait begins) and `$B6EB` (the first instruction after the
HALT) is logged with the RZX frame and the T-state in it. Writes OUT, one line a pass: the frame and T-state of the
pass's start after the HALT, the work in T-states up to the next `$B6E9`, and the frames from one HALT's end to the
next.

    python3 tools/rzx_passes.py work/candidates/zxdb-extra/bumpy.rzx work/stage1/passes.tsv --start 0 --stop 30000
"""
import argparse
import os
import sys
import tempfile

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402

FRAME_T = 69888
SIM = []
EVENTS = []
START = [0]


def hook(tracefile, context, fetch_counter, pc):
    if pc == 0xB6E9 or pc == 0xB6EB:
        f = context.frame_count
        if f >= START[0]:
            EVENTS.append((pc, f, SIM[0].registers[25]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('out')
    ap.add_argument('--start', type=int, default=0)
    ap.add_argument('--stop', type=int, required=True)
    a = ap.parse_args()
    START[0] = a.start
    orig_init = rzxplay.RZXTracer.__init__

    def init(self, context, block):
        orig_init(self, context, block)
        SIM[:] = [self.simulator]
    rzxplay.RZXTracer.__init__ = init
    rzxplay.trace_exec = hook
    dummy = os.path.join(tempfile.mkdtemp(dir=os.path.dirname(os.path.abspath(a.out))), 'trace')
    rzxplay.main([a.rzx, '--quiet', '--no-screen', '--trace', dummy, '--stop', str(a.stop)])
    with open(a.out, 'w') as out:
        out.write('frame\ttstate\twork_t\tframes_to_next\n')
        begin = None
        for pc, f, t in EVENTS:
            now = f * FRAME_T + t
            if pc == 0xB6EB:
                if begin is not None:
                    out.write(f'{begin[0]}\t{begin[1]}\t{begin[3]}\t{f - begin[0]}\n')
                begin = [f, t, now, None]
            elif begin is not None and begin[3] is None:
                begin[3] = now - begin[2]


if __name__ == '__main__':
    main()

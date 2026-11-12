#!/usr/bin/env python3
"""Count the main loop's passes (`$8DFE` fetched) and the object updates (`$8E2B`) in every frame of the RZX run,
SkoolKit's rzxplay with a per-instruction hook (slow: run it with --stop). Writes OUT (frame, passes, updates).

    PYTHONPATH=$SKOOLKIT_VENV/lib/python3.12/site-packages python3 tools/rzx_passes.py RZX OUT.tsv --stop FRAMES
"""
import argparse
import os
import tempfile

from skoolkit import rzxplay

COUNT = {}
CTX = []


class Ctx(rzxplay.RZXContext):
    def __init__(self, screen):
        super().__init__(screen)
        CTX.append(self)


def hook(tracefile, context, fetch_counter, pc):
    if pc == 0x8DFE or pc == 0x8E2B:
        c = COUNT.setdefault(context.frame_count, [0, 0])
        c[pc == 0x8E2B] += 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('out')
    ap.add_argument('--stop', type=int, required=True)
    a = ap.parse_args()
    rzxplay.RZXContext = Ctx
    rzxplay.trace_exec = hook
    dummy = os.path.join(tempfile.mkdtemp(dir=os.path.dirname(os.path.abspath(a.out))), 'trace')
    rzxplay.main([a.rzx, '--quiet', '--no-screen', '--trace', dummy, '--stop', str(a.stop)])
    with open(a.out, 'w') as f:
        f.write('frame\tpasses\tupdates\n')
        for k in sorted(COUNT):
            f.write(f'{k}\t{COUNT[k][0]}\t{COUNT[k][1]}\n')


if __name__ == '__main__':
    main()

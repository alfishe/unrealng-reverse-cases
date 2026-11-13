#!/usr/bin/env python3
"""The random seeds of the RZX Archive's Myth run: each stage seeds its random number word `$FE0A` from the R register
(`LD A,R`) at its set-up (stage 1 `$9DBF`, stage 2 `$9784`, stage 3 `$9D1E`, stage 4 `$9F9C`, stage 5 `$96FB`: the
`LD ($FE0A),BC` after two `LD A,R`) and, in stages 1 and 3, every 64th run of a routine of the main loop (stage 1
`$796B`, stage 3 `$7983`: the high byte from R). R counts the instructions and the interrupts taken, so it depends on
the machine's timing, and a keyed replay of the run in unreal-ng (tools/rzx_replay.py) gets other seeds than the RZX's
emulator (SPIN 0.5) did; the replay writes the RZX's seeds instead.

SkoolKit's rzxplay plays the RZX twice, no emulator instance. The first pass gives each frame's executed addresses
(the C simulator's exec map) and keeps the frames where a store of the frame's stage ran; the second traces only those
frames instruction by instruction and reads `$FE0A-$FE0B` right after each store. Output OUT/seeds.json:
[{block, rzx_frame, site, n, value}], n the store's run count in its input block (1 = its first run after the block's
snapshot), so the replay writes the same word after the same run. The stores sit at addresses another stage's code
also uses, so a store counts only in the block of its own stage (block N holds stage N, block 0 the menu).

    python3 tools/rzx_seeds.py work/candidates/rzxarchive/myth.rzx --out work/stage2/rzx

(The first form of this tool stopped unreal-ng's own RZX playback on a breakpoint at each store: the step after the
stop desynced the playback, "too_many_ins" at RZX frame 2671.)
"""
import argparse
import json
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402

SITES = {1: (0x796B, 0x9DBF), 2: (0x9784,), 3: (0x7983, 0x9D1E), 4: (0x9F9C,), 5: (0x96FB,)}


def play(rzx, traced):
    """One pass. traced None: returns the frames where a store of the block's stage ran; else traces those frames
    and returns the seeds"""
    base = rzxplay.CSimulator
    found, seeds, blocks, counts = [], [], [], {}
    orig_set = rzxplay.RZXTracer.set_input_rec
    ctx = {}

    def set_input_rec(self, input_rec):
        orig_set(self, input_rec)
        blocks.append(self.context.frame_count)
        ctx['context'] = self.context

    class Sim(base):
        def exec_frame(self, fetch_counter, exec_map, trace):
            frame = ctx['context'].frame_count
            block = len(blocks) - 1
            sites = SITES.get(block, ())
            if traced is None:
                seen = set()
                r = base.exec_frame(self, fetch_counter, seen, trace)
                if sites and any(s in seen for s in sites):
                    found.append(frame)
                return r
            if frame not in traced:
                return base.exec_frame(self, fetch_counter, exec_map, trace)
            state = {'site': None}
            mem = self.memory

            def step(*args):
                pc = args[-1]
                if state['site'] is not None:
                    site = state['site']
                    n = counts[(block, site)] = counts.get((block, site), 0) + 1
                    seeds.append({'block': block, 'rzx_frame': frame, 'site': f'${site:04X}', 'n': n,
                                  'value': mem[0xFE0A] + 256 * mem[0xFE0B]})
                    state['site'] = None
                if pc in sites:
                    state['site'] = pc
            return base.exec_frame(self, fetch_counter, exec_map, step)

    rzxplay.CSimulator = Sim
    rzxplay.RZXTracer.set_input_rec = set_input_rec
    try:
        rzxplay.main(['--no-screen', '--quiet', '--fps', '0', rzx])
    finally:
        rzxplay.CSimulator = base
        rzxplay.RZXTracer.set_input_rec = orig_set
    return found if traced is None else seeds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    frames = play(a.rzx, None)
    print(f'{len(frames)} frames run a seed store', flush=True)
    seeds = play(a.rzx, set(frames))
    os.makedirs(a.out, exist_ok=True)
    json.dump({'rzx': a.rzx, 'frames_with_stores': len(frames), 'seeds': seeds},
              open(os.path.join(a.out, 'seeds.json'), 'w'), indent=1)
    by = {}
    for x in seeds:
        by[(x['block'], x['site'])] = by.get((x['block'], x['site']), 0) + 1
    print(len(seeds), 'seeds', by)


if __name__ == '__main__':
    main()
